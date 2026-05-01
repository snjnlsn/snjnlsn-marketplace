# Callout Resolution Detection Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a pre-routing resolution filter so callouts that this branch fixed are dropped from `finalize-branch`'s routing walk instead of being awkwardly funneled through `dismiss`. The filter has two inputs: explicit `> Resolved: …` markers (heavy flow, written by `handle-callouts`) and a diff-evidence heuristic (lightweight scan, run by `finalize-branch`).

**Architecture:** Markdown-only edits across two SKILL.md files plus a plugin version bump. `handle-callouts/SKILL.md` gains a Mark resolved trigger list and a Mark resolved subflow that writes the marker. `finalize-branch/SKILL.md`'s Phase 1 Step 5 gains a `#### Resolution filter` sub-step between smart-merge dedup and configuration. The smart-merge sub-step is updated in three small ways: body normalization strips the marker before substance match; the prompt is skipped for clusters whose newest member is resolved; the prompt prepends a reopen-after-resolution note when applicable. Phase 1 Step 6 recommendation table folds "resolved" into the existing `remove` bullet. Phase 4 commit footer extends the `Callouts:` line with a resolved tally.

**Tech Stack:** Markdown for SKILL.md edits. JSON for `plugin.json` version bump.

**Spec:** `docs/superpowers/specs/2026-04-30-callout-resolution-detection-design.md`

**Depends on:** `docs/superpowers/plans/2026-04-30-session-handoff-callout-delegation.md` (the delegation work bumps `local_conf` to `1.7.0`; this plan bumps to `1.8.0`). The two plans can ship in either order in terms of behavior — they don't share file regions — but the version bump assumes Plan 1 lands first.

---

## File structure

**Modify:**
- `plugins/local_conf/skills/handle-callouts/SKILL.md` — extend `## When to use` with Mark resolved triggers; add a new `## Mark resolved subflow` section after `## Authoring flow`.
- `plugins/local_conf/skills/finalize-branch/SKILL.md` — add `#### Resolution filter` sub-step after `#### Smart-merge dedup` in Phase 1 Step 5; add three small notes inside `#### Smart-merge dedup` (body normalization, skip-prompt for resolved, reopen-after-resolution); extend the Phase 1 Step 6 recommendation bullet; extend the Phase 4 commit footer template.

**Bump:**
- `plugins/local_conf/.claude-plugin/plugin.json` — version `1.7.0` → `1.8.0` (assuming Plan 1 has landed; otherwise bump from current).

**Test approach:** No automated harness (skills are markdown). Each task ends with a Read-based structural verification. A final manual smoke test in Task 8 exercises both the heavy flow and the lightweight heuristic in a fresh Claude Code session.

---

### Task 1: Extend handle-callouts' "When to use" with Mark resolved triggers

**Files:**
- Modify: `plugins/local_conf/skills/handle-callouts/SKILL.md` — `## When to use` section.

The current section lists two trigger groups (explicit phrases for new callouts, proactive recognition). Add a third group for Mark resolved triggers — closing out an existing callout, not creating a new one.

- [ ] **Step 1: Read the current section**

Use `Read` on `plugins/local_conf/skills/handle-callouts/SKILL.md` with `offset: 10, limit: 18`. Confirm the section matches the `old_string` below; if line numbers drifted, anchor by the `## When to use` heading.

- [ ] **Step 2: Apply the edit**

Use the `Edit` tool on `plugins/local_conf/skills/handle-callouts/SKILL.md`:

- old_string:

  ````
  Also activate proactively when the session produces:

  - A non-obvious behavior just confirmed (especially against a hypothesis)
  - A deliberate trade-off accepted between two approaches
  - A constraint that surprised the session (rate limit, schema gotcha, version pin, etc.)
  - A finding that explains repeated behavior elsewhere
  - A decision that closes off an alternative explicitly considered

  Propose once per moment. If declined, don't re-propose for the same finding — the user can always trigger explicitly later.
  ````

- new_string:

  ````
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
  ````

- [ ] **Step 3: Verify**

Re-Read the section. Confirm the Mark resolved triggers paragraph appears between the proactive list and the "Propose once per moment" closer. The two existing trigger lists are unchanged.

- [ ] **Step 4: Commit**

