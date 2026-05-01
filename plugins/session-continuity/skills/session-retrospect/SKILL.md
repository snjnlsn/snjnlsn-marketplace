---
name: session-retrospect
description: Reflect on the current session — what went well, what didn't, and what concrete changes to make to skills, CLAUDE.md, settings, or hooks. Use when the user says "retrospect", "retrospect this session", "let's retro", frames "what went well / what didn't", or accepts the wrap-up nudge from the Stop hook. Nothing is persisted before the user approves.
---

# Session Retrospect

Reflect on a session. Produce narrative insight (saved to the current session's handoff) plus a list of concrete edits to apply (only after user approval).

## When to use

Activate when the user says:
- "retrospect" / "retrospect this session" / "let's retro"
- frames "what went well" / "what didn't go well"

Also activate when the Stop hook has surfaced a wrap-up nudge and the user accepts.

## Process

1. **Analyze.** Look at the session transcript context. Identify:
   - What went well (decisions that paid off, smooth flows, useful tools)
   - What didn't (friction, dead ends, repeated corrections, missing context)
   - Candidate concrete changes:
     - Skills (in this marketplace's plugins or any other accessible skill location)
     - `~/.claude/CLAUDE.md` (global instructions)
     - Per-project CLAUDE.md
     - `~/.claude/settings.json`
     - Hooks

   If anything matching a trigger in `handle-callouts/SKILL.md`'s `## When to use` section surfaces — a new callout-worthy finding (discovery, decision, lesson learned, etc.) **or** a resolution-shaped statement that closes out a previous callout — route through `handle-callouts` rather than into the Retrospective narrative. See Coordination section below.
2. **Present.** Write the retrospective to the user as a structured message with three sections (well / not well / candidate changes). Each candidate change should name the file and the proposed edit clearly enough that approval is meaningful.
3. **Discuss.** The user can edit, add, remove, or reframe items. Keep the draft in conversation context. **Do not persist anything yet.**
4. **Apply on approval.** When the user gives a clear "persist" / "apply these" / "ok do it" signal:
   1. Append a `## Retrospective` section to the *current session's* handoff. If no handoff exists yet for this session, lazy-create one (delegate to the `session-handoff` skill flow: derive slug, compute filename, create file with template). The Retrospective section content is the agreed-upon narrative — what went well, what didn't — *not* the list of file changes.
   2. Apply each approved concrete change directly via Edit/Write tools to the affected files.
   3. Confirm what was written and what was edited.

## Constraints

- Nothing is persisted before the user approves.
- The "Retrospective" section in the handoff is narrative only (well / not well). Concrete file changes go to the files themselves; do not duplicate them in the handoff.
- If the user approves only narrative without applying changes, that's fine — apply just the handoff append.
- If the user approves only concrete changes without saving narrative, that's fine too.
- If the session was very short or the user explicitly skips the analysis step, do not invent observations. Say so plainly.

## Coordination with `handle-callouts`

The Retrospective section is for **experience reflection** — what went well, what didn't, how the session felt. Anything matching a trigger in `handle-callouts/SKILL.md`'s `## When to use` section routes through `handle-callouts` rather than into the Retrospective narrative. That covers two cases:

- **New findings worth permanent record** (discoveries, decisions, lessons learned, etc.) → `handle-callouts` authoring flow writes a callout.
- **Resolution-shaped statements that close out a previous callout** ("we resolved the JWT skew issue", "<finding> is no longer applicable") → `handle-callouts` Mark resolved subflow writes the marker. Without this, the resolution falls through to the lightweight heuristic at `finalize-branch` time, which is less reliable.

Examples:

- "We picked Tailwind over CSS modules" surfacing during retro — if it's reflection ("the team responded well"), Retrospective; if it's the decision content ("Tailwind because of utility-class density"), `handle-callouts` Decision callout.
- "We resolved the JWT skew Known issue this session" — `handle-callouts` Mark resolved subflow, not retrospective narrative.
