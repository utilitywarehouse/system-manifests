version=v1.15.3
aws_pca_version=v1.4.0

# replace all namespace references with "kube-system", this works since we
# deploy all resources under "kube-system"
mvns=| sed -E 's|(\s*)namespace: "?cert-manager"?|\1namespace: "kube-system"|g'

get-yaml:
	curl -L https://github.com/jetstack/cert-manager/releases/download/$(version)/cert-manager.yaml $(mvns) > upstream-cert-manager.yaml

.PHONY: gen-aws-pca-yaml
gen-aws-pca-yaml:
	docker run -ti --rm \
	  -v $${PWD}:/opt/manifests \
	  -e AWS_PCA_RELEASE=$(aws_pca_version) \
	  --workdir=/opt/manifests/aws-pca-issuer \
	  --entrypoint=/bin/sh \
	  alpine/helm ./gen-yaml/gen