```bash
git add plugins/local_conf/skills/handle-callouts/SKILL.md
git commit -m "handle-callouts: add Mark resolved triggers to When-to-use"
```

---

### Task 2: Add the Mark resolved subflow section to handle-callouts

**Files:**
- Modify: `plugins/local_conf/skills/handle-callouts/SKILL.md` — insert new `## Mark resolved subflow` section between `## Authoring flow` and `## Writing style`.

The new section documents the operational steps for the heavy flow: identifying the target callout (working handoff first, then read-only scan of older handoffs), composing and writing the marker, and edge-case handling.

- [ ] **Step 1: Read the seam**

Use `Read` on `plugins/local_conf/skills/handle-callouts/SKILL.md` with `offset: 110, limit: 8`. Confirm the section ends with step 7 (the `## Authoring flow`'s "Report" line — `Saved as ### <type> — <title> to <handoff path>.`) followed by `## Writing style`.

- [ ] **Step 2: Apply the insert via `insert_after_symbol` is N/A here (markdown — no symbols), so use `Edit`**

Use the `Edit` tool on `plugins/local_conf/skills/handle-callouts/SKILL.md`:

- old_string:

  ````
  7. **Report.** One line — `Saved as ### <type> — <title> to <handoff path>.`

  ## Writing style
  ````

- new_string:

  ````
  7. **Report.** One line — `Saved as ### <type> — <title> to <handoff path>.`

  ## Mark resolved subflow

  Activated by the explicit and proactive Mark resolved triggers in `## When to use`. Marks an existing callout resolved by writing a `> Resolved: …` blockquote line into a callout body in the working handoff. Older handoffs are read-only — never edited mid-session.

  ### 1. Identify the target callout

  - Scan the working handoff first for a heading-text match against the user's reference.
  - If no match in the working handoff, scan the branch's older handoffs read-only via `git log <base>..HEAD --name-only --pretty=format: -- docs/handoffs/`. Read each candidate; look for matching headings or body-substance matches.
  - Surface candidates: `Did you mean ### Known issue — JWT clock skew … (in <handoff path>)? confirm / that's a different one / cancel.`
  - If zero candidates surface, ask the user to name the heading or paste the body.

  ### 2. Compose the marker

  Format: `> Resolved: <freeform note + optional commit ref>` blockquote line.

  - Pull resolution context from the user's framing or the most recent commit on the branch (proactive case).
  - Bare `> Resolved` (no payload) is allowed.
  - Show the proposed payload to the user and let them edit before write.

  ### 3. Confirm and write

  - **Explicit user trigger with target clear** → auto-write with one-line report (mirrors the authoring flow's explicit-typed shortcut).
  - **Proactive recognition or any ambiguity** → show the proposed marker + target heading; confirm before write.

  ### 4. Apply the write

  - **Target in the working handoff:** insert `> Resolved: …` as the first body line under the existing callout heading. Refresh `**Last updated:**` timestamp.
  - **Target in an older handoff:** write a *resolution-only callout* to the working handoff — heading copied verbatim from the older callout, body containing only the marker line. Smart-merge clusters them at branch end via heading match; cluster resolution is determined by the newest member (this resolution-only callout).

  ### 5. Report

  One line: `Marked ### <heading> resolved in <handoff path>.`

  ### Dedup interaction

  - Resolution-only callouts skip the authoring flow's dedup check. `finalize-branch`'s smart-merge handles the cluster at branch end.
  - Marking resolved a callout that already has a marker → prompt: `replace / keep existing / cancel`.

  ### Edge cases

  - **Reversing a resolution mid-session.** User says "actually that came back." Edit the marker line out, or write a new active callout in the working handoff if the resolution-only one is the only record. Smart-merge will treat the cluster as active per latest-wins.
  - **Resolution-only callout has no source heading match in older handoffs.** Smart-merge won't cluster it. Surface a warning at write time: `no matching active callout found in branch handoffs — this won't count as a resolution at finalize-branch time. Continue?`
  - **Mark resolved on a callout type the heuristic narrows out** (Discovery, Decision, Lesson learned). Allowed — the marker writes; `finalize-branch` silently drops at routing time.

  ## Writing style
  ````

- [ ] **Step 3: Verify**

Re-Read `handle-callouts/SKILL.md` around the insertion. Confirm:
- `## Authoring flow`'s 7 steps are intact.
- New `## Mark resolved subflow` section follows immediately.
- New section has 5 numbered subsections (Identify, Compose, Confirm, Apply, Report) plus Dedup interaction and Edge cases.
- `## Writing style` follows immediately after the new section, unchanged.

- [ ] **Step 4: Commit**

```bash
git add plugins/local_conf/skills/handle-callouts/SKILL.md
git commit -m "handle-callouts: add Mark resolved subflow"
```

---

### Task 3: Add the resolution filter sub-step to finalize-branch Phase 1 Step 5

**Files:**
- Modify: `plugins/local_conf/skills/finalize-branch/SKILL.md` — insert new `#### Resolution filter` sub-step between `#### Smart-merge dedup` and `#### Configuration`.

The resolution filter splits merged clusters into resolved (dropped) and active (passed downstream). It runs the diff-evidence heuristic on issue-shaped active clusters.

- [ ] **Step 1: Read the seam**

Use `Read` on `plugins/local_conf/skills/finalize-branch/SKILL.md` with `offset: 246, limit: 8`. Confirm `#### Smart-merge dedup` ends with the `**Output:**` paragraph and `#### Configuration` follows immediately.

- [ ] **Step 2: Apply the insert**

Use the `Edit` tool on `plugins/local_conf/skills/finalize-branch/SKILL.md`:

- old_string:

  ````
  **Output:** a list of merged routing items, each carrying its origin metadata (which handoffs it came from, which match category triggered the merge). The per-callout routing walk in subsequent sub-sections consumes this list as it does today.

  #### Configuration
  ````

- new_string:

  ````
  **Output:** a list of merged routing items, each carrying its origin metadata (which handoffs it came from, which match category triggered the merge). Resolved clusters (see `#### Resolution filter`) are tagged at this point and pass through; active clusters flow into the per-callout routing walk in subsequent sub-sections.

  #### Resolution filter

  Resolved callouts skip the routing walk entirely — there's no current state to document. The filter runs against the merged clusters output by smart-merge dedup, splits them into resolved and active, and feeds only active clusters into Configuration and the per-callout walk.

  **Resolution marker detection regex:**

  ```
  ^\s*>\s*Resolved\b\s*[:—\-]?\s*(.*?)\s*$
  ```

  Captures an optional payload (commit ref, freeform note). A bare `> Resolved` matches with empty capture. Markers are written by `handle-callouts`' Mark resolved subflow.

  **Filter order:**

  1. **Explicit markers first.** Any cluster whose newest member has a `> Resolved: …` marker → silently dropped from the walk; counted toward the resolved tally. (Smart-merge already skipped its prompt for these clusters — see "Skip-prompt for resolved clusters" in `#### Smart-merge dedup`.)
  2. **Heuristic on remaining clusters.** For each active cluster whose type is **issue-shaped** (Known issue, Caveat, Gotcha, Edge case) or **Complexity**, run the diff-evidence scan.

  The heuristic does not run on Discovery / Decision / Lesson learned — these atemporal types have no clear diff signal for resolution. Explicit markers still work for them via the heavy flow.

  **Diff-evidence scan** (per candidate cluster):

  - Extract file paths and code symbols from the body. Path candidates: tokens matching path-shaped strings (`lib/...`, `test/...`, `src/...`, etc.). Symbol candidates: capitalized identifiers, dotted forms (`Auth.JWT.verify/2`), function-arity forms.
  - Cross-reference against `git diff <base>..HEAD --name-only` and `git diff <base>..HEAD --stat`.
  - **Fire** if a mentioned path or symbol is touched **and** the diff in that area exceeds the threshold: more than 10 lines changed (added + removed combined), or any new test files added under the path.

  **Heuristic prompt:**

  ```
  Possible resolution detected — Known issue 3 from <handoff path>

    ### Known issue — JWT clock skew tolerance varies by platform

    > Tokens minted on macOS fail validation on Linux when …

    Evidence: lib/auth/jwt.ex (+47/-12), test/auth/jwt_test.exs (new file, 38 lines).

    Mark resolved (y) / route normally (n) / show diff (d)
  ```

  `y` → drop, count toward resolved. `n` → continue into the routing walk. `d` → dump the matched diff hunks, then re-prompt.

  False-positive cost is one prompt; false negatives fall through to the routing walk where the user can `dismiss`.

  **Edge cases:**

  - **Resolution-only callout in the working handoff with no cluster match across older handoffs.** Smart-merge produces a single-member cluster containing only the resolution marker. Surface a warning here: `resolution-only callout <heading> in <working handoff> doesn't match any active callout in the branch — wasn't counted as resolved`. User can dismiss and proceed.
  - **Marker references a commit that's been rebased away.** Note becomes stale but the marker still works as a resolution signal. No special handling.
  - **Multiple resolution markers in one body.** Last one wins (most recent edit). All are stripped during smart-merge body normalization.
  - **Branch with no diff** (rare; user finalizes a no-op branch). Heuristic never fires; explicit markers still work.

  **Output:** a tally of resolved clusters (counted in the Phase 4 commit footer; not routed) and a list of active clusters that flow into Configuration and the per-callout routing walk.

  #### Configuration
  ````

- [ ] **Step 3: Verify**

Re-Read around the insertion. Confirm:
- `#### Smart-merge dedup`'s **Output** paragraph now ends with the resolved-clusters cross-reference.
- New `#### Resolution filter` sub-step appears with all six headings (regex, Filter order, Diff-evidence scan, Heuristic prompt, Edge cases, Output).
- `#### Configuration` follows immediately, unchanged.

- [ ] **Step 4: Commit**

```bash
git add plugins/local_conf/skills/finalize-branch/SKILL.md
git commit -m "finalize-branch: add resolution filter sub-step to Phase 1 Step 5"
```

---

### Task 4: Smart-merge integration updates

**Files:**
- Modify: `plugins/local_conf/skills/finalize-branch/SKILL.md` — three small edits inside `#### Smart-merge dedup`.

Three independent updates inside the smart-merge section:
- (4a) Body normalization strips resolution markers before substance match.
- (4b) Skip-prompt note: clusters whose newest member is resolved skip the smart-merge prompt and pass to the resolution filter.
- (4c) Reopen-after-resolution note prepends a history line to the prompt when applicable.

- [ ] **Step 1: Read smart-merge dedup section**

Use `Read` on `plugins/local_conf/skills/finalize-branch/SKILL.md` with `offset: 183, limit: 70`. Get the section in your head before editing.

- [ ] **Step 2: Edit 4a — body normalization on body-substance match**

Use the `Edit` tool:

- old_string:

  ````
  - **Body substance match.** Semantic judgment — do the two callouts describe the same finding, even with different headings?
  ````

- new_string:

  ````
  - **Body substance match.** Semantic judgment — do the two callouts describe the same finding, even with different headings? **Normalization:** strip lines matching `^\s*>\s*Resolved\b.*$` before comparing — the resolution marker is metadata, not content, and including it would distort the substance match.
  ````

- [ ] **Step 3: Edit 4b — skip-prompt for resolved clusters**

Use the `Edit` tool. Insert a new paragraph immediately after the trigger threshold table, before "**Resolution categories**":

- old_string:

  ````
  | Body-substance match (semantic judgment), heading diverges | Smart-merge prompt |

  **Resolution categories** (used to draft the synthesis):
  ````

- new_string:

  ````
  | Body-substance match (semantic judgment), heading diverges | Smart-merge prompt |

  **Skip-prompt for resolved clusters.** Before deciding whether the prompt fires, examine the newest cluster member's body for a resolution marker (regex: `^\s*>\s*Resolved\b.*$`; see `#### Resolution filter` for full semantics). If present, the cluster is resolved — skip the smart-merge prompt entirely and pass the cluster to the resolution filter unchanged. If absent, the prompt fires per the trigger threshold above.

  **Resolution categories** (used to draft the synthesis):
  ````

- [ ] **Step 4: Edit 4c — reopen-after-resolution note**

Use the `Edit` tool. Insert a new paragraph immediately after the smart-merge prompt UX code block (after the line about single-letter shortcuts), before "**Atemporal rewrite timing.**":

- old_string:

  ````
  Single-letter shortcuts (`m`/`f`/`l`/`b`) avoid collision with the existing routing UX (`a`/`c`/`r`/`d`).

  **Atemporal rewrite timing.**
  ````

- new_string:

  ````
  Single-letter shortcuts (`m`/`f`/`l`/`b`) avoid collision with the existing routing UX (`a`/`c`/`r`/`d`).

  **Reopen-after-resolution.** When the newest cluster member is unmarked but at least one older member has a resolution marker, the smart-merge prompt prepends a history note before the source excerpts:

  ```
  Note: this callout was marked resolved in handoff <B> (> Resolved: switched to JWT v2 …)
  but is active in handoff <C>. Treating as active.
  ```

  The synthesis draft can fold the resolved-then-reopened arc into the body when relevant. User can `nuance` if the framing is off. No new markup required — absence of a resolution marker on a newer cluster member implies reopened.

  **Atemporal rewrite timing.**
  ````

- [ ] **Step 5: Verify**

Re-Read `#### Smart-merge dedup` end-to-end. Confirm:
- Body substance match line now ends with the **Normalization:** clause.
- A new **Skip-prompt for resolved clusters** paragraph appears between trigger threshold and resolution categories.
- A new **Reopen-after-resolution** paragraph appears between the prompt UX shortcuts line and **Atemporal rewrite timing**.
- All other paragraphs (transitive clusters, large clusters, nuance, output) are intact.

- [ ] **Step 6: Commit**

```bash
git add plugins/local_conf/skills/finalize-branch/SKILL.md
git commit -m "finalize-branch: smart-merge integration with resolution markers"
```

---

### Task 5: Phase 1 Step 6 — fold "resolved" into the `remove` recommendation

**Files:**
- Modify: `plugins/local_conf/skills/finalize-branch/SKILL.md` — `**Recommendation per match:**` list inside `### Step 6 — In-code reference cleanup`.

A code comment referencing a callout that resolved should recommend `remove` (the original concern is gone). Fold "resolved" into the existing bullet that already covers `dismissed` and `already-captured`.

- [ ] **Step 1: Read the recommendation list**

Use `Read` on `plugins/local_conf/skills/finalize-branch/SKILL.md` with `offset: 457, limit: 10`. Confirm the four-bullet list matches the `old_string` below; anchor by the `**Recommendation per match:**` header if line numbers drifted.

- [ ] **Step 2: Apply the edit**

Use the `Edit` tool:

- old_string:

  ````
  - If the referenced callout was `dismissed` or `already-captured` → recommend `remove` (the original reference is now noise).
  ````

- new_string:

  ````
  - If the referenced callout was `dismissed`, `already-captured`, or **resolved** in the resolution filter → recommend `remove` (the original concern is gone or already documented elsewhere).
  ````

- [ ] **Step 3: Verify**

Re-Read the recommendation list. Confirm the bullet now includes `resolved`; the other three bullets are unchanged.

- [ ] **Step 4: Commit**

```bash
git add plugins/local_conf/skills/finalize-branch/SKILL.md
git commit -m "finalize-branch: Step 6 recommends remove for resolved callout refs"
```

---

### Task 6: Phase 4 — extend the commit footer template

**Files:**
- Modify: `plugins/local_conf/skills/finalize-branch/SKILL.md` — `Callouts:` line in the Phase 4 Step 4 commit message template.

Add a `<V> resolved by this branch` clause, omitted when zero (matching the existing `[, <M> smart-merged]` pattern).

- [ ] **Step 1: Read the template**

Use `Read` on `plugins/local_conf/skills/finalize-branch/SKILL.md` with `offset: 626, limit: 25`. Confirm the template matches the `old_string` below.

- [ ] **Step 2: Apply the edit**

Use the `Edit` tool:

- old_string:

  ````
  Callouts: <X> to repo docs, <Y> to inline code docs, <Z> already captured, <W> dismissed[, <M> smart-merged].
  ````

- new_string:

  ````
  Callouts: <X> to repo docs, <Y> to inline code docs, <Z> already captured, <W> dismissed[, <V> resolved by this branch][, <M> smart-merged].
  ````

- [ ] **Step 3: Verify**

Re-Read the template block. Confirm the `Callouts:` line now has the new optional clause and the surrounding lines (`docs: finalize <branch-name>`, `Inline code docs:`, `Repo docs:`, `Removed <N>...`, `In-code references:`) are unchanged.

- [ ] **Step 4: Commit**

```bash
git add plugins/local_conf/skills/finalize-branch/SKILL.md
git commit -m "finalize-branch: add resolved tally to Phase 4 commit footer"
```

---

### Task 7: Bump local_conf plugin version

**Files:**
- Modify: `plugins/local_conf/.claude-plugin/plugin.json` — `version` field.

User-visible behavior changes (resolution filter + heavy flow). Minor bump.

- [ ] **Step 1: Read the file**

Use `Read` on `plugins/local_conf/.claude-plugin/plugin.json`. Confirm `"version": "1.7.0"` (assumes Plan 1 has landed; otherwise reconcile by reading the current value and bumping by one minor over it).

- [ ] **Step 2: Apply the edit**

Use the `Edit` tool on `plugins/local_conf/.claude-plugin/plugin.json`:

- old_string: `"version": "1.7.0",`
- new_string: `"version": "1.8.0",`

- [ ] **Step 3: Verify**

Re-Read the file. Confirm the version is now `1.8.0` and the JSON is otherwise valid and unchanged.

- [ ] **Step 4: Commit**

```bash
git add plugins/local_conf/.claude-plugin/plugin.json
git commit -m "local_conf: bump to 1.8.0"
```

---

### Task 8: Manual smoke test (no commit)

This task is a hands-on verification in a fresh Claude Code session. It does not produce file changes; it confirms both the heavy flow and lightweight heuristic behave as documented.

- [ ] **Step 1: Cross-file coherence read**

Open `handle-callouts/SKILL.md` and `finalize-branch/SKILL.md` side by side. Verify:
- `handle-callouts`' Mark resolved triggers reference `## Mark resolved subflow`, and that section exists with its 5 numbered steps + edge cases.
- `finalize-branch`'s `#### Resolution filter` references `handle-callouts`' Mark resolved subflow and the smart-merge skip-prompt logic, and both exist.
- The smart-merge skip-prompt note references `#### Resolution filter`, which exists immediately after smart-merge dedup.
- The Phase 1 Step 6 recommendation bullet includes `resolved`.
- The Phase 4 commit footer includes `<V> resolved by this branch`.

- [ ] **Step 2: Heavy flow — explicit trigger**

Start a fresh session in a worktree with at least one Known issue callout already in the working handoff. Say: "mark that JWT skew Known issue resolved — switched to JWT v2 in commit abc123."

Expected: `handle-callouts` Mark resolved subflow runs, identifies the target by heading match in the working handoff, writes `> Resolved: switched to JWT v2 in commit abc123.` as the first body line under the heading, refreshes `**Last updated:**`, reports.

- [ ] **Step 3: Heavy flow — older-handoff target**

Start a session in a branch with a callout in an older handoff (not the working one). Say: "mark the JWT skew issue from the earlier handoff resolved."

Expected: `handle-callouts` scans older handoffs read-only, surfaces the candidate, on confirm writes a resolution-only callout to the working handoff with the heading copied verbatim and body containing only the marker line.

- [ ] **Step 4: Lightweight heuristic at finalize-branch**

In a branch with a Known issue callout that mentions a file path the branch's diff has substantially modified (>10 lines changed or new tests added), run `/finalize-branch`. At Phase 1 Step 5, after smart-merge dedup, the resolution filter should fire the heuristic prompt for the matching cluster.

Expected prompt format: `Possible resolution detected — Known issue ... Evidence: <path> (+N/-M)... Mark resolved (y) / route normally (n) / show diff (d)`.

Pick `y` and continue. Confirm the cluster is dropped from the per-callout walk; the Step 5 close-out tally and the Phase 4 commit footer both show a resolved count.

- [ ] **Step 5: Reopen-after-resolution prompt**

Set up two handoffs: an older one with a callout marked resolved, a newer one with the same callout active (no marker). Run `/finalize-branch`. The smart-merge prompt for the active cluster should prepend the reopen note.

Expected note: `Note: this callout was marked resolved in handoff <older> (> Resolved: ...) but is active in handoff <newer>. Treating as active.`

- [ ] **Step 6: Phase 1 Step 6 reference cleanup**

In a branch where a code comment references a callout that resolved (heavy flow or heuristic), run `/finalize-branch`. At Phase 1 Step 6, the recommendation for that comment should be `remove`, not `redirect` (since there's no destination doc) and not `inline` (since the concern is gone).

If any of these checks fail, the implementation diverged from the spec — re-open the affected task and fix.
