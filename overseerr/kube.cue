package kube

#App:   "overseerr"
#Image: "sctx/\(#App)"

configMap: env: data: TZ: "\(#TZ)"

deployment: overseerr: spec: template: spec: containers: [{
	envFrom: [{configMapRef: name: "env"}]
	image: "\(#Image)"
	ports: [{containerPort: 5055}]
	volumeMounts: [{
		mountPath: "/app/config"
		name:      "config"
	}]
}]
