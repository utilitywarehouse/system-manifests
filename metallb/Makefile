.DEFAULT_GOAL := all
.PHONY: all build get-upstream

version=v0.11.0



all: get-upstream

build:
	# TODO
	@echo
	kustomize build ./namespaced > final/metallb-namespaced.yaml
	kustomize build ./cluster    > final/metallb-cluster.yaml

get-upstream:
	@echo
	curl -Ls \
	 https://raw.githubusercontent.com/metallb/metallb/$(version)/manifests/metallb.yaml \
	 > upstream/metallb.yaml
