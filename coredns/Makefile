.DEFAULT_GOAL := get-upstream
.PHONY: get-upstream

# https://github.com/coredns/deployment
# 1.9.2
COMMIT_REF=19d203a1c92a80d21fb4e360183a355b9c1da6de

get-upstream:
	curl -Ls \
	 https://raw.githubusercontent.com/coredns/deployment/$(COMMIT_REF)/kubernetes/coredns.yaml.sed \
	 > upstream/coredns.yaml
