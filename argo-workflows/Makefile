.DEFAULT_GOAL := get-upstream

# https://github.com/argoproj/argo-workflows/releases
VERSION=v4.0.1
NAMESPACE=sys-argo-workflows

.PHONY: get-upstream
get-upstream:
	mkdir -p cluster namespaced
	curl -Ls https://github.com/argoproj/argo-workflows/releases/download/${VERSION}/namespace-install.yaml > /tmp/argo.yaml

	yq 'select(.kind == "CustomResourceDefinition")' /tmp/argo.yaml > cluster/crds.yaml
# 	yq 'select(.kind == "ClusterRole")' /tmp/argo.yaml > cluster/clusterrole.yaml
# 	yq 'select(.kind == "ClusterRoleBinding")' /tmp/argo.yaml > cluster/clusterrolebinding.yaml
	yq e 'select(.kind != "CustomResourceDefinition" and .kind != "ClusterRole" and .kind != "ClusterRoleBinding")' /tmp/argo.yaml > namespaced/preview.yaml

