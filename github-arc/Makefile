VERSION=0.9.3

.PHONY: get-upstream
get-upstream:
	curl -o /tmp/github-arc.yaml -Ls https://github.com/actions/actions-runner-controller/releases/download/gha-runner-scale-set-$(VERSION)/actions-runner-controller.yaml

	# replace namespace
	sd "namespace: actions-runner-system" "namespace: dev-enablement" /tmp/github-arc.yaml

	# cluster resources
	yq 'select(.kind=="ClusterRole")' /tmp/github-arc.yaml > cluster/upstream/ClusterRole.yaml
	yq 'select(.kind=="ClusterRoleBinding")' /tmp/github-arc.yaml > cluster/upstream/ClusterRoleBinding.yaml
	yq 'select(.kind=="CustomResourceDefinition")' /tmp/github-arc.yaml > cluster/upstream/CustomResourceDefinition.yaml
	yq 'select(.kind=="MutatingWebhookConfiguration")' /tmp/github-arc.yaml > cluster/upstream/MutatingWebhookConfiguration.yaml
	yq 'select(.kind=="ValidatingWebhookConfiguration")' /tmp/github-arc.yaml > cluster/upstream/ValidatingWebhookConfiguration.yaml

	# namespace resources
	yq 'select(.kind=="Certificate")' /tmp/github-arc.yaml > namespaced/upstream/Certificate.yaml
	yq 'select(.kind=="Deployment")' /tmp/github-arc.yaml > namespaced/upstream/Deployment.yaml
	yq 'select(.kind=="Issuer")' /tmp/github-arc.yaml > namespaced/upstream/Issuer.yaml
	yq 'select(.kind=="Namespace")' /tmp/github-arc.yaml > namespaced/upstream/Namespace.yaml
	yq 'select(.kind=="Role")' /tmp/github-arc.yaml > namespaced/upstream/Role.yaml
	yq 'select(.kind=="RoleBinding")' /tmp/github-arc.yaml > namespaced/upstream/RoleBinding.yaml
	yq 'select(.kind=="Service")' /tmp/github-arc.yaml > namespaced/upstream/Service.yaml
