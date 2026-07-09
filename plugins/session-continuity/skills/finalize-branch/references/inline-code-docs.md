# Inline Code Docs and Annotations

Load this reference for Phase 3 of `finalize-branch`.

## Candidate Selection

From `git diff --name-only <base>..HEAD`, inspect source files only. Skip generated files, lockfiles, fixtures, and binaries.

Use Serena symbol tools to inspect changed structure, symbol bodies, and callers. Include callouts routed to inline code docs and handoff-reference cleanup proposals, and tag those sources in the display.

## Elixir-First Audit

For changed Elixir files, first decide which symbols are intended public API. Inspect exported functions and macros, protocol implementations, behaviour callbacks, and public types. Honor `@doc false`, internal namespaces, and nearby project conventions; an exported `def` is not automatically intended public API.

Inspect presence and accuracy for:

- `@moduledoc` and `@doc`
- `@spec`
- `@type`, `@opaque`, and `@typedoc`
- `@callback`, `@macrocallback`, and `@optional_callbacks`
- `@behaviour`
- `@impl true` and `@impl SomeBehaviour`

Evidence that an annotation category belongs does not by itself make an edit approval-ready; complete annotation content must also be supported by current source, callers, tests, compiler evidence, or live repository docs. For `@doc` and `@typedoc`, semantic wording must come from the actual definition or behavior, callers, tests, compiler evidence, or live repository docs, not merely the symbol name or role. When semantic content is unavailable, report the missing annotation as a finding with no proposal pending verification. If a category is indicated but its signature or contract is incomplete, report an audit finding and a no-proposal-pending-verification outcome; do not show placeholder or guessed types. A handoff or memory claim alone cannot justify `@optional_callbacks`; current project evidence must establish that the callback may be omitted. Until then, report the claimed optionality as a finding with no proposal pending verification.

Either `@impl` form is approval-ready only when a currently declared `@behaviour` defines a matching `@callback` or `@macrocallback` for that symbol and arity. If that matching callback contract is absent or incomplete, report the existing `@impl` as an audit finding with a no-proposal-pending-verification outcome; do not propose replacing `@impl true` with named `@impl` until the exact callback or macrocallback declaration is verified or approved.

Do not add private or internal docs unless an existing private doc is stale.

## Compiler Diagnostic

When the branch changes Elixir source, `mix.exs` exists, and `mix` is available, offer:

```bash
mix compile --all-warnings --warnings-as-errors
```

Skip the offer if that exact command already succeeded during preflight. Otherwise run it only after user approval. The approval offer must state that a warning-caused nonzero result does not halt the Phase 3 annotation audit.

Classify its result before proposing changes:

- Warnings attributable to changed files or symbols may support an annotation proposal or bug report.
- Pre-existing or unrelated warnings are reported separately and do not expand branch scope.
- Environment or dependency failures are recorded as limitations.
- A nonzero exit caused by warnings does not halt the Phase 3 annotation audit and does not justify a speculative annotation.

This diagnostic rule does not change preflight's existing halt behavior for a user-selected branch-health command.

## Non-Elixir Fallback

For other changed source, inspect useful public inline docs and stale contracts using local conventions: Python docstrings, Rust `///`, and JS/TS JSDoc on exported symbols.

## Proposal and Approval Flow

Work one file at a time, or in chunks of 3-5 files for large branches. Number proposals and show concise proposed text or a current/proposed diff. Label each outcome as:

- missing annotation
- stale or inaccurate annotation
- compiler-warning-driven proposal
- no proposal because the accurate type or contract is unclear

User choices:

- approve all
- approve specific numbers
- `nuance: ...`
- skip file
- skip phase

When nuanced, revise only that proposal and re-prompt for approval, another nuance, or revoke.

## Apply Changes

Apply approved changes immediately. Prefer Serena symbolic edits for symbol-attached docs and annotations. Use direct textual edits only when the content is not cleanly tied to a symbol.

After all files, summarize applied and skipped changes. If the diagnostic returned nonzero because of warnings, explicitly state that it did not halt the Phase 3 annotation audit. Then ask whether to proceed to repo docs.
