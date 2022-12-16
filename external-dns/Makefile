.DEFAULT_GOAL := get-upstream
.PHONY: get-upstream

# v0.13.1
COMMIT_REF=de3474436fd84b825dfcac9eb2f0d1f14804a5d3

#VERSION=v0.12.2
## Using a later commit instead of the tagged version, because the release did not update the image.
## https://github.com/kubernetes-sigs/external-dns/commit/bb2606c50d1f602895795e945891c29f5418dd22

get-upstream:
	curl -LOs https://raw.githubusercontent.com/kubernetes-sigs/external-dns/$(COMMIT_REF)/kustomize/external-dns-clusterrole.yaml
	curl -LOs https://raw.githubusercontent.com/kubernetes-sigs/external-dns/$(COMMIT_REF)/kustomize/external-dns-clusterrolebinding.yaml
	curl -LOs https://raw.githubusercontent.com/kubernetes-sigs/external-dns/$(COMMIT_REF)/kustomize/external-dns-deployment.yaml
	curl -LOs https://raw.githubusercontent.com/kubernetes-sigs/external-dns/$(COMMIT_REF)/kustomize/external-dns-serviceaccount.yaml
	mv -fv external-dns-* upstream/
