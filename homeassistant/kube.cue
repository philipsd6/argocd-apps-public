package kube

#App: "homeassistant"

configMap: env: data: TZ: "\(#TZ)"

deployment: homeassistant: spec: template: spec: {
	containers: [{
		envFrom: [{configMapRef: name: "env"}]
		image: "homeassistant/home-assistant"
		ports: [{containerPort: 8123}]
		volumeMounts: [{mountPath: "/config", name: "config"}]
	}]
	hostNetwork: true
}

deployment: homeassistant: spec: dnsPolicy: "ClusterFirstWithHostNet"
