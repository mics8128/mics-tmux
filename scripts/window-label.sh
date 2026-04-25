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

process_cmd=

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
      for (pid in process_args) {
        if (!descendant_of_pane(pid)) continue
        args = process_args[pid]
        if (matches(args, "nvim")) {
          print "nvim"
          exit
        }
      }
      for (pid in process_args) {
        if (!descendant_of_pane(pid)) continue
        args = process_args[pid]
        if (matches(args, "vim")) {
          print "vim"
          exit
        }
      }
    }
  ')
fi

if [ -n "$process_cmd" ]; then
  cmd=$process_cmd
fi

case "$cmd" in
  codex*) cmd=codex ;;
  [0-9]*.[0-9]*.[0-9]*) cmd=claude ;;
  zsh|bash|fish|sh) cmd= ;;
esac

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
