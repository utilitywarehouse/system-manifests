VERSION=0.9.3
NAMESPACE=sys-actions

.DEFAULT_GOAL := generate-manifests
.PHONY: generate-manifests
generate-manifests: controller runners

.PHONY: controller
controller:
	helm template arc --namespace $(NAMESPACE) --include-crds --values controller/values.yaml oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller --version $(VERSION) > /tmp/arc-controller.yaml

	yq 'select(.kind=="CustomResourceDefinition")' /tmp/arc-controller.yaml > controller/cluster/crds.yaml
	yq 'select(.kind=="ClusterRole")' /tmp/arc-controller.yaml > controller/cluster/clusterrole.yaml
	yq 'select(.kind=="ClusterRoleBinding")' /tmp/arc-controller.yaml > controller/cluster/clusterrolebinding.yaml

	yq 'select(.kind!="CustomResourceDefinition" and .kind!="ClusterRole" and .kind!="ClusterRoleBinding")' /tmp/arc-controller.yaml > /tmp/arc-controller-namespaced.yaml
	# Remove empty yaml documents by generated a unified yaml document and splitting it back
	yq ea '[.]' /tmp/arc-controller-namespaced.yaml | yq '.[] | split_doc' > controller/namespaced/generated-manifests.yaml

.PHONY: runners
runners:
	# Removing the cleanup finalizers becuase the arc controller doesn't
	# clean them up when the pod is killed, and we have argocd to take care
	# of cleanup anyway.

	$(eval RUNNER=system-exp-aws)
	helm template \
		oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set --version $(VERSION) \
		--namespace $(NAMESPACE) \
		--values runner/common-values.yaml --values runner/$(RUNNER)/values.yaml | yq 'del(.metadata.finalizers)' \
		> runner/$(RUNNER)/generated-manifests.yaml

	$(eval RUNNER=system-exp-merit)
	helm template \
		oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set --version $(VERSION) \
		--namespace $(NAMESPACE) \
		--values runner/common-values.yaml --values runner/$(RUNNER)/values.yaml | yq 'del(.metadata.finalizers)' \
		> runner/$(RUNNER)/generated-manifests.yaml

	$(eval RUNNER=system-dev-aws)
	helm template \
		oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set --version $(VERSION) \
		--namespace $(NAMESPACE) \
		--values runner/common-values.yaml --values runner/$(RUNNER)/values.yaml | yq 'del(.metadata.finalizers)' \
		> runner/$(RUNNER)/generated-manifests.yaml

	$(eval RUNNER=system-dev-merit)
	helm template \
		oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set --version $(VERSION) \
		--namespace $(NAMESPACE) \
		--values runner/common-values.yaml --values runner/$(RUNNER)/values.yaml | yq 'del(.metadata.finalizers)' \
		> runner/$(RUNNER)/generated-manifests.yaml

	$(eval RUNNER=system-prod-merit)
	helm template \
		oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set --version $(VERSION) \
		--namespace $(NAMESPACE) \
		--values runner/common-values.yaml --values runner/$(RUNNER)/values.yaml | yq 'del(.metadata.finalizers)' \
		> runner/$(RUNNER)/generated-manifests.yaml
