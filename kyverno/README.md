# kyverno
Deploys kyverno from upstream and a list of policies.

## Overview
There is a `make` target to fetches install.yaml from Kyverno release artifacts
and place it under [remote dir](./remote) to act as the remote base for
deploying.

The following kustomize bases are available:
* audit-only: Deploys the above base with policies configured to only audit.
* base: Deploys kyverno under `kube-system` namespace and a set of policies in
  `enforce` mode.
* remote: The fetched upstream manifests wrapped in a kustomize base.

## Policies
Deployed policies include but are not limited to the Pod Security Standards
Baseline list:
https://kyverno.io/policies/?policytypes=Pod%2520Security%2520Standards%2520%28Baseline%29

By default, all policies are in `enforce` mode and will take effect once
applied. Use the [audit-only base](./audit-only) for fresh deployments to avoid
enforcing any rules.
