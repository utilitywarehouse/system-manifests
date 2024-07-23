.DEFAULT_GOAL := get-upstream

VERSION=0.9.3

.PHONY: get-upstream
get-upstream:
	curl -Ls -O --output-dir cluster/upstream https://raw.githubusercontent.com/actions/actions-runner-controller/gha-runner-scale-set-$(VERSION)/charts/gha-runner-scale-set-controller/crds/actions.github.com_autoscalinglisteners.yaml
	curl -Ls -O --output-dir cluster/upstream https://raw.githubusercontent.com/actions/actions-runner-controller/gha-runner-scale-set-$(VERSION)/charts/gha-runner-scale-set-controller/crds/actions.github.com_autoscalingrunnersets.yaml
	curl -Ls -O --output-dir cluster/upstream https://raw.githubusercontent.com/actions/actions-runner-controller/gha-runner-scale-set-$(VERSION)/charts/gha-runner-scale-set-controller/crds/actions.github.com_ephemeralrunners.yaml
	curl -Ls -O --output-dir cluster/upstream https://raw.githubusercontent.com/actions/actions-runner-controller/gha-runner-scale-set-$(VERSION)/charts/gha-runner-scale-set-controller/crds/actions.github.com_ephemeralrunnersets.yaml

	helm template arc --namespace dev-enablement -f controller/values.yaml oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller > /tmp/ark-controller.yaml

	yq 'select(.kind=="ClusterRole")' /tmp/ark-controller.yaml > cluster/upstream/clusterrole.yaml
	yq 'select(.kind=="ClusterRoleBinding")' /tmp/ark-controller.yaml > cluster/upstream/clusterrolebinding.yaml

	yq 'select(.kind=="Deployment")' /tmp/ark-controller.yaml > controller/upstream/deployment.yaml
	yq 'select(.kind=="Role")' /tmp/ark-controller.yaml > controller/upstream/role.yaml
	yq 'select(.kind=="RoleBinding")' /tmp/ark-controller.yaml > controller/upstream/rolebinding.yaml
	yq 'select(.kind=="ServiceAccount")' /tmp/ark-controller.yaml > controller/upstream/serviceaccount.yaml

	# Remove the "namespace" attribute so we can easily re-use the base in other namespaces
	helm template arc-runners -f runner/values.yaml oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set | sd "^\s*namespace: default\n" "" > /tmp/ark-runner.yaml

	yq 'select(.kind=="ServiceAccount")' /tmp/ark-runner.yaml > runner/upstream/serviceaccount.yaml
	yq 'select(.kind=="Role")' /tmp/ark-runner.yaml > runner/upstream/role.yaml
	yq 'select(.kind=="RoleBinding")' /tmp/ark-runner.yaml > runner/upstream/rolebinding.yaml
	yq 'select(.kind=="AutoscalingRunnerSet")' /tmp/ark-runner.yaml > runner/upstream/autoscalingrunnerset.yaml
