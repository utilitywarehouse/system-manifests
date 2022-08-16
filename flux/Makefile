.DEFAULT_GOAL := get-upstream
.PHONY: get-upstream

# https://github.com/fluxcd/flux2
VERSION=v0.32.0

get-upstream:
	curl -Ls \
	 https://github.com/fluxcd/flux2/releases/download/$(VERSION)/install.yaml \
	 > base/upstream/flux.yaml
