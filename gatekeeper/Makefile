SHELL := /bin/bash
HELM_VERSION=3.4.0

.PHONY: helm
helm: helm-fetch helm-cluster helm-namespaced

.PHONY: helm-fetch
helm-fetch:
	helm repo add gatekeeper https://open-policy-agent.github.io/gatekeeper/charts
	helm repo update
	helm fetch --version=$(HELM_VERSION) 'gatekeeper/gatekeeper'

.PHONY: helm-cluster
helm-cluster: helm-fetch
	# - Select resources without a namespace field
	# - Exclude ClusterRoleBindings (should be set in the overlay)
	helm template --release-name --include-crds --set postInstall.labelNamespace.enabled=false gatekeeper gatekeeper-$(HELM_VERSION).tgz | \
		yq eval 'select(.metadata | has("namespace") | not) | select(.kind != "ClusterRoleBinding")' - \
		> cluster/gatekeeper.yaml

.PHONY: helm-namespaced
helm-namespaced: helm-fetch
	# - Select resources with a namespace field
	# - Exclude RoleBindings (should be set in the overlay)
	# - Remove the namespace field
	helm template --release-name gatekeeper --set postInstall.labelNamespace.enabled=false gatekeeper-$(HELM_VERSION).tgz | \
		yq eval 'select(.metadata | has("namespace")) | select(.kind != "RoleBinding") | del(.metadata.namespace)' - \
		> namespaced/gatekeeper.yaml
