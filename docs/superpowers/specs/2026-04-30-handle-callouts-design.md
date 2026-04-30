# `handle-callouts` skill — design

**Status:** spec, pre-implementation
**Date:** 2026-04-30
**Plugin:** `local_conf`

## Problem

`session-handoff` already defines the callout format and contains internal guidance to "proactively recognize callout-worthy moments." `finalize-branch` Phase 1 Step 5 already harvests callouts at branch end. The gap: nothing reliably triggers callout capture *during* the session. `session-handoff`'s `description` only fires on explicit handoff phrases ("add to the handoff", "create a handoff"), so its proactive-recognition guidance only runs after the skill is already loaded for some other reason. Findings made mid-session — non-obvious behaviors confirmed, trade-offs accepted, surprising constraints — slip past until the user explicitly engages with the handoff or hits end-of-branch finalization.

A dedicated skill with a `description` tuned to callout *events* (explicit phrases or implicit recognition) closes the gap.

## Terminology

**Callout** is the standard term — for the category as a whole, for individual instances when the type isn't named, and for skill/section/variable names. The eight keywords (Discovery, Decision, Caveat, Gotcha, Lesson learned, Known issue, Complexity, Edge case) are *types of callout*. They appear in headings (always) and in prose when:

- Mirroring the user's framing — `"save that as a decision"` → `"Saved as ### Decision — …"`.
- Mirroring surrounding writing that already uses the keyword — an existing handoff body's prose, an existing section name, etc.
- The specific type is what the prose is about — "the Discovery you saved earlier covers this."

Otherwise, default to "callout." The user may also override the convention explicitly (e.g., "always say discovery in this session").

## Scope and lifecycle position

| Skill | Concern |
|---|---|
| `session-handoff` | The handoff document — create, append, format, migrate. Includes safety-net callout authoring at end-of-session. |
| `handle-callouts` (new) | Callout authoring during the session — recognize, classify, persist. |
| `session-retrospect` | Retrospective narrative + concrete change proposals. |
| `finalize-branch` | Branch wrap-up: doc audit, callout routing, handoff cleanup, final commit. |

Out of scope for this skill:
- Document creation/migration/structure (owned by `session-handoff`).
- End-of-branch routing of callouts to inline/repo docs (owned by `finalize-branch` Phase 1 Step 5).
- Retrospective narrative (owned by `session-retrospect`).

## Trigger and interaction model

### `description` field

> "Capture session findings as callouts (discoveries, decisions, caveats, gotchas, lessons learned, known issues, complexities, edge cases) into the current session's handoff, in the format the `finalize-branch` skill later harvests. Use when the user says 'this is a discovery', 'save that as a decision', 'that's a gotcha', 'document this as a callout', or any singular/plural variant; or proactively when the session produces a non-obvious behavior just confirmed, a deliberate trade-off accepted, a constraint that surprised the session, a finding that explains repeated behavior elsewhere, or a decision that closes off an alternative explicitly considered. Delegates to session-handoff for lazy-create when no handoff exists."

### Interaction modes

Inherits the existing `session-handoff` rule, "Ask before writing if the framing isn't clear":

| Source | Behavior |
|---|---|
| Explicit user request, type named ("save that as a decision") | Auto-write. One-line report: `Saved as ### Decision — drop legacy session middleware to <handoff path>.` |
| Explicit user request, type unspecified ("save that callout" / "callout this") | Propose type + title; confirm before write. |
| Implicit recognition (Claude notices a callout-worthy moment) | Propose type + title + body draft; confirm before write. Phrasing: "This looks like a discovery worth capturing: `### Discovery — JWT clock skew tolerance varies by platform`. Save?" |

**Boundary on proactive recognition:** propose once per moment. If declined, don't re-propose for the same finding. The user can always trigger explicitly later.

## Authoring flow

When the skill fires:

1. **Determine working handoff path.**
   - If working handoff is in conversation context → use it.
   - Else → invoke `session-handoff` via the Skill tool. It handles lazy-create (slugifier, `git config user.name`, collision suffix, template write) or context re-discovery (list `docs/handoffs/`, match session timestamp, or ask the user). Resume here with the resolved path.

2. **Compose the callout.**
   - **Type** — from explicit user phrasing, or Claude's classification (one of the 8 keywords). Prefer singular form for a single finding.
   - **Title** — short, names the *finding* not the *task* (per `session-handoff` line 139). Separator: ` — ` (em dash with spaces) by convention; the regex also accepts `-` and `:`.
   - **Body** — 1–3 sentences in normal session voice. Link to `path:line` over restating code. Don't pre-strip "during this session" or "we found that" — `finalize-branch` rewrites bodies atemporally at routing time.

3. **Confirm per the interaction model above.** Skip on explicit-typed; show heading + body draft otherwise.

4. **Determine placement.**
   - **Default:** `## Callouts` section, positioned after `## Summary` and before `## Work done`. Create the section if missing.
   - **Override:** if the user explicitly asks for inline ("under the auth work-done item"), place there instead.

