# Argo Workflows - The workflow engine for Kubernetes

### Layout

- **cluster**: base for cluster resources.
- **namespaced**: base for namespaced resources.

### Makefile

- `make get-upstream`: gets the upstream manifests in a single file and splits it
  in to cluster and namespaced resources. when updating please manually check for
  any new resource type added to upstream.

### Documentation

- [Installation Options](https://argo-workflows.readthedocs.io/en/latest/installation/#installation-options)
- [GitHub Project](https://github.com/argoproj/argo-workflows/tree/main/manifests)

### Provisional ADRs

- We are keeping to namespace install for POC
- Install via project releases as the [helm chart](https://github.com/argoproj/argo-helm) is community maintained. This was the approach taken for [argocd](../argocd/) also
