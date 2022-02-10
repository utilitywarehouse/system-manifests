.DEFAULT_GOAL := get-upstream
.PHONY: get-upstream

# 1.9.0
COMMIT_REF=cb075b0a3810ccc0cb83339ddbce4b094c8f499b

get-upstream:
	curl -Ls \
	 https://raw.githubusercontent.com/coredns/deployment/$(COMMIT_REF)/kubernetes/coredns.yaml.sed \
	 > upstream/coredns.yaml
