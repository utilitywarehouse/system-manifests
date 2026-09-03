#!/bin/sh
# Fetch each cluster's API-server CA from its kube-ca-cert endpoint and
# re-fetch on a schedule. Runs as a restartable init container
# (restartPolicy: Always) so a failed refresh restarts the loop, not the pod.
# Usage: fetch-ca.sh "<name>|<url>" ["<name>|<url>" ...]
# Output: <CA_DIR>/<name>.pem (matches kubeconfig certificate-authority).

set -eu

CA_DIR="${CA_DIR:-/certs}"
REFRESH_INTERVAL="${REFRESH_INTERVAL:-86400}"

# curl retries transient failures (incl. the first-DNS-lookup conntrack race
# in fresh pods) via --retry-all-errors; the PEM check keeps a non-cert
# response (SSO redirect, error page) from poisoning the CA.
fetch_ca() { # name url
  name="$1"
  url="$2"
  dest="${CA_DIR}/${name}.pem"
  tmp="${dest}.tmp"

  if curl -fsSL --max-time 20 --retry 5 --retry-delay 5 --retry-all-errors \
      "$url" -o "$tmp" \
      && grep -q -- '-----BEGIN CERTIFICATE-----' "$tmp"; then
    mv "$tmp" "$dest"
  else
    echo "failed to fetch valid CA for ${name} from ${url}" >&2
    rm -f "$tmp"
    return 1
  fi
}

while :; do
  for entry in "$@"; do
    name="${entry%%|*}"
    url="${entry#*|}"
    fetch_ca "$name" "$url" || true
  done
  sleep "$REFRESH_INTERVAL"
done