BITNAMI_KAFKA_RELEASE=32.4.3
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

list-versions:
	docker run -it --rm \
		--entrypoint=/bin/sh alpine/helm  -c  \
		"helm repo add bitnami https://charts.bitnami.com/bitnami && \
		  helm search repo -l bitnami/kafka | head -n 20"
