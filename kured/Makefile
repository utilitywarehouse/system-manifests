.DEFAULT_GOAL := update-upstream
SHELL := /bin/bash
RELEASE := 1.14.0

.PHONY: update-upstream
update-upstream:
	mkdir -p upstream
	curl -sL https://github.com/weaveworks/kured/releases/download/$(RELEASE)/kured-$(RELEASE)-dockerhub.yaml -o upstream/kured.yaml
	# Cluster scope
	yq 'select(.kind=="ClusterRole")' upstream/kured.yaml > cluster/clusterrole.yaml
	yq 'select(.kind=="ClusterRoleBinding") | .subjects[].namespace = "sys-flatcar"' upstream/kured.yaml > cluster/clusterrolebinding.yaml
	# Namespace scope
	yq 'select(.kind=="DaemonSet") | del(.metadata.namespace)' upstream/kured.yaml > namespaced/daemonset.yaml
	yq 'select(.kind=="Role") | del(.metadata.namespace)' upstream/kured.yaml > namespaced/role.yaml
	yq 'select(.kind=="RoleBinding") | del(.metadata.namespace) | del(.subjects[].namespace)' upstream/kured.yaml > namespaced/rolebinding.yaml
	yq 'select(.kind=="ServiceAccount") | del(.metadata.namespace)' upstream/kured.yaml > namespaced/serviceaccount.yaml
