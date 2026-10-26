.DEFAULT_GOAL := help

# Clusters to read discovery from. No default, because cluster names do not
# belong in a public repo.
CONTEXTS ?=

# Never added to view-aggregates. RBAC cannot deny, so we leave them out; the
# built-in `view` role grants none of them either.
VIEW_SKIP_RESOURCES ?= \
	deployments/rollback \
	nodes/proxy \
	pods/attach \
	pods/ephemeralcontainers \
	pods/eviction \
	pods/exec \
	pods/portforward \
	pods/proxy \
	secrets \
	services/proxy

# Not added to admin-aggregates: these skip the operator's own API and
# validation, or act outside the namespace that writes them. `*.group` covers the
# whole group. View still reads them.
ADMIN_SKIP_RESOURCES ?= \
	*.actions.github.com \
	*.crd.projectcalico.org \
	*.k6.io \
	*.metallb.io \
	*.trident.netapp.io \
	endpointslices.discovery.k8s.io \
	leases.coordination.k8s.io

# Added on top of what the built-in `admin` role covers, one per line as
# `resource.group`. Use it for grants discovery cannot see: subresources,
# cluster-scoped resources, and writes the built-in role only reads.
ADMIN_EXTRA ?= \
	limitranges \
	pods/ephemeralcontainers \
	pods/eviction

# Rules the pair model cannot express, appended to admin-aggregates.yaml as
# JSON. Keep this rare: everything else is derived from discovery.
ADMIN_EXTRA_RULES ?= \
	[{"apiGroups":["projectcalico.org"],"resources":["tier.networkpolicies"],"resourceNames":["default.*"],"verbs":["*"]}]

export ADMIN_EXTRA ADMIN_EXTRA_RULES ADMIN_SKIP_RESOURCES VIEW_SKIP_RESOURCES

.PHONY: help gen check require-contexts

help:
	@echo "Targets:"
	@echo "  gen    rewrite admin-aggregates.yaml and view-aggregates.yaml"
	@echo "  check  fail if a cluster serves something the files are missing"
	@echo
	@echo "Both read discovery, so they need the clusters to query:"
	@echo "  make gen CONTEXTS=\"cluster-a cluster-b\""
	@echo "  make check CONTEXTS=\"cluster-a cluster-b\""

require-contexts:
	@if [ -z "$(CONTEXTS)" ]; then \
		echo 'error: CONTEXTS is not set, e.g. make gen CONTEXTS="cluster-a cluster-b"' >&2; \
		exit 1; \
	fi

gen: require-contexts
	@for c in $(CONTEXTS); do ./rbac.sh gen -c "$$c"; done

check: require-contexts
	@fail=0; \
	for c in $(CONTEXTS); do \
		echo "== $$c"; \
		./rbac.sh check -c "$$c" || fail=1; \
	done; \
	exit $$fail
