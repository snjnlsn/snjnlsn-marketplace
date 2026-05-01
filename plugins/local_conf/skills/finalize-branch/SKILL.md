---
name: finalize-branch
description: Finalize a feature branch before merge — review the branch's handoffs and changes, audit and update inline code docs (`@moduledoc`, `@doc`, `@spec` for Elixir; equivalents elsewhere), audit and update `docs/`/README/CLAUDE.md as relevant, delete the branch's handoff documents, and produce one final commit. Use when the user says "finalize this branch", "wrap up this branch", "I'm done with this branch", "ready to merge this branch", or runs `/finalize-branch`. Manual invocation only.
---

# Finalize Branch

Walk a five-phase pipeline that brings inline code docs and project docs current with a feature branch's changes, removes the branch's session handoff documents, and produces one final commit.

The skill is interactive throughout. Each phase has an explicit user approval gate. A later phase cannot begin until the previous phase is fully approved. State carried between phases lives only in conversation context — cancellation means start over (with optional stash-based resume of applied edits).

## When to use

Activate when the user says:

- "finalize this branch" / "wrap up this branch"
- "I'm done with this branch" / "ready to merge this branch"
- runs `/finalize-branch`

## Source-of-truth precedence

When handoffs and code disagree, resolve in this order: **code (current) > newest handoff > older handoffs (newer wins among handoffs)**. Code is what actually runs; handoffs are intent.

## Documentation language and tone

The inline-code-documentation and repo-documentation phases produce written content. Apply these rules to every proposed `@moduledoc`/`@doc`/docstring/JSDoc and every prose edit to `docs/`/`README.md`/`CLAUDE.md`.

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

Every premature exit — pre-flight refusal, branch health failure, mid-phase error, user cancellation, hook failure — must end with a brief summary that names *what's wrong* and *what to do next*. The user should never have to read scrollback to figure out the recovery action. When applied doc edits exist in the working tree at exit time, run the "Cancellation retention" prompt below.

## Phase 0 — Resume detection, pre-flight gate, branch health checks

### Step 1 — Resume detection

Run `git stash list` and look for entries whose message matches `finalize-branch:<current-branch>:`. If any matches:

> "Found N pending finalize-branch stash(es) for branch `<branch>`:
>   - `<stash-ref>` (created `<ISO-timestamp>`, N files)
>
> Apply and resume? (`apply` / `skip` — leave stashed for later / `discard` — drop the stash)"

- **`apply`** — Run `git status --porcelain` first. If non-empty, refuse: "Working tree has uncommitted changes unrelated to the resume stash. Commit, stash separately, or discard them with `git stash` / `git restore`, then re-run `/finalize-branch`. The finalize-branch resume stash is preserved." On clean tree, run `git stash apply <stash-ref>`. If apply succeeds without conflict, drop the stash with `git stash drop <stash-ref>` and proceed. If apply produces a merge conflict, abort the apply, leave the stash intact, and refuse with: "Resume stash conflicts with current branch state at `<paths>`. The stash is preserved; resolve by manually applying with `git stash apply <stash-ref>` and reconciling conflicts, then re-run." After a clean apply, the working tree is dirty *only* with the stash contents — proceed to step 2 with the dirty-tree pre-flight check **bypassed for this run only**.
- **`skip`** — continue with normal pre-flight (which will refuse if the working tree is dirty for any reason).
- **`discard`** — `git stash drop <stash-ref>`, then continue with normal pre-flight.

If multiple matching stashes exist (rare — usually means cancellations across multiple sessions), list all and prompt the user to pick which to apply (or `apply all` / `discard all`).

### Step 2 — Pre-flight (refuses to start)

Each refusal includes both *what's wrong* and *what to do next*:

