# Finalize Branch — Callout Handling

**Date:** 2026-04-30
**Status:** Approved — ready for implementation plan
**Plugin:** `local_conf`
**Skill touched:** `finalize-branch`
**Related spec:** `2026-04-30-finalize-branch-skill-design.md`

## Problem

Session handoff documents under `docs/handoffs/` often carry substantive findings — data-shape quirks discovered against real artifacts, contract requirements surfaced from external systems, route or schema reconciliations — that get propagated forward through later handoffs and baked into in-flight plan documents. Many projects already use a recurring callout pattern in handoffs to flag these, with headings like:

```markdown
### Discovery 1 — <title>
### Decision 3 — <title>
```

The current `finalize-branch` skill has no concept of these callouts. Its audit phase reads handoff narrative as a single source-of-truth picture; its inline-code-documentation and repo-documentation phases are seeded by the diff against the base branch. When the final phase deletes the branch's handoffs, any finding that didn't happen to land on a code symbol the diff scan caught — or in a doc the diff scan flagged — is lost. Git history preserves the handoff content, but the running record of how the system was reasoned into its current shape disappears from the active doc surface.

The gap is most visible for findings that describe **long-lived facts** with no single owning symbol: API contracts, data-shape conventions, cross-system invariants. These need a permanent home in repo docs, not a `@doc` attachment. Without explicit handling they slip through finalize-branch's diff-driven proposal generation entirely.

## Goal

Add a discrete extraction-and-routing step inside the audit phase of the `finalize-branch` skill that:

- Scans the branch's confirmed handoffs for matching callout headings (configurable patterns; sensible defaults).
- Dedupes callouts that recur across handoffs.
- For each unique callout, asks the user to route it: `already-captured`, `add-to-inline-code`, `add-to-repo-docs`, or `dismiss`.
- Each non-`dismiss`/non-`already-captured` choice creates a tracked proposal that flows into the existing inline-code or repo-documentation phases — same approval rhythm as ordinary proposals, just seeded from a callout instead of from a diff scan.
- Repo-doc routing prefers a single project-defined destination doc and a stable section heading inside it (convention scan with optional override).
- Phase 4 cannot delete a handoff that contains an unrouted callout; the user must resolve every callout before final commit.

The change is additive within the existing five-phase pipeline. It introduces no new phase. The audit phase grows one sub-step; the inline-code and repo-documentation phases gain a new proposal source; the final commit phase grows one summary line in its commit message footer.

## Non-Goals

- **Not a callout-aware doc surface beyond `finalize-branch`.** The skill doesn't migrate historical callouts from handoffs that aren't on the current branch, and doesn't run in any other context.
- **Not a project-wide reorganizer.** When multiple destination candidates exist, a merge proposal is offered, but only because this branch produced callouts that need routing. No proactive `docs/` cleanup.
- **Not a callout authoring helper.** Drafting handoffs is out of scope; this only handles callouts that already exist when finalize-branch runs.
- **Doesn't auto-route.** Every extracted callout requires an explicit user choice. Recommendations are best-effort and always overridable.
- **Doesn't preserve session-voice prose.** Callouts routed to repo docs are rewritten to atemporal voice using the skill's existing tone rules; the goal is a doc that reads like the rest of `docs/`, not a transcript of the branch's life.
- **Doesn't backlink to source handoffs.** Handoffs are deleted in the final phase, so any link to them would dangle in the merged tree. The git history is the audit trail.

## Activation

This change adds no new entry points. The new sub-step runs as part of the existing `finalize-branch` flow whenever at least one handoff in the branch's confirmed handoff list contains a matching callout heading. If nothing matches, the sub-step is silent and the skill behaves exactly as before.

## Design

### Where the change lands

The audit phase already (1) confirms the branch's handoff list, (2) builds a silent source-of-truth picture, (3) identifies divergences and ambiguities, and (4) walks an interactive question loop. The new behavior becomes:

> **Step 5 — Callout extraction & routing**
>
> Inserted between the existing question loop and the audit-phase close-out gate. Runs only if at least one handoff contains a matching callout heading.

Existing steps are not modified. The phase gate at the end becomes "Proceed to inline code documentation?" (descriptive name; see "Phase-naming sweep" below).

### Pattern matching

A callout is a Markdown heading at level `###` or deeper whose text matches:

```
^(<pattern>)(?:\s+\d+)?(?:\s*[—\-:]\s*.*)?$
```

…where `<pattern>` is one of the configured callout patterns. Default pattern set:

- `Discovery`
- `Decision`
- `Caveat`
- `Gotcha`
- `Lesson learned`

Matches require parsed Markdown headings, not raw text. A literal `### Discovery` line inside a fenced code block is ignored. Plain prose mentions ("see Discovery 4") are ignored — only headings count.

