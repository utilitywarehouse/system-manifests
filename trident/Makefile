.PHONY: build
build:
	docker build -t tridentctl .

.PHONY: gen-yaml
gen-yaml:
	docker run -ti --rm \
	-v $$(which kubectl):/usr/local/bin/kubectl:ro \
	-v $${HOME}/.kube:/root/.kube:rw \
	-v $${PWD}:/opt/trident \
	tridentctl /opt/trident/gen-yaml
