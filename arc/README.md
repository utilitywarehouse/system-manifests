# Github's ARC
https://github.com/actions/actions-runner-controller

We chose to run it with a single controller per cluster, with one or several
RunnerSets living on the same namespace, all managed by @system.

## Instructions
* To update the manifests, update the VERSION variable in the Makefile and run `make`.
* To change controller settings, update the controller/values.yaml file (ref: https://github.com/actions/actions-runner-controller/blob/master/charts/gha-runner-scale-set-controller/values.yaml)
* To change runner settings, update the runner/common-values.yaml and/or the runner/<runner>/values.yaml (ref: https://github.com/actions/actions-runner-controller/blob/master/charts/gha-runner-scale-set/values.yaml). The common-values will be overriden by the specific runner values.
* To create a new runner:
  * Create a new dir inside `runner` with the new runner name.
  * Copy a kustomization.yaml file from another runner, and also copy and
    update a values.yaml file, changing at least the `runnerScaleSetName`
    value, to the new runner name.
  * On the Makefile, duplicate an existing generator code and update the RUNNER name.

## ARC vs static runners
* PRO: ARC runner pods do not expose credentials to modify Github's runners (our
  naive static runners implementation does)
* PRO: ARC runner pods are killed after executing a workflow, so they don't
  keep state between runs. This property simplifies configuring actions since the
  output is more predictable
* CON: ARC runner pods are idle until they execute a workflow, and are killed
  afterwards. This means that we can't get reliable usage metrics unless
  workflows take a very long time. It also means high cardinality of the metrics.
  For now, we are not gathering runner pod metrics.
* CON: ARC deployment involves helm templating, with CRDs, roles... while
  static runners require very small manifests

## Team-managed runners
Teams may want to self-manage dedicated runners to give them access to
team-owned private resources.

ARC runners need the secret with github credentials to live in the same
namespace as them, which means that any team that wants to self-manage a runner
set will have access to the credentials that have full self-hosted-runners
permissions (there are no granular permissions).

This fact is true also for the current "naive" implementation of static
self-hosted runners.

The github credentials can be used to hijack other runners and steal the
credentials that are sent to the compromised runners.

An alternative for teams is to let @systems operate a dedicated runner set for
them and give their runners access to their team-private resources with network
policies rules that select only their runners with pod name,label or annotation
selectors.

### Deploying team-managed runners
If teams need a team-managed ARC deployment, the easiest approach would be to
deploy both a new controller and a new runner set on their namespace, by
reusing most of the Makefile code while changing the NAMESPACE variable
(reusing the controller is possible in theory, but not straightforward and not
worth it since it only saves a pod running and has no security benefits).

## Other notes
* The secret holding the github credentials must have the name configured in
  runner/common-values.yaml and be created in the runner's namespace following
  this instructions: https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners-with-actions-runner-controller/authenticating-to-the-github-api#authenticating-arc-with-a-github-app
* Generation of different manifests for different teams and environments is
  done via helm templating instead of relying on kustomize as we usually do.
  The reasons are:
    * Some of the runner configuration is done via helm template values, so we
      can't skip this step. We might as well do *all* the configuration and
      avoid the need for kustomize patches later
    * Kustomize templating is limited and doesn't produce the same output as
      the helm templating. We'd need to be very careful to ensure we don't
      break any github/controller/runner relationship based on names

## Future improvements
* Using the pushgateway to push runner metrics to prometheus before letting the pod die
