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
		"helm repo add 1password https://1password.github.io/connect-helm-charts && \
		  helm search repo -l 1password/connect | head -n 20"
