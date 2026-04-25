# Codex Hooks

Wire Codex lifecycle events to `scripts/agent-status.sh` so the tmux window
label reflects the current Codex state.

## Event-to-Status Mapping

| Hook Event         | Matcher              | Status     | When it fires                                  |
|--------------------|----------------------|------------|------------------------------------------------|
| `SessionStart`     | (any)                | `busy`     | Codex session starts.                          |
| `UserPromptSubmit` | (any)                | `busy`     | User submits a prompt; agent starts working.   |
| `PreToolUse`       | `.*`                 | `busy` or `question` | Tool is about to run; inline command dispatches by tool name. |
| `PostToolUse`      | `.*`                 | `busy`     | Tool finished; agent resumes work.             |
| `PermissionRequest`| (any)                | `auth`     | Codex requests user approval or permission.    |
| `Stop`             | (any)                | `done`     | Codex finishes responding to the current turn. |

`request_user_input` is Codex's question tool name. It is not Claude's
`AskUserQuestion` matcher. The inline `PreToolUse` shell command maps it to
`question`; other `PreToolUse` payloads map to `busy`.

## config.toml

Enable Codex hooks in `~/.codex/config.toml`. The minimal example is
[`codex.config.toml`](codex.config.toml).

Merge the feature with any existing `[features]` table. Do not duplicate the
table.

## hooks.json

Add the `hooks` block from [`codex.hooks.json`](codex.hooks.json) to
`~/.codex/hooks.json` (user-level, applies to all projects). Merge it with
anything already in the file.

The example file is intentionally separate from this explanation so
`scripts/test.sh` can parse and smoke-test it.

Each command is suffixed with `>/dev/null 2>&1 || true` so it fails silently
when Codex is launched outside a tmux session.

## Codex-Specific Quirks

- **Question prompts are tools.** Codex questions use the `request_user_input`
  tool, so the inline `PreToolUse` command maps that payload to `question`.
- **The inline parser is intentionally small.** It avoids `jq` and extra repo
  helper scripts by extracting the top-level `tool_name` string with POSIX shell
  parameter expansion.
- **Approval review has no completion hook.** `PermissionRequest` runs before
  user approval or guardian auto-review, and Codex emits
  `item/autoApprovalReview/started|completed` only through the app-server
  protocol. There is no hook event for auto-review completion, so hooks can
  reset status either when a later tool starts (`PreToolUse`) or when the
  approved tool finishes (`PostToolUse`).
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
