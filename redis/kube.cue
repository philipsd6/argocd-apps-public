package kube

#App: "redis"
#Image: "redis:alpine"

configMap: config: data: {
	"redis.conf": """
		bind 0.0.0.0
		protected-mode no
		port 6379
		tcp-backlog 511
		timeout 0
		daemonize no
		loglevel notice
		logfile ""
		databases 16
		# save <seconds> <changes> [<seconds> <changes> ...]
		save 1200 1 300 100 60 1000
		dbfilename dump.rdb
		appendonly yes
		appendfilename "appendonly.aof"
		appenddirname "appendonly"
		appendfsync everysec
		maxmemory 2mb
		maxmemory-policy allkeys-lru

		"""
}

deployment: "redis": spec: template: spec: containers: [{
	image: #Image
	command: ["redis-server", "/config/redis.conf"]
	env: [{name: "MASTER", value: "true"}]
	ports: [{containerPort: 6379, _expose: false}]
	volumeMounts: [
		{mountPath: "/data", name: "data"},
		{mountPath: "/config", name: "config"},
	]
}]
