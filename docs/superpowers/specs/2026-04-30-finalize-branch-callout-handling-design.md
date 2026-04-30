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
- Scans existing source-file comments and docstrings for references to handoff paths or callout identifiers, and resolves each one before the source handoff is deleted: either inline the relevant content into the comment, redirect the reference to the destination doc + section, or remove it.
- Phase 4 cannot delete a handoff that is still referenced from code, and cannot delete a handoff that contains an unrouted callout; the user must resolve every callout and every in-code reference before final commit.

The change is additive within the existing five-phase pipeline. It introduces no new phase. The audit phase grows two sub-steps (callout extraction & routing, then in-code reference cleanup); the inline-code and repo-documentation phases gain new proposal sources; the final commit phase grows one summary line in its commit message footer.

## Non-Goals

- **Not a callout-aware doc surface beyond `finalize-branch`.** The skill doesn't migrate historical callouts from handoffs that aren't on the current branch, and doesn't run in any other context.
- **Not a project-wide reorganizer.** When multiple destination candidates exist, a merge proposal is offered, but only because this branch produced callouts that need routing. No proactive `docs/` cleanup.
- **Not a callout authoring helper.** Drafting handoffs is out of scope; this only handles callouts that already exist when finalize-branch runs.
- **Doesn't auto-route.** Every extracted callout requires an explicit user choice. Recommendations are best-effort and always overridable.
- **Doesn't preserve session-voice prose.** Callouts routed to repo docs are rewritten to atemporal voice using the skill's existing tone rules; the goal is a doc that reads like the rest of `docs/`, not a transcript of the branch's life.
- **Doesn't backlink to source handoffs.** Handoffs are deleted in the final phase, so any link to them would dangle in the merged tree. The git history is the audit trail.
- **Not a project-wide doc-comment refactor.** The in-code reference scan only acts on references that point to handoffs in the deletion list or to callout identifiers extracted in Step 5. It doesn't restructure unrelated comments, fix unrelated stale doc references, or rewrite docstrings the branch's changes don't touch.

## Activation

This change adds no new entry points. The new sub-step runs as part of the existing `finalize-branch` flow whenever at least one handoff in the branch's confirmed handoff list contains a matching callout heading. If nothing matches, the sub-step is silent and the skill behaves exactly as before.

## Design

### Where the change lands

The audit phase already (1) confirms the branch's handoff list, (2) builds a silent source-of-truth picture, (3) identifies divergences and ambiguities, and (4) walks an interactive question loop. The new behavior becomes two new sub-steps:

> **Step 5 — Callout extraction & routing**
>
> Inserted between the existing question loop and the audit-phase close-out gate. Runs only if at least one handoff contains a matching callout heading.

> **Step 6 — In-code reference cleanup**
>
> Runs immediately after Step 5. Scans source-file comments and docstrings for references to (a) handoff paths in the deletion list and (b) callout identifiers extracted in Step 5. Each match becomes a tracked proposal for the inline-code-documentation phase. Runs whenever the deletion list is non-empty or Step 5 found callouts; otherwise silent.

Existing steps are not modified. The phase gate at the end becomes "Proceed to inline code documentation?" (descriptive name; see "Phase-naming sweep" below).

### Pattern matching

A callout is a Markdown heading at level `###` or deeper whose text matches:

```
^(<pattern>)(?:\s+\d+)?(?:\s*[—\-:]\s*.*)?$
```

…where `<pattern>` is one of the configured callout patterns. Each pattern is a literal heading-prefix string; singular and plural forms are listed as separate entries so that handoffs using either form match. Default pattern set:

- `Discovery` / `Discoveries`
- `Decision` / `Decisions`
- `Caveat` / `Caveats`
- `Gotcha` / `Gotchas`
- `Lesson learned` / `Lessons learned`
- `Known issue` / `Known issues`
- `Complexity` / `Complexities`
- `Edge case` / `Edge cases`

The slash form is shorthand — each line above expands to two entries in the matcher's literal-pattern list (e.g., `Discovery` and `Discoveries` are both matched independently).

Matches require parsed Markdown headings, not raw text. A literal `### Discovery` line inside a fenced code block is ignored. Plain prose mentions ("see Discovery 4") are ignored — only headings count.

Pattern matching is case-insensitive on the pattern keyword. Numbering after the keyword is optional and not anchored to any sequence — `### Discovery — title`, `### Discovery 1 — title`, `#### Decision: title`, and `### Edge cases — empty input` all match. A heading like `### Known issues` with no trailing dash, colon, or content is also a valid match (the body of the section is the callout content).

Multi-word patterns (`Lesson learned`, `Known issue`, `Edge case`) match literally as space-separated tokens at the heading-text start; the matcher does not collapse internal whitespace.

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

Only `destination` is required in the override. `section` defaults to `## Discoveries` (created if missing). `patterns` defaults to the built-in set; when overriding `patterns`, list each form the project uses literally — singular and plural variants must each be specified (e.g., `["Discovery", "Discoveries"]`) since no auto-pluralization is applied to override values. Override file beats convention scan in all cases.

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
```

Step 5 doesn't gate on the user — it transitions straight into Step 6 (in-code reference cleanup) when there's anything to scan, or skips ahead to the audit-phase close-out gate when there isn't. The user-facing "Proceed to inline code documentation?" prompt is owned by whichever step exits the audit phase last.

### In-code reference cleanup (audit step 6)

After Step 5 settles routing decisions and (if applicable) the destination doc, Step 6 scans source files for comments and docstrings that reference handoffs or callouts and proposes a resolution for each. The goal is to leave no comment in the merged tree that points to a deleted handoff or to a callout identifier that no longer has a definition.

#### Scope of the scan

Source files only. The scan walks every file the project's language conventions treat as a source file (matched by extension: `.ex`/`.exs` for Elixir, `.js`/`.jsx`/`.ts`/`.tsx` for JS/TS, `.py` for Python, `.rs` for Rust, etc.). Generated files, lockfiles, fixtures, and binary files are skipped using the same exclusion list the inline-code-documentation phase already uses.

The scan covers the **whole repo**, not just files in the branch's diff. A pre-existing comment that happens to reference one of this branch's handoffs is rare in practice — references are usually added at the same time as the handoff — but the cost of a full-repo regex scan is low and the cost of a missed dangling reference is high.

Detection is text-level (read each file with `Read`, match a small set of regexes). Symbol-level navigation isn't useful here; we're looking inside comment bodies, not at code structure.

#### What counts as a reference

Two pattern families:

- **Handoff path references** — a literal substring matching `docs/handoffs/<filename>` (or, if the project's handoffs live elsewhere, the equivalent path discovered from the deletion list). Matches are scoped to comments and docstrings — references inside string literals or code that genuinely uses the path (e.g., a script that opens the file) are flagged but routed to the user with a "is this a real code dependency? skip if so" prompt.
- **Callout-identifier references** — a sequence matching `(<pattern>) ?\d+` (e.g., `Discovery 4`, `Decision 12`) inside comments and docstrings, where `<pattern>` is one of the configured callout patterns. The match is only meaningful if Step 5 extracted a callout with the same identifier; references to identifiers that don't exist in any handoff are noted but typically dismissed.

The scanner reports each match with file path, line number, and the surrounding 1–3 lines of comment context.

#### Resolution choices per reference

Each match becomes a tracked **inline-code-doc proposal** that the user resolves during the inline-code-documentation phase walk. Per-reference choices:

- **`inline`** — extract the relevant content and rewrite the comment so the fact is present in the code itself. Best for short, terse references where the original handoff text is a sentence or two. The skill drafts the inlined replacement using the same atemporal-rewrite rules as `add-to-repo-docs` (no session-voice, no branch references) and presents the diff for `approve / nuance / skip`.
- **`redirect`** — replace the reference with a pointer to the destination doc + section. Format: `# see <destination-path> "<section>" — <topic title>` (or the language's idiomatic comment style). Available only when the referenced callout was routed to `add-to-repo-docs` in Step 5; the skill knows the destination path and the rewritten title from that routing decision.
- **`remove`** — delete the reference. Use when the comment carried the reference as supporting context but the surrounding text is self-contained without it.
- **`skip`** — leave the reference as-is. Use sparingly; the skill warns at the close of Step 6 that any skipped reference will dangle once handoffs are deleted, and asks for explicit confirmation.

The skill recommends a default per match:

- If the referenced callout was routed to `add-to-repo-docs` in Step 5 → recommend `redirect` (preserves the link, fixes the dangling path).
- If the referenced callout was routed to `add-to-inline-code` and the matched comment is on or near that symbol → recommend `inline` (the routed proposal will already cover the same ground; the existing reference can be folded in or removed).
- If the referenced callout was `dismissed` or `already-captured` → recommend `remove` (the original reference is now noise).
- If the reference is to a path/identifier with no Step 5 match (and the path isn't in the deletion list) → recommend `skip` (nothing to clean up).

#### Per-reference proposal display

```
In-code reference — lib/<path>.ex:42

  Source comment context:
    │ # See docs/handoffs/<filename>.md for the rationale —
    │ # specifically Discovery 4.
    │ defp build_request(...) do

  Proposed resolution: redirect
  Reason: Discovery 4 was routed to docs/conventions.md → ## Discoveries.

  ┌─ Proposed comment ──────────────────────────────────────────────
  │ # See docs/conventions.md "## Discoveries" —
  │ # <rewritten callout title>.
  └─────────────────────────────────────────────────────────────────

  Approve (a) / change resolution (i / r / x / s) / nuance: <text>
```

Resolution-change shortcuts: `i`=inline, `r`=redirect, `x`=remove, `s`=skip. On a change, the skill re-drafts the proposed comment for the new resolution and re-prompts.

#### Step 6 close-out

```
Audit step 6 complete:
  References resolved by inlining:    2
  References resolved by redirect:    4
  References removed:                 1
  References skipped (will dangle):   0

Proceed to inline code documentation?
```

If any references were skipped, the close-out adds: "Note: <N> reference(s) will dangle in the merged tree. Re-run if you want to revisit this."

#### Interaction with handoff deletion

The final phase's deletion gate (already covered in "Failure-mode safety") is extended: a handoff cannot be deleted if any source file still contains a reference to its path that wasn't resolved as `inline`, `redirect`, or `remove`. A `skip` decision is recorded as an explicit user choice to leave the dangle, and does not block deletion — the close-out warning is the only signal.

The defensive halt on the deletion path checks for both unrouted callouts (Step 5 contract) and unresolved references (Step 6 contract); under normal flow neither check fires.

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

The final-phase pending-changes summary annotates callout-sourced and reference-cleanup proposals with counts:

```
Pending changes (not yet committed):
  Inline code docs: 14 changes across 6 files
                    (1 from a callout, 7 from in-code reference cleanup)
  Repo docs:
    Updated:    docs/architecture.md, README.md
    Augmented:  docs/conventions.md (3 from callouts)
    ...
```

Just counts, not separate sections. The proposals themselves are already individually approved.

#### Commit message footer

The existing template gets up to two new lines: one when callouts were processed, one when in-code references were resolved:

```
docs: finalize <branch-name>

Inline code docs:
  - <terse summary>

Repo docs:
  - <terse summary>

Removed <N> session handoff document(s).
Callouts: <X> to repo docs, <Y> to inline code docs, <Z> already captured, <W> dismissed.
In-code references: <I> inlined, <R> redirected, <X> removed, <S> skipped.
[optional: "(branch health checks skipped)"]
```

Either line is omitted entirely if its corresponding step had nothing to report (no extracted callouts; no detected references).

### Failure-mode safety

Step 5's close-out gate enforces the callout contract: every extracted callout has an explicit routing decision (`already-captured`, `add-to-inline-code`, `add-to-repo-docs`, or `dismiss`) before the audit phase exits. Step 6's close-out gate enforces the reference-cleanup contract: every detected in-code reference has an explicit resolution (`inline`, `redirect`, `remove`, or `skip`) before the audit phase exits. Once a routing decision or resolution is made, the item is considered handled — even if the user later skips the resulting proposal during the inline-code or repo-documentation phase. A skip there reduces that phase's "(N from …)" count in the final-review summary, and the source handoff is still safe to delete.

The final phase carries defensive halts as safety nets: if conversation state ever reaches the deletion step with (a) a callout that has no recorded routing decision or (b) a handoff path still referenced from code without an explicit `skip` decision, halt with the relevant recovery hint ("Re-run and resolve at audit step 5" or "Re-run and resolve at audit step 6"). Under normal flow these halts are unreachable; they exist so that future changes to the audit phase can't silently drop callouts or references.

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
- **Zero handoffs on the branch** — Step 5 and Step 6 don't run (no callouts to find; no deletion list).
- **Handoffs but zero matching callouts and zero in-code references** — Step 5 and Step 6 are silent; flow is unchanged.
- **All callouts dismissed or already-captured** — no new proposals from Step 5; final commit footer's callouts line still records the tallies.
- **User cancels mid-routing or mid-cleanup** — same cancellation retention behavior as elsewhere in the skill. No applied edits exist yet at this point in the flow, so the prompt is the short "no edits to retain" exit.
- **In-code reference to a handoff that's NOT in the deletion list** (e.g., a comment pointing to a handoff from a previous branch that was kept) — surfaced in Step 6 with recommendation `skip` and an explanatory note. The reference doesn't dangle, so cleanup is optional.
- **Callout-identifier reference (`Discovery 4`) where Step 5 didn't extract a matching callout** — surfaced with recommendation `skip` and a "no matching callout in this branch's handoffs" note. The user may still choose `inline` or `remove` if they recognize the reference is now stale.
- **Source-file reference to a handoff path inside a string literal or path argument** (not a comment/docstring) — surfaced with a "appears to be a real code dependency, not a comment" warning; recommendation defaults to `skip`. The user can still choose other resolutions if they know the code path is dead.

## Tool usage

This change introduces no new tool requirements. The skill continues to use Serena's symbolic tools for code reads/edits, `Read`/`Edit` for non-code, and `Bash` for git operations.

For pattern matching on Markdown headings (Step 5), the implementation should read each handoff with `Read` and parse heading lines with a regex — not Serena (handoffs are non-code) and not `Grep` (the regex needs to inspect document structure, not just match strings).

For the source-file reference scan (Step 6), `Grep` is appropriate: the matches are text-level (substrings inside comments and docstrings), and the regex can express the handoff-path and callout-identifier patterns directly. `Read` is used afterward to capture the surrounding 1–3 lines of context for the per-reference proposal display, and Serena's `replace_symbol_body` (or `Edit` when the comment isn't symbol-attached) applies the approved edit during the inline-code-documentation phase.

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
- A branch where source-file comments reference a deleted handoff path (verify Step 6 detects them and recommends `redirect` when the relevant callout was routed to repo docs).
- A branch where source-file comments reference a callout identifier (`Discovery 4`) without naming the handoff path (verify Step 6 detects the identifier and links the resolution to Step 5's routing).
- A branch with zero in-code references (verify Step 6 is silent).
- A reference inside a string literal that looks like a handoff path (verify the "real code dependency" warning fires and the default is `skip`).
- A user `skip` on an in-code reference to a handoff that IS in the deletion list (verify the close-out warning, verify final commit succeeds with the dangle as an explicit user choice).

## Open questions

None at this time.
