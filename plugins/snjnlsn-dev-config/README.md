# snjnlsn-dev-config

Personal Claude Code and Codex plugin holding development hooks, helper
scripts, workflow caveats, and opinionated code-quality guidance for
`services@snjnlsn.co`'s local setup. Part of the
[`snjnlsn-marketplace`](../../README.md).

## What's inside

### Skills

| Skill | Purpose |
|---|---|
| `good-quality-code` | Quality bar for readable, maintainable code, module boundaries, tests, and Ash/Phoenix/Elixir choices. |
| `superpowers-caveat` | When using Superpowers skills, prefer and adhere to repo-local instructions and opinionated skills for reading, writing, and reviewing code. |

### Hooks

| Event | Behavior |
|---|---|
| `SessionStart` | Activates Serena. |
| `Stop` | Serena cleanup. |
| `PreToolUse` | (1) Auto-approves `mcp__serena__*` tool calls. (2) `scripts/sed-guard.sh` blocks `sed -i` / `--in-place`. |

### Scripts

| Script | Used by | Purpose |
|---|---|---|
| `scripts/sed-guard.sh` | `PreToolUse` | Block in-place sed. |

## Installation

1. Install the marketplace in Claude Code:
   ```
   /plugin marketplace add @snjnlsn/snjnlsn-marketplace
   ```

2. Install the plugin:
   ```
   /plugin install snjnlsn-dev-config@snjnlsn-marketplace
   ```

## After structural changes

Run `/reload-plugins` in Claude Code, or restart.
