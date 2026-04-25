# mics-tmux

Personal tmux configuration for macOS. The config is intended to live at
`~/.mics-tmux` and be linked from `~/.tmux.conf`.

## Install

```sh
git clone <repo-url> ~/.mics-tmux
ln -sfn ~/.mics-tmux/tmux.conf ~/.tmux.conf
tmux source-file ~/.tmux.conf
tpack install
```

If `~/.tmux.conf` already exists and is not a symlink, back it up before linking.

Agent status integration is not installed until the agent runner has mandatory
lifecycle hooks configured to call `~/.mics-tmux/scripts/agent-status.sh`.
Prompt text and skills are advisory mechanisms only and do not count as
installation for agent status updates.

## Test

```sh
scripts/test.sh
```

## Font Requirement

The status bar uses Nerd Font icons for load, battery, time, and agent pane status. Before enabling
or changing those icons, confirm the terminal font is a Nerd Font, such as:

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

## Window Labels

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
keeps only the final folder name intact.
Shell commands such as `zsh`, `bash`, `fish`, and `sh` are omitted. `codex-*`
commands are shown as `codex`.

## Agent Status Hook

Agent status must be updated by mandatory lifecycle hooks from the agent runner.
Run the hook inside the agent process environment so `TMUX_PANE` points to the
pane that owns the agent. The helper stores status on that pane, and the tab
label renders the active pane status. If `TMUX_PANE` is missing, it refuses to
update anything. Do not rely on prompts or skills to
remember to update status; those are advisory and can be skipped by the agent.

Configure runner hooks to call `scripts/agent-status.sh`:

```sh
~/.mics-tmux/scripts/agent-status.sh busy
~/.mics-tmux/scripts/agent-status.sh auth
~/.mics-tmux/scripts/agent-status.sh question
~/.mics-tmux/scripts/agent-status.sh blocked
~/.mics-tmux/scripts/agent-status.sh done
~/.mics-tmux/scripts/agent-status.sh clear
```

Hook points should map to user-visible agent states:

```text
busy      󰔟  actively working
auth      󰌾  needs user approval or permission
question  󰋗  needs the user to answer a question
blocked   󰅖  cannot continue without external action
done      󰄬  finished the current task
```

Example labels:

```text
~/p/mics-tmux:codex 󰔟
~/p/mics-tmux:codex 󰌾
~/p/mics-tmux:codex 󰋗
~/p/mics-tmux:codex 󰅖
~/p/mics-tmux:codex 󰄬
```

### Pitfalls When Wiring a New Runner

These apply to any agent runner; runner-specific quirks live in
`reference/<runner>.md`.

- **Transient states need a recovery hook.** Setting `auth` or `question`
  only fires when the agent enters that state. If nothing fires on the way
  out, the icon stays stuck. Pair every transient hook with a "tool
  finished" hook that resets to `busy`.
- **Always clear on session end.** Without a session-end hook calling
  `clear`, the last status (usually `done`) sticks on the window after the
  agent exits.

Per-runner setup notes live under `reference/`. For Claude Code, see
[`reference/claude.md`](reference/claude.md) — it contains a complete
`settings.json` example wiring all lifecycle events to `agent-status.sh`.
For Codex, see [`reference/codex.md`](reference/codex.md) — it documents
`~/.codex/config.toml`, `~/.codex/hooks.json`, and the `request_user_input`
question-tool hook.
