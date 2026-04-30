# Finalize Branch Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `finalize-branch` skill to the `local_conf` plugin that walks a five-phase pipeline (resume detection + pre-flight gate + branch health checks → audit & questions → inline code docs → project docs → handoff cleanup + final commit) at end-of-branch, with explicit user approval at each gate.

**Architecture:** Single skill (`SKILL.md`) plus one slash command. No helper scripts, no hooks, no on-disk state. The skill is pure Claude-driven procedure executed against the working repo's `cwd`. The runtime "memory" between phases is conversation context — cancellation means start over (with optional stash-based resume of applied edits).

**Tech Stack:** Markdown for `SKILL.md` and the slash command. JSON for the plugin manifest. Bash + git (read-only inspection plus `git stash` / `git rm` / `git commit`) at runtime.

**Spec:** `docs/superpowers/specs/2026-04-30-finalize-branch-skill-design.md`

---

## File structure

**Create:**
- `plugins/local_conf/skills/finalize-branch/SKILL.md`
- `plugins/local_conf/commands/finalize-branch.md`

**Modify:**
- `plugins/local_conf/README.md` — add `finalize-branch` rows to the skills and slash commands tables
- `README.md` (marketplace root) — update the `local_conf` row to mention `finalize-branch`
- `plugins/local_conf/.claude-plugin/plugin.json` — bump version `1.1.1` → `1.2.0`

**Test approach:** No automated harness (consistent with prior `local_conf` plans — see `docs/superpowers/plans/2026-04-29-session-handoff-and-retrospect-skills.md`). Static checks: SKILL.md and slash command verified via shape inspection (`head -3` showing `---` / `name:` / `description:` for SKILL.md; `---` / `description:` for the command). JSON validity checked via `jq .`. End-to-end behavior verified manually in Task 6 by invoking the skill on a real branch.

---

### Task 1: Create the `finalize-branch` skill

**Files:**
- Create: `plugins/local_conf/skills/finalize-branch/SKILL.md`

This is the main artifact. The SKILL.md is long because the skill's runtime behavior is detailed (five phases, several gated approvals, error/retention handling). It is self-contained: the executing Claude does not need to read the spec at runtime.

- [ ] **Step 1: Create the skill directory**

```bash
mkdir -p plugins/local_conf/skills/finalize-branch
```

- [ ] **Step 2: Write `SKILL.md`**

Write `plugins/local_conf/skills/finalize-branch/SKILL.md` with the following exact content:

`````markdown
---
name: finalize-branch
description: Finalize a feature branch before merge — review the branch's handoffs and changes, audit and update inline code docs (`@moduledoc`, `@doc`, `@spec` for Elixir; equivalents elsewhere), audit and update `docs/`/README/CLAUDE.md as relevant, delete the branch's handoff documents, and produce one final commit. Use when the user says "finalize this branch", "wrap up this branch", "I'm done with this branch", "ready to merge this branch", or runs `/finalize-branch`. Manual invocation only.
---

# Finalize Branch

Walk a five-phase pipeline that brings inline code docs and project docs current with a feature branch's changes, removes the branch's session handoff documents, and produces one final commit.

The skill is interactive throughout. Each phase has an explicit user approval gate. Phase N+1 cannot begin until phase N is fully approved. State carried between phases lives only in conversation context — cancellation means start over (with optional stash-based resume of applied edits).

## When to use

Activate when the user says:

- "finalize this branch" / "wrap up this branch"
- "I'm done with this branch" / "ready to merge this branch"
- runs `/finalize-branch`

## Source-of-truth precedence

When handoffs and code disagree, resolve in this order: **code (current) > newest handoff > older handoffs (newer wins among handoffs)**. Code is what actually runs; handoffs are intent.

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

Anything unaddressed in a chunk defaults to `accept`. The user may add free-form clarifications between chunks. After all chunks are processed, summarize the resolved picture and ask: "Proceed to phase 2?".

If new questions arise during resolution (rare), append and run another mini-chunk.

## Phase 2 — Inline code documentation

### Step 1 — Build the candidate list

From `git diff --name-only <base>..HEAD`, take all source files; skip lockfiles, generated files, fixtures, binary files. For each, identify doc opportunities by reading via Serena's symbol tools (`get_symbols_overview`, then `find_symbol` per top-level symbol):

- Modules without `@moduledoc` (Elixir) or top-of-file equivalent
- Public functions/methods without `@doc` (Elixir) or equivalent
- Existing `@moduledoc` / `@doc` stale relative to phase 1's resolved picture
- Missing or misleading `@spec` on public functions — propose only when the type is unambiguous; **never fabricate types where inference is unclear**
- Non-Elixir equivalents: Python docstrings, Rust `///` doc comments, JS/TS JSDoc on exported symbols

