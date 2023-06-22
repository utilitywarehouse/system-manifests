.PHONY: update
CCM_VERSION:=v27.1.5
# This is a temporary workaround and should be replaced by the above variable
# once this issue is resolved:
# https://github.com/kubernetes/cloud-provider-gcp/issues/289
# It looks like they recently start to push images under
# registry.k8s.io/cloud-provider-gcp/cloud-controller-manager but tagging is
# wrong atm and points to a non-existent repo tag.
CCM_IMAGE_VERSION:= v26.2.4

update:
	# This fetches  an example manifest from upstream repo used to test on
	# kOps. Author of the change claims that this is to be used to test
	# production scenariosn, so it could be a valid base for us:
	# https://github.com/kubernetes/cloud-provider-gcp/commit/79d1462d8c05e14d98c44d03067bdb80fb6cd9df
	curl -s https://raw.githubusercontent.com/kubernetes/cloud-provider-gcp/ccm/${CCM_VERSION}/deploy/packages/default/manifest.yaml > upstream.yaml
	# We also need to update the image as the upstream points to `latest`
	sed -i "s/newTag:.*/newTag: ${CCM_IMAGE_VERSION}/g" kustomization.yaml