1. **Dirty working tree** — `git status --porcelain` non-empty → refuse: "Working tree has uncommitted changes. Commit, stash, or discard them with `git stash` / `git restore`, then re-run `/finalize-branch`." **Bypassed** if step 1 successfully applied a resume stash on a previously-clean tree.
2. **No commits ahead of base** — Detect base branch via `git symbolic-ref refs/remotes/origin/HEAD`. Fallback chain: `main` → `master` → ask user. If `git rev-list --count <base>..HEAD` is `0` → refuse: "No commits ahead of `<base>`. Nothing to finalize. Make at least one commit on a feature branch first, or switch to the branch you intended."
3. **On the base branch** — if current branch *is* the base (e.g. `main` with commits ahead of `origin/main`), advocate first:
   > "You're finalizing directly on `main`. For most work, branching this off (`git switch -c <feature>`) and merging via PR gives you isolation, code review, and a cleaner history. Continue on `main` anyway? (y/N)"
   - On `N`, exit with: "Exited without finalizing. Recommended: `git switch -c <feature-name>` to move your commits onto a feature branch, then re-run `/finalize-branch` from there."
   - On `y`, proceed.
4. **Detached HEAD** — `git symbolic-ref --quiet HEAD` returns non-zero → refuse: "Not on a branch (detached HEAD). Checkout a branch with `git switch <branch>` or create one with `git switch -c <new-branch>`, then re-run."
5. **Mid-rebase/merge/cherry-pick** — check for `.git/rebase-merge/`, `.git/rebase-apply/`, `.git/MERGE_HEAD`, `.git/CHERRY_PICK_HEAD`, `.git/REVERT_HEAD`. Any found → refuse: "A git operation is in progress (`<operation-name>`). Resolve or abort it (`git rebase --continue` / `--abort`, `git merge --continue` / `--abort`, `git cherry-pick --continue` / `--abort`), then re-run."

### Step 3 — Branch health checks

Auto-detect a project-defined pre-commit alias or pipeline. Search in this order:

1. `mix.exs` aliases — look for `precommit`, `check`, `quality`, `verify`
2. `package.json` scripts — look for `precommit`, `check`, `verify`, `lint && test`
3. `Makefile` targets — `make check`, `make precommit`, `make verify`
4. `CLAUDE.md` for project-specific "before committing" / "pre-commit" guidance
5. `README.md` for project-specific guidance — typically in "Development", "Contributing", "Testing", or "Getting started" sections; commands tied to "before committing", "pre-commit", "checks", "verify", "test"
6. Language-default fallbacks:
   - Elixir: `mix format --check-formatted && mix compile --warnings-as-errors && mix test`
   - JS/TS: `npm test`
   - Python: `pytest`

Report what you found and ask: `run` / `edit` / `skip`.

- **`run`** — execute. On non-zero exit: halt with the failed command, stdout/stderr summary, and recovery hint: "Branch health checks failed: `<command>` exited <code>. Failures look like: `<one-line summary of the most relevant error>`. Address the failures and re-run `/finalize-branch`. To bypass intentionally, re-run and answer `skip` at the checks prompt."
- **`edit`** — user provides a replacement command, then run.
- **`skip`** — record that checks were skipped; final commit footer notes `(branch health checks skipped)`.

If nothing is detected, ask: "Provide a pre-commit alias name (e.g., `mix precommit`) or a list of checks to run, or `skip`." **Do not** create new aliases in `mix.exs`/`package.json` — out of scope.

## Phase 1 — Audit & clarifying questions

### Step 1 — Confirm the handoff list

Resolve via:

```
git log --name-only --pretty=format: <base>..HEAD -- docs/handoffs/
```

Show the resolved list, sorted oldest → newest. Ask: "These are the handoffs I attribute to this branch. Add, remove, or proceed? (`proceed` / `edit`)".

If zero handoffs returned, report: "No handoffs found for this branch — context will come from commits/diffs only" and proceed.

### Step 2 — Build the source-of-truth picture (silent)

- Read `git diff <base>..HEAD` and `git diff --stat <base>..HEAD`.
- Read each confirmed handoff in chronological order (older → newer); later overrides earlier on conflicts.
- Map code-level facts (modules added/removed/renamed, public API changes, schema/migration changes) and narrative-level facts (intent, rationale, open questions).
- Source-of-truth precedence: **code > newest handoff > older handoffs**.

### Step 3 — Identify divergences and ambiguities

