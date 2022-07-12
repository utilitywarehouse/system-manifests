# MetalLB

### Layout
- __cluster__: base for cluster resources.
- __namespaced__: base for namespaced resources.

### Makefile
- `make get-upstream`: gets the upstream manifest in a single file and tries to
  split in cluster and namespaced resources

### Notes
Our Makefile fetches upstream resources and follows a list of expected clustered
and namespaced resources. In case of heavy upstream developmnet we might need to
verify that the set of resources we keep is up to date and can provide a
complete metallb setup.
