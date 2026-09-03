## Clusters

One kube mcp server serves all clusters in the <env>; target via the `context` parameter
on every tool: `<env>-aws`, `<env>-gcp`, `<env>-merit`.

## Querying

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