Produce clarifying questions in these categories:

- **Handoff-vs-code conflicts** — e.g., "Handoff `2026-04-15-...md` says module `Foo.Bar` was removed, but it still exists in the code. Reverted, or stale handoff?"
- **Public API without docs** — e.g., "New public function `Acme.Users.invite/2` has no `@doc`. Draft from the handoff narrative, or specific phrasing?"
- **Stale-but-relevant docs** — e.g., "`docs/architecture.md` says 'all auth flows through `Auth.Session`' but this branch added `Auth.OAuth`. Update the arch doc?"
- **README/CLAUDE.md candidates** — e.g., "Branch added a new mix task `mix acme.seed`. Mention in `README.md`'s 'Setup' section?"
- **Open questions in handoffs** — e.g., "Handoff `...md` left an open question: '<question>'. Resolved, deferred, or still open?"

Each question carries a recommended answer.

### Step 4 — Interactive question loop

Present questions in chunks of 3–5 at a time. Per-question response options:

- `accept` — use the recommended answer
- `change: <text>` — override
- `skip` — don't act on this in later phases

Anything unaddressed in a chunk defaults to `accept`. The user may add free-form clarifications between chunks. After all chunks are processed, summarize the resolved picture. If Steps 5 and 6 will both be silent (no matching callouts and no deletion list), Step 4 prompts: "Proceed to inline code documentation?" Otherwise, Step 4 hands off silently and the gate prompt is owned by whichever of Step 5 or Step 6 runs last.

If new questions arise during resolution (rare), append and run another mini-chunk.

### Step 5 — Callout extraction & routing

Runs only if at least one handoff in the confirmed deletion list contains a matching callout heading. Otherwise silent.

#### Pattern matching

A callout is a Markdown heading at any level whose text matches:

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

Each "X / Y" entry above expands to two literal patterns in the matcher's list. Pattern matching is case-insensitive on the keyword. Numbering after the keyword is optional and not anchored to any sequence — `## Discoveries`, `### Discovery — title`, `### Discovery 1 — title`, `#### Decision: title`, `### Edge cases — empty input`, and a bare `### Known issues` all match.

Multi-word patterns (`Lesson learned`, `Known issue`, `Edge case`) match literally as space-separated tokens at the heading-text start; internal whitespace is not collapsed.

Matches require parsed Markdown headings, not raw text — a literal `### Discovery` line inside a fenced code block is ignored. Plain prose mentions ("see Discovery 4") are ignored.

#### Smart-merge dedup

Callouts that match across (or within) handoffs are detected and resolved via a smart-merge prompt before the per-callout routing walk. This sub-step runs immediately after pattern matching; the per-callout walk then operates on the resolved list.

**Match signals.** A pair of callouts triggers as a match if either of these fires:

- **Heading text match.** Normalized canonical key: lowercase, collapse whitespace, strip leading numbering (`Discovery N —`). The heading text is the anchor, not the number; renumbering between handoffs is OK.
- **Body substance match.** Semantic judgment — do the two callouts describe the same finding, even with different headings? **Normalization:** strip lines matching `^\s*>\s*Resolved\b.*$` before comparing — the resolution marker is metadata, not content, and including it would distort the substance match.

**Trigger threshold:**

| Match shape | Behavior |
|---|---|
| **True duplicate**: heading matches by canonical normalization AND body matches by string equality after collapsing whitespace runs and trimming leading/trailing whitespace (no semantic judgment) | Silent collapse, first wins (no prompt) |
| Heading match, body diverges (whitespace-stripped string inequality) | Smart-merge prompt |
| Body-substance match (semantic judgment), heading diverges | Smart-merge prompt |

**Skip-prompt for resolved clusters.** Before deciding whether the prompt fires, examine the newest cluster member's body for a resolution marker (regex: `^\s*>\s*Resolved\b.*$`; see `#### Resolution filter` for full semantics). If present, the cluster is resolved — skip the smart-merge prompt entirely and pass the cluster to the resolution filter unchanged. If absent, the prompt fires per the trigger threshold above.

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

