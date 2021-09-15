# gatekeeper

Kustomize bases to deploy Open Policy Agent gatekeeper.

## Usage

The resources are divided into two bases:

- `cluster` - cluster scoped resources
- `namespaced` - namespaced resources

Reference them in your `kustomization.yaml`, like so:

```
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
bases:
  - github.com/utilitywarehouse/system-manifests/gatekeeper/cluster
  - github.com/utilitywarehouse/system-manifests/gatekeeper/namespaced
```

Define the gatekeeper configuration suitable for your environment.

Refer to the `example/`.

Note that you need to [provide the `ClusterRoleBinding` for gatekeeper's service
account](example/rbac.yaml). This is required in order to keep the base namespace-agnostic.

## Update

To update the upstream version, edit `HELM_VERSION` in the
[`Makefile`](Makefile) and run:

```
make helm
```

Note: requires `helm` v3 and `yq` v3.

This will update the files:
- [`cluster/gatekeeper.yaml`](cluster/gatekeeper.yaml)
- [`namespaced/gatekeeper.yaml`](namespaced/gatekeeper.yaml)

Patch changes on top of the upstream in the patches:
- [`cluster/gatekeeper-patch.yaml`](cluster/gatekeeper-patch.yaml)
- [`namespaced/gatekeeper-patch.yaml`](namespaced/gatekeeper-patch.yaml)


## Templates

Our library of `ConstraintTemplates` can also be pulled in as a base. See [gatekeeper-template-manifests](https://github.com/utilitywarehouse/gatekeeper-template-manifests).
