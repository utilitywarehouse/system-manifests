# external-dns

### Update procedure
- Update `Makefile` with the new target commit reference.
- Check [upstream](https://github.com/kubernetes-sigs/external-dns/tree/master/kustomize) in case the are new resources defined.
- Run `make` to fetch the updated upstream manifests.
- Push to this repo.
