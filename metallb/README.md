# MetalLB

### Layout
- __upstream__: the original manifest provided in the upstream repo.
- __cluster__: kustomization for cluster resources
- __final-cluster__: rendered manifests for cluster resources.
- __namespaced__: kustomization for namespaced resources
- __final-namespaced__: rendered manifests for namespaced resources.

&nbsp;
### Makefile
- `make get-upstream`: gets the upstream manifest in a single file.
- `make build`: runs separate builds for cluster AND namespaced resources.
- `make: get-upstream` + build.
- `make build-cluster`: builds only cluster resources.
- `make build-namespaced`: builds only namespaced resources.

&nbsp;
### Notes
We run MetalLB Speakers on kube masters slightly differently.
For that reason we have to add an extra [manifest](namespaced/ds-master-speaker.yaml) file.
We __must__ follow any changes in the DaemonSet from upstream.
