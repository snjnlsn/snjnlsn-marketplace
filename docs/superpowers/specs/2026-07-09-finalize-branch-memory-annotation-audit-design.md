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
3. Follow only memory references that appear relevant to changed code, changed docs, handoff claims, or branch facts.
4. If no `core` memory exists, use memory names as the relevance signal and read only likely matches.
5. Summarize which memories were read, which were skipped as irrelevant, and whether any memory guidance affects later proposals.

Current code remains authoritative. Memories provide context to verify against the branch, not facts that override source, tests, or repo docs.

If no memories exist, or no memories are relevant, finalize should record that briefly and continue.

## Elixir Annotation Audit

Extend the inline code docs phase so Elixir is the primary target.

For introduced or changed Elixir public API, inspect annotation presence and accuracy for:

- `@moduledoc`
- `@doc`
- `@spec`
- `@type`
- `@opaque`
- `@callback`
- `@impl true`

Propose additions or corrections only when the annotation is accurate from the source, callers, tests, or compiler feedback. Prefer no annotation over a guessed type or callback contract.

For Elixir projects, running this command is useful evidence for type/spec warnings:

```bash
mix compile --all-warnings --warnings-as-errors
```

The skill should not blindly require the command if the project is not Elixir or the environment cannot compile. When it runs and fails, the relevant warnings become inputs to annotation proposals or bug reports. The warnings do not automatically justify speculative annotations.

Keep the existing non-Elixir guidance as a fallback: Python docstrings, Rust `///`, and JS/TS JSDoc on exported symbols.

## User Interaction

Memory findings should appear in the audit summary:

- memories read
- memories skipped as irrelevant
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

The plugin cache copy under `~/.codex/plugins/cache/...` is not the canonical source and should not be edited for the repo change.

## Validation

After updating the skill:

1. Confirm the skill tells a future agent where the memory audit happens.
2. Confirm relevance is determined by `core` memory first when present, otherwise memory names.
3. Confirm memories are framed as context to verify, not authority over source.
4. Confirm Elixir annotation coverage includes `@spec`, related type/callback annotations, and `@impl true`.
5. Confirm annotation accuracy is prioritized over completeness.
6. Confirm `mix compile --all-warnings --warnings-as-errors` is mentioned as useful Elixir evidence without becoming an unconditional requirement.
7. Run the available skill/frontmatter validation for the changed skill if one exists in the repo or plugin tooling.
