BITNAMI_KAFKA_RELEASE=32.3.5
NAMESPACE=otel
NAME=kafka

.PHONY: gen-yaml
gen-yaml:
	docker run -ti --rm \
	  -v $${PWD}:/opt/manifests \
	  -e BITNAMI_KAFKA_RELEASE=${BITNAMI_KAFKA_RELEASE} \
	  -e NAMESPACE=${NAMESPACE} \
	  -e NAME=${NAME} \
	  --workdir=/opt/manifests \
	  --entrypoint=/bin/sh \
	  alpine/helm ./gen-yaml
