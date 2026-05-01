# local_conf

Personal Claude Code plugin holding hooks, helper scripts, and skills for `services@snjnlsn.co`'s local setup. Part of the [`snjnlsn-marketplace`](../../README.md).

## What's inside

### Skills

| Path | Purpose |
|---|---|
| `skills/session-handoff/` | Maintains a per-session handoff document under `docs/handoffs/`. Author-tagged filenames support multiple users sharing one repo; tone guidance keeps prose plain and disclaimer-marked; includes a one-shot migration path for legacy single-user filenames |
| `skills/session-retrospect/` | End-of-session reflection. After explicit approval: narrative appended to the current handoff; concrete edits applied directly to the affected files (skills, `CLAUDE.md`, settings, hooks). |
| `skills/finalize-branch/` | End-of-branch pipeline — audits and updates inline code docs and project docs (with language/tone guidance), removes the branch's handoffs, produces one final commit; supports cancel-and-resume via stash |
| `skills/handle-callouts/` | Capture session findings as callouts (discoveries, decisions, caveats, gotchas, lessons learned, known issues, complexities, edge cases) in the current session's handoff. Triggers on explicit phrases or proactive recognition. |

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
