# gatekeeper
These manifests abstract all the common configuration to deploy gatekeeper in our clusters

## Overview

There are 3 layers of configuration

* upstream: manifests from gatekeeper's official helm deployment, plus the basic patch to make it adaptable
* UW: custom UW configurations and addons, common to all clusters, leveraging upstream manifests
* cluster: cluster specific resources and patches, leveraging UW's manifests

Refer to the `example/` for how to deploy it in our clusters

## Updating upstream

To update the upstream version, edit `HELM_VERSION` in the
[`Makefile`](Makefile) and run:

```
make helm
```

Note: requires `helm` v3 and `yq` v3.

This will update the files:
- [`cluster/upstream/gatekeeper.yaml`](cluster/upstream/gatekeeper.yaml)
- [`namespaced/upstream/gatekeeper.yaml`](namespaced/upstream/gatekeeper.yaml)
