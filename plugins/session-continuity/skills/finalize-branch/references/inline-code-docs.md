# Inline Code Docs

Load this reference for Phase 2 of `finalize-branch`.

## Candidate Selection

From `git diff --name-only <base>..HEAD`, inspect source files only. Skip generated files, lockfiles, fixtures, and binaries.

Use Serena symbol tools for source structure. Look for:

- New or changed modules lacking useful `@moduledoc` or equivalent.
- New public functions/methods lacking useful `@doc` or equivalent.
- Existing public docs made stale by the branch.
- Obvious missing or stale `@spec` entries. Propose specs only when the type is clear.
- Non-Elixir equivalents: Python docstrings, Rust `///`, JS/TS JSDoc on exported symbols.

Do not add private/internal docs unless an existing private doc is now stale.

Also include:

- Callouts routed to inline code docs.
- Handoff-reference cleanup proposals.

Tag these sourced proposals in the display.

## Approval Flow

Work one file at a time, or chunks of 3-5 files for large branches. For each file, show numbered proposals with concise proposed text or a current/proposed diff.

User choices:

- approve all
- approve specific numbers
- `nuance: ...`
- skip file
- skip phase

When nuanced, revise only that proposal and re-prompt for approval, another nuance, or revoke.

## Apply Changes

Apply approved changes immediately. Prefer Serena symbolic edits for symbol-attached docs. Use direct textual edits only when the doc is not cleanly tied to a symbol.

After all files, summarize applied and skipped doc changes, then ask whether to proceed to repo docs.
