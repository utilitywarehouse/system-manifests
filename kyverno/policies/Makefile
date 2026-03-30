SHELL := /bin/bash

KYVERNO = reg.kyverno.io/kyverno/kyverno-cli:latest


.PHONY: test test-dir

test:
# 	docker run -v "${PWD}":"${PWD}" --workdir="${PWD}" ${KYVERNO} test .

test-dir:
	@TARGET_PATH=$(filter-out $@,$(MAKECMDGOALS)); \
	if [ -z "$$TARGET_PATH" ]; then \
		echo "Error: path not specified. Usage: make test-dir path/to/policies"; \
		exit 1; \
	fi; \
	docker run -v "${PWD}:${PWD}" --workdir="${PWD}" ${KYVERNO} test "$$TARGET_PATH"
