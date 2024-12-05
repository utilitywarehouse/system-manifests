.DEFAULT_GOAL := get-upstream
.PHONY: get-upstream

# https://github.com/kubernetes/kubernetes
# 1.11.1
COMMIT_REF=78538bd303d49ddb4c7cb9daaf212fa7d0c75895

get-upstream:
	curl -Ls \
	 https://raw.githubusercontent.com/kubernetes/kubernetes/$(COMMIT_REF)/cluster/addons/dns/coredns/coredns.yaml.sed \
	 > upstream/coredns.yaml
