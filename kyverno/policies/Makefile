SHELL := /bin/bash

.PHONY: build test test-dir

build:
	docker build -t kyverno-test .

test: build
	docker run -v "${PWD}":"${PWD}" --workdir="${PWD}" kyverno-test kyverno test ./../../

test-dir: build
	@TARGET_PATH=$(filter-out $@,$(MAKECMDGOALS)); \
	if [ -z "$$TARGET_PATH" ]; then \
		echo "Error: path not specified. Usage: make test-dir path/to/policies"; \
		exit 1; \
	fi; \
	docker run -v "${PWD}:${PWD}" --workdir="${PWD}" kyverno-test kyverno test "$$TARGET_PATH"
