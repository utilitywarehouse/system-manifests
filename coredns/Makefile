.DEFAULT_GOAL := all
.PHONY: all build echo get-upstream

# 1.8.3
COMMIT_REF=316f8a857c06813cc899267a4428bf5ba4088d87



all: get-upstream echo build

build:
	kustomize build . > final/coredns.yaml

echo:
	@echo

get-upstream:
	curl -Ls \
	 https://raw.githubusercontent.com/coredns/deployment/$(COMMIT_REF)/kubernetes/coredns.yaml.sed \
	 > upstream/coredns.yaml
