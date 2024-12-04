.DEFAULT_GOAL := get-upstream
.PHONY: get-upstream

# https://github.com/kubernetes/kubernetes
# 1.12.0
COMMIT_REF=7429380b1cacebde73084ad3cb6fb676c69bd6b8

get-upstream:
	curl -Ls \
	 https://raw.githubusercontent.com/kubernetes/kubernetes/$(COMMIT_REF)/cluster/addons/dns/coredns/coredns.yaml.sed \
	 > upstream/coredns.yaml
