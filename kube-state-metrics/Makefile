v=v2.6.0

pull-upstream:
	curl https://raw.githubusercontent.com/kubernetes/kube-state-metrics/$(v)/examples/standard/cluster-role-binding.yaml > cluster/cluster-role-binding.yaml
	curl https://raw.githubusercontent.com/kubernetes/kube-state-metrics/$(v)/examples/standard/cluster-role.yaml > cluster/cluster-role.yaml
	curl https://raw.githubusercontent.com/kubernetes/kube-state-metrics/$(v)/examples/standard/deployment.yaml > namespaced/deployment.yaml
	curl https://raw.githubusercontent.com/kubernetes/kube-state-metrics/$(v)/examples/standard/service-account.yaml > namespaced/service-account.yaml
	curl https://raw.githubusercontent.com/kubernetes/kube-state-metrics/$(v)/examples/standard/service.yaml > namespaced/service.yaml