**Reopen-after-resolution.** When the newest cluster member is unmarked but at least one older member has a resolution marker, the smart-merge prompt prepends a history note before the source excerpts:

```
Note: this callout was marked resolved in handoff <B> (> Resolved: switched to JWT v2 …)
but is active in handoff <C>. Treating as active.
```

The synthesis draft can fold the resolved-then-reopened arc into the body when relevant. User can `nuance` if the framing is off. No new markup required — absence of a resolution marker on a newer cluster member implies reopened.

**Atemporal rewrite timing.** The synthesis applies the atemporal-rewrite rules (see "Content transformation for `add-to-repo-docs`" below: strip temporal markers, strip branch/PR refs, keep code/data fences verbatim, promote heading) **before** showing the prompt. So the merged routing item is ready to flow into the routing walk. `f` and `l` route the original heading + body verbatim; atemporal rewrite still applies at routing time as today. Only `m` benefits from the pre-prompt rewrite.

**Transitive clusters.** When 3+ callouts pairwise match (A↔B and B↔C both match), treat them as one cluster with one prompt and one synthesis drawing from all sources. The `f`/`l` shortcuts mean "earliest" and "latest" across the whole cluster; middle versions are dropped if `f` or `l` is picked.

**Cluster-level resolution category** when pairs disagree (e.g., A↔B is "new info adds detail" but A↔C is "contradicts"): use the most severe category found in the cluster (contradicts > superseded > new info > redundant). The synthesis must handle the contradiction explicitly.

**Large clusters (5+ callouts):** display only the first 2-3 source excerpts in the prompt with a `…and N more` indicator to keep the prompt readable. The synthesis still draws from all sources.

**`nuance: <text>`** — user pushes back on the synthesis or proposes a better one. Skill regenerates and re-prompts. Same rhythm as existing `nuance:` patterns elsewhere in Phase 1.

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

Entries land in routing order = Step 5 walk order = chronological order across handoffs (oldest callout first). Produces a chronological log feel without requiring date prefixes inside the doc.

#### Step 5 close-out

```
Audit step 5 complete:
  Callouts after smart-merge: 4 (from 6 raw across 3 handoffs)
  Added to inline code docs:  1 (Acme.Users @moduledoc)
  Added to repo docs:         3 (→ docs/conventions.md)
  Already captured:           1
  Dismissed:                  1
```

The `Callouts after smart-merge:` line renders only when at least one merge happened; otherwise it is omitted to keep the close-out clean for the no-merge case.

Step 5 doesn't gate on the user — it transitions straight into Step 6 when there's anything to scan, or skips ahead to the audit-phase close-out gate when there isn't. The user-facing "Proceed to inline code documentation?" prompt is owned by whichever step exits the audit phase last.

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

Apply §Documentation language and tone to every proposed `@moduledoc` / `@doc` / docstring / JSDoc.

### Step 1 — Build the candidate list

From `git diff --name-only <base>..HEAD`, take all source files; skip lockfiles, generated files, fixtures, binary files. For each, identify doc opportunities by reading via Serena's symbol tools (`get_symbols_overview`, then `find_symbol` per top-level symbol):

- Modules without `@moduledoc` (Elixir) or top-of-file equivalent
- Public functions/methods without `@doc` (Elixir) or equivalent
- Existing `@moduledoc` / `@doc` stale relative to the audit phase's resolved picture
- Missing or misleading `@spec` on public functions — propose only when the type is unambiguous; **never fabricate types where inference is unclear**
- Non-Elixir equivalents: Python docstrings, Rust `///` doc comments, JS/TS JSDoc on exported symbols

**Do NOT touch private/internal function docs unless they already exist and are now stale.**

The candidate list also includes any callout-sourced proposals routed to `add-to-inline-code` in audit Step 5 and any in-code reference-cleanup proposals from audit Step 6. These flow through the same per-file walk as diff-sourced proposals and are tagged with their source on display (e.g., `[from callout: Discovery 4 in <handoff filename>]` or `[from in-code reference cleanup: <path>:<line>]`).

### Step 2 — Per-file proposal

