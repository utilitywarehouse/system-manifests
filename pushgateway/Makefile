.DEFAULT_GOAL := gen-manifests

# Helm chart version for prometheus-community/prometheus-pushgateway.
version=3.8.0
# maps to pushgateway app version v1.11.3

.PHONY: gen-manifests
gen-manifests:
	docker run -ti --rm \
	  -v $${PWD}:/opt/manifests \
	  -e VERSION=$(version) \
	  --workdir=/opt/manifests \
	  --entrypoint=/bin/sh \
	  alpine/helm ./gen-yaml
