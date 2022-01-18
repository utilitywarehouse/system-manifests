.DEFAULT_GOAL := all
.PHONY: all build echo get-upstream

version=v0.11.0



all: get-upstream echo build

build: build-cluster build-namespaced

build-cluster:
	kustomize build ./cluster    > final-cluster/metallb-cluster.yaml

build-namespaced:
	kustomize build ./namespaced > final-namespaced/metallb-namespaced.yaml

echo:
	@echo

get-upstream:
	curl -Ls \
	 https://raw.githubusercontent.com/metallb/metallb/$(version)/manifests/metallb.yaml \
	 > upstream/metallb.yaml
