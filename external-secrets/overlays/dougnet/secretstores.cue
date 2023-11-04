package kube

#App: "external-secrets"
#Component: "secret-store"
#BaseURL: "http://bitwarden-api.bitwarden-api.svc.cluster.local:8087/object"

for k, v in {
	login: url:       "item/{{ .remoteRef.key }}"
	login: result:    "$.data.login.{{ .remoteRef.property }}"

	fields: url:      login.url
	fields: result:   "$.data.fields[?@.name==\"{{ .remoteRef.property }}\"].value"

	notes: url:       login.url
	notes: result:    "$.data.notes"

	attachments: url: "attachment/{{ .remoteRef.property }}?itemid={{ .remoteRef.key }}"
	attachments: contentType: "application/octet-stream"
} {
	webhookClusterSecretStore: "bitwarden-\(k)": {
		spec: provider: webhook: url: "\(#BaseURL)/\(v.url)"
		if v.result != _|_ {
			spec: provider: webhook: result: jsonPath: v.result
		}
		if v.contentType != _|_ {
			spec: provider: webhook: headers: "Content-Type": v.contentType
		}
	}
}
