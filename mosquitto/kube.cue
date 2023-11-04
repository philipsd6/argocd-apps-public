package kube

#App: "mosquitto"
#Ports: {
	mqtt:      1883
	websocket: 9001
}
#ConfigFile:          "mosquitto.conf"
#ConfigLocation:      "/mosquitto/config"
#PersistenceLocation: "/mosquitto/data"

configMap: config: data: "\(#ConfigFile)": """
	persistence true
	persistence_location \(#PersistenceLocation)
	listener \(#Ports.mqtt)
	listener \(#Ports.websocket)
	allow_anonymous true
	protocol websockets
	log_dest stdout
	require_certificate false
	"""

statefulSet: mosquitto: spec: template: spec: containers: [{
	command: ["mosquitto", "-c", "\(#ConfigLocation)/\(#ConfigFile)"]
	image: "eclipse-mosquitto:2.0"
	ports: [for k, v in #Ports {
		_expose:       false
		name:          k
		containerPort: v
	}]
	livenessProbe: tcpSocket: port:  "mqtt"
	readinessProbe: tcpSocket: port: "mqtt"
	volumeMounts: [{
		mountPath: "\(#ConfigLocation)"
		name:      "config"
	}, {
		mountPath: "\(#PersistenceLocation)"
		name:      "data"
	}]
}]
