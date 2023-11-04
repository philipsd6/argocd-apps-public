package kube

#App:           "plex"
#Image:         "plexinc/pms-docker:plexpass"
#ContainerPort: 32400

configMap: env: data: {
	TZ:         "\(#TZ)"
	PLEX_CLAIM: "claim-G9pYGjEajwkEpJwGpFEp"
}

deployment: plex: spec: template: spec: containers: [{
	envFrom: [{configMapRef: name: "env"}]
	image:           "\(#Image)"
	imagePullPolicy: "Always"
	ports: [{containerPort: #ContainerPort}]
	_probeDefaults: {
		initialDelaySeconds: 0
		timeoutSeconds:      1
		tcpSocket: port: #ContainerPort
		timeoutSeconds: 1
	}
	livenessProbe: _probeDefaults & {
		failureThreshold: 3
		periodSeconds:    10
	}
	readinessProbe: _probeDefaults & {
		failureThreshold: 3
		periodSeconds:    10
	}
	startupProbe: _probeDefaults & {
		failureThreshold: 30
		periodSeconds:    5
	}
	stdin: true
	tty:   true
	volumeMounts: [{
		mountPath: "/config"
		name:      "config"
	}, {
		mountPath: "/transcode"
		name:      "transcode"
		_empty:    true
	}, {
		mountPath: "/data"
		name:      "data"
	}]
}]

persistentVolume: data: spec: {
	capacity: storage: "200Gi"
	hostPath: path:    "/srv/data/media"
}

persistentVolumeClaim: data: spec: resources: requests: storage: "200Gi"
