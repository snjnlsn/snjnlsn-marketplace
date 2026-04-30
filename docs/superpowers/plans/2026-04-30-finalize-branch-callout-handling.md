# Finalize-branch callout handling — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add callout-extraction-and-routing (Step 5) and in-code reference cleanup (Step 6) to the audit phase of the `finalize-branch` skill, plus the supporting changes in later phases (proposal-source tagging, final-review annotations, commit footer lines, defensive halts), and apply the cross-cutting phase-naming sweep that drops user-facing "Phase N" wording.

**Architecture:** All edits land in two files: `plugins/local_conf/skills/finalize-branch/SKILL.md` (almost all changes) and `plugins/local_conf/.claude-plugin/plugin.json` (version bump). The change is additive — no phases are added or removed; internal `## Phase N` headers keep their numbering for skill-author orientation; only user-facing prompts adopt descriptive names. No executable code, no new MCP tools, no schema changes.

**Tech Stack:** Markdown only. Edits applied via `Edit` (anchor-based string replacement) and `Read` for verification. No tests run; verification is by reading the file back and cross-checking against the spec.

**Spec:** `docs/superpowers/specs/2026-04-30-finalize-branch-callout-handling-design.md`

---

## File Structure

Files modified:

- `plugins/local_conf/skills/finalize-branch/SKILL.md` — the bulk of the work:
  - User-facing "Phase N" references reworded to descriptive names (multiple inline edits across the file).
  - `## Phase 1 — Audit & clarifying questions` gains two new step sections after existing Step 4: **Step 5 — Callout extraction & routing** and **Step 6 — In-code reference cleanup**. Existing Step 4's close-out prompt becomes conditional on whether 5/6 will run.
  - `## Phase 2 — Inline code documentation` gets one short paragraph noting callout-sourced and reference-cleanup proposal sources.
  - `## Phase 3 — Architecture, ...` gets one short paragraph noting callout-sourced Augment proposals.
  - `## Phase 4 — Handoff cleanup & final commit`:
    - Step 1 (Final review) summary annotated with `(N from a callout, M from in-code reference cleanup)` tallies; defensive halts described.
    - Step 4 (Commit message) template gains the two footer lines.
  - `## Edge cases` gains new entries.
  - `## Tool usage` gains one paragraph on the pattern-matching/scanning approach for Steps 5 and 6.
- `plugins/local_conf/.claude-plugin/plugin.json` — version bump `1.3.0` → `1.4.0` (additive feature).

Files created: none.
Files deleted: none.

The marketplace root README and the `local_conf/README.md` are out of scope — they don't enumerate phase steps.

## Verification approach

No test suite. Each edit is verified by:

1. Re-reading the surrounding region with the `Read` tool.
2. Confirming the inserted/changed text matches the task's intended content.
3. Confirming the surrounding anchors (preceding/following lines) are unchanged.

The final task does a holistic read-through of the file end-to-end against the spec.

Conventions used in every task below:

- "Anchor-confirm" means: `Read` the affected region first, eyeball it against the `old_string`, abort if it doesn't match. This protects against drift if earlier tasks were applied differently than expected.
- "Verify" after an `Edit` means: `Read` the same region back and confirm the new text is present.
- All edits use the `Edit` tool with `old_string`/`new_string`. Use `replace_all=true` only when explicitly noted; default is single-occurrence replacement.

---

### Task 1: Apply the phase-naming sweep (user-facing prompts only)

This task is a series of small string replacements. Each one targets a single user-facing prompt; internal `## Phase N — ...` headers are untouched. Apply them in file order so anchors don't conflict.

**Files:**
- Modify: `plugins/local_conf/skills/finalize-branch/SKILL.md` (multiple call-sites)

- [ ] **Step 1: Anchor-confirm by reading the file structure**

Run (via the `Read` tool):

```
Read plugins/local_conf/skills/finalize-branch/SKILL.md
```

Confirm the file currently contains the `## Phase 0`, `## Phase 1`, `## Phase 2`, `## Phase 3`, `## Phase 4` top-level section headers. If any are missing or renamed, stop and re-derive anchors before proceeding.

- [ ] **Step 2: Reword the Phase 1 Step 4 gate prompt**

`Edit` `plugins/local_conf/skills/finalize-branch/SKILL.md`:

`old_string`:

```
Anything unaddressed in a chunk defaults to `accept`. The user may add free-form clarifications between chunks. After all chunks are processed, summarize the resolved picture and ask: "Proceed to phase 2?".
```

`new_string`:

```
Anything unaddressed in a chunk defaults to `accept`. The user may add free-form clarifications between chunks. After all chunks are processed, summarize the resolved picture. If Steps 5 and 6 will both be silent (no matching callouts and no deletion list), Step 4 prompts: "Proceed to inline code documentation?" Otherwise, Step 4 hands off silently and the gate prompt is owned by whichever of Step 5 or Step 6 runs last.
```

- [ ] **Step 3: Reword Phase 2 Step 5 close-out**

`Edit`:

`old_string`:

```
After all files walked: "Phase 2 complete: applied N doc changes across M files, skipped K files. Proceed to phase 3?"
```

`new_string`:

```
After all files walked: "Inline code documentation complete: applied N doc changes across M files, skipped K files. Proceed to repo documentation?"
```

- [ ] **Step 4: Reword Phase 3 Step 3 close-out**

`Edit`:

`old_string`:

```
Approved changes applied immediately. Phase summary: "Updated N docs, augmented M, created K, reorganized L. Skipped P. Proceed to phase 4?"
```

`new_string`:

```
Approved changes applied immediately. Phase summary: "Updated N docs, augmented M, created K, reorganized L. Skipped P. Proceed to handoff cleanup & final commit?"
```

- [ ] **Step 5: Reword the Phase 4 final-review summary section labels**

`Edit`:

`old_string`:

```
Pending changes (not yet committed):
  Phase 2 — Inline code docs: 14 changes across 6 files
  Phase 3 — Architecture/docs:
    Updated:    docs/architecture.md, README.md
    Augmented:  docs/business-logic/users.md
    Created:    docs/architecture/auth-oauth.md
    Reorganized: merged docs/migration.md + docs/post-migration.md

About to delete (phase 4):
```

`new_string`:

```
Pending changes (not yet committed):
  Inline code docs: 14 changes across 6 files
  Repo docs:
    Updated:    docs/architecture.md, README.md
    Augmented:  docs/business-logic/users.md
    Created:    docs/architecture/auth-oauth.md
    Reorganized: merged docs/migration.md + docs/post-migration.md

About to delete:
```

