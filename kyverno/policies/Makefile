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

# Make 'help' the default target if no target is specified
.DEFAULT_GOAL := help

.PHONY: help
help:
	@echo "Kyverno Policies - Chainsaw Test Runner"
	@echo "======================================="
	@echo "Usage: make <target> [VARIABLES]"
	@echo ""
	@echo "Core Targets:"
	@echo "  test-all      Run all chainsaw tests across all policies."
	@echo "  test-target   Run tests for a specific policy directory. (Requires DIR=<name>)"
	@echo "  clean         Destroy the persistent kind cluster and remove debug kubeconfigs."
	@echo ""
	@echo "Variables for Local Dev:"
	@echo "  DIR           Target directory for 'test-target' (e.g., DIR=argocd)."
	@echo "  REUSE_CLUSTER Set to 'true' to speed up testing by skipping cluster teardown."
	@echo "                MUST be used if you need to run kubectl commands to debug failures."
	@echo "                NOTE: Requires running 'make clean' manually when finished."
	@echo ""
	@echo "Debugging (When REUSE_CLUSTER=true):"
	@echo "  To run kubectl commands against the persistent test cluster from your host:"
	@echo "  make kubectl CMD=\"get pods -n kyverno\""
	@echo ""
	@echo "Examples:"
	@echo "  make test-all"
	@echo "  make test-target DIR=pod-security"
	@echo "  make test-target DIR=argocd REUSE_CLUSTER=true"
	@echo "  make kubectl CMD=\"get pods -n kyverno\""

IMAGE_NAME := chainsaw-test-image
REPO_DIR := $(shell git rev-parse --show-toplevel)

REUSE_CLUSTER ?= false


.PHONY: build
build:
	@echo "Building test runner image..."
	docker build -t $(IMAGE_NAME) .

.PHONY: setup-network
setup-network:
	@docker network inspect kind >/dev/null 2>&1 || docker network create kind

.PHONY: test-all
test-all: build setup-network
	@echo "Running ALL chainsaw tests (Reuse: $(REUSE_CLUSTER))..."
	docker run --rm \
		--name chainsaw-runner \
		--network kind \
		-e REUSE_CLUSTER=$(REUSE_CLUSTER) \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v $(REPO_DIR):/repo \
		$(IMAGE_NAME) "kyverno/policies"

.PHONY: test-target
test-target: build setup-network
	@if [ -z "$(DIR)" ]; then \
		echo "Error: DIR is not set. Usage: make test-target DIR=argocd"; \
		exit 1; \
	fi
	@echo "Running tests for: kyverno/policies/$(DIR) (Reuse: $(REUSE_CLUSTER))"
	docker run --rm \
		--name chainsaw-runner \
		--network kind \
		-e REUSE_CLUSTER=$(REUSE_CLUSTER) \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v $(REPO_DIR):/repo \
		$(IMAGE_NAME) "kyverno/policies/$(DIR)"

.PHONY: clean
clean: setup-network
	@docker run --rm \
		--network kind \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v $(REPO_DIR):/repo \
		$(IMAGE_NAME) "clean"

.PHONY: kubectl
kubectl:
	@if [ -z "$(CMD)" ]; then \
		echo "Error: CMD is not set. Usage: make kubectl CMD=\"get ns\""; \
		exit 1; \
	fi
	@docker exec -it -e KUBECONFIG=/tmp/kubeconfig chainsaw-runner kubectl $(CMD)