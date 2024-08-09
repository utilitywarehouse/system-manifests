.DEFAULT_GOAL := gen-manifests

CHART_VERSION=3.8.0
APP_VERSION=0.0.16


.PHONY: gen-manifests
gen-manifests:
	helm repo add grafana https://grafana.github.io/helm-charts
	helm repo update
	helm template k6-operator --namespace dev-enablement -f values.yaml grafana/k6-operator --version $(CHART_VERSION) > /tmp/k6-operator.yaml

	yq 'select(.kind=="CustomResourceDefinition" and .metadata.name=="privateloadzones.k6.io")' /tmp/k6-operator.yaml > cluster/privateloadzones.yaml
	yq 'select(.kind=="ClusterRole" and (.metadata.name | test("privateloadzone")))' /tmp/k6-operator.yaml > cluster/clusterRole.yaml
	yq 'select(.kind=="ClusterRoleBinding" and (.roleRef.name | test("privateloadzone")))' /tmp/k6-operator.yaml > cluster/clusterRoleBinding.yaml