**Do NOT touch private/internal function docs unless they already exist and are now stale.**

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

Apply approved proposals immediately to the working tree. **Prefer Serena's symbolic edits** (`replace_symbol_body`, `insert_before_symbol`, `insert_after_symbol`). Use direct `Edit` only for non-symbol-level cases. Don't stage yet — staging happens in phase 4.

### Step 5 — Phase gate

After all files walked: "Phase 2 complete: applied N doc changes across M files, skipped K files. Proceed to phase 3?"

## Phase 3 — Architecture, business-logic, README, CLAUDE.md

Working surface:

- `docs/**` excluding `docs/handoffs/` and `docs/superpowers/**`
- `README.md` (root)
- `CLAUDE.md` (root, plus any nested `CLAUDE.md` surfaced by phase 1)

### Step 1 — Build proposal list (four buckets)

- **Update** — existing doc has stale content this branch invalidates.
- **Augment** — existing doc is structurally fine but missing coverage of something this branch added.
- **Create** — no existing doc covers a topic this branch introduces, and the topic is significant enough to warrant a new doc. **Always opt-in per file.**
- **Reorganize** — suggestions to merge overlapping docs (e.g., "`docs/migration.md` and `docs/post-migration.md` cover overlapping ground; merge into `docs/migration.md`?"), move a doc to a more appropriate subdirectory, or split a sprawling doc. Always opt-in. Bounded to docs the branch's changes make relevant — never whole-`docs/` cleanup.

Stale-but-unrelated docs flagged in phase 1 land in **update**, with the original phase-1 question carried forward as context.

### Doc surface rules

- **`CLAUDE.md`** — conservative; propose additions only when a phase-1 fact would actively mislead future Claude sessions if absent (new convention introduced, previously-documented convention removed, project standard commands changed). Phase 3 close-out includes a one-liner suggestion: "consider running `claude-md-improver` separately for broader auditing."
- **`README.md`** — propose changes only when the branch touches something README explicitly covers (install steps, usage commands, public API surface visible from README). No editorializing on tone, marketing, or structure.
- **New file placement** — scan `docs/` for existing subdirectory conventions (e.g. `docs/architecture/`, `docs/business-logic/`) and propose a path that fits. Default `docs/<kebab-topic>.md`. User can `nuance: rename to <path>`.

### Step 2 — Per-document proposal

Same rhythm as phase 2 but the unit is one document. For **create** proposals, show the proposed file path, a short rationale, and the full proposed body before asking. For **reorganize** proposals, show full file moves and combined diffs and approve individually.

### Step 3 — Application & gate

Approved changes applied immediately. Phase summary: "Updated N docs, augmented M, created K, reorganized L. Skipped P. Proceed to phase 4?"

## Phase 4 — Handoff cleanup & final commit

### Step 1 — Final review

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

`show diff` runs `git diff` (uncommitted) plus the list of pending deletes. `cancel` triggers the cancellation retention flow.

If after phases 2 + 3 there are **zero proposals approved** *and* zero handoffs to delete, exit with "Nothing to finalize" — no empty commit.

### Step 2 — Delete handoffs

