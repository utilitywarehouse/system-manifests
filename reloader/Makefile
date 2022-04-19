.DEFAULT_GOAL := get-upstream
.PHONY: get-upstream

TAG=v0.0.110

get-upstream:
	wget -O - https://raw.githubusercontent.com/stakater/Reloader/${TAG}/deployments/kubernetes/manifests/deployment.yaml | grep -v namespace > namespaced/deployment.yaml
	wget -O - https://raw.githubusercontent.com/stakater/Reloader/${TAG}/deployments/kubernetes/manifests/serviceaccount.yaml | grep -v namespace > namespaced/serviceaccount.yaml
	wget -O - https://raw.githubusercontent.com/stakater/Reloader/${TAG}/deployments/kubernetes/manifests/clusterrole.yaml | grep -v namespace | sed 's/ClusterRole/Role/g' > namespaced/role.yaml
	wget -O - https://raw.githubusercontent.com/stakater/Reloader/${TAG}/deployments/kubernetes/manifests/clusterrolebinding.yaml | grep -v namespace | sed 's/ClusterRole/Role/g' > namespaced/rolebinding.yaml
