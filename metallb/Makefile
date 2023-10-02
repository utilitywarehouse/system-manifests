.PHONY: get-upstream

version=v0.13.11
cluster_resources=ClusterRole|ClusterRoleBinding|CustomResourceDefinition|ValidatingWebhookConfiguration
namespaced_resources=DaemonSet|Deployment|Role|RoleBinding|Secret|Service|ServiceAccount

# This fetches manifests from upstream and splits resources into cluster/ and
# namespaced/ directories. It follows a list of expected resources in the
# upstream repo and ignores not needed ones, like Namespace and
# PodSecurityPolicies. In case of heavy upstream developmnet we might need to
# verify that the set of resources we keep is up to date and can provide a
# complete metallb setup.
# Upstream also contains a ca bundle for the CRDs in a valid pem format, which
# ends up committed in our repo. This is just a placeholder and the operator
# will patch it: https://github.com/metallb/metallb/pull/1522.
get-upstream:
	# Fetch remote manifests and store temporarily
	curl -s https://raw.githubusercontent.com/metallb/metallb/$(version)/config/manifests/metallb-native.yaml > /tmp/upstream.yaml
	# Patch metallb-system ns to sys-metallb
	sed -i 's/namespace: metallb-system/namespace: sys-metallb/' /tmp/upstream.yaml
	# Match cluster resoures and put them under cluster/
	awk  'BEGIN{RS="---\n"; ORS="---\n"} match($$0, /kind: ($(cluster_resources))\nmetadata/) {print}' /tmp/upstream.yaml > cluster/upstream.yaml
	# Match the namespaced resources and place under namespaced/
	awk  'BEGIN{RS="---\n"; ORS="---\n"} match($$0, /kind: ($(namespaced_resources))\nmetadata/) {print}' /tmp/upstream.yaml > namespaced/upstream.yaml
	# Clean up
	rm /tmp/upstream.yaml
