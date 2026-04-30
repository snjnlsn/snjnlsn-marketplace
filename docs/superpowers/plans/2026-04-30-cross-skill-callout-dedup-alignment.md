# Cross-Skill Callout Dedup Alignment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Align `finalize-branch`'s callout dedup with `handle-callouts`' (heading + body substance + smart resolution), and add a callout-awareness section to `session-retrospect` that delegates callout-worthy items to `handle-callouts`.

**Architecture:** Markdown-only changes across two SKILL.md files plus a version bump. Replaces `finalize-branch`'s short heading-text-only `#### Dedup` subsection with a substantial `#### Smart-merge dedup` subsection covering match signals, trigger threshold, resolution categories, prompt UX, transitive clusters, and large-cluster handling. Adds a one-liner pointer in `session-retrospect`'s Process step 1 plus a new `## Coordination with handle-callouts` section at the bottom of that skill. No code, no scripts, no hooks.

**Tech Stack:** Markdown for SKILL.md edits. JSON for `plugin.json` version bump.

**Spec:** `docs/superpowers/specs/2026-04-30-cross-skill-callout-dedup-alignment-design.md`

---

## File structure

**Modify:**
- `plugins/local_conf/skills/finalize-branch/SKILL.md` — replace the `#### Dedup` subsection (lines 183-185), update Step 5 close-out (lines 347-355), update Phase 4 commit-message template (line 574).
- `plugins/local_conf/skills/session-retrospect/SKILL.md` — append a paragraph to Process step 1 (after line 28), add new `## Coordination with handle-callouts` section after `## Constraints` (line 42).

**Bump:**
- `plugins/local_conf/.claude-plugin/plugin.json` — version 1.5.0 → 1.6.0.

**Test approach:** No automated harness (skills are markdown). Each Task ends with structural verification (grep for expected anchor strings). A final smoke test in Task 6 exercises the new behavior in a fresh Claude Code session.

---

### Task 1: Replace `#### Dedup` with `#### Smart-merge dedup` in finalize-branch

**Files:**
- Modify: `plugins/local_conf/skills/finalize-branch/SKILL.md:183-185`

This is the largest content change in the plan — replaces a 1-paragraph subsection with a multi-section subsection covering the full smart-merge behavior. The replacement preserves the surrounding `#### Configuration` subsection that follows.

- [ ] **Step 1: Read the current Dedup subsection for context**

Use the `Read` tool on `plugins/local_conf/skills/finalize-branch/SKILL.md` with `offset: 183, limit: 8`. Confirm the content matches the `old_string` block below. If it differs, reconcile manually before continuing.

- [ ] **Step 2: Apply the replacement**

Use the `Edit` tool on `plugins/local_conf/skills/finalize-branch/SKILL.md`:

- old_string:

  ````
  #### Dedup

  Callouts that recur across handoffs are deduped by canonical key: `(first handoff path, normalized heading text)`. Heading text is normalized by lowercasing, collapsing whitespace, and stripping leading numbering (`Discovery N —`). Later handoffs that reference the same heading text are treated as cross-references; only the first appearance becomes a routing item. Renumbering between handoffs is OK — the heading text is the anchor, not the number.
  ````

