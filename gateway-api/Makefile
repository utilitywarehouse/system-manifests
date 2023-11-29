.DEFAULT_GOAL := get-upstream
.PHONY: get-upstream

VERSION=v1.0.0

get-upstream:
	curl -LOs https://github.com/kubernetes-sigs/gateway-api/releases/download/${VERSION}/standard-install.yaml
	mv standard-install.yaml upstream/
