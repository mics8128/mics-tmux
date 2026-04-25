#!/bin/sh

pane_pid=${1:-}
fallback_cmd=${2:-}
mode=${3:-label}

process_cmd=

if [ -n "$pane_pid" ]; then
  process_cmd=$(ps -axo pid=,ppid=,args= 2>/dev/null | awk -v pane_pid="$pane_pid" -v mode="$mode" '
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

    function print_first(name) {
      for (pid in process_args) {
        if (!descendant_of_pane(pid)) continue
        args = process_args[pid]
        if (matches(args, name)) {
          print name
          return 1
        }
      }
      return 0
    }

    END {
      if (print_first("claude")) exit
      if (print_first("codex")) exit

      if (mode == "label") {
        if (print_first("nvim")) exit
        if (print_first("vim")) exit
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
