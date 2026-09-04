---
name: uw-traces
description: >
  Use when looking up or querying UW stack distributed traces (Tempo) via the MCP servers.
  Knows which tiers actually expose trace tools, the real (verified live) span/resource attribute set,
  and provides light TraceQL query examples for common questions (find slow/error traces for a service, fetch a trace by ID, correlate to logs).
---

## Datasource

Tempo, UID `tempo`; verify with `grafana__list_datasources`. Confirm a
backend exposes tempo tools with `find_tools` before promising results.

## Key attributes (verified live)

- `service.name` - often `<team>/<service>`, match the full string.
- `k8s.namespace.name`, `k8s.cluster.name`.
- `deployment.environment` (tier), `uw.team` (ownership).
- `service.namespace`, `service.version`, `process.command`,
  `telemetry.sdk.language`.

Span-scoped attributes vary per instrumentation library - check
per-service with `grafana__tempo_get-attribute-names` (`datasourceUid`,
optional `scope`) / `get-attribute-values` (`datasourceUid`, `name`).

## Querying

`grafana__tempo_traceql-search`: `datasourceUid`, `query` (required);
`start`/`end` RFC3339 (defaults to past hour).
`grafana__tempo_get-trace`: `datasourceUid`, `trace_id`.
Metrics from spans: `grafana__tempo_traceql-metrics-instant` / `-range`
(same args). Syntax help: `grafana__tempo_docs-traceql`.

Examples:

```
call_tool(name="grafana__tempo_traceql-search",
  arguments={datasourceUid="tempo",
    query="{ resource.service.name = \"<team>/<service>\" && status = error }",
    start="now-1h", end="now"})
```

```
call_tool(name="grafana__tempo_traceql-search",
  arguments={datasourceUid="tempo",
    query="{ resource.service.name = \"<team>/<service>\" && duration > 500ms }",
    start="now-1h", end="now"})
```

## Cross-reference

Log line with `trace_id`: go straight to `grafana__tempo_get-trace`.
Trace to logs: filter Loki on `kubernetes_namespace` + `trace_id=<id>`
line filter. Tempo `serviceMap` points at `globalthanos` for metrics.
