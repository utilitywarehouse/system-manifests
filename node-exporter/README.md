# node-exporter

A Kustomize base for deploying
[node-exporter](https://github.com/prometheus/node_exporter)

Splitting cluster-scoped and namespaced-scoped resources into `cluster/` and
`namespaced/` respectively to be used as separate bases if needed.

## Updating

This is not following a certain upstream deployment but is based on a simple
daemonset manifest, where users usually only have to bump the image version.