Pattern matching is case-insensitive on the pattern keyword. Numbering after the keyword is optional and not anchored to any sequence — `### Discovery — title`, `### Discovery 1 — title`, and `#### Decision: title` all match.

### Dedup

Callouts that recur across handoffs are deduped by canonical key: `(first handoff path, normalized heading text)`. Heading text is normalized by lowercasing, collapsing whitespace, and stripping leading numbering (`Discovery N —`). Later handoffs that reference the same heading text are treated as cross-references; only the first appearance becomes a routing item.

This means renumbering between handoffs is OK — the heading text is the anchor, not the number.

### Configuration

Two things need to be known per project: the callout patterns and the repo-docs destination (file path + section heading inside it). Both follow a "convention with override" model.

#### Convention scan (default; zero config)

When Step 5 runs, the skill computes the destination by scanning `docs/` (top level plus one subdirectory level deep) for filenames matching this case-insensitive set:

```
discoveries.md, decisions.md, findings.md, lessons.md,
caveats.md, gotchas.md, notes.md
```

- **Exactly one match** → that's the destination.
- **Zero matches** → the "propose creating one" flow runs (see "Bootstrap" below).
- **Multiple matches** → a merge offer runs (see "Multiple matches" below).

Once the file is identified, the skill scans for a top-level heading matching `## Discoveries`, `## Findings`, `## Decisions`, `## Notes`, `## Lessons learned`, or `## Caveats` (case-insensitive). First match wins. If none found, the skill creates a `## Discoveries` section at the end of the file as part of the routed proposal — the user reviews the diff in the repo-documentation phase before commit.

#### Override file

Used when the convention doesn't fit the project. Location: `.claude/finalize-branch.toml` or `.claude/finalize-branch.json` at repo root.

Minimal TOML shape:

```toml
[discoveries]
destination = "docs/conventions.md"
section = "## Discovery log"
patterns = ["Discovery", "Decision"]
```

JSON form:

```json
{
  "discoveries": {
    "destination": "docs/conventions.md",
    "section": "## Discovery log",
    "patterns": ["Discovery", "Decision"]
  }
}
```

Only `destination` is required in the override. `section` defaults to `## Discoveries` (created if missing). `patterns` defaults to the built-in set. Override file beats convention scan in all cases.

If the override's `destination` points to a file that doesn't exist, the skill halts with a recovery hint: "Override points to `<path>` which doesn't exist. Create the file or fix the override." No silent fallback to convention.

If the override file is present but unparseable, the skill halts at Step 5 entry with the parse error and a recovery hint.

#### Multiple matches

When the convention scan finds more than one candidate destination:

```
Multiple discovery destination candidates found:
  - docs/discoveries.md
  - docs/lessons.md

Options:
  1. Pick one as the destination (this branch only — leaves both files in place)
  2. Merge into one (queued as a Reorganize proposal in the repo-documentation phase:
     combined diff reviewed before commit; routed callouts land in the merge target)
  3. Halt — let me set an override

Choice? (1 / 2 / 3)
```

Option 2 aligns with the skill's existing **Reorganize** bucket, which is bounded to docs the branch's changes make relevant — the merge offer only appears because callouts need routing. Without callouts, duplicate destinations sit untouched.

#### Bootstrap (zero matches)

If the convention scan finds nothing and no override exists, the skill prompts:

```
No discoveries destination found. Propose creating `docs/discoveries.md`?
(`yes` / `nuance: <different path>` / `cancel`)
```

On `yes`, the new file is added to the repo-documentation phase as a **Create** proposal. Routed callouts populate it. This mirrors how that phase already handles `Create` proposals.

### Per-callout routing UX

After extraction and dedup, the skill prints a one-line tally and the resolved destination:

```
Found 6 unique callouts across 4 handoffs (after dedup).
Destination: docs/conventions.md → ## Discoveries
```

If a bootstrap (zero matches) flow ran, that prompt completes first so the user knows the destination is settled before answering routing questions.

Then per-callout walk, one at a time:

```
Callout 3 of 6 — from docs/handoffs/<filename>.md

  ### Discovery 4 — <heading text>

  [first 8-12 lines of body, with "…" if truncated]

  Recommendation: add-to-repo-docs
  Reasoning: <one-sentence rationale based on heuristics below>

  Choose:
    a — already-captured       (already in code or docs; nothing to do)
    c — add-to-inline-code     (becomes an @moduledoc/@doc/comment proposal)
    r — add-to-repo-docs       (added to docs/conventions.md → ## Discoveries)
    d — dismiss                (transient; no permanent home needed)
  Or: nuance: <free text> to push back on the recommendation
```

