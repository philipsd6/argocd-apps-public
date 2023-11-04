package kube
import "strings"

#Link: {
	name: string | *url
	icon: =~ "^fa-" | *"fa-link"
	url!: =~ "^https?://"
}

#Service: {
	name!: string
	logo!: string
	url!: =~ "^https://"
}

#Config: {
	title!: strings.MaxRunes(18) | *"Homepage"
	title_font!: string | *"Fraktur"
	background: *"trianglify" | "geopattern"
	links: [...#Link]
	services: [...#Service]
}

// This could be used to validate a YAML config file:
//     cue vet config.yaml -d '#Config'
// but that's largely useless, since what I really need is to create a configMap with that yaml file as the contents,
// and have it validated to make sure it's ok at the same time. I'm not sure how to generically support such a workflow.