- new_string:

  ````
  #### Smart-merge dedup

  Callouts that match across (or within) handoffs are detected and resolved via a smart-merge prompt before the per-callout routing walk. This sub-step runs immediately after pattern matching; the per-callout walk then operates on the resolved list.

  **Match signals.** A pair of callouts triggers as a match if either of these fires:

  - **Heading text match.** Normalized canonical key: lowercase, collapse whitespace, strip leading numbering (`Discovery N —`). The heading text is the anchor, not the number; renumbering between handoffs is OK.
  - **Body substance match.** Semantic judgment — do the two callouts describe the same finding, even with different headings?

  **Trigger threshold:**

  | Match shape | Behavior |
  |---|---|
  | **True duplicate**: heading matches by canonical normalization AND body matches by string equality after collapsing whitespace runs and trimming leading/trailing whitespace (no semantic judgment) | Silent collapse, first wins (no prompt) |
  | Heading match, body diverges (whitespace-stripped string inequality) | Smart-merge prompt |
  | Body-substance match (semantic judgment), heading diverges | Smart-merge prompt |

  **Resolution categories** (used to draft the synthesis):

  | Category | When | Drafted action |
  |---|---|---|
  | Redundant | Same finding, no new info | No update drafted; flag and use existing |
  | New info adds detail | Same finding, later one extends earlier | Draft body that folds both |
  | Partially wrong / superseded | Later contradicts or supersedes earlier on a point | Draft replacement body; if heading misframes, propose heading edit |
  | Contradicts | Later overturns earlier's conclusion | Draft body that records the supersession explicitly (preserves original reasoning, states new conclusion) |

  **Smart-merge prompt UX:**

  ```
  Body-substance match detected — Discovery 1 (in handoff A) vs Caveat 2 (in handoff B)

    Handoff A (older), ### Discovery — JWT clock skew tolerance varies by platform:
    > [body excerpt, first 8-12 lines, "…" if truncated]

    Handoff B (newer), ### Caveat — JWT auth fails near midnight:
    > [body excerpt, first 8-12 lines, "…" if truncated]

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

  Single-letter shortcuts (`m`/`f`/`l`/`b`) avoid collision with the existing routing UX (`a`/`c`/`r`/`d`).

  **Atemporal rewrite timing.** The synthesis applies the atemporal-rewrite rules (see "Content transformation for `add-to-repo-docs`" below: strip temporal markers, strip branch/PR refs, keep code/data fences verbatim, promote heading) **before** showing the prompt. So the merged routing item is ready to flow into the routing walk. `f` and `l` route the original heading + body verbatim; atemporal rewrite still applies at routing time as today. Only `m` benefits from the pre-prompt rewrite.

  **Transitive clusters.** When 3+ callouts pairwise match (A↔B and B↔C both match), treat them as one cluster with one prompt and one synthesis drawing from all sources. The `f`/`l` shortcuts mean "earliest" and "latest" across the whole cluster; middle versions are dropped if `f` or `l` is picked.

  **Cluster-level resolution category** when pairs disagree (e.g., A↔B is "new info adds detail" but A↔C is "contradicts"): use the most severe category found in the cluster (contradicts > superseded > new info > redundant). The synthesis must handle the contradiction explicitly.

  **Large clusters (5+ callouts):** display only the first 2-3 source excerpts in the prompt with a `…and N more` indicator to keep the prompt readable. The synthesis still draws from all sources.

  **`nuance: <text>`** — user pushes back on the synthesis or proposes a better one. Skill regenerates and re-prompts. Same rhythm as existing `nuance:` patterns elsewhere in Phase 1.

  **Output:** a list of merged routing items, each carrying its origin metadata (which handoffs it came from, which match category triggered the merge). The per-callout routing walk in subsequent sub-sections consumes this list as it does today.
  ````

- [ ] **Step 3: Verify the new subsection landed and the old one is gone**

```bash
grep -n "^#### Smart-merge dedup\|^#### Dedup$" plugins/local_conf/skills/finalize-branch/SKILL.md
```

Expected: one match for `#### Smart-merge dedup`, no match for `#### Dedup` (only the new heading should be present).

- [ ] **Step 4: Verify all expected sub-headings within the new subsection are present**

```bash
grep -nE "^\*\*Match signals|^\*\*Trigger threshold|^\*\*Resolution categories|^\*\*Smart-merge prompt UX|^\*\*Atemporal rewrite timing|^\*\*Transitive clusters|^\*\*Cluster-level resolution category|^\*\*Large clusters|^\*\*\`nuance:|^\*\*Output:" plugins/local_conf/skills/finalize-branch/SKILL.md
```

Expected: 10 matches, all within the new `#### Smart-merge dedup` subsection block.

- [ ] **Step 5: Commit**

```bash
git add plugins/local_conf/skills/finalize-branch/SKILL.md
git commit -m "$(cat <<'EOF'
Replace finalize-branch Dedup with Smart-merge dedup

Adds body-substance matching alongside heading-text. Adds smart-merge
prompt UX (apply merge / keep first / keep latest / keep both / nuance)
mirroring handle-callouts' resolution rhythm with cross-handoff
adaptations. Covers trigger threshold (silent on true duplicate, prompt
on divergence), resolution categories (redundant / new info / superseded
/ contradicts), transitive clusters across 3+ handoffs, and large-cluster
display rules.
EOF
)"
```

---

### Task 2: Update Step 5 close-out to include smart-merge tally