(Note: Task 8 will revisit this same example to add the `(N from a callout, M from in-code reference cleanup)` annotations. Keep it minimal here — strip the `Phase N — ` prefixes only.)

- [ ] **Step 6: Reword the Phase 4 commit message section labels**

`Edit`:

`old_string`:

```
Phase 2 (code docs):
  - <terse summary, one bullet per file or grouped by module>

Phase 3 (project docs):
  - <terse summary>

Removed <N> session handoff document(s).
```

`new_string`:

```
Inline code docs:
  - <terse summary, one bullet per file or grouped by module>

Repo docs:
  - <terse summary>

Removed <N> session handoff document(s).
```

(Task 9 will add the two new footer lines below `Removed ... session handoff document(s).`.)

- [ ] **Step 7: Reword the cancellation-retention "phase 0 or phase 1" sentence**

`Edit`:

`old_string`:

```
If there are zero applied edits at cancellation time (cancelled in phase 0 or phase 1, before any edits were made), skip this prompt — exit with a one-line confirmation.
```

`new_string`:

```
If there are zero applied edits at cancellation time (cancelled before any edits were made), skip this prompt — exit with a one-line confirmation.
```

- [ ] **Step 8: Reword the cancellation-retention stash recipe's reference to phase 0**

`Edit`:

`old_string`:

```
- **1 (stash)** — `git stash push -m "finalize-branch:<branch-name>:<ISO-timestamp>" -- <list of touched paths>`. Confirm: "Stashed N file(s) as `<stash-ref>`. Re-run `/finalize-branch` when ready — phase 0 will detect and offer to apply."
```

`new_string`:

```
- **1 (stash)** — `git stash push -m "finalize-branch:<branch-name>:<ISO-timestamp>" -- <list of touched paths>`. Confirm: "Stashed N file(s) as `<stash-ref>`. Re-run `/finalize-branch` when ready — resume detection at the start of the next run will detect and offer to apply."
```

- [ ] **Step 9: Reword the stash-resume narrative reference to "phase 0"**

`Edit`:

`old_string`:

```
>   1. **Stash for resume (recommended)** — saves the edits as a named stash. On the next `/finalize-branch`, phase 0 will offer to apply them automatically.
```

`new_string`:

```
>   1. **Stash for resume (recommended)** — saves the edits as a named stash. On the next `/finalize-branch`, resume detection will offer to apply them automatically.
```

- [ ] **Step 10: Reword edge-case entries that name "phase N"**

`Edit`:

`old_string`:

```
- **Empty branch** (zero commits ahead of base) — refuse at phase 0.
- **Zero handoffs on the branch** — phase 1 reports and proceeds; context comes from commits/diffs only.
- **Zero proposals after phases 2 + 3, plus zero handoffs** — exit with "Nothing to finalize" — no empty commit.
```

`new_string`:

```
- **Empty branch** (zero commits ahead of base) — refuse at the pre-flight gate.
- **Zero handoffs on the branch** — the audit phase reports and proceeds; context comes from commits/diffs only.
- **Zero proposals after the inline-code and repo-doc phases, plus zero handoffs** — exit with "Nothing to finalize" — no empty commit.
```

`Edit`:

`old_string`:

```
- **Working tree changes outside the skill mid-flow** — detected at phase 4 staging — pause with: "Detected files in `git status` not produced by this skill: `<list>`. Stage/commit them separately or discard, then continue (`yes` / `cancel`)."
- **Pre-commit hook failure on final commit** — covered in phase 4 step 5; halts with hook output and runs the cancellation retention prompt.
- **Cancellation at any approval gate** — covered in "Cancellation retention"; if zero edits applied, exits with a one-line confirmation instead.
- **Worktrees** — work without modification; operate on `cwd`.
- **Binary files in diff** — silently skip in phase 2 candidate building.
```

`new_string`:

```
- **Working tree changes outside the skill mid-flow** — detected at handoff-cleanup staging — pause with: "Detected files in `git status` not produced by this skill: `<list>`. Stage/commit them separately or discard, then continue (`yes` / `cancel`)."
- **Pre-commit hook failure on final commit** — covered in the handoff-cleanup phase; halts with hook output and runs the cancellation retention prompt.
- **Cancellation at any approval gate** — covered in "Cancellation retention"; if zero edits applied, exits with a one-line confirmation instead.
- **Worktrees** — work without modification; operate on `cwd`.
- **Binary files in diff** — silently skip in inline-code-documentation candidate building.
```

- [ ] **Step 11: Reword the introductory paragraph and prose references to "phase N"**

`Edit` (top of file overview):

`old_string`:

```
The skill is interactive throughout. Each phase has an explicit user approval gate. Phase N+1 cannot begin until phase N is fully approved. State carried between phases lives only in conversation context — cancellation means start over (with optional stash-based resume of applied edits).
```

`new_string`:

```
The skill is interactive throughout. Each phase has an explicit user approval gate. A later phase cannot begin until the previous phase is fully approved. State carried between phases lives only in conversation context — cancellation means start over (with optional stash-based resume of applied edits).
```

`Edit` (in §Documentation language and tone):

`old_string`:

```
Phases 2 and 3 produce written content. Apply these rules to every proposed `@moduledoc`/`@doc`/docstring/JSDoc and every prose edit to `docs/`/`README.md`/`CLAUDE.md`.
```

`new_string`:

```
The inline-code-documentation and repo-documentation phases produce written content. Apply these rules to every proposed `@moduledoc`/`@doc`/docstring/JSDoc and every prose edit to `docs/`/`README.md`/`CLAUDE.md`.
```

`Edit` (in §Phase 2 Step 1):

`old_string`:

```
- Existing `@moduledoc` / `@doc` stale relative to phase 1's resolved picture
```

`new_string`:

```
- Existing `@moduledoc` / `@doc` stale relative to the audit phase's resolved picture
```

`Edit` (in §Phase 2 Step 4):

`old_string`:

```
Apply approved proposals immediately to the working tree. **Prefer Serena's symbolic edits** (`replace_symbol_body`, `insert_before_symbol`, `insert_after_symbol`). Use direct `Edit` only for non-symbol-level cases. Don't stage yet — staging happens in phase 4.
```

`new_string`:

```
Apply approved proposals immediately to the working tree. **Prefer Serena's symbolic edits** (`replace_symbol_body`, `insert_before_symbol`, `insert_after_symbol`). Use direct `Edit` only for non-symbol-level cases. Don't stage yet — staging happens in the handoff-cleanup phase.
```

