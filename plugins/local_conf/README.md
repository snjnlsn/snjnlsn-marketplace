# local_conf

Personal Claude Code plugin holding hooks, helper scripts, skills, and slash commands for `services@snjnlsn.co`'s local setup. Part of the [`snjnlsn-marketplace`](../../README.md).

## What's inside

### Skills

| Path | Purpose |
|---|---|
| `skills/session-handoff/` | Maintains a per-session handoff document under `docs/handoffs/` |
| `skills/session-retrospect/` | End-of-session reflection — narrative to the handoff, concrete edits applied directly |

### Slash commands

| Command | Purpose |
|---|---|
| `/handoff` | Route to the `session-handoff` skill |
| `/retrospect` | Route to the `session-retrospect` skill |

### Hooks

| Event | Behavior |
|---|---|
| `SessionStart` | (1) Activates Serena. (2) Runs `scripts/handoff-list-recent.sh` to inject a list of recent handoffs into context. |
| `Stop` | (1) Serena cleanup. (2) Runs `scripts/stop-nudge.sh` — emits a wrap-up reminder when the session has run long enough, rate-limited per session. |
| `PreToolUse` | (1) Auto-approves `mcp__serena__*` tool calls. (2) `scripts/sed-guard.sh` blocks `sed -i` / `--in-place`. |

### Scripts

| Script | Used by | Purpose |
|---|---|---|
| `scripts/sed-guard.sh` | `PreToolUse` | Block in-place sed |
| `scripts/handoff-list-recent.sh` | `SessionStart` | List recent handoffs for context injection |
| `scripts/stop-nudge.sh` | `Stop` | Rate-limited wrap-up reminder |

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
