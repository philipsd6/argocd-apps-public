package kube

#App:       "authtest"
#Component: "webserver"

configMap: site: data: {
	"index.html": """
		<html>
			<head><title>DougNet</title></head>
			<body>
			<h1>DougNet</h1>
			<ul>
			<li><a href="cgi-bin/printenv">Display environment variables</a></li>
			</ul>
			</body>
		</html>
		"""
}

configMap: cgi: data: {
	"printenv": """
		#!/bin/sh
		echo "Content-Type: text/html"
		echo ""

		echo "<html><head>"
		echo '<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">'
		echo "<title>Environment</title>"
		echo "</head><body>"
		echo "<h1>Environment Variables</h1>"
		echo "<pre>"
		env
		echo "</pre>"
		echo "</body></html>"
		"""
}

ingress: authtest: metadata: annotations: {
	"nginx.ingress.kubernetes.io/auth-url": "https://auth.\(#Domain)/oauth2/auth"
	"nginx.ingress.kubernetes.io/auth-response-headers": "X-Auth-Request-User,X-Auth-Request-Email"
	"nginx.ingress.kubernetes.io/auth-signin": "https://auth.\(#Domain)/oauth2/start?rd=$scheme%3A%2F%2F$host$escaped_request_uri"
}

deployment: authtest: spec: template: spec: containers: [{
	image: "busybox"
	ports: [{containerPort: 8280}]
	volumeMounts: [{
		mountPath: "/var/www"
		name:      "site"
	}, {
		mountPath: "/var/www/cgi-bin"
		name:      "cgi"
		_mode:     0o500 // r-x
	}]
	command: ["httpd", "-vv", "-f", "-p", "8280", "-h", "/var/www/"]
}]
