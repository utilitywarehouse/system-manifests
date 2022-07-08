.PHONY: get-upstream

version=v0.13.3
cluster_resources=ClusterRole|ClusterRoleBinding|CustomResourceDefinition|ValidatingWebhookConfiguration
namespaced_resources=DaemonSet|Deployment|Role|RoleBinding|Secret|Service|ServiceAccount

# This fetches manifests from upstream and splits resources into cluster/ and
# namespaced/ directories. It follows a list of expectved resources in the
# upstream repo and ignores not needed ones, like Namespace and
# PodSecurityPolicies. In case of heavy upstream developmnet we might need to
# verify that the set of resources we keep is up to date and can provide a
# complete metallb setup.
get-upstream:
	# Fetch remote manifests and store temporarily
	curl -s https://raw.githubusercontent.com/metallb/metallb/$(version)/config/manifests/metallb-native.yaml > /tmp/upstream.yaml
	# Patch metallb-system ns to sys-metallb
	sed -i 's/namespace: metallb-system/namespace: sys-metallb/' /tmp/upstream.yaml
	# Match cluster resoures and put them under cluster/
	awk  'BEGIN{RS="---\n"; ORS="---\n"} match($$0, /kind: ($(cluster_resources))\nmetadata/) {print}' /tmp/upstream.yaml > cluster/upstream.yaml
	# Match the namespaced resources and place under namespaced/
	awk  'BEGIN{RS="---\n"; ORS="---\n"} match($$0, /kind: ($(namespaced_resources))\nmetadata/) {print}' /tmp/upstream.yaml > namespaced/upstream.yaml
	# We run a separate metallb deployment on master nodes. This is to avoid
	# routing traffic destined to worker services from master nodes, due to
	# BGP multipath node selection (all nodes have equal weights and master
	# nodes will take precedence because of lower IP addresses.
	# Copy the DaemonSet to create a separate one for master nodes
	awk  'BEGIN{RS="---\n"; ORS="---\n"} match($$0, /kind: DaemonSet\nmetadata/) {print}' /tmp/upstream.yaml > namespaced/master-speaker.yaml
	# Patch the name and labels of the master speaker
	sed -i 's/name: speaker/name: master-speaker/' namespaced/master-speaker.yaml
	sed -i 's/app: metallb/app: master-metallb/' namespaced/master-speaker.yaml
	sed -i 's/component: speaker/component: master-speaker/' namespaced/master-speaker.yaml
	# Clean up
	rm /tmp/upstream.yaml
