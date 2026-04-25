# Agent Install Instructions

Install mics-tmux from https://github.com/mics8128/mics-tmux.

## Goal

- Put the repo at `~/.mics-tmux`.
- Link `~/.tmux.conf` to `~/.mics-tmux/tmux.conf`.
- Load the tmux config if tmux is available.
- Install tmux plugins with tpack if tpack is available.
- Configure Claude Code and/or Codex agent status hooks only if those tools and
  their config directories exist.
- Preserve existing user settings. Merge hook blocks; do not replace unrelated
  settings.

## Steps

1. Check for required tools: `git`, `tmux`, `sh`, `awk`, `sed`, `cut`, `cksum`,
   `date`, `ps`, and `uptime`. Note any missing tools before changing files.
2. If `~/.mics-tmux` already exists and is a git repo, pull the latest changes.
   Otherwise clone `https://github.com/mics8128/mics-tmux.git` to
   `~/.mics-tmux`.
3. If `~/.tmux.conf` exists and is not a symlink to
   `~/.mics-tmux/tmux.conf`, back it up before changing it.
4. Link `~/.tmux.conf` to `~/.mics-tmux/tmux.conf` with `ln -sfn`.
5. Run `~/.mics-tmux/scripts/test.sh`.
6. If a tmux server is available, run `tmux source-file ~/.tmux.conf`.
7. If tpack is available, run `tpack install`.
8. For Claude Code, merge `~/.mics-tmux/reference/claude.settings.json` into
   `~/.claude/settings.json` if `~/.claude` exists. Preserve unrelated
   settings.
9. For Codex, merge `~/.mics-tmux/reference/codex.config.toml` into
   `~/.codex/config.toml` and merge `~/.mics-tmux/reference/codex.hooks.json`
   into `~/.codex/hooks.json` if `~/.codex` exists. Preserve unrelated
   settings.
10. Validate JSON config files after editing. Report exactly what changed and
    any skipped steps.

Do not overwrite non-symlink config files without making a timestamped backup.
Do not assume Node, jq, Python, Homebrew, apt, or sudo are available unless you
check first. If installing missing system packages is needed, ask before doing
it.
