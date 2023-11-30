.DEFAULT_GOAL := get-upstream

# https://github.com/argoproj/argo-cd
VERSION=v2.9.2

# tool 'yq' can be downloaded from https://github.com/mikefarah/yq

# This fetches manifests from upstream and splits resources into cluster/ and
# namespaced/ directories based on type of resources. 
.PHONY: get-upstream
get-upstream:
	curl -Ls https://raw.githubusercontent.com/argoproj/argo-cd/$(VERSION)/manifests/ha/install.yaml > /tmp/argo.yaml

	# replace namespace
	sd "namespace: argocd" "namespace: sys-argocd" /tmp/argo.yaml
	
	# Filter out dex and applicationset resoruces
	yq 'select(.metadata.name != "argocd-dex-server*" and .metadata.name != "argocd-applicationset*")' /tmp/argo.yaml > /tmp/argo_filtered.yaml

	# cluster resources
	yq 'select(.kind=="CustomResourceDefinition")' /tmp/argo_filtered.yaml > cluster/upstream/CustomResourceDefinition.yaml
	yq 'select(.kind=="ClusterRole")' /tmp/argo_filtered.yaml > cluster/upstream/ClusterRole.yaml
	yq 'select(.kind=="ClusterRoleBinding")' /tmp/argo_filtered.yaml > cluster/upstream/ClusterRoleBinding.yaml

	# namespace resources
	yq 'select(.kind=="Deployment")' /tmp/argo_filtered.yaml > namespaced/upstream/Deployment.yaml
	yq 'select(.kind=="StatefulSet")' /tmp/argo_filtered.yaml > namespaced/upstream/StatefulSet.yaml
	yq 'select(.kind=="Role")' /tmp/argo_filtered.yaml > namespaced/upstream/Role.yaml
	yq 'select(.kind=="RoleBinding")' /tmp/argo_filtered.yaml > namespaced/upstream/RoleBinding.yaml
	yq 'select(.kind=="Secret")' /tmp/argo_filtered.yaml > namespaced/upstream/Secret.yaml
	yq 'select(.kind=="Service")' /tmp/argo_filtered.yaml > namespaced/upstream/Service.yaml
	yq 'select(.kind=="ServiceAccount")' /tmp/argo_filtered.yaml > namespaced/upstream/ServiceAccount.yaml
	yq 'select(.kind=="ConfigMap")' /tmp/argo_filtered.yaml > namespaced/upstream/ConfigMap.yaml
	yq 'select(.kind=="NetworkPolicy")' /tmp/argo_filtered.yaml > namespaced/upstream/NetworkPolicy.yaml

	# remove temp file
	rm /tmp/argo.yaml /tmp/argo_filtered.yaml
