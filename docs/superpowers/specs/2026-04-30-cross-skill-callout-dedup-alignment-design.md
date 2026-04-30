# Cross-skill callout dedup alignment — design

**Status:** spec, pre-implementation
**Date:** 2026-04-30
**Plugins:** `local_conf`

## Problem

`handle-callouts` (shipped in PR #6) introduced smart dedup at write time: heading-text **or** body-substance match, with smart-resolution categories (redundant / new info adds detail / partially wrong / contradicts) and a four-option prompt (apply update / replace / keep both / skip). `finalize-branch`'s existing dedup (Phase 1 Step 5, SKILL.md lines 183-185) is heading-text only, with silent first-wins behavior — so cross-handoff callouts that describe the same finding with different headings currently route as two separate items, and divergent bodies under matching headings get silently collapsed with the body diff lost.

`session-retrospect` has no callout flow at all. If retrospection surfaces callout-worthy findings (a discovery, a decision, a lesson learned worth permanent record), the skill doesn't tell Claude what to do — those items risk landing in the Retrospective narrative instead of as harvestable callouts.

## Scope and deliverables

| Skill | Change |
|---|---|
| `finalize-branch` | Phase 1 Step 5 dedup: add body-substance matching alongside heading-text. Add a smart-merge resolution sub-step before the per-callout routing walk, mirroring `handle-callouts`' rhythm with cross-handoff adaptations. |
| `session-retrospect` | Add a `## Coordination with handle-callouts` section delegating callout-worthy items, plus a one-liner pointer in `## Process` step 1 (Analyze). |
| `handle-callouts` | No changes — its dedup logic is the canonical version this work aligns to. |

**Out of scope:**

- Terminology cleanup (already conformant after PR #6).
- Cross-handoff `already-captured` detection (the substring-match logic in `finalize-branch`'s existing per-callout walk stays as-is — separate concern from dedup).
- Any change to `handle-callouts` or `session-handoff`.

## Match signals

Same as `handle-callouts`, applied across handoffs:

- **Heading text match.** Normalized canonical key (lowercase, collapse whitespace, strip leading numbering — same normalization `finalize-branch` uses today at line 184).
- **Body substance match.** Claude's semantic judgment — do the two callouts describe the same finding, even with different headings?

A pair triggers as a "match" if either signal fires.

## Trigger threshold

| Match shape | Behavior |
|---|---|
| **True duplicate**: heading matches by canonical normalization **and** body matches by string equality after collapsing whitespace runs and trimming leading/trailing whitespace (no semantic judgment) | **Silent collapse, first wins** (no prompt) |
| Heading match, body diverges (whitespace-stripped string inequality) | Smart-merge prompt |
| Body-substance match (semantic judgment), heading diverges | Smart-merge prompt |

This is a pragmatic hybrid that diverges slightly from `handle-callouts` (which prompts even on "redundant, no new info" within a single handoff). The reasoning: cross-handoff true duplicates are common (later handoffs often repeat earlier callouts to track them); same-handoff true duplicates are unusual. Prompting on every cross-handoff true duplicate would undermine the smart-merge value.

## Resolution categories

Copied verbatim from `handle-callouts` — the semantics carry across:

| Category | When | Drafted action |
|---|---|---|
| Redundant | Same finding, no new info | No update drafted; flag and use existing |
| New info adds detail | Same finding, later one extends earlier | Draft body that folds both |
| Partially wrong / superseded | Later contradicts or supersedes earlier on a point | Draft replacement body; if heading misframes, propose heading edit |
| Contradicts | Later overturns earlier's conclusion | Draft body that records the supersession explicitly (preserves original reasoning, states new conclusion) |

## Smart-merge prompt UX

```
Body-substance match detected — Discovery 1 (in handoff A) vs Caveat 2 (in handoff B)

  Handoff A (older), ### Discovery — JWT clock skew tolerance varies by platform:
  > [body excerpt]

  Handoff B (newer), ### Caveat — JWT auth fails near midnight:
  > [body excerpt]

  Resolution category: same finding, new info adds detail.

  Proposed merged routing item (atemporal rewrite already applied):

    ### JWT clock skew tolerance varies by platform

    [synthesized body]

  Choose:
    m — merge (route the synthesis above; recommended)
    f — keep first (route Handoff A's version only)
    l — keep latest (route Handoff B's version only)
    b — keep both (route as separate items)
  Or: nuance: <text> to revise the synthesis or push back
```

**Body excerpt length:** match the existing convention in `finalize-branch` SKILL.md line 277 — first 8-12 lines of each source body, `…` truncation indicator if longer. Large clusters reduce excerpt count further (see Edge cases).

**Single-letter shortcuts** (`m`/`f`/`l`/`b`) avoid collision with the existing routing UX (`a`/`c`/`r`/`d`).

**Atemporal rewrite timing.** The synthesis applies the atemporal-rewrite rules (`finalize-branch` SKILL.md lines 311-321: strip temporal markers, strip branch/PR refs, keep code/data fences verbatim, promote heading) **before** showing the prompt. So the merged routing item is ready to flow into the routing walk. Caveat: `f` and `l` route the original heading + body verbatim; atemporal rewrite still applies at routing time as today. Only `m` benefits from the pre-prompt rewrite.

**Output of this sub-step:** a list of merged routing items, each carrying its origin metadata (which handoffs it came from, which match category triggered the merge). The per-callout routing walk consumes this list as it does today.

## Phase 1 Step 5 structure

Today's sub-sections:

```
Pattern matching → Dedup → Configuration → Per-callout routing UX → Content transformation → Step 5 close-out
```

**Replace** the current `#### Dedup` subsection (lines 183-185 — short paragraph) with a new `#### Smart-merge dedup` subsection covering match signals, trigger threshold, resolution categories, prompt UX, and output format.

**Sub-section ordering stays the same.** Smart-merge dedup runs between extraction and configuration. The Configuration step (destination resolution) and the Per-callout routing UX both operate on the merged list — no other restructuring needed.

**Step 5 close-out** gets one new line — merge tally:

```
Audit step 5 complete:
  Callouts after smart-merge: 4 (from 6 raw across 3 handoffs)
  Added to inline code docs:  1 (Acme.Users @moduledoc)
  Added to repo docs:         3 (→ docs/conventions.md)
  Already captured:           1
  Dismissed:                  1
```

The `Callouts after smart-merge:` line renders only when at least one merge happened; otherwise omitted.

**Final commit footer** (Phase 4) — extend the existing `Callouts:` line:

```
Callouts: <X> to repo docs, <Y> to inline code docs, <Z> already captured, <W> dismissed[, <M> smart-merged].
```

`smart-merged` clause omitted when M is zero.

**No changes** to the rest of Phase 1 Step 5 (pattern matching regex, configuration/destination resolution, content transformation rules) or to subsequent phases.

## session-retrospect callout-awareness

**New `## Coordination with handle-callouts` section** added at the bottom of `session-retrospect` SKILL.md (parallels `handle-callouts`' own `## Coordination with session-handoff` section):

```markdown
## Coordination with `handle-callouts`

The Retrospective section is for **experience reflection** — what went well, what didn't, how the session felt. Findings worth permanent record (discoveries, decisions, lessons learned, etc.) are **callouts**, not retrospective narrative; route those through the `handle-callouts` skill.

Example: "We picked Tailwind over CSS modules" surfacing during retro — if it's reflection ("the team responded well"), it goes in the Retrospective; if it's the decision content ("Tailwind because of utility-class density"), it goes through `handle-callouts` as a Decision callout.
```

**Plus a one-liner pointer** appended to `## Process` step 1 (Analyze):

> "If a callout-worthy item surfaces (a discovery, decision, lesson learned, etc. that should outlive the session), route through `handle-callouts` rather than into the Retrospective narrative — see Coordination section below."

## Edge cases

- **3+ handoffs match the same finding (transitive cluster).** Detect transitively: if A↔B and B↔C both match, treat all three as one cluster. Single prompt with one synthesis drawing from all sources. The `f`/`l` shortcuts mean "earliest" and "latest" across the whole cluster; middle versions are dropped if `f` or `l` is picked. No `p — pick by handoff` option — YAGNI.

- **Within-handoff matches.** Smart-merge runs across all callout pairs, regardless of source handoff. So a within-handoff body-substance match (e.g., `session-handoff`'s safety-net role wrote a near-duplicate of an earlier `handle-callouts` write) gets caught at finalize-branch time even if it slipped past `handle-callouts`' write-time dedup.

- **Cluster-level resolution category** when pairs disagree (e.g., A↔B is "new info adds detail" but A↔C is "contradicts"): use the most severe category found in the cluster (contradicts > superseded > new info > redundant). The synthesis draft must handle the contradiction explicitly.

- **Body-substance matcher false positive** — Claude judges two callouts as the same finding when they're not. Recovery: user picks `b — keep both` at the prompt. No data loss.

- **Body-substance matcher false negative** — Claude misses a real semantic match. Recovery: callouts route as separate items; user can dismiss or address one in the per-callout walk. No data loss.

- **`nuance: <text>` on the smart-merge prompt** — user pushes back on the synthesis or proposes a better one. Skill regenerates and re-prompts. Same rhythm as existing `nuance:` patterns elsewhere in Phase 1.

- **Large cluster (5+ callouts)** — display only the first 2-3 source excerpts in the prompt with a `...and N more` indicator to keep the prompt readable. The synthesis still draws from all sources.

## Spec reference

- `handle-callouts` SKILL.md — canonical dedup logic this work aligns to.
- `finalize-branch` SKILL.md Phase 1 Step 5 — replaces the `#### Dedup` subsection with `#### Smart-merge dedup`; close-out and commit footer get tally additions.
- `session-retrospect` SKILL.md — new `## Coordination with handle-callouts` section + one-liner pointer in Process step 1.
- Original `handle-callouts` design: `docs/superpowers/specs/2026-04-30-handle-callouts-design.md`.
