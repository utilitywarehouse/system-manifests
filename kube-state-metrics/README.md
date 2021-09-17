# kube-state-metrics-manifests

A Kustomize base for deploying
[kube-state-metrics](https://github.com/kubernetes/kube-state-metrics).

## Updating

Copy files from the
[upstream](https://github.com/kubernetes/kube-state-metrics/tree/master/examples/standard),
splitting cluster-scoped and namespaced-scoped resources into `cluster/` and `namespaced/`
respectively.

Patches to the upstream manifests can be found in
`{cluster,namespaced}/patch.yaml`. Amend these in response to any relevant
upstream changes.
