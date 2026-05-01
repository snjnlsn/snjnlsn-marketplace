# session-continuity

Personal Claude Code plugin holding the per-session and per-branch documentation lifecycle: handoffs that carry context across sessions, callouts that capture findings inline, retrospects that reflect on the session, and a finalize step that harvests it all into permanent docs at branch end. Part of the [`snjnlsn-marketplace`](../../README.md).

## What's inside

### Skills

| Path | Purpose |
|---|---|
| `skills/session-handoff/` | Maintains a per-session handoff document under `docs/handoffs/`. Author-tagged filenames support multiple users sharing one repo; tone guidance keeps prose plain and disclaimer-marked; includes a one-shot migration path for legacy single-user filenames. |
| `skills/session-retrospect/` | End-of-session reflection. After explicit approval: narrative appended to the current handoff; concrete edits applied directly to the affected files (skills, `CLAUDE.md`, settings, hooks). |
| `skills/handle-callouts/` | Capture session findings as callouts (discoveries, decisions, caveats, gotchas, lessons learned, known issues, complexities, edge cases) in the current session's handoff. Triggers on explicit phrases or proactive recognition. |
| `skills/finalize-branch/` | End-of-branch pipeline — audits and updates inline code docs and project docs (with language/tone guidance), removes the branch's handoffs, produces one final commit; supports cancel-and-resume via stash. |

### Hooks

| Event | Behavior |
|---|---|
| `SessionStart` | Runs `scripts/handoff-list-recent.sh` — lists the most recent handoffs in `docs/handoffs/` and points the session at the `session-handoff` / `session-retrospect` skills. |
| `Stop` | Runs `scripts/stop-nudge.sh` — emits a wrap-up reminder when the session has run long enough, rate-limited per session. |

### Scripts

| Script | Used by | Purpose |
|---|---|---|
| `scripts/handoff-list-recent.sh` | `SessionStart` | List recent handoffs for context injection. |
| `scripts/stop-nudge.sh` | `Stop` | Rate-limited wrap-up reminder. |

## Installation

1. Install the marketplace in Claude Code:
   ```
   /plugin marketplace add @snjnlsn/snjnlsn-marketplace
   ```

2. Install the plugin:
   ```
   /plugin install session-continuity@snjnlsn-marketplace
   ```

## After structural changes

Run `/reload-plugins` in Claude Code, or restart.
