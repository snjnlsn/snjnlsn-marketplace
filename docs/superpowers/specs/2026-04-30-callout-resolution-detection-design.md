# Callout resolution detection — design

**Status:** spec, pre-implementation
**Date:** 2026-04-30
**Plugins:** `local_conf`

## Problem

`finalize-branch`'s Phase 1 Step 5 routes every extracted callout to one of four outcomes: `add-to-repo-docs`, `add-to-inline-code`, `already-captured`, `dismiss`. None of these accommodate "the callout described an issue that this branch fixed." The closest available is `dismiss`, but its framing — "transient facts with no permanent home" (`finalize-branch/SKILL.md:360`) — is wrong for "was real, now resolved."

This matters most for issue-shaped callout types (Known issue, Caveat, Gotcha, Edge case): the callout describes a state of the system that the branch's work may close out. A resolved callout has no current state to document, so it shouldn't be routed to docs or inline code — it should be dropped from the routing walk entirely, with its existence acknowledged in the commit footer.

`handle-callouts` has no way to mark a callout resolved mid-session, and `finalize-branch` has no way to detect resolution at branch end without explicit input.

## Architecture

**Resolution is a pre-routing filter, not a routing outcome.** The premise of routing is "this fact about the system needs a permanent home." A resolved fact has no current state to document, so the routing walk shouldn't see it.

`finalize-branch` Phase 1 Step 5 gains a resolution filter between smart-merge dedup and the per-callout routing walk. Two inputs feed the filter: explicit markers (heavy flow, written by `handle-callouts`) and heuristic detection (lightweight scan, run by `finalize-branch`).

```
Pattern matching
  → Smart-merge dedup
    → Resolution filter (NEW)
      → Per-callout routing walk (only on unresolved clusters)
```

## Scope and deliverables

| Skill | Change |
|---|---|
| `handle-callouts` | New "Mark resolved" subflow with explicit + proactive triggers. Read-only scan across branch handoffs as discovery aid. Always writes to the working handoff. |
| `finalize-branch` | New resolution filter sub-step in Phase 1 Step 5 (pre-routing). Heuristic diff-evidence scan for issue-shaped callouts. New tally clause in commit footer. Phase 1 Step 6 recommendation update. |
| `session-handoff` | No changes (handoff document mechanics unchanged). |

**Out of scope:**

- Changes to existing routing outcomes or smart-merge resolution categories.
- Cross-branch resolution (resolution scope is per-branch, matching the per-branch handoff model).
- Configurability of the heuristic threshold or marker syntax (hardcoded defaults; override file can grow keys later if needed).

## Resolution marker

### Format

A blockquote line in the callout body:

```markdown
### Known issue 3 — JWT clock skew tolerance varies by platform

> Resolved: switched to JWT v2 library; see commit abc123.

Tokens minted on macOS fail validation on Linux when …
```

- Top of body, after the heading.
- Optional payload after `Resolved` — freeform text, commit reference, or empty.
- Multiple markers in one body: last one wins (most recent edit). All are stripped during body normalization.

### Detection regex

Used by `handle-callouts` (existence check) and `finalize-branch` (filter):

```
^\s*>\s*Resolved\b\s*[:—\-]?\s*(.*?)\s*$
```

Captures an optional payload. A bare `> Resolved` matches with empty capture.

## Heavy flow (in `handle-callouts`)

A new "Mark resolved" subflow alongside the existing authoring flow.

### Triggers

Added to `## When to use`:

- **Explicit:** "mark X resolved", "this is fixed", "the JWT skew Known issue is gone now", "resolve callout 3", "<finding> is no longer applicable".
- **Proactive:** when the session's diff appears to address a callout the skill has seen in the working handoff or in the branch's older handoffs. Recognition during normal session flow, not a separate scan.

### Routing from `session-handoff`