5. **Dedup check before write.** Scan all callout-shaped headings in the working handoff — both inline-under-section placements and entries under `## Callouts`. Match on either signal:
   - **Heading text** — normalized match (lowercase, collapsed whitespace, leading numbering stripped — same normalization `finalize-branch` uses at line 184).
   - **Body substance** — Claude judges whether an existing callout's body covers the same finding the new draft covers, even if the heading differs.

   On a match, evaluate whether the existing callout is still correct given the new finding, and draft a proposed update:
   - **Existing still correct, no new info** → flag as redundant; no update drafted.
   - **Existing still correct, new info adds detail** → draft a body that folds both.
   - **Existing partially wrong / superseded** → draft a replacement body. If the heading itself misframes the finding, propose a heading edit too.
   - **Existing contradicts the new finding** → draft a body that records the supersession explicitly (preserves the original's reasoning, states the new conclusion).

   Then prompt with the drafted update visible: **apply update**, **replace with new (drop existing)**, **write new (separate, both stay)**, or **skip**.

   Scope: just the working handoff. Cross-handoff dedup remains `finalize-branch`'s job.

6. **Apply the write** via `Edit`. Refresh `**Last updated:**` timestamp (per `session-handoff`'s append rules).

7. **Report.** One line — `Saved as ### <type> — <title> to <handoff path>.`

## Format spec (duplicated from `session-handoff` lines 99-140)

A callout is a Markdown heading at any level (typically `###`) where the first words match a keyword (case-insensitive), optionally followed by a number, a separator (`—`, `-`, or `:`), then a title.

Keywords — singular and plural both detected:

- Discovery / Discoveries
- Decision / Decisions
- Caveat / Caveats
- Gotcha / Gotchas
- Lesson learned / Lessons learned
- Known issue / Known issues
- Complexity / Complexities
- Edge case / Edge cases

Valid heading examples:

- `### Discovery — JWT clock skew tolerance varies by platform`
- `### Discovery 4 — JWT clock skew tolerance varies by platform`
- `#### Decision: drop legacy session middleware`
- `### Edge cases — empty input handling`
- `### Known issues` (bare, no title)

Body: everything under the heading until the next heading. Write in normal session voice; `finalize-branch` rewrites bodies atemporally at routing time, so don't pre-strip "during this session" or "we found that".

**Title by finding, not task:** `### Discovery — JWT clock skew tolerance varies by platform`, not `### Discovery — investigated JWT auth`.

**Anti-pattern — bare callout-keyword parent sections:** never use `## Discoveries`, `## Decisions`, `## Caveats` as parent section names. Those headings themselves match the keyword pattern, so the entire section body harvests as one callout. `## Callouts` is safe (not on the keyword list).

## Writing style — referenced, not duplicated

All callouts follow the "Language and tone" rules from `session-handoff` SKILL.md lines 74-97. Pertinent points the skill restates inline (rather than asking Claude to context-load the whole referenced section every time):

- 1–3 sentences. Lead with the finding.
- Cut marketing adjectives, filler, hedges, narrating the obvious, vague verbs without outcomes.
- `path:line` references over restated code. Preserve code/data fences verbatim when they're the substance of the finding.

## Edge cases

- **Numbering.** The skill produces unnumbered headings (`### Discovery — title`) by default. Numbering is allowed by the regex but not auto-assigned. `finalize-branch` strips numbering during dedup (line 184), so unnumbered keeps things cleaner and avoids collision with manually-numbered entries.

- **Multiple callouts in one trigger** ("these last three are all decisions"). Iterate, treat each as a separate authoring flow. Per-callout confirmation still applies — explicit-but-untyped (user said "decisions" without titles) means confirm each title before write.

- **Type outside the 8 keywords** ("save this as a tip"). Don't invent a keyword. Suggest the closest match ("Sounds like a Discovery — use that?") or ask the user to pick from the list.

- **Placement override to nonexistent section** ("put it under the Auth work-done item" but no such heading). Ask the user to point to an existing section, or fall back to `## Callouts`.

- **Working handoff file missing** (e.g., manually deleted mid-session). `Edit` will fail. Surface the error, re-invoke `session-handoff` to lazy-create, retry the write.

- **Reading an old handoff ≠ writing target.** Callouts always go to the working handoff for the current session. If the user is reading a prior handoff (via `session-handoff`'s read flow) and wants to capture a callout, the write goes to *this* session's working handoff — lazy-create one if needed, don't append to the file being read.

- **Conversation context drops the working handoff path** mid-session. Step 1 re-invokes `session-handoff`, which handles re-discovery (list `docs/handoffs/`, match session timestamp, or ask).

## Coordination with `session-handoff`'s callout safety-net

`session-handoff`'s "Callouts: discoveries, decisions, caveats" section (lines 99-140) and its proactive-recognition guidance (line 137) remain in place. Two reasons for the duplication:

1. The format spec is the contract `finalize-branch` reads against, and both authoring skills need to produce conforming output.
2. `session-handoff` keeps a safety-net authoring role for end-of-session catch-up — when the user invokes it explicitly to "update the handoff" and there's a finding `handle-callouts` missed, `session-handoff` can still write a properly-formatted callout without needing to defer to another skill.

`handle-callouts` is the primary author during the session; `session-handoff` is the safety net. Both write to the same handoff document in the same format.

## Spec reference

`finalize-branch` Phase 1 Step 5 (SKILL.md lines 154-359) describes the harvesting end of the contract — pattern matching, dedup, routing, atemporal rewrite. That is the authoritative source for what conforming callout output looks like; `handle-callouts` SKILL.md will mirror the format spec but defer to `finalize-branch` for the matching/harvest logic.
