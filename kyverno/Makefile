.DEFAULT_GOAL := get-upstream
.PHONY: get-upstream

VERSION=v1.13.5

get-upstream:
	curl -LOs https://github.com/kyverno/kyverno/releases/download/${VERSION}/install.yaml
	mv install.yaml upstream/
