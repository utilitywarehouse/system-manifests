## Datasource UID

`tempo` - confirmed via `grafana__list_datasources` (`type: tempo`,
`uid: tempo`). If unsure, confirm with `grafana__list_datasources`.

## Key attributes to start a search

**Verified live** with `grafana__tempo_get-attribute-names(datasourceUid="tempo", scope="resource")`
via the local gateway:

| Attribute                                                        | Example                                           | Notes                                                                        |
| ---------------------------------------------------------------- | ------------------------------------------------- | ---------------------------------------------------------------------------- |
| `service.name`                                                   | `energy-smart/energy-dcc-adapter-usmart-consumer` | Often `<team>/<service>`, not just the bare service - match the full string. |
| `k8s.namespace.name`                                             |                                                   |                                                                              |
| `k8s.cluster.name`                                               |                                                   |                                                                              |
| `deployment.environment` / `deployment.environment.name`         |                                                   | tier                                                                         |
| `uw.team`                                                        |                                                   | ownership label, when present                                                |
| `service.namespace`, `service.version`                           |                                                   |                                                                              |
| `process.command`, `process.pid`, `process.runtime.name/version` |                                                   |                                                                              |
| `telemetry.sdk.language/name/version`                            |                                                   |                                                                              |

Span-scoped attributes (call with `scope="span"`) vary per
instrumentation library - check per-service before assuming a name.

## Cross-referencing with logs and metrics

The on-prem Loki datasource has a `derivedFields` config that turns
`trace_id=...`/`traceID=...` seen in a log line into a link to
Tempo, and Tempo's datasource config points `tracesToLogsV2` back at
Loki with a query built from `deployment.environment` /
`k8s.namespace.name`-style tags. Practically: if you have a
`trace_id` from a log line, use it directly with
`grafana__tempo_get-trace`; if you have a trace and want the logs,
filter Loki on `kubernetes_namespace` + a `trace_id=<id>` line filter
(see the uw-logs knowledge base). Tempo's `serviceMap` points at the
`globalthanos` datasource for correlating span service names to
metrics (see the uw-metrics knowledge base).

## Tools

- `grafana__list_datasources` / `grafana__get_datasource` - confirm the Tempo datasource exists before anything else.
- `grafana__tempo_get-attribute-names` / `grafana__tempo_get-attribute-values` - discover what you can filter on; optionally scoped (`span`, `resource`, `event`, `link`, `instrumentation`).
- `grafana__tempo_docs-traceql` - TraceQL syntax help if unsure how to phrase a query.
- `grafana__tempo_traceql-search` - the main search tool. `query` is a TraceQL string, `start`/`end` RFC3339 (defaults to the past hour).
- `grafana__tempo_get-trace` - fetch one trace by ID.
- `grafana__tempo_traceql-metrics-instant` / `grafana__tempo_traceql-metrics-range` - TraceQL metrics (e.g. span rate/error rate/latency derived from trace data), instant or range.

## Examples

All traces for a service in the last hour:

```
call_tool(name="grafana__tempo_traceql-search",
  arguments={datasourceUid="tempo",
    query="{ resource.service.name = \"<team>/<service>\" }"})
```

Slow traces for a service (>500ms):

```
call_tool(name="grafana__tempo_traceql-search",
  arguments={datasourceUid="tempo",
    query="{ resource.service.name = \"<team>/<service>\" && duration > 500ms }"})
```

Errored spans for a service:

```
call_tool(name="grafana__tempo_traceql-search",
  arguments={datasourceUid="tempo",
    query="{ resource.service.name = \"<team>/<service>\" && status = error }"})
```

Fetch a specific trace (e.g. found via a `trace_id` in a log line):

```
call_tool(name="grafana__tempo_get-trace",
  arguments={datasourceUid="tempo", trace_id="<trace_id>"})
```

Verified live via the local gateway: an unfiltered
`grafana__tempo_traceql-search(query="{ }")` returned real traces
spanning many teams (`energy-smart`, `telecom-fixed-line`,
`energy-platform`, `auth`, `payment-platform`, `cbc`, `acs`,
`corp-netapp-audit`, `my-account`), confirming `rootServiceName` is
commonly `<team>/<service>` and `serviceStats` breaks a trace down per
hop with `spanCount`/`errorCount`.

## Steps

1. If unsure what's queryable, `grafana__tempo_get-attribute-names`
   (and `grafana__tempo_get-attribute-values` for a specific
   attribute) before writing TraceQL.
2. Use `grafana__tempo_traceql-search` to find candidate traces, then
   `grafana__tempo_get-trace` on a specific `traceID` for the full
   span tree.
3. Match `service.name` as the full `<team>/<service>` string unless
   you've confirmed otherwise for that service.
4. If the user has a `trace_id` from a log line, go straight to
   `grafana__tempo_get-trace` rather than searching.

## Notes

- Confirm a backend exposes tempo tools with `find_tools` before
  promising trace results.
