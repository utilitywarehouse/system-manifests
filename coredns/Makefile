.DEFAULT_GOAL := get-upstream
.PHONY: get-upstream

# https://github.com/coredns/deployment
# 1.9.4
COMMIT_REF=128be7d6cea78fe335898fcaf87ffe85f1f2dc1c

get-upstream:
	curl -Ls \
	 https://raw.githubusercontent.com/coredns/deployment/$(COMMIT_REF)/kubernetes/coredns.yaml.sed \
	 > upstream/coredns.yaml
