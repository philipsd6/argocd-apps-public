package kube

#App:       "postgres"
#Component: "database"
#Image:     "postgres:16.0"

configMap: env: data: {
	// not sure why OPERATOR_NAME is here... doesn't seem to be needed at all...
	OPERATOR_NAME:             "postgres-user-operator"
	POSTGRES_HOST_AUTH_METHOD: "trust"
}

#BitwardenID: "8943ae5a-360b-454b-a8e3-f414b64d43f1"
externalSecret: postgres: spec: target: name: "env"
externalSecret: postgres: spec: secretStoreRef: name: "bitwarden-login"
externalSecret: postgres: spec: data: [{
	remoteRef: property: "username"
}, {
	remoteRef: property: "password"
}]
externalSecret: postgres: spec: target: template: data: {
	POSTGRES_USERNAME: "{{ .username }}"
	POSTGRES_PASSWORD: "{{ .password }}"
}

// This is my user operator managing the PostgreSQLUser CRD!
deployment: "postgres-user-operator": metadata: labels: "app.kubernetes.io/component": "postgres-user-operator"
deployment: "postgres-user-operator": spec: template: spec: containers: [{
	image: "ghcr.io/philipsd6/postgres-user-operator"
	envFrom: [{secretRef: name: "env"}]
	env: [{
		name: "POSTGRES_NAMESPACE"
		valueFrom: fieldRef: fieldPath: "metadata.namespace"
	}]
}]
// We need the cluster service token for the operator
deployment: "postgres-user-operator": spec: template: spec: automountServiceAccountToken: true

statefulSet: postgres: spec: template: spec: containers: [{
	image: "\(#Image)"
	envFrom: [
		{configMapRef: name: "env"},
		{secretRef: name: "env"},
	]
	ports: [{
		_expose:       false
		containerPort: 5432
		name:          "tcp-postgresql"
	}]
	resources: requests: cpu:    "250m"
	resources: requests: memory: "256Mi"
	volumeMounts: [{
		mountPath: "/dev/shm"
		name:      "dshm"
		_empty:    true
	}, {
		mountPath: "/var/lib/postgresql/data"
		name:      "data"
	}]
}]

// Use this annotation in addition to the actual publishNotReadyAddresses
// field below because the annotation will stop being respected soon but the
// field is broken in some versions of Kubernetes:
// https://github.com/kubernetes/kubernetes/issues/58662
service: postgres: metadata: annotations: "service.alpha.kubernetes.io/tolerate-unready-endpoints": "true"

// We want all pods in the StatefulSet to have their addresses published for
// the sake of the other Postgresql pods even before they're ready, since they
// have to be able to talk to each other in order to become ready.
service: postgres: spec: publishNotReadyAddresses: true
