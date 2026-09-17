#!/bin/sh
set -u

pg="${PUSHGATEWAY_URL:-}"
findings=/work/out/findings.json
logs=/work/logs/logs.txt

# RuleID + StartLine out of the (redacted) JSON report.
# Emit "rule line" pairs, one per finding.
list_findings() {
  awk '
    /"RuleID":/    { v=$0; sub(/^.*"RuleID": *"/, "", v); sub(/".*$/, "", v); rule=v }
    /"StartLine":/ { v=$0; sub(/^.*"StartLine": */, "", v); sub(/,.*$/, "", v); print rule, v }
  ' "$1"
}

# Print where each finding is, never the secret itself.
if [ -f "$findings" ]; then
  list_findings "$findings" | while read -r rule line; do
    [ -n "${rule:-}" ] || continue
    [ -n "${line:-}" ] || continue
    # Everything before the " #ARGS# " marker is safe metadata; the rest is
    # the raw arguments, so it is never printed.
    meta=$(sed -n "${line}s/ #ARGS#.*//p" "$logs")
    printf '%s\t%s\n' "$rule" "$meta"
  done
fi

if [ -n "$pg" ]; then
  findings_count=0
  lines_scanned=0
  if [ -f "$findings" ]; then
    findings_count=$(list_findings "$findings" | wc -l)
  fi
  if [ -f "$logs" ]; then
    lines_scanned=$(wc -l < "$logs")
  fi

  {
    printf '# TYPE tetragon_secret_scan_findings gauge\n'
    printf 'tetragon_secret_scan_findings %d\n' "$findings_count"
    printf '# TYPE tetragon_secret_scan_log_lines_scanned gauge\n'
    printf 'tetragon_secret_scan_log_lines_scanned %d\n' "$lines_scanned"
  } | curl -sf --data-binary @- "${pg}/metrics/job/tetragon-secret-scan" \
      || echo "warning: could not push metrics to ${pg}" >&2
fi

exit 0
