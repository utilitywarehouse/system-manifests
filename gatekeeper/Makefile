SHELL := /bin/bash
HELM_VERSION=3.7.1

# Comma separated list of supported api versions
#
# Needed to pass helm capability checks like https://github.com/open-policy-agent/gatekeeper/blob/master/charts/gatekeeper/templates/gatekeeper-controller-manager-poddisruptionbudget.yaml#L1
API_VERSIONS=policy/v1/PodDisruptionBudget,

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
	helm template --api-versions={$(API_VERSIONS)} --release-name --include-crds --set postInstall.labelNamespace.enabled=false --no-hooks gatekeeper gatekeeper-$(HELM_VERSION).tgz | \
		yq eval 'select(.metadata | has("namespace") | not) | select(.kind != "ClusterRoleBinding")' - \
		> cluster/upstream/gatekeeper.yaml

.PHONY: helm-namespaced
helm-namespaced: helm-fetch
	# - Select resources with a namespace field
	# - Exclude RoleBindings (should be set in the overlay)
	# - Remove the namespace field
	helm template --api-versions={$(API_VERSIONS)} --release-name gatekeeper --set postInstall.labelNamespace.enabled=false --set resourceQuota=false --no-hooks gatekeeper-$(HELM_VERSION).tgz | \
		yq eval 'select(.metadata | has("namespace")) | select(.kind != "RoleBinding") | del(.metadata.namespace)' - \
		> namespaced/upstream/gatekeeper.yaml
