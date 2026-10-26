#!/bin/bash

# Keep the `admin` and `view` aggregate roles in step with what a cluster serves.
#
# `admin-aggregates` gives admins full access to every namespaced resource the
# built-in `admin` role does not grant, so a new CRD works without a hand edit.
#
# `view-aggregates` does the same for `view`, read-only and cluster scope
# included. The MCP service account binds `view` and nothing else, so it can read
# whatever its operator can. We write only the gaps: another aggregator may
# already grant a resource, and listing it twice helps nobody.
#
# Both files come from discovery, so a new CRD shows up as a `check` failure
# instead of a confusing "forbidden". Clusters differ and `gen` merges into the
# files, so running against a leaner cluster never drops access another one
# needs. To shrink them, delete both files and run gen again.
#
# Usage:
#   rbac.sh gen   [-c CONTEXT]
#   rbac.sh check [-c CONTEXT]
#
# Needs kubectl, jq and yq.

set -euo pipefail

export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly ADMIN_FILE="${SCRIPT_DIR}/admin-aggregates.yaml"
readonly VIEW_FILE="${SCRIPT_DIR}/view-aggregates.yaml"

# `resource.group` entries from the Makefile: group omitted for core, `*` for a
# whole group.
readonly ADMIN_SKIP="${ADMIN_SKIP_RESOURCES:-}"
readonly SKIP_RESOURCES="${VIEW_SKIP_RESOURCES:-}"

# Split `a.b.c` into resource `a` and group `b.c`. Every jq program here uses it.
# shellcheck disable=SC2016 # jq parameters, not shell expansions
readonly PARSE_PAIRS='def parse_pairs:
  map(if test("\\.")
      then {resource: (split(".")[0]), group: (split(".")[1:] | join("."))}
      else {resource: ., group: ""} end);

# Split a Makefile list into `resource.group` entries; blank lines dropped.
def skip_list($s): [$s | splits("\\s+")] | map(select(length > 0)) | parse_pairs;

# An entry matches by name, by `*.group`, or across every group when it has no
# group, so `pods/exec` works.
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

# Cluster data the projection needs, fetched once. Discovery leaves out
# subresources, and so do the aggregate roles.
fetch() {
  kube api-resources --verbs=get -o name |
    jq -R -s "${PARSE_PAIRS} split(\"\\n\") | map(select(length > 0)) | parse_pairs" >"${TMP_DIR}/served.json"
  kube api-resources --namespaced=true --verbs=get -o name |
    jq -R -s "${PARSE_PAIRS} split(\"\\n\") | map(select(length > 0)) | parse_pairs" >"${TMP_DIR}/namespaced.json"
  kube get clusterroles -o json >"${TMP_DIR}/roles.json"
}

