## Datasource

Tempo, UID `tempo`; verify with `grafana__list_datasources`.

## Key attributes to start a search

Verified live via `grafana__tempo_get-attribute-names` (scope
`resource`):

- `service.name` - often `<team>/<service>`, match the full string.
- `k8s.namespace.name`, `k8s.cluster.name`.
- `deployment.environment` (tier), `uw.team` (ownership).
- `service.namespace`, `service.version`, `process.command`,
  `telemetry.sdk.language`.

Span-scoped attributes (`scope="span"`) vary per instrumentation
library - check per-service before assuming.

## Cross-reference

Log line with `trace_id`: go straight to `grafana__tempo_get-trace`.
Trace to logs: filter Loki on `kubernetes_namespace` +
`trace_id=<id>` line filter. Tempo `serviceMap` points at
`globalthanos` for metrics.

## Tools

`grafana__tempo_traceql-search` (TraceQL string, `start`/`end`
RFC3339, defaults to past hour) finds candidates;
`grafana__tempo_get-trace` fetches one trace by ID;
`grafana__tempo_traceql-metrics-instant` / `-range` derive
rate/error/latency from spans; `grafana__tempo_docs-traceql` covers
syntax. Queries: `{ resource.service.name = "<team>/<service>"
&& status = error }`.

## Notes

Confirm a backend exposes tempo tools with `find_tools` first.