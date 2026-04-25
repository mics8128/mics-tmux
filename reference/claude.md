# Claude Code Hooks

Wire Claude Code's lifecycle events to `scripts/agent-status.sh` so the tmux
window label reflects the current agent state.

## Event-to-Status Mapping

| Hook Event          | Matcher          | Status     | When it fires                                       |
|---------------------|------------------|------------|-----------------------------------------------------|
| `UserPromptSubmit`  | (any)            | `busy`     | User submits a prompt; agent starts working.        |
| `PermissionRequest` | (any, filtered†) | `auth`     | Agent requests tool permission.                     |
| `PermissionDenied`  | (any)            | `blocked`  | User denied permission; agent cannot proceed.       |
| `PreToolUse`        | `AskUserQuestion`| `question` | Agent is about to ask the user a question.          |
| `Notification`      | (any)            | `question` | Agent is idle, waiting for user input.              |
| `PostToolUse`       | (any)            | `busy`     | Tool finished; agent resumes work.                  |
| `Stop`              | (any)            | `done`     | Agent finishes responding to the current turn.      |
| `StopFailure`       | (any)            | `blocked`  | Stop hook failed; agent cannot continue.            |
| `SessionStart`      | (any)            | `clear`    | New session begins; reset stale status.             |
| `SessionEnd`        | (any)            | `clear`    | Session ends (Claude exits); clear status.          |

† `PermissionRequest` checks `tool_name` from stdin and skips `AskUserQuestion`,
otherwise the lock icon would briefly flash before the question icon. The
`PreToolUse` hook matched on `AskUserQuestion` then sets the question icon.

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
            "command": "{ t=$(jq -r '.tool_name // empty'); [ \"$t\" != \"AskUserQuestion\" ] && ~/.mics-tmux/scripts/agent-status.sh auth; } >/dev/null 2>&1 || true"
          }
        ]
      }
    ],
    "PermissionDenied": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.mics-tmux/scripts/agent-status.sh blocked >/dev/null 2>&1 || true"
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "AskUserQuestion",
        "hooks": [
          {
            "type": "command",
            "command": "~/.mics-tmux/scripts/agent-status.sh question >/dev/null 2>&1 || true"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.mics-tmux/scripts/agent-status.sh busy >/dev/null 2>&1 || true"
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

## Claude-Specific Quirks

- **Lock flashes before a question.** `AskUserQuestion` triggers
  `PermissionRequest` first, briefly showing the lock before the question
  icon appears. The `PermissionRequest` command above reads `tool_name`
  from stdin and skips `AskUserQuestion` so the lock no longer flashes.
- **Permission denial does not fire `PostToolUse`.** When the user denies
  a tool, the tool never runs, so the usual "tool finished → busy"
  recovery never happens. Without a `PermissionDenied` hook the icon
  stays on `auth`. The hook above maps `PermissionDenied` to `blocked` so
  it's clear the agent was stopped.

## Apply Changes

Settings added to `settings.json` do not affect the running session until the
hook watcher reloads. Either:

- Open `/hooks` once (reloads the watcher), or
- Restart Claude Code.

## Verify

While Claude is working, the current tmux window label should pick up the
agent icon. Check the raw window option directly:

```sh
tmux show-option -pt "$TMUX_PANE" -v @mics_pane_status
```

Expected values: `busy`, `auth`, `question`, `blocked`, `done`, or unset
(after `clear`).
