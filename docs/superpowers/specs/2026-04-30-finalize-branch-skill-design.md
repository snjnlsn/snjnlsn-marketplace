# Finalize Branch Skill

**Date:** 2026-04-30
**Status:** Approved — ready for implementation plan
**Plugin:** `local_conf`

## Problem

A typical work branch in this setup spans multiple Claude Code sessions. Each session produces a handoff document under `docs/handoffs/` plus code changes and commits. By the time the branch is ready to merge, three things tend to be true:

1. The branch's accumulated handoff documents collectively describe intent, but only the *latest* handoff plus the actual code reflect current truth — earlier handoffs may contradict reality.
2. Inline code documentation (`@moduledoc`, `@doc`, `@spec` for Elixir; equivalents elsewhere) lags the code changes, especially for public API added or modified during the branch.
3. Architecture and business-logic documentation under `docs/` may be silently stale because branch changes weren't reflected back into it.

There is currently no skill that, on demand, takes responsibility for closing all three gaps and removing the now-redundant handoff documents (which exist only to support the in-branch development cycle and become misleading once the branch lands).

## Goal

Add a `finalize-branch` skill inside the `local_conf` plugin that runs manually at the end of a branch's life, walks a fixed pipeline of phases (each with explicit user approval), and produces a single final commit that:

- Brings inline code documentation up to date with the branch's code changes
- Updates, augments, and (with explicit opt-in) creates architecture/business-logic docs under `docs/` to reflect the branch's changes
- Adjusts `README.md` and `CLAUDE.md` only where the branch's changes warrant it
- Removes the branch's handoff documents from `docs/handoffs/`

The skill is interactive throughout. It surfaces clarifying questions before proposing changes, presents proposals in approvable units, and supports approve / revoke / nuance per proposal.

## Non-Goals

- **Not a code reviewer.** No code-quality comments, refactor suggestions, bug flags, or non-doc code changes.
- **Not a test writer.** Doesn't add tests even when missing coverage is implied.
- **Not a merger.** Doesn't push, doesn't open PRs, doesn't merge.
- **Not a CHANGELOG generator.** Out of scope.
- **Not a CLAUDE.md auditor.** Conservative additions only; broader CLAUDE.md auditing belongs to `claude-md-improver`.
- **Not a doc deduper.** Reorganization is bounded to docs the branch's changes make relevant.
- **Doesn't touch `docs/superpowers/**` — ever.**
- **Doesn't run on dirty trees, branches with no commits ahead of base, or detached HEAD.** Refusal is the feature.
- **Doesn't auto-resume.** Cancellation means start over.
- **Doesn't run in the background or as a hook.** Manual invocation only.

## Activation

The skill activates two ways:

1. **Slash command:** `/finalize-branch` at `plugins/local_conf/commands/finalize-branch.md` — explicitly invokes the skill.
2. **Phrase-based:** the SKILL.md `description` frontmatter triggers on phrases such as "finalize this branch", "wrap up this branch", "I'm done with this branch", "ready to merge this branch".

## Design

### File layout

```
plugins/local_conf/
├── commands/
│   └── finalize-branch.md          # NEW — slash command that invokes the skill
└── skills/
    └── finalize-branch/            # NEW
        └── SKILL.md
```

No helper scripts. No hooks. No state files on disk. The skill is pure Claude-driven procedure.

### Pipeline overview

Five phases, strictly ordered, each gated by explicit user approval. Phase N+1 cannot begin until phase N is fully approved. State carried between phases lives only in conversation context.

| Phase | Purpose | Gate |
|---|---|---|
| 0 | Pre-flight + branch health checks | Hard gate — failures halt the skill |
| 1 | Audit handoffs, ask clarifying questions, settle intent | User confirms resolved picture |
| 2 | Propose inline code documentation changes | User approves (per-file, chunkable) |
| 3 | Propose docs/, README, CLAUDE.md changes | User approves (per-document) |
| 4 | Delete handoffs, stage everything, single final commit | User approves commit message and continues |

State carried forward in conversation context:

- Base branch name and base SHA (`git merge-base HEAD <base>`)
- Confirmed list of branch handoff files
- Merged source-of-truth picture: **code (current) > newest handoff > older handoffs (newer wins)**
- Approved-but-not-yet-applied changes accumulating across phases
- Phase-1 follow-up notes raised during questioning

If the user cancels mid-flow or the skill halts on error, conversation context is the only memory; re-invoking starts over from phase 0.

### Phase 0 — Pre-flight gate + branch health checks

**Pre-flight (refuses to start):**

