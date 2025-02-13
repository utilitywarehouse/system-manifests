# inject-vault-sidecar

this policy injects vault sidecar container when pods are created based on annotations.

* base: This is the standard policy which inject sidecar as `initContainer` with 
  `startupProbe`, so that main container will only start if vault sidecar is successful

* fail-open: This is patched version of the policy where `startupProbe` is removed.
  The main policy container will be started without waiting on vault sidecar

* legacy: This patched base adds support for legacy `injector.tumblr.com/request` annotation to the `base policy`.