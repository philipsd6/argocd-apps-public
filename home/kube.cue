package kube

#App:       "home"
#Component: "webserver"

// #BitwardenID: "c5709bee-df4c-4b30-9c17-5ece4d30f2a2"
// externalSecret: "git-creds": spec: secretStoreRef: name: "bitwarden-attachments"
// externalSecret: "git-creds": spec: data: [
//	{secretKey: "ssh_private_key", remoteRef: property: "dougnet-homepage-deploy-key.id_ed25519"},
//	{secretKey: "ssh_public_key", remoteRef: property: "dougnet-homepage-deploy-key.id_ed25519.pub"},
//	{secretKey: "known_hosts", remoteRef: property: "known_hosts-github.com"},
// ]

// externalSecret: "git-creds": spec: target: template: data: {
//	"id_ed25519":     "{{ .ssh_private_key }}"
//	"id_ed25519.pub": "{{ .ssh_public_key }}"
//	"known_hosts":    "{{ .known_hosts }}"
// }

// deployment: home: spec: template: spec: securityContext: fsGroup: 65533 // to make SSH key readable
deployment: home: spec: template: spec: containers: [{
	image: "busybox"
	ports: [{containerPort: 8280}]
	securityContext: runAsUser: 65533 // git-sync user
	volumeMounts: [
		{name: "content-from-git", mountPath: "/www", _empty: true},
	]
	command: [
		"/bin/sh", "-c",
		"httpd -vv -f -p 8280 -h /www/current/",
	]
}, {
	name:  "git-sync"
	image: "registry.k8s.io/git-sync/git-sync:v4.0.0"
	args: [
		// "--repo=git@github.com:philipsd6/homepage",
		"--repo=https://github.com/philipsd6/homepage",
		"--ref=dougnet",
		// "--sparse-checkout-file=" // TBD for font dir?
		"--depth=1",
		"--period=60s",
		"--link=current",
		"--root=/git",
		"--group-write",
		"--verbose=6",
		// "--ssh-known-hosts=false",
	]
	securityContext: runAsUser: 65533 // git-sync user
	volumeMounts: [
		{name: "content-from-git", mountPath: "/git", _empty: true},
		// {name: "git-creds", mountPath: "/etc/git-secret", readOnly: true, _mode: 0o400},
	]
}]
