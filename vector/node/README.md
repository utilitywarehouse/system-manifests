Contains manifests to deploy Vector as a DaemonSet in all cluster nodes to push
logs to Loki. It comprises of 2 different bases:

- `cluster`, where we define RBAC for the vector-node deployment
- `namespaced`, where the deployment and configuration live.

To avoid collision with other vector-deployments we suffix all the related
Kubernetes objects with `-node`.
