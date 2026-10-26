.DEFAULT_GOAL := help

# Clusters to read discovery from. No default: cluster names do not belong in a
# public repo.
CONTEXTS ?=

# Left out of view-aggregates. RBAC cannot deny, so these are simply not added;
# the built-in `view` role grants none of them either.
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

# Left out of admin-aggregates: these bypass the operator's own API and
# validation, or act outside the namespace that writes them. `*.group` matches
# every resource in that group. The reads stay available through VIEW_EXTRAS.
ADMIN_SKIP_RESOURCES ?= \
	*.actions.github.com \
	*.crd.projectcalico.org \
	*.k6.io \
	*.metallb.io \
	*.trident.netapp.io \
	endpointslices.discovery.k8s.io \
	leases.coordination.k8s.io

# Reads that belong in the read-only role only: cluster scoped resources with no
# write counterpart, and groups we keep out of admin on purpose. `*.group`
# expands to every resource that group serves.
VIEW_EXTRAS ?= \
	*.actions.github.com \
	*.crd.projectcalico.org \
	*.k6.io \
	*.kyverno.io \
	*.metallb.io \
	*.trident.netapp.io \
	appprojects.argoproj.io \
	clusterrolebindings.rbac.authorization.k8s.io \
	clusterroles.rbac.authorization.k8s.io \
	csinodes.storage.k8s.io \
	csidrivers.storage.k8s.io \
	customresourcedefinitions.apiextensions.k8s.io \
	endpointslices.discovery.k8s.io \
	globalnetworksets.projectcalico.org \
	ingressclasses.networking.k8s.io \
	leases.coordination.k8s.io \
	nodes \
	persistentvolumes \
	policyreports.wgpolicyk8s.io \
	priorityclasses.scheduling.k8s.io \
	rolebindings.rbac.authorization.k8s.io \
	roles.rbac.authorization.k8s.io \
	runtimeclasses.node.k8s.io \
	storageclasses.storage.k8s.io \
	tiers.projectcalico.org \
	volumeattachments.storage.k8s.io \
	volumesnapshotcontents.snapshot.storage.k8s.io

export ADMIN_SKIP_RESOURCES VIEW_SKIP_RESOURCES VIEW_EXTRAS

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
