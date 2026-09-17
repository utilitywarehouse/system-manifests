#!/bin/sh
set -eu

mkdir -p /work/logs /work/out

addr=${LOKI_ADDR:?}
out=/work/logs/logs.txt
: > "$out"

# Extra logcli flags are appended word-split, e.g.
#   LOKI_EXTRA_ARGS="--since=25h"
#   LOKI_EXTRA_ARGS="--from=2026-06-01T00:00:00Z --to=2026-06-08T00:00:00Z"
# shellcheck disable=SC2086
run_logcli() {
  q="$1"
  /usr/bin/logcli --addr="$addr" query \
    --output=default --no-labels --timezone=UTC --quiet \
    --parallel-duration="${SCAN_WINDOW:-1h}" \
    --parallel-max-workers="${SCAN_WORKERS:-2}" \
    --batch="${SCAN_BATCH:-500}" \
    --retries=5 --min-backoff=1 --max-backoff=10 \
    ${LOKI_EXTRA_ARGS:-} \
    "$q"
}

# Each line is <timestamp> <tag>|<cluster>|<node>|<namespace>|<pod>|<binary> #ARGS# <arguments>
# The reporter only ever reads the metadata before #ARGS#.
#
# The query is a single shell word split across lines: each segment is
# single-quoted and joined with a trailing backslash, so no newline ever lands
# in the LogQL. Continuation lines must start at the quote (no indent), else
# the whitespace would split the argument into separate words.
run_logcli '{log_source="kube_tetragon_events"} |= `"process_kprobe":` | json'\
' | line_format "kprobe|{{.cluster_name}}|{{.node_name}}|'\
'{{.process_kprobe_process_pod_namespace}}|{{.process_kprobe_process_pod_name}}|'\
'{{.process_kprobe_process_binary}} #ARGS# {{.process_kprobe_process_arguments}}"' >> "$out"

run_logcli '{log_source="kube_tetragon_events"} |= `"process_exec":` | json'\
' | line_format "exec|{{.cluster_name}}|{{.node_name}}|'\
'{{.process_exec_process_pod_namespace}}|{{.process_exec_process_pod_name}}|'\
'{{.process_exec_process_binary}} #ARGS# {{.process_exec_process_arguments}}"' >> "$out"