`Edit` (in §Phase 3 working surface):

`old_string`:

```
- `CLAUDE.md` (root, plus any nested `CLAUDE.md` surfaced by phase 1)
```

`new_string`:

```
- `CLAUDE.md` (root, plus any nested `CLAUDE.md` surfaced by the audit phase)
```

`Edit` (in §Phase 3 Step 1, two occurrences — confirm there are exactly two before proceeding; if there are more or fewer, stop and re-derive):

`old_string`:

```
- **`CLAUDE.md`** — conservative; propose additions only when a phase-1 fact would actively mislead future Claude sessions if absent (new convention introduced, previously-documented convention removed, project standard commands changed). Phase 3 close-out includes a one-liner suggestion: "consider running `claude-md-improver` separately for broader auditing."
```

`new_string`:

```
- **`CLAUDE.md`** — conservative; propose additions only when an audit-phase fact would actively mislead future Claude sessions if absent (new convention introduced, previously-documented convention removed, project standard commands changed). Repo-documentation close-out includes a one-liner suggestion: "consider running `claude-md-improver` separately for broader auditing."
```

`Edit`:

`old_string`:

```
Stale-but-unrelated docs flagged in phase 1 land in **update**, with the original phase-1 question carried forward as context.
```

`new_string`:

```
Stale-but-unrelated docs flagged in the audit phase land in **update**, with the original audit-phase question carried forward as context.
```

`Edit` (Phase 3 Step 2):

`old_string`:

```
Same rhythm as phase 2 but the unit is one document. For **create** proposals, show the proposed file path, a short rationale, and the full proposed body before asking. For **reorganize** proposals, show full file moves and combined diffs and approve individually.
```

`new_string`:

```
Same rhythm as the inline-code-documentation phase but the unit is one document. For **create** proposals, show the proposed file path, a short rationale, and the full proposed body before asking. For **reorganize** proposals, show full file moves and combined diffs and approve individually.
```

- [ ] **Step 12: Verify the sweep**

Run (via `Read`):

```
Read plugins/local_conf/skills/finalize-branch/SKILL.md
```

Search the output for any remaining lowercase `phase 0`, `phase 1`, `phase 2`, `phase 3`, `phase 4`, or `phases 2 + 3` strings. The only allowed remaining occurrences are the literal `## Phase N — ...` section headers. If any user-facing prose mention slipped through, fix it inline before proceeding.

- [ ] **Step 13: Commit**

```bash
git add plugins/local_conf/skills/finalize-branch/SKILL.md
git commit -m "$(cat <<'EOF'
finalize-branch: phase-naming sweep — descriptive names in user-facing prompts

Drops "Phase N" framing from gate prompts, summary labels, commit-message
template, cancellation flow, and edge-case prose. Internal `## Phase N — ...`
headers are kept for skill-author orientation.
EOF
)"
```

---

### Task 2: Update §Tool usage to describe the callout / reference-scan tools

**Files:**
- Modify: `plugins/local_conf/skills/finalize-branch/SKILL.md` (the `## Tool usage` section near the bottom)

- [ ] **Step 1: Anchor-confirm**

`Read` the `## Tool usage` section (search for the heading). Confirm it currently ends with the bullet list:

```
- **Symbol-level reads/edits in source files**: prefer Serena's tools ...
- **Markdown / non-code edits**: `Read` and `Edit`.
- **Git operations and `mix`/`npm`/`pytest` runs**: `Bash`.
- **HexDocs MCP** for Hex package API context if the branch's changes touch a Hex dependency's surface; **Context7 MCP** for non-Hex libraries.
```

- [ ] **Step 2: Insert the callout / reference-scan paragraph**

`Edit`:

`old_string`:

```
- **HexDocs MCP** for Hex package API context if the branch's changes touch a Hex dependency's surface; **Context7 MCP** for non-Hex libraries.

## Spec reference
```

`new_string`:

```
- **HexDocs MCP** for Hex package API context if the branch's changes touch a Hex dependency's surface; **Context7 MCP** for non-Hex libraries.

For pattern matching on Markdown headings inside handoffs (audit Step 5): read each handoff with `Read` and parse heading lines with a regex — not Serena (handoffs are non-code) and not `Grep` (the regex needs to inspect document structure, not just match strings). For the source-file reference scan (audit Step 6), `Grep` is appropriate: matches are text-level (substrings inside comments and docstrings), and the regex can express the handoff-path and callout-identifier patterns directly. `Read` captures the surrounding 1–3 lines of context for the per-reference proposal display, and Serena's `replace_symbol_body` (or `Edit` when the comment isn't symbol-attached) applies the approved edit during the inline-code-documentation phase.

## Spec reference
```

- [ ] **Step 3: Verify**

`Read` the `## Tool usage` section and confirm the new paragraph is present between the last bullet and `## Spec reference`.

- [ ] **Step 4: Commit**

```bash
git add plugins/local_conf/skills/finalize-branch/SKILL.md
git commit -m "finalize-branch: document tool usage for callout & in-code reference scans"
```

---

### Task 3: Insert audit Step 5 — Callout extraction & routing

This task inserts a large new section between the existing audit Step 4 ("Interactive question loop") and the start of `## Phase 2 — Inline code documentation`.

**Files:**
- Modify: `plugins/local_conf/skills/finalize-branch/SKILL.md`

- [ ] **Step 1: Anchor-confirm the insertion point**

`Read` the SKILL.md region containing the end of `## Phase 1 — Audit & clarifying questions` and the start of `## Phase 2 — Inline code documentation`. Confirm the closing prose of Step 4 is followed (after a blank line) by the literal heading `## Phase 2 — Inline code documentation`.

The closing prose of Step 4 (post-Task-1 wording) is:

```
Anything unaddressed in a chunk defaults to `accept`. The user may add free-form clarifications between chunks. After all chunks are processed, summarize the resolved picture. If Steps 5 and 6 will both be silent (no matching callouts and no deletion list), Step 4 prompts: "Proceed to inline code documentation?" Otherwise, Step 4 hands off silently and the gate prompt is owned by whichever of Step 5 or Step 6 runs last.

If new questions arise during resolution (rare), append and run another mini-chunk.
```

- [ ] **Step 2: Insert Step 5**

`Edit`:

`old_string`:

```
If new questions arise during resolution (rare), append and run another mini-chunk.

## Phase 2 — Inline code documentation
```

`new_string`:

````
If new questions arise during resolution (rare), append and run another mini-chunk.

