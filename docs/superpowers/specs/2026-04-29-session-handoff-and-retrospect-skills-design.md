# Session Handoff & Retrospect Skills

**Date:** 2026-04-29
**Status:** Approved — ready for implementation plan
**Plugin:** `local_conf`

## Problem

There is currently no in-session mechanism in this setup for capturing what a session accomplished, surfacing prior session context at the start of a new one, or reflecting on how a session went and feeding those lessons back into skills, CLAUDE.md, or settings. Every session starts cold and ends without a written trace beyond commit history and transcript scrollback.

## Goal

Add two skills inside the `local_conf` plugin, plus accompanying hooks, that:

1. Maintain a per-session **handoff document** under `docs/handoffs/` with a timestamp and a meaningful slug, written incrementally during the session.
2. Run a **retrospective** at end of session that produces both narrative insight (saved to the handoff) and concrete edits (applied directly to skills, CLAUDE.md, settings, etc.) — but only after the user reviews and approves.

Hooks at SessionStart and Stop nudge Claude to surface relevant offers (read prior handoff, continue one, update the current one, run a retrospective at wrap-up). Manual triggers via natural-language phrases always work too.

## Non-Goals

- No automated test harness for skills or hooks. Smoke testing is sufficient.
- No SessionEnd interactivity. SessionEnd fires when interaction is no longer possible; that hook is non-interactive (or omitted).
- No retrospective file separate from the handoff. The handoff is the single per-session artifact.
- No helper shell scripts for content manipulation. All file I/O for handoffs and retrospectives goes through Claude's Edit/Write/Read tools driven by skill prompts.
- No cross-session aggregation, search, or index over handoffs. Filenames and `docs/handoffs/` listing suffice.
- No support for multiple parallel sessions writing to the same handoff. Last-write-wins is acceptable.

## Design

### File layout

New additions only — no existing files restructured.

```
plugins/local_conf/
├── hooks/
│   └── hooks.json                          # extended with SessionStart + Stop hook entries
├── scripts/
│   ├── sed-guard.sh                        # existing
│   ├── handoff-list-recent.sh              # NEW — tiny helper: lists recent handoffs for SessionStart context
│   └── stop-nudge.sh                       # NEW — Stop hook driver: rate-limited wrap-up nudge
└── skills/                                 # NEW directory
    ├── session-handoff/
    │   └── SKILL.md
    └── session-retrospect/
        └── SKILL.md
```

Note: although Approach 1 (skill-driven, no helper scripts) was chosen for *content manipulation*, two tiny shell scripts are still needed because hooks themselves cannot run Claude tools — they can only run shell commands and emit JSON. These scripts do *only* discovery and rate-limiting, not any content editing or markdown manipulation. All handoff/retrospective writes go through Claude.

### Handoff document

**Filename:** `docs/handoffs/YYYY-MM-DD-HHMMSS-<slug>.md`, relative to the working repo's cwd.

- `YYYY-MM-DD-HHMMSS` is the timestamp at the moment of *first content write* (lazy creation), not session start.
- `<slug>` is a short kebab-case summary derived by Claude from the session's work so far. If the session is too sparse to summarize, Claude asks the user.
- If a slug collision occurs on the same day (e.g., two unrelated sessions both produce `fix-auth-bug`), the second appends `-2`, `-3`, etc.

**Document template:**

```markdown
# <slug, humanized>

**Started:** <ISO timestamp at first write>
**Last updated:** <ISO timestamp, refreshed on every write>

## Summary

<one-paragraph overview of the session's purpose and outcome>

## Work done

<bullets or short paragraphs of concrete changes, decisions, and milestones>

## Open questions / next steps

<bullets of unresolved items, things to pick up later>

## Retrospective

<added when the retrospect skill finalizes; otherwise absent>
```

The skill prompt instructs Claude to use the Edit tool to splice into the right section based on what's being added (e.g., a TODO goes under "Open questions / next steps"; a description of a shipped change goes under "Work done"). Sections may be reorganized or refined during the session, but the four-section shape is the default.

### Skill: `session-handoff`

**Location:** `plugins/local_conf/skills/session-handoff/SKILL.md`

**Frontmatter `description` triggers** (informal — actual phrasing TBD in implementation):
- "add this/that to the handoff"
- "update the handoff"
- "create a handoff"
- "start a handoff for this session"
- "read the handoff" / "read the latest handoff"
- "continue the handoff at <path>"

**Behavior:**

- **Read existing handoff for context:** Use Read tool on the requested handoff file (or the most recent one if unspecified). Summarize relevance to current session. Optionally: adopt that file as the working handoff for this session if the user says so.
- **Continue / adopt existing handoff:** Set the in-conversation working handoff path to that file. Subsequent "add to handoff" calls write there.
- **Create handoff (lazy):** On the first write request, derive slug from session work. If insufficient context, ask user. Compute filename. Create `docs/handoffs/` if missing. Write the template with the first content already in the right section.
- **Append to existing handoff:** Read the file, splice content into the appropriate section using Edit, refresh "Last updated" timestamp.

**State:** the working handoff path is held in conversation context (no separate state file). If conversation context drops it, Claude re-discovers from the most recent file matching this session's pattern, or asks.

### Skill: `session-retrospect`

**Location:** `plugins/local_conf/skills/session-retrospect/SKILL.md`

