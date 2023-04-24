# kyverno
Deploys kyverno from upstream and a list of policies.

## Overview
There is a `make` target to fetches install.yaml from Kyverno release artifacts
and place it under [upstream dir](./upstream) to act as the remote base for
deploying.

The following kustomize bases are available:
* deploy: Deploys kyverno under `kube-system` namespace
* policies: A set of base policies in `enforce` mode.
* policies-audit-only: Deploys the above base with policies configured to only audit.
* upstream: The fetched upstream manifests wrapped in a kustomize base.

## Policies
Deployed policies include but are not limited to the Pod Security Standards
Baseline list:
https://kyverno.io/policies/?policytypes=Pod%2520Security%2520Standards%2520%28Baseline%29

By default, all policies are in `enforce` mode and will take effect once
applied. Use the [audit-only base](./policies-audit-only) for fresh deployments
to avoid enforcing any rules.
