# Flux
Open and extensible continuous delivery solution for Kubernetes.


### Layout
- __cluster__: base for cluster resources.
- __namespaced__: base for namespaced resources.

### Makefile
- `get-upstream-resource-types`: gets list of unique resource types from upstream manifest

- `make get-upstream`: gets the upstream manifest in a single file and splits it 
in to cluster and namespaced resources. 
Following resource types are selected, when updating please manually check for 
any new resource type added to upstream

* CustomResourceDefinition
* ClusterRole
* NetworkPolicy
* Deployment
* Service
* ServiceAccount
* ClusterRoleBinding


### Documentation
flux documents are available [here](https://fluxcd.io/docs)
also see [Cluster sync from git](https://fluxcd.io/docs/flux-e2e/#diagram-cluster-sync-from-git)


### Note
helm, image-automation & image-reflector controller and corresponding service accounts are not deployed.
