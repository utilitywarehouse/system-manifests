# Kured

This is a base to deploy [kured](https://github.com/weaveworks/kured)

Following installation [instructions](https://github.com/weaveworks/kured#installation)
we can fetch a single manifests file to deploy the latest version.
```
make fetch-upstream
```
Following our usual model we need to split cluster resources under a separate
[base](./cluster).

