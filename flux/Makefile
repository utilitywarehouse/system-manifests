.DEFAULT_GOAL := get-upstream


# https://github.com/fluxcd/flux2
VERSION=v0.32.0

# tool 'yq' can be downloaded from https://github.com/mikefarah/yq


# This will print type of resources found in upstream but only required once are added
.PHONY: get-upstream-resource-types
get-upstream-resource-types:
	curl -Ls https://github.com/fluxcd/flux2/releases/download/$(VERSION)/install.yaml > /tmp/flux.yaml
	cat /tmp/flux.yaml | rg ^kind: | uniq
	rm  /tmp/flux.yaml

# This fetches manifests from upstream and splits resources into cluster/ and
# namespaced/ directories based on type of resources. 
.PHONY: get-upstream
get-upstream:
	curl -Ls https://github.com/fluxcd/flux2/releases/download/$(VERSION)/install.yaml > /tmp/flux.yaml
	
	# replace flux-system with sys-flux (extra "" is needed in MacOS)
	sed -i "" 's/flux-system/sys-flux/g' /tmp/flux.yaml

	# cluster resources 
	yq 'select(.kind=="CustomResourceDefinition")' /tmp/flux.yaml > cluster/upstream/crds.yaml
	yq 'select(.kind=="ClusterRole")' /tmp/flux.yaml > cluster/upstream/cluster-roles.yaml

	# namespace resources
	yq 'select(.kind=="NetworkPolicy")' /tmp/flux.yaml > namespaced/upstream/network-policies.yaml
	yq 'select(.kind=="Deployment")' /tmp/flux.yaml > namespaced/upstream/deployments.yaml
	yq 'select(.kind=="Service")' /tmp/flux.yaml > namespaced/upstream/services.yaml
	yq 'select(.kind=="ServiceAccount")' /tmp/flux.yaml > namespaced/upstream/service-accounts.yaml
	yq 'select(.kind=="ClusterRoleBinding")' /tmp/flux.yaml > namespaced/upstream/cluster-role-bindings.yaml

	# remove temp file
	rm  /tmp/flux.yaml
