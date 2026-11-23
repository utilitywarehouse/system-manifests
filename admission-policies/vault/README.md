# Vault credential injection

These policies inject the Vault credential helpers (`vkcc`) into pods. They
are native `MutatingAdmissionPolicy`/`ValidatingAdmissionPolicy` objects with
`Deny` bindings, enforced by the API server. This group no longer runs through
Kyverno.

- `inject-vault-*.yaml` — mutating policies, one per injection mechanism, each
  with a `not-already-injected` guard so a re-applied policy cannot add a
  second copy of its container.
- `vault-aws-role-arn.yaml` — validates the `vault.uw.systems/aws-role`
  annotation when a ServiceAccount sets it; the value must be a role ARN.
- `vault-github-permission-set.yaml` — requires
  `github.uw.systems/permission-set` on pods that request the GitHub sidecar.

## Paths

Paths on the injected volume, for workloads that cannot use the env vars:

| Payload | Path |
| --- | --- |
| AWS credentials file | `/etc/aws/credentials` |
| AWS profiles | `/etc/aws` (`AWS_CONFIG_FILE=/etc/aws/config`) |
| GCP key | `/gcp/sa.json` |
| GitHub token | `/etc/github/token` |

## Annotations

The sidecar-injection policies use one annotation per provider, valued by an
enum string naming the specific mechanism - `aws-credentials` picks between
the sidecar and the init-container variant, `gcp-credentials` picks between
the token and key flows, and a separate pod-wide
`credentials-inject-failure-policy: "fail-open"` annotation controls
startup-blocking behaviour independently of which provider is requested. This
supersedes the original single annotation whose value named the capability.
The plain capability policies (`aws`, `gcp-key`, `gcp-token`,
`vault-init-container-aws`) accept either the old or the new annotation.

| Capability                                      | Old annotation                                                                 | New annotation                                                                                                                     |
| ----------------------------------------------- | ------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------- |
| AWS (sidecar, HTTP)                             | `uw.systems/kyverno-inject-sidecar-request: vault-sidecar-aws`                 | `vault.uw.systems/aws-credentials: "sts-http"`                                                                                     |
| AWS (sidecar, profiles)                         | _(none — net new)_                                                             | `vault.uw.systems/aws-credentials: "sts-profile"`                                                                                  |
| AWS (fail-open)                                 | `uw.systems/kyverno-inject-sidecar-request: vault-sidecar-aws-fail-open`       | `vault.uw.systems/aws-credentials: "sts-http"` **+** `vault.uw.systems/credentials-inject-failure-policy: "fail-open"`             |
| AWS init container (one-shot, credentials file) | `uw.systems/kyverno-inject-sidecar-request: vault-init-container-aws`          | `vault.uw.systems/aws-credentials: "sts-file"`                                                                                     |
| GCP service account key                         | `uw.systems/kyverno-inject-sidecar-request: vault-sidecar-gcp-key`             | `vault.uw.systems/gcp-credentials: "key-file"`                                                                                     |
| GCP access token                                | `uw.systems/kyverno-inject-sidecar-request: vault-sidecar-gcp-token`           | `vault.uw.systems/gcp-credentials: "token-http"`                                                                                   |
| GCP access token (fail-open)                    | `uw.systems/kyverno-inject-sidecar-request: vault-sidecar-gcp-token-fail-open` | `vault.uw.systems/gcp-credentials: "token-http"` **+** `vault.uw.systems/credentials-inject-failure-policy: "fail-open"`           |
| AWS + GCP token (combo, legacy only)            | `uw.systems/kyverno-inject-sidecar-request: vault-sidecar-aws-gcp`             | `aws-credentials: "sts-http"` **+** `gcp-credentials: "token-http"`                                                                |
| AWS + GCP key (combo, legacy only)              | `uw.systems/kyverno-inject-sidecar-request: vault-sidecar-aws-gcp-key`         | `aws-credentials: "sts-http"` **+** `gcp-credentials: "key-file"`                                                                  |
| AWS + GCP token (combo, fail-open, legacy only) | `uw.systems/kyverno-inject-sidecar-request: vault-sidecar-aws-gcp-fail-open`   | `aws-credentials: "sts-http"` **+** `gcp-credentials: "token-http"` **+** `credentials-inject-failure-policy: "fail-open"`         |
| GitHub                                          | _(none — net new)_                                                             | `vault.uw.systems/github-credentials: "token-file"`                                                                                |

All four new-scheme annotations above live under `vault.uw.systems/*`,
on the **Pod**. This is the same prefix the ServiceAccount-level identity
annotations below use, but a different resource and a different purpose -
these pick a sidecar mechanism, the ServiceAccount ones configure the Vault
role/account itself.

Notes:

- The injected sidecar starts before any user init container, so an init
  container that reads credentials from the sidecar can rely on it being
  there. Fail-open sidecars skip their startup probe and may start before
  the credentials are ready.
- `vault.uw.systems/credentials-inject-failure-policy: "fail-open"` is a
  pod-wide toggle, not per-capability - it applies to every fail-open-capable
  sidecar requested on that pod. AWS and GCP access token support it; GCP
  service account key and the GitHub sidecar do not currently have a
  fail-open mode.
- `aws-credentials` and `gcp-credentials` are each a single annotation
  shared by two mutually-exclusive mechanisms (sidecar vs. init container
  for AWS; token vs. key for GCP) - the value picked, not the annotation's
  presence, determines which policy matches and which payload gets
  injected.
- The three "legacy only" combo rows have no equivalent new-scheme annotation;
  migrating off them means switching to the separate per-provider
  annotations shown, not a new combo annotation.
- `github.uw.systems/permission-set` is required on the Pod alongside the
  GitHub sidecar annotation above, naming which `vault-plugin-secrets-github`
  permission set to fetch a token for.
- `vault.uw.systems/*` annotations on **ServiceAccounts** (`aws-role`,
  `gcp-service-account`, `gcp-token-scopes`, `default-sts-ttl`,
  `default-gcp-key-ttl`, etc.) are read by the vkcc operator to create the
  underlying Vault role or static account.
- `aws-credentials: "sts-profile"` is a separate, opt-in policy. It disables
  the sidecar HTTP endpoint, publishes one profile per role into a shared
  memory volume, and sets `AWS_CONFIG_FILE` and `AWS_SDK_LOAD_CONFIG=1` on the
  workload and init containers. The latter is required by AWS SDK for Go v1
  to read the config file; other SDKs ignore it. SDKs use the `default`
  profile when `AWS_PROFILE` is unset; set it only to choose another profile.
  It requires a VKCC image with multi-role
  profile support. Its startup probe holds the following init containers until
  the first profiles are ready; fail-open pods skip the probe and may start
  them before profiles exist.
- Do not combine `sts-profile` with `uw.systems/kyverno-inject-sidecar-request`;
  the legacy labels are handled by the existing policies and would inject a
  second AWS sidecar.

The `VKCC_VAULT_ROLE` value is built from the namespace, ServiceAccount and
the cluster environment. The environment prefix (`dev`, `exp-1`, `prod`) comes
from a `vkac_env` variable patched per cluster in
`kubernetes-manifests/<cluster>/kube-system/admission-policies/kustomization.yaml`.

**When every workload on every cluster has migrated off the old annotation**
(including the combo values), the old fail-open policies
(`inject-vault-sidecar-aws-fail-open`, `-gcp-token-fail-open`) and the three
legacy combo policies can be deleted, and the old-value branch can be dropped
from the plain policies' `matchConditions`.
