#!/bin/sh
# Fetch each cluster's API-server CA from kube-ca-cert.<env>.<provider>.uw.systems/
# and re-fetch on a schedule.
# Config via env: ENV (tier), CLUSTERS (space-separated providers), CA_DIR,
# REFRESH_INTERVAL. Output: <CA_DIR>/<env>-<provider>.pem (matches kubeconfig).

set -eu

CA_DIR="${CA_DIR:-/certs}"
REFRESH_INTERVAL="${REFRESH_INTERVAL:-86400}"

# curl retries transient failures (incl. the first-DNS-lookup conntrack race
# in fresh pods) via --retry-all-errors; the PEM check keeps a non-cert
# response (SSO redirect, error page) from poisoning the CA.
fetch_ca() { # cluster
  cluster="$1"
  url="https://kube-ca-cert.${ENV}.${cluster}.uw.systems/"
  dest="${CA_DIR}/${ENV}-${cluster}.pem"
  tmp="${dest}.tmp"

  if curl -fsSL --max-time 20 --retry 5 --retry-delay 5 --retry-all-errors \
      "$url" -o "$tmp" \
      && grep -q -- '-----BEGIN CERTIFICATE-----' "$tmp"; then
    mv "$tmp" "$dest"
  else
    echo "failed to fetch valid CA for ${cluster} from ${url}" >&2
    rm -f "$tmp"
    return 1
  fi
}

while :; do
  for cluster in $CLUSTERS; do
    fetch_ca "$cluster" || true
  done
  sleep "$REFRESH_INTERVAL"
done
