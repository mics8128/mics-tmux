# Agent Guidance

This file only covers tmux behavior for this repository.

## tmux Config

- Treat `tmux.conf` as the source of truth for this user's tmux setup.
- The installed location is `/Users/mics/.mics-tmux`.
- `~/.tmux.conf` should be a symlink to `/Users/mics/.mics-tmux/tmux.conf`.
- After changing `tmux.conf`, reload with:

```sh
tmux source-file /Users/mics/.mics-tmux/tmux.conf
```

## Nerd Font Check

Before adding or changing status bar icons, confirm with the user that their
terminal is using a Nerd Font. The current status bar uses Nerd Font glyphs for
load, battery, and time.

Good examples:

```text
JetBrainsMono Nerd Font
Hack Nerd Font
MesloLGS NF
```

If the user does not have a Nerd Font, prefer plain ASCII status labels.

## Agent Window Status

Agents may update the current tmux window label through the window-scoped
`@mics_window_status` option:

```sh
tmux set-option -wq @mics_window_status "coding"
tmux refresh-client -S
```

Clear it before finishing if the status is temporary:

```sh
tmux set-option -uw @mics_window_status
tmux refresh-client -S
```

Suggested values:

```text
plan
coding
test
review
blocked
done
```

Example rendered labels:

```text
~/p/mics-tmux:codex(plan)
~/p/mics-tmux:codex(coding)
~/p/mics-tmux:codex(test)
~/p/mics-tmux:codex(blocked)
~/p/mics-tmux:codex(done)
```
