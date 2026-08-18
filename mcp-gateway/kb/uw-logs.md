## Datasource UID

`loki` - confirmed via `grafana__list_datasources` on the
gateway (`type: loki`, `uid: loki`). If unsure, confirm with
`grafana__list_datasources` rather than assuming.

## Tool access

All grafana tools are namespaced `grafana__<tool>` and invoked through
`call_tool(name="grafana__<tool>", arguments={...})` where `arguments`
is a JSON object. Run `find_tools` (e.g. pattern `(?i)loki`) to
discover what's available before calling.

## Key labels to start a search

**Verified live** with `grafana__list_loki_label_names(datasourceUid="loki")`
via the local gateway - this supersedes any older doc that says
`namespace`/`pod`/`container`, which are wrong:

| Label                                                                                             | Example                 | Notes                                     |
| ------------------------------------------------------------------------------------------------- | ----------------------- | ----------------------------------------- |
| `kubernetes_namespace`                                                                            | `sys-mon`               | not `namespace`                           |
| `kubernetes_pod_name`                                                                             | `prometheus-customer-0` | not `pod`                                 |
| `kubernetes_container`                                                                            | `prometheus`            | not `container`                           |
| `kubernetes_cluster`                                                                              | `<env>-<provider>`      |                                           |
| `app` / `app_kubernetes_io_name`                                                                  | `prometheus`            | depends whether the pod carries the label |
| `service_name`                                                                                    | `prometheus`            |                                           |
| `uw_environment`                                                                                  | `<env>`                 | tier                                      |
| `cloud_provider`                                                                                  | `aws`                   |                                           |
| `log_source`                                                                                      | `cloudflare`, `s3`      | Vector custom                             |
| `kafka_broker`                                                                                    |                         | Vector custom                             |
| `syslog_identifier`, `systemd_unit`, `hostname`, `log_cluster`, `log_hostname`, `log_machinerole` |                         | non-k8s sources                           |

K8s labels depend on the pod carrying them - check with
`grafana__list_loki_label_names` / `grafana__list_loki_label_values`
before relying on one, per-time-range, since the live set can drift.

## Tools

- `grafana__list_datasources` / `grafana__get_datasource` / `grafana__check_datasources_health` - confirm the Loki datasource is healthy.
- `grafana__list_loki_label_names` / `grafana__list_loki_label_values` - discover labels before querying; cheap.
- `grafana__query_loki_stats` - cheap index-level check that a stream has data (streams/chunks/entries/bytes) before running an expensive query. Only accepts a bare label selector, no filters/parsers.
- `grafana__query_loki_logs` - the main query tool. `queryType: range` (default) or `instant`. Use a `count_over_time()` metric expression with `queryType: instant` to count matching lines precisely (stats endpoint counts are approximate).
- `grafana__query_loki_patterns` - pattern-mine a selector.
- `grafana__analyze_loki_labels` - audits a label strategy/cardinality; useful if the user is designing new labels, not just searching.

## Examples

Recent logs from one pod:

```
call_tool(name="grafana__query_loki_logs",
  arguments={datasourceUid="loki",
    logql="{kubernetes_namespace=\"<ns>\",kubernetes_pod_name=\"<pod>\"}",
    startRfc3339="now-5m", endRfc3339="now", limit=100})
```

Grep errors across a namespace:

```
call_tool(name="grafana__query_loki_logs",
  arguments={datasourceUid="loki",
    logql="{kubernetes_namespace=\"<ns>\"} |~ \"(?i)error|exception|panic\"",
    startRfc3339="now-10m", endRfc3339="now", limit=100})
```

Count log lines per pod in the last hour:

```
call_tool(name="grafana__query_loki_logs",
  arguments={datasourceUid="loki",
    logql="sum(count_over_time({kubernetes_namespace=\"<ns>\"}[1h])) by (kubernetes_pod_name)",
    queryType="instant", endRfc3339="now"})
```

Cheap existence check before a heavier query:

```
call_tool(name="grafana__query_loki_stats",
  arguments={datasourceUid="loki", logql="{kubernetes_namespace=\"<ns>\"}",
    startRfc3339="now-1h", endRfc3339="now"})
```

Verified live via the local gateway: `grafana__query_loki_stats` on
`{kubernetes_namespace="sys-mon"}` returned 49 streams / 1839 entries
in the last hour; the log lines carry labels `app`,
`app_kubernetes_io_name`, `cloud_provider`, `kubernetes_cluster`,
`kubernetes_container`, `kubernetes_namespace`, `kubernetes_pod_name`,
`service_name`, `uw_environment`.

## Steps

1. Use the `grafana__*` tools via `call_tool`; the gateway is
   read-only.
2. `grafana__query_loki_stats` or `grafana__list_loki_label_values`
   as a cheap sanity check before a heavier query, especially on a
   selector you haven't confirmed has data.
3. Pick the closest example above. Use `kubernetes_namespace` /
   `kubernetes_pod_name` / `kubernetes_container`, not the bare
   k8s names - add filters liberally, Loki rewards narrow selectors.
4. `grafana__query_loki_logs` with `queryType: instant` for a
   count/single value, `range` for a slice of logs or a time series.
5. If the user asks for a dashboard, point them at Grafana and stop.

## Notes

- Loki lives only on the aws cluster per environment - there is no
  cross-provider or gcp/merit Loki.
