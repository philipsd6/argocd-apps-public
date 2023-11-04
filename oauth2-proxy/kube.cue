package kube

#App:       "oauth2-proxy"
#Component: "authentication-proxy"
#Image:     "quay.io/oauth2-proxy/oauth2-proxy:v7.6.0"

#BitwardenID: "c192926a-3bd5-45fe-9f59-114407ee404a"
externalSecret: "oauth2-proxy": spec: data: [
	{secretKey: "COOKIE_SECRET"},
	{secretKey: "CLIENT_SECRET"},
	{secretKey: "CLIENT_ID"},
]
externalSecret: "oauth2-proxy": spec: target: template: data: {
	OAUTH2_PROXY_COOKIE_SECRET: "{{ .COOKIE_SECRET }}"
	OAUTH2_PROXY_CLIENT_SECRET: "{{ .CLIENT_SECRET }}"
	OAUTH2_PROXY_CLIENT_ID:     "{{ .CLIENT_ID }}"
}

serviceAccount: "oauth2-proxy": automountServiceAccountToken: true

configMap: "oauth2-proxy-accesslist": data: {
	"oauth2-proxy-accesslist.txt": """
		philipsd@gmail.com
		"""
}

configMap: "oauth2-proxy": data: {
	OAUTH2_PROXY_HTTP_ADDRESS:              "0.0.0.0:4180"
	OAUTH2_PROXY_HTTPS_ADDRESS:             "0.0.0.0:4443"
	OAUTH2_PROXY_REVERSE_PROXY:             "true"
	OAUTH2_PROXY_PASS_BASIC_AUTH:           "true"
	OAUTH2_PROXY_PASS_USER_HEADERS:         "true"
	OAUTH2_PROXY_PASS_HOST_HEADER:          "true"
	OAUTH2_PROXY_COOKIE_DOMAINS:            "\(#Domain)"
	OAUTH2_PROXY_WHITELIST_DOMAINS:         "*.\(#Domain)"
	OAUTH2_PROXY_AUTHENTICATED_EMAILS_FILE: "/etc/oauth2-proxy/oauth2-proxy-accesslist.txt"
	OAUTH2_PROXY_SESSION_STORE_TYPE:        "redis"
	OAUTH2_PROXY_REDIS_CONNECTION_URL:      "redis://redis.redis.svc.cluster.local"
	OAUTH2_PROXY_UPSTREAMS:                 "static://200"
	OAUTH2_PROXY_SET_XAUTHREQUEST:          "true"
	OAUTH2_PROXY_REDIRECT_URL:              "https://auth.\(#Domain)/oauth2/callback"
}

ingress: auth: metadata: annotations: {
	"nginx.ingress.kubernetes.io/server-snippet": "large_client_header_buffers 4 32k;"
}

deployment: auth: spec: template: spec: serviceAccountName:           "oauth2-proxy"
deployment: auth: spec: template: spec: automountServiceAccountToken: true
deployment: auth: spec: template: spec: containers: [{
	image: #Image
	envFrom: [
		{configMapRef: name: "oauth2-proxy"},
		{secretRef: name: "oauth2-proxy"},
	]
	ports: [{containerPort: 4180}]
	volumeMounts: [{
		mountPath: "/etc/oauth2-proxy"
		name:      "oauth2-proxy-accesslist"
	}]

	livenessProbe: httpGet: path:   "/ping"
	livenessProbe: httpGet: port:   4180
	livenessProbe: httpGet: scheme: "HTTP"
	livenessProbe: initialDelaySeconds: 0
	livenessProbe: timeoutSeconds:      1

	readinessProbe: httpGet: path:   "/ready"
	readinessProbe: httpGet: port:   4180
	readinessProbe: httpGet: scheme: "HTTP"
	readinessProbe: initialDelaySeconds: 0
	readinessProbe: timeoutSeconds:      5
	readinessProbe: successThreshold:    1
	readinessProbe: periodSeconds:       10

	securityContext: allowPrivilegeEscalation: false
	securityContext: capabilities: drop: ["ALL"]
	securityContext: readOnlyRootFilesystem: true
	securityContext: runAsGroup:             2000
	securityContext: runAsNonRoot:           true
	securityContext: runAsUser:              2000
	securityContext: seccompProfile: type: "RuntimeDefault"
}]