The destination path appears inline next to `add-to-repo-docs` so the user can see exactly where it'll land without scrolling.

#### Recommendation heuristics

Best-effort defaults; the user always has final say.

- `add-to-repo-docs` — when the callout describes an API/data contract, project-wide convention, or external-system fact. Default for most callouts.
- `add-to-inline-code` — when the callout is tightly bound to a specific function/module *the branch added or modified*. The skill cross-references `git diff <base>..HEAD` for symbol names that appear in the callout heading or body.
- `already-captured` — when the heading text appears (case-insensitive substring match) in any code comment or any `docs/` doc *outside* `docs/handoffs/` in the current tree. Flagged with: `(I see "<matching text>" already in <path>:<line>)`. The user still confirms — the skill never auto-skips.
- `dismiss` — for transient facts ("we tried X, it didn't work, we did Y") with no permanent home. Rare default; usually the user picks this manually.

#### Routing actions

- **`add-to-repo-docs`** — creates a tracked **Augment** proposal against the destination file and section, with rewritten atemporal content (see "Content transformation"). Reviewed in the repo-documentation phase via the existing `approve / nuance / skip` rhythm.
- **`add-to-inline-code`** — the skill picks a target symbol:
  1. If exactly one diff-symbol matches the callout, that's the recommendation.
  2. If zero match, the skill prompts for one (`module/function`) or back-out to the four-way choice.
  3. If multiple match, list with a recommendation.

  The selected symbol becomes a tracked **inline-code-doc proposal** that joins the inline-documentation phase's per-file walk. Tagged with its callout source so the user sees `[from callout: Discovery 4 in <handoff filename>]` as context. Same `approve / nuance / skip` rhythm as ordinary inline-doc proposals.
- **`already-captured`** — recorded in conversation state as "captured at `<path>:<line>`". No proposal created. Counted toward the commit footer's `N already captured` tally.
- **`dismiss`** — recorded in state, counted toward the commit footer's `N dismissed` tally.

`nuance: <text>` lets the user push back without picking a routing. The skill replies, possibly revises its recommendation, and re-prompts. Same rhythm as the existing per-proposal nuance loop.

#### Step 5 close-out

```
Audit step 5 complete:
  Added to inline code docs:  1 (Acme.Users @moduledoc)
  Added to repo docs:         3 (→ docs/conventions.md)
  Already captured:           1
  Dismissed:                  1

Proceed to inline code documentation?
```

### Content transformation for `add-to-repo-docs`

When a callout is routed to repo docs, the skill drafts a `### <title>` section to append under the destination's `##` heading. The rewrite applies the skill's existing §"Documentation language and tone" rules plus these callout-specific rules:

- **Strip temporal markers.** "During this session", "in the <date> handoff", "we discovered", "as we worked through", "after the Nth amendment". Replace with present-tense statements about the system.
- **Strip branch/PR/plan references.** "Task X in the active plan", "this branch", "the in-flight plan". The destination doc lives past all of those.
- **Keep code/data fences and tables verbatim.** A fence containing real artifacts (sample data, command snippets, route tables) is the part of a callout most often worth preserving as-is. The rewrite never paraphrases inside fences or table cells.
- **Promote the heading and strip session-relative numbering.** `### Discovery 4 — <title>` becomes `### <title>`. The destination doc doesn't care about session numbering.
- **No source-handoff backlink.** Handoffs are deleted in the final phase. Linking to them would dangle. Git history preserves the original.

#### Per-callout proposal display

Format presented in the repo-documentation phase walk:

```
Augment proposal — docs/conventions.md
  Source callout: Discovery 4 from <handoff filename>

  Insertion: append under `## Discoveries` (creating section if missing)

  ┌─ Proposed addition (rewritten) ─────────────────────────────────
  │ ### <rewritten title>
  │
  │ <rewritten atemporal body, 2-4 sentences>
  │
  │ ```<language>
  │ <preserved verbatim fence content>
  │ ```
  └─────────────────────────────────────────────────────────────────

  Approve (a) / nuance: <text> / skip (s)
```

The proposal flows through the existing per-document approval rhythm. Only the seed is new.

#### Section creation when missing

If the destination doc lacks the configured section heading, the first routed callout's proposal includes the section header plus the new entry as one diff. Subsequent callouts append under the now-existing heading.

#### Order of routed entries

Entries land in routing order, which equals the order Step 5 walked them, which equals chronological order across handoffs (oldest discovery first). This produces a chronological log feel without requiring date prefixes inside the doc.

### Final review and commit message updates

#### Final review summary

The final-phase pending-changes summary annotates callout-sourced proposals with a count:

```
Pending changes (not yet committed):
  Inline code docs: 14 changes across 6 files (1 from a callout)
  Repo docs:
    Updated:    docs/architecture.md, README.md
    Augmented:  docs/conventions.md (3 from callouts)
    ...
