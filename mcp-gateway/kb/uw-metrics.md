## Datasource UIDs (verify per environment with `grafana__list_datasources`)

| UID            | Use                                                                |
| -------------- | ------------------------------------------------------------------ |
| `globalthanos` | **Default.** Federates every provider (aws/gcp/merit).             |
| `thanos`       | Per-provider (aws) shared Thanos - namespaces the global may drop. |
| `prometheus`   | Per-cluster, short retention, most recent data.                    |

## Cost rule: always scope queries

`globalthanos` federates every cluster/provider; a bare metric name
scans thousands of series (unlabeled `count(up)` is ~10k). Never run
`up == 0` or any query without a label selector. Narrow first
(pod/service/namespace, or `cluster="<env>-<provider>"`), widen only
on no data. `grafana__list_prometheus_metric_names` is metadata, not
a scan - safe.

## Labels by metric source (verified live)

The k8s labels depend on the exporter:

| Source                                               | Namespace/pod labels                                |
| ---------------------------------------------------- | --------------------------------------------------- |
| kube-state-metrics (`kube_*`)                        | `namespace`, `pod`, `node`, `container`             |
| cAdvisor (`container_*`)                             | `namespace`, `pod`, `container`, `instance` (=node) |
| Pod scrapes (`up`, `process_*`, `go_*`, app metrics) | `kubernetes_namespace`, `kubernetes_pod_name`       |

Gotchas: `kube_*` and `container_*` do NOT carry `kubernetes_*`
labels - use bare `namespace`/`pod`. cAdvisor also emits
pod/namespace-level aggregates; add `container!=""`. `kubernetes_cluster`
is the stable cluster label across sources. Don't assume - check labels
live with `grafana__list_prometheus_label_names` (`matches=[{label:"__name__",
value:"<m>"}]`) or `topk(1, <metric>)`.

## Examples (globalthanos, always scoped)

```
call_tool(name="grafana__query_prometheus",
  arguments={datasourceUid="globalthanos",
    expr="up{kubernetes_namespace=\"<ns>\"} == 0", queryType="instant"})

call_tool(name="grafana__query_prometheus",
  arguments={datasourceUid="globalthanos",
    expr="topk(10, sum by(pod)(rate(container_cpu_usage_seconds_total{namespace=\"<ns>\",container!=\"\"}[5m])))",
    queryType="instant"})

call_tool(name="grafana__query_prometheus",
  arguments={datasourceUid="globalthanos",
    expr="increase(kube_pod_container_status_restarts_total{namespace=\"<ns>\"}[1h]) > 5",
    queryType="instant"})

call_tool(name="grafana__query_prometheus",
  arguments={datasourceUid="globalthanos",
    expr="sum(rate(http_requests_total{service=\"<svc>\",code=~\"5..\"}[5m])) / sum(rate(http_requests_total{service=\"<svc>\"}[5m]))",
    queryType="instant"})
```

## Tools

- `grafana__list_datasources` / health checks before querying.
- `grafana__list_prometheus_metric_names` (regex) - call first if
  unsure a metric exists.
- `grafana__list_prometheus_label_names` / `grafana__list_prometheus_label_values` -
  `matches` is `[{label,value}]`, not a bare string.
- `grafana__query_prometheus` - `instant` for a value, `range` for a
  graph (needs `startTime` + `stepSeconds`).
- `grafana__query_prometheus_histogram`, `grafana__generate_deeplink`.

## Steps

1. Default `globalthanos`; fall back to `thanos`/`prometheus` for very
   recent or globally-dropped data.
2. If unsure the metric exists, list names first, then query with
   narrow labels.
3. Dashboard ask? `grafana__generate_deeplink` and stop.

## Notes

- Thanos downsamples/ages out old data; recent short-scrape metrics
  may only be on the per-cluster Prometheus.
