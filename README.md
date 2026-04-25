# mics-tmux

Personal tmux configuration. It is intended to live at `~/.mics-tmux` and be
linked from `~/.tmux.conf`.

The config is used primarily on macOS. The helper scripts stick to POSIX shell
and common Unix tools where possible, so most behavior should also work on
Linux or WSL. The battery indicator uses macOS `pmset`; on systems without it,
the battery segment is simply omitted.

## Install

```sh
git clone <repo-url> ~/.mics-tmux
ln -sfn ~/.mics-tmux/tmux.conf ~/.tmux.conf
tmux source-file ~/.tmux.conf
tpack install
```

If `~/.tmux.conf` already exists and is not a symlink, back it up before
linking.

Runtime requirements:

- `tmux`
- `tpack`
- POSIX `sh` plus common Unix tools such as `awk`, `sed`, `cut`, `cksum`,
  `date`, `ps`, and `uptime`
- A Nerd Font in the terminal for status icons

## Font Requirement

The status bar uses Nerd Font icons for load, battery, time, and agent pane
status. Use a Nerd Font such as:

- JetBrainsMono Nerd Font
- Hack Nerd Font
- MesloLGS NF

Without a Nerd Font, the icons may render as boxes. The rest of the config still
works.

## Key Bindings

Prefix is tmux default `Ctrl-b`.

```text
Alt-1..9      switch to window 1..9

Ctrl-b t      new window in the current pane directory
Ctrl-b c      new window in the current pane directory

Ctrl-b \      horizontal split in the current pane directory
Ctrl-b -      vertical split in the current pane directory

Ctrl-b h/j/k/l  focus left/down/up/right pane
Ctrl-b H/J/K/L  resize pane left/down/up/right

Ctrl-b r      refresh client
Ctrl-b R      reload ~/.mics-tmux/tmux.conf

Ctrl-b x      confirm and kill pane
Ctrl-b X      confirm and kill window
```

## Status Bar

The right side shows load, battery, and time. It is rendered by
`scripts/status-right.sh` and cached per minute, so time updates shortly after
the minute changes while avoiding repeated battery/load probes.

Window labels are rendered by `scripts/window-label.sh`.

The label format is:

```text
short/path[:command][ status-icon|(custom)]
```

Examples:

```text
~/p/mics-tmux:codex
~/.p/f/project
/p/v/f/project
~/Downloads
~/a/b/c/project:nvim(build)
```

The path shortener keeps `~`, abbreviates intermediate folders to one character,
abbreviates hidden intermediate folders to two characters such as `.p`, and
keeps only the final folder name intact. Shell commands such as `zsh`, `bash`,
`fish`, and `sh` are omitted. `codex-*` commands are shown as `codex`.

## Agent Status

Agent status integration is optional. It is not installed until the agent runner
has mandatory lifecycle hooks configured to call
`~/.mics-tmux/scripts/agent-status.sh`.

Run hooks inside the agent process environment so `TMUX_PANE` points to the pane
that owns the agent. The helper stores status on that pane, and the tab label
renders the active pane status. If `TMUX_PANE` is missing, it refuses to update
anything.

Configure runner hooks to call:

```sh
~/.mics-tmux/scripts/agent-status.sh busy
~/.mics-tmux/scripts/agent-status.sh auth
~/.mics-tmux/scripts/agent-status.sh question
~/.mics-tmux/scripts/agent-status.sh blocked
~/.mics-tmux/scripts/agent-status.sh done
~/.mics-tmux/scripts/agent-status.sh clear
```

Statuses:

```text
busy      󰔟  actively working
auth      󰌾  needs user approval or permission
question  󰋗  needs the user to answer a question
blocked   󰅖  cannot continue without external action
done      󰄬  finished the current task
clear        remove the pane status
```

Example labels:

```text
~/p/mics-tmux:codex 󰔟
~/p/mics-tmux:codex 󰌾
~/p/mics-tmux:codex 󰋗
~/p/mics-tmux:codex 󰅖
~/p/mics-tmux:codex 󰄬
```

Runner-specific setup:

- Claude Code: [`reference/claude.md`](reference/claude.md), with example
  hooks in [`reference/claude.settings.json`](reference/claude.settings.json)
- Codex: [`reference/codex.md`](reference/codex.md), with examples in
  [`reference/codex.config.toml`](reference/codex.config.toml) and
  [`reference/codex.hooks.json`](reference/codex.hooks.json)

## Updating

```sh
cd ~/.mics-tmux
git pull
tmux source-file ~/.tmux.conf
```

Restart Claude Code or Codex after changing their hook settings.

## Development

Development notes, test coverage, and reference-example maintenance rules live
in [`DEVELOPMENT.md`](DEVELOPMENT.md).
