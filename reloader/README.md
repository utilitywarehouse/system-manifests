# Reloader

This is a base to deploy [Reloader](https://github.com/stakater/Reloader) under
kube-system. Follows manifests from:
https://github.com/stakater/Reloader/tree/master/deployments/kubernetes/manifests

- [kube-system](./kube-system) is the output base to be used in order to deploy
Reloader under kube-system namespace with the needed permissions.

A `make` target is available to help pulling and altering manifests.

Note: The deployment needs access to all cluster secrets via a respective
ClusterRole which is not favourable.
