## Datasource UIDs

`globalthanos` default - federates every provider (aws/gcp/merit).
`thanos` per-provider (aws); `prometheus` per-cluster, short
retention, newest data. Verify with `grafana__list_datasources`.

## Always scope queries

A bare metric on `globalthanos` scans thousands of series
(unlabeled `count(up)` is ~10k); never query without a label
selector. Narrow first (namespace/service/`cluster="<env>-<provider>"`);
widen only on no data. `grafana__list_prometheus_metric_names` is
metadata - safe.

## Labels by source

`kube_*`/`container_*`: bare `namespace`/`pod`/`container`, no
`kubernetes_*` labels; add `container!=""` for cAdvisor. Pod scrapes
(`up`, `process_*`, app metrics): `kubernetes_namespace` /
`kubernetes_pod_name`. `kubernetes_cluster` is stable across
sources. Check live: `grafana__list_prometheus_label_names` or
`topk(1, <metric>)`.

## Querying

`query_prometheus`: `instant` for a value, `range` for a graph
(`startTime` + `stepSeconds`). Example:
`up{kubernetes_namespace="<ns>"} == 0`.

Dashboard ask: `grafana__generate_deeplink` and stop. Thanos
downsamples old data; recent metrics may only be on per-cluster
Prometheus.