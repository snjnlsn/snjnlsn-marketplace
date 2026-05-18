---
name: handle-callouts
description: Capture session findings as callouts (discoveries, decisions, caveats, gotchas, lessons learned, known issues, complexities, edge cases) into the current session's handoff, in the format the `finalize-branch` skill later harvests. Use when the user says "this is a discovery", "save that as a decision", "that's a gotcha", "document this as a callout", or any singular/plural variant; or proactively when the session produces a non-obvious behavior just confirmed, a deliberate trade-off accepted, a constraint that surprised the session, a finding that explains repeated behavior elsewhere, or a decision that closes off an alternative explicitly considered. Delegates to session-handoff for lazy-create when no handoff exists.
---

# Handle Callouts

Capture findings worth surfacing across sessions — discoveries, decisions, caveats, and the like — as properly-formatted callout headings in the current session's handoff. Pairs with `session-handoff` (which owns the document) and `finalize-branch` (which harvests callouts at branch end).

## When to use

Activate when the user says:

- "this is a discovery / decision / caveat / gotcha / lesson learned / known issue / complexity / edge case" (singular or plural)
- "save that as a discovery / decision / caveat / gotcha / lesson / known issue / complexity / edge case"
- "that's a gotcha / discovery / decision / caveat / lesson / known issue / complexity / edge case"
- "document this as a callout" / "callout this" / "save that callout"

Also activate proactively when the session produces:

- A non-obvious behavior just confirmed (especially against a hypothesis)
- A deliberate trade-off accepted between two approaches
- A constraint that surprised the session (rate limit, schema gotcha, version pin, etc.)
- A finding that explains repeated behavior elsewhere
- A decision that closes off an alternative explicitly considered

**Mark resolved triggers** — when the user closes out a previously-recorded callout, route into `## Mark resolved subflow` instead of the authoring flow:

- **Explicit:** "mark X resolved", "this is fixed", "the JWT skew Known issue is gone now", "resolve callout 3", "<finding> is no longer applicable".
- **Proactive:** when the session's diff appears to address a callout the skill has seen in the working handoff or in the branch's older handoffs (recognition during normal session flow, not a separate scan).

Propose once per moment. If declined, don't re-propose for the same finding — the user can always trigger explicitly later.

## Terminology

**Callout** is the standard term — for the category as a whole, for individual instances when the type isn't named, and for skill/section/variable names. The eight keywords (Discovery, Decision, Caveat, Gotcha, Lesson learned, Known issue, Complexity, Edge case) are *types of callout*. They appear in headings (always) and in prose when:

- Mirroring the user's framing — `"save that as a decision"` → `"Saved as ### Decision — …"`.
- Mirroring surrounding writing that already uses the keyword.
- The specific type is what the prose is about — "the Discovery you saved earlier covers this."

Otherwise, default to "callout."

## Format

A callout is a Markdown heading at any level (typically `###`) where the first words match a keyword (case-insensitive), optionally followed by a number, a separator (`—`, `-`, or `:`), then a title.

Keywords — singular and plural both detected:

- `Discovery` / `Discoveries`
- `Decision` / `Decisions`
- `Caveat` / `Caveats`
- `Gotcha` / `Gotchas`
- `Lesson learned` / `Lessons learned`
- `Known issue` / `Known issues`
- `Complexity` / `Complexities`
- `Edge case` / `Edge cases`

Valid heading examples:

- `### Discovery — JWT clock skew tolerance varies by platform`
- `### Discovery 4 — JWT clock skew tolerance varies by platform`
- `#### Decision: drop legacy session middleware`
- `### Edge cases — empty input handling`
- `### Known issues` (bare, no title)

Body: everything under the heading until the next heading. Write in normal session voice; `finalize-branch` rewrites bodies atemporally at routing time, so don't pre-strip "during this session" or "we found that".

**Title by finding, not task:** `### Discovery — JWT clock skew tolerance varies by platform`, not `### Discovery — investigated JWT auth`.

**Anti-pattern — bare callout-keyword parent sections:** never use `## Discoveries`, `## Decisions`, `## Caveats` as parent section names. Those headings themselves match the keyword pattern, so the entire section body harvests as one callout. `## Callouts` is safe (not on the keyword list).

## Interaction modes

