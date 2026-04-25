# Claude Code Hooks

Wire Claude Code's lifecycle events to `scripts/agent-status.sh` so the tmux
window label reflects the current agent state.

## Event-to-Status Mapping

| Hook Event          | Status     | When it fires                                  |
|---------------------|------------|------------------------------------------------|
| `UserPromptSubmit`  | `busy`     | User submits a prompt; agent starts working.   |
| `PermissionRequest` | `auth`     | Agent requests tool permission.                |
| `Notification`      | `question` | Agent is idle, waiting for user input.         |
| `Stop`              | `done`     | Agent finishes responding to the current turn. |
| `StopFailure`       | `blocked`  | Stop hook failed; agent cannot continue.       |
| `SessionStart`      | `clear`    | New session begins; reset stale status.        |
| `SessionEnd`        | `clear`    | Session ends (Claude exits); clear status.     |

## settings.json

Add to `~/.claude/settings.json` (user-level, applies to all projects). Merge
the `hooks` block with anything already in your settings — do not replace.

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.mics-tmux/scripts/agent-status.sh busy >/dev/null 2>&1 || true"
          }
        ]
      }
    ],
    "PermissionRequest": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.mics-tmux/scripts/agent-status.sh auth >/dev/null 2>&1 || true"
          }
        ]
      }
    ],
    "Notification": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.mics-tmux/scripts/agent-status.sh question >/dev/null 2>&1 || true"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.mics-tmux/scripts/agent-status.sh done >/dev/null 2>&1 || true"
          }
        ]
      }
    ],
    "StopFailure": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.mics-tmux/scripts/agent-status.sh blocked >/dev/null 2>&1 || true"
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.mics-tmux/scripts/agent-status.sh clear >/dev/null 2>&1 || true"
          }
        ]
      }
    ],
    "SessionEnd": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.mics-tmux/scripts/agent-status.sh clear >/dev/null 2>&1 || true"
          }
        ]
      }
    ]
  }
}
```

Each command is suffixed with `>/dev/null 2>&1 || true` so it fails silently
when Claude Code is launched outside a tmux session.

## Apply Changes

Settings added to `settings.json` do not affect the running session until the
hook watcher reloads. Either:

- Open `/hooks` once (reloads the watcher), or
- Restart Claude Code.

## Verify

While Claude is working, the current tmux window label should pick up the
agent icon. Check the raw window option directly:

```sh
tmux show-option -wv @mics_window_status
```

Expected values: `busy`, `auth`, `question`, `blocked`, `done`, or unset
(after `clear`).
