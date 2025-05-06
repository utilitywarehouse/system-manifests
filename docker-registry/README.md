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
```

## Example

Build the example:

```
kustomize build example/
```

## Requires

- https://github.com/kubernetes-sigs/kustomize

## Generating JWKS

1. Apply `registry-auth-cert` and save the contents of the secret resource to a file

```
$ kubectl -n example get secret registry-auth-cert -o yaml | yq '.data."ca.crt"' | base64 -d >> cert
$ kubectl -n example get secret registry-auth-cert -o yaml | yq '.data."tls.crt"' | base64 -d >> cert
$ kubectl -n example get secret registry-auth-cert -o yaml | yq '.data."tls.key"' | base64 -d >> cert
```

2. Get `bundle2jwks` from https://github.com/brandond/bundle2jwks
3. Run `bundle2jwks` with the `cert` file to generate JWKS

```
$ bundle2jwks cert
{
  "keys": [
    {
      "kty": "RSA",
      "kid": "4V6G:RPFT:5YP4:YHNF:WDEI:2F6F:JRPI:DXNT:JRDN:BEUB:4ZOO:VT4R",
      "n": "oZpnAF1kemuUTTnWoxzX0bU6NXKTwMANcN6FU-mQSrtsfZXwK7cvM432gb...",
      "e": "AQAB"
    }
  ]
}
```

4. Create a new secret resource with the JWKS and mount it as a new volume in `docker-registry` container
5. Add the `REGISTRY_AUTH_TOKEN_JWKS` env var pointing to the location of the JWKS file

```
- name: REGISTRY_AUTH_TOKEN_JWKS
  value: "/certs/jwks.json"
```