1. `git status --porcelain` non-empty → refuse: "Working tree has uncommitted changes. Commit or stash, then re-run."
2. Detect base branch via `git symbolic-ref refs/remotes/origin/HEAD`. Fallback chain: `main` → `master` → ask the user. If `git rev-list --count <base>..HEAD` is `0` → refuse: "No commits ahead of `<base>`. Nothing to finalize."
3. If the current branch *is* the base branch (e.g. `main` with commits ahead of `origin/main`): allow, but advocate first:
   > "You're finalizing directly on `main`. For most work, branching this off (`git switch -c <feature>`) and merging via PR gives you isolation, code review, and a cleaner history. Continue on `main` anyway? (y/N)"
   - On `N`, exit. On `y`, proceed.
4. Detached HEAD → refuse with "Not on a branch." Detected via `git symbolic-ref --quiet HEAD` returning non-zero.
5. Mid-rebase/merge/cherry-pick → refuse with "A git operation is in progress. Resolve it before finalizing." Detected by checking for the presence of any of: `.git/rebase-merge/`, `.git/rebase-apply/`, `.git/MERGE_HEAD`, `.git/CHERRY_PICK_HEAD`, `.git/REVERT_HEAD`. (The `git status --porcelain` check alone is insufficient — a paused rebase can have an empty porcelain.)

**Branch health checks (auto-detect + run):**

The skill scans for a project-defined pre-commit alias or pipeline, in this order:

1. `mix.exs` aliases — look for `precommit`, `check`, `quality`, `verify`
2. `package.json` scripts — look for `precommit`, `check`, `verify`, `lint && test`
3. `Makefile` targets — `make check`, `make precommit`, `make verify`
4. `CLAUDE.md` for project-specific "before committing" / "pre-commit" guidance
5. `README.md` for project-specific guidance — typically in "Development", "Contributing", "Testing", or "Getting started" sections; look for documented commands tied to "before committing", "pre-commit", "checks", "verify", "test"
6. Language-default fallbacks:
   - Elixir: `mix format --check-formatted && mix compile --warnings-as-errors && mix test`
   - JS/TS: `npm test`
   - Python: `pytest`

Skill reports what it found and asks: `run / edit / skip`.

- **run** — execute. On non-zero exit, halt with stdout/stderr summary: "Branch health checks failed. Address these and re-run finalize-branch. Skip with `skip` if you intentionally want to bypass."
- **edit** — user provides a replacement command, then run.
- **skip** — record that checks were skipped. Final commit message footer notes `(branch health checks skipped)`.

If nothing is detected, ask: "Provide a pre-commit alias name (e.g., `mix precommit`) or a list of checks to run, or `skip`." The skill does **not** create new aliases in `mix.exs`/`package.json` — that is out of scope.

### Phase 1 — Audit & clarifying questions

**Step 1 — Confirm the handoff list.**

Resolve via:

```
git log --name-only --pretty=format: <base>..HEAD -- docs/handoffs/
```

Show the resolved list, sorted oldest → newest. Ask: "These are the handoffs I attribute to this branch. Add, remove, or proceed? (`proceed` / `edit`)"

If zero handoffs are returned, the skill reports "No handoffs found for this branch — context will come from commits/diffs only" and proceeds.

**Step 2 — Build the source-of-truth picture (silent).**

Internally, the skill:

- Reads `git diff <base>..HEAD` and `git diff --stat <base>..HEAD`
- Reads each confirmed handoff in chronological order (older → newer), treating later as overriding earlier on conflicts
- Maps code-level facts (modules added/removed/renamed, public API changes, schema/migration changes) and narrative-level facts (intent, rationale, open questions)
- Source-of-truth precedence: **code > newest handoff > older handoffs**

**Step 3 — Identify divergences and ambiguities.**

Skill produces a list of clarifying questions, in categories:

- **Handoff-vs-code conflicts:** "Handoff `2026-04-15-...md` says module `Foo.Bar` was removed, but it still exists in the code. Was the removal reverted, or is the handoff stale?"
- **Public API without docs:** "New public function `Acme.Users.invite/2` has no `@doc`. Want me to draft one based on the handoff narrative, or do you have specific phrasing in mind?"
- **Stale-but-relevant docs:** "`docs/architecture.md` says 'all auth flows through `Auth.Session`' but this branch added `Auth.OAuth`. Update the arch doc to mention OAuth?"
- **README/CLAUDE.md candidates:** "Branch added a new mix task `mix acme.seed`. Mention it in `README.md`'s 'Setup' section?"
- **Open questions in handoffs:** "Handoff `...md` left an open question: 'Should we add a rate limiter?' Resolved, deferred, or still open?"

Each question carries the skill's recommended answer.

**Step 4 — Interactive question loop.**

Questions are split into chunks of ~3–5 at a time. For each chunk, the user responds per question with:

- `accept` — use the recommended answer
- `change: <text>` — override
- `skip` — don't act on this in later phases

