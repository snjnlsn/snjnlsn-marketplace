---
name: good-quality-code
description: Use when writing, architecting, planning, implementing, or reviewing code, including brainstorming/spec work, implementation plans, code review, and Ash/Phoenix/Elixir changes. Defines the standard for readable, maintainable, idiomatic code, module boundaries, tests, and Ash-specific abstraction choices.
---

# Good Quality Code

## Overview

Good code here is explicit, boring, domain-shaped, and easy to change safely.
Use this skill as the quality bar while shaping specs and plans, dispatching
subagents, implementing code, and reviewing changes. It complements workflow
skills; it does not expand scope beyond the approved task.

## Quality Standard

- Optimize for readability. Prefer code another engineer can understand
  quickly over clever abstractions, macros, or indirection.
- Model the domain, not the implementation. Names should describe business
  concepts and caller intent, not plumbing.
- Resist premature abstraction. Remove duplication when the repeated pattern
  has stable semantics or the extraction makes the caller easier to read.
  Localized duplication is acceptable when it keeps behavior obvious.
- Keep modules loosely coupled. Expose small public APIs and hide internals
  behind clear boundaries.
- Prefer clear data transformation pipelines when they make data flow easier
  to follow. Avoid pipelines that hide branching or error handling.
- Leverage pattern matching, guards, and multiple function heads over repeated
  field inspection and deeply nested conditionals.
- Isolate side effects at boundaries. Keep core business logic pure whenever
  practical, and make it testable without mocks.
- When asked to refactor or clean up, remove code, tests, fixtures, skips,
  config, and docs that were introduced before the refactor and are now dead,
  redundant, or asserting obsolete behavior. Keep that cleanup in the same
  change so stale scaffolding does not survive as accidental contract.
- Use OTP and established libraries for runtime concerns. Prefer GenServers,
  Supervisors, Tasks, Oban, and Ash facilities over custom lifecycle systems.
- Follow Elixir conventions: `{:ok, value}` / `{:error, reason}` when useful,
  `!` only when raising is intentional, and `?` suffixes for predicates.
- Value simplicity over cleverness. The solution should be simpler than the
  problem it solves.

## Ash-Specific Quality

- Treat domains and their code interfaces as the caller-facing API.
  Controllers, LiveViews, jobs, services, background workers, and ordinary
  tests should call the domain module instead of building ad hoc Ash queries or
  changesets.
- Keep as much of the model/business slice as practical inside Ash resources
  and actions. Before adding caller-side Elixir orchestration, ask whether the
  behavior belongs in a specific action, action argument, code-interface option,
  preparation, change, validation, calculation, policy, pipeline, relationship
  manager, generic action, or multi-step action.
- Design endpoint interactions to use as few domain/Ash/Postgres calls as
  practical. Shape the action, query, or changeset so Ash owns filtering,
  loading, validation, relationship management, persistence, and derived values;
  avoid iterative caller-side Postgres work and post-Ash Elixir logic when Ash
  can express the operation clearly.
- Keep Ash domain modules declarative. Do not wrap Ash interactions in custom
  domain helper functions to perform loading, permission checks, filtering,
  business logic, or relationship orchestration. Let controllers translate action success/error state into response shape when a web contract requires it.
- Use domain code interfaces for caller contracts. Pass `query:`, `load:`,
  `actor:`, `authorize?:`, `page:`, and other supported options to the code
  interface instead of building raw `Ash.Query`, `Ash.Changeset`, or
  `Ash.get/read/load/create/update/destroy` calls in callers.
- Use action arguments for operation inputs, especially values that need
  validation, coercion, relationship management, or are not persisted
  attributes.
- Use preparations for reusable read/query shaping: filters, sorts, limits,
  default loads, actor-aware query changes, and argument-dependent query
  behavior.
- Use changes for create/update/destroy behavior: setting or deriving
  attributes, lifecycle hooks, side-effect intent, and relationship management.
  Prefer inline built-in changes first, especially hook changes such as
  `before_action`, `after_action`, `before_transaction`, and
  `after_transaction`, before writing pure Elixir helpers that choreograph work
  around an action. Implement reusable or multi-step changes as named
  `Ash.Resource.Change` modules, and prefer `atomic/3` support when the change
  can be expressed atomically.
- Use validations for reusable invariants that reject invalid input without
  mutating it. Use calculations for derived values or projections that belong
  to the resource model and may be loaded, filtered, sorted, or rendered.
- Use pipelines when multiple actions share the same stable bundle of changes,
  validations, and/or preparations. Do not introduce a pipeline merely to make
  one action shorter.
- Use generic actions for behavior that belongs in Ash but is not naturally a
  create/read/update/destroy on one record. Use multi-step actions or action
  runner modules when an operation coordinates multiple Ash calls, transaction
  boundaries, policy context, or side-effect intent but should still be exposed
  as one native domain operation.
- Keep Ash resources readable. A resource should reveal its attributes,
  relationships, actions, policies, calculations, and identities without
  forcing the reader through unnecessary wrappers.
- Prefer Ash relationship management for write actions that create, update,
  replace, remove, or otherwise change related records. Use action-level
  `manage_relationship(...)` when action arguments carry the related data, or
  `Ash.Changeset.manage_relationship/4` inside a named custom change when the
  related values are computed. Direct domain-code-interface orchestration is a
  fallback only when the relationship operation cannot be expressed cleanly
  through Ash relationship management.
- Use bulk create/update/destroy when the operation is set-oriented and uniform
  across many records. Design the underlying actions, changes, and validations
  to remain atomic and bulk-friendly where practical; reach for iterative
  per-record calls only when the operation genuinely varies per record or needs
  per-record external coordination.
- Use separate modules for Ash calculations, changes, preparations,
  validations, embedded resources, custom types, generic action runners, and
  policy helpers when the extraction is DRY, named by the domain concept, and
  improves readability or testability. Do not extract Ash modules just to make
  a file shorter.
- Put extracted Ash modules in the owning domain namespace and matching folder
  (`changes`, `calculations`, `validations`, `preparations`, `types`,
  embedded-resource folders, etc.) so navigation stays predictable.
- Prefer explicit system actors over broad `authorize?: false` for privileged
  internal work. Keep authorization bypasses narrow, named, and test-covered.
- Preserve clean internal models even when external payloads are awkward. Put
  compatibility translation at ingestion and response-shaping boundaries.
- Name Ash attributes by business meaning.
- When creating an Ash resource, prefer organized
  attribute lists, enum/state fields, embedded values, and state machines over boolean-derived state.

## Testing Standard

- Tests should verify behavior, not implementation trivia or mocks.
- Use `Ash.Generator` and real actions for test data unless the test is about a
  deliberate bypass.
- Test through domain code interfaces. Raw Ash APIs belong in focused resource,
  policy, generator, or framework-integration tests where that API is the
  subject.
- Cover the boundary that owns the behavior: resource/action tests for domain
  rules, ingestion tests for external data mapping, controller/journey tests
  for HTTP behavior, and architecture tests for repo-wide conventions.

## Review Questions

Ask these before calling work complete:

1. Is the intent immediately clear?
2. Does the naming reflect the domain?
3. Is any abstraction premature or too clever?
4. Can pattern matching replace branching?
5. Are side effects isolated at boundaries?
6. Is OTP, Ash, or an existing project pattern doing work a custom abstraction
   is trying to do?
7. Is each module boundary well-defined and easy to test?
8. Would a new team member understand this quickly?
9. Is there unnecessary coupling between modules?
10. Did the refactor delete obsolete code and tests from the pre-refactor
    shape?
11. Does the test suite prove the behavior that matters?
