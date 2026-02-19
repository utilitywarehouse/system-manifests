.DEFAULT_GOAL := get-upstream

# https://github.com/argoproj/argo-workflows/releases
VERSION=v4.0.1
NAMESPACE=sys-argo-workflows

.PHONY: get-upstream

get-upstream:
	mkdir -p cluster namespaced/server namespaced/controller
	curl -Ls https://github.com/argoproj/argo-workflows/releases/download/${VERSION}/namespace-install.yaml > /tmp/argo.yaml

	yq e 'select(.kind == "CustomResourceDefinition")' /tmp/argo.yaml > cluster/crds.yaml

	yq e 'select(.kind != "CustomResourceDefinition" and .kind != "ClusterRole" and .kind != "ClusterRoleBinding")' /tmp/argo.yaml > /tmp/_namespaced-all.yaml

	@for kind in $$(yq e '.kind' /tmp/_namespaced-all.yaml | sort | uniq | grep -v null); do \
		yq e "select(.kind == \"$$kind\" and (.metadata.name // \"\" | contains(\"argo-server\")))" /tmp/_namespaced-all.yaml > namespaced/server/$$(echo "$$kind" | tr '[:upper:]' '[:lower:]').yaml; \
		if [ ! -s namespaced/server/$$(echo "$$kind" | tr '[:upper:]' '[:lower:]').yaml ]; then \
			rm namespaced/server/$$(echo "$$kind" | tr '[:upper:]' '[:lower:]').yaml; \
		fi; \
	done

	yq e 'select((.metadata.name // "" | contains("argo-server") | not))' /tmp/_namespaced-all.yaml > /tmp/_namespaced-nonserver.yaml

	@for kind in $$(yq e '.kind' /tmp/_namespaced-nonserver.yaml | sort | uniq | grep -v null); do \
		yq e "select(.kind == \"$$kind\")" /tmp/_namespaced-nonserver.yaml > namespaced/controller/$$(echo "$$kind" | tr '[:upper:]' '[:lower:]').yaml; \
		if [ ! -s namespaced/controller/$$(echo "$$kind" | tr '[:upper:]' '[:lower:]').yaml ]; then \
			rm namespaced/controller/$$(echo "$$kind" | tr '[:upper:]' '[:lower:]').yaml; \
		fi; \
	done