`git rm` each confirmed handoff file. Deletes go into the final commit; history preserved. Only the confirmed list — never `docs/handoffs/` wholesale.

### Step 3 — Stage everything

`git add` the specific files touched in phases 2 and 3, **by name**. Never `git add -A` / `git add .`. Deletes from step 2 are already staged via `git rm`. If `git status` shows files not produced by the skill, pause: "Detected files in `git status` not produced by this skill: `<list>`. Stage/commit them separately or discard, then continue (`yes` / `cancel`)."

### Step 4 — Compose commit message

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

Show the proposed message and ask: `commit` / `edit` / `cancel`. On `edit`, user supplies a replacement.

### Step 5 — Commit

`git commit -m "<message>"` via HEREDOC. Per global rules: never `--amend`, never `--no-verify`. On pre-commit hook failure: halt with the hook output and a recovery summary: "Pre-commit hook failed: `<one-line summary of what's failing>`. The doc changes from phases 2/3 are still in your working tree (and staged). Fix the failure, then re-run `/finalize-branch`." Then run the cancellation retention prompt — `git stash push` captures both staged and unstaged changes, so a stash here preserves the doc edits and the staged handoff deletions, and the next run re-stages/commits naturally.

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
>   1. **Stash for resume (recommended)** — saves the edits as a named stash. On the next `/finalize-branch`, phase 0 will offer to apply them automatically.
>   2. **Commit manually** — produces a separate commit on the branch (default message: `WIP: finalize-branch doc updates`). The next `/finalize-branch` run will see them as part of `<base>..HEAD` and re-audit normally; you may end up with both this commit and the final commit on the branch.
>   3. **Keep in working tree** — leave as-is. The next `/finalize-branch` run will refuse pre-flight until you handle the dirty tree yourself.
>   4. **Discard** — runs `git restore` on the affected paths and throws the edits away.
>
> Choice? (`1`/`2`/`3`/`4`)"

Behavior per choice:

- **1 (stash)** — `git stash push -m "finalize-branch:<branch-name>:<ISO-timestamp>" -- <list of touched paths>`. Confirm: "Stashed N file(s) as `<stash-ref>`. Re-run `/finalize-branch` when ready — phase 0 will detect and offer to apply."
- **2 (commit)** — Stage the touched files by name, prompt for message (default editable), commit. Confirm SHA.
- **3 (keep)** — Exit with: "Edits left in working tree. Re-run will require you to commit, stash, or discard them first."
- **4 (discard)** — `git restore <touched paths>`. Exit with: "Discarded N applied edit(s)."

If there are zero applied edits at cancellation time (cancelled in phase 0 or phase 1, before any edits were made), skip this prompt — exit with a one-line confirmation.

## Edge cases

- **Empty branch** (zero commits ahead of base) — refuse at phase 0.
- **Zero handoffs on the branch** — phase 1 reports and proceeds; context comes from commits/diffs only.
- **Zero proposals after phases 2 + 3, plus zero handoffs** — exit with "Nothing to finalize" — no empty commit.
- **Base branch undetectable** — try `main` → `master` → ask the user.
- **File edit fails mid-phase** (file disappeared, permission) — halt: "Edit failed on `<path>`: `<error>`. Resolve the file issue (e.g., restore the file, fix permissions), then re-run `/finalize-branch`." Then run the cancellation retention prompt for any already-applied edits.
- **Working tree changes outside the skill mid-flow** — detected at phase 4 staging — pause with: "Detected files in `git status` not produced by this skill: `<list>`. Stage/commit them separately or discard, then continue (`yes` / `cancel`)."
- **Worktrees** — work without modification; operate on `cwd`.
- **Binary files in diff** — silently skip in phase 2 candidate building.

## Tool usage

