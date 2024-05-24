localize:
	kustomize localize "https://github.com/traefik/traefik-helm-chart//traefik/crds?ref=62d7a9be592b552965fb690681b6f4f8865ce792" # valid for v2.10.3
	rm localized-crds-62d7a9be592b552965fb690681b6f4f8865ce792/traefik/crds/traefik.io_* # remove the traefik.io CRD manifests
	sd '\- traefik.io_.*\n' '' localized-crds-62d7a9be592b552965fb690681b6f4f8865ce792/traefik/crds/kustomization.yaml # remove from kustomization.yaml
	kustomize localize "https://github.com/traefik/traefik-helm-chart//traefik/crds?ref=a429dd01418a0eeeb35a84019945e211148db69b" # valid for v3.0.0
