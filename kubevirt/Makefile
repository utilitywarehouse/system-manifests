.DEFAULT_GOAL := get-upstream

# https://github.com/kubevirtproj/kubevirt-cd
VERSION=v1.8.2

# tool 'yq' can be downloaded from https://github.com/mikefarah/yq

# This fetches manifests from upstream and splits resources into cluster/ and
# namespaced/ directories based on type of resources.
.PHONY: get-upstream
get-upstream:
	curl -Ls https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/kubevirt-operator.yaml > /tmp/upstream.yaml

	# replace namespace
	sd "namespace: kubevirt" "namespace: sys-kubevirt" /tmp/upstream.yaml

	# cluster resources
	yq 'select(.kind=="CustomResourceDefinition")' /tmp/upstream.yaml > cluster/upstream/crds.yaml
	yq 'select(.kind=="ClusterRole" or .kind=="ClusterRoleBinding")' /tmp/upstream.yaml > cluster/upstream/cluster-rbac.yaml
	yq 'select(.kind=="PriorityClass")' /tmp/upstream.yaml > cluster/upstream/priorityClass.yaml

	# namespace resources
	yq 'select(.kind=="Deployment" or .kind=="StatefulSet" or .kind=="Service")' /tmp/upstream.yaml > namespaced/upstream/apps.yaml
	yq 'select(.kind=="Role" or .kind=="RoleBinding" or .kind=="ServiceAccount")' /tmp/upstream.yaml > namespaced/upstream/rbac.yaml
	yq 'select(.kind=="ConfigMap")' /tmp/upstream.yaml > namespaced/upstream/configMaps.yaml
	yq 'select(.kind=="NetworkPolicy")' /tmp/upstream.yaml > namespaced/upstream/netpols.yaml

	# remove temp file
	rm /tmp/upstream.yaml

	# Create the KubeVirt CR (instance deployment request) which triggers the actual installation
	curl -Ls https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/kubevirt-cr.yaml > namespaced/upstream/kubevirt-cr.yaml
	sd "namespace: kubevirt" "namespace: sys-kubevirt" namespaced/upstream/kubevirt-cr.yaml


.PHONY: diff-upstream
diff-upstream:
	@curl -Ls https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/kubevirt-operator.yaml > /tmp/upstream.yaml

	@yq -o=tsv '.metadata.name + " (" + .kind + ")"' /tmp/upstream.yaml | sort > /tmp/remote_resources
	@yq -o=tsv '.metadata.name + " (" + .kind + ")"' cluster/upstream/*.yaml namespaced/upstream/*.yaml | sort > /tmp/local_resources

	# diff betweeen remote and local
	-diff --color -U 0 /tmp/remote_resources /tmp/local_resources

	@rm /tmp/upstream.yaml /tmp/remote_resources /tmp/local_resources
