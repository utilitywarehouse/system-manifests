#!/bin/bash

# RBAC for the mcp-kube service account: generate the ClusterRole that
# complements the built-in `view` role, and check what the account can reach.
#
# `gen` projects the built-in `admin` role onto this cluster. `admin` is the
# reference because it is namespaced by construction: cluster scoped API
# plumbing (apiservices, flowcontrol, admission webhooks, CSRs, device classes)
# never enters the projection, while operator CRDs that aggregate into `admin`
# come along for free. Anything that reads secret values or reaches into a
# container or node is removed afterwards (DENY_RESOURCES), the few cluster
# scoped resources worth reading are added by hand (CLUSTER_EXTRAS), and what
# `view` already grants is subtracted so the file stays small.
#
# Clusters do not serve the same CRDs, so `gen` merges into the existing file:
# running on a leaner cluster never drops access another cluster needs. `check`
# therefore fails only on missing entries; `--replace` is the only way the file
# shrinks.
#
# Usage:
#   rbac.sh gen   [-c CONTEXT] [--replace]
#   rbac.sh check [-c CONTEXT]
#
# Requires: kubectl, jq, yq.

set -euo pipefail

export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
OUTPUT="${SCRIPT_DIR}/mcp-kube-extras.yaml"
readonly BASELINE_ROLE="admin"
# Already granted through the mcp-kube-view binding; do not repeat it here.
readonly COVERED_ROLE="view"

# Which reads to withhold and which cluster scoped reads to add is decided in
# the Makefile, so generation and verification cannot disagree. Space separated,
# exported by `make`.
DENY_LIST=()
EXTRAS_LIST=()

COMMAND=""
CONTEXT=""
REPLACE=0
TMP_DIR=""
STAGED=""

usage() {
  cat <<'EOF'
Usage: rbac.sh COMMAND [options]

Commands:
  gen    write mcp-kube-extras.yaml: what `admin` can read that `view` does not,
         minus exec/proxy/secret paths, plus the cluster scoped allowlist.
         New entries are merged into the existing file.
  check  exit 1 if this cluster needs an entry the file is missing

Options:
  -c, --context CONTEXT  kubectl context to query (default: current)
      --replace          discard existing entries instead of merging
  -h, --help             show this help
EOF
}

die() {
  echo "error: $*" >&2
  exit 1
}

kube() {
  local -a args=("$@")
  if [[ -n "${CONTEXT}" ]]; then
    args+=("--context=${CONTEXT}")
  fi
  kubectl "${args[@]}"
}

json_list() {
  printf '%s\n' "$@" | jq -R -s 'split("\n") | map(select(length > 0))'
}

read_lists() {
  local entry

  if [[ -z "${DENY_RESOURCES:-}" ]]; then
    die "DENY_RESOURCES is not set; run through make (see rbac/Makefile)"
  fi

  for entry in ${DENY_RESOURCES}; do
    DENY_LIST+=("${entry}")
  done

  for entry in ${CLUSTER_EXTRAS:-}; do
    EXTRAS_LIST+=("${entry}")
  done
}

# Everything the projection needs from the cluster, cached for one run.
fetch() {
  # resource.group for everything that supports get. Subresources are not
  # listed here, so they can only enter through an explicit role rule.
  kube api-resources --verbs=get -o name |
    jq -R -s 'split("\n") | map(select(length > 0))' >"${TMP_DIR}/served.json"

  kube get clusterroles -o json >"${TMP_DIR}/roles.json"
}

