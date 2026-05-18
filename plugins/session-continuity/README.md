# session-continuity

Personal Claude Code plugin holding the per-session and per-branch documentation lifecycle: handoffs that carry context across sessions, callouts that capture findings inline, retrospects that reflect on the session, and a finalize step that harvests it all into permanent docs at branch end. Part of the [`snjnlsn-marketplace`](../../README.md).

Handoffs live under `.session-continuity/handoffs/` — a skill-managed directory. The plugin's skills are the only sanctioned readers and writers; the directory itself and its `README.md` sentinel survive across branch finalizations.

## Workflow

```
                  .session-continuity/handoffs/  (skill-managed)
                          │
   write ─────────────────┤
     session-handoff      │      ┌─ read ─ read-branch-handoffs
     handle-callouts      │      │         (sanctioned bulk read for
     session-retrospect   │      │          prior-session context)
                          │      │
                          ├──────┘
                          │
                          └─ delete (specific files only) ─ finalize-branch
                                  (preserves the directory + README)
```

- **Create / continue / append** to the current session's handoff → `session-handoff`.
- **Record findings** (discoveries, decisions, caveats, gotchas, lessons learned, known issues, complexities, edge cases) → `handle-callouts`.
- **Read prior context** for the active branch → `read-branch-handoffs` (sanctioned bulk read path) or `session-handoff` for a single file.
- **Reflect at session end** → `session-retrospect`.
- **Wrap a branch** → `finalize-branch` (audits, updates inline + repo docs, deletes the branch's handoff files only).

Editing, listing, or deleting files in `.session-continuity/handoffs/` outside these skills breaks the per-session, append-only contract handoffs depend on.

## Installation

1. Install the marketplace in Claude Code:
   ```
   /plugin marketplace add @snjnlsn/snjnlsn-marketplace
   ```

2. Install the plugin:
   ```
   /plugin install session-continuity@snjnlsn-marketplace
   ```

## Initial setup (per repo)

Run the setup script once per consuming repo. It creates `.session-continuity/handoffs/` and seeds it with a `README.md` warning collaborators (human and AI) that the directory is skill-managed:

```
bash <plugin-install-path>/scripts/setup-handoffs.sh
```

`<plugin-install-path>` resolves to wherever your marketplace install lives — typically `~/.claude/plugins/marketplaces/snjnlsn-marketplace/plugins/session-continuity/` (the path varies by Claude Code version and install method, so locate it with `find ~/.claude -name setup-handoffs.sh` if unsure).

The script is idempotent: re-runs preserve the existing directory and any existing `README.md`.

## What's inside

### Skills

| Path | Purpose |
|---|---|
| `skills/session-handoff/` | Maintains a per-session handoff document under `.session-continuity/handoffs/`. Author-tagged filenames support multiple users sharing one repo; tone guidance keeps prose plain and disclaimer-marked; includes a one-shot migration path for legacy single-user filenames. |
| `skills/read-branch-handoffs/` | Read-only bulk loader. Gathers every handoff attributable to the current git branch (committed on the branch + uncommitted in the working tree) and presents them in chronological order as session context. The sanctioned read path for prior-session handoffs. |
| `skills/handle-callouts/` | Capture session findings as callouts (discoveries, decisions, caveats, gotchas, lessons learned, known issues, complexities, edge cases) in the current session's handoff. Triggers on explicit phrases or proactive recognition. |
| `skills/session-retrospect/` | End-of-session reflection. After explicit approval: narrative appended to the current handoff; concrete edits applied directly to the affected files (skills, `CLAUDE.md`, settings, hooks). |
| `skills/finalize-branch/` | End-of-branch pipeline — audits and updates inline code docs and project docs (with language/tone guidance), removes the branch's specific handoff files (never the `.session-continuity/handoffs/` directory or its `README.md`), produces one final commit; supports cancel-and-resume via stash. |

### Hooks

| Event | Behavior |
|---|---|
| `SessionStart` | Runs `scripts/handoff-list-recent.sh` — lists the most recent handoffs in `.session-continuity/handoffs/` and points the session at the `read-branch-handoffs`, `session-handoff`, `handle-callouts`, and `session-retrospect` skills. |
| `Stop` | Runs `scripts/stop-nudge.sh` — emits a wrap-up reminder when the session has run long enough, rate-limited per session. |

### Scripts

| Script | Used by | Purpose |
|---|---|---|
| `scripts/setup-handoffs.sh` | Manual (per-repo bootstrap) | Creates `.session-continuity/handoffs/` and seeds it with a skill-managed-directory `README.md`. Idempotent. |
| `scripts/handoff-list-recent.sh` | `SessionStart` hook | Lists recent handoffs and emits a SessionStart `additionalContext` payload pointing Claude at the session-continuity skills. |
| `scripts/stop-nudge.sh` | `Stop` hook | Rate-limited wrap-up reminder. |

## After structural changes

Run `/reload-plugins` in Claude Code, or restart.