- **Symbol-level reads/edits in source files**: prefer Serena's tools (`get_symbols_overview`, `find_symbol`, `find_referencing_symbols`, `replace_symbol_body`, `insert_before_symbol`, `insert_after_symbol`).
- **Markdown / non-code edits**: `Read` and `Edit`.
- **Git operations and `mix`/`npm`/`pytest` runs**: `Bash`.
- **HexDocs MCP** for Hex package API context if the branch's changes touch a Hex dependency's surface; **Context7 MCP** for non-Hex libraries.

## Spec reference

Full design rationale and decision history: `docs/superpowers/specs/2026-04-30-finalize-branch-skill-design.md`.
`````

- [ ] **Step 3: Verify the file is well-formed**

Run: `head -3 plugins/local_conf/skills/finalize-branch/SKILL.md`
Expected: shows `---` then `name: finalize-branch` then a `description: …` line beginning with "Finalize a feature branch before merge".

- [ ] **Step 4: Verify the SKILL.md is parseable as one frontmatter block + one body**

Run: `awk 'BEGIN{n=0} /^---$/{n++; if(n>2) exit 1} END{if(n!=2) exit 1}' plugins/local_conf/skills/finalize-branch/SKILL.md && echo "ok"`
Expected: `ok`. (Confirms exactly two `---` fences in the file — opening and closing of the frontmatter block, with no stray third one.)

- [ ] **Step 5: Commit**

```bash
git add plugins/local_conf/skills/finalize-branch/SKILL.md
git commit -m "Add finalize-branch skill to local_conf"
```

---

### Task 2: Add `/finalize-branch` slash command

**Files:**
- Create: `plugins/local_conf/commands/finalize-branch.md`

This is a thin shim that invokes the skill — same pattern as `commands/handoff.md` and `commands/retrospect.md`.

- [ ] **Step 1: Write `commands/finalize-branch.md`**

```markdown
---
description: Finalize a feature branch — audit and update inline code docs and project docs, remove the branch's handoffs, produce one final commit
---

Use the `finalize-branch` skill to walk the end-of-branch pipeline. The skill is interactive throughout: it runs pre-flight + branch health checks, audits the branch's handoffs and changes, asks clarifying questions, proposes inline code doc and project doc updates with per-item approval, deletes the branch's handoff documents, and produces one final commit.

If the user passed arguments after `/finalize-branch`, treat them as additional context or instructions for the skill (e.g., "finalize this branch, skip the docs update for X"). Otherwise just hand control to the skill.
```

- [ ] **Step 2: Verify the file is well-formed**

Run: `head -3 plugins/local_conf/commands/finalize-branch.md`
Expected: shows `---` then `description: …` then `---`.

- [ ] **Step 3: Commit**

```bash
git add plugins/local_conf/commands/finalize-branch.md
git commit -m "Add /finalize-branch slash command to local_conf"
```

---

### Task 3: Update `local_conf` README to document the new skill and slash command

**Files:**
- Modify: `plugins/local_conf/README.md`

The current README has tables for Skills and Slash commands; add one row to each.

- [ ] **Step 1: Read the current README to confirm the table shape**

```bash
sed -n '1,40p' plugins/local_conf/README.md
```

Expected: shows the `### Skills` table with the two existing rows (`session-handoff`, `session-retrospect`) and the `### Slash commands` table with `/handoff`, `/retrospect`. If the file shape has drifted from what's shown in Step 2's "before" view, reconcile manually before continuing.

- [ ] **Step 2: Add the `finalize-branch` row to the Skills table**

Use the `Edit` tool to replace this exact block:

```
| `skills/session-retrospect/` | End-of-session reflection — narrative to the handoff, concrete edits applied directly |

### Slash commands
```

with this exact block:

```
| `skills/session-retrospect/` | End-of-session reflection — narrative to the handoff, concrete edits applied directly |
| `skills/finalize-branch/` | End-of-branch pipeline — audits and updates inline code docs and project docs, removes the branch's handoffs, produces one final commit |

### Slash commands
```

- [ ] **Step 3: Add the `/finalize-branch` row to the Slash commands table**

Replace this exact block:

```
| `/handoff` | Route to the `session-handoff` skill |
| `/retrospect` | Route to the `session-retrospect` skill |
```