```

Just a count, not a separate section. The proposals themselves are already individually approved.

#### Commit message footer

The existing template gets one new line when callouts were processed:

```
docs: finalize <branch-name>

Inline code docs:
  - <terse summary>

Repo docs:
  - <terse summary>

Removed <N> session handoff document(s).
Callouts: <X> to repo docs, <Y> to inline code docs, <Z> already captured, <W> dismissed.
[optional: "(branch health checks skipped)"]
```

The callouts line is omitted entirely if zero callouts were extracted.

### Failure-mode safety

Step 5's close-out gate enforces the contract: every extracted callout has an explicit routing decision (`already-captured`, `add-to-inline-code`, `add-to-repo-docs`, or `dismiss`) before the audit phase exits. Once a routing decision is made, the callout is considered handled — even if the user later skips the resulting proposal during the inline-code or repo-documentation phase. A skip there reduces that phase's "(N from a callout)" count in the final-review summary, and the source handoff is still safe to delete in the final phase.

The final phase carries a defensive halt as a safety net: if conversation state ever reaches the deletion step with a callout that has no recorded routing decision, halt with "Handoff `<path>` has unrouted callout `<heading>`. Re-run and resolve at audit step 5." Under normal flow this halt is unreachable; it exists so that future changes to the audit phase can't silently drop callouts.

### Phase-naming sweep

Cross-cutting rename applied throughout the skill so user-facing prompts no longer reference phase numbers. Internal section headers (`## Phase 0 — ...`) keep their numbering for skill-author orientation. The user-facing rename:

- "Phase 1" → "audit"
- "Phase 2" → "inline code documentation"
- "Phase 3" → "repo documentation"
- "Phase 4" → "handoff cleanup & final commit" (or "final review" where shorter is appropriate)

Specific touchpoints:

- All gate prompts ("Proceed to phase N?") reworded to use the descriptive name.
- The cancellation retention prompt's "cancelled in phase 0 or phase 1, before any edits were made" reworded to "cancelled before any edits were made".
- The final-phase pending-changes summary uses descriptive phase names in its section labels.
- Edge-case error messages use descriptive names.
- Pre-commit hook failure messages use descriptive names.

## Edge cases

- **Callout heading with no body** (just the heading, nothing under it before the next heading) — present in routing as `(empty body)`; recommendation defaults to `dismiss`. Body-less callouts usually mean the discovery was captured by the heading text alone.
- **Pattern match inside a fenced code block** — ignored. Pattern matching happens on parsed Markdown headings, not raw text.
- **Override file present but unparseable** — halt at Step 5 entry with the parse error.
- **Override `destination` points to a missing file** — halt with the recovery hint above.
- **Same heading text appears as both a callout and an existing heading inside the destination doc** — flagged as `already-captured` candidate with the existing heading's location. User confirms or overrides.
- **Zero handoffs on the branch** — Step 5 doesn't run (no callouts to find).
- **Handoffs but zero matching callouts** — Step 5 is silent; flow is unchanged.
- **All callouts dismissed or already-captured** — no new proposals; final commit footer's callouts line still records the tallies.
- **User cancels mid-routing** — same cancellation retention behavior as elsewhere in the skill. No applied edits exist yet at this point in the flow, so the prompt is the short "no edits to retain" exit.

## Tool usage

This change introduces no new tool requirements. The skill continues to use Serena's symbolic tools for code reads/edits, `Read`/`Edit` for non-code, and `Bash` for git operations.

For pattern matching on Markdown headings, the implementation should read each handoff with `Read` and parse heading lines with a regex — not Serena (handoffs are non-code) and not `Grep` (the regex needs to inspect document structure, not just match strings).

## Testing

Manual interactive testing on a real branch is the primary validation path, consistent with the rest of the `finalize-branch` skill. Recommended cases to walk through before declaring done:

- A branch with handoffs containing callouts where the destination is set by convention scan (one match).
- A branch with handoffs containing callouts where the destination is set by an override file.
- A branch where the convention scan matches multiple files (verify the merge-offer flow).
- A branch where the convention scan matches nothing (verify the bootstrap flow).
- A branch where every callout routes to `dismiss` or `already-captured` (verify no proposals generated, footer line still appears).
- A branch with zero callouts (verify Step 5 is silent and the existing flow is unchanged).
- A callout whose heading text matches existing repo doc content (verify the `already-captured` recommendation surfaces with a path/line reference).
- A callout the diff scan can attach to a single symbol (verify `add-to-inline-code` recommendation).
- A callout that recurs across multiple handoffs (verify dedup).

## Open questions

None at this time.
