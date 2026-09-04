---
name: uw-metrics
description: >
  Use when looking up or querying UW stack runtime metrics (Prometheus/Thanos) via the grafana MCP servers.
  Knows which datasource UID to use per tier and provides light PromQL query examples for common
  questions (up, request rate, error rate, CPU, memory, pod restarts, SLO latency).
---

## Datasource UIDs

`globalthanos` default - federates every provider (aws/gcp/merit).
`thanos` per-provider (aws); `prometheus` per-cluster, short
retention, newest data. Verify with `grafana__list_datasources`.

## Always scope queries

A bare metric on `globalthanos` scans thousands of series (unlabeled
`count(up)` is ~10k); never query without a label selector. Narrow
first (namespace/service/`cluster="<env>-<provider>"`); widen only on
no data. Label/metric discovery tools are metadata - safe.

## Labels by source

`kube_*`/`container_*`: bare `namespace`/`pod`/`container`, no
`kubernetes_*` labels; add `container!=""` for cAdvisor. Pod scrapes
(`up`, `process_*`, app metrics): `kubernetes_namespace` /
`kubernetes_pod_name`. `kubernetes_cluster` is stable across sources.
Check live: `grafana__list_prometheus_label_names` /
`list_prometheus_label_values` (`matches` = `[{name,value,type}]`, not a
bare string) or `topk(1, <metric>)`.

## Querying

`grafana__query_prometheus`: `datasourceUid`, `expr`, `endTime`
(required); `queryType` `instant`|`range`; `range` needs `startTime` +
`stepSeconds`. If unsure a metric exists, discover first:
`grafana__list_prometheus_metric_names` (`datasourceUid`, `regex`).
Histograms: `grafana__query_prometheus_histogram` (`metric`,
`percentile`, `labels`).

Examples:

```
call_tool(name="grafana__query_prometheus",
  arguments={datasourceUid="globalthanos",
    expr="up{kubernetes_namespace=\"<ns>\"} == 0",
    queryType="instant", endTime="now"})

call_tool(name="grafana__query_prometheus",
  arguments={datasourceUid="globalthanos",
    expr="increase(kube_pod_container_status_restarts_total{namespace=\"<ns>\"}[1h]) > 5",
    queryType="instant", endTime="now"})

call_tool(name="grafana__query_prometheus",
  arguments={datasourceUid="globalthanos",
    expr="sum(rate(http_requests_total{service=\"<svc>\",code=~\"5..\"}[5m])) / sum(rate(http_requests_total{service=\"<svc>\"}[5m]))",
    queryType="instant", endTime="now"})
```

Dashboard ask: `grafana__generate_deeplink` (`resourceType`,
`datasourceUid`, `queries`) and stop. Thanos downsamples old data;
recent metrics may only be on per-cluster Prometheus.
