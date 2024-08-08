.DEFAULT_GOAL := get-upstream

CHART_VERSION=3.8.0
APP_VERSION=0.0.16


.PHONY: get-upstream
get-upstream:
	helm repo add grafana https://grafana.github.io/helm-charts
	helm repo update
	helm template k6-operator --namespace dev-enablement -f values.yaml grafana/k6-operator --version $(CHART_VERSION) > /tmp/k6-operator.yaml

	yq 'select(.kind=="CustomResourceDefinition" and .metadata.name=="k6s.k6.io")' /tmp/k6-operator.yaml > cluster/upstream/k6.yaml
	yq 'select(.kind=="CustomResourceDefinition" and .metadata.name=="privateloadzones.k6.io")' /tmp/k6-operator.yaml > cluster/upstream/plz.yaml
	yq 'select(.kind=="CustomResourceDefinition" and .metadata.name=="testruns.k6.io")' /tmp/k6-operator.yaml > cluster/upstream/testrun.yaml
	yq 'select(.kind=="ClusterRole")' /tmp/k6-operator.yaml > cluster/upstream/clusterRole.yaml
	yq 'select(.kind=="ClusterRoleBinding")' /tmp/k6-operator.yaml > cluster/upstream/clusterRoleBinding.yaml
	
	yq 'select(.kind=="ServiceAccount")' /tmp/k6-operator.yaml > upstream/controller/serviceaccount.yaml
	yq 'select(.kind=="Role")' /tmp/k6-operator.yaml > upstream/controller/role.yaml
	yq 'select(.kind=="RoleBinding")' /tmp/k6-operator.yaml > upstream/controller/roleBinding.yaml
	yq 'select(.kind=="Service")' /tmp/k6-operator.yaml > upstream/controller/service.yaml
	yq 'select(.kind=="Deployment")' /tmp/k6-operator.yaml > upstream/controller/deployment.yaml
