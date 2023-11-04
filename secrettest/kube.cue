package kube

#App:         "secrettest"
#Component:   #App
#BitwardenID: "0cb5c601-f19b-4f22-9b48-5a273e9af776"

// testing bitwarden-login
externalSecret: "login-test": spec: secretStoreRef: name: "bitwarden-login"
externalSecret: "login-test": spec: data: [
	{secretKey: "username"},
	{secretKey: "password"},
]
externalSecret: "login-test": spec: target: template: data: {
	username: "{{ .username }}"
	password: "{{ .password }}"
}

// testing bitwarden-fields
externalSecret: "fields-test": spec: secretStoreRef: name: "bitwarden-fields"
externalSecret: "fields-test": spec: data: [
	{secretKey: "githubAppID"},
	{secretKey: "githubAppInstallationID"},
]
externalSecret: "fields-test": spec: target: template: data: {
	githubAppID:             "{{ .githubAppID }}"
	githubAppInstallationID: "{{ .githubAppInstallationID }}"
}

// testing bitwarden-notes
externalSecret: "notes-test": spec: secretStoreRef: name: "bitwarden-notes"
externalSecret: "notes-test": spec: data: [
	{secretKey: "someNotes"},
]
externalSecret: "notes-test": spec: target: template: data: {
	someNotes: "{{ .someNotes }}"
}

// testing bitwarden-attachments
externalSecret: "attachments-test": spec: secretStoreRef: name: "bitwarden-attachments"
externalSecret: "attachments-test": spec: data: [
	{secretKey: "githubAppPrivateKey", remoteRef: property: "githubAppPrivateKey.rsa"},
]
externalSecret: "attachments-test": spec: target: template: data: {
	githubAppPrivateKey: "{{ .githubAppPrivateKey }}"
}

// testing all of them at once!
externalSecret: "allinone-test": spec: target: template: data: {
	// login
	username: "{{ .username }}"
	password: "{{ .password }}"
	// fields
	githubAppID:             "{{ .githubAppID }}"
	githubAppInstallationID: "{{ .githubAppInstallationID }}"
	// notes
	someNotes: "{{ .someNotes }}"
	// attachments
	githubAppPrivateKey: "{{ .githubAppPrivateKey }}"
}

externalSecret: "allinone-test": spec: data: [
	// login
	{secretKey: "username", sourceRef: storeRef: name: "bitwarden-login"},
	{secretKey: "password", sourceRef: storeRef: name: "bitwarden-login"},
	// fields is the default...
	{secretKey: "githubAppID"},
	{secretKey: "githubAppInstallationID"},
	// notes
	{secretKey: "someNotes", sourceRef: storeRef: name: "bitwarden-notes"},
	// attachments
	{
		secretKey: "githubAppPrivateKey"
		sourceRef: storeRef: name: "bitwarden-attachments"
		remoteRef: property: "githubAppPrivateKey.rsa"
	},
]
