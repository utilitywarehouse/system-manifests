# argocd

Argo CD is a declarative, GitOps continuous delivery tool for Kubernetes.

### Layout

- **cluster**: base for cluster resources.
- **namespaced**: base for namespaced resources.

### Makefile

- `get-upstream-info`: gets list and count of unique resource types from upstream `ha` manifest
  and names of deployments

- `make get-upstream`: gets the upstream `ha` manifest in a single file and splits it
  in to cluster and namespaced resources. when updating please manually check for
  any new resource type added to upstream.

### Documentation

- [Declarative Setup](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/)

### Config files

- [argocd-cm](argocd/namespaced/argocd-cm.yaml)
- [argocd-cmd-params-cm](argocd/namespaced/argocd-cmd-params-cm.yaml)
- [argocd-rbac-cm](argocd/namespaced/argocd-rbac-cm.yaml)

### Removed resources from upstream

- ApplicationSet - ApplicationSet are mostly used to deploy 1 application across multiple cluster.
  since we do not have multi cluster support this controller is removed
- Dex Server - as we are using oidc for authentication
