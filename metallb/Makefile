version=v0.11.0

get-upstream:
	curl -Ls https://raw.githubusercontent.com/metallb/metallb/$(version)/manifests/metallb.yaml \
	 | sed 's/namespace\: metallb-system/namespace\: sys-metallb/g' \
	> metallb.yaml