with this exact block:

```
| `/handoff` | Route to the `session-handoff` skill |
| `/retrospect` | Route to the `session-retrospect` skill |
| `/finalize-branch` | Route to the `finalize-branch` skill |
```

- [ ] **Step 4: Verify both rows landed**

Run: `grep -c 'finalize-branch' plugins/local_conf/README.md`
Expected: `2` (one row per table).

- [ ] **Step 5: Commit**

```bash
git add plugins/local_conf/README.md
git commit -m "Document finalize-branch skill and slash command in local_conf README"
```

---

### Task 4: Update marketplace root README to mention `finalize-branch`

**Files:**
- Modify: `README.md` (repository root)

The root README's `local_conf` row currently lists "session-handoff and session-retrospect skills" — add `finalize-branch` to that list.

- [ ] **Step 1: Read the current root README to confirm the table shape**

```bash
sed -n '1,30p' README.md
```

Expected: shows the `local_conf` row with the text `Includes session-handoff and session-retrospect skills, Serena auto-approval, in-place sed guard, and end-of-session wrap-up nudge.`

- [ ] **Step 2: Update the `local_conf` row**

Use the `Edit` tool to replace this exact string:

```
Includes session-handoff and session-retrospect skills, Serena auto-approval, in-place sed guard, and end-of-session wrap-up nudge.
```

with this exact string:

```
Includes session-handoff, session-retrospect, and finalize-branch skills, Serena auto-approval, in-place sed guard, and end-of-session wrap-up nudge.
```

- [ ] **Step 3: Verify the edit landed**

Run: `grep -c 'finalize-branch' README.md`
Expected: `1`.

- [ ] **Step 4: Commit**

```bash
git add README.md
git commit -m "Mention finalize-branch in marketplace root README"
```

---

### Task 5: Bump `local_conf` plugin version

**Files:**
- Modify: `plugins/local_conf/.claude-plugin/plugin.json`

Add a feature → minor version bump.

- [ ] **Step 1: Read current version**

```bash
cat plugins/local_conf/.claude-plugin/plugin.json
```

Expected: shows `"version": "1.1.1"`.

- [ ] **Step 2: Bump to `1.2.0`**

Use the `Edit` tool to replace `"version": "1.1.1"` with `"version": "1.2.0"`. After the edit, the file should be:

```json
{
  "name": "local_conf",
  "description": "My personal configuration",
  "version": "1.2.0",
  "author": {
    "name": "Sanjay Nelson"
  }
}
```

- [ ] **Step 3: Validate JSON**

Run: `jq . plugins/local_conf/.claude-plugin/plugin.json > /dev/null && echo "valid"`
Expected: `valid`.

- [ ] **Step 4: Commit**

```bash
git add plugins/local_conf/.claude-plugin/plugin.json
git commit -m "Bump local_conf to 1.2.0"
```

---

### Task 6: End-to-end smoke verification (manual)

Done by the user, not the implementer. The implementer should report the verification steps in the final summary so the user can run them.

The verification steps:

- [ ] **Step 1: Reload plugins**

In Claude Code: `/reload-plugins`. Expect to see the new skill (`finalize-branch`) and the new slash command (`/finalize-branch`) listed.

- [ ] **Step 2: Slash command discoverability**

In Claude Code, type `/fin` and confirm `/finalize-branch` appears in the autocomplete list.

- [ ] **Step 3: Phrase-based activation**

In a fresh Claude Code session in this repo, say: "Let's do a dry walkthrough of finalize-branch — pretend the branch is ready to merge, but stop at phase 0 step 3 (branch health checks) and tell me what you'd run." Expect Claude to invoke the `finalize-branch` skill, perform resume detection, run pre-flight, and stop at step 3 reporting the detected pre-commit alias (or fallback) without actually executing it.

- [ ] **Step 4: Pre-flight refusal — dirty tree**

