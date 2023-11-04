package kube

#App: "teslamate"

configMap: env: data: {
	TZ:            "\(#TZ)"
	DISABLE_MQTT:  "false"
	DATABASE_HOST: "postgres.postgres.svc.cluster.local"
	MQTT_HOST:     "mosquitto.mosquitto.svc.cluster.local"
	GF_AUTH_OAUTH_AUTO_LOGIN: "true"
	GF_AUTH_SIGNOUT_REDIRECT_URL: "https://auth.\(#Domain)/oauth2/sign_out"
	GF_USERS_VIEWERS_CAN_EDIT: "false"
	GF_USERS_ALLOW_SIGN_UP: "false"
	GF_USERS_AUTO_ASSIGN_ORG: "true"
	GF_USERS_AUTO_ASSIGN_ORG_ROLE: "Editor"
	GF_AUTH_ANONYMOUS_ENABLED: "true"
	GF_AUTH_ANONYMOUS_ORG_ROLE: "Viewer"
	GF_AUTH_PROXY_ENABLED: "true"
	GF_AUTH_PROXY_HEADER_NAME: "X-Email"
	GF_AUTH_PROXY_HEADER_PROPERTY: "email"
	GF_AUTH_PROXY_HEADERS: "Name:X-User"
	GF_AUTH_PROXY_ENABLE_LOGIN_TOKEN: "false"
}

#BitwardenID: "e2a18c2a-4a07-463a-ad49-f0e9af08324b"
externalSecret: teslamate: spec: data: [
	{secretKey: "DATABASE_NAME"},
	{secretKey: "DATABASE_USER"},
	{secretKey: "DATABASE_PASS"},
	{secretKey: "ENCRYPTION_KEY"},
]
externalSecret: teslamate: spec: target: template: data: {
	DATABASE_NAME:  "{{ .DATABASE_NAME }}"
	DATABASE_USER:  "{{ .DATABASE_USER }}"
	DATABASE_PASS:  "{{ .DATABASE_PASS }}"
	ENCRYPTION_KEY: "{{ .ENCRYPTION_KEY }}"
}

deployment: teslamate: spec: template: spec: containers: [{
	image: "teslamate/teslamate"
	envFrom: [
		{configMapRef: name: "env"},
		{secretRef: name: "teslamate"},
	]
	ports: [{containerPort: 4000}]
}, {
	image: "teslamate/grafana"
	name:  "grafana"
	envFrom: [
		{configMapRef: name: "env"},
		{secretRef: name: "teslamate"},
	]
	ports: [{
		containerPort: 3000
		name:          "grafana"
	}]
	volumeMounts: [{
		mountPath: "/var/lib/grafana"
		name:      "data"
	}]
}]

persistentVolume: data: spec: hostPath: path: "/srv/data/teslamate/grafana"

ingress: teslamate: metadata: annotations: {
	"nginx.ingress.kubernetes.io/auth-url":              "https://auth.\(#Domain)/oauth2/auth"
	"nginx.ingress.kubernetes.io/auth-response-headers": "X-Auth-Request-User,X-Auth-Request-Email"
	"nginx.ingress.kubernetes.io/auth-signin":           "https://auth.\(#Domain)/oauth2/start?rd=$scheme%3A%2F%2F$host$escaped_request_uri"
	"nginx.ingress.kubernetes.io/configuration-snippet": """
														 auth_request_set $user   $upstream_http_x_auth_request_user;
														 auth_request_set $email  $upstream_http_x_auth_request_email;
														 proxy_set_header X-User  $user;
														 proxy_set_header X-Email $email;
														 """
}

postgreSQLUser: teslamate: metadata: labels: "app.kubernetes.io/component": "database"
postgreSQLUser: teslamate: spec: superuser: true
