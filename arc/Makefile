VERSION=0.14.2
NAMESPACE=sys-actions

# https://github.com/actions/runner/pkgs/container/actions-runner
RUNNER_UPSTREAM_VERSION=2.336.0
UW_RUNNER_IMAGE_REVISION=1
UW_RUNNER_IMAGE_VERSION=$(RUNNER_UPSTREAM_VERSION)-$(UW_RUNNER_IMAGE_REVISION)

.DEFAULT_GOAL := generate-manifests
.PHONY: generate-manifests
generate-manifests: controller runners

.PHONY: controller
controller:
	helm template arc --namespace $(NAMESPACE) --include-crds --values controller/values.yaml oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller --version $(VERSION) > /tmp/arc-controller.yaml

	yq 'select(.kind == "CustomResourceDefinition")' /tmp/arc-controller.yaml > controller/cluster/crds.yaml
	yq 'select(.kind == "ClusterRole")' /tmp/arc-controller.yaml > controller/cluster/clusterrole.yaml
	yq 'select(.kind == "ClusterRoleBinding")' /tmp/arc-controller.yaml > controller/cluster/clusterrolebinding.yaml

	yq 'select(.kind != "CustomResourceDefinition" and .kind != "ClusterRole" and .kind != "ClusterRoleBinding")' /tmp/arc-controller.yaml > /tmp/arc-controller-namespaced.yaml
	# Remove empty yaml documents by generated a unified yaml document and splitting it back
	yq ea '[.]' /tmp/arc-controller-namespaced.yaml | yq '.[] | select(.Pulled == null) | split_doc' > controller/namespaced/generated-manifests.yaml

.PHONY: runner-image-version
runner-image-version:
	@sed -i "s|^FROM ghcr.io/actions/actions-runner:.*|FROM ghcr.io/actions/actions-runner:$(RUNNER_UPSTREAM_VERSION)|" Dockerfile; \
	sed -i "s/^\(\s*version: \).*/\1$(UW_RUNNER_IMAGE_VERSION)/" ../.github/workflows/build-arc.yaml; \
	sed -i "s|quay.io/utilitywarehouse/actions-runner:.*|quay.io/utilitywarehouse/actions-runner:$(UW_RUNNER_IMAGE_VERSION)|" runner/system-dev-merit/values.yaml runner/system-prod-merit/values.yaml; \
	echo "UW_RUNNER_IMAGE_VERSION=$(UW_RUNNER_IMAGE_VERSION)"

.PHONY: runners
runners: runner-image-version
	# Removing the cleanup finalizers becuase the arc controller doesn't
	# clean them up when the pod is killed, and we have argocd to take care
	# of cleanup anyway.

	$(eval RUNNER=system-exp-merit)
	helm template \
		oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set --version $(VERSION) \
		--namespace $(NAMESPACE) \
		--values runner/common-values.yaml --values runner/$(RUNNER)/values.yaml | yq 'select(.Pulled == null) | del(.metadata.finalizers)' \
		> runner/$(RUNNER)/generated-manifests.yaml

	$(eval RUNNER=system-dev-merit)
	helm template \
		oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set --version $(VERSION) \
		--namespace $(NAMESPACE) \
		--values runner/common-values.yaml --values runner/$(RUNNER)/values.yaml | yq 'select(.Pulled == null) | del(.metadata.finalizers)' \
		> runner/$(RUNNER)/generated-manifests.yaml

	$(eval RUNNER=system-prod-merit)
	helm template \
		oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set --version $(VERSION) \
		--namespace $(NAMESPACE) \
		--values runner/common-values.yaml --values runner/$(RUNNER)/values.yaml | yq 'select(.Pulled == null) | del(.metadata.finalizers)' \
		> runner/$(RUNNER)/generated-manifests.yaml
