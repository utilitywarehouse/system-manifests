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
per-service with `grafana__list_tempo_attribute_names` (`datasourceUid`,
optional `scope`; set it, unscoped results can be very large) /
`grafana__list_tempo_attribute_values` (`datasourceUid`, `name`).

## Querying

`grafana__search_tempo_traces`: `datasourceUid`, `query` (required);
optional `start`/`end` in RFC3339 (defaults to the past hour), `limit`
(default 20) and `spss` (default 3).
`grafana__get_tempo_trace`: `datasourceUid`, `trace_id`; optional
`start`/`end` narrow the lookup and `focus_span_id` selects an initial span.
Metrics from spans: `grafana__query_tempo_metrics` with `datasourceUid`,
`query`, optional `start`/`end` in RFC3339, and `type` (`instant` or
`range`; default `range`).
Trace diffs: `grafana__diff_tempo_traces` with `datasourceUid`,
`base_trace_id` and `compare_trace_id`.
Syntax help: `grafana__get_tempo_traceql_docs` with `topic` (`basic`,
`aggregates`, `structural` or `metrics`).

Examples:

```
call_tool(name="grafana__search_tempo_traces",
  arguments={datasourceUid="tempo",
    query="{ resource.service.name = \"<team>/<service>\" && status = error }"})
```

```
call_tool(name="grafana__search_tempo_traces",
  arguments={datasourceUid="tempo",
    query="{ resource.service.name = \"<team>/<service>\" && duration > 500ms }"})
```

## Cross-reference

Log line with `trace_id`: go straight to `grafana__get_tempo_trace`.
Trace to logs: filter Loki on `kubernetes_namespace` + `trace_id=<id>`
line filter. Tempo `serviceMap` points at `globalthanos` for metrics.