### Step 5 — Callout extraction & routing

Runs only if at least one handoff in the confirmed deletion list contains a matching callout heading. Otherwise silent.

#### Pattern matching

A callout is a Markdown heading at level `###` or deeper whose text matches:

```
^(<pattern>)(?:\s+\d+)?(?:\s*[—\-:]\s*.*)?$
```

…where `<pattern>` is one of the configured callout patterns. Each pattern is a literal heading-prefix string; singular and plural forms are listed as separate entries so handoffs using either form match. Default pattern set:

- `Discovery` / `Discoveries`
- `Decision` / `Decisions`
- `Caveat` / `Caveats`
- `Gotcha` / `Gotchas`
- `Lesson learned` / `Lessons learned`
- `Known issue` / `Known issues`
- `Complexity` / `Complexities`
- `Edge case` / `Edge cases`

Each "X / Y" entry above expands to two literal patterns in the matcher's list. Pattern matching is case-insensitive on the keyword. Numbering after the keyword is optional and not anchored to any sequence — `### Discovery — title`, `### Discovery 1 — title`, `#### Decision: title`, `### Edge cases — empty input`, and a bare `### Known issues` all match.

Multi-word patterns (`Lesson learned`, `Known issue`, `Edge case`) match literally as space-separated tokens at the heading-text start; internal whitespace is not collapsed.

Matches require parsed Markdown headings, not raw text — a literal `### Discovery` line inside a fenced code block is ignored. Plain prose mentions ("see Discovery 4") are ignored.

#### Dedup

Callouts that recur across handoffs are deduped by canonical key: `(first handoff path, normalized heading text)`. Heading text is normalized by lowercasing, collapsing whitespace, and stripping leading numbering (`Discovery N —`). Later handoffs that reference the same heading text are treated as cross-references; only the first appearance becomes a routing item. Renumbering between handoffs is OK — the heading text is the anchor, not the number.

#### Configuration

Two things are known per project: the callout patterns and the repo-docs destination (file path + section heading inside it). Both follow a "convention with override" model.

**Convention scan (default; zero config).** When Step 5 runs, the skill computes the destination by scanning `docs/` (top level plus one subdirectory level deep) for filenames matching this case-insensitive set:

```
discoveries.md, decisions.md, findings.md, lessons.md,
caveats.md, gotchas.md, notes.md
```

- **Exactly one match** → that's the destination.
- **Zero matches** → the bootstrap flow runs (below).
- **Multiple matches** → the merge-offer flow runs (below).

Once the file is identified, scan for a top-level heading matching `## Discoveries`, `## Findings`, `## Decisions`, `## Notes`, `## Lessons learned`, or `## Caveats` (case-insensitive). First match wins. If none found, the skill creates a `## Discoveries` section at the end of the file as part of the routed proposal — the user reviews the diff in the repo-documentation phase before commit.

**Override file.** Used when the convention doesn't fit. Location: `.claude/finalize-branch.toml` or `.claude/finalize-branch.json` at repo root.

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

Only `destination` is required. `section` defaults to `## Discoveries` (created if missing). `patterns` defaults to the built-in set; when overriding, list each form the project uses literally — singular and plural variants must each be specified (e.g., `["Discovery", "Discoveries"]`) since no auto-pluralization is applied to override values. Override beats convention scan in all cases.

If the override's `destination` points to a missing file, halt at Step 5 entry: "Override points to `<path>` which doesn't exist. Create the file or fix the override." No silent fallback to convention. If the override file is unparseable, halt at Step 5 entry with the parse error and a recovery hint.

**Multiple matches.** When the convention scan finds more than one candidate destination:

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

Option 2 aligns with the existing **Reorganize** bucket — bounded to docs the branch's changes make relevant. The merge offer only appears because callouts need routing; without callouts, duplicate destinations sit untouched.

**Bootstrap (zero matches).** If the convention scan finds nothing and no override exists:

```
No discoveries destination found. Propose creating `docs/discoveries.md`?
(`yes` / `nuance: <different path>` / `cancel`)
```

On `yes`, the new file is added to the repo-documentation phase as a **Create** proposal. Routed callouts populate it.

#### Per-callout routing UX

After extraction, dedup, and destination resolution, print a one-line tally and the resolved destination:

```
Found 6 unique callouts across 4 handoffs (after dedup).
Destination: docs/conventions.md → ## Discoveries
```

If a bootstrap flow ran, that prompt completes first so the destination is settled before answering routing questions.

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

The destination path appears inline next to `add-to-repo-docs` so the user can see exactly where it'll land.

**Recommendation heuristics** (best-effort defaults; user has final say):

- `add-to-repo-docs` — when the callout describes an API/data contract, project-wide convention, or external-system fact. Default for most callouts.
- `add-to-inline-code` — when the callout is tightly bound to a specific function/module *the branch added or modified*. Cross-reference `git diff <base>..HEAD` for symbol names that appear in the callout heading or body.
- `already-captured` — when the heading text appears (case-insensitive substring match) in any code comment or any `docs/` doc *outside* `docs/handoffs/` in the current tree. Flag with: `(I see "<matching text>" already in <path>:<line>)`. The user still confirms — never auto-skip.
- `dismiss` — for transient facts ("we tried X, it didn't work, we did Y") with no permanent home. Rare default; usually picked manually.

**Routing actions:**

- **`add-to-repo-docs`** — creates a tracked **Augment** proposal against the destination file and section, with rewritten atemporal content (see "Content transformation" below). Reviewed in the repo-documentation phase via the existing `approve / nuance / skip` rhythm.
- **`add-to-inline-code`** — pick a target symbol:
  1. If exactly one diff-symbol matches the callout, that's the recommendation.
  2. If zero match, prompt for one (`module/function`) or back-out to the four-way choice.
  3. If multiple match, list with a recommendation.

  The selected symbol becomes a tracked **inline-code-doc proposal** that joins the inline-documentation phase's per-file walk. Tagged with its callout source so the user sees `[from callout: Discovery 4 in <handoff filename>]` as context. Same `approve / nuance / skip` rhythm.
- **`already-captured`** — record as "captured at `<path>:<line>`". No proposal created. Counted toward the commit footer's `N already captured` tally.
- **`dismiss`** — record. Counted toward the commit footer's `N dismissed` tally.

`nuance: <text>` lets the user push back without picking a routing. The skill replies, possibly revises its recommendation, and re-prompts. Same rhythm as the existing per-proposal nuance loop.

#### Content transformation for `add-to-repo-docs`

