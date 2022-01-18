# MetalLB

### Layout
- __upstream__: the original manifest provided in the [upstream](https://github.com/metallb/metallb) repo.
- __cluster__: kustomization for cluster resources.
- __final-cluster__: rendered manifests for cluster resources.
- __namespaced__: kustomization for namespaced resources.
- __final-namespaced__: rendered manifests for namespaced resources.

### Makefile
- `make get-upstream`: gets the upstream manifest in a single file.
- `make build`: runs Kustomize builds for all the resources.
- `make`: get-upstream + build.
- `make build-cluster`: builds only cluster resources.
- `make build-namespaced`: builds only namespaced resources.

### Notes
We run MetalLB Speakers on kube masters slightly differently.
For that reason we have to add an extra [manifest](namespaced/ds-master-speaker.yaml) file.
We __must__ follow any changes in the DaemonSet from upstream.
