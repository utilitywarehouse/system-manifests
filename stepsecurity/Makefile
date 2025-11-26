.PHONY: gen-yaml
gen-yaml:
	docker run -ti --rm \
	  -v $${PWD}:/opt/manifests \
	  --workdir=/opt/manifests \
	  --entrypoint=/bin/sh \
	  alpine/helm ./gen-yaml