# projection: the baseline role's readable resources for this cluster, grouped
# as `[{group, resources: [...]}]`.
projection() {
  # shellcheck disable=SC2016 # jq arguments, not shell expansions
  jq -n \
    --slurpfile served "${TMP_DIR}/served.json" \
    --slurpfile roles "${TMP_DIR}/roles.json" \
    --argjson deny "$(json_list "${DENY_LIST[@]}")" \
    --argjson extras "$(json_list "${EXTRAS_LIST[@]}" |
      jq -c 'map({group: (split("/")[0]), resource: (split("/")[1:] | join("/"))})')" \
    --arg baseline "${BASELINE_ROLE}" \
    --arg covered "${COVERED_ROLE}" '
    ["get", "list", "watch"] as $read
    | ($served[0]
        | map(if test("\\.")
              then {resource: (split(".")[0]), group: (split(".")[1:] | join("."))}
              else {resource: ., group: ""} end)) as $pairs
    | ($pairs
        | group_by(.group)
        | map({key: .[0].group, value: (map(.resource) | unique)})
        | from_entries) as $by_group
    | ($pairs | map(.group) | unique) as $groups

    # {group, resource} pairs a role grants for at least one read verb, with
    # `*` expanded against discovery and the role plus every role aggregated
    # into it resolved.
    | def read_pairs($role):
        [ $roles[0].items[]
          | select(.metadata.name == $role
                   or .metadata.labels["rbac.authorization.k8s.io/aggregate-to-" + $role] == "true")
          | .rules[]?
          | select([.verbs[]? | select(. == "*" or (. as $v | $read | index($v)))] | length > 0)
          | (.apiGroups // [""])[] as $ag
          | (if $ag == "*" then $groups[] else $ag end) as $g
          | (.resources // [])[] as $r
          | (if $r == "*" then ($by_group[$g] // [])[] else $r end) as $res
          | {group: $g, resource: $res} ];

    # A dead rule names a resource this cluster no longer serves (extensions
    # leftovers, renamed kinds); a subresource counts as served when its parent
    # is. finalizers carries no data worth reading and only shows up because
    # operator roles grant it alongside the real resource.
    def live:
      . as $p
      | ($p.resource | split("/")[0]) as $base
      | any($pairs[]; .group == $p.group and .resource == $base);

    (read_pairs($baseline) - read_pairs($covered))
    | map(select(.resource | endswith("/finalizers") | not))
    | map(select(live))
    | unique
    | map(select(.resource as $r | ($deny | index($r)) == null))
    | . + $extras
    | unique
    | map(select(live))
    | group_by(.group)
    | map({group: .[0].group, resources: (map(.resource) | unique | sort)})
    | sort_by(.group)
  '
}

# existing_rules: `[{group, resources: [...]}]` from the committed file.
existing_rules() {
  if [[ ! -f "${OUTPUT}" ]]; then
    echo "[]"
    return
  fi

  # shellcheck disable=SC2016 # yq binds $g, not the shell.
  yq -o=json '[.rules // [] | .[] | (.apiGroups // [""])[] as $g | {"group": $g, "resources": (.resources // [])}]' "${OUTPUT}"
}

# merge_rules EXISTING NEW: union of both, grouped and sorted. Denied resources
# are dropped here too, so an entry that becomes forbidden never survives a run.
merge_rules() {
  jq -n --argjson existing "$1" --argjson new "$2" \
    --argjson deny "$(json_list "${DENY_LIST[@]}")" '
    ($existing + $new)
    | group_by(.group)
    | map({group: .[0].group, resources: (map(.resources[]) | unique | sort)})
    | map(.resources |= map(select(. as $r | ($deny | index($r)) == null)))
    # Same reasoning as project: finalizers subresources are noise.
    | map(.resources |= map(select(endswith("/finalizers") | not)))
    | map(select((.resources | length) > 0))
    | sort_by(.group)
  '
}

emit() {
  local rules="$1" scope="$2"

  cat <<EOF
# Generated by rbac.sh from the built-in \`${BASELINE_ROLE}\` role. Do not edit by
# hand: re-run the script and review the diff.
#
# Holds only what \`${COVERED_ROLE}\` does not already grant, plus the cluster scoped
# resources in CLUSTER_EXTRAS, ${scope}. Left out on purpose:
# secrets, exec/attach/portforward/proxy, and the cluster scoped API plumbing
# (apiservices, flowcontrol, admission webhooks, CSRs, cluster scoped storage
# topology and DRA).
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: mcp-kube-viewer-extras
  labels:
    app.kubernetes.io/name: mcp-kube
rules:
EOF

  printf '%s' "${rules}" | jq -r '
    .[] | "  - apiGroups: [\(.group | @json)]
    resources: [\(.resources | map(@json) | join(", "))]
    verbs: [get, list, watch]"
  '
}

# report_missing CLUSTER FILE: fail when this cluster needs an entry the file
# does not have. Extra entries are fine: another cluster may require them.
report_missing() {
  jq -rn --argjson cluster "$1" --argjson file "$2" '
    def pairs: [.[] | .group as $g | .resources[] | "\($g)|\(.)"];
    ($cluster | pairs) as $c
    | ($file | pairs) as $f
    | ($c - $f) as $missing
    | (if ($missing | length) > 0 then
         "== missing from the file ==",
         ($missing[] | "    " + .),
         ""
       else empty end),
      "cluster needs \($c | length), file has \($f | length): \($missing | length) missing"
  '
}

resource_count() {
  printf '%s' "$1" | jq '[.[].resources[]] | length'
}

# A set this small means the baseline failed to resolve, not that the cluster is
# quiet: refuse to write or to pass.
require_projection() {
  local count
  count="$(resource_count "$1")"
  ((count >= 5)) || die "only ${count} resources resolved from ${BASELINE_ROLE}"
}

do_gen() {
  local cluster rules scope count

  cluster="$(projection)"
  require_projection "${cluster}"

  if ((REPLACE)); then
    rules="${cluster}"
    scope="for this cluster only"
  else
    rules="$(merge_rules "$(existing_rules)" "${cluster}")"
    scope="merged across clusters"
  fi

  # Write next to the target so the replace is atomic: a failed run leaves the
  # previous file intact.
  STAGED="$(mktemp "${OUTPUT}.XXXXXX")"
  emit "${rules}" "${scope}" >"${STAGED}"
  mv "${STAGED}" "${OUTPUT}"

  printf '%s: %s groups, %s resources\n' \
    "${OUTPUT}" "$(printf '%s' "${rules}" | jq 'length')" "$(resource_count "${rules}")"
}

do_check() {
  local cluster missing

  cluster="$(projection)"
  require_projection "${cluster}"

  missing="$(report_missing "${cluster}" "$(existing_rules)")"
  echo "${missing}"

  if printf '%s' "${missing}" | grep -q '^== missing'; then
    echo >&2
    echo "error: ${OUTPUT} is missing entries this cluster needs; re-run 'rbac.sh gen'" >&2
    exit 1
  fi
}

parse_args() {
  COMMAND="${1:-}"
  case "${COMMAND}" in
    gen|check) shift ;;
    ""|-h|--help) usage; exit 0 ;;
    *) die "unknown command: ${COMMAND} (try --help)" ;;
  esac

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -c|--context) CONTEXT="$2"; shift 2 ;;
      --replace)
        [[ "${COMMAND}" == "gen" ]] || die "--replace is only valid for gen"
        REPLACE=1; shift ;;
      -h|--help) usage; exit 0 ;;
      *) die "unknown option: $1" ;;
    esac
  done
}

main() {
  parse_args "$@"
  read_lists

  command -v kubectl >/dev/null 2>&1 || die "kubectl is required"
  command -v jq >/dev/null 2>&1 || die "jq is required"
  command -v yq >/dev/null 2>&1 || die "yq is required"

  TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "${TMP_DIR}"; if [[ -n "${STAGED}" ]]; then rm -f "${STAGED}"; fi' EXIT

  fetch

  case "${COMMAND}" in
    gen) do_gen ;;
    check) do_check ;;
  esac
}

main "$@"
