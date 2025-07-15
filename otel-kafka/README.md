Kustomize base to deploy a kafka cluster based on bitnami manifests.

This is particularly tailored for otel namespace as we need to be passing a
namespace value to bitnami helm charts in order to properly set names for all
services used during cluster initialisation.

In this base we should try to keep things as simple as possible and only
contain manifests for a kafka cluster as close as possible to the bitnami
upstream.In order to successfully deploy, one needs to deploy the following:

- A `Secret` resource named `kafka-kraft` where we will keep the cluster and
  controllers uuid.
```
apiVersion: v1
data:
  cluster-id: XXXXXXXXXXXXXXXXXXXXXXXXXXXXX==
  controller-0-id: XXXXXXXXXXXXXXXXXXXXXXXXXXXXX==
  controller-1-id: XXXXXXXXXXXXXXXXXXXXXXXXXXXXX==
  controller-2-id: XXXXXXXXXXXXXXXXXXXXXXXXXXXXX==
kind: Secret
metadata:
  name: kafka-kraft
type: Opaque

```

- A `Secret` resource names `kafka-tls-passwords` where passwords for the
  keystores are set. This is a requirement by the upstream manifests generator,
  even though in our case where we use cert-manager to deploy a CA and
  certificates we could have avoid it.
```
apiVersion: v1
data:
  keystore-password:   XXXXXXXXXXXXXX==
  truststore-password: XXXXXXXXXXXXXX==
kind: Secret
metadata:
  name: kafka-tls-passwords
type: Opaque
```
