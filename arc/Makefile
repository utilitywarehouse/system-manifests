VERSION=0.9.3
CONTROLLER_NAMESPACE=sys-actions
NAMESPACE=sys-actions

.DEFAULT_GOAL := generate-manifests
.PHONY: generate-manifests
generate-manifests: controller runners

.PHONY: controller
controller:
	helm template arc --namespace $(CONTROLLER_NAMESPACE) --include-crds --values controller/values.yaml oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller --version $(VERSION) > /tmp/arc-controller.yaml

	yq 'select(.kind=="CustomResourceDefinition")' /tmp/arc-controller.yaml > controller/cluster/crds.yaml
	yq 'select(.kind=="ClusterRole")' /tmp/arc-controller.yaml > controller/cluster/clusterrole.yaml
	yq 'select(.kind=="ClusterRoleBinding")' /tmp/arc-controller.yaml > controller/cluster/clusterrolebinding.yaml

	yq 'select(.kind=="Deployment")' /tmp/arc-controller.yaml > controller/namespaced/deployment.yaml
	yq 'select(.kind=="Role")' /tmp/arc-controller.yaml > controller/namespaced/role.yaml
	yq 'select(.kind=="RoleBinding")' /tmp/arc-controller.yaml > controller/namespaced/rolebinding.yaml
	yq 'select(.kind=="ServiceAccount")' /tmp/arc-controller.yaml > controller/namespaced/serviceaccount.yaml

.PHONY: runners
runners:
	# * Runner names are global on github, so manifests cannot be reused
	# * Removing the "namespace" attributes so runners can be deployed in any namespace

	$(eval RUNNER=infra-exp)
	helm template \
		oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set --version $(VERSION) \
		--values runner/common-values.yaml --values runner/$(RUNNER)/values.yaml  \
		| sd "^\s*namespace: default\n" "" > runner/$(RUNNER)/generated-manifests.yaml

	$(eval RUNNER=infra-dev)
	helm template \
		oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set --version $(VERSION) \
		--values runner/common-values.yaml --values runner/$(RUNNER)/values.yaml  \
		| sd "^\s*namespace: default\n" "" > runner/$(RUNNER)/generated-manifests.yaml
