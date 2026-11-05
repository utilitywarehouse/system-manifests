# https://github.com/kubernetes-csi/csi-driver-smb/releases
VERSION=v1.20.4

# This fetches the kubectl install manifests (deploy/$(VERSION)) from upstream
# into upstream/. Do not edit files in upstream/, they are overwritten here.
# Linux node manifests only.
.PHONY: update-manifests
update-manifests:
	mkdir -p upstream
	cd upstream && curl -fLs -O https://raw.githubusercontent.com/kubernetes-csi/csi-driver-smb/$(VERSION)/deploy/$(VERSION)/csi-smb-driver.yaml
	cd upstream && curl -fLs -O https://raw.githubusercontent.com/kubernetes-csi/csi-driver-smb/$(VERSION)/deploy/$(VERSION)/rbac-csi-smb.yaml
	cd upstream && curl -fLs -O https://raw.githubusercontent.com/kubernetes-csi/csi-driver-smb/$(VERSION)/deploy/$(VERSION)/csi-smb-controller.yaml
	cd upstream && curl -fLs -O https://raw.githubusercontent.com/kubernetes-csi/csi-driver-smb/$(VERSION)/deploy/$(VERSION)/csi-smb-node.yaml
