.DEFAULT_GOAL := fetch-upstream
.PHONY: fetch-upstream

SHELL := /bin/bash

fetch-upstream:
	mkdir -p upstream; \
	latest=$$(curl -s https://api.github.com/repos/weaveworks/kured/releases | jq -r .[0].tag_name); \
	echo "fetching latest kured version: $$latest under upstream/ dir"; \
	curl -sL https://github.com/weaveworks/kured/releases/download/$$latest/kured-$$latest-dockerhub.yaml -o upstream/kured-$$latest-upstream.yaml
