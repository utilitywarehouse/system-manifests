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

	yq 'select(.kind=="Deployment")' /tmp/arc-controller.yaml > controller/namespaced/deployment.yaml
	yq 'select(.kind=="Role")' /tmp/arc-controller.yaml > controller/namespaced/role.yaml
	yq 'select(.kind=="RoleBinding")' /tmp/arc-controller.yaml > controller/namespaced/rolebinding.yaml
	yq 'select(.kind=="ServiceAccount")' /tmp/arc-controller.yaml > controller/namespaced/serviceaccount.yaml

.PHONY: runners
runners:
	$(eval RUNNER=infra-exp)
	helm template \
		oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set --version $(VERSION) \
		--namespace $(NAMESPACE) \
		--values runner/common-values.yaml --values runner/$(RUNNER)/values.yaml  \
		> runner/$(RUNNER)/generated-manifests.yaml

	$(eval RUNNER=infra-dev)
	helm template \
		oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set --version $(VERSION) \
		--namespace $(NAMESPACE) \
		--values runner/common-values.yaml --values runner/$(RUNNER)/values.yaml  \
		> runner/$(RUNNER)/generated-manifests.yaml