# projection ROLE OWNED SOURCE READ_ONLY: the `{group, resource}` pairs the role
# does not cover well enough. `admin` and `view` aggregate what we grant, so we
# subtract OWNED from the coverage; otherwise every resource would look covered.
# SOURCE is `namespaced` or `served`; READ_ONLY narrows what counts as a grant.
projection() {
  # shellcheck disable=SC2016 # jq arguments, not shell expansions
  jq -n \
    --arg role "$1" --arg owned "$2" --argjson read_only "$4" \
    --slurpfile want "${TMP_DIR}/$3.json" \
    --slurpfile served "${TMP_DIR}/served.json" \
    --slurpfile roles "${TMP_DIR}/roles.json" '
    # Rules of a role, optionally including the roles aggregated into it.
    def rules_of($items; $name; $with_aggregates):
        [ $items[]
          | select(.metadata.name == $name
                   or ($with_aggregates
                       and .metadata.labels["rbac.authorization.k8s.io/aggregate-to-" + $name] == "true"))
          | .rules[]? ];

    # Rules expanded against discovery: `*` groups and `*` resources become the
    # served pairs, `*` verbs become the standard verb set.
    def expand($rules; $by_group; $groups; $std):
        [ $rules[]
          | (.verbs // []) as $v
          | select(($v | length) > 0)
          | (.apiGroups // [""])[] as $ag
          | (if $ag == "*" then $groups[] else $ag end) as $g
          | (.resources // [])[] as $r
          | (if $r == "*" then ($by_group[$g] // [])[] else $r end) as $res
          | {group: $g, resource: $res,
             verbs: ([ $v[] | if . == "*" then $std[] else . end ] | unique)} ];

    # Pairs with the verbs they grant, `*` expanded.
    def verb_map($rules; $by_group; $groups; $std):
        expand($rules; $by_group; $groups; $std)
        | group_by([.group, .resource])
        | map({key: "\(.[0].group)|\(.[0].resource)",
               value: (map(.verbs) | add | unique)})
        | from_entries;

    # Verbs a pair must keep. A pair the old aggregate never granted only needs
    # to be reachable; one it did grant keeps every verb, so replacing the role
    # never turns write access into read-only.
    def wanted($old; $read_only):
        if ((($old // []) | length) == 0) then ["get"]
        elif $read_only then
            ([ $old[] | select(. != "create" and . != "update" and . != "patch"
                               and . != "delete" and . != "deletecollection") ]
             | if length == 0 then ["get"] else . end)
        else $old end;

    ["get", "list", "watch", "create", "update", "patch", "delete", "deletecollection"] as $std
    | ($served[0]) as $all
    | ($all | group_by(.group) | map({key: .[0].group, value: (map(.resource) | unique)}) | from_entries) as $by_group
    | ($all | map(.group) | unique) as $groups
    | ($roles[0].items) as $items
    # Subtract our role from the coverage: `admin` and `view` aggregate what we
    # grant, so leaving it in would make every resource look covered.
    | (rules_of($items; $role; true) - rules_of($items; $owned; false)) as $base_rules
    | (rules_of($items; $owned; false)) as $old_rules
    | (verb_map($base_rules; $by_group; $groups; $std)) as $base
    | (verb_map($old_rules; $by_group; $groups; $std)) as $old
    | [ $want[0][]
        | "\(.group)|\(.resource)" as $k
        | select((wanted($old[$k]; $read_only) - ($base[$k] // [])) | length > 0) ]
    | unique
  '
}

# render MODE EXISTING PROJECTION: the final pairs for one file: what is already
# committed plus the projection, minus what must never be aggregated.
render() {
  # shellcheck disable=SC2016 # jq arguments, not shell expansions
  jq -cn \
    --arg mode "$1" --argjson existing "$2" --argjson new "$3" \
    --arg admin_extra "${ADMIN_EXTRA}" \
    --arg admin_skip "${ADMIN_SKIP}" --arg skip "${SKIP_RESOURCES}" \
    "${PARSE_PAIRS}"'
    (if $mode == "admin" then skip_list($admin_skip) else skip_list($skip) end) as $skips
    | ($existing + $new
       + (if $mode == "admin" then skip_list($admin_extra) else [] end))
    | unique
    | map(select(.resource | endswith("/finalizers") | not))
    | map(select(. as $p | is_skipped($skips; $p) | not))
    | sort_by(.group, .resource)
  '
}

# The `{group, resource}` pairs a committed file already lists.
existing_rules() {
  if [[ ! -f "$1" ]]; then
    echo "[]"
    return
  fi

  # shellcheck disable=SC2016 # yq binds $g, not the shell.
  yq -o=json '[.rules // [] | .[] | (.apiGroups // [""])[] as $g | (.resources // [])[] as $r | {"group": $g, "resource": $r}]' "$1" |
    # ADMIN_EXTRA_RULES are written verbatim, so leave them out of the pair
    # model; otherwise the merge would add a second, wider copy.
    jq --argjson extra "${ADMIN_EXTRA_RULES:-[]}" '
      map(select(. as $p
                 | any($extra[]; (.apiGroups[0] // "") == $p.group
                                 and (.resources[0] // "") == $p.resource)
                 | not))'
}

emit() {
  local pairs="$1" verbs="$2" name="$3" label="$4" header="$5" extra="$6"

  cat <<EOF
# Generated by rbac.sh. Do not edit: run \`make gen\` and review the diff.
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

  printf '%s' "${extra}" | jq -r '
    .[]
    | "  - apiGroups: [\(.apiGroups | map(@json) | join(", "))]\n"
      + "    resources: [\(.resources | map(@json) | join(", "))]\n"
      + (if ((.resourceNames // []) | length) > 0
         then "    resourceNames: [\(.resourceNames | map(@json) | join(", "))]\n"
         else "" end)
      + "    verbs: [\(.verbs | map(@json) | join(", "))]"
  '
}

write_file() {
  printf '%s\n' "$2" >"$1"
}

# No built-in role means no coverage, so every resource would look missing. Stop
# instead of guessing.
require_baseline() {
  jq -e --arg role "$1" 'any(.items[]; .metadata.name == $role)' "${TMP_DIR}/roles.json" >/dev/null ||
    die "cluster does not serve ClusterRole $1"
}

# An empty projection means discovery or the role lookup broke. Write nothing
# rather than an empty role.
require_projection() {
  local count
  count="$(jq 'length' <<<"$2")"
  ((count >= 5)) || die "$1 projection resolved to ${count} resources"
}

do_gen() {
  local gaps admin view gaps_view

  require_baseline admin
  require_baseline view
  gaps="$(projection admin admin-aggregates namespaced false)"
  require_projection admin "${gaps}"
  admin="$(render admin "$(existing_rules "${ADMIN_FILE}")" "${gaps}")"

  gaps_view="$(projection view view-aggregates served true)"
  require_projection view "${gaps_view}"
  view="$(render view "$(existing_rules "${VIEW_FILE}")" "${gaps_view}")"

  write_file "${ADMIN_FILE}" "$(
    emit "${admin}" '["*"]' admin-aggregates admin \
      "# The namespaced access the built-in \`admin\` role lacks, read/write.
# New CRDs need no hand edit; ADMIN_SKIP_RESOURCES lists what stays out." \
      "${ADMIN_EXTRA_RULES:-[]}"
  )"
  write_file "${VIEW_FILE}" "$(
    emit "${view}" '["get", "list", "watch"]' view-aggregates view \
      "# The reads the built-in \`view\` role lacks, cluster scope included.
# Never secrets, exec, attach, portforward or proxy (VIEW_SKIP_RESOURCES)." \
      '[]'
  )"

  printf '%s: %s resources\n' "${ADMIN_FILE}" "$(jq 'length' <<<"${admin}")"
  printf '%s: %s resources\n' "${VIEW_FILE}" "$(jq 'length' <<<"${view}")"
}

# Fail when a file misses something this cluster needs, or grants something it
# must not.
do_check() {
  local status=0 admin_now view_now

  require_baseline admin
  require_baseline view
  admin_now="$(render admin '[]' "$(projection admin admin-aggregates namespaced false)")"
  missing_report "${ADMIN_FILE}" "${admin_now}" "$(existing_rules "${ADMIN_FILE}")" || status=1

  view_now="$(render view '[]' "$(projection view view-aggregates served true)")"
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

# The `resource.group` entries FILE grants that the skip list forbids.
forbidden_entries() {
  yq -o=json '.rules // []' "$1" |
    jq -r --arg skip "$2" "${PARSE_PAIRS}"'
      skip_list($skip) as $sk
      | .[] as $rule
      | ($rule.apiGroups // [""])[] as $g
      | ($rule.resources // [])[] as $r
      | {group: $g, resource: $r}
      | select(. as $p | is_skipped($sk; $p))
      | if .group == "" then .resource else "\(.resource).\(.group)" end'
}

require_no_skips() {
  local hits

  hits="$(forbidden_entries "$1" "$2" | paste -sd, - | sed 's/,/, /g')"
  if [[ -n "${hits}" ]]; then
    echo "== $1 grants a skipped resource: ${hits} =="
    return 1
  fi
}

# The view role is ours, so `check` enforces its promises: read verbs only, no
# wildcards, nothing from the skip list.
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
      | select($g == "*" or $r == "*")
      | if $g == "" then $r else "\($r).\($g)" end ]
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
