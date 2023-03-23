Contains alerts templates under a single base

# Available bases

- common: Contains templates for alerts we deploy everywhere
- aws: Appends common base with alerts only for aws clusters

# Environment variables

The following environment variables are used and expected to be patched:
- ENVIRONMENT: exp-1|dev|prod
- PROVIDER: aws|gcp|merit

# Patch inside an init container

One way to patch is using `envsubst` inside an init container in the ruler
deployment. For example:

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
              for file in $(ls /var/thanos/rule-templates/*.tmpl); do
                f=$(basename $file);
                envsubst '${ENVIRONMENT},${PROVIDER}' < $file > /var/thanos/rules/${f%.*};
              done;
          volumeMounts:
            - name: rules-rendered
              mountPath: /var/thanos/rules
            - name: rule-templates
              mountPath: /var/thanos/rule-templates
      volumes:
        - name: rules-rendered
          value:
            emptyDir: {}
        - name: rule-templates
          configMap:
            defaultMode: 420
            name: alerts
```
