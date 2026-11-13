.DEFAULT_GOAL := gen-manifests

CHART_VERSION=4.7.0

# Objects chart 4.7.0 renders that this deployment does not use:
#   k6-operator-metrics-*  RBAC for the metrics endpoint; nothing scrapes it
#                          (the Service itself is disabled in values.yaml)
#   privateloadzone-*      convenience end-user roles, never bound to anything
UNUSED_REGEX := k6-operator-metrics-reader|k6-operator-metrics-auth-role|k6-operator-metrics-auth-rolebinding|privateloadzone-editor-role|privateloadzone-viewer-role

.PHONY: gen-manifests
gen-manifests:
	helm repo list | grep -q '^grafana' || helm repo add grafana https://grafana.github.io/helm-charts
	helm repo update > /dev/null
	helm template k6-operator --namespace sys-k6 -f values.yaml grafana/k6-operator --version $(CHART_VERSION) > /tmp/k6-operator-og.yaml

	# rbac.namespaced=true already gives us namespaced Role/RoleBinding objects.
	yq 'select(.metadata.name | test("^($(UNUSED_REGEX))$$") | not)' /tmp/k6-operator-og.yaml > /tmp/k6-operator.yaml

	# CRDs are cluster-scoped, everything else is namespaced.
	yq 'select(.kind=="CustomResourceDefinition" and .metadata.name=="privateloadzones.k6.io")' /tmp/k6-operator.yaml > cluster/privateLoadZones.yaml
	yq 'select(.kind=="CustomResourceDefinition" and .metadata.name=="testruns.k6.io")' /tmp/k6-operator.yaml > cluster/testRun.yaml

	# One multi-document file per kind: manager + leader-election role/binding.
	yq 'select(.kind=="Role")' /tmp/k6-operator.yaml > namespaced/role.yaml
	yq 'select(.kind=="RoleBinding")' /tmp/k6-operator.yaml > namespaced/roleBinding.yaml
	yq 'select(.kind=="ServiceAccount")' /tmp/k6-operator.yaml > namespaced/serviceAccount.yaml
	yq 'select(.kind=="Deployment")' /tmp/k6-operator.yaml > namespaced/deployment.yaml
