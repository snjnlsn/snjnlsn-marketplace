# Finalize Branch Memory and Annotation Audit Design

## Goal

Update `session-continuity:finalize-branch` so finalization uses relevant Serena memories as project context and performs a stronger Elixir-first annotation audit for introduced or changed code.

This is a targeted change to the existing finalize flow. It should not turn finalization into broad documentation archaeology or require annotation churn where types cannot be verified.

## Problem

The current skill audits handoffs, branch facts, inline code docs, and repo docs, but it does not explicitly check Serena memories. That can miss stable project conventions captured outside the repo or earlier sessions.

The current inline docs guidance mentions `@spec`, but it is too narrow for Elixir code that introduces or changes public API, callbacks, types, or behaviour implementations. It also lacks a concrete way to surface type/spec warnings before proposing annotation edits.

## Chosen Approach

Add the memory audit to the existing "Audit handoffs and branch facts" phase, before finalize compares branch facts with current code and proposes documentation changes.

This keeps preflight focused on git safety and branch health while ensuring project memory context is available before doc and annotation decisions.

## Memory Audit

During the audit phase, use Serena memory tooling:

1. Call `list_memories`.
2. If a `core` memory exists, read it first and treat it as the relevance map.
3. Compare the changed paths and symbols, changed docs, handoff claims, and branch facts with the topics and memory references described by `core`.
4. Read only memories that the comparison identifies as likely to affect the branch audit.
5. If `core` is absent, incomplete, unreadable, or does not cover the branch topics, use the remaining memory names as a secondary relevance signal and read only likely matches.
6. If a referenced memory is unavailable or unreadable, record that limitation and continue with the evidence that is available.
7. Summarize memories read, the count of memories skipped as irrelevant, and whether memory guidance affects later proposals. Name skipped memories only when the name explains a decision or limitation.

Current code remains authoritative. Memories provide context to verify against the branch, not facts that override source, tests, or repo docs.

If Serena memory tooling is unavailable, or if no memories exist or are relevant, finalize should record that briefly and continue. It should not search Serena's storage directly or halt finalization solely because memory context is unavailable.

## Elixir Annotation Audit

Extend the inline code docs phase so Elixir is the primary target.

For introduced or changed Elixir public API, inspect annotation presence and accuracy for:

- `@moduledoc`
- `@doc`
- `@spec`
- `@type`
- `@opaque`
- `@typedoc`
- `@callback`
- `@macrocallback`
- `@optional_callbacks`
- `@behaviour`
- `@impl true` and `@impl SomeBehaviour`

Treat a symbol as intended public API only when the changed code and project conventions support that conclusion. Inspect exported functions, macros, protocol implementations, behaviour callbacks, and public types, while honoring `@doc false`, internal namespaces, and nearby documentation conventions. Do not infer that every exported `def` is intended as documented public API.

Propose additions or corrections only when the annotation is accurate from the source, callers, tests, or compiler feedback. Prefer no annotation over a guessed type or callback contract.

For Elixir projects, running this command is useful evidence for type/spec warnings:

```bash
mix compile --all-warnings --warnings-as-errors
```

For branches with introduced or changed Elixir source, offer this command during the inline annotation phase unless the exact command already ran successfully during preflight. Keep the annotation-phase run approval-gated like the existing branch-health checks.

Treat the result as diagnostic evidence rather than an automatic finalization gate:

- Attribute warnings to changed files or symbols before using them in an annotation proposal.
- Use warnings attributable to introduced or changed code as proposal or bug-report evidence.
- Report unrelated or pre-existing warnings separately without expanding the branch scope.
- Record environment or dependency failures as limitations and continue the annotation audit.
- Do not treat a nonzero exit caused by warnings as an automatic halt or as justification for speculative annotations.

This non-blocking policy applies to the annotation-phase diagnostic. It does not change the existing preflight policy for a user-selected branch-health command. Do not offer the diagnostic for non-Elixir branches, when `mix.exs` is absent, or when the `mix` executable is unavailable.

Keep the existing non-Elixir guidance as a fallback: Python docstrings, Rust `///`, and JS/TS JSDoc on exported symbols.

## User Interaction

Memory findings should appear in the audit summary:

- memories read
- count of memories skipped as irrelevant, naming individual skipped memories only when useful
- unavailable or unreadable memory context
- memory guidance that affects a proposed handoff, inline-doc, repo-doc, or annotation decision

Annotation proposals should remain approval-gated with the current inline docs flow. They should clearly distinguish:

- missing annotation
- stale or inaccurate annotation
- compiler-warning-driven proposal
- no proposal because the accurate type or contract is unclear

## Implementation Scope

Expected files:

- `plugins/session-continuity/skills/finalize-branch/SKILL.md`
- `plugins/session-continuity/skills/finalize-branch/references/inline-code-docs.md`
- optionally a small new reference if the memory audit would make `SKILL.md` too dense

While editing `inline-code-docs.md`, correct its stale phase label so it matches Phase 3 in the main skill. Check `agents/openai.yaml` after the skill edit and regenerate it only if its user-facing metadata no longer matches the skill.

The plugin cache copy under `~/.codex/plugins/cache/...` is not the canonical source and should not be edited for the repo change.

## Validation

Validate the behavior before and after updating the skill:

1. Before editing the skill, run a baseline application scenario against the current skill. Use isolated fixture data or tool-result stubs rather than changing project memories. The fixture should include a `core` memory, one relevant memory, one irrelevant memory, changed Elixir types or callbacks, one warning attributable to changed code, one unrelated warning, and an intentionally unclear type that must not receive a guessed spec. Record the current skill's omissions or incorrect decisions.
2. After editing, rerun the same scenario and confirm the revised skill reads `core`, selects only relevant memory, aggregates irrelevant memory reporting, scopes compiler warnings to changed code, inspects the full Elixir annotation relationships, and declines the unclear spec.
3. Add an edge-case scenario where `core` is incomplete or a memory is unreadable. Confirm the skill falls back to memory names, reports the limitation, and continues.
4. Confirm the skill tells a future agent that the memory audit happens during the handoff and branch-facts phase.
5. Confirm memories are framed as context to verify, not authority over source.
6. Confirm public API selection honors `@doc false`, internal namespaces, macros, protocols, behaviours, and local conventions.
7. Confirm Elixir coverage includes docs, specs, types and type docs, callbacks and macro callbacks, optional callbacks, behaviours, and both forms of `@impl`.
8. Confirm annotation accuracy is prioritized over completeness.
9. Confirm `mix compile --all-warnings --warnings-as-errors` is approval-gated in the annotation phase, reused when it already succeeded during preflight, non-blocking as an annotation diagnostic, and scoped to warnings attributable to changed code.
10. Confirm `inline-code-docs.md` identifies itself as Phase 3 and `agents/openai.yaml` still matches the skill.
11. Run the available skill/frontmatter validation for the changed skill if one exists in the repo or plugin tooling.