**Frontmatter `description` triggers:**
- "retrospect" / "retrospect this session" / "let's retro"
- "what went well / what didn't" framing
- triggered indirectly when the Stop nudge fires and the user accepts

**Behavior:**

1. Analyze the session's transcript context. Produce a structured retrospective covering:
   - What went well
   - What didn't go well
   - Candidate changes — to skills (wherever they live, including this marketplace's plugins or upstream plugin caches), to `~/.claude/CLAUDE.md`, to per-project CLAUDE.md, to `~/.claude/settings.json`, to hooks, etc.
2. Present the retrospective to the user. Discussion follows. Items can be added, removed, or edited.
3. On a "persist" / "apply these" signal from the user:
   - Append a `## Retrospective` section to the *current session's* handoff. Lazy-create the handoff if none exists yet (same flow as the handoff skill).
   - Apply each approved concrete change directly via Edit/Write tools to the affected files.
4. Nothing is persisted before approval. The retrospective is a draft until the user signals to apply.

### Hooks

Extends `plugins/local_conf/hooks/hooks.json` with two new entries.

**`SessionStart` hook**
- Calls `${CLAUDE_PLUGIN_ROOT}/scripts/handoff-list-recent.sh`.
- The script lists up to 5 most recent files in `docs/handoffs/` (relative to cwd), sorted by mtime, formatted as `<filename> — <ISO mtime>`.
- The script then emits an `additionalContext` JSON payload pointing Claude at:
  - the list (if any)
  - the `session-handoff` skill (offer to read, continue, or start fresh)
  - the `session-retrospect` skill (available on demand)
- If `docs/handoffs/` doesn't exist or is empty, the script still emits a brief context note that the skills exist but no prior handoffs are present.

**`Stop` hook**
- Calls `${CLAUDE_PLUGIN_ROOT}/scripts/stop-nudge.sh`.
- The script reads the transcript path from stdin, counts assistant turns and elapsed wall time since session start.
- Threshold (initial values, tunable in script): nudge if (turns ≥ 20 OR elapsed ≥ 30 min) AND last-nudge timestamp for this session is ≥ 15 min ago (or absent).
- Last-nudge timestamps stored in `~/.cache/local_conf/stop-nudge/<session_id>.ts` (created lazily; cache directory created if missing).
- When threshold is met, script emits `additionalContext` suggesting Claude offer to update the handoff and/or run a retrospective if the moment looks like a wrap-up. When threshold not met, exits 0 with no output.
- Script must always exit 0 on internal error (e.g., transcript unreadable, jq missing) and emit no nudge in that case — hooks must never block or crash a session.

**`SessionEnd`:** not added. SessionEnd fires when interaction is no longer possible.

### Data flow

**At session start:**
1. SessionStart hook fires → injects context with recent handoff list and skill availability.
2. Claude surfaces an offer to the user only if recent handoffs are present.

**Mid-session, "add this to the handoff":**
1. `session-handoff` skill activates.
2. If no working handoff yet, derive slug, lazy-create the file with template, write content into the right section.
3. Otherwise, splice into the existing file via Edit.

**Stop-hook nudge:**
1. Stop hook fires after every assistant turn.
2. Script checks thresholds and rate limit; emits nudge if appropriate.
3. Claude reads the nudge and decides whether to surface a wrap-up offer.

**Retrospective:**
1. Triggered manually or via accepted Stop nudge.
2. Claude analyzes session, presents draft retrospective.
3. User discusses, edits, approves.
4. On approval, retrospective section appended to handoff (lazy-creating if needed); concrete edits applied directly.

**At session end:**
1. No interactive flow.

### Error handling & edge cases

- **`docs/handoffs/` missing** — skills create it on first write.
- **No project root / unusual cwd** — handoffs land relative to cwd; documented in skill prompts.
- **Hook script failure** (jq missing, transcript unreadable, I/O error) — script exits 0 with no output. No blocking.
- **Stop-nudge state file missing or corrupt** — treated as "never nudged"; rate limit recomputes.
- **`add to handoff` with sparse session** — skill asks for a slug, optionally proposing one from git status / prior messages.
- **Concurrent writes to the same handoff** — last write wins. Skills do Read-then-Edit (not blind overwrite) which makes accidental clobber rare.
- **Slug collision on the same day** — append `-2`, `-3`, etc.
- **Retrospective draft lost on session crash** — accepted loss. Personal tool; not a system of record.

### Testing

- **Smoke test:** invoke each skill manually after install; verify file is created in the expected location with the expected template; verify retrospective appends correctly.
- **Hook scripts:** shellcheck both new scripts. Manually verify SessionStart context injection appears in transcript; let a session run past thresholds and confirm Stop nudge fires; verify rate limit suppresses follow-up nudges within 15 min.
- **No automated test harness.**

## Open implementation details (deferred to plan)

- Exact wording of skill `description` fields (matters for Claude's trigger reliability).
- Exact wording of hook `additionalContext` payloads (matters for nudge effectiveness without being noisy).
- Whether the Stop nudge thresholds (20 turns / 30 min / 15 min cooldown) are right or need tuning after live use.
- Whether to add a `/handoff` and/or `/retrospect` slash command alongside the natural-language triggers. Tentatively yes for both; finalize in plan.
- Whether the `local_conf` README should be updated to document the new skills (yes — finalize copy in plan).
