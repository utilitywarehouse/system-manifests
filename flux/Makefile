.DEFAULT_GOAL := get-upstream


# https://github.com/fluxcd/flux2
VERSION=v0.38.3
TF_CON_VER=v0.13.1

# tool 'yq' can be downloaded from https://github.com/mikefarah/yq


# This will print the type of resources found in the upstream but only required ones are added
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
	
	# replace flux-system with sys-flux
	sd  flux-system sys-flux /tmp/flux.yaml

	# cluster resources 
	yq 'select(.kind=="CustomResourceDefinition")' /tmp/flux.yaml > cluster/upstream/crds.yaml
	yq 'select(.kind=="ClusterRole")' /tmp/flux.yaml > cluster/upstream/cluster-roles.yaml
	yq 'select(.kind=="ClusterRoleBinding")' /tmp/flux.yaml > cluster/upstream/cluster-role-bindings.yaml

	# namespace resources
	yq 'select(.kind=="NetworkPolicy")' /tmp/flux.yaml > namespaced/upstream/network-policies.yaml
	yq 'select(.kind=="Deployment")' /tmp/flux.yaml > namespaced/upstream/deployments.yaml
	yq 'select(.kind=="Service")' /tmp/flux.yaml > namespaced/upstream/services.yaml
	yq 'select(.kind=="ServiceAccount")' /tmp/flux.yaml > namespaced/upstream/service-accounts.yaml

	# remove temp file
	rm  /tmp/flux.yaml


.PHONY: get-tf-controller
get-tf-controller:
	curl -Ls https://github.com/weaveworks/tf-controller/releases/download/${TF_CON_VER}/tf-controller.crds.yaml > tf-controller/cluster/crds.yaml
	curl -Ls https://github.com/weaveworks/tf-controller/releases/download/${TF_CON_VER}/tf-controller.deployment.yaml > tf-controller/namespaced/deployment.yaml
	curl -Ls https://github.com/weaveworks/tf-controller/releases/download/${TF_CON_VER}/tf-controller.rbac.yaml > /tmp/tf-controller.rbac.yaml

	# replace flux-system with sys-flux
	sd flux-system sys-flux /tmp/tf-controller.rbac.yaml

	# cluster resources
	yq 'select(.kind=="ClusterRole")' /tmp/tf-controller.rbac.yaml > tf-controller/cluster/cluster-roles.yaml
	yq 'select(.kind=="ClusterRoleBinding")' /tmp/tf-controller.rbac.yaml > tf-controller/cluster/cluster-role-bindings.yaml


	# namespace resources
	yq 'select(.kind=="ServiceAccount")' /tmp/tf-controller.rbac.yaml > tf-controller/namespaced/services.yaml
	yq 'select(.kind=="Role")' /tmp/tf-controller.rbac.yaml > tf-controller/namespaced/role.yaml
	yq 'select(.kind=="RoleBinding")' /tmp/tf-controller.rbac.yaml > tf-controller/namespaced/role-bindings.yaml
