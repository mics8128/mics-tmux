# Development

This file covers repository maintenance. User-facing install and usage
instructions live in [`README.md`](README.md).

## Compatibility

Runtime scripts should stay portable across macOS, Linux, and WSL where
reasonable. Prefer POSIX `sh` and common Unix tools:

```text
awk sed cut cksum date mkdir mv ps rm tmux uptime
```

Avoid adding runtime dependencies such as `jq`, Python, Node, GNU-only flags, or
macOS-only tools unless the script has a quiet fallback. The current exception
is `scripts/battery-icon.sh`, which uses macOS `pmset` and exits without output
when battery data is unavailable.

`node` is allowed in `scripts/test.sh` as an optional development dependency for
parsing JSON example files. It is not required at runtime.

## Caching

`scripts/status-right.sh` caches the right status segment under
`${TMPDIR:-/tmp}/mics-tmux` by minute. This keeps the clock fresh enough for the
status bar while avoiding repeated `uptime`, battery, and clock probes during
the same minute.

`scripts/effective-command.sh` caches command detection under the same cache
directory. The cache key includes mode, pane PID, and fallback command, so a pane
or foreground-command change naturally misses the cache. Set
`MICS_TMUX_CACHE_DIR` in tests to isolate cache files.

## Reference Files

Runner setup lives under `reference/`.

Markdown files explain behavior and caveats:

```text
reference/claude.md
reference/codex.md
```

Example files are meant to be copied or merged into user-level runner settings
and are parsed by `scripts/test.sh`:

```text
reference/claude.settings.json
reference/codex.config.toml
reference/codex.hooks.json
```

Keep large JSON/TOML examples out of markdown. This makes examples easier to
validate and keeps the docs focused on setup decisions.

## Tests

Run:

```sh
scripts/test.sh
tmux source-file -n tmux.conf
```

`scripts/test.sh` currently covers:

- Shell syntax for every `scripts/*.sh`
- JSON parsing for `reference/*.json` examples when `node` is available
- Smoke tests for the inline Claude and Codex hook commands from the example
  files
- `reference/codex.config.toml` containing `codex_hooks = true`
- `effective-command.sh` fallback behavior and cache read/write
- Window label path shortening, status rendering, and stale-owner hiding
- Codex and Claude hook payload parsing helpers
- `agent-status.sh --help`

It does not fully exercise live tmux pane option writes, live process-tree
detection, all battery levels, or multiple OS environments. Those need manual
checks when changed.

## Live Config Sync

When updating example hook files, compare them with the current user-level
settings if this machine is the target install:

```sh
node - <<'NODE'
const fs = require('fs');
const home = process.env.HOME;
const repo = process.cwd();
function json(path) { return JSON.parse(fs.readFileSync(path, 'utf8')); }
function sort(v) {
  if (Array.isArray(v)) return v.map(sort);
  if (v && typeof v === 'object') {
    return Object.fromEntries(Object.keys(v).sort().map(k => [k, sort(v[k])]));
  }
  return v;
}
function same(name, actual, expected) {
  const ok = JSON.stringify(sort(actual)) === JSON.stringify(sort(expected));
  console.log(`${ok ? 'ok' : 'mismatch'} - ${name}`);
}
same('codex hooks block', json(`${home}/.codex/hooks.json`).hooks, json(`${repo}/reference/codex.hooks.json`).hooks);
same('claude hooks block', json(`${home}/.claude/settings.json`).hooks, json(`${repo}/reference/claude.settings.json`).hooks);
NODE
```