When a callout is routed to repo docs, draft a `### <title>` section to append under the destination's `##` heading. The rewrite applies §"Documentation language and tone" plus these callout-specific rules:

- **Strip temporal markers.** "During this session", "in the <date> handoff", "we discovered", "as we worked through", "after the Nth amendment". Replace with present-tense statements about the system.
- **Strip branch/PR/plan references.** "Task X in the active plan", "this branch", "the in-flight plan". The destination doc lives past all of those.
- **Keep code/data fences and tables verbatim.** Real artifacts (sample data, command snippets, route tables) are the part of a callout most often worth preserving as-is. Never paraphrase inside fences or table cells.
- **Promote the heading and strip session-relative numbering.** `### Discovery 4 — <title>` becomes `### <title>`.
- **No source-handoff backlink.** Handoffs are deleted in the final phase. Linking would dangle. Git history preserves the original.

Per-callout proposal display (in the repo-documentation phase walk):

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

If the destination doc lacks the configured section heading, the first routed callout's proposal includes the section header plus the new entry as one diff. Subsequent callouts append under the now-existing heading.

Entries land in routing order = Step 5 walk order = chronological order across handoffs (oldest discovery first). Produces a chronological log feel without requiring date prefixes inside the doc.

#### Step 5 close-out

```
Audit step 5 complete:
  Added to inline code docs:  1 (Acme.Users @moduledoc)
  Added to repo docs:         3 (→ docs/conventions.md)
  Already captured:           1
  Dismissed:                  1
```

Step 5 doesn't gate on the user — it transitions straight into Step 6 when there's anything to scan, or skips ahead to the audit-phase close-out gate when there isn't. The user-facing "Proceed to inline code documentation?" prompt is owned by whichever step exits the audit phase last.

The contract: every extracted callout has an explicit routing decision before the audit phase exits. The handoff-cleanup phase carries a defensive halt that fires if conversation state ever reaches deletion with an unrouted callout.

## Phase 2 — Inline code documentation
````

- [ ] **Step 3: Verify**

`Read` the file region from the end of audit Step 4 to the start of `## Phase 2 — Inline code documentation`. Confirm:

- The new `### Step 5 — Callout extraction & routing` heading is present.
- Subsections in order: pattern matching, dedup, configuration (with convention scan / override / multiple matches / bootstrap), per-callout routing UX, content transformation, Step 5 close-out.
- The next heading after Step 5's close-out is `## Phase 2 — Inline code documentation`.

- [ ] **Step 4: Commit**

```bash
git add plugins/local_conf/skills/finalize-branch/SKILL.md
git commit -m "$(cat <<'EOF'
finalize-branch: add audit Step 5 — callout extraction & routing

Scans the branch's confirmed handoffs for matching callout headings,
dedupes across handoffs, and routes each unique callout to one of
add-to-repo-docs / add-to-inline-code / already-captured / dismiss
with a recommendation per heuristic. Includes the convention scan,
override file, multiple-matches merge offer, and zero-matches
bootstrap flows. Routed callouts seed proposals into the existing
inline-code and repo-doc phase walks.
EOF
)"
```

---

### Task 4: Insert audit Step 6 — In-code reference cleanup

**Files:**
- Modify: `plugins/local_conf/skills/finalize-branch/SKILL.md`

- [ ] **Step 1: Anchor-confirm**

