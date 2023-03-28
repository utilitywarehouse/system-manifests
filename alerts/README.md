Contains alerts templates under a single base

# Available bases

- common: Contains templates for alerts we deploy everywhere
- cis-aws: Contains templates for alerts based on CIS Benchmark for AWS
- kube-applier: Contains templates for kube-applier alerts

# Environment variables

The following environment variables are used and expected to be patched:
- ENVIRONMENT: exp-1|dev|prod
- PROVIDER: aws|gcp|merit

# Patch inside an init container

Include the needed bases under `kustomization.yaml` like:

```
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - github.com/utilitywarehouse/system-manifests/alerts/common?ref=master
  - github.com/utilitywarehouse/system-manifests/alerts/cis-aws?ref=master
  - github.com/utilitywarehouse/system-manifests/alerts/kube-applier?ref=master
```

Then for each of the above resources mount a volume under
/var/thanos/rule-templates/ dir. Templates configMaps should be expected to
follow the patter `alert-templates-<base-name>`.
Run the following initContainer to render all alerts under the same emptyDir,
which will be shared with thanos-rule container:

```
      initContainers:
        - name: render-alerts
          image: alpine
          env:
            - name: ENVIRONMENT
              value: exp-1
            - name: PROVIDER
              value: aws
          args:
            - /bin/sh
            - -c
            - |
              apk add --no-cache gettext;
              for file in $(ls /var/thanos/rule-templates/*/*.tmpl); do
                f=$(basename $file);
                envsubst '${ENVIRONMENT},${PROVIDER}' < $file > /var/thanos/rules/${f%.*};
              done;
          volumeMounts:
            - name: rules-rendered
              mountPath: /var/thanos/rules
            - name: rule-templates-common
              mountPath: /var/thanos/rule-templates/common/
            - name: rule-templates-cis-aws
              mountPath: /var/thanos/rule-templates/cis-aws/
            - name: rule-templates-kube-applier
              mountPath: /var/thanos/rule-templates/kube-applier/
      volumes:
        - name: rules-rendered
          value:
            emptyDir: {}
        - name: rule-templates-common
          configMap:
            defaultMode: 420
            name: alert-templates-common
        - name: rule-templates-cis-aws
          configMap:
            defaultMode: 420
            name: alert-templates-cis-aws
        - name: rule-templates-kube-applier
          configMap:
            defaultMode: 420
            name: alert-templates-kube-applier
```
