.PHONY: gen-yaml  list-versions

gen-yaml:
	docker run -ti --rm \
	  -v $${PWD}:/opt/manifests \
	  --workdir=/opt/manifests \
	  --entrypoint=/bin/sh \
	  alpine/helm ./gen-yaml

list-versions:
	docker run -it --rm \
		--entrypoint=/bin/sh alpine/helm  -c  \
		"helm repo add cilium https://helm.cilium.io && \
		  helm search repo -l  cilium/tetragon | head -n 20"

crd:
	docker run -it --rm \
		--entrypoint=/bin/sh alpine/helm  -c  \
		"helm repo add cilium https://helm.cilium.io && \
		  helm show values  cilium/tetragon"
