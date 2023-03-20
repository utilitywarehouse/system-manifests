# external-dns

### Update procedure
Update kustomize remote base reference in [kustomization.yaml](./kustomization.yaml)
with the new version.

Note: the remote base might lack an image version, so we may have to patch image
if we want to deploy latest.

Note: remote `ClusterRoleBinding` binds to external-dns SA under default
namespace. We leave that as is here, since we suffix names and patch downstream
per environment.
