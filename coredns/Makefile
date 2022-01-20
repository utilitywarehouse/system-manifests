.DEFAULT_GOAL := get-upstream
.PHONY: get-upstream

# 1.8.6
COMMIT_REF=8e13ce82cc607c53551dfe3ab40aef788a69c1ac

get-upstream:
	curl -Ls \
	 https://raw.githubusercontent.com/coredns/deployment/$(COMMIT_REF)/kubernetes/coredns.yaml.sed \
	 > upstream/coredns.yaml
