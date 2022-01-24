.DEFAULT_GOAL := get-upstream
.PHONY: get-upstream

# v0.10.1
COMMIT_REF=c226aa9c90d7d6d76c956ef4c7af6323027bf156

get-upstream:
	curl -LOs https://raw.githubusercontent.com/kubernetes-sigs/external-dns/$(COMMIT_REF)/kustomize/external-dns-clusterrole.yaml
	curl -LOs https://raw.githubusercontent.com/kubernetes-sigs/external-dns/$(COMMIT_REF)/kustomize/external-dns-clusterrolebinding.yaml
	curl -LOs https://raw.githubusercontent.com/kubernetes-sigs/external-dns/$(COMMIT_REF)/kustomize/external-dns-deployment.yaml
	curl -LOs https://raw.githubusercontent.com/kubernetes-sigs/external-dns/$(COMMIT_REF)/kustomize/external-dns-serviceaccount.yaml
	mv external-dns-* upstream/