In a sample repo, leave one file with uncommitted changes. Run `/finalize-branch`. Expect refusal at phase 0 step 2.1 with: "Working tree has uncommitted changes. Commit, stash, or discard them with `git stash` / `git restore`, then re-run `/finalize-branch`."

- [ ] **Step 5: Pre-flight refusal — base branch advocacy**

On `main` with at least one commit ahead of `origin/main`, working tree clean. Run `/finalize-branch`. Expect the advocacy prompt: "You're finalizing directly on `main`. … Continue on `main` anyway? (y/N)". On `N`, expect the recommended `git switch -c <feature>` exit message.

- [ ] **Step 6: Pre-flight refusal — no commits ahead of base**

On a feature branch with no commits ahead of `main`. Run `/finalize-branch`. Expect refusal at phase 0 step 2.2 with: "No commits ahead of `<base>`. Nothing to finalize. …".

- [ ] **Step 7: Cancellation retention — stash + resume round trip**

On a feature branch with at least one handoff in `docs/handoffs/` and at least one source file with a missing `@moduledoc` (or equivalent). Run `/finalize-branch`. Approve a couple of phase-2 doc edits. Cancel at phase 3 or phase 4. At the retention prompt, choose `1` (stash). Confirm: working tree returns to clean, a stash is created with name `finalize-branch:<branch>:<ISO-timestamp>`. Re-run `/finalize-branch`. Confirm phase 0 step 1 detects the stash, applies it, and proceeds; the dirty-tree check is bypassed; the doc edits are still in the tree.

- [ ] **Step 8: Final commit shape**

Complete a finalize end-to-end on a small branch. Confirm:
- The final commit message matches the template (`docs: finalize <branch>`, phase 2 / phase 3 bullets, `Removed N session handoff document(s).`)
- No `Co-Authored-By` trailer.
- The handoff files for that branch are removed by the commit (visible in `git show`).

- [ ] **Step 9: Commit any tweaks**

If any of Steps 1–8 surface wording, ordering, or behavior issues, make targeted fixes to the SKILL.md, slash command, or READMEs and commit them with messages explaining the tweak.

---

## Self-review notes

- **Spec coverage:**
  - Activation (slash command + phrase) → Tasks 1 (description frontmatter) + 2 (slash command).
  - File layout (`SKILL.md`, slash command) → Tasks 1, 2.
  - Pipeline overview, phase 0–4, cancellation retention, error/edge cases, halt-and-exit messaging principle, source-of-truth precedence, doc surface rules, SKILL.md description draft → Task 1 (encoded in `SKILL.md`).
  - "No helper scripts. No hooks. No state files on disk." → reflected in plan having zero script/hook tasks.
  - Plugin documentation (local_conf README + marketplace root README) → Tasks 3, 4.
  - Plugin manifest update → Task 5.
  - Manual smoke verification → Task 6.
- **Placeholder scan:** no "TBD" / "TODO" / "fill in details" / unspecified types. All commit messages and exact strings are concrete. The `Edit` tool blocks in Tasks 3 and 4 give exact `old_string` and `new_string` content.
- **Type/name consistency:** skill name `finalize-branch` is consistent across SKILL.md frontmatter, slash command body, both README updates, and the spec. Stash naming (`finalize-branch:<branch-name>:<ISO-timestamp>`) is the same string in SKILL.md phase 0 step 1 ("look for entries whose message matches"), in the cancellation retention behavior section ("`git stash push -m \"finalize-branch:...\"`"), and in the spec.
- **Risk noted:** the SKILL.md is long (~250 lines). If a future runtime experience suggests Claude isn't following all phases consistently, consider splitting per-phase reference content into sibling files (`PHASE-1.md`, `PHASE-2.md`, etc.) under the skill directory and shortening `SKILL.md` to a control-flow outline that points to them — same pattern the brainstorming skill uses with `visual-companion.md`. This is not done now because the skill is brand-new and we don't yet know which phases will be the rough edges. Defer until smoke testing reveals a problem.
