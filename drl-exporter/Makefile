.DEFAULT_GOAL := get-upstream
.PHONY: get-upstream

# https://github.com/kha7iq/drl-exporter/tree/master/deploy/chart
TAG=v2.1.0

get-upstream:
	curl -sL \
	 https://raw.githubusercontent.com/kha7iq/drl-exporter/${TAG}/deploy/chart/templates/_helpers.tpl \
	 > templates/_helpers.tpl
	curl -sL \
	 https://raw.githubusercontent.com/kha7iq/drl-exporter/${TAG}/deploy/chart/templates/deployment.yaml \
	 > templates/deployment.yaml
	curl -sL \
	 https://raw.githubusercontent.com/kha7iq/drl-exporter/${TAG}/deploy/chart/templates/secret.yaml \
	 > templates/secret.yaml
	curl -sL \
	 https://raw.githubusercontent.com/kha7iq/drl-exporter/${TAG}/deploy/chart/templates/service.yaml \
	 > templates/service.yaml
	curl -sL \
	 https://raw.githubusercontent.com/kha7iq/drl-exporter/${TAG}/deploy/chart/templates/serviceaccount.yaml \
	 > templates/serviceaccount.yaml
	curl -sL \
	 https://raw.githubusercontent.com/kha7iq/drl-exporter/${TAG}/deploy/chart/templates/servicemonitor.yaml \
	 > templates/servicemonitor.yaml

	curl -sL \
	 https://raw.githubusercontent.com/kha7iq/drl-exporter/${TAG}/deploy/chart/Chart.yaml \
	 > Chart.yaml
	curl -sL \
	 https://raw.githubusercontent.com/kha7iq/drl-exporter/${TAG}/deploy/chart/values.yaml \
	 > values.yaml

	sed -i '' 's/tag:.*/tag: ${TAG}/g' values.yaml

	helm package .
	helm template drl-exporter drl-exporter-*.tgz --values values.yaml > base/drl-exporter.yaml