Anything not addressed in a chunk defaults to `accept`. The user may add free-form clarifications between chunks. After all chunks are processed, the skill summarizes the resolved picture and asks: "Proceed to phase 2?"

If new questions arise during resolution (rare), they're appended and another mini-chunk runs.

### Phase 2 — Inline code documentation

The phase proposes inline doc edits in source files touched by the branch — and only those.

**Step 1 — Build the candidate list.**

From `git diff --name-only <base>..HEAD`, take all source files; skip lockfiles, generated files, fixtures, binary files. For each, the skill identifies doc opportunities by re-reading via Serena's symbol tools (`get_symbols_overview`, then `find_symbol` per top-level symbol):

- Modules without `@moduledoc` (Elixir) or top-of-file equivalent
- Public functions/methods without `@doc` (Elixir) or equivalent
- Existing `@moduledoc` / `@doc` that is stale relative to phase 1's resolved picture
- Missing or misleading `@spec` on public functions — proposed only when the type is unambiguous; the skill never fabricates types where inference is unclear
- Non-Elixir equivalents: Python docstrings, Rust `///` doc comments, JS/TS JSDoc on exported symbols

**The skill does NOT touch private/internal function docs unless they already exist and are now stale.**

**Step 2 — Per-file proposal.**

Default unit of work is one file at a time. For larger branches (many files with proposals), the skill batches into small chunks of ~3–5 files at a time. For each file:

```
File: lib/acme/users.ex (3 proposals)

  1. Add @moduledoc explaining the module's purpose
     [shows proposed text, ~3-5 lines]

  2. Add @doc to invite/2 (new public function)
     [shows proposed text]

  3. Update @doc on register/1 — current text says
     "creates a user" but the branch added email verification.
     [shows current vs. proposed diff]

Approve all (a) / approve specific (e.g. "1,3") / nuance (e.g. "2: shorter, mention the role param") / skip file (s) / skip phase (S)
```

**Step 3 — Nuance handling.**

When the user nuances a proposal (`2: shorter, mention the role param`), the skill revises in place, re-shows just the revised proposal, and asks: `approve` / `nuance again` / `revoke`.

**Step 4 — Apply approved changes.**

Approved proposals are applied immediately to the working tree, preferring Serena's symbolic edits (`replace_symbol_body`, `insert_before_symbol`, `insert_after_symbol`). Direct `Edit` is used only for non-symbol-level cases. Changes are not staged yet — staging happens in phase 4.

**Step 5 — Phase gate.**

After all files are walked: "Phase 2 complete: applied N doc changes across M files, skipped K files. Proceed to phase 3?"

### Phase 3 — Architecture, business-logic, README, CLAUDE.md

Working surface:

- `docs/**` excluding `docs/handoffs/` and `docs/superpowers/**`
- `README.md` (root)
- `CLAUDE.md` (root, plus any nested `CLAUDE.md` surfaced by phase 1)

**Step 1 — Build proposal list.**

Four buckets:

- **Update** — existing doc has stale content this branch invalidates.
- **Augment** — existing doc is structurally fine but missing coverage of something this branch added.
- **Create** — no existing doc covers a topic this branch introduces, and the topic is significant enough to warrant a new doc. **Always opt-in per file.**
- **Reorganize** — suggestions to merge overlapping docs (e.g., "`docs/migration.md` and `docs/post-migration.md` cover overlapping ground; merge into `docs/migration.md`?"), move a doc to a more appropriate subdirectory, or split a sprawling doc. Always opt-in. Bounded to docs this branch's changes make relevant — never whole-`docs/` cleanup.

Stale-but-unrelated docs flagged in phase 1 land in **update**, with the original phase-1 question carried forward as context.

**Doc surface rules:**

- **`CLAUDE.md`:** conservative — propose additions only when a phase-1 fact would actively mislead future Claude sessions if absent (new convention introduced, previously-documented convention removed, project standard commands changed). Phase 3 close-out includes a one-liner suggestion to run `claude-md-improver` separately if broader auditing is desired.
- **`README.md`:** propose changes only when the branch touches something README explicitly covers (install steps, usage commands, public API surface visible from README). No editorializing on tone, marketing, or structure.
- **New file placement:** scan `docs/` for existing subdirectory conventions (e.g. `docs/architecture/`, `docs/business-logic/`) and propose a path that fits. Default `docs/<kebab-topic>.md`. User can `nuance: rename to <path>`.

**Step 2 — Per-document proposal.**

Same rhythm as phase 2 but one document at a time. For **create** proposals, show the proposed file path, a short rationale, and the full proposed body before asking. For **reorganize** proposals, show full file moves and combined diffs and approve individually.

**Step 3 — Application & gate.**

