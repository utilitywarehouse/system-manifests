.DEFAULT_GOAL := get-upstream
.PHONY: get-upstream

# https://github.com/kubernetes/kubernetes
# 1.14.1
COMMIT_REF=1713d43d13623a0c2e31cbc30bd5fca0f58fc229

get-upstream:
	curl -Ls \
	 https://raw.githubusercontent.com/kubernetes/kubernetes/$(COMMIT_REF)/cluster/addons/dns/coredns/coredns.yaml.sed \
	 > upstream/coredns.yaml
