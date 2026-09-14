#!/bin/bash

# Diff the effective `get`-only rules of the built-in `admin` and `view`
# ClusterRoles for a cluster, resolving their aggregationRules (the raw YAML
# of either role only shows a label selector). Contributing rules are
# flattened to unique group|resource|get tuples; tuples admin grants that
# view does not are reported, grouped by resource.
#
# Also verifies the supplemental permissions the mcp-kube SA relies on beyond
# `view` are actually granted by the union of `view` + the
# mcp-kube-viewer-extras ClusterRole (see mcp-kube-rbac.yaml).
#
# Usage:
#   rbac-diff.sh [--context CONTEXT]
#
# Requires: kubectl and jq. yq is used if present for local YAML->JSON
# conversion of the extras role; otherwise kubectl converts it.

set -euo pipefail

# Force byte-order collation for sort AND comm. Without this, the piped sort
# runs under C collation while comm uses the user's locale; the mismatch makes
# comm mis-diff identical lines and print "not in sorted order" errors.
export LC_ALL=C

readonly ADMIN_SELECTOR='.metadata.labels["rbac.authorization.k8s.io/aggregate-to-admin"]=="true" or .metadata.labels["rbac.authorization.k8s.io/aggregate-to-edit"]=="true" or .metadata.labels["rbac.authorization.k8s.io/aggregate-to-view"]=="true"'
readonly VIEW_SELECTOR='.metadata.labels["rbac.authorization.k8s.io/aggregate-to-view"]=="true"'
readonly EXTRAS_ROLE_NAME="mcp-kube-viewer-extras"
readonly DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly RBAC_FILE="${DIR}/mcp-kube-rbac.yaml"

CONTEXT=""

usage() {
  cat <<'EOF'
Usage: rbac-diff.sh [options]

Diff the aggregation-resolved `get`-only rules of the built-in `admin` and
`view` ClusterRoles, reporting what admin grants that view does not, and
verify the supplemental reads granted beyond `view` are present.

Options:
  -c, --context CONTEXT  kubectl context to query (default: current)
  -h, --help             show this help
EOF
}

die() {
  echo "error: $*" >&2
  exit 1
}

# cluster_get SELECTOR: flatten rules of matching roles to sorted unique
# group|resource|get tuples (get verb only).
cluster_get() {
  local selector="$1"
  local -a args=("get" "clusterroles" "-o" "json")
  if [[ -n "${CONTEXT}" ]]; then
    args+=("--context=${CONTEXT}")
  fi
  kubectl "${args[@]}" | jq -r \
    '[.items[] | select('"${selector}"') | .rules[] | select(.apiGroups) |
      .apiGroups[] as $g | .resources[] as $r | select(.verbs | index("get")) |
      "\($g)|\($r)|get"] | unique[]' | LC_ALL=C sort
}

# extras_get: get-tuples from the mcp-kube-viewer-extras ClusterRole.
# Returns empty when the role is not yet applied on the target cluster (the
# RBAC base is a separate kustomize base), so callers can report MISSING
# instead of failing.
extras_get() {
  local -a args=("get" "clusterrole" "${EXTRAS_ROLE_NAME}" "-o" "json")
  if [[ -n "${CONTEXT}" ]]; then
    args+=("--context=${CONTEXT}")
  fi
  local out
  out="$(kubectl "${args[@]}" 2>/dev/null)" || return 0
  printf '%s' "${out}" | jq -r \
    '[.rules[] | select(.apiGroups) | .apiGroups[] as $g |
      .resources[] as $r | select(.verbs | index("get")) |
      "\($g)|\($r)|get"] | unique[]' | LC_ALL=C sort
}

# extras_expected: the group|resource pairs the extras role declares in the
# local RBAC file, so the live cluster can be checked against intent.
extras_expected() {
  local stream
  if command -v yq >/dev/null 2>&1; then
    stream="$(yq -o=json '.' "${RBAC_FILE}")"
  else
    stream="$(kubectl create --dry-run=client --validate=false -o json \
      -f "${RBAC_FILE}")"
  fi
  printf '%s\n' "${stream}" | jq -r \
    'select(.kind == "ClusterRole" and .metadata.name == "'"${EXTRAS_ROLE_NAME}"'") |
      .rules[] | select(.apiGroups) | .apiGroups[] as $g |
      .resources[] as $r | select(.verbs | index("get")) |
      "\($g)|\($r)"' | LC_ALL=C sort -u
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -c|--context) CONTEXT="$2"; shift 2 ;;
      -h|--help) usage; exit 0 ;;
      *) die "unknown option: $1" ;;
    esac
  done
}

# check_extras VIEW_TUPLES: verify every read the extras role declares in
# mcp-kube-rbac.yaml is granted by the union of the resolved `view` role and
# the live extras ClusterRole.
check_extras() {
  local view_tuples="$1"
  local extras expected
  extras="$(extras_get)"
  expected="$(extras_expected)"
  local combined
  combined="$(printf '%s\n%s\n' "${view_tuples}" "${extras}" | LC_ALL=C sort -u)"

  echo "== supplemental reads beyond view (from ${RBAC_FILE}) =="
  if [[ -z "${expected}" ]]; then
    echo "  (no extras role '${EXTRAS_ROLE_NAME}' found in ${RBAC_FILE})"
    return
  fi

  local -a rows=()
  readarray -t rows <<<"${expected}"
  local entry granted
  for entry in "${rows[@]}"; do
    if printf '%s\n' "${combined}" | grep -qx "${entry}|get"; then
      granted="OK"
    else
      granted="MISSING"
    fi
    printf '  %-5s %s\n' "${granted}" "${entry}"
  done
}

main() {
  parse_args "$@"

  command -v kubectl >/dev/null 2>&1 || die "kubectl is required"
  command -v jq >/dev/null 2>&1 || die "jq is required"

  local admin view admin_only
  admin="$(cluster_get "${ADMIN_SELECTOR}")"
  view="$(cluster_get "${VIEW_SELECTOR}")"
  # comm exits 1 when differences are found; that is the expected case here.
  admin_only="$(comm -13 <(printf '%s' "${view}") \
    <(printf '%s' "${admin}") || true)"

  echo "== get permissions admin has that view lacks =="
  if [[ -n "${admin_only}" ]]; then
    printf '%s\n' "${admin_only}" | awk -F'|' '
      { print $1 "|" $2 }
    ' | LC_ALL=C sort -u
  else
    echo "(none)"
  fi
  echo

  check_extras "${view}"
}

main "$@"