`Read` the file region containing the end of `### Step 5 — Callout extraction & routing` (specifically Step 5's close-out) and the start of `## Phase 2 — Inline code documentation`. Confirm Step 5 ends with the close-out paragraph from Task 3 and the next heading is `## Phase 2`.

- [ ] **Step 2: Insert Step 6**

`Edit`:

`old_string`:

```
The contract: every extracted callout has an explicit routing decision before the audit phase exits. The handoff-cleanup phase carries a defensive halt that fires if conversation state ever reaches deletion with an unrouted callout.

## Phase 2 — Inline code documentation
```

`new_string`:

````
The contract: every extracted callout has an explicit routing decision before the audit phase exits. The handoff-cleanup phase carries a defensive halt that fires if conversation state ever reaches deletion with an unrouted callout.

### Step 6 — In-code reference cleanup

Runs immediately after Step 5 whenever the deletion list is non-empty or Step 5 found callouts; otherwise silent. Scans source files for comments and docstrings that reference handoffs or callouts and proposes a resolution for each, so no comment in the merged tree points to a deleted handoff or to a callout identifier without a definition.

#### Scope of the scan

Source files only. Walk every file the project's language conventions treat as a source file (matched by extension: `.ex`/`.exs` for Elixir, `.js`/`.jsx`/`.ts`/`.tsx` for JS/TS, `.py` for Python, `.rs` for Rust, etc.). Generated files, lockfiles, fixtures, and binary files are skipped using the same exclusion list the inline-code-documentation phase already uses.

The scan covers the **whole repo**, not just files in the branch's diff. References usually arrive with the handoff, but the cost of a full-repo regex scan is low and the cost of a missed dangling reference is high.

Detection is text-level — read each file with `Read` (or scan with `Grep` for the regex match list first), match a small set of regexes. Symbol-level navigation isn't useful inside comment bodies.

#### What counts as a reference

Two pattern families:

- **Handoff path references** — a literal substring matching `docs/handoffs/<filename>` (or the equivalent path discovered from the deletion list, if the project's handoffs live elsewhere). Matches inside comments and docstrings are routed normally; matches inside string literals or path arguments are flagged with a "is this a real code dependency? skip if so" prompt.
- **Callout-identifier references** — a sequence matching `(<pattern>) ?\d+` (e.g., `Discovery 4`, `Decision 12`) inside comments and docstrings, where `<pattern>` is one of the configured callout patterns. Only meaningful when Step 5 extracted a callout with the same identifier; references to identifiers that don't exist in any handoff are noted but typically dismissed.

Each match is reported with file path, line number, and the surrounding 1–3 lines of comment context.

#### Resolution choices per reference

Each match becomes a tracked **inline-code-doc proposal** that the user resolves during the inline-code-documentation phase walk. Per-reference choices:

- **`inline`** — extract the relevant content and rewrite the comment so the fact is present in the code itself. Best for short, terse references where the original handoff text is a sentence or two. Draft the inlined replacement using the same atemporal-rewrite rules as `add-to-repo-docs` (no session-voice, no branch references) and present the diff for `approve / nuance / skip`.
- **`redirect`** — replace the reference with a pointer to the destination doc + section. Format: `# see <destination-path> "<section>" — <topic title>` (or the language's idiomatic comment style). Available only when the referenced callout was routed to `add-to-repo-docs` in Step 5; the skill knows the destination path and the rewritten title from that routing decision.
- **`remove`** — delete the reference. Use when the comment carried the reference as supporting context but the surrounding text is self-contained without it.
- **`skip`** — leave the reference as-is. Use sparingly; the skill warns at the close of Step 6 that any skipped reference will dangle once handoffs are deleted, and asks for explicit confirmation.

**Recommendation per match:**

- If the referenced callout was routed to `add-to-repo-docs` in Step 5 → recommend `redirect` (preserves the link, fixes the dangling path).
- If the referenced callout was routed to `add-to-inline-code` and the matched comment is on or near that symbol → recommend `inline` (the routed proposal will already cover the same ground).
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

Resolution-change shortcuts: `i`=inline, `r`=redirect, `x`=remove, `s`=skip. On a change, re-draft the proposed comment for the new resolution and re-prompt.

#### Step 6 close-out

```
Audit step 6 complete:
  References resolved by inlining:    2
  References resolved by redirect:    4
  References removed:                 1
  References skipped (will dangle):   0

Proceed to inline code documentation?
```

If any references were skipped, append: "Note: <N> reference(s) will dangle in the merged tree. Re-run if you want to revisit this."

The contract: every detected in-code reference has an explicit resolution (`inline`, `redirect`, `remove`, or `skip`) before the audit phase exits. A `skip` is recorded as an explicit user choice to leave the dangle, and does not block deletion — the close-out warning is the only signal. The handoff-cleanup phase carries a defensive halt that fires if conversation state ever reaches deletion with an unresolved reference (no `skip` recorded).

## Phase 2 — Inline code documentation
````

- [ ] **Step 3: Verify**

`Read` the new region. Confirm `### Step 6 — In-code reference cleanup` is present between Step 5's close-out and `## Phase 2 — Inline code documentation`, with subsections: scope, what counts, resolution choices, per-reference display, close-out.

- [ ] **Step 4: Commit**

```bash
git add plugins/local_conf/skills/finalize-branch/SKILL.md
git commit -m "$(cat <<'EOF'
finalize-branch: add audit Step 6 — in-code reference cleanup

Scans the whole repo's source files for references to handoff paths
in the deletion list and to callout identifiers extracted by Step 5,
and proposes a per-reference resolution (inline / redirect / remove
/ skip) tagged with a recommendation linked to that callout's Step 5
routing. Each match flows through the existing inline-code-doc
phase walk with the standard approve / nuance / skip rhythm.
EOF
)"
```

---

### Task 5: Acknowledge new proposal sources in Phase 2 (Inline code documentation)

**Files:**
- Modify: `plugins/local_conf/skills/finalize-branch/SKILL.md` (the `## Phase 2 — Inline code documentation` Step 1)

- [ ] **Step 1: Anchor-confirm**

`Read` the start of `## Phase 2 — Inline code documentation`. Confirm Step 1 begins with "From `git diff --name-only ...`" and lists the doc-opportunity bullets.

- [ ] **Step 2: Insert the proposal-source paragraph**

`Edit`:

`old_string`:

```
**Do NOT touch private/internal function docs unless they already exist and are now stale.**

### Step 2 — Per-file proposal
```

`new_string`:

```
**Do NOT touch private/internal function docs unless they already exist and are now stale.**

The candidate list also includes any callout-sourced proposals routed to `add-to-inline-code` in audit Step 5 and any in-code reference-cleanup proposals from audit Step 6. These flow through the same per-file walk as diff-sourced proposals and are tagged with their source on display (e.g., `[from callout: Discovery 4 in <handoff filename>]` or `[from in-code reference cleanup: <path>:<line>]`).

### Step 2 — Per-file proposal
```

- [ ] **Step 3: Verify** by re-reading the section.

- [ ] **Step 4: Commit**

```bash
git add plugins/local_conf/skills/finalize-branch/SKILL.md
git commit -m "finalize-branch: thread callout & reference-cleanup proposals into Phase 2 walk"
```

---

### Task 6: Acknowledge the callout proposal source in Phase 3 (repo documentation)

**Files:**
- Modify: `plugins/local_conf/skills/finalize-branch/SKILL.md` (the `## Phase 3 — Architecture, ...` Step 1 buckets)

- [ ] **Step 1: Anchor-confirm**

`Read` the start of `## Phase 3 — Architecture, business-logic, README, CLAUDE.md` Step 1. Confirm the four-bucket list (Update / Augment / Create / Reorganize) is present.

- [ ] **Step 2: Insert the callout-source paragraph**

`Edit`:

`old_string`:

```
Stale-but-unrelated docs flagged in the audit phase land in **update**, with the original audit-phase question carried forward as context.

### Doc surface rules
```

`new_string`:

```
Stale-but-unrelated docs flagged in the audit phase land in **update**, with the original audit-phase question carried forward as context.

Augment proposals also include any callouts routed to `add-to-repo-docs` in audit Step 5, applied against the resolved destination file and section. They flow through the same per-document approval rhythm and are tagged with their source on display (e.g., `Source callout: Discovery 4 from <handoff filename>`). If the destination doc was bootstrapped (zero-matches flow), it appears in the **Create** bucket and the routed callouts populate it.

### Doc surface rules
```

- [ ] **Step 3: Verify** by re-reading the section.

- [ ] **Step 4: Commit**

```bash
git add plugins/local_conf/skills/finalize-branch/SKILL.md
git commit -m "finalize-branch: thread callout-sourced Augment proposals into Phase 3 walk"
```

---

### Task 7: Final-review summary annotations and defensive halts (Phase 4 Step 1)

**Files:**
- Modify: `plugins/local_conf/skills/finalize-branch/SKILL.md` (the `## Phase 4 — Handoff cleanup & final commit` Step 1)

- [ ] **Step 1: Anchor-confirm**

`Read` the start of `## Phase 4 — Handoff cleanup & final commit` Step 1. Confirm the example block currently reads (post-Task-1):

```
Pending changes (not yet committed):
  Inline code docs: 14 changes across 6 files
  Repo docs:
    Updated:    docs/architecture.md, README.md
    Augmented:  docs/business-logic/users.md
    Created:    docs/architecture/auth-oauth.md
    Reorganized: merged docs/migration.md + docs/post-migration.md

About to delete:
  docs/handoffs/2026-04-15-200312-initial-spike.md
```

- [ ] **Step 2: Annotate the example with callout / reference-cleanup tallies**

`Edit`:

`old_string`:

```
Pending changes (not yet committed):
  Inline code docs: 14 changes across 6 files
  Repo docs:
    Updated:    docs/architecture.md, README.md
    Augmented:  docs/business-logic/users.md
    Created:    docs/architecture/auth-oauth.md
    Reorganized: merged docs/migration.md + docs/post-migration.md
```

`new_string`:

```
Pending changes (not yet committed):
  Inline code docs: 14 changes across 6 files
                    (1 from a callout, 7 from in-code reference cleanup)
  Repo docs:
    Updated:    docs/architecture.md, README.md
    Augmented:  docs/conventions.md (3 from callouts), docs/business-logic/users.md
    Created:    docs/architecture/auth-oauth.md
    Reorganized: merged docs/migration.md + docs/post-migration.md
```

Each parenthetical is omitted when its count is zero. The proposals themselves are already individually approved; the parentheticals are an at-a-glance source breakdown.

- [ ] **Step 3: Insert the defensive-halt paragraph**

`Edit`:

`old_string`:

```
`show diff` runs `git diff` (uncommitted) plus the list of pending deletes. `cancel` triggers the cancellation retention flow.

If after the inline-code and repo-doc phases there are **zero proposals approved** *and* zero handoffs to delete, exit with "Nothing to finalize" — no empty commit.
```

(If the surrounding text differs because Task 1 used different wording for "phases 2 + 3", adjust the `old_string` to match.)

`new_string`:

```
`show diff` runs `git diff` (uncommitted) plus the list of pending deletes. `cancel` triggers the cancellation retention flow.

If after the inline-code and repo-doc phases there are **zero proposals approved** *and* zero handoffs to delete, exit with "Nothing to finalize" — no empty commit.

**Defensive halts before deletion.** A handoff cannot be deleted if (a) audit Step 5 extracted a callout from it that has no recorded routing decision, or (b) any source file still contains a reference to its path that wasn't resolved as `inline`, `redirect`, or `remove` (a recorded `skip` does not block — the user explicitly chose to leave the dangle). Under normal flow neither check fires; they exist so future audit-phase changes can't silently drop callouts or references. On a fired halt, exit with the relevant recovery hint: "Re-run and resolve at audit step 5" or "Re-run and resolve at audit step 6".
```

- [ ] **Step 4: Verify** by re-reading the section.

- [ ] **Step 5: Commit**

```bash
git add plugins/local_conf/skills/finalize-branch/SKILL.md
git commit -m "finalize-branch: annotate final-review summary; add deletion-gate defensive halts"
```

---

### Task 8: Update the commit message footer template (Phase 4 Step 4)

**Files:**
- Modify: `plugins/local_conf/skills/finalize-branch/SKILL.md` (the `## Phase 4 — ...` Step 4 template)

- [ ] **Step 1: Anchor-confirm**

`Read` the `### Step 4 — Compose commit message` block. Confirm the template currently reads (post-Task-1):

```
docs: finalize <branch-name>

Inline code docs:
  - <terse summary, one bullet per file or grouped by module>

Repo docs:
  - <terse summary>

Removed <N> session handoff document(s).
[optional: "(branch health checks skipped)"]
```

- [ ] **Step 2: Insert the two new footer lines**

`Edit`:

`old_string`:

```
Removed <N> session handoff document(s).
[optional: "(branch health checks skipped)"]
```

`new_string`:

```
Removed <N> session handoff document(s).
Callouts: <X> to repo docs, <Y> to inline code docs, <Z> already captured, <W> dismissed.
In-code references: <I> inlined, <R> redirected, <X> removed, <S> skipped.
[optional: "(branch health checks skipped)"]
```

- [ ] **Step 3: Add the omission note immediately after the template**

`Edit`:

`old_string`:

```
No `Co-Authored-By` trailer.
```

`new_string`:

```
Either of the `Callouts:` / `In-code references:` lines is omitted entirely when its corresponding step had nothing to report (no extracted callouts; no detected references). No `Co-Authored-By` trailer.
```

- [ ] **Step 4: Verify** by re-reading the section.

- [ ] **Step 5: Commit**

```bash
git add plugins/local_conf/skills/finalize-branch/SKILL.md
git commit -m "finalize-branch: extend commit footer with callout & reference-cleanup tallies"
```

---

### Task 9: Add new edge cases

**Files:**
- Modify: `plugins/local_conf/skills/finalize-branch/SKILL.md` (the `## Edge cases` section)

- [ ] **Step 1: Anchor-confirm**

`Read` the `## Edge cases` section. Confirm it begins with `- **Empty branch** (zero commits ahead of base) — refuse at the pre-flight gate.` (post-Task-1 wording) and ends with `- **Binary files in diff** — silently skip in inline-code-documentation candidate building.`

- [ ] **Step 2: Insert callout-handling and reference-cleanup edge cases**

`Edit`:

`old_string`:

```
- **Binary files in diff** — silently skip in inline-code-documentation candidate building.

## Tool usage
```

`new_string`:

```
- **Binary files in diff** — silently skip in inline-code-documentation candidate building.
- **Callout heading with no body** (just the heading, nothing under it before the next heading) — present in routing as `(empty body)`; recommendation defaults to `dismiss`.
- **Pattern match inside a fenced code block** — ignored. Pattern matching happens on parsed Markdown headings, not raw text.
- **Override file present but unparseable** — halt at audit Step 5 entry with the parse error.
- **Override `destination` points to a missing file** — halt with the recovery hint above (Step 5 configuration).
- **Same heading text appears as both a callout and an existing heading inside the destination doc** — flagged as `already-captured` candidate with the existing heading's location. User confirms or overrides.
- **Handoffs but zero matching callouts and zero in-code references** — Steps 5 and 6 are silent; flow is unchanged.
- **All callouts dismissed or already-captured** — no new proposals from Step 5; final commit footer's `Callouts:` line still records the tallies.
- **User cancels mid-routing or mid-cleanup** — same cancellation retention behavior as elsewhere. No applied edits exist yet at this point in the flow, so the prompt is the short "no edits to retain" exit.
- **In-code reference to a handoff that's NOT in the deletion list** (e.g., a comment pointing to a handoff from a previous branch that was kept) — surfaced in Step 6 with recommendation `skip` and an explanatory note. Cleanup is optional.
- **Callout-identifier reference (`Discovery 4`) where Step 5 didn't extract a matching callout** — surfaced with recommendation `skip` and a "no matching callout in this branch's handoffs" note. The user may still choose `inline` or `remove` if they recognize the reference is now stale.
- **Source-file reference to a handoff path inside a string literal or path argument** (not a comment/docstring) — surfaced with a "appears to be a real code dependency, not a comment" warning; recommendation defaults to `skip`. The user can still choose other resolutions if they know the code path is dead.

## Tool usage
```

- [ ] **Step 3: Verify** by re-reading the section.

- [ ] **Step 4: Commit**

```bash
git add plugins/local_conf/skills/finalize-branch/SKILL.md
git commit -m "finalize-branch: document callout & reference-cleanup edge cases"
```

---

### Task 10: Bump the local_conf plugin version

**Files:**
- Modify: `plugins/local_conf/.claude-plugin/plugin.json`

- [ ] **Step 1: Anchor-confirm**

`Read` `plugins/local_conf/.claude-plugin/plugin.json`. Confirm `"version": "1.3.0"` is present.

- [ ] **Step 2: Bump to 1.4.0** (additive feature)

`Edit`:

`old_string`:

```
  "version": "1.3.0",
```

`new_string`:

```
  "version": "1.4.0",
```

- [ ] **Step 3: Verify** with `Read`.

- [ ] **Step 4: Commit**

```bash
git add plugins/local_conf/.claude-plugin/plugin.json
git commit -m "local_conf: bump to 1.4.0 — finalize-branch callout handling"
```

---

### Task 11: Holistic self-review against the spec

This task runs no edits; it cross-checks the result and surfaces any drift before declaring done. Fix issues found inline (re-applying Task 1–10 edits as needed).

**Files:**
- Read: `plugins/local_conf/skills/finalize-branch/SKILL.md`
- Read: `docs/superpowers/specs/2026-04-30-finalize-branch-callout-handling-design.md`

- [ ] **Step 1: Read SKILL.md end-to-end**

```
Read plugins/local_conf/skills/finalize-branch/SKILL.md
```

- [ ] **Step 2: Re-read the spec**

```
Read docs/superpowers/specs/2026-04-30-finalize-branch-callout-handling-design.md
```

- [ ] **Step 3: Cross-check requirements**

For each section of the spec, verify the corresponding text exists in SKILL.md. Confirmation list:

- **Pattern matching defaults** — all eight singular/plural pattern pairs are listed in Step 5.
- **Dedup** — canonical-key rule (first handoff path, normalized heading text) is documented.
- **Convention scan filenames** — the seven filenames (`discoveries.md`, `decisions.md`, `findings.md`, `lessons.md`, `caveats.md`, `gotchas.md`, `notes.md`) are listed.
- **Section heading defaults** — the six matched headings (`## Discoveries`, `## Findings`, `## Decisions`, `## Notes`, `## Lessons learned`, `## Caveats`) are listed.
- **Override file** — both TOML and JSON shapes shown; required vs default fields documented; missing-file and unparseable halts called out.
- **Multiple matches** — the three-option prompt (pick / merge / halt) is reproduced.
- **Bootstrap** — the propose-creating prompt with `yes` / `nuance:` / `cancel` is reproduced.
- **Per-callout routing UX** — the four routing choices (`a`/`c`/`r`/`d`) and `nuance:` are documented; the four heuristics are present.
- **Routing actions** — Augment, inline-code, already-captured, dismiss are each described.
- **Step 5 close-out** — the four-line tally is shown.
- **Step 6 scope, references, choices** — full-repo source-file scan; both pattern families; four resolutions (`inline`/`redirect`/`remove`/`skip`); all four recommendations.
- **Per-reference proposal display** — the `In-code reference — <path>:<line>` block is reproduced.
- **Step 6 close-out** — four-line tally + dangling-skip note.
- **Phase 2 / Phase 3 acknowledgments** — both note the new proposal sources.
- **Phase 4 final review annotations** — `(N from a callout, M from in-code reference cleanup)` and `(N from callouts)` annotations are present.
- **Defensive halts** — both Step 5 (unrouted callout) and Step 6 (unresolved reference) are documented in Phase 4.
- **Commit message footer** — both new lines (`Callouts:`, `In-code references:`) are present; omission rule is documented.
- **Phase-naming sweep** — no remaining lowercase `phase 0`/`phase 1`/`phase 2`/`phase 3`/`phase 4` references in user-facing prose. Internal `## Phase N — ...` headers retained.
- **Edge cases** — all twelve new edge cases from Task 9 are present.
- **Tool usage** — the new paragraph on Read+regex (handoffs) and Grep (source scan) is present.
- **Plugin version** — `plugin.json` is at `1.4.0`.

If any item is missing, fix it inline (apply a follow-up `Edit`, `Read`-verify, then commit with a message like `finalize-branch: <one-line fix>`).

- [ ] **Step 4: Final commit** (only if step 3 surfaced fixes; otherwise skip)

```bash
git add plugins/local_conf/skills/finalize-branch/SKILL.md
git commit -m "finalize-branch: self-review fixes — <one-line>"
```

---

## Self-review (plan author)

After writing the plan above, the author cross-checked it against the spec and the existing SKILL.md. Notes:

- **Spec coverage:** Every spec subsection maps to a task. Step 5 → Task 3; Step 6 → Task 4; phase-naming sweep → Task 1; final-review annotations + defensive halts → Task 7; commit footer → Task 8; edge cases → Task 9; tool usage → Task 2; Phase 2/3 thread-through → Tasks 5/6. Plugin version is a routine addition (Task 10). Holistic check is Task 11.
- **Anchor risk:** Task 1's user-facing-prompt sweep changes lines that later tasks anchor on. Each later task explicitly states the post-Task-1 wording it expects to see. If anchors don't match, the engineer is told to stop and re-derive.
- **Type/term consistency:** Step labels referenced consistently — "audit Step 5" / "audit Step 6"; "inline code documentation phase" / "repo documentation phase" / "handoff cleanup & final commit". Routing choice keys (`already-captured`, `add-to-inline-code`, `add-to-repo-docs`, `dismiss`) match the spec verbatim. Resolution keys (`inline`, `redirect`, `remove`, `skip`) match.
- **Placeholder scan:** No `TBD` / "implement later" / "add error handling" / "similar to Task N" placeholders. All new markdown content is included verbatim in `new_string` blocks.

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-04-30-finalize-branch-callout-handling.md`. Two execution options:

**1. Subagent-Driven (recommended)** — dispatch a fresh subagent per task, review between tasks, fast iteration.

**2. Inline Execution** — execute tasks in this session using executing-plans, batch execution with checkpoints.

Which approach?