**Files:**
- Modify: `plugins/local_conf/skills/finalize-branch/SKILL.md` (the Step 5 close-out block, currently lines 347-355 — line numbers will have drifted after Task 1's much-larger replacement).

- [ ] **Step 1: Locate the close-out block by anchor**

```bash
grep -n "^#### Step 5 close-out" plugins/local_conf/skills/finalize-branch/SKILL.md
```

Expected: one match. Use that line number for the next step.

- [ ] **Step 2: Read the current close-out block for context**

Use the `Read` tool on `plugins/local_conf/skills/finalize-branch/SKILL.md` with `offset: <line from Step 1>, limit: 12`. Confirm the content matches the `old_string` block below.

- [ ] **Step 3: Apply the close-out update**

Use the `Edit` tool on `plugins/local_conf/skills/finalize-branch/SKILL.md`:

- old_string:

  ````
  ```
  Audit step 5 complete:
    Added to inline code docs:  1 (Acme.Users @moduledoc)
    Added to repo docs:         3 (→ docs/conventions.md)
    Already captured:           1
    Dismissed:                  1
  ```
  ````

- new_string:

  ````
  ```
  Audit step 5 complete:
    Callouts after smart-merge: 4 (from 6 raw across 3 handoffs)
    Added to inline code docs:  1 (Acme.Users @moduledoc)
    Added to repo docs:         3 (→ docs/conventions.md)
    Already captured:           1
    Dismissed:                  1
  ```

  The `Callouts after smart-merge:` line renders only when at least one merge happened; otherwise it is omitted to keep the close-out clean for the no-merge case.
  ````

- [ ] **Step 4: Verify**

```bash
grep -n "Callouts after smart-merge:" plugins/local_conf/skills/finalize-branch/SKILL.md
```

Expected: one match in the Step 5 close-out block.

- [ ] **Step 5: Commit**

```bash
git add plugins/local_conf/skills/finalize-branch/SKILL.md
git commit -m "Add smart-merge tally to Step 5 close-out"
```

---

### Task 3: Update Phase 4 commit footer to include smart-merge count

**Files:**
- Modify: `plugins/local_conf/skills/finalize-branch/SKILL.md` (Phase 4 commit-message template, currently line 574 — will have drifted after Tasks 1 & 2).

- [ ] **Step 1: Locate the commit-message Callouts line**

```bash
grep -n "^Callouts: <X> to repo docs" plugins/local_conf/skills/finalize-branch/SKILL.md
```

Expected: one match.

- [ ] **Step 2: Read for context**

Use the `Read` tool on `plugins/local_conf/skills/finalize-branch/SKILL.md` with `offset: <line from Step 1 minus 5>, limit: 12`. Confirm the line matches the `old_string` below.

- [ ] **Step 3: Apply the footer update**

Use the `Edit` tool on `plugins/local_conf/skills/finalize-branch/SKILL.md`:

- old_string: `Callouts: <X> to repo docs, <Y> to inline code docs, <Z> already captured, <W> dismissed.`
- new_string: `Callouts: <X> to repo docs, <Y> to inline code docs, <Z> already captured, <W> dismissed[, <M> smart-merged].`

The bracketed `, <M> smart-merged` follows the same omission rule as the Step 5 close-out: omitted entirely when M is zero, included otherwise.

- [ ] **Step 4: Verify**

```bash
grep -n "smart-merged" plugins/local_conf/skills/finalize-branch/SKILL.md
```

Expected: at least three matches — one in the Step 5 close-out (from Task 2), one in the new commit-footer line (from this task), plus the multiple references inside the new `#### Smart-merge dedup` subsection (from Task 1).

- [ ] **Step 5: Commit**

```bash
git add plugins/local_conf/skills/finalize-branch/SKILL.md
git commit -m "Add smart-merge count to Phase 4 commit footer"
```

---

### Task 4: Add callout-awareness to session-retrospect

**Files:**
- Modify: `plugins/local_conf/skills/session-retrospect/SKILL.md` — append paragraph to Process step 1 (after line 28), add new `## Coordination with handle-callouts` section after `## Constraints`.

- [ ] **Step 1: Read the current Process step 1 + Constraints region for context**

Use the `Read` tool on `plugins/local_conf/skills/session-retrospect/SKILL.md` with `offset: 17, limit: 27`. Confirm the content matches what's referenced in the `old_string` blocks below.

- [ ] **Step 2: Append the pointer to Process step 1**

The cleanest anchor is the last bullet of step 1's nested list (`- Hooks`), which is unique in the file. The Edit appends the pointer paragraph after it without touching step 2.

Use the `Edit` tool on `plugins/local_conf/skills/session-retrospect/SKILL.md`:

- old_string:

  ````
       - `~/.claude/settings.json`
       - Hooks
  ````

- new_string:

  ````
       - `~/.claude/settings.json`
       - Hooks

     If a callout-worthy item surfaces (a discovery, decision, lesson learned, etc. that should outlive the session), route through `handle-callouts` rather than into the Retrospective narrative — see Coordination section below.
  ````

Note: the leading whitespace in both blocks is significant (5 spaces before `-`, matching the file's nested-list indentation). The new pointer paragraph is indented 5 spaces to align with the list's content level, then separated by a blank line so it renders as a sibling paragraph to the bulleted list.

- [ ] **Step 3: Verify the pointer landed**

```bash
grep -n "callout-worthy item surfaces" plugins/local_conf/skills/session-retrospect/SKILL.md
```

Expected: one match inside the Process step 1 block.

- [ ] **Step 4: Read end-of-file for context (Constraints + after)**

Use the `Read` tool on `plugins/local_conf/skills/session-retrospect/SKILL.md` with `offset: 36`. Confirm Constraints is the last section and ends around line 42.

- [ ] **Step 5: Append the new Coordination section**

Use the `Edit` tool on `plugins/local_conf/skills/session-retrospect/SKILL.md`:

- old_string:

  ````
  - If the session was very short or the user explicitly skips the analysis step, do not invent observations. Say so plainly.
  ````

- new_string:

  ````
  - If the session was very short or the user explicitly skips the analysis step, do not invent observations. Say so plainly.

  ## Coordination with `handle-callouts`

  The Retrospective section is for **experience reflection** — what went well, what didn't, how the session felt. Findings worth permanent record (discoveries, decisions, lessons learned, etc.) are **callouts**, not retrospective narrative; route those through the `handle-callouts` skill.

  Example: "We picked Tailwind over CSS modules" surfacing during retro — if it's reflection ("the team responded well"), it goes in the Retrospective; if it's the decision content ("Tailwind because of utility-class density"), it goes through `handle-callouts` as a Decision callout.
  ````

- [ ] **Step 6: Verify the new section landed**

```bash
grep -n "^## Coordination with .handle-callouts." plugins/local_conf/skills/session-retrospect/SKILL.md
```

Expected: one match near the end of the file.

- [ ] **Step 7: Commit**

```bash
git add plugins/local_conf/skills/session-retrospect/SKILL.md
git commit -m "$(cat <<'EOF'
Add callout-awareness to session-retrospect

Pointer in Process step 1 + new Coordination section delegating
callout-worthy items to handle-callouts. The Retrospective section
remains experience-reflection only; permanent-record findings go
through handle-callouts.
EOF
)"
```

---

### Task 5: Bump local_conf plugin version

**Files:**
- Modify: `plugins/local_conf/.claude-plugin/plugin.json`

Bump 1.5.0 → 1.6.0 (minor bump for new behavior in finalize-branch and session-retrospect).

- [ ] **Step 1: Read current version**

Use the `Read` tool on `plugins/local_conf/.claude-plugin/plugin.json`. Confirm `"version": "1.5.0"`. If it differs, reconcile manually before continuing.

- [ ] **Step 2: Apply the bump**

Use the `Edit` tool on `plugins/local_conf/.claude-plugin/plugin.json`:

- old_string: `"version": "1.5.0",`
- new_string: `"version": "1.6.0",`

- [ ] **Step 3: Verify**

```bash
grep '"version"' plugins/local_conf/.claude-plugin/plugin.json
```

Expected: `"version": "1.6.0",`.

- [ ] **Step 4: Commit**

```bash
git add plugins/local_conf/.claude-plugin/plugin.json
git commit -m "Bump local_conf to 1.6.0 for cross-skill dedup alignment"
```

---

### Task 6: Manual smoke test

**Files:** none (verification only).

These checks run from a fresh Claude Code session after the plugin reloads. The first three exercise the new finalize-branch behavior; the fourth exercises the session-retrospect coordination.

- [ ] **Step 1: Reload the plugin**

In a Claude Code session: `/reload-plugins` (or restart Claude Code).

- [ ] **Step 2: Smoke test — silent collapse on true duplicate**

In a working repo with multiple handoffs containing an *identical* callout (heading + body byte-for-byte equal after whitespace normalization), run `/finalize-branch`. At Phase 1 Step 5:

Expected:
- No smart-merge prompt fires.
- The Step 5 close-out shows the merge tally line: `Callouts after smart-merge: <N-1> (from <N> raw across <H> handoffs)` (since one duplicate was silently collapsed).
- The per-callout routing walk presents the deduped count, not the raw count.

- [ ] **Step 3: Smoke test — smart-merge prompt fires on body divergence**

Set up two handoffs where a callout has the same heading but bodies that differ on whitespace-stripped string equality (e.g., one body has an extra sentence the other doesn't). Run `/finalize-branch`.

Expected:
- Smart-merge prompt fires showing both source bodies and the proposed merged synthesis.
- All four shortcuts (`m`/`f`/`l`/`b`) are listed plus the `nuance:` option.
- Resolution category is one of "redundant / new info adds detail / partially wrong / contradicts" depending on the body difference.

Pick `m` (merge). Verify the merged routing item flows into the per-callout walk and routes per the user's choice.

- [ ] **Step 4: Smoke test — body-substance match across different headings**

Set up two handoffs where two callouts describe the same finding but with semantically different headings (e.g., `### Discovery — JWT clock skew tolerance varies by platform` and `### Caveat — JWT auth fails near midnight`). Run `/finalize-branch`.

Expected:
- Smart-merge prompt fires (body substance matched even though headings don't).
- The synthesis picks one canonical heading, drawing from both bodies.
- Picking `b` (keep both) routes them as separate items — recovery path for a false-positive match.

- [ ] **Step 5: Smoke test — transitive cluster of 3+ callouts**

Set up three or more handoffs with callouts that pairwise match. Run `/finalize-branch`.

Expected:
- A single prompt fires for the whole cluster (not three separate pairwise prompts).
- The synthesis draws from all source callouts.
- `f` and `l` resolve to the earliest and latest in the cluster, respectively.

- [ ] **Step 6: Smoke test — Phase 4 commit footer includes merge count**

Complete `/finalize-branch` through Phase 4 (final commit) on a branch where at least one smart-merge happened. Inspect the commit message.

Expected: `Callouts: ... dismissed, <M> smart-merged.` line present in the footer with the correct M count.

Re-run on a branch where zero merges happened. Expected: footer omits the `, <M> smart-merged` clause entirely.

- [ ] **Step 7: Smoke test — session-retrospect callout coordination**

In a session that produced a callout-worthy finding, invoke `/retrospect`. During the retrospective analysis:

Expected:
- Claude does not place the finding in the Retrospective narrative.
- Claude either invokes `handle-callouts` for the finding or surfaces it as a candidate change pointing to `handle-callouts`.
- The Retrospective narrative covers experience reflection only (what went well / didn't), not the finding itself.

- [ ] **Step 8: If any smoke test fails, document and fix**

Common failure modes:

- **Smart-merge prompt fires on true duplicates** — verify the trigger threshold table in the new subsection is preserved verbatim from the spec.
- **`m`/`f`/`l`/`b` shortcuts not recognized** — verify the prompt UX block in the new subsection includes the literal four-option block.
- **No merge tally in Step 5 close-out when merges happened** — verify Task 2's close-out edit landed.
- **No `, <M> smart-merged` in Phase 4 footer** — verify Task 3's footer edit landed.
- **Retrospect places callout-worthy findings in Retrospective narrative** — verify the Process step 1 pointer (Task 4 Step 2) and the new Coordination section (Task 4 Step 5) both landed.

Fix forward in a new commit; do not amend. Re-run the affected smoke test.

- [ ] **Step 9: Final verification**

```bash
git log --oneline main..HEAD
```

Expected: 6 commits — one per Task 1 through Task 5, plus the spec commit (Task 0, committed during brainstorming).

```bash
git diff main..HEAD --stat
```

Expected files changed:
- `docs/superpowers/specs/2026-04-30-cross-skill-callout-dedup-alignment-design.md` (new, from spec commit)
- `docs/superpowers/plans/2026-04-30-cross-skill-callout-dedup-alignment.md` (new, from this plan)
- `plugins/local_conf/skills/finalize-branch/SKILL.md` (Tasks 1-3)
- `plugins/local_conf/skills/session-retrospect/SKILL.md` (Task 4)
- `plugins/local_conf/.claude-plugin/plugin.json` (Task 5)

If anything else shows in the diff, reconcile before opening a PR.

---

## Notes

- **No automated tests.** Skills are markdown documents with no test harness. Verification is structural (grep for expected anchors) plus the live smoke tests in Task 6.
- **Order matters within Task 1.** The replacement `old_string` is unique only because of the surrounding paragraph context, so don't split Task 1 across multiple Edit calls — apply it as one replacement.
- **Tasks 2 and 3 follow Task 1.** Both target finalize-branch SKILL.md and rely on Task 1's structural anchors (close-out and commit-message template) being unchanged from their pre-Task-1 form. Don't reorder.
- **Task 4 is independent of Tasks 1-3.** Could be done in any order relative to them.
- **No `--no-verify` or `--amend`.** Per global rules. If a pre-commit hook fails, fix forward in a new commit.
