.DEFAULT_GOAL := get-upstream
.PHONY: get-upstream

# https://github.com/kubernetes/kubernetes
# 1.12.1
COMMIT_REF=302a8505833e29db86812b25fdc25fc2167f84fe

get-upstream:
	curl -Ls \
	 https://raw.githubusercontent.com/kubernetes/kubernetes/$(COMMIT_REF)/cluster/addons/dns/coredns/coredns.yaml.sed \
	 > upstream/coredns.yaml
