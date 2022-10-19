# argocd
Argo CD is a declarative, GitOps continuous delivery tool for Kubernetes.


### Layout
- __cluster__: base for cluster resources.
- __namespaced__: base for namespaced resources.

### Makefile
- `get-upstream-info`: gets list and count of unique resource types from upstream `ha` manifest
and names of deployments

- `make get-upstream`: gets the upstream `ha` manifest in a single file and splits it 
in to cluster and namespaced resources. 
Following resource types are selected, when updating please manually check for 
any new resource type added to upstream. 

### Documentation
* [Declarative Setup] (https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/)

### Note
current `get-upstream-info` output `v2.5.0-rc3`
```
count of unique resource types
   3 kind: CustomResourceDefinition
   8 kind: ServiceAccount
   7 kind: Role
   2 kind: ClusterRole
   7 kind: RoleBinding
   2 kind: ClusterRoleBinding
   9 kind: ConfigMap
   2 kind: Secret
  12 kind: Service
   6 kind: Deployment
   2 kind: StatefulSet
   8 kind: NetworkPolicy

Deployment/StatefulSet Names
argocd-applicationset-controller
---
argocd-dex-server
---
argocd-notifications-controller
---
argocd-redis-ha-haproxy
---
argocd-repo-server
---
argocd-server
argocd-application-controller
---
argocd-redis-ha-server
```
