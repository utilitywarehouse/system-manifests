.DEFAULT_GOAL := get-upstream
.PHONY: get-upstream

TAG=v1.0.94

get-upstream:
	curl -sL https://raw.githubusercontent.com/stakater/Reloader/${TAG}/deployments/kubernetes/manifests/deployment.yaml | grep -v namespace > kube-system/deployment.yaml
	curl -sL https://raw.githubusercontent.com/stakater/Reloader/${TAG}/deployments/kubernetes/manifests/serviceaccount.yaml | grep -v namespace > kube-system/serviceaccount.yaml
	curl -sL https://raw.githubusercontent.com/stakater/Reloader/${TAG}/deployments/kubernetes/manifests/clusterrole.yaml | grep -v namespace > kube-system/clusterrole.yaml
	curl -sL https://raw.githubusercontent.com/stakater/Reloader/${TAG}/deployments/kubernetes/manifests/clusterrolebinding.yaml | grep -v namespace > kube-system/clusterrolebinding.yaml
