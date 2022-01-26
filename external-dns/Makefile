.DEFAULT_GOAL := get-upstream
.PHONY: get-upstream

# v0.10.2
COMMIT_REF=c226aa9c90d7d6d76c956ef4c7af6323027bf156

#VERSION=v0.10.2
## Using a later commit instead of the tagged version, because the release did not update the image.
## https://github.com/kubernetes-sigs/external-dns/tree/69e0e54844ac8c2133854d5ab2a569f643786be6/kustomize

get-upstream:
	curl -LOs https://raw.githubusercontent.com/kubernetes-sigs/external-dns/$(COMMIT_REF)/kustomize/external-dns-clusterrole.yaml
	curl -LOs https://raw.githubusercontent.com/kubernetes-sigs/external-dns/$(COMMIT_REF)/kustomize/external-dns-clusterrolebinding.yaml
	curl -LOs https://raw.githubusercontent.com/kubernetes-sigs/external-dns/$(COMMIT_REF)/kustomize/external-dns-deployment.yaml
	curl -LOs https://raw.githubusercontent.com/kubernetes-sigs/external-dns/$(COMMIT_REF)/kustomize/external-dns-serviceaccount.yaml
	mv -fv external-dns-* upstream/
