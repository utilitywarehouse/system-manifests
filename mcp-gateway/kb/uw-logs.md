---
name: uw-logs
description: >
  Use when looking up or querying UW stack logs (Loki) via the MCP servers
  Knows which datasource UID to use per tier, the real (verified live) log label set,
  and provides light LogQL query examples for common questions (recent pod logs, error grep, label listing, range tail).
---

## Datasource

Loki, UID `loki`; verify with `grafana__list_datasources`. Gateway is read-only.

## Labels

Use k8s-prefixed labels, never bare names: `kubernetes_namespace`,
`kubernetes_pod_name`, `kubernetes_container`, `kubernetes_cluster`
(verified live - not `namespace`/`pod`/`container`). Also useful:
`app`/`service_name`, `uw_environment`, `cloud_provider`, `log_source`
(Vector), `syslog_identifier`, `systemd_unit`, `hostname`. Sets drift per
time-range; check live with `grafana__list_loki_label_names`
(`datasourceUid`) / `grafana__list_loki_label_values` (`datasourceUid`,
`labelName`) before relying on one.

## Querying

`grafana__query_loki_logs`: `datasourceUid`, `logql` (required);
`startRfc3339`/`endRfc3339`, `limit`, `queryType` (`range` default |
`instant`). `queryType: instant` + `count_over_time()` counts lines
precisely (stats are approximate). `grafana__query_loki_stats`
(`datasourceUid`, `logql` - bare selector only) is a cheap existence
check first. Add filters liberally; Loki rewards narrow selectors.
Error grep: `|~ "(?i)error|exception|panic"`.

Examples:

```
call_tool(name="grafana__query_loki_logs",
  arguments={datasourceUid="loki",
    logql="{kubernetes_namespace=\"<ns>\"} |~ \"(?i)error\"",
    startRfc3339="now-10m", endRfc3339="now", limit=100})
```

```
call_tool(name="grafana__query_loki_logs",
  arguments={datasourceUid="loki",
    logql="sum(count_over_time({kubernetes_namespace=\"<ns>\"}[1h])) by (kubernetes_pod_name)",
    queryType="instant", endRfc3339="now"})
```

Also available: `grafana__query_loki_patterns` (mine a selector's log
shapes), `grafana__analyze_loki_labels` (label strategy audit).

Dashboard ask: point at Grafana and stop.

## Notes

Loki exists only on the aws cluster per environment - no
cross-provider or gcp/merit Loki.
