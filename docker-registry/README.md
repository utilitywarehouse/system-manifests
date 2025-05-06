# docker-registry

This directory provides a Kustomize base for Docker Registry v2, backed by an
S3 bucket and with authentication and authorization provided by
[docker_auth](https://github.com/cesanta/docker_auth).

## Usage

Reference the base in your `kustomization.yaml`:

```
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - github.com/utilitywarehouse/system-manifests/docker-registry/base
components:
  - github.com/utilitywarehouse/system-manifests/docker-registry/components/jwks-updater
```

## Example

Build the example:

```
kustomize build example/
```

## Requires

- https://github.com/kubernetes-sigs/kustomize

## Generating JWKS

In registry version 3 `libtrust` has been deprecated in favour of `go-jose`
which adds a new requirement of generating JWKS in order to keep the auth
working. To get this accomplished we added a `jwks-updater` initContainer which
runs a script that you can find [here](https://github.com/utilitywarehouse/system-manifests/tree/master/docker-registry/components/jwks-updater).  
This script automatically keeps the `jwks.json` up-to-date by watching the
`registry-auth-cert` secret files and using them to generate new JWKS which is
then passed to the `registry` container via the shared volume.
