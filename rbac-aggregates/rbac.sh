#!/bin/bash

# Keep the `admin` and `view` aggregation roles in step with what the cluster
# actually serves.
#
# `admin-aggregates` fills the gaps in the built-in `admin` role: full access to
# every namespaced resource that role does not already grant, so a new CRD is
# usable by admins without editing a role by hand.
#
# `view-aggregates` is derived from `admin-aggregates`: its whole content, plus
# the initial and cluster scoped reads in VIEW_EXTRAS, minus everything in
# VIEW_SKIP_RESOURCES. That is what keeps the MCP service account, which is
# bound to `view` and nothing else, from hitting forbidden on a resource its
# human operator can read. Duplicating a grant the cluster's own view
# aggregators already provide is harmless: they all land in the same role.
#
# Both files are generated from discovery, so a new CRD shows up as a `check`
# failure instead of a mystery "forbidden". Clusters do not serve the same
# CRDs, so `gen` merges into the existing files: running against a leaner
# cluster never drops access another cluster needs. To let them shrink, delete
# them first and re-run gen.
#
# Usage:
#   rbac.sh gen   [-c CONTEXT]
#   rbac.sh check [-c CONTEXT]
#
# Requires: kubectl, jq, yq.

set -euo pipefail

export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly ADMIN_FILE="${SCRIPT_DIR}/admin-aggregates.yaml"
readonly VIEW_FILE="${SCRIPT_DIR}/view-aggregates.yaml"

# The built-in role whose grants we top up and mirror.
readonly BASELINE_ROLE="admin"

# `resource.group` (group omitted for core, `*` for a whole group) as handed over
# by the Makefile.
readonly ADMIN_SKIP="${ADMIN_SKIP_RESOURCES:-}"
readonly SKIP_RESOURCES="${VIEW_SKIP_RESOURCES:-}"
readonly EXTRA_RESOURCES="${VIEW_EXTRAS:-}"

# Turn discovery output into `{group, resource}` objects, splitting `a.b.c` into
# resource `a` and group `b.c`. Shared by every jq program here.
# shellcheck disable=SC2016 # jq parameters, not shell expansions
readonly PARSE_PAIRS='def parse_pairs:
  map(if test("\\.")
      then {resource: (split(".")[0]), group: (split(".")[1:] | join("."))}
      else {resource: ., group: ""} end);

# The `resource.group` lines a Makefile list holds, blank lines dropped.
def skip_list($s): [$s | splits("\\s+")] | map(select(length > 0)) | parse_pairs;

# A resource is skipped when an entry names it, or names every resource of its
# group; an entry without a group matches any group, so `pods/exec` works.
def is_skipped($skips; $p):
  $skips
  | any((.group == $p.group or .group == "")
        and (.resource == $p.resource or .resource == "*"));'

COMMAND=""
CONTEXT=""
TMP_DIR=""

