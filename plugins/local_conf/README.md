# local_conf

Personal Claude Code plugin holding hooks and helper scripts for `services@snjnlsn.co`'s local setup. Part of the [`snjnlsn-marketplace`](../../README.md).

## What's inside

### Hooks

| Event | Behavior |
|---|---|
| `SessionStart` | Activates Serena. |
| `Stop` | Serena cleanup. |
| `PreToolUse` | (1) Auto-approves `mcp__serena__*` tool calls. (2) `scripts/sed-guard.sh` blocks `sed -i` / `--in-place`. |

### Scripts

| Script | Used by | Purpose |
|---|---|---|
| `scripts/sed-guard.sh` | `PreToolUse` | Block in-place sed |

## Installation

1. Install the marketplace in Claude Code:
   ```
   /plugin marketplace add @snjnlsn/snjnlsn-marketplace
   ```

2. Install the plugin:
   ```
   /plugin install local_conf@snjnlsn-marketplace
   ```

## After structural changes

Run `/reload-plugins` in Claude Code, or restart.
