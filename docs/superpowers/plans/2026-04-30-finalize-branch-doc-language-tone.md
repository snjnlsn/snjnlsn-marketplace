# Finalize-branch documentation language and tone — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a "Documentation language and tone" section to the `finalize-branch` skill, plus one-line pointers from Phase 2 and Phase 3 that reference it.

**Architecture:** All edits land in a single file: `plugins/local_conf/skills/finalize-branch/SKILL.md`. One new top-level section is inserted between two existing top-level sections; two short pointer lines are inserted at the top of Phase 2's and Phase 3's bodies. No code, no tests, no version bumps. The pattern (canonical block + per-phase pointers) mirrors how `overrides:using-overrides` references its MCP toolkit block.

**Tech Stack:** Markdown only. Edits via the `Edit` tool with `old_string`/`new_string` anchors.

**Spec:** `docs/superpowers/specs/2026-04-30-finalize-branch-doc-language-tone-design.md`

---

## File Structure

Files modified:

- `plugins/local_conf/skills/finalize-branch/SKILL.md` — three insertions:
  1. New `## Documentation language and tone` section between `## Source-of-truth precedence` and `## Halt and exit messaging`.
  2. One-line pointer immediately under `## Phase 2 — Inline code documentation`.
  3. One-line pointer immediately under `## Phase 3 — Architecture, business-logic, README, CLAUDE.md`.

Files created: none.
Files deleted: none.

No other files in the repo are affected. The `local_conf` plugin version (`plugin.json`), the plugin README, and the marketplace root README are out of scope per the spec.

## Verification approach

Because there are no executable tests, each insertion is verified by reading the file back and confirming:

- The exact inserted text is present.
- The surrounding anchors (preceding and following content) are unchanged.
- The order of sections/subsections is preserved.

The final task does a holistic re-read against the spec.

---

### Task 1: Insert the "Documentation language and tone" section

**Files:**
- Modify: `plugins/local_conf/skills/finalize-branch/SKILL.md` (insert between `## Source-of-truth precedence` body and `## Halt and exit messaging` heading)

- [ ] **Step 1: Read the surrounding region to confirm the anchor**

Run (via the `Read` tool):

```
Read plugins/local_conf/skills/finalize-branch/SKILL.md offset=19 limit=10
```

Expected to see (line numbers approximate, content exact):

```
## Source-of-truth precedence

When handoffs and code disagree, resolve in this order: **code (current) > newest handoff > older handoffs (newer wins among handoffs)**. Code is what actually runs; handoffs are intent.

## Halt and exit messaging

Every premature exit — pre-flight refusal, branch health failure, mid-phase error, user cancellation, hook failure — must end with a brief summary ...
```

If the surrounding text differs, stop and re-derive anchors before proceeding.

- [ ] **Step 2: Insert the new section via `Edit`**

Use the `Edit` tool on `plugins/local_conf/skills/finalize-branch/SKILL.md`:

`old_string`:

```
When handoffs and code disagree, resolve in this order: **code (current) > newest handoff > older handoffs (newer wins among handoffs)**. Code is what actually runs; handoffs are intent.

## Halt and exit messaging
```

`new_string`:

