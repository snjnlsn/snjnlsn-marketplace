# Preflight

Load this reference for Phase 0 of `finalize-branch`.

## Resume Detection

Run `git stash list` and look for messages matching `finalize-branch:<current-branch>:`. If found, list matching stashes and ask whether to `apply`, `skip`, or `discard`.

- `apply`: require a clean working tree first. Apply the stash, drop it only after a clean apply, and bypass the dirty-tree preflight only for this run.
- `skip`: keep the stash and continue normal preflight.
- `discard`: drop the selected stash, then continue normal preflight.

If apply conflicts, abort the apply if possible, preserve the stash, and exit with the conflicting paths and recovery instruction.

## Refusal Checks

Refuse before starting when any of these are true:

- Working tree is dirty, unless a resume stash was just applied cleanly.
- Current branch has zero commits ahead of the base.
- HEAD is detached.
- A merge, rebase, cherry-pick, or revert is in progress.

If the current branch is the base branch, warn and ask before continuing. Recommend creating a feature branch.

Detect base from `origin/HEAD`, then `main`, then `master`; ask the user if none resolves.

Every refusal names the problem and the next action.

## Branch Health Checks

Detect a project check command in this order:

1. `mix.exs` aliases: `precommit`, `check`, `quality`, `verify`.
2. `package.json` scripts with similar names.
3. `Makefile` targets such as `check`, `precommit`, `verify`.
4. `CLAUDE.md` or `README.md` project guidance.
5. Language fallback: Elixir uses `mix format --check-formatted && mix compile --warnings-as-errors && mix test`; JS/TS uses `npm test`; Python uses `pytest`.

Report the detected command and ask `run`, `edit`, or `skip`.

- `run`: execute it. On failure, halt with command, exit code, relevant output summary, and recovery hint.
- `edit`: run the user-provided replacement command.
- `skip`: record that checks were skipped so the final commit message can say so.

Do not create or modify project aliases as part of this phase.
