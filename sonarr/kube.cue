package kube

#App:   "sonarr"
#Image: "hotio/\(#App)"

configMap: env: data: {
	PUID:  "\(#UID)"
	PGID:  "\(#GID)"
	TZ:    "\(#TZ)"
	UMASK: "002"
}

deployment: sonarr: spec: template: spec: containers: [{
	envFrom: [{
		configMapRef: name: "env"
	}]
	image: "\(#Image)"
	ports: [{containerPort: 8989}]
	volumeMounts: [{
		mountPath: "/config"
		name:      "config"
	}, {
		mountPath: "/data"
		name:      "data"
	}]
}]

persistentVolume: data: spec: hostPath: path: "/srv/data"
