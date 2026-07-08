# Final Commit

Load this reference for Phase 4 of `finalize-branch`.

## Final Review

Show a summary of pending inline-doc edits, repo-doc edits, sourced callout/reference changes, and the exact handoff files about to be deleted.

Ask `yes`, `show diff`, or `cancel`. `show diff` displays uncommitted diff and pending deletes. If no edits were approved and no handoffs are confirmed for deletion, exit with "Nothing to finalize."

Before deletion, defensively halt if any extracted callout lacks a routing decision or any handoff reference lacks a resolution or explicit skip.

## Delete Handoffs

Use `git rm` for each confirmed handoff file, one path at a time.

Never delete:

- `.session-continuity/handoffs/` as a directory.
- `.session-continuity/handoffs/README.md`.
- Any handoff not confirmed in the audit list.

## Stage

Stage only files produced by this skill, by explicit path. Deletes are already staged by `git rm`.

If `git status` shows unrelated changes, pause and ask the user to stage/commit them separately, discard them, continue, or cancel as appropriate. Do not stage unrelated files.

## Commit Message

Use this shape:

```text
docs: finalize <branch-name>

Inline code docs:
  - <terse summary>

Repo docs:
  - <terse summary>

Removed <N> session handoff document(s).
Callouts: <X> to repo docs, <Y> to inline code docs, <Z> already captured, <W> dismissed[, <V> resolved][, <M> smart-merged].
In-code references: <I> inlined, <R> redirected, <X> removed, <S> skipped.
[optional: "(branch health checks skipped)"]
```

Omit `Callouts:` or `In-code references:` when the corresponding phase had none. Show the message and ask `commit`, `edit`, or `cancel`.

Run a normal `git commit`; never amend and never skip hooks. On hook failure, halt with the relevant output and run cancellation retention.

## Cancellation Retention

If the user cancels or the workflow halts after approved edits were applied, ask how to retain them:

1. Stash for resume: `git stash push -m "finalize-branch:<branch>:<ISO-timestamp>" -- <touched paths>`.
2. Commit manually with an editable default message.
3. Keep in working tree.
4. Discard with `git restore <touched paths>`.

If no edits were applied, exit with a one-line cancellation confirmation.

## Final Report

Report:

- commit SHA and subject
- files changed
- handoffs removed
- next action, usually push and open a PR

## Edge Cases

- Empty branch: refuse during preflight.
- Zero handoffs: proceed from commit/diff context only.
- Zero proposals and zero handoffs: no empty commit.
- Base branch undetectable: ask user.
- Edit failure: halt with path, error, recovery hint, and cancellation retention if edits exist.
- External working-tree changes mid-flow: detect before staging and pause.
- Binary files: skip inline-doc candidate building.
- Empty callout heading: present as empty body; default recommendation is dismiss.
- Callout matches in fenced code: ignore.
- Unparseable override file or missing override destination: halt before routing.
- Existing destination heading matches a callout: offer already-captured, but require confirmation.
- User cancels during routing before edits: exit without retention prompt.
