.DEFAULT_GOAL := help

# No default: this repo is public, so the cluster names stay with the operator.
#   make gen CONTEXTS="cluster-a cluster-b"
CONTEXTS ?=

# Reads the MCP must never have: secret values, the container/pod/network
# escapes, and write actions that upstream happens to list with read verbs.
# rbac.sh withholds these when it generates the role.
DENY_RESOURCES ?= secrets pods/exec pods/attach pods/portforward pods/proxy \
                  services/proxy pods/ephemeralcontainers nodes/proxy \
                  pods/eviction deployments/rollback

# Cluster scoped reads a namespace admin does not get but debugging wants.
# group/resource form; nothing here is namespaced.
CLUSTER_EXTRAS ?= storage.k8s.io/storageclasses storage.k8s.io/csidrivers \
                  networking.k8s.io/ingressclasses \
                  apiextensions.k8s.io/customresourcedefinitions

export DENY_RESOURCES
export CLUSTER_EXTRAS

.PHONY: help gen check require-contexts

help:
	@echo "gen    rebuild mcp-kube-extras.yaml from the clusters in CONTEXTS"
	@echo "check  fail if a cluster needs a read the committed role lacks"
	@echo
	@echo 'Pass CONTEXTS on every run, e.g. make gen CONTEXTS="cluster-a cluster-b"'

# Cluster names are not committed; refuse to run without them instead of
# silently doing nothing.
require-contexts:
	@[ -n "$(CONTEXTS)" ] || { \
	  echo 'error: CONTEXTS is not set, e.g. make gen CONTEXTS="cluster-a cluster-b"' >&2; \
	  exit 1; \
	}

# Additive by design: a cluster that serves fewer CRDs cannot remove access
# another cluster needs.
gen: require-contexts
	@for c in $(CONTEXTS); do \
	  echo "== $$c"; \
	  ./rbac.sh gen -c $$c || exit 1; \
	done

check: require-contexts
	@fail=0; for c in $(CONTEXTS); do \
	  echo "== $$c"; \
	  ./rbac.sh check -c $$c || fail=1; \
	done; \
	exit $$fail
