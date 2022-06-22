.DEFAULT_GOAL := get-upstream
.PHONY: get-upstream

# https://github.com/coredns/deployment
# 1.9.3
COMMIT_REF=6135cc08f48270fc4f0cea141692db621e362c85

get-upstream:
	curl -Ls \
	 https://raw.githubusercontent.com/coredns/deployment/$(COMMIT_REF)/kubernetes/coredns.yaml.sed \
	 > upstream/coredns.yaml