| Source | Behavior |
|---|---|
| Explicit user request, type named ("save that as a decision") | Auto-write. One-line report: `Saved as ### Decision — drop legacy session middleware to <handoff path>.` |
| Explicit user request, type unspecified ("save that callout" / "callout this") | Propose type + title; confirm before write. |
| Implicit recognition (you notice a callout-worthy moment) | Propose type + title + body draft; confirm before write. Phrasing: "This looks like a discovery worth capturing: `### Discovery — JWT clock skew tolerance varies by platform`. Save?" |

## Authoring flow

When the skill fires:

1. **Determine working handoff path.**
   - If working handoff is in conversation context → use it.
   - Else → invoke `session-handoff` via the Skill tool. It handles lazy-create or context re-discovery. Resume here with the resolved path.

2. **Compose the callout.**
   - **Type** — from explicit user phrasing, or your classification (one of the 8 keywords). Prefer singular form for a single finding.
   - **Title** — short, names the *finding* not the *task*. Separator: ` — ` (em dash with spaces) by convention; the regex also accepts `-` and `:`. Don't auto-assign numbering.
   - **Body** — 1–3 sentences in normal session voice. Link to `path:line` over restating code. Don't pre-strip "during this session" or "we found that" — `finalize-branch` rewrites bodies atemporally at routing time.

3. **Confirm per the interaction-modes table above.** Skip on explicit-typed; show heading + body draft otherwise.

4. **Determine placement.**
   - **Default:** `## Callouts` section, positioned after `## Summary` and before `## Work done`. Create the section if missing.
   - **Override:** if the user explicitly asks for inline ("under the auth work-done item"), place there instead. If the named section doesn't exist, ask the user to point to an existing one or fall back to `## Callouts`.

