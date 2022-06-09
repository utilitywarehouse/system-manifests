# external-dns

### Update procedure
- Update `Makefile` with the new target commit reference.
- Check [upstream](https://github.com/kubernetes-sigs/external-dns/tree/master/kustomize) in case the are new resources defined.
    - Versioning / tagging on this repo might be unreliable, commit references are preferred.
    - For this reason, `kustomize.yaml` is __not__ used as is, plus a [patch](patches/deploy.yaml) is added.
- Run `make` to fetch the updated upstream manifests.
- Update [kustomization.yaml](./kustomization.yaml) with the new image tag.
