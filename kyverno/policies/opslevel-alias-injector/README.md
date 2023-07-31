# OpsLevel Alias Injector

This is a [mutating cluster
policy](https://kyverno.io/docs/writing-policies/mutate/) to inject the [unique
service
identifier](https://linear.app/utilitywarehouse/issue/DENA-149/allow-associating-the-kubernetes-resources-with-opslevel-id)
alias we generate for each service in OpsLevel, it injects:

  - An annotation: `app.uw.systems/opslevel-service-alias`
  - An environment variable: `OPSLEVEL_SERVICE_ALIAS` (inside any container in
    the spec)

Into the spec for Deployments, CronJobs, and StatefulSets so that they are
available to pods created under these replica controllers.