Default unit of work: one file at a time. For larger branches with many files, batch into chunks of ~3–5 files. For each file, present:

```
File: lib/acme/users.ex (3 proposals)

  1. Add @moduledoc explaining the module's purpose
     [show proposed text, ~3-5 lines]

  2. Add @doc to invite/2 (new public function)
     [show proposed text]

  3. Update @doc on register/1 — current text says
     "creates a user" but the branch added email verification.
     [show current vs. proposed diff]

Approve all (a) / approve specific (e.g. "1,3") / nuance (e.g. "2: shorter, mention the role param") / skip file (s) / skip phase (S)
```

### Step 3 — Nuance handling

When the user nuances a proposal: revise in place, re-show just the revised proposal, ask `approve` / `nuance again` / `revoke`.

### Step 4 — Apply approved changes

Apply approved proposals immediately to the working tree. **Prefer Serena's symbolic edits** (`replace_symbol_body`, `insert_before_symbol`, `insert_after_symbol`). Use direct `Edit` only for non-symbol-level cases. Don't stage yet — staging happens in the handoff-cleanup phase.

### Step 5 — Phase gate

After all files walked: "Inline code documentation complete: applied N doc changes across M files, skipped K files. Proceed to repo documentation?"

## Phase 3 — Architecture, business-logic, README, CLAUDE.md

Apply §Documentation language and tone to every proposed prose edit. Clarity and concision come first; mirror the established register in `docs/` where it serves the reader, but tighten adjacent prose that's bloated rather than preserving it.

Working surface:

- `docs/**` excluding `docs/handoffs/` and `docs/superpowers/**`
- `README.md` (root)
- `CLAUDE.md` (root, plus any nested `CLAUDE.md` surfaced by the audit phase)

### Step 1 — Build proposal list (four buckets)

- **Update** — existing doc has stale content this branch invalidates.
- **Augment** — existing doc is structurally fine but missing coverage of something this branch added.
- **Create** — no existing doc covers a topic this branch introduces, and the topic is significant enough to warrant a new doc. **Always opt-in per file.**
- **Reorganize** — suggestions to merge overlapping docs (e.g., "`docs/migration.md` and `docs/post-migration.md` cover overlapping ground; merge into `docs/migration.md`?"), move a doc to a more appropriate subdirectory, or split a sprawling doc. Always opt-in. Bounded to docs the branch's changes make relevant — never whole-`docs/` cleanup.

Stale-but-unrelated docs flagged in the audit phase land in **update**, with the original audit-phase question carried forward as context.

Augment proposals also include any callouts routed to `add-to-repo-docs` in audit Step 5, applied against the resolved destination file and section. They flow through the same per-document approval rhythm and are tagged with their source on display (e.g., `Source callout: Discovery 4 from <handoff filename>`). If the destination doc was bootstrapped (zero-matches flow), it appears in the **Create** bucket and the routed callouts populate it.

### Doc surface rules

- **`CLAUDE.md`** — conservative; propose additions only when an audit-phase fact would actively mislead future Claude sessions if absent (new convention introduced, previously-documented convention removed, project standard commands changed). Repo-documentation close-out includes a one-liner suggestion: "consider running `claude-md-improver` separately for broader auditing."
- **`README.md`** — propose changes only when the branch touches something README explicitly covers (install steps, usage commands, public API surface visible from README). No editorializing on tone, marketing, or structure.
- **New file placement** — scan `docs/` for existing subdirectory conventions (e.g. `docs/architecture/`, `docs/business-logic/`) and propose a path that fits. Default `docs/<kebab-topic>.md`. User can `nuance: rename to <path>`.

### Step 2 — Per-document proposal

Same rhythm as the inline-code-documentation phase but the unit is one document. For **create** proposals, show the proposed file path, a short rationale, and the full proposed body before asking. For **reorganize** proposals, show full file moves and combined diffs and approve individually.

### Step 3 — Application & gate

Approved changes applied immediately. Phase summary: "Updated N docs, augmented M, created K, reorganized L. Skipped P. Proceed to handoff cleanup & final commit?"