```
When handoffs and code disagree, resolve in this order: **code (current) > newest handoff > older handoffs (newer wins among handoffs)**. Code is what actually runs; handoffs are intent.

## Documentation language and tone

Phases 2 and 3 produce written content. Apply these rules to every proposed `@moduledoc`/`@doc`/docstring/JSDoc and every prose edit to `docs/`/`README.md`/`CLAUDE.md`.

**Be clear and concise first.** Documentation earns its space by helping the reader understand the code faster than reading the code itself would. Every word should pull weight. When in doubt, cut.

**Then match the surrounding voice — but don't inherit verbosity.** Before drafting, sample 2–3 nearby docs of the same kind — for inline docs, other `@moduledoc`s/`@doc`s in the same file or sibling modules; for project docs, other entries in the same `docs/` subdirectory or other sections of the same file. Mirror their register where it serves the reader: vocabulary, formality, headings vs. prose, presence/absence of examples.

If existing docs are unnecessarily long, padded, or hedged, **clarity wins over fidelity**. The skill is a chance to incrementally improve docs where the work makes the improvement relevant — when you're editing a function's `@doc` or a paragraph in an architecture doc and the surrounding prose is bloated, tighten it. Don't preserve waste just because it's the local style. (This does *not* license drifting into rewrites of unrelated sections for style — see the per-surface notes.)

**Anti-patterns** — these signal "an LLM wrote this" regardless of project voice. Avoid in every proposal:

- **Marketing adjectives** — "seamless(ly)", "powerful", "robust", "elegant", "blazing", "simply", "easily", "effortless", "comprehensive". Cut them; the claim either survives without the adjective or shouldn't be made.
- **Narrating the obvious** — "The `Foo` module is a module that handles foo." / "This function takes a user and returns a user." Lead with WHY/WHEN a caller reaches for it, not WHAT it does syntactically; the signature already says what.
- **Referencing the change/PR/branch** — "As part of this change…", "Recently added…", "This PR introduces…". Docs describe the current state of the code, not the journey to it.
- **Filler and hedges** — "In order to" → "to"; drop "It should be noted that…", "Please note", "It is important to", "Currently…". (Genuine counter-intuitive caveats are a separate case — flag them when they exist.)
- **Restating the symbol name** — "`Acme.Users.invite/2` is a function that invites users." The reader already sees the name; spend the sentence on the meaningful part.
- **Future-tense aspiration** — "This will eventually support…". If it's not implemented, don't document it.
- **Editorial self-praise** — "This elegant solution…", "An efficient approach…". Let the code earn the adjective.

**Per-surface notes:**

- **`@moduledoc`** — one to three sentences on the module's responsibility and when a caller would reach for it. Skip if the module name plus public function list already make it obvious and no project convention requires one.
- **`@doc`** — describe the contract: what the function does for the caller, important constraints, non-obvious return shape. Add examples only when they meaningfully clarify; don't pad with doctests.
- **`@spec`** — propose only when the type is unambiguous. Never invent. (Already stated in Phase 2; restated here for completeness.)
- **README / architecture docs** — when *updating*, scope edits to the new fact plus any directly adjacent prose that's now misleading, bloated, or padded; tightening is encouraged where it falls in your editing path. Don't drift into rewriting unrelated sections for style — that's a separate cleanup task. When *creating*, sample the existing `docs/` voice but lean toward concise even if local norms run long.

When in doubt, prefer a shorter doc over a longer one. Edits that *reduce* word count without losing information are almost always correct, and incremental tightening of docs you're already editing is part of the job, not a detour.

## Halt and exit messaging
```

- [ ] **Step 3: Verify the insertion**

Run (via `Read`):

```
Read plugins/local_conf/skills/finalize-branch/SKILL.md offset=20 limit=60
```

Confirm:
- Line ~20 is still `## Source-of-truth precedence` (unchanged).
- The next section heading after the source-of-truth body is `## Documentation language and tone`.
- The first paragraph under that heading begins `Phases 2 and 3 produce written content.`
- The section ends with the "When in doubt, prefer a shorter doc…" closer.
- Immediately after the closer comes `## Halt and exit messaging` with its existing first paragraph (`Every premature exit — …`) intact.

If any of those conditions fails, revert with `git restore plugins/local_conf/skills/finalize-branch/SKILL.md` and redo the edit.

- [ ] **Step 4: Do not commit yet**

All three insertions go in a single commit at the end of Task 4.

---

### Task 2: Insert the Phase 2 pointer

**Files:**
- Modify: `plugins/local_conf/skills/finalize-branch/SKILL.md` (insert between `## Phase 2 — Inline code documentation` heading and `### Step 1 — Build the candidate list` heading)

- [ ] **Step 1: Read the Phase 2 region to confirm the anchor**

Run (via `Read`):

```
Read plugins/local_conf/skills/finalize-branch/SKILL.md
```

Then locate the Phase 2 region. The relevant lines should read:

```
## Phase 2 — Inline code documentation

### Step 1 — Build the candidate list
```

There is no body content between the heading and the first sub-section — the pointer line will be the only intervening content.

- [ ] **Step 2: Insert the Phase 2 pointer via `Edit`**

Use the `Edit` tool on `plugins/local_conf/skills/finalize-branch/SKILL.md`:

`old_string`:

```
## Phase 2 — Inline code documentation

### Step 1 — Build the candidate list
```

`new_string`:

```
## Phase 2 — Inline code documentation

Apply §Documentation language and tone to every proposed `@moduledoc` / `@doc` / docstring / JSDoc.

### Step 1 — Build the candidate list
```

- [ ] **Step 3: Verify the insertion**

Run (via `Read`) and locate the Phase 2 heading. Confirm the order is:

