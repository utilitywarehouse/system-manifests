# https://github.com/kubernetes-csi/external-snapshotter/releases
VERSION=v6.3.1

# tool 'yq' can be downloaded from https://github.com/mikefarah/yq

# This fetches manifests from upstream and splits resources into cluster/ and
# namespaced/ directories based on type of resources. 
.PHONY: update-manifests
update-manifests:
	curl -Ls -O https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/$(VERSION)/deploy/kubernetes/snapshot-controller/rbac-snapshot-controller.yaml
	curl -Ls -O https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/$(VERSION)/deploy/kubernetes/snapshot-controller/setup-snapshot-controller.yaml

	curl -Ls -O https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/$(VERSION)/client/config/crd/snapshot.storage.k8s.io_volumesnapshotclasses.yaml
	curl -Ls -O https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/$(VERSION)/client/config/crd/snapshot.storage.k8s.io_volumesnapshotcontents.yaml
	curl -Ls -O https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/$(VERSION)/client/config/crd/snapshot.storage.k8s.io_volumesnapshots.yaml