## Phase 4 — Handoff cleanup & final commit

### Step 1 — Final review

Top-level summary of everything approved across the inline-code and repo-doc phases:

```
Pending changes (not yet committed):
  Inline code docs: 14 changes across 6 files
                    (1 from a callout, 7 from in-code reference cleanup)
  Repo docs:
    Updated:    docs/architecture.md, README.md
    Augmented:  docs/conventions.md (3 from callouts), docs/business-logic/users.md
    Created:    docs/architecture/auth-oauth.md
    Reorganized: merged docs/migration.md + docs/post-migration.md

About to delete:
  docs/handoffs/2026-04-15-200312-initial-spike.md
  docs/handoffs/2026-04-18-141022-handle-edge-cases.md
  docs/handoffs/2026-04-22-093041-final-cleanup.md

Continue? (yes / show diff / cancel)
```

`show diff` runs `git diff` (uncommitted) plus the list of pending deletes. `cancel` triggers the cancellation retention flow.

If after the inline-code and repo-doc phases there are **zero proposals approved** *and* zero handoffs to delete, exit with "Nothing to finalize" — no empty commit.

**Defensive halts before deletion.** A handoff cannot be deleted if (a) audit Step 5 extracted a callout from it that has no recorded routing decision, or (b) any source file still contains a reference to its path that wasn't resolved as `inline`, `redirect`, or `remove` (a recorded `skip` does not block — the user explicitly chose to leave the dangle). Under normal flow neither check fires; they exist so future audit-phase changes can't silently drop callouts or references. On a fired halt, exit with the relevant recovery hint: "Re-run and resolve at audit step 5" or "Re-run and resolve at audit step 6".

### Step 2 — Delete handoffs

`git rm` each confirmed handoff file. Deletes go into the final commit; history preserved. Only the confirmed list — never `docs/handoffs/` wholesale.

### Step 3 — Stage everything

`git add` the specific files touched in the inline-code and repo-doc phases, **by name**. Never `git add -A` / `git add .`. Deletes from step 2 are already staged via `git rm`. If `git status` shows files not produced by the skill, pause: "Detected files in `git status` not produced by this skill: `<list>`. Stage/commit them separately or discard, then continue (`yes` / `cancel`)."

### Step 4 — Compose commit message

Template:

```
docs: finalize <branch-name>

Inline code docs:
  - <terse summary, one bullet per file or grouped by module>

Repo docs:
  - <terse summary>

Removed <N> session handoff document(s).
Callouts: <X> to repo docs, <Y> to inline code docs, <Z> already captured, <W> dismissed[, <M> smart-merged].
In-code references: <I> inlined, <R> redirected, <X> removed, <S> skipped.
[optional: "(branch health checks skipped)"]
```

Either of the `Callouts:` / `In-code references:` lines is omitted entirely when its corresponding step had nothing to report (no extracted callouts; no detected references). No `Co-Authored-By` trailer.

Show the proposed message and ask: `commit` / `edit` / `cancel`. On `edit`, user supplies a replacement.

### Step 5 — Commit

`git commit -m "<message>"` via HEREDOC. Per global rules: never `--amend`, never `--no-verify`. On pre-commit hook failure: halt with the hook output and a recovery summary: "Pre-commit hook failed: `<one-line summary of what's failing>`. The doc changes from the inline-code and repo-doc phases are still in your working tree (and staged). I'll offer retention options next so the next run can pick the work back up cleanly; after that, fix the failure and re-run `/finalize-branch`." Then run the cancellation retention prompt — `git stash push` captures both staged and unstaged changes, so a stash here preserves the doc edits and the staged handoff deletions, and the next run re-stages/commits naturally.

### Step 6 — Final report

```
Branch finalized.
  Commit: <sha> docs: finalize <branch>
  Files changed: <n>
  Handoffs removed: <n>

Next: push and open a PR (or merge if appropriate).
```

Skill exits.

## Cancellation retention

When the user cancels (or the skill halts) **with applied doc edits in the working tree**, prompt before exiting:

