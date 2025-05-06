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
  - github.com/utilitywarehouse/system-manifests/docker-registry/components/jwks-generator
```

## Example

Build the example:

```
kustomize build example/
```

## Requires

- https://github.com/kubernetes-sigs/kustomize

## Generating JWKS

In registry version 3, `libtrust` has been deprecated in favor of `go-jose`,
which requires generating JSON Web Key Sets (JWKS) to maintain authentication.
To achieve this, we added a `jwks-generator` initContainer that runs a script on
pod startup to generate JWKS using the current `tls.key` as input. The JWKS is
placed in a shared volume to be accessed by the registry. When the certificate
is renewed, [Reloader](https://github.com/stakater/Reloader) takes care of
restarting the deployment, triggering the generation of a new JWKS - this is
done using the following annotation:
`secret.reloader.stakater.com/reload: "registry-auth-cert"`.
The `jwks-generator` script can be found [here](https://github.com/utilitywarehouse/system-manifests/tree/master/docker-registry/components/jwks-generator).
