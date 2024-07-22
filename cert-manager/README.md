# cert-manager manifests

This is an opinionated Kustomize deployment of cert-manager. We run everything
inside `kube-system` namespace, and so manifests and patches are tailored
towards that.

## updating

1. Update version inside Makefile
2. Run `make get-yaml` to update the upstream manifest
