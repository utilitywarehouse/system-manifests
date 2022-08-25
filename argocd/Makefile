.DEFAULT_GOAL := get-upstream

# https://github.com/argoproj/argo-cd
VERSION=v2.4.11

# tool 'yq' can be downloaded from https://github.com/mikefarah/yq

# This will print the type of resources found in the upstream
.PHONY: get-upstream-info
get-upstream-info:
	@curl -Ls https://raw.githubusercontent.com/argoproj/argo-cd/$(VERSION)/manifests/ha/install.yaml > /tmp/argo.yaml
	@echo "count of unique resource types"
	@cat /tmp/argo.yaml | rg ^kind: | uniq -c
	@echo
	@echo "Deployment/StatefulSet Names"
	@yq 'select(.kind=="Deployment")' /tmp/argo.yaml | yq '.metadata.name'
	@yq 'select(.kind=="StatefulSet")' /tmp/argo.yaml | yq '.metadata.name'
	@rm  /tmp/argo.yaml

# This fetches manifests from upstream and splits resources into cluster/ and
# namespaced/ directories based on type of resources. 
.PHONY: get-upstream
get-upstream:
	curl -Ls https://raw.githubusercontent.com/argoproj/argo-cd/$(VERSION)/manifests/ha/install.yaml > /tmp/argo.yaml

	# replace namespace
	sd  "namespace: argocd" "namespace: sys-argocd" /tmp/argo.yaml
	
	# cluster resources
	yq 'select(.kind=="CustomResourceDefinition")' /tmp/argo.yaml > cluster/upstream/CustomResourceDefinition.yaml
	yq 'select(.kind=="ClusterRole")' /tmp/argo.yaml > cluster/upstream/ClusterRole.yaml
	yq 'select(.kind=="ClusterRoleBinding")' /tmp/argo.yaml > cluster/upstream/ClusterRoleBinding.yaml

	# namespace resources
	yq 'select(.kind=="Deployment")' /tmp/argo.yaml > namespaced/upstream/Deployment.yaml
	yq 'select(.kind=="StatefulSet")' /tmp/argo.yaml > namespaced/upstream/StatefulSet.yaml
	yq 'select(.kind=="Role")' /tmp/argo.yaml > namespaced/upstream/Role.yaml
	yq 'select(.kind=="RoleBinding")' /tmp/argo.yaml > namespaced/upstream/RoleBinding.yaml
	yq 'select(.kind=="Secret")' /tmp/argo.yaml > namespaced/upstream/Secret.yaml
	yq 'select(.kind=="Service")' /tmp/argo.yaml > namespaced/upstream/Service.yaml
	yq 'select(.kind=="ServiceAccount")' /tmp/argo.yaml > namespaced/upstream/ServiceAccount.yaml
	yq 'select(.kind=="ConfigMap")' /tmp/argo.yaml > namespaced/upstream/ConfigMap.yaml
	yq 'select(.kind=="NetworkPolicy")' /tmp/argo.yaml > namespaced/upstream/NetworkPolicy.yaml

	# remove temp file
	rm  /tmp/argo.yaml
