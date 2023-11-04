package kube

#App:   "radarr"
#Image: "hotio/\(#App)"

configMap: env: data: {
	PUID:  "\(#UID)"
	PGID:  "\(#GID)"
	TZ:    "\(#TZ)"
	UMASK: "002"
}

deployment: radarr: spec: template: spec: containers: [{
	envFrom: [{configMapRef: name: "env"}]
	image: "\(#Image)"
	ports: [{containerPort: 7878}]
	volumeMounts: [{
		mountPath: "/config"
		name:      "config"
	}, {
		mountPath: "/data"
		name:      "data"
	}]
}]

persistentVolume: data: spec: hostPath: path: "/srv/data"
