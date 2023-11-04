package kube

import (
	"list"
	"strings"
)

#App:       string
#Component: string | *"app"
#Domain:    "home.philipdouglass.com"
#Labels: {
	"app.kubernetes.io/name":      string | *#App
	"app.kubernetes.io/part-of":   #App
	"app.kubernetes.io/component": string | *#Component
}
#BitwardenID: string
#TZ:          "America/New_York"

// uid/gid for me
#UID: 1000
#GID: 1000

serviceAccount: [Name=_]: {
	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: name:      string | *Name
	metadata: namespace: #App
	metadata: labels:    #Labels
	automountServiceAccountToken: bool | *true
}

networkPolicy: [Name=_]: {
	apiVersion: "networking.k8s.io/v1"
	kind:       "NetworkPolicy"
	metadata: name:      string | *Name
	metadata: namespace: #App
	ML=metadata: labels: #Labels
	spec: podSelector: matchLabels: ML.labels
	ingress?: [...{}]
}

persistentVolume: [Name=_]: {
	apiVersion: "v1"
	kind:       "PersistentVolume"
	metadata: name:   string | *"\(#App)-\(Name)"
	metadata: labels: #Labels
	spec: {
		accessModes: [...string] | *["ReadWriteOnce"]
		capacity: storage: string | *"1Gi"
		claimRef: {
			apiVersion: "v1"
			kind:       "PersistentVolumeClaim"
			name:       string | *Name
			namespace:  #App
		}
		storageClassName: "microk8s-hostpath"
		hostPath: path: string | *"/srv/data/\(#App)"
	}
}

persistentVolumeClaim: [Name=_]: {
	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: name:      string | *Name
	metadata: namespace: #App
	metadata: labels:    #Labels
	spec: {
		accessModes: [...string] | *["ReadWriteOnce"]
		resources: requests: storage: string | *"1Gi"
		storageClassName: "microk8s-hostpath"
		volumeName:       string | *"\(#App)-\(Name)"
	}
}

postgreSQLUser: [Name=_]: {
	apiVersion: "philipdouglass.com/v1"
	kind:       "PostgreSQLUser"
	metadata: name:      string | *Name
	metadata: namespace: #App
	metadata: labels:    #Labels
	spec: db: valueFrom: secretKeyRef: {
		name: string | *#App
		key:  string | *"DATABASE_NAME"
	}
	spec: username: valueFrom: secretKeyRef: {
		name: string | *#App
		key:  string | *"DATABASE_USER"
	}
	spec: password: valueFrom: secretKeyRef: {
		name: string | *#App
		key:  string | *"DATABASE_PASS"
	}
	spec: superuser: bool | *false
}

configMap: [Name=_]: {
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: name:      string | *Name
	metadata: namespace: #App
	metadata: annotations: "argocd.argoproj.io/sync-options": "Replace=true,Force=true"
	metadata: labels: #Labels
	immutable: bool | *true
	data: {}
}

webhookClusterSecretStore: [Name=_]: {
	apiVersion: "external-secrets.io/v1beta1"
	kind:       "ClusterSecretStore"
	metadata: name: string | *Name
	metadata: labels: #Labels
	spec: provider: webhook: url: string
	spec: provider: webhook: headers: "Content-Type": string | *"application/json"
	spec: provider: webhook: result: jsonPath?:       string
}

externalSecret: [Name=_]: {
	apiVersion: "external-secrets.io/v1beta1"
	kind:       "ExternalSecret"
	metadata: name:        string | *Name
	metadata: namespace:   #App
	metadata: labels:      #Labels
	spec: refreshInterval: string | *"1h"
	spec: secretStoreRef: name:   string | *"bitwarden-fields"
	spec: secretStoreRef: kind:   "ClusterSecretStore"
	spec: target: name?:          string
	spec: target: deletionPolicy: string | *"Delete"
	spec: target: template: type: string | *"Opaque"
	spec: target: template: metadata?: annotations?: {...}
	spec: target: template: metadata?: labels?: {...}
	spec: target: template: data?: {...}
	spec: target: template: templateFrom?: [...{configMap: {name: string, items: [...{key: string}]}}]
	spec: data: [...{
		// this show a nice feature cue-lang... if we provide the secretKey, we get that as the remoteRef property. If
		// we provide the remoteRef property, we get the secretKey. So it's reflectively concrete. Or we can provide
		// them separately if desired.
		KEY=secretKey: string | *PROP.property
		sourceRef?: storeRef: name: string
		sourceRef?: storeRef: kind: "ClusterSecretStore"
		remoteRef: key:           string | *#BitwardenID
		PROP=remoteRef: property: string | *KEY
	}]
}

