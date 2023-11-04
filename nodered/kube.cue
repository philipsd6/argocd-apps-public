package kube

#App: "nodered"

configMap: env: data: {
	NODE_RED_ENABLE_PROJECTS: "false"
	TZ:                       "\(#TZ)"
}

#BitwardenID: "1389d9bb-c276-47d8-8c68-9376a8a64198"
externalSecret: nodered: spec: target: name: "cred"
externalSecret: nodered: spec: data: [{
	secretKey: "NODE_RED_CREDENTIAL_SECRET"
}]
externalSecret: nodered: spec: target: template: data: {
	NODE_RED_CREDENTIAL_SECRET: '{{ .NODE_RED_CREDENTIAL_SECRET }}'
}

deployment: nodered: spec: template: spec: containers: [{
	envFrom: [
		{configMapRef: name: "env"},
		{secretRef: name: "cred"},
	]
	image: "nodered/node-red"
	ports: [{
		containerPort: 1880
	}, {
		_expose:       false
		name:          "orvibo"
		containerPort: 10000
		protocol:      "UDP"
	}]
	volumeMounts: [{
		mountPath: "/data"
		name:      "data"
	}]
}]