5. **Dedup check before write.** Scan all callout-shaped headings in the working handoff — both inline-under-section placements and entries under `## Callouts`. Match on either signal:
   - **Heading text** — normalized match (lowercase, collapsed whitespace, leading numbering stripped).
   - **Body substance** — judge whether an existing callout's body covers the same finding the new draft covers, even if the heading differs.

   On a match, evaluate whether the existing callout is still correct given the new finding, and draft a proposed update:

   - **Existing still correct, no new info** → flag as redundant; no update drafted.
   - **Existing still correct, new info adds detail** → draft a body that folds both.
   - **Existing partially wrong / superseded** → draft a replacement body. If the heading itself misframes the finding, propose a heading edit too.
   - **Existing contradicts the new finding** → draft a body that records the supersession explicitly (preserves the original's reasoning, states the new conclusion).

   Then prompt with the drafted update visible: **apply update**, **replace with new (drop existing)**, **write new (separate, both stay)**, or **skip**.

   Scope: just the working handoff. Cross-handoff dedup is `finalize-branch`'s job.

6. **Apply the write** via Edit. Refresh the `**Last updated:**` timestamp.

7. **Report.** One line — `Saved as ### <type> — <title> to <handoff path>.`

## Mark resolved subflow

Activated by the explicit and proactive Mark resolved triggers in `## When to use`. Marks an existing callout resolved by writing a `> Resolved: …` blockquote line into a callout body in the working handoff. Older handoffs are read-only — never edited mid-session.

### 1. Determine working handoff path

- If working handoff is in conversation context → use it.
- Else → invoke `session-handoff` via the Skill tool. It handles lazy-create or context re-discovery. Resume here with the resolved path.

This step ensures a writable target exists before scanning. Even when the eventual target callout lives in an older handoff, the resolution-only callout still writes to the working handoff (see Step 5), so a working handoff is always required.

### 2. Identify the target callout

- Scan the working handoff first for a heading-text match against the user's reference.
- If no match in the working handoff, scan the branch's older handoffs read-only via `git log <base>..HEAD --name-only --pretty=format: -- .session-continuity/handoffs/`. Read each candidate; look for matching headings or body-substance matches.
- Surface candidates: `Did you mean ### Known issue — JWT clock skew … (in <handoff path>)? confirm / that's a different one / cancel.`
- If zero candidates surface, ask the user to name the heading or paste the body.

### 3. Compose the marker

Format: `> Resolved: <freeform note + optional commit ref>` blockquote line.

- Pull resolution context from the user's framing or the most recent commit on the branch (proactive case).
- Bare `> Resolved` (no payload) is allowed.
- Show the proposed payload to the user and let them edit before write.

### 4. Confirm and write

- **Explicit user trigger with target clear** → auto-write with one-line report (mirrors the authoring flow's explicit-typed shortcut).
- **Proactive recognition or any ambiguity** → show the proposed marker + target heading; confirm before write.

### 5. Apply the write

- **Target in the working handoff:** insert `> Resolved: …` as the first body line under the existing callout heading. Refresh `**Last updated:**` timestamp.
- **Target in an older handoff:** write a *resolution-only callout* to the working handoff — heading copied verbatim from the older callout, body containing only the marker line. Smart-merge clusters them at branch end via heading match; cluster resolution is determined by the newest member (this resolution-only callout).

### 6. Report

One line: `Marked ### <heading> resolved in <handoff path>.`

### Dedup interaction

- Resolution-only callouts skip the authoring flow's dedup check. `finalize-branch`'s smart-merge handles the cluster at branch end.
- Marking resolved a callout that already has a marker → prompt: `replace / keep existing / cancel`.

### Edge cases

- **Reversing a resolution mid-session.** User says "actually that came back." Edit the marker line out, or write a new active callout in the working handoff if the resolution-only one is the only record. Smart-merge will treat the cluster as active per latest-wins.
- **Resolution-only callout has no source heading match in older handoffs.** Smart-merge won't cluster it. Surface a warning at write time: `no matching active callout found in branch handoffs — this won't count as a resolution at finalize-branch time. Continue?`
- **Mark resolved on a callout type the heuristic narrows out** (Discovery, Decision, Lesson learned). Allowed — the marker writes; `finalize-branch` silently drops at routing time.

## Writing style

Callouts follow the "Language and tone" rules from `session-handoff` SKILL.md (lines 74-97). The pertinent points:

- 1–3 sentences. Lead with the finding.
- Cut marketing adjectives, filler ("In order to" → "to"), hedges ("It should be noted that…"), narrating the obvious, vague verbs without outcomes.
- `path:line` references over restated code. Preserve code/data fences verbatim when they're the substance of the finding.

## Edge cases

- **Numbering.** Produce unnumbered headings (`### Discovery — title`) by default. Numbering is allowed by the regex but not auto-assigned. `finalize-branch` strips numbering during dedup, so unnumbered keeps things cleaner and avoids collision with manually-numbered entries.

- **Multiple callouts in one trigger** ("these last three are all decisions"). Iterate, treat each as a separate authoring flow. Per-callout confirmation still applies — explicit-but-untyped (user said "decisions" without titles) means confirm each title before write.

- **Type outside the 8 keywords** ("save this as a tip"). Don't invent a keyword. Suggest the closest match ("Sounds like a Discovery — use that?") or ask the user to pick from the list.

- **Working handoff file missing** (e.g., manually deleted mid-session). Edit will fail. Surface the error, re-invoke `session-handoff` to lazy-create, retry the write.

- **Reading an old handoff ≠ writing target.** Callouts always go to the working handoff for the current session. If the user is reading a prior handoff and wants to capture a callout, the write goes to *this* session's working handoff — lazy-create one if needed, don't append to the file being read.

- **Conversation context drops the working handoff path** mid-session. Step 1 re-invokes `session-handoff`, which handles re-discovery (list `.session-continuity/handoffs/`, match session timestamp, or ask).

## Coordination with `session-handoff`

`session-handoff` recognizes callout-shaped content during its append flow and **delegates to this skill** via the Skill tool. This skill owns all callout writes: format, dedup, placement. `session-handoff` owns the handoff document lifecycle (create, read, route non-callout content, migrate). The two skills are mutually-recursive in trigger but mutually-exclusive in execution — `session-handoff`'s lazy-create runs only when no handoff exists; the delegation runs only when one does.

## Tool usage

- **Read the working handoff** to scan for existing callouts and dedup match — `Read` (handoffs are markdown, not code).
- **Write/edit the handoff** — `Edit`. Refresh `**Last updated:**` on every write.
- **Lazy-create when no handoff exists** — invoke `session-handoff` via the Skill tool; do not duplicate its lazy-create logic inline.

## Spec reference

Full design rationale: `docs/superpowers/specs/2026-04-30-handle-callouts-design.md`.
