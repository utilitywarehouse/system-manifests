.DEFAULT_GOAL := get-upstream
.PHONY: get-upstream

# https://github.com/kubernetes/kubernetes
# 1.14.2
COMMIT_REF=fc1726397e13fadd371b1aabd1b14c222908bfee

get-upstream:
	curl -Ls \
	 https://raw.githubusercontent.com/kubernetes/kubernetes/$(COMMIT_REF)/cluster/addons/dns/coredns/coredns.yaml.sed \
	 > upstream/coredns.yaml
