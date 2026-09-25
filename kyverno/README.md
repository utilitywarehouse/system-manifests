# kyverno

Deploys kyverno from upstream and a list of policies.

## Overview

There is a `make` target to fetches install.yaml from Kyverno release artifacts
and place it under [upstream dir](./upstream) to act as the remote base for
deploying.

The following kustomize bases are available:

- deploy: Deploys kyverno under `kube-system` namespace
- policies: A set of base policies in `enforce` mode.
- policies-audit-only: Deploys the above base with policies configured to only audit.
- upstream: The fetched upstream manifests wrapped in a kustomize base.

## Policies

Deployed policies include but are not limited to the Pod Security Standards
Baseline list:
https://kyverno.io/policies/?policytypes=Pod%2520Security%2520Standards%2520%28Baseline%29

By default, all policies are in `enforce` mode and will take effect once
applied. Use the [audit-only base](./policies-audit-only) for fresh deployments
to avoid enforcing any rules.

### Vault sidecar injection annotations

The `policies/vault` sidecar-injection policies gained a new scheme - one
boolean annotation per capability (plus a separate pod-wide flag for
fail-open behaviour) - alongside the original single annotation whose value
named the capability. The plain capability policies (`aws`, `gcp-key`,
`gcp-token`, `vault-init-container-aws`) are the _same_ objects as before,
just with `matchConditions` widened to accept either form - no policy was
added, deleted, or renamed. **The old fail-open value is the one exception**:
it's still handled entirely by its own separate, untouched policy
(`inject-vault-sidecar-aws-fail-open` / `-gcp-token-fail-open`), which the
plain policies never match - old and new fail-open are mutually exclusive
annotation values matched by different objects, so nothing needs deleting
for either to work correctly.

One consequence worth knowing: because the plain policies only have one
payload shape, a Pod still on the old **plain** value (e.g.
`vault-sidecar-gcp-token`) gets the new capability-suffixed container name
and (for GCP) the new ports the moment this policy deploys - not only once
its annotation is migrated. Old **fail-open** values are unaffected by this,
since they're handled by the untouched separate policy.

| Capability                                      | Old annotation                                                                 | New annotation                                                                                                                  |
| ----------------------------------------------- | ------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------- |
| AWS                                             | `uw.systems/kyverno-inject-sidecar-request: vault-sidecar-aws`                 | `uw.systems/kyverno-inject-sidecar-request-aws: "true"`                                                                         |
| AWS (fail-open)                                 | `uw.systems/kyverno-inject-sidecar-request: vault-sidecar-aws-fail-open`       | `uw.systems/kyverno-inject-sidecar-request-aws: "true"` **+** `uw.systems/kyverno-inject-sidecar-fail-open: "true"`       |
| AWS init container                              | `uw.systems/kyverno-inject-sidecar-request: vault-init-container-aws`          | `uw.systems/kyverno-inject-sidecar-request-vault-init-container-aws: "true"`                                                    |
| GCP service account key                         | `uw.systems/kyverno-inject-sidecar-request: vault-sidecar-gcp-key`             | `uw.systems/kyverno-inject-sidecar-request-gcp-key: "true"`                                                                     |
| GCP access token                                | `uw.systems/kyverno-inject-sidecar-request: vault-sidecar-gcp-token`           | `uw.systems/kyverno-inject-sidecar-request-gcp-token: "true"`                                                                   |
| GCP access token (fail-open)                    | `uw.systems/kyverno-inject-sidecar-request: vault-sidecar-gcp-token-fail-open` | `uw.systems/kyverno-inject-sidecar-request-gcp-token: "true"` **+** `uw.systems/kyverno-inject-sidecar-fail-open: "true"` |
| AWS + GCP token (combo, legacy only)            | `uw.systems/kyverno-inject-sidecar-request: vault-sidecar-aws-gcp`             | `-request-aws: "true"` **+** `-request-gcp-token: "true"`                                                                       |
| AWS + GCP key (combo, legacy only)              | `uw.systems/kyverno-inject-sidecar-request: vault-sidecar-aws-gcp-key`         | `-request-aws: "true"` **+** `-request-gcp-key: "true"`                                                                         |
| AWS + GCP token (combo, fail-open, legacy only) | `uw.systems/kyverno-inject-sidecar-request: vault-sidecar-aws-gcp-fail-open`   | `-request-aws: "true"` **+** `-request-gcp-token: "true"` **+** `-sidecar-fail-open: "true"`                              |
| GitHub                                          | _(none — net new)_                                                             | `uw.systems/kyverno-inject-sidecar-request-github: "true"`                                                                      |

Notes:

- `uw.systems/kyverno-inject-sidecar-fail-open: "true"` is a pod-wide
  toggle, not per-capability - it applies to every fail-open-capable sidecar
  requested on that pod. AWS and GCP access token support it; GCP service
  account key and the GitHub sidecar do not currently have a fail-open mode.
- The three "legacy only" combo rows have no equivalent new-scheme annotation;
  migrating off them means switching to the separate per-capability
  annotations shown, not a new combo annotation.
- `github.uw.systems/permission-set` is required on the Pod alongside the
  GitHub sidecar annotation above, naming which `vault-plugin-secrets-github`
  permission set to fetch a token for.
- `vault.uw.systems/*` annotations (`aws-role`, `gcp-service-account`,
  `gcp-token-scopes`, `default-sts-ttl`, `default-gcp-key-ttl`, etc.) go on
  `ServiceAccounts` and are read by the vkcc operator to create the
  underlying Vault role or static account.

**When every workload on every cluster has migrated off the old annotation**
(including the combo values), the old fail-open policies
(`inject-vault-sidecar-aws-fail-open`, `-gcp-token-fail-open`) and the three
legacy combo policies can be deleted, and the old-value branch can be dropped
from the plain policies' `matchConditions`.