`session-handoff`'s delegation criterion (per `2026-04-30-session-handoff-callout-delegation-design.md`) is "content matches any trigger in `handle-callouts`' `## When to use` section." Adding the Mark resolved triggers above to that section automatically extends `session-handoff`'s routing — when the user says "add this to the handoff: the JWT thing is fixed", `session-handoff` delegates to `handle-callouts`, which then routes through the Mark resolved subflow.

No edits to `session-handoff/SKILL.md` are required by this spec; the delegation criterion stays stable.

### Subflow steps

1. **Identify the target callout.**
   - Scan the working handoff first for a heading match against the user's reference (heading text or finding description).
   - If no match in the working handoff, run a read-only scan across the branch's older handoffs via `git log <base>..HEAD --name-only --pretty=format: -- docs/handoffs/`. Scope: read-only — never edits older handoffs.
   - Surface candidates: `Did you mean ### Known issue — JWT clock skew … (in <handoff path>)? confirm / that's a different one / cancel.`
   - If zero candidates, ask the user to name the heading or paste the body.

2. **Compose the marker.**
   - Default: pull resolution context from the user's framing or the most recent commit on the branch (proactive recognition case).
   - User can edit the proposed payload before write.
   - Bare `> Resolved` (no payload) is allowed.

3. **Confirm and write.**
   - Explicit user trigger with target clear → auto-write with one-line report.
   - Proactive recognition or any ambiguity → show the proposed marker + target heading; confirm before write.

4. **Apply the write.**
   - **Target in the working handoff:** insert `> Resolved: …` as the first body line under the existing callout heading. Refresh `**Last updated:**` timestamp.
   - **Target in an older handoff:** write a *resolution-only callout* to the working handoff — heading copied verbatim from the older callout, body containing only the marker. Smart-merge clusters them at branch end via heading match.

5. **Report.** One line — `Marked ### <heading> resolved in <handoff path>.`

### Dedup interaction

- Resolution-only callouts skip the authoring flow's dedup check. Smart-merge handles the cluster at branch end.
- Marking resolved a callout that already has a marker → prompt: `replace / keep existing / cancel`.

## Lightweight heuristic (in `finalize-branch` Phase 1 Step 5)

### Filter order

1. **Explicit markers first.** Any cluster whose newest member has a `> Resolved: …` marker → silently dropped from the walk; counted toward the resolved tally.
2. **Heuristic on remaining clusters.** For each unresolved cluster whose type is **issue-shaped** (Known issue, Caveat, Gotcha, Edge case) or **Complexity**, run the diff-evidence scan.

The heuristic does not run on Discovery / Decision / Lesson learned — these atemporal types have no clear diff signal for resolution. Explicit markers still work for them via the heavy flow.

### Diff-evidence scan

For each candidate cluster:

- Extract file paths and code symbols from the body. Path candidates: tokens matching path-shaped strings (`lib/...`, `test/...`, `src/...`, etc.). Symbol candidates: capitalized identifiers, dotted forms (`Auth.JWT.verify/2`), function-arity forms.
- Cross-reference against `git diff <base>..HEAD --name-only` and `git diff <base>..HEAD --stat`.
- Fire if a mentioned path or symbol is touched **and** the diff in that area exceeds the threshold: more than 10 lines changed (added + removed combined), or any new test files added under the path.

### Heuristic prompt

```
Possible resolution detected — Known issue 3 from <handoff path>

  ### Known issue — JWT clock skew tolerance varies by platform

  > Tokens minted on macOS fail validation on Linux when …

  Evidence: lib/auth/jwt.ex (+47/-12), test/auth/jwt_test.exs (new file, 38 lines).

  Mark resolved (y) / route normally (n) / show diff (d)
```

`y` → drop, count toward resolved. `n` → continue into the routing walk. `d` → dump the matched diff hunks, then re-prompt.

False-positive cost is one prompt; false negatives fall through to the routing walk where the user can `dismiss`.

## Smart-merge interaction

Two integration points with the existing smart-merge logic (`finalize-branch/SKILL.md:183-248`):