usage() {
  cat <<'EOF'
Usage: rbac.sh COMMAND [options]

Commands:
  gen    write admin-aggregates.yaml and view-aggregates.yaml from this cluster.
         New entries are merged into the existing files.
  check  exit 1 if this cluster serves something the files are missing, if
         view-aggregates grants a write verb, a wildcard or a VIEW_SKIP_RESOURCES
         entry, or if admin-aggregates grants an ADMIN_SKIP_RESOURCES entry.

Options:
  -c, --context CONTEXT  kubectl context to query (default: current)
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

# Everything the projection needs from the cluster, cached for one run.
# Discovery omits subresources, and the aggregate roles do not grant any.
fetch() {
  kube api-resources --verbs=get -o name |
    jq -R -s "${PARSE_PAIRS} split(\"\\n\") | map(select(length > 0)) | parse_pairs" >"${TMP_DIR}/served.json"
  kube api-resources --namespaced=true --verbs=get -o name |
    jq -R -s "${PARSE_PAIRS} split(\"\\n\") | map(select(length > 0)) | parse_pairs" >"${TMP_DIR}/namespaced.json"
  kube get clusterroles -o json >"${TMP_DIR}/roles.json"
}

# projection: `{group, resource}` pairs this cluster wants in admin-aggregates,
# i.e. every namespaced resource it serves that the built-in admin role does not
# already grant.
projection() {
  # shellcheck disable=SC2016 # jq arguments, not shell expansions
  jq -n \
    --slurpfile served "${TMP_DIR}/served.json" \
    --slurpfile namespaced "${TMP_DIR}/namespaced.json" \
    --slurpfile roles "${TMP_DIR}/roles.json" \
    --arg baseline "${BASELINE_ROLE}" \
    --arg owned "admin-aggregates" '
    # Rules of a role, optionally including the roles aggregated into it.
    def rules_of($items; $role; $with_aggregates):
        [ $items[]
          | select(.metadata.name == $role
                   or ($with_aggregates
                       and .metadata.labels["rbac.authorization.k8s.io/aggregate-to-" + $role] == "true"))
          | .rules[]? ];

    # {group, resource} pairs a role grants, with `*` expanded against discovery.
    # $read_only keeps only rules carrying at least one of get/list/watch.
    def pairs_of($items; $role; $with_aggregates; $read_only; $by_group; $groups):
        [ rules_of($items; $role; $with_aggregates)[]
          | select(if $read_only
                   then ([.verbs[]? | select(. == "*" or . == "get" or . == "list" or . == "watch")] | length > 0)
                   else ((.verbs // []) | length > 0) end)
          | (.apiGroups // [""])[] as $ag
          | (if $ag == "*" then $groups[] else $ag end) as $g
          | (.resources // [])[] as $r
          | (if $r == "*" then ($by_group[$g] // [])[] else $r end) as $res
          | {group: $g, resource: $res} ]
        | unique;

    ($served[0]) as $all
    | ($namespaced[0]) as $ns
    | ($all | group_by(.group) | map({key: .[0].group, value: (map(.resource) | unique)}) | from_entries) as $by_group
    | ($all | map(.group) | unique) as $groups
    | ($roles[0].items) as $items
    # Ours is subtracted so this file is judged as if it were not applied yet:
    # otherwise a rule we delete would count as covered by the stale copy.
    | (pairs_of($items; $baseline; true; false; $by_group; $groups)
       - pairs_of($items; $owned; false; false; $by_group; $groups)
       | map("\(.group)|\(.resource)")) as $admin_keys
    # Core is left alone: the built-in role already grants what admins need
    # there, and the only gap is podtemplates, which stays out.
    | ($ns | map(select(. as $p | ($admin_keys | index("\($p.group)|\($p.resource)")) | not))
       | map(select(.group != "")))
    | unique
  '
}

# render MODE EXISTING PROJECTION: the final `{group, resource}` list for one
# file, merged with what is already committed and stripped of everything that
# must never be aggregated.
render() {
  # shellcheck disable=SC2016 # jq arguments, not shell expansions
  jq -cn \
    --arg mode "$1" --argjson existing "$2" --argjson new "$3" \
    --slurpfile served "${TMP_DIR}/served.json" \
    --arg admin_skip "${ADMIN_SKIP}" --arg skip "${SKIP_RESOURCES}" \
    --arg extras "${EXTRA_RESOURCES}" \
    "${PARSE_PAIRS}"'
    ($served[0]) as $all
    | (if $mode == "admin" then skip_list($admin_skip) else skip_list($skip) end) as $skips
    | ([ skip_list($extras)[] as $e
         | if $e.resource == "*"
           then $all[] | select(.group == $e.group) | {group, resource}
           else $e end ]) as $extra_pairs
    | ($existing + $new + (if $mode == "view" then $extra_pairs else [] end))
    | unique
    | map(select(.resource | endswith("/finalizers") | not))
    | map(select(. as $p | is_skipped($skips; $p) | not))
    | sort_by(.group, .resource)
  '
}

# existing_rules FILE: `{group, resource}` pairs from a committed file.
existing_rules() {
  if [[ ! -f "$1" ]]; then
    echo "[]"
    return
  fi

  # shellcheck disable=SC2016 # yq binds $g, not the shell.
  yq -o=json '[.rules // [] | .[] | (.apiGroups // [""])[] as $g | (.resources // [])[] as $r | {"group": $g, "resource": $r}]' "$1"
}

emit() {
  local pairs="$1" verbs="$2" name="$3" label="$4" header="$5"

  cat <<EOF
# Generated by rbac.sh. Do not edit by hand: re-run \`make gen\` and review the
# diff.
#
${header}
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: ${name}
  labels:
    rbac.authorization.k8s.io/aggregate-to-${label}: "true"
rules:
EOF

  printf '%s' "${pairs}" | jq -r --argjson verbs "${verbs}" '
    group_by(.group)
    | .[]
    | "  - apiGroups: [\(.[0].group | @json)]\n"
      + "    resources: [\(map(.resource) | join(", "))]\n"
      + "    verbs: [\($verbs | map(@json) | join(", "))]"
  '
}

write_file() {
  printf '%s\n' "$2" >"$1"
}

# A projection that shrank to nothing means the role or the impersonation is
# broken; write no file rather than an empty role.
require_projection() {
  local count
  count="$(jq 'length' <<<"$2")"
  ((count >= 5)) || die "$1 projection resolved to ${count} resources"
}

do_gen() {
  local gaps admin view

  gaps="$(projection)"
  require_projection admin "${gaps}"
  admin="$(render admin "$(existing_rules "${ADMIN_FILE}")" "${gaps}")"

  # view is derived from the file, not from the cluster: the role is not applied
  # yet, so the cluster would only tell us what other aggregators already grant.
  view="$(render view "$(existing_rules "${VIEW_FILE}")" "${admin}")"
  require_projection view "${view}"

  write_file "${ADMIN_FILE}" "$(
    emit "${admin}" '["*"]' admin-aggregates admin \
      "# Fills the gaps in the built-in \`admin\` role: full access to every namespaced
# API group it does not already grant, so new CRDs need no manual role edit. The
# core group is left alone; its only gap is podtemplates, which we do not want."
  )"
  write_file "${VIEW_FILE}" "$(
    emit "${view}" '["get", "list", "watch"]' view-aggregates view \
      "# Read side of \`admin-aggregates\`, plus the initial and cluster scoped reads
# in VIEW_EXTRAS. Never secrets, exec/attach/portforward/proxy."
  )"

  printf '%s: %s resources\n' "${ADMIN_FILE}" "$(jq 'length' <<<"${admin}")"
  printf '%s: %s resources\n' "${VIEW_FILE}" "$(jq 'length' <<<"${view}")"
}

# Fail when a file is missing something this cluster needs, or when either file
# grants something it must not.
do_check() {
  local status=0 admin_now view_now

  admin_now="$(render admin '[]' "$(projection)")"
  missing_report "${ADMIN_FILE}" "${admin_now}" "$(existing_rules "${ADMIN_FILE}")" || status=1

  view_now="$(render view '[]' "$(existing_rules "${ADMIN_FILE}")")"
  missing_report "${VIEW_FILE}" "${view_now}" "$(existing_rules "${VIEW_FILE}")" || status=1
  require_read_only "${VIEW_FILE}" || status=1
  require_no_skips "${ADMIN_FILE}" "${ADMIN_SKIP}" || status=1

  if ((status)); then
    echo >&2
    echo "error: run 'make gen' and review the diff" >&2
    exit 1
  fi

  echo "ok: this cluster needs nothing more than the files already grant"
}

missing_report() {
  local file="$1" cluster="$2" have="$3" missing

  missing="$(jq -rn --argjson cluster "${cluster}" --argjson have "${have}" '
    def keys: [.[] | "\(.group)|\(.resource)"];
    ($cluster | keys) - ($have | keys) | .[]
  ')"

  if [[ -n "${missing}" ]]; then
    echo "== ${file##*/} is missing =="
    printf '%s\n' "${missing}" | sed 's/^/    /'
    return 1
  fi

  echo "${file##*/}: nothing missing"
}

# The SKIPLIST entries FILE grants, one per line, core group unqualified.
forbidden_entries() {
  yq -o=json '.rules // []' "$1" |
    jq -r --arg skip "$2" "${PARSE_PAIRS}"'
      skip_list($skip) as $sk
      | .[] as $rule
      | ($rule.apiGroups // [""])[] as $g
      | ($rule.resources // [])[] as $r
      | {group: $g, resource: $r}
      | select(. as $p | is_skipped($sk; $p))
      | if .group == "" then .resource else "\(.group)|\(.resource)" end'
}

require_no_skips() {
  local hits

  hits="$(forbidden_entries "$1" "$2" | paste -sd, - | sed 's/,/, /g')"
  if [[ -n "${hits}" ]]; then
    echo "== $1 grants a skipped resource: ${hits} =="
    return 1
  fi
}

# The view role is written by this script, so `check` is where its promises are
# enforced: read verbs only, no wildcard, nothing from the skip list.
require_read_only() {
  local file="$1" verbs wild

  verbs="$(yq -o=json '[.rules[].verbs[]] | unique' "$file" |
    jq -r 'map(select(. != "get" and . != "list" and . != "watch")) | join(",")')"
  if [[ -n "${verbs}" ]]; then
    echo "== $file grants a write verb: ${verbs} =="
    return 1
  fi

  wild="$(yq -o=json '.' "$file" | jq -r '
    [ .rules[] | (.apiGroups // [""])[] as $g | (.resources // [])[] as $r
      | select($g == "*" or $r == "*") | "\($g)|\($r)" ]
    | unique | join(", ")')"
  if [[ -n "${wild}" ]]; then
    echo "== $file grants a wildcard: ${wild} =="
    return 1
  fi

  require_no_skips "$file" "${SKIP_RESOURCES}" || return 1
  echo "$file: read-only"
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
      -h|--help) usage; exit 0 ;;
      *) die "unknown option: $1" ;;
    esac
  done
}

main() {
  parse_args "$@"

  [[ -n "${SKIP_RESOURCES}" ]] ||
    die "VIEW_SKIP_RESOURCES is not set; run through make (see rbac-aggregates/Makefile)"

  command -v kubectl >/dev/null 2>&1 || die "kubectl is required"
  command -v jq >/dev/null 2>&1 || die "jq is required"
  command -v yq >/dev/null 2>&1 || die "yq is required"

  TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "${TMP_DIR}"' EXIT

  fetch

  case "${COMMAND}" in
    gen) do_gen ;;
    check) do_check ;;
  esac
}

main "$@"
