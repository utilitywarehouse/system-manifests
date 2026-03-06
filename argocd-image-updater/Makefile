.DEFAULT_GOAL := get-upstream

# https://github.com/argoproj-labs/argocd_image_updater
ARGOCD_VERSION=v1.1.1

# tool 'yq' can be downloaded from https://github.com/mikefarah/yq

# This fetches manifests from upstream and splits resources into cluster/ and
# namespaced/ directories based on type of resources. 
.PHONY: get-upstream
get-upstream:
	curl -Ls https://raw.githubusercontent.com/argoproj-labs/argocd-image-updater/$(ARGOCD_VERSION)/config/install.yaml > /tmp/argocd_image_updater.yaml

	# replace namespace
	sd "namespace: argocd" "namespace: sys-argocd" /tmp/argocd_image_updater.yaml
	

	# cluster resources
	yq 'select(.kind=="CustomResourceDefinition")' /tmp/argocd_image_updater.yaml > cluster/upstream/crds.yaml
	yq 'select(.kind=="ClusterRole" or .kind=="ClusterRoleBinding")' /tmp/argocd_image_updater.yaml > cluster/upstream/cluster-rbac.yaml

	# namespace resources
	yq 'select(.kind=="Deployment" or .kind=="StatefulSet" or .kind=="Service")' /tmp/argocd_image_updater.yaml > namespaced/upstream/apps.yaml
	yq 'select(.kind=="Role" or .kind=="RoleBinding" or .kind=="ServiceAccount")' /tmp/argocd_image_updater.yaml > namespaced/upstream/rbac.yaml
	yq 'select(.kind=="ConfigMap")' /tmp/argocd_image_updater.yaml > namespaced/upstream/configMaps.yaml
	yq 'select(.kind=="NetworkPolicy")' /tmp/argocd_image_updater.yaml > namespaced/upstream/netpols.yaml

	# remove temp file
	rm /tmp/argocd_image_updater.yaml

.PHONY: diff-upstream
diff-upstream:
	@curl -Ls https://raw.githubusercontent.com/argoproj-labs/argocd-image-updater/$(ARGOCD_VERSION)/config/install.yaml > /tmp/argocd_image_updater.yaml

	@yq -o=tsv '.metadata.name + " (" + .kind + ")"' /tmp/argocd_image_updater.yaml | sort > /tmp/argocd_image_updater_remote_res
	@yq -o=tsv '.metadata.name + " (" + .kind + ")"' cluster/upstream/*.yaml namespaced/upstream/*.yaml | sort > /tmp/argocd_image_updater_local_res
	
	# diff betweeen remote and local
	-diff --color -U 0 /tmp/argocd_image_updater_remote_res /tmp/argocd_image_updater_local_res

	@rm /tmp/argocd_image_updater.yaml  /tmp/argocd_image_updater_remote_res  /tmp/argocd_image_updater_local_res