1. **Body normalization for body-substance match.** Strip `^\s*>\s*Resolved\b.*$` lines before comparing. The marker is metadata, not content; including it would distort the substance match.
2. **Cluster state determination.** After smart-merge produces a cluster, examine the **newest cluster member's** body for a resolution marker.
   - Newest has marker → cluster is resolved. Skip the smart-merge prompt; route directly into the resolution filter.
   - Newest is unmarked → cluster is active. Smart-merge proceeds normally.

### Reopen-after-resolution

When the newest cluster member is unmarked but at least one older member has a resolution marker, the smart-merge prompt surfaces the history:

```
Note: this callout was marked resolved in handoff <B> (> Resolved: switched to JWT v2 …)
but is active in handoff <C>. Treating as active.
```

The synthesis draft can fold the resolved-then-reopened arc into the body when relevant. User can `nuance` if the framing is off.

No new markup required for reopen — absence of a resolution marker on a newer cluster member implies reopened.

## Phase 1 Step 6 interaction

In-code reference cleanup recommendation update (`finalize-branch/SKILL.md:457-462`):

- New rule: "If the referenced callout was resolved in the resolution filter → recommend `remove` (the original concern is gone; the comment is now stale)."

This sits alongside today's rules (`redirect` when routed to repo docs, `inline` when near the routed symbol, etc.).

## Commit footer (Phase 4 Step 4)

Extend the existing `Callouts:` line in `finalize-branch/SKILL.md:633-643`:

```
Callouts: <X> to repo docs, <Y> to inline code docs, <Z> already captured, <W> dismissed, <V> resolved by this branch[, <M> smart-merged].
```

`resolved by this branch` distinguishes the new tally from `dismissed`. Each clause is omitted when its count is zero, matching today's behavior.

## Edge cases

- **Heuristic fires on a callout that already has a resolution marker.** Pre-filtered by step 1 of the resolution filter; heuristic doesn't re-evaluate.
- **Marker with no payload.** Treated as resolved; tally entry has no commit ref. Allowed.
- **Multiple resolution markers in one body.** Last one wins. All are stripped during body normalization.
- **Resolution marker on a callout type the heuristic narrows out** (Discovery, Decision, Lesson learned). Heavy flow allows it (any type accepts a marker); the explicit marker still drops the cluster.
- **Resolution-only callout in the working handoff with no cluster match across older handoffs.** Surfaced as a warning at the resolution filter step: `resolution-only callout <heading> in <working handoff> doesn't match any active callout in the branch — wasn't counted as resolved`. User can dismiss and proceed.
- **User marks resolved during a session, the marker lands in the working handoff, then a later session writes an active version.** Latest-wins per smart-merge — cluster is active. User can re-mark resolved if desired.
- **Heuristic threshold edge cases.** A 10-line refactor that just renames a symbol shouldn't fire but might. Mitigation: rely on Claude's judgment when reading the diff hunks for the prompt's "Evidence" line. Acceptable cost.
- **Branch with no diff.** Heuristic never fires; explicit markers still work.
- **Marker references a commit that's been rebased away.** Note becomes stale but the marker still works as a resolution signal.
- **User marks resolved, then reverses mid-session.** Edit the marker line out (or replace with active body if the resolution-only callout is the only record). Smart-merge will treat the cluster as active per latest-wins.
- **Cluster of only-resolution-only callouts.** Possible if the user marks resolved a finding that has no active counterpart in any handoff. Same warning as above; cluster doesn't count toward the resolved tally.

## Spec reference

- `handle-callouts/SKILL.md` — adds the "Mark resolved" subflow alongside the existing authoring flow.
- `finalize-branch/SKILL.md` — Phase 1 Step 5 gains the resolution filter sub-step; Phase 1 Step 6 recommendation table updated; Phase 4 commit-footer line extended.
- `2026-04-30-cross-skill-callout-dedup-alignment-design.md` — establishes the smart-merge model this work integrates with.
- `2026-04-30-handle-callouts-design.md` — original design rationale for the authoring flow this extends.
- `2026-04-30-finalize-branch-callout-handling-design.md` — original design rationale for Phase 1 Step 5 / 6.
