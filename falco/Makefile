.PHONY: gen-yaml
gen-yaml:
	docker run -ti --rm \
	  -v $${PWD}:/opt/manifests \
	  --workdir=/opt/manifests \
	  --entrypoint=/bin/sh \
	  alpine/helm ./gen-yaml


list-versions:
	docker run -it --rm \
		--entrypoint=/bin/sh alpine/helm  -c  \
		"helm repo add falcosecurity https://falcosecurity.github.io/charts && \
		  helm search repo -l falcosecurity/falco | head -n 20"
