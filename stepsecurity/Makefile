.PHONY: gen-yaml  list-versions values

gen-yaml:
	docker run -ti --rm \
	  -v $${PWD}:/opt/manifests \
	  --workdir=/opt/manifests \
	  --entrypoint=/bin/sh \
	  alpine/helm ./gen-yaml

list-versions:
	docker run -it --rm \
		--entrypoint=/bin/sh alpine/helm  -c  \
		"helm repo add stepsecurity https://helm.stepsecurity.io/arc-harden-runner && \
		  helm search repo -l  stepsecurity/arc-harden-runner | head -n 20"

values:
	docker run -it --rm \
		--entrypoint=/bin/sh alpine/helm  -c  \
		"helm repo add stepsecurity https://helm.stepsecurity.io/arc-harden-runner && \
		  helm show values stepsecurity/arc-harden-runner"
