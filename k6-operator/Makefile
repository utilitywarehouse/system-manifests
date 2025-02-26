.DEFAULT_GOAL := gen-manifests

CHART_VERSION=3.11.0

.PHONY: gen-manifests
gen-manifests:
	helm repo list | grep grafana || helm repo add grafana https://grafana.github.io/helm-charts
	helm repo update
	helm template k6-operator --namespace sys-k6 -f values.yaml grafana/k6-operator --version $(CHART_VERSION) > /tmp/k6-operator.yaml

	yq 'select(.kind=="CustomResourceDefinition" and .metadata.name=="privateloadzones.k6.io")' /tmp/k6-operator.yaml > cluster/privateLoadZones.yaml
	yq 'select(.kind=="CustomResourceDefinition" and .metadata.name=="testruns.k6.io")' /tmp/k6-operator.yaml > cluster/testRun.yaml
	yq 'select(.kind=="ClusterRole" and .metadata.name!="k6-operator-manager-role")' /tmp/k6-operator.yaml > cluster/clusterRole.yaml
	yq 'select(.kind=="ClusterRoleBinding" and .roleRef.name!="k6-operator-manager-role")' /tmp/k6-operator.yaml > cluster/clusterRoleBinding.yaml

	yq 'select(.kind=="ClusterRole" and .metadata.name=="k6-operator-manager-role")' /tmp/k6-operator.yaml > namespaced/role.yaml
	yq eval -i 'del(.metadata.annotations) | .kind = "Role" | .metadata.namespace = "sys-k6s"' namespaced/role.yaml
	yq 'select(.kind=="ClusterRoleBinding" and .roleRef.name=="k6-operator-manager-role")' /tmp/k6-operator.yaml > namespaced/roleBinding.yaml
	yq eval -i 'del(.metadata.annotations) | .kind = "RoleBinding" | .metadata.namespace = "sys-k6s" | .roleRef.kind = "Role"' namespaced/roleBinding.yaml

	yq 'select(.kind=="ServiceAccount")' /tmp/k6-operator.yaml > controller/serviceAccount.yaml
	yq 'select(.kind=="Role")' /tmp/k6-operator.yaml > controller/role.yaml
	yq 'select(.kind=="RoleBinding")' /tmp/k6-operator.yaml > controller/roleBinding.yaml
	yq 'select(.kind=="Service")' /tmp/k6-operator.yaml > controller/service.yaml
	yq 'select(.kind=="Deployment")' /tmp/k6-operator.yaml > controller/deployment.yaml
