# Session-handoff callout delegation — design

**Status:** spec, pre-implementation
**Date:** 2026-04-30
**Plugins:** `local_conf`

## Problem

`handle-callouts` (PR #6) introduced smart dedup at write time, and PR #7 aligned `finalize-branch`'s cross-handoff dedup to the same logic. `session-handoff` retained its callout safety-net role from before either change — when the user explicitly invokes "update the handoff" with content `handle-callouts` missed, `session-handoff` writes a properly-formatted callout itself.

`session-handoff/SKILL.md` documents callout format and routing (lines 99-140) but never tells the safety-net path to run dedup. So a callout written via `session-handoff` skips the dedup logic that `handle-callouts` and `finalize-branch` both apply at their callsites — a small alignment gap.

## Scope and deliverables

| Skill | Change |
|---|---|
| `session-handoff` | Safety-net path delegates callout writes to `handle-callouts` via the Skill tool. Slim down the duplicated `## Callouts` format spec; keep a pointer. |
| `handle-callouts` | Coordination section clarified — safety-net is strictly delegation, not direct write. |

**Out of scope:**

- Any change to dedup logic itself.
- Any change to `finalize-branch`.
- Renaming of `session-handoff`'s `## Callouts` section.

## Mechanism

When `session-handoff`'s `### Append to existing handoff` flow processes content, it checks first whether the content matches any of `handle-callouts`' triggers — see its `## When to use` section. Initially these cover callout-shaped headings and callout-worthy findings; once the resolution-detection spec (`2026-04-30-callout-resolution-detection-design.md`) ships, they'll also cover resolution-shaped phrases ("mark X resolved", "this is fixed", "<finding> is no longer applicable"). On a match, `session-handoff` invokes `handle-callouts` via the Skill tool and stops. `handle-callouts` then runs the appropriate subflow — authoring with dedup, or Mark resolved — and writes.

This delegation criterion stays stable across future trigger additions: `session-handoff` always defers to whatever `handle-callouts`' `## When to use` section currently lists. No re-edits to `session-handoff` are needed when `handle-callouts`' trigger set grows.

The append flow continues to own routing of non-callout content: work-done, open-questions, summary edits, retrospective edits.

## No-loop guarantee

`session-handoff` invokes `handle-callouts` only during append (the working handoff already exists). `handle-callouts` invokes `session-handoff` only for lazy-create (no working handoff exists). The two trigger conditions are mutually exclusive — neither path can recurse into the other.

## Edits

### `session-handoff/SKILL.md`

1. **`### Append to existing handoff`** — add a step at the top:

   > **Step 0 — Callout delegation.** If the content matches any trigger in `handle-callouts/SKILL.md`'s `## When to use` section (callout-shaped headings, callout-worthy findings, and — once the resolution-detection spec ships — resolution-shaped phrases), invoke `handle-callouts` via the Skill tool and stop. The remaining steps in this flow handle non-callout content only.

2. **`## Callouts: discoveries, decisions, caveats`** (lines 99-140) — slim down. Keep:
   - The pointer: "`handle-callouts` is the primary author. See its SKILL.md for keyword list, format, dedup logic, and authoring flow."
   - The placement guidance (inline-under-section vs. dedicated `## Callouts` section), since it's still routing-relevant for both skills.

   Drop the duplicated keyword list and format examples — `handle-callouts` owns them.

3. **`## Routing content to the right section`** — change the existing callout bullet from "record as a callout heading" to "delegate to `handle-callouts`."

### `handle-callouts/SKILL.md`

**`## Coordination with session-handoff`** — replace the existing text:

> `session-handoff` retains its callout safety-net role: when the user explicitly invokes it to "update the handoff" and there's a finding this skill missed, `session-handoff` can still write a properly-formatted callout. This skill is the primary author during the session; `session-handoff` is the safety net. Both write to the same handoff in the same format.

with:

> `session-handoff` recognizes callout-shaped content during its append flow and **delegates to this skill** via the Skill tool. This skill owns all callout writes: format, dedup, placement. `session-handoff` owns the handoff document lifecycle (create, read, route non-callout content, migrate). The two skills are mutually-recursive in trigger but mutually-exclusive in execution — `session-handoff`'s lazy-create runs only when no handoff exists; the delegation runs only when one does.

## Edge cases

- **Mixed content in one append.** User says "add this batch — the JWT skew issue is a Discovery, the rest is work-done bullets." `session-handoff` splits: callout content delegates to `handle-callouts`; non-callout content routes through the existing append flow. Two skill invocations may be needed.
- **Detection false negative.** `session-handoff`'s callout-shape check misses callout-worthy content; it routes as work-done. The user can later invoke `handle-callouts` explicitly to re-classify. No data loss, just suboptimal placement.
- **Detection false positive.** `session-handoff` thinks something's a callout but it isn't. `handle-callouts` runs its own classification — if it doesn't recognize a callout shape, it can ask the user or fall back. (Not implemented by this spec; relies on `handle-callouts`' existing behavior.)
- **Skill tool unavailable.** `session-handoff` falls back to writing the callout itself in the established format — same code path as today. Logs a note. Out of scope to harden further.

## Spec reference

- `session-handoff/SKILL.md` — append flow, callout section, routing section.
- `handle-callouts/SKILL.md` — coordination section + the "When to use" trigger list `session-handoff` defers to.
- `2026-04-30-cross-skill-callout-dedup-alignment-design.md` — the immediate predecessor; `session-handoff` was explicitly out of scope there.
- `2026-04-30-handle-callouts-design.md` — original design rationale.
