#!/bin/sh

set -eu

status=${1:-}

usage() {
  cat <<'USAGE'
Usage: agent-status.sh <busy|auth|question|blocked|done|clear>

Updates the tmux pane that owns the calling process. TMUX_PANE is required;
without it the script exits without changing any tmux pane or window.

Statuses:
  busy      Agent is actively working.
  auth      Agent needs user approval or permission.
  question  Agent needs the user to answer a question.
  blocked   Agent cannot continue without external action.
  done      Agent finished the current task.
  clear     Remove the status from the agent pane.
USAGE
}

target_pane() {
  if [ -z "${TMUX_PANE:-}" ]; then
    printf 'TMUX_PANE is required; refusing to update tmux status\n' >&2
    return 1
  fi

  tmux display-message -pt "$TMUX_PANE" '#{pane_id}' 2>/dev/null
}

effective_command() {
  pane_pid=$1
  fallback_cmd=$2

  if [ -n "$pane_pid" ]; then
    process_cmd=$(ps -axo pid=,ppid=,args= 2>/dev/null | awk -v pane_pid="$pane_pid" '
      {
        pid = $1
        parent[pid] = $2
        args = ""
        for (i = 3; i <= NF; i++) {
          args = args (args == "" ? "" : " ") $i
        }
        process_args[pid] = args
      }

      function descendant_of_pane(pid) {
        while (pid in parent) {
          if (parent[pid] == pane_pid) return 1
          pid = parent[pid]
        }
        return 0
      }

      function matches(args, name) {
        return args ~ "(^|[[:space:]])" name "([[:space:]]|$)" || args ~ "/" name "([[:space:]]|$)"
      }

      END {
        for (pid in process_args) {
          if (!descendant_of_pane(pid)) continue
          args = process_args[pid]
          if (matches(args, "claude")) {
            print "claude"
            exit
          }
        }
        for (pid in process_args) {
          if (!descendant_of_pane(pid)) continue
          args = process_args[pid]
          if (matches(args, "codex")) {
            print "codex"
            exit
          }
        }
      }
    ')
  fi

  cmd=${process_cmd:-$fallback_cmd}

  case "$cmd" in
    codex*) cmd=codex ;;
    [0-9]*.[0-9]*.[0-9]*) cmd=claude ;;
    zsh|bash|fish|sh) cmd= ;;
  esac

  printf '%s' "$cmd"
}

case "$status" in
  busy|auth|question|blocked|done|clear) ;;
  -h|--help|help|"")
    usage
    exit 0
    ;;
  *)
    printf 'unknown agent status: %s\n' "$status" >&2
    usage >&2
    exit 2
    ;;
esac

target=$(target_pane)
pane_pid=$(tmux display-message -pt "$target" '#{pane_pid}' 2>/dev/null || printf '')
pane_cmd=$(tmux display-message -pt "$target" '#{pane_current_command}' 2>/dev/null || printf '')
owner=$(effective_command "$pane_pid" "$pane_cmd")

case "$status" in
  clear)
    tmux set-option -pq -u -t "$target" @mics_pane_status
    tmux set-option -pq -u -t "$target" @mics_pane_status_owner
    ;;
  *)
    tmux set-option -pq -t "$target" @mics_pane_status "$status"
    tmux set-option -pq -t "$target" @mics_pane_status_owner "$owner"
    ;;
esac

tmux refresh-client -S
