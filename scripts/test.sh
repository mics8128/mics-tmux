#!/bin/sh

set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

assert_eq() {
  expected=$1
  actual=$2
  name=$3

  if [ "$actual" != "$expected" ]; then
    printf 'not ok - %s\n' "$name" >&2
    printf 'expected: %s\n' "$expected" >&2
    printf 'actual:   %s\n' "$actual" >&2
    exit 1
  fi

  printf 'ok - %s\n' "$name"
}

for script in "$repo_dir"/scripts/*.sh; do
  sh -n "$script"
done
printf 'ok - shell syntax\n'

codex_pre_tool_status() {
  payload=
  while IFS= read -r line || [ -n "$line" ]; do
    payload=$payload$line
  done

  tool_name=${payload#*\"tool_name\"}
  if [ "$tool_name" != "$payload" ]; then
    tool_name=${tool_name#*:}
    tool_name=${tool_name#*\"}
    tool_name=${tool_name%%\"*}
  fi

  case "$tool_name" in
    request_user_input) printf 'question' ;;
    *) printf 'busy' ;;
  esac
}

assert_eq "codex" "$("$repo_dir/scripts/effective-command.sh" "" "codex-something" agent)" "codex fallback"
assert_eq "claude" "$("$repo_dir/scripts/effective-command.sh" "" "1.2.3" agent)" "claude version fallback"
assert_eq "" "$("$repo_dir/scripts/effective-command.sh" "" "zsh" label)" "shell fallback hidden"

assert_eq "~/p/mics-tmux" \
  "$(HOME=/Users/mics "$repo_dir/scripts/window-label.sh" /Users/mics/projects/mics-tmux zsh __mics_empty_status__ "" "" __mics_empty_owner__)" \
  "short path without shell command"

assert_eq "~/p/mics-tmux:codex 󰔟" \
  "$(HOME=/Users/mics "$repo_dir/scripts/window-label.sh" /Users/mics/projects/mics-tmux codex busy "" "" codex)" \
  "codex busy label"

assert_eq "~/p/mics-tmux:codex" \
  "$(HOME=/Users/mics "$repo_dir/scripts/window-label.sh" /Users/mics/projects/mics-tmux codex busy "" "" claude)" \
  "stale owner status hidden"

assert_eq "question" \
  "$(printf '{"tool_name":"request_user_input"}' | codex_pre_tool_status)" \
  "codex question pre-tool status"

assert_eq "busy" \
  "$(printf '{"tool_name":"exec_command"}' | codex_pre_tool_status)" \
  "codex generic pre-tool status"

"$repo_dir/scripts/agent-status.sh" --help >/dev/null
printf 'ok - agent-status help\n'
