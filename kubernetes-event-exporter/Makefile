.DEFAULT_GOAL := get-upstream

BITNAMI_RELEASE:="2.7.2"

.PHONY: get-upstream
get-upstream:
	helm template ${BITNAMI_RELEASE} -f values.yaml --namespace=sys-prom oci://registry-1.docker.io/bitnamicharts/kubernetes-event-exporter > /tmp/kubernetes-event-exporter.yaml
	# Split cluster scoped resources
	mkdir -p cluster
	cp kustomization.yaml.base cluster/kustomization.yaml
	yq 'select(.kind=="ClusterRole")' /tmp/kubernetes-event-exporter.yaml > cluster/clusterrole.yaml
	echo "  - clusterrole.yaml" >> cluster/kustomization.yaml
	yq 'select(.kind=="ClusterRoleBinding")' /tmp/kubernetes-event-exporter.yaml > cluster/clusterrolebinding.yaml
	echo "  - clusterrolebinding.yaml" >> cluster/kustomization.yaml
	# Split namespace scoped resources
	mkdir -p namespaced
	cp kustomization.yaml.base namespaced/kustomization.yaml
	yq 'select(.kind=="ConfigMap")' /tmp/kubernetes-event-exporter.yaml > namespaced/configmap.yaml
	echo "  - configmap.yaml" >> namespaced/kustomization.yaml
	yq 'select(.kind=="Deployment")' /tmp/kubernetes-event-exporter.yaml > namespaced/deployment.yaml
	echo "  - deployment.yaml" >> namespaced/kustomization.yaml
	yq 'select(.kind=="ServiceAccount")' /tmp/kubernetes-event-exporter.yaml > namespaced/serviceaccount.yaml
	echo "  - serviceaccount.yaml" >> namespaced/kustomization.yaml
	# Cleanup
	rm /tmp/kubernetes-event-exporter.yaml
