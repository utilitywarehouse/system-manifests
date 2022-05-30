# kyverno
Deploys kyverno from upstream [base](github.com/kyverno/kyverno/config/release)
and a list of policies.

## Overview

* base: Deploys kyverno under `kube-system` namespace and a set of policies in
  `enforce` mode.
* audit-only: Deploys the above base with policies configured to only audit.

## Policies
Deployed policies include but are not limited to the Pod Security Standards
Baseline list:
https://kyverno.io/policies/?policytypes=Pod%2520Security%2520Standards%2520%28Baseline%29

By default, all policies are in `enforce` mode and will take effect once
applied. Use the [audit-only base](./audit-only) for fresh deployments to avoid
enforcing any rules.