```
## Phase 2 — Inline code documentation

Apply §Documentation language and tone to every proposed `@moduledoc` / `@doc` / docstring / JSDoc.

### Step 1 — Build the candidate list

From `git diff --name-only <base>..HEAD`, take all source files; ...
```

If the pointer is missing, `### Step 1` content is altered, or `Step 1`'s opening text is disturbed, revert and redo.

- [ ] **Step 4: Do not commit yet**

Continue to Task 3.

---

### Task 3: Insert the Phase 3 pointer

**Files:**
- Modify: `plugins/local_conf/skills/finalize-branch/SKILL.md` (insert between `## Phase 3 — Architecture, business-logic, README, CLAUDE.md` heading and `Working surface:` paragraph)

- [ ] **Step 1: Read the Phase 3 region to confirm the anchor**

Run (via `Read`) and locate the Phase 3 region. The relevant lines should read:

```
## Phase 3 — Architecture, business-logic, README, CLAUDE.md

Working surface:

- `docs/**` excluding `docs/handoffs/` and `docs/superpowers/**`
```

- [ ] **Step 2: Insert the Phase 3 pointer via `Edit`**

Use the `Edit` tool on `plugins/local_conf/skills/finalize-branch/SKILL.md`:

`old_string`:

```
## Phase 3 — Architecture, business-logic, README, CLAUDE.md

Working surface:
```

`new_string`:

```
## Phase 3 — Architecture, business-logic, README, CLAUDE.md

Apply §Documentation language and tone to every proposed prose edit. Clarity and concision come first; mirror the established register in `docs/` where it serves the reader, but tighten adjacent prose that's bloated rather than preserving it.

Working surface:
```

- [ ] **Step 3: Verify the insertion**

Run (via `Read`) and locate the Phase 3 heading. Confirm the order is:

```
## Phase 3 — Architecture, business-logic, README, CLAUDE.md

Apply §Documentation language and tone to every proposed prose edit. Clarity and concision come first; mirror the established register in `docs/` where it serves the reader, but tighten adjacent prose that's bloated rather than preserving it.

Working surface:

- `docs/**` excluding `docs/handoffs/` and `docs/superpowers/**`
- `README.md` (root)
- `CLAUDE.md` (root, plus any nested `CLAUDE.md` surfaced by phase 1)
```

If the pointer is missing or `Working surface:` is altered, revert and redo.

---

### Task 4: Final verification and commit

**Files:**
- All edits are in: `plugins/local_conf/skills/finalize-branch/SKILL.md`

- [ ] **Step 1: Run a holistic structural check**

Run:

```bash
grep -n '^## ' plugins/local_conf/skills/finalize-branch/SKILL.md
```

Expected output (order is what matters; line numbers will shift due to the new section):

```
6:# Finalize Branch
13:## When to use
20:## Source-of-truth precedence
24:## Documentation language and tone
<line>:## Halt and exit messaging
<line>:## Phase 0 — Resume detection, pre-flight gate, branch health checks
<line>:## Phase 1 — Audit & clarifying questions
<line>:## Phase 2 — Inline code documentation
<line>:## Phase 3 — Architecture, business-logic, README, CLAUDE.md
<line>:## Phase 4 — Handoff cleanup & final commit
<line>:## Cancellation retention
<line>:## Edge cases
<line>:## Tool usage
<line>:## Spec reference
```

The line `## Documentation language and tone` must appear immediately after `## Source-of-truth precedence` and immediately before `## Halt and exit messaging`. If the order is wrong, fix before committing.

(Note: line 6 is `# Finalize Branch` — single-`#` — and will appear in the grep output because the pattern is `^## ` not `^### `; ignore it for ordering. Actually re-checking: the H1 is `# Finalize Branch` so `^## ` will *not* match it. The first match should be `## When to use`.)

- [ ] **Step 2: Confirm both phase pointers are present**

Run:

```bash
grep -n 'Apply §Documentation language and tone' plugins/local_conf/skills/finalize-branch/SKILL.md
```

Expected: exactly two matches, the first inside Phase 2 and the second inside Phase 3.

- [ ] **Step 3: Confirm the canonical section's bullet list is intact**

Run:

```bash
grep -nE '^- \*\*(Marketing adjectives|Narrating the obvious|Referencing the change/PR/branch|Filler and hedges|Restating the symbol name|Future-tense aspiration|Editorial self-praise)\*\*' plugins/local_conf/skills/finalize-branch/SKILL.md
```

Expected: exactly seven matches in the order shown, all within the new `## Documentation language and tone` section.

- [ ] **Step 4: Confirm `Note that…` is NOT in the filler bullet**

Run:

```bash
grep -n '"Note that' plugins/local_conf/skills/finalize-branch/SKILL.md
```

Expected: zero matches. (The spec explicitly excludes "Note that…" from the filler list because counter-intuitive caveats are sometimes legitimate.)

- [ ] **Step 5: Read the file end-to-end against the spec**

Open both files side-by-side mentally:

- Plan reference: `docs/superpowers/specs/2026-04-30-finalize-branch-doc-language-tone-design.md` (the Design → Content of the shared section block).
- Edited file: `plugins/local_conf/skills/finalize-branch/SKILL.md`.

Read the new `## Documentation language and tone` section in full and confirm it matches the spec's verbatim block (including the "Be clear and concise first" lead, the "Then match the surrounding voice — but don't inherit verbosity" rule, the "clarity wins over fidelity" paragraph, the seven-item anti-pattern list, the four-item per-surface notes, and the "When in doubt, prefer a shorter doc…" closer).

Confirm the Phase 2 pointer text matches the spec exactly:
> Apply §Documentation language and tone to every proposed `@moduledoc` / `@doc` / docstring / JSDoc.

Confirm the Phase 3 pointer text matches the spec exactly:
> Apply §Documentation language and tone to every proposed prose edit. Clarity and concision come first; mirror the established register in `docs/` where it serves the reader, but tighten adjacent prose that's bloated rather than preserving it.

If any text is off by even a word, fix and re-verify.

- [ ] **Step 6: Inspect the diff before staging**

Run:

```bash
git diff plugins/local_conf/skills/finalize-branch/SKILL.md
```

Confirm the diff shows:
- Three insertion blocks (no deletions).
- No changes to any other content in the file (no whitespace drift in unrelated sections, no accidentally-disturbed lines).

If the diff shows anything beyond the three insertions, revert and redo the offending task.

- [ ] **Step 7: Stage and commit**

Run:

```bash
git add plugins/local_conf/skills/finalize-branch/SKILL.md
git commit -m "$(cat <<'EOF'
Add language and tone guidance to finalize-branch skill

Adds a "Documentation language and tone" section between
source-of-truth precedence and halt-and-exit messaging, plus
one-line pointers from Phase 2 and Phase 3. Guidance leads with
clarity/concision, allows tightening adjacent verbose prose
during edits, and lists universal LLM-prose anti-patterns.

Spec: docs/superpowers/specs/2026-04-30-finalize-branch-doc-language-tone-design.md
EOF
)"
```

Expected: a single new commit on the current branch (`feat/finalize-branch-skill`), one file changed, only insertions.

- [ ] **Step 8: Confirm commit landed**

Run:

```bash
git log --oneline -3
```

Expected: the new commit on top, followed by the two prior brainstorm commits (`Nuance finalize-branch doc tone spec…` and `Spec finalize-branch doc language/tone guidance`).

Run:

```bash
git status
```

Expected: working tree clean.

---

## Self-review — issues found and resolved

**Spec coverage:**

- Spec § "Placement" → Tasks 1, 2, 3 each handle one of the three insertion points. ✓
- Spec § "Content of the shared section" → Task 1 inserts the verbatim block. ✓
- Spec § "Pointers in each phase" → Tasks 2 and 3 insert the verbatim pointer text. ✓
- Spec § "Resolved decisions" — `Note that…` exclusion → Task 4 Step 4 grep guard. ✓
- Spec § "Resolved decisions" — clarity over fidelity → embedded in Task 1's `new_string`. ✓
- Spec § "Files affected" → Task 4 Step 6 diff check confirms only the one file changed. ✓
- Spec § "Out of scope" — no version bump, no README touch → no task in this plan touches those, and Task 4 Step 6 would catch any accidental drift. ✓

**Placeholder scan:**

- No "TBD"/"TODO"/"implement later" anywhere in the plan. ✓
- All `old_string` and `new_string` blocks contain the exact verbatim Markdown to insert. ✓
- Verification commands include the exact regex/string to search for and the expected match count. ✓
- Commit message is provided in full via heredoc. ✓

**Type/text consistency:**

- The shared section's text in Task 1 matches the spec's "Content of the shared section" block character-for-character (verified by re-reading both before writing the plan).
- The Phase 2 pointer text in Task 2 matches the spec's pointer text exactly.
- The Phase 3 pointer text in Task 3 matches the spec's pointer text exactly.
- The grep in Task 4 Step 3 matches all seven anti-pattern bullet labels in the order they appear in the new section.

No fixes needed.
