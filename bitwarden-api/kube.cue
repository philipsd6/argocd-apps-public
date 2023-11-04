package kube

#App: "bitwarden-api"

#Port: 8087

// We need to supply BW_HOST, BW_USER, BW_PASS as a secret out-of-band manually for security reasons, so we can't define it here and it won't be visible in ArgoCD. ;-(

// Just keep it on the cluster level?
service: "bitwarden-api": spec: type: "ClusterIP"

deployment: "bitwarden-api": spec: template: spec: containers: [{
	envFrom: [{secretRef: name: "env"}]
	image: "ghcr.io/philipsd6/bw-serve"
	ports: [{containerPort: #Port, _expose: false}]
	livenessProbe: exec: command: ["wget", "-qO-", "http://127.0.0.1:\(#Port)/sync?force=true", "--post-data=''"]
	livenessProbe: {
		initialDelaySeconds: 20
		failureThreshold:    3
		timeoutSeconds:      10
		periodSeconds:       120
	}
	readinessProbe: tcpSocket: port: #Port
	readinessProbe: {
		initialDelaySeconds: 20
		failureThreshold:    3
		timeoutSeconds:      1
		periodSeconds:       10
	}
	startupProbe: tcpSocket: port: #Port
	startupProbe: {
		initialDelaySeconds: 10
		failureThreshold:    30
		timeoutSeconds:      1
		periodSeconds:       5
	}
}]

networkPolicy: "bitwarden-api": spec: ingress: [{
	from: [{
		podSelector: matchLabels: {
			"app.kubernetes.io/instance": "external-secrets"
			"app.kubernetes.io/part-of":  "external-secrets"
		}
		namespaceSelector: matchLabels: {
			"kubernetes.io/metadata.name": "external-secrets"
		}
	}]
}]
