#!/bin/sh

set -eu

status=${1:-}

usage() {
  cat <<'USAGE'
Usage: agent-status.sh <busy|auth|question|blocked|done|clear>

Statuses:
  busy      Agent is actively working.
  auth      Agent needs user approval or permission.
  question  Agent needs the user to answer a question.
  blocked   Agent cannot continue without external action.
  done      Agent finished the current task.
  clear     Remove the status from the current tmux window.
USAGE
}

case "$status" in
  busy|auth|question|blocked|done)
    tmux set-option -wq @mics_window_status "$status"
    ;;
  clear)
    tmux set-option -uw @mics_window_status
    ;;
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

tmux refresh-client -S
