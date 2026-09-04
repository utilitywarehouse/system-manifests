---
name: uw-kubernetes
description: >
  Use when inspecting Kubernetes resources (pods, deployments, services, events, CRDs)
  via the kube MCP server. Read-only. Knows how to target a cluster via the `context`
  parameter and the key read-only tools with their arguments. Prefer Grafana
  (uw-logs/uw-metrics/uw-traces) for logs, metrics and traces.
---

## Querying

Every tool targets a cluster via the `context` parameter.

`kubernetes__pods_list_in_namespace` (`namespace`, `context`) for pods;
`kubernetes__pods_log` (`namespace`, `name`) for logs;
`kubernetes__resources_list` / `resources_get` (`apiVersion`, `kind`,
e.g. `v1 Service`, `apps/v1 Deployment`) for any resource incl. CRDs.
`kubernetes__events_list` for warnings. Node/pod CPU/mem:
`kubernetes__nodes_top` / `kubernetes__pods_top`.

Example:

```
call_tool(name="kubernetes__pods_list_in_namespace",
  arguments={context="<env>-gcp", namespace="<ns>"})
```

```
call_tool(name="kubernetes__resources_list",
  arguments={context="<env>-aws", apiVersion="apps/v1",
    kind="Deployment", namespace="<ns>"})
```

```
call_tool(name="kubernetes__pods_log",
  arguments={context="<env>-merit", namespace="<ns>", name="<pod>"})
```

Prefer Grafana (`kb__uw-logs`, `kb__uw-metrics`, `kb__uw-traces`) for
metrics/logs/traces; use kube for resource-level inspection.
