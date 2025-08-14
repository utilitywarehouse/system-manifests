.DEFAULT_GOAL := get-upstream

VERSION=v3.13.0

.PHONY: get-upstream
get-upstream:
	mkdir -p cluster
	mkdir -p namespaced
	# csi-nodeplugin-rbac.yaml
	curl -Ls https://raw.githubusercontent.com/ceph/ceph-csi/refs/tags/$(VERSION)/deploy/rbd/kubernetes/csi-nodeplugin-rbac.yaml > /tmp/csi-nodeplugin-rbac.yaml
	sd "namespace: default" "namespace: sys-ceph" /tmp/csi-nodeplugin-rbac.yaml
	yq 'select(.kind=="ClusterRole")' /tmp/csi-nodeplugin-rbac.yaml > cluster/csi-nodeplugin-rbac.yaml
	echo "---" >> cluster/csi-nodeplugin-rbac.yaml
	yq 'select(.kind=="ClusterRoleBinding")' /tmp/csi-nodeplugin-rbac.yaml >> cluster/csi-nodeplugin-rbac.yaml
	yq 'select(.kind=="ServiceAccount")' /tmp/csi-nodeplugin-rbac.yaml > namespaced/csi-nodeplugin-rbac.yaml
	rm /tmp/csi-nodeplugin-rbac.yaml
	# csi-provisioner-rbac.yaml
	curl -Ls https://raw.githubusercontent.com/ceph/ceph-csi/refs/tags/$(VERSION)/deploy/rbd/kubernetes/csi-provisioner-rbac.yaml > /tmp/csi-provisioner-rbac.yaml
	sd "namespace: default" "namespace: sys-ceph" /tmp/csi-provisioner-rbac.yaml
	yq 'select(.kind=="ClusterRole")' /tmp/csi-provisioner-rbac.yaml > cluster/csi-provisioner-rbac.yaml
	echo "---" >> cluster/csi-provisioner-rbac.yaml
	yq 'select(.kind=="ClusterRoleBinding")' /tmp/csi-provisioner-rbac.yaml >> cluster/csi-provisioner-rbac.yaml
	echo "---" >> cluster/csi-provisioner-rbac.yaml
	yq 'select(.kind=="ServiceAccount")' /tmp/csi-provisioner-rbac.yaml > namespaced/csi-provisioner-rbac.yaml
	echo "---" >> namespaced/csi-provisioner-rbac.yaml
	yq 'select(.kind=="Role")' /tmp/csi-provisioner-rbac.yaml >> namespaced/csi-provisioner-rbac.yaml
	echo "---" >> namespaced/csi-provisioner-rbac.yaml
	yq 'select(.kind=="RoleBinding")' /tmp/csi-provisioner-rbac.yaml >> namespaced/csi-provisioner-rbac.yaml
	rm /tmp/csi-provisioner-rbac.yaml
	# csi-rbdplugin-provisioner.yaml
	curl -Ls https://raw.githubusercontent.com/ceph/ceph-csi/refs/tags/$(VERSION)/deploy/rbd/kubernetes/csi-rbdplugin-provisioner.yaml > namespaced/csi-rbdplugin-provisioner.yaml
	sd "namespace: default" "namespace: sys-ceph" namespaced/csi-rbdplugin-provisioner.yaml
	# csi-rbdplugin.yaml
	curl -Ls https://raw.githubusercontent.com/ceph/ceph-csi/refs/tags/v3.13.0/deploy/rbd/kubernetes/csi-rbdplugin.yaml > namespaced/csi-rbdplugin.yaml
	sd "namespace: default" "namespace: sys-ceph" namespaced/csi-rbdplugin.yaml
	# csidriver.yaml
	curl -Ls https://raw.githubusercontent.com/ceph/ceph-csi/refs/tags/v3.13.0/deploy/rbd/kubernetes/csidriver.yaml > cluster/csidriver.yaml
