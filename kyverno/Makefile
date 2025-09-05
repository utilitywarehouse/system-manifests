.DEFAULT_GOAL := get-upstream
.PHONY: get-upstream

VERSION=v1.15.1

get-upstream:
	curl -LOs https://github.com/kyverno/kyverno/releases/download/${VERSION}/install.yaml
	mv install.yaml upstream/
