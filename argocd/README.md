# argocd
Argo CD is a declarative, GitOps continuous delivery tool for Kubernetes.


### Layout
- __cluster__: base for cluster resources.
- __namespaced__: base for namespaced resources.

### Makefile
- `get-upstream-info`: gets list and count of unique resource types from upstream `ha` manifest
and names of deployments

- `make get-upstream`: gets the upstream `ha` manifest in a single file and splits it 
in to cluster and namespaced resources. when updating please manually check for 
any new resource type added to upstream. 

### Documentation
* [Declarative Setup](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/)


### Config files
   * [argocd-cm](argocd/namespaced/argocd-cm.yaml)
   * [argocd-cmd-params-cm](argocd/namespaced/argocd-cmd-params-cm.yaml)
   * [argocd-rbac-cm](argocd/namespaced/argocd-rbac-cm.yaml)

### Removed resources from upstream
   * ApplicationSet - ApplicationSet are mostly used to deploy 1 application across multiple cluster. 
      since we do not have multi cluster support this controller is removed
   * Dex Server - as we are using oidc for authentication

### Note
current `get-upstream-info` output `v2.6.0-rc1`
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
