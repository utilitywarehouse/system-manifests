.DEFAULT_GOAL := get-upstream
.PHONY: get-upstream

VERSION=v1.19.1

get-upstream:
	curl -fsSLO https://github.com/kyverno/kyverno/releases/download/${VERSION}/install.yaml
	mv install.yaml upstream/
