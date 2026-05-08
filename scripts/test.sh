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

if command -v node >/dev/null 2>&1; then
  node -e 'const fs = require("fs"); const root = process.argv[1]; for (const path of ["reference/claude.settings.json", "reference/codex.hooks.json"]) JSON.parse(fs.readFileSync(root + "/" + path, "utf8"));' "$repo_dir" >/dev/null
  printf 'ok - reference JSON examples\n'

  codex_pre_tool_command=$(node -e 'const fs = require("fs"); const root = process.argv[1]; const data = JSON.parse(fs.readFileSync(root + "/reference/codex.hooks.json", "utf8")); console.log(data.hooks.PreToolUse[0].hooks[0].command);' "$repo_dir")
  printf '{"tool_name":"request_user_input"}' | TMUX_PANE= sh -c "$codex_pre_tool_command"
  printf '{"tool_name":"exec_command"}' | TMUX_PANE= sh -c "$codex_pre_tool_command"
  printf 'ok - codex example pre-tool command\n'

  claude_permission_command=$(node -e 'const fs = require("fs"); const root = process.argv[1]; const data = JSON.parse(fs.readFileSync(root + "/reference/claude.settings.json", "utf8")); console.log(data.hooks.PermissionRequest[0].hooks[0].command);' "$repo_dir")
  printf '{"tool_name":"AskUserQuestion"}' | TMUX_PANE= sh -c "$claude_permission_command"
  printf '{"tool_name":"Bash"}' | TMUX_PANE= sh -c "$claude_permission_command"
  printf 'ok - claude example permission command\n'
else
  printf 'ok - reference JSON examples skipped (node unavailable)\n'
fi

grep -q 'codex_hooks = true' "$repo_dir/reference/codex.config.toml"
printf 'ok - codex config example\n'

hook_tool_name() {
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

  printf '%s' "$tool_name"
}

codex_pre_tool_status() {
  case "$(hook_tool_name)" in
    request_user_input) printf 'question' ;;
    *) printf 'busy' ;;
  esac
}

claude_permission_request_status() {
  case "$(hook_tool_name)" in
    AskUserQuestion) printf 'skip' ;;
    *) printf 'auth' ;;
  esac
}

assert_eq "codex" "$("$repo_dir/scripts/effective-command.sh" "" "codex-something" agent)" "codex fallback"
assert_eq "claude" "$("$repo_dir/scripts/effective-command.sh" "" "1.2.3" agent)" "claude version fallback"
assert_eq "" "$("$repo_dir/scripts/effective-command.sh" "" "zsh" label)" "shell fallback hidden"

test_cache_dir="${TMPDIR:-/tmp}/mics-tmux-test-$$"
rm -rf "$test_cache_dir"
assert_eq "codex" "$(MICS_TMUX_CACHE_DIR=$test_cache_dir "$repo_dir/scripts/effective-command.sh" "" "codex-something" agent)" "effective command cache write"
assert_eq "codex" "$(MICS_TMUX_CACHE_DIR=$test_cache_dir "$repo_dir/scripts/effective-command.sh" "" "codex-something" agent)" "effective command cache read"
rm -rf "$test_cache_dir"

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

assert_eq "skip" \
  "$(printf '{"tool_name":"AskUserQuestion"}' | claude_permission_request_status)" \
  "claude question permission skip"

assert_eq "auth" \
  "$(printf '{"tool_name":"Bash"}' | claude_permission_request_status)" \
  "claude generic permission auth"

assert_eq "https://example.com/abcdefghijklmnopqrstuvwxyz" \
  "$(printf '%s\n' 'https://example.com/abcde' 'fghijklmnopqrstuvwxyz' | TMUX_PANE_WIDTH=25 MICS_TMUX_URL_PICKER_PRINT_ONLY=1 "$repo_dir/scripts/tmux-url-picker.sh")" \
  "url picker joins wrapped URL"

assert_eq "https://example.com/abcde" \
  "$(printf '%s\n' 'note https://example.com/abcde' 'plain-followup' | TMUX_PANE_WIDTH=40 MICS_TMUX_URL_PICKER_PRINT_ONLY=1 "$repo_dir/scripts/tmux-url-picker.sh")" \
  "url picker does not join unwrapped URL"

assert_eq "https://example.com/abcde" \
  "$(printf '%s\n' 'note https://example.com/abcde' 'https://second.example/path' | TMUX_PANE_WIDTH=40 MICS_TMUX_URL_PICKER_PRINT_ONLY=1 "$repo_dir/scripts/tmux-url-picker.sh" | tail -n 1)" \
  "url picker keeps separate URLs"

"$repo_dir/scripts/agent-status.sh" --help >/dev/null
printf 'ok - agent-status help\n'