> "Cancelled with `<N>` applied doc edit(s) in the working tree (handoffs were NOT deleted). How should the edits be retained?
>
>   1. **Stash for resume (recommended)** — saves the edits as a named stash. On the next `/finalize-branch`, resume detection will offer to apply them automatically.
>   2. **Commit manually** — produces a separate commit on the branch (default message: `WIP: finalize-branch doc updates`). The next `/finalize-branch` run will see them as part of `<base>..HEAD` and re-audit normally; you may end up with both this commit and the final commit on the branch.
>   3. **Keep in working tree** — leave as-is. The next `/finalize-branch` run will refuse pre-flight until you handle the dirty tree yourself.
>   4. **Discard** — runs `git restore` on the affected paths and throws the edits away.
>
> Choice? (`1`/`2`/`3`/`4`)"

Behavior per choice:

- **1 (stash)** — `git stash push -m "finalize-branch:<branch-name>:<ISO-timestamp>" -- <list of touched paths>`. Confirm: "Stashed N file(s) as `<stash-ref>`. Re-run `/finalize-branch` when ready — resume detection at the start of the next run will detect and offer to apply."
- **2 (commit)** — Stage the touched files by name, prompt for message (default editable), commit. Confirm SHA.
- **3 (keep)** — Exit with: "Edits left in working tree. Re-run will require you to commit, stash, or discard them first."
- **4 (discard)** — `git restore <touched paths>`. Exit with: "Discarded N applied edit(s)."

If there are zero applied edits at cancellation time (cancelled before any edits were made), skip this prompt — exit with a one-line confirmation.

## Edge cases

- **Empty branch** (zero commits ahead of base) — refuse at the pre-flight gate.
- **Zero handoffs on the branch** — the audit phase reports and proceeds; context comes from commits/diffs only.
- **Zero proposals after the inline-code and repo-doc phases, plus zero handoffs** — exit with "Nothing to finalize" — no empty commit.
- **Base branch undetectable** — try `main` → `master` → ask the user.
- **File edit fails mid-phase** (file disappeared, permission) — halt: "Edit failed on `<path>`: `<error>`. Resolve the file issue (e.g., restore the file, fix permissions), then re-run `/finalize-branch`." Then run the cancellation retention prompt for any already-applied edits.
- **Working tree changes outside the skill mid-flow** — detected at handoff-cleanup staging — pause with: "Detected files in `git status` not produced by this skill: `<list>`. Stage/commit them separately or discard, then continue (`yes` / `cancel`)."
- **Pre-commit hook failure on final commit** — covered in the handoff-cleanup phase; halts with hook output and runs the cancellation retention prompt.
- **Cancellation at any approval gate** — covered in "Cancellation retention"; if zero edits applied, exits with a one-line confirmation instead.
- **Worktrees** — work without modification; operate on `cwd`.
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

- **Symbol-level reads/edits in source files**: prefer Serena's tools (`get_symbols_overview`, `find_symbol`, `find_referencing_symbols`, `replace_symbol_body`, `insert_before_symbol`, `insert_after_symbol`).
- **Markdown / non-code edits**: `Read` and `Edit`.
- **Git operations and `mix`/`npm`/`pytest` runs**: `Bash`.
- **HexDocs MCP** for Hex package API context if the branch's changes touch a Hex dependency's surface; **Context7 MCP** for non-Hex libraries.

For pattern matching on Markdown headings inside handoffs (audit Step 5): read each handoff with `Read` and parse heading lines with a regex — not Serena (handoffs are non-code) and not `Grep` (the regex needs to inspect document structure, not just match strings). For the source-file reference scan (audit Step 6), `Grep` is appropriate: matches are text-level (substrings inside comments and docstrings), and the regex can express the handoff-path and callout-identifier patterns directly. `Read` captures the surrounding 1–3 lines of context for the per-reference proposal display, and Serena's `replace_symbol_body` (or `Edit` when the comment isn't symbol-attached) applies the approved edit during the inline-code-documentation phase.

## Spec reference

Full design rationale and decision history: `docs/superpowers/specs/2026-04-30-finalize-branch-skill-design.md`.
