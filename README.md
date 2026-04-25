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

## Font Requirement

The status bar uses Nerd Font icons for load, battery, and time. Before enabling
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
short/path[:command][(status)]
```

Examples:

```text
~/p/mics-tmux:codex
~/Downloads
~/a/b/c/project:nvim(build)
```

The path shortener keeps `~`, abbreviates intermediate folders to one character,
and keeps the final folder name intact. Shell commands such as `zsh`, `bash`,
`fish`, and `sh` are omitted. `codex-*` commands are shown as `codex`.

## Agent Status Hook

Agents can update the active tmux window label by setting the window-scoped
`@mics_window_status` option.

```sh
tmux set-option -wq @mics_window_status "running"
tmux refresh-client -S
```

Clear it with:

```sh
tmux set-option -uw @mics_window_status
tmux refresh-client -S
```

Suggested status values:

```text
plan
coding
test
review
blocked
done
```

Example labels:

```text
~/p/mics-tmux:codex(plan)
~/p/mics-tmux:codex(coding)
~/p/mics-tmux:codex(test)
~/p/mics-tmux:codex(blocked)
~/p/mics-tmux:codex(done)
```
