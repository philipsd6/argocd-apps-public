package kube

#App:   "nzbget"
#Image: "hotio/\(#App)"

configMap: env: data: {
	PUID:  "\(#UID)"
	PGID:  "\(#GID)"
	TZ:    "\(#TZ)"
	UMASK: "002"
}

deployment: nzbget: spec: template: spec: containers: [{
	envFrom: [{configMapRef: name: "env"}]
	image: "\(#Image)"
	ports: [{containerPort: 6789}]
	volumeMounts: [{
		mountPath: "/config"
		name:      "config"
	}, {
		mountPath: "/data"
		name:      "data"
	}]
}]

persistentVolume: config: spec: hostPath: path: "/srv/data/usenet/nzbget"
persistentVolume: data: spec: hostPath: path: "/srv/data/usenet"
