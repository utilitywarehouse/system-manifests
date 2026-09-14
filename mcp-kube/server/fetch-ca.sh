#!/bin/sh
# Fetches CA certificates from specified cluster endpoints and re-fetches on
# a schedule. Runs as a restartable init container (restartPolicy: Always) so
# a failed refresh restarts the loop, not the pod.
#
# Arguments:
#   Positional pairs in the format: <name> <url> [<name> <url> ...]
# Output: <CA_DIR>/<name>.pem for each pair.

set -eu

CA_DIR="${CA_DIR:-/certs}"
REFRESH_INTERVAL="${REFRESH_INTERVAL:-86400}"

# Fetches a CA certificate and validates PEM format.
# Arguments:
#   1: Name of the certificate destination file
#   2: Source URL
# Returns: 0 on success, non-zero on failure.
fetch_ca() {
  name="$1"
  url="$2"
  dest="${CA_DIR}/${name}.pem"
  tmp="${dest}.tmp"

  # curl retries transient failures
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

# Processes positional parameters in pairs without destroying outer $@.
process_targets() {
  while [ "$#" -ge 2 ]; do
    fetch_ca "$1" "$2" || true
    shift 2
  done
}

# Validate that arguments are provided in pairs.
if [ "$#" -eq 0 ] || [ "$(( $# % 2 ))" -ne 0 ]; then
  echo "error: arguments must be provided in matching 'name url' pairs" >&2
  exit 1
fi

while :; do
  process_targets "$@"
  sleep "$REFRESH_INTERVAL"
done
