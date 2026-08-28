## Datasource

Loki, UID `loki`; verify with `grafana__list_datasources` if unsure.

## Tool access

Tools are `grafana__<tool>`, called via
`call_tool(name="grafana__<tool>", arguments={...})`; discover with
`find_tools`. Gateway is read-only.

## Labels

Use k8s-prefixed labels, never bare names: `kubernetes_namespace`,
`kubernetes_pod_name`, `kubernetes_container`, `kubernetes_cluster`
(verified live - not `namespace`/`pod`/`container`). Also useful:
`app`, `service_name`, `uw_environment`, `cloud_provider`,
`log_source` (Vector), `syslog_identifier`, `systemd_unit`,
`hostname`. Sets drift per time-range; check live with
`grafana__list_loki_label_names` / `grafana__list_loki_label_values`
before relying on one.

## Querying

`grafana__query_loki_stats` (bare selector only) is a cheap
existence check before heavy queries. `grafana__query_loki_logs`:
`queryType: instant` with `count_over_time()` counts lines precisely
(stats are approximate); `range` slices logs. Add filters liberally;
Loki rewards narrow selectors. Errors:
`|~ "(?i)error|exception|panic"`.

Dashboard ask: point at Grafana and stop.

## Notes

Loki exists only on the aws cluster per environment - no
cross-provider or gcp/merit Loki.