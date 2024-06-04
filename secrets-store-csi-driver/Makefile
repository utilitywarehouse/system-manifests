.DEFAULT_GOAL := get-upstream

# https://github.com/kubernetes-sigs/secrets-store-csi-driver
VERSION=v1.4.3

# tool 'yq' can be downloaded from https://github.com/mikefarah/yq

FILES = csidriver.yaml \
	rbac-secretproviderclass.yaml \
	rbac-secretproviderrotation.yaml \
	rbac-secretprovidersyncing.yaml \
	rbac-secretprovidertokenrequest.yaml \
	role-secretproviderclasses-admin.yaml \
	role-secretproviderclasses-viewer.yaml \
	role-secretproviderclasspodstatuses-viewer.yaml \
	secrets-store-csi-driver.yaml \
	secrets-store.csi.x-k8s.io_secretproviderclasses.yaml \
	secrets-store.csi.x-k8s.io_secretproviderclasspodstatuses.yaml

.PHONY: get-upstream
get-upstream:
	for file in $(FILES) ; do \
	 curl -Ls https://github.com/kubernetes-sigs/secrets-store-csi-driver/releases/download/$(VERSION)/$$file > upstream/$$file; \
	done
