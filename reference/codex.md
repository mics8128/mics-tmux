# Codex Hooks

Wire Codex lifecycle events to `scripts/agent-status.sh` so the tmux window
label reflects the current Codex state.

## Event-to-Status Mapping

| Hook Event         | Matcher              | Status     | When it fires                                  |
|--------------------|----------------------|------------|------------------------------------------------|
| `SessionStart`     | (any)                | `busy`     | Codex session starts.                          |
| `UserPromptSubmit` | (any)                | `busy`     | User submits a prompt; agent starts working.   |
| `PreToolUse`       | `request_user_input` | `question` | Codex is about to show the question UI.        |
| `PostToolUse`      | `.*`                 | `busy`     | Tool finished; agent resumes work.             |
| `PermissionRequest`| (any)                | `auth`     | Codex requests user approval or permission.    |
| `Stop`             | (any)                | `done`     | Codex finishes responding to the current turn. |

`request_user_input` is Codex's question tool name. It is not Claude's
`AskUserQuestion` matcher.

## config.toml

Enable Codex hooks in `~/.codex/config.toml`:

```toml
[features]
codex_hooks = true
```

Merge the feature with any existing `[features]` table. Do not duplicate the
table.

## hooks.json

Add to `~/.codex/hooks.json` (user-level, applies to all projects). Merge the
`hooks` block with anything already in the file.

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/Users/mics/.mics-tmux/scripts/agent-status.sh busy >/dev/null 2>&1 || true"
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/Users/mics/.mics-tmux/scripts/agent-status.sh busy >/dev/null 2>&1 || true"
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "request_user_input",
        "hooks": [
          {
            "type": "command",
            "command": "/Users/mics/.mics-tmux/scripts/agent-status.sh question >/dev/null 2>&1 || true"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "/Users/mics/.mics-tmux/scripts/agent-status.sh busy >/dev/null 2>&1 || true"
          }
        ]
      }
    ],
    "PermissionRequest": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/Users/mics/.mics-tmux/scripts/agent-status.sh auth >/dev/null 2>&1 || true"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/Users/mics/.mics-tmux/scripts/agent-status.sh done >/dev/null 2>&1 || true"
          }
        ]
      }
    ]
  }
}
```

Each command is suffixed with `>/dev/null 2>&1 || true` so it fails silently
when Codex is launched outside a tmux session.

## Codex-Specific Quirks

- **Question prompts are tools.** Codex questions use the `request_user_input`
  tool, so the question icon is driven by a `PreToolUse` matcher.
- **Generic `PreToolUse` is not used for `busy`.** Normal work starts at
  `UserPromptSubmit` and recovers after tools through `PostToolUse`.
- **Permission prompts are separate.** Approval prompts use `PermissionRequest`
  and should stay mapped to `auth`.
- **Question state needs recovery.** `PostToolUse` resets to `busy` after the
  user answers the question.
- **Session exit may leave stale state.** If Codex does not emit a shutdown
  hook in the current version, the last status can remain until the next
  session starts or the pane command changes.

## Apply Changes

Hook settings are loaded by the Codex process. Restart Codex after changing
`~/.codex/config.toml` or `~/.codex/hooks.json`.

## Verify

Check the effective config files:

```sh
grep -n "codex_hooks" ~/.codex/config.toml
node -e 'JSON.parse(require("fs").readFileSync(process.env.HOME + "/.codex/hooks.json", "utf8")); console.log("hooks.json valid JSON")'
```

Then trigger a Codex `request_user_input` question. The tmux label should show
the `question` icon while Codex waits for the answer, then return to `busy`
after the tool completes.
