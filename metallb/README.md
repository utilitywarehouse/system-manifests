# MetalLB

### Layout
- __cluster__: base for cluster resources.
- __namespaced__: base for namespaced resources.

### Makefile
- `make get-upstream`: gets the upstream manifest in a single file and tries to
  split in cluster and namespaced resources

### Notes
We run MetalLB Speakers on kube masters slightly differently. Because we rely on
BGP configuration for MetalLB and all nodes have equal weights, we want a
separate masters deployment to avoid routing all services traffic through master
nodes. This will happen because BGP multipathing on equal cost peers will prefer
configuring paths for lower IP addresses, which our masters have compared to
workers.
Our Makefile target will try to create a separate manifest for master-speaker,
which we can later patch.
