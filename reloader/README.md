# Reloader

This is a base to deploy [Reloader](https://github.com/stakater/Reloader).

Follows manifests from:
https://github.com/stakater/Reloader/tree/master/deployments/kubernetes/manifests
We should manually edit the proposed clusterRole into a simple Role and create
a base for users to opt-in on namespace level. The downside of this approach is
that we will need a deployment for eaach namespace using reloader automation.

- [namespaced](./namespaced) is a base to be used by namespaces that opt in and
allow Reloader to access their resources.

A `make` target is available to help pulling and altering manifests.
