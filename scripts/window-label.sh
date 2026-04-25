#!/bin/sh

path=$1
cmd=$2
status=$3
pane_pid=${4:-}
pane_id=${5:-}
status_owner=${6:-}

if [ "$status" = "__mics_empty_status__" ]; then
  status=
fi

if [ "$status_owner" = "__mics_empty_owner__" ]; then
  status_owner=
fi

case "$status:$pane_pid" in
  [0-9]*:)
    pane_pid=$status
    status=
    ;;
esac

short_path=$(printf '%s\n' "$path" | awk '
{
  path = $0
  home = ENVIRON["HOME"]

  if (path == home) {
    print "~"
    exit
  }

  if (index(path, home "/") == 1) {
    path = "~/" substr(path, length(home) + 2)
  }

  n = split(path, parts, "/")
  out = ""

  for (i = 1; i <= n; i++) {
    part = parts[i]

    if (part == "") {
      if (i == 1) out = "/"
      continue
    }

    if (i == 1 && part == "~") {
      out = "~"
      continue
    }

    if (i < n) {
      part = substr(part, 1, substr(part, 1, 1) == "." ? 2 : 1)
    }

    if (out == "" || out == "/") {
      out = out part
    } else {
      out = out "/" part
    }
  }

  print out
}')

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cmd=$("$script_dir/effective-command.sh" "$pane_pid" "$cmd" label)

if [ -n "$status" ] && [ -n "$status_owner" ] && [ "$status_owner" != "$cmd" ]; then
  if [ -n "$pane_id" ]; then
    tmux set-option -pq -u -t "$pane_id" @mics_pane_status 2>/dev/null || true
    tmux set-option -pq -u -t "$pane_id" @mics_pane_status_owner 2>/dev/null || true
  fi
  status=
fi

label=$short_path

if [ -n "$cmd" ]; then
  label="$label:$cmd"
fi

if [ -n "$status" ]; then
  case "$status" in
    busy) status_icon="󰔟" ;;
    auth) status_icon="󰌾" ;;
    question) status_icon="󰋗" ;;
    blocked) status_icon="󰅖" ;;
    done) status_icon="󰄬" ;;
    *) status_icon= ;;
  esac

  if [ -n "$status_icon" ]; then
    label="$label $status_icon"
  else
    label="$label($status)"
  fi
fi

printf '%s' "$label"