Approved changes applied immediately. Phase summary: "Updated N docs, augmented M, created K, reorganized L. Skipped P. Proceed to phase 4?"

### Phase 4 — Handoff cleanup & final commit

**Step 1 — Final review.**

Top-level summary of everything approved across phases 2 and 3:

```
Pending changes (not yet committed):
  Phase 2 — Inline code docs: 14 changes across 6 files
  Phase 3 — Architecture/docs:
    Updated:    docs/architecture.md, README.md
    Augmented:  docs/business-logic/users.md
    Created:    docs/architecture/auth-oauth.md
    Reorganized: merged docs/migration.md + docs/post-migration.md

About to delete (phase 4):
  docs/handoffs/2026-04-15-200312-initial-spike.md
  docs/handoffs/2026-04-18-141022-handle-edge-cases.md
  docs/handoffs/2026-04-22-093041-final-cleanup.md

Continue? (yes / show diff / cancel)
```

`show diff` runs `git diff` (uncommitted) plus the list of pending deletes. `cancel` aborts the skill — working tree changes from phases 2/3 stay in place; nothing is rolled back. Skill prints: "Cancelled. Working tree contains <N> applied edits from phases 2/3. Use `git restore` to discard or commit manually."

If after phases 2 and 3 there are **zero proposals approved** *and* zero handoffs to delete, the skill exits with "Nothing to finalize" rather than producing an empty commit.

**Step 2 — Delete handoffs.**

`git rm` each confirmed handoff file. The deletes go into the final commit and history is preserved. Only the confirmed list — never `docs/handoffs/` wholesale.

**Step 3 — Stage everything.**

`git add` the specific files touched in phases 2 and 3, by name. Never `git add -A` / `git add .`. Deletes from step 2 are already staged via `git rm`. If `git status` shows files not produced by the skill, pause and ask the user to resolve before continuing.

**Step 4 — Compose commit message.**

Template:

```
docs: finalize <branch-name>

Phase 2 (code docs):
  - <terse summary, one bullet per file or grouped by module>

Phase 3 (project docs):
  - <terse summary>

Removed <N> session handoff document(s).
[optional: "(branch health checks skipped)"]
```

No `Co-Authored-By` trailer.

Skill shows the proposed message and asks: `commit / edit / cancel`. On `edit`, user supplies a replacement.

**Step 5 — Commit.**

`git commit -m "<message>"` via HEREDOC. Per global CLAUDE.md rules: never `--amend`, never `--no-verify`. On pre-commit hook failure, halt with hook output and direct user to fix and re-run finalize-branch (which restarts from phase 0; prior approvals are not preserved).

**Step 6 — Final report.**

```
Branch finalized.
  Commit: <sha> docs: finalize <branch>
  Files changed: <n>
  Handoffs removed: <n>

Next: push and open a PR (or merge if appropriate).
```

Skill exits.

### Error handling & edge cases

| Situation | Behavior |
|---|---|
| Empty branch (zero commits ahead of base) | Refuse at phase 0. |
| Zero handoffs on the branch | Phase 1 reports and proceeds; context comes from commits/diffs only. |
| Zero proposals after phases 2 + 3, plus zero handoffs | Exit with "Nothing to finalize" — no empty commit. |
| Base branch undetectable | Try `main` → `master` → ask the user. |
| Detached HEAD / mid-rebase / mid-merge | Refuse at phase 0. |
| File edit fails mid-phase (disappeared, permission) | Halt phase, show partial state, user resolves and resumes or cancels. |
| Working tree changes outside the skill mid-flow | Detected at phase 4 staging — pause, ask user to resolve. |
| Pre-commit hook failure on final commit | Halt; surface hook output; direct user to fix and re-run (full restart). |
| Cancellation at any approval gate | Exit. Working tree retains applied edits; nothing rolled back. |
| Worktrees | Works without modification — operates on `cwd`. |
| Binary files in diff | Silently skipped in phase 2 candidate building. |

### SKILL.md description (frontmatter)

The `description` field must trigger on the relevant phrases and clearly scope the skill. Draft (final wording can be tuned in implementation):

> Finalize a feature branch before merge: review the branch's handoffs and changes, audit and update inline code docs (`@moduledoc`, `@doc`, `@spec` for Elixir; equivalents elsewhere), audit and update `docs/`/README/CLAUDE.md as relevant, delete the branch's handoff documents, and produce one final commit. Use when the user says "finalize this branch", "wrap up this branch", "I'm done with this branch", "ready to merge this branch", or runs `/finalize-branch`.

### Slash command file

`plugins/local_conf/commands/finalize-branch.md` is a thin shim that invokes the skill — same pattern as other slash commands in the marketplace.

## Open questions

None at design time. All design decisions captured above are approved.