#OneOfSecretData: {data: {...}} | {stringData: {...}}
secret: [Name=_]: {
	apiVersion: "v1"
	kind:       "Secret"
	metadata: name:      Name
	metadata: namespace: #App
	metadata: annotations: "argocd.argoproj.io/sync-options": string | *"Replace=true"
	metadata: labels: #Labels
	type:      string | *"Opaque"
	immutable: bool | *true
	#OneOfSecretData
}

service: [Name=_]: {
	apiVersion: "v1"
	kind:       "Service"
	metadata: name:      Name
	metadata: namespace: #App
	ML=metadata: labels: #Labels
	spec: {
		ports: [...{
			name:       string | *"http"
			port:       int
			targetPort: int | *port
			protocol:   *"TCP" | "UDP"
		}]
		selector: ML.labels
		type:     string | *"LoadBalancer"
	}
}

#Path: {
	pathType: string | *"Prefix"
	path:     string | *"/"
	backend: service: name: string
	backend: service: port: {name: string} | {number: int}
}

ingress: [Name=_]: {
	apiVersion: "networking.k8s.io/v1"
	kind:       "Ingress"
	metadata: annotations: "cert-manager.io/cluster-issuer": "letsencrypt"
	metadata: labels:       #Labels
	metadata: name:         Name
	metadata: namespace:    #App
	spec: ingressClassName: "nginx"
	spec: rules: [...{host: string, http: paths: [...#Path]}]
	spec: tls: [...{hosts: [...string], secretName: "\(#App)-tls"}]
}

daemonSet: [Name=_]: _deploymentSpec & {
	_name: Name
	kind:  "DaemonSet"
}

statefulSet: [Name=_]: _deploymentSpec & {
	_name: Name
	kind:  "StatefulSet"
	spec: serviceName: string | *"\(Name)"
	spec: updateStrategy: {
		rollingUpdate: partition: int | *0
		type: string | *"RollingUpdate"
	}
}

deployment: [Name=_]: _deploymentSpec & {
	_name: Name
	kind:  "Deployment"
	spec: strategy: type: string | *"Recreate"
	spec: progressDeadlineSeconds: int | *600
}

_deploymentSpec: {
	_name:      string
	apiVersion: "apps/v1"

	metadata: name:      _name
	metadata: namespace: #App
	ML=metadata: labels: #Labels
	spec: {
		minReadySeconds:      int | *0
		replicas:             int | *1
		revisionHistoryLimit: int | *2
		selector: matchLabels: ML.labels
		template: metadata: labels: ML.labels

		template: spec: containers: [
			// always one container with name of app
			{name: _name},
			// but may be others as well
			...{
				name:  string
				image: string
				resources: limits: cpu?:     _|_
				resources: limits: memory:   number | *"2048Mi"
				resources: requests: cpu:    number | *"2m"
				resources: requests: memory: number | *"64Mi"
			},
		]

		template: spec: {
			automountServiceAccountToken:  bool | *false
			setHostnameAsFQDN:             bool | *false
			hostNetwork:                   bool | *false
			dnsPolicy:                     string | *"ClusterFirst"
			restartPolicy:                 string | *"Always"
			terminationGracePeriodSeconds: int | *30
		}

		let ConfigMaps = [for k, v in configMap {k}]
		let Secrets = [for k, v in secret {k}] + [for k, v in externalSecret {k}]
		let Volumes = [
			for c in template.spec.containers
			if c.volumeMounts != _|_
			for vm in c.volumeMounts {
				name: vm.name
				[// switch
					if vm._empty {
						emptyDir: {medium: "Memory"}
					},
					if list.Contains(ConfigMaps, vm.name) {
						configMap: name: string | *vm.name
						if vm._mode != _|_ {
							configMap: defaultMode: vm._mode
						}
					},
					if list.Contains(Secrets, vm.name) {
						secret: secretName: string | *vm.name
						if vm._mode != _|_ {
							secret: defaultMode: vm._mode
						}
					},
					{
						persistentVolumeClaim: claimName: string | *vm.name
					},
				][0]
			},
		]

		template: spec: volumes: [for i, v in Volumes if !list.Contains(list.Drop(Volumes, i+1), v) {v}]
	}
}

_deploymentSpec: spec: template: spec: containers: [...{
	ports: [...{
		_export: *true | false // include the port in the service
		_expose: *true | false // include an ingress for this service port
	}]
	volumeMounts: [...{
		_empty: true | *false // mount is an emptyDir
	}]
}]

// Construct a fully qualified hostname from various input strings
#Hostname: {
	X1="in": [...string]
	X2: X1 + strings.Split(#Domain, ".")
	uniq: [for i, x in X2 if !list.Contains(list.Drop(X2, i+1), x) && x != "http" {x}]
	out: strings.Join(uniq, ".")
}

for x in [deployment, daemonSet, statefulSet] for k, v in x {
	let exported_ports = [
		for c in v.spec.template.spec.containers
		for p in c.ports
		if p._export {
			{
				port: p.containerPort
			}
			if p.name != _|_ {
				name: p.name
			}
			if p.protocol != _|_ {
				protocol: p.protocol
			}
			if p.targetPort != _|_ {
				targetPort: p.targetPort
			}
		},
	]

	let expose_rules = [
		for c in v.spec.template.spec.containers
		for p in c.ports
		if p._export && p._expose {
			let portName = p.name | *"http" // Default http gets dropped from hostname
			host: (#Hostname & {in: [portName, c.name, "\(k)"]}).out
			http: paths: [{
				path:     string | *"/"
				pathType: "Prefix"
				backend: service: name: "\(k)"
				backend: service: port: [// switch
							if p.name != _|_ {
						name: p.name
					}, {
						number: p.targetPort | *p.containerPort
					},
				][0]
			}]
		},
	]

	if len(exported_ports) > 0 {
		service: "\(k)": {
			metadata: labels: v.metadata.labels
			spec: selector:   v.spec.template.metadata.labels
			spec: ports:      exported_ports
			if v.kind == "StatefulSet" {
				spec: type:      "ClusterIP"
				spec: clusterIP: "None"
			}
		}
	}

	if len(expose_rules) > 0 {
		ingress: "\(k)": {
			metadata: labels: v.metadata.labels
			spec: rules:      expose_rules
			spec: tls: [{
				hosts: [for rule in expose_rules {rule.host}]
			}]
		}
	}

	let ConfigMaps = [for k, v in configMap {k}]
	let Secrets = [for k, v in secret {k}] + [for k, v in externalSecret {k}]

	for c in v.spec.template.spec.containers {
		if c.volumeMounts != _|_
		for vm in c.volumeMounts {
			// If the volumeMount name is in ConfigMaps or Secrets, we've mounted that and don't need PV/PVC
			if !list.Contains(ConfigMaps, vm.name)
			if !list.Contains(Secrets, vm.name)
			if !vm._empty {
				persistentVolumeClaim: "\(vm.name)": metadata: labels: v.metadata.labels
				persistentVolume: "\(vm.name)": metadata: labels:      v.metadata.labels
			}
		}
	}
}

objects: [
	for x in [persistentVolume, persistentVolumeClaim, postgreSQLUser, configMap, secret, service, ingress, daemonSet, statefulSet, deployment, networkPolicy, externalSecret, serviceAccount, webhookClusterSecretStore] for k, v in x {
		v
	},
]
