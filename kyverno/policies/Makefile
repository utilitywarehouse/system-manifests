SHELL := /bin/bash

KYVERNO = reg.kyverno.io/kyverno/kyverno-cli:latest
# policy tests references custom CRDs from diff base
repo_base_path = $(shell git rev-parse --show-toplevel)

.PHONY: test test-dir

test:
	docker run -v "${repo_base_path}":"${repo_base_path}" --workdir="${repo_base_path}" ${KYVERNO} test "${repo_base_path}/kyverno/policies"

test-dir:
	@TARGET_PATH=$(filter-out $@,$(MAKECMDGOALS)); \
	if [ -z "$$TARGET_PATH" ]; then \
		echo "Error: path not specified. Usage: make test-dir path/to/policies"; \
		exit 1; \
	fi; \
	docker run -v "${repo_base_path}:${repo_base_path}" --workdir="${repo_base_path}" ${KYVERNO} test "${repo_base_path}/$$TARGET_PATH"
