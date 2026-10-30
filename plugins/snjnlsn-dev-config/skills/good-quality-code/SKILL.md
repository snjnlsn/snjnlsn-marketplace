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

Apply the general standards to all code. Apply language and framework sections
only when the code uses that language or framework. Follow explicit repository
instructions and established language conventions. Do not introduce another
language's patterns solely to satisfy this skill. Apply these requirements to
code within the task's scope; do not expand a change into a repository-wide cleanup.

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
- Use idiomatic language features to make control flow clear. Avoid repeated
  field inspection and deeply nested conditionals.
- Isolate side effects at boundaries. Keep core business logic pure whenever
  practical, and make it testable without mocks.
- When asked to refactor or clean up, remove code, tests, fixtures, skips,
  config, and docs that were introduced before the refactor and are now dead,
  redundant, or asserting obsolete behavior. Keep that cleanup in the same
  change so stale scaffolding does not survive as accidental contract.
- Use established runtime and library facilities before building custom
  lifecycle systems.
- Value simplicity over cleverness. The solution should be simpler than the
  problem it solves.

## Documentation and Comments

Use ASD-STE100 Simplified Technical English for documentation and code comments.
Use short sentences, active voice, direct instructions, and consistent technical
terms. Keep each sentence focused on one idea. Preserve exact identifiers, API
names, commands, paths, and quoted text. Simplify the prose without changing its
technical meaning.

### Documentation and API Contracts

- Document each module's purpose and responsibilities with the language's
  standard documentation format.
- Document public API contracts. Describe inputs, results, and relevant errors
  or side effects. Explain constraints that callers need to know.
- Use idiomatic type declarations or annotations to make contracts explicit.
  A typed function signature can satisfy this requirement; do not repeat its
  types in a separate annotation or comment.
- Mark interface or callback implementations when the language supports an
  explicit marker. Do not invent one when it does not.
- Keep documentation and types consistent with the implementation. Explain
  intent and contracts instead of restating names or code.
- If code is generated, update its source or generator when that is in scope.
  Do not edit generated output solely to add annotations.

## Elixir Conventions

Apply this section to Elixir code only.

- Prefer pattern matching, guards, and multiple function heads when they make
  control flow clearer than repeated field inspection or nested conditionals.
- Use OTP and established libraries for runtime concerns. Prefer GenServers,
  Supervisors, Tasks, Oban, and, in Ash projects, Ash facilities over custom
  lifecycle systems.
- Follow Elixir conventions: `{:ok, value}` / `{:error, reason}` when useful,
  `!` only when raising is intentional, and `?` suffixes for predicates.
- Populate `@moduledoc` with the module's purpose and responsibilities.
  If a module is intentionally excluded from published documentation, use
  `@moduledoc false` and explain its purpose in a short module-level comment.
- Add `@doc` to public functions. For behaviour callbacks, use the behaviour's
  documentation and add local documentation when the implementation introduces
  constraints or side effects that callers need to know. For an intentionally
  hidden public function, use `@doc false`.
- Mark behaviour callback implementations with `@impl true` or the specific
  behaviour module. Use the module when it is needed to identify the contract.
- Add meaningful `@spec` declarations to public and private functions. Describe
  the actual inputs and results, including error tuples. Use named types for
  shared domain concepts. Avoid broad types that hide a known contract.

## Ash-Specific Quality

Apply this section only to code that uses Ash.

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

### Ash Testing

- Use `Ash.Generator` and real actions for test data unless the test is about a
  deliberate bypass.
- Test through domain code interfaces. Raw Ash APIs belong in focused resource,
  policy, generator, or framework-integration tests where that API is the
  subject.

## Testing Standard

### Test-Driven Development

- For new behavior and bug fixes, use short red-green-refactor cycles. Define
  an observable result, write a focused test, and run it before implementation.
  Confirm that it fails because the behavior is missing or incorrect, not
  because the test setup is broken. Add the smallest correct implementation,
  confirm that the test passes, then refactor while the tests remain green.
- For a bug fix, reproduce the defect in a regression test before fixing it
  when a reliable automated reproduction is practical. If it is not, record
  the limitation and use the closest reliable check without claiming that it
  reproduces the defect.
- Before changing unfamiliar or untested behavior, add characterization tests
  for the contracts that must remain stable. Do not preserve a known defect as
  the desired contract. For a refactor, use existing tests when they already
  cover the affected behavior.
- Use exploratory checks to resolve uncertainty before writing a lasting test.
  Do not add tests that only restate implementation details or cover reversible,
  low-impact prose, metadata, or formatting changes. Use proportionate validation
  for those changes. Follow explicit repository testing requirements.

### Choose Tests by Risk and Boundary

Choose the lowest-cost test that can detect the relevant failure at the boundary
that owns it. Add another level when it covers a distinct failure mode. A task
does not need every test type, and a unit test does not prove that components
work together.

| Test type | Use when | Keep focused on |
|---|---|---|
| Unit | Rules, transformations, validation, or edge cases can be checked in isolation. | Observable inputs and results, with fast, precise failures. |
| Integration | Correctness depends on components working together, such as persistence, transactions, authorization, HTTP contracts, or job execution. | Real project components and relevant infrastructure; verify contracts and side effects across the boundary. |
| Browser | Correctness depends on browser behavior, such as JavaScript, DOM interaction, navigation, focus, or a critical user journey. | A small set of valuable journeys and browser-specific risks; use lower-level tests for exhaustive rule combinations. |
| Property | A meaningful invariant applies across many inputs or operation sequences, such as round trips, ordering, idempotency, or state transitions. | Domain-valid generators, useful edge cases, and an oracle independent of the implementation. |

- Test through the API that owns the contract. Use lower-level APIs in focused
  tests where those APIs are the subject. For framework-rendered UI tests,
  identify which browser behavior remains untested.
- For jobs, test enqueue arguments and worker effects separately. Add an
  enqueue-to-execution integration test when their connection is a material risk.
- For property tests, preserve reproducible seeds and use shrinking when the
  tool supports it. Keep explicit regression examples for known defects.
  Do not add randomized tests without a clear invariant.
- For concurrency or recovery risks, exercise the relevant overlap, failure,
  and recovery conditions. Sequential happy-path tests do not establish these
  guarantees.

### Reliable and Efficient Execution

- Test observable behavior and meaningful failure paths. Avoid assertions on
  private structure, incidental call order, or mocks alone. Coverage metrics
  can reveal gaps; they are not a substitute for useful assertions.
- Use the project's standard test-data tools. Keep fixtures small and isolate
  mutable state. Use real components where their interaction is the subject.
  Use test doubles at controlled external boundaries when needed, and verify
  those contracts with suitable integration or contract checks.
- Control clocks, randomness, and external dependencies. For asynchronous or
  browser tests, wait for observable conditions with bounded timeouts instead
  of fixed sleeps. Do not use retries to hide failures; investigate flaky tests.
- Run focused tests during each development cycle. Before completion, run
  affected suites and repository-required checks. Expand testing when shared
  behavior, integration risk, or failures justify it. Do not repeat broad suites
  without a new change or unresolved concern.
- Report what was checked, what passed, and material gaps or skipped checks.
  Distinguish manual observations from automated regression coverage.

## Review Questions

Ask these before calling work complete:

1. Is the intent immediately clear?
2. Does the naming reflect the domain?
3. Is any abstraction premature or too clever?
4. Can idiomatic language features make control flow clearer?
5. Are side effects isolated at boundaries?
6. Can an existing runtime facility, library, or project pattern do the work
   of a custom abstraction?
7. Is each module boundary well-defined and easy to test?
8. Would a new team member understand this quickly?
9. Is there unnecessary coupling between modules?
10. Did the refactor delete obsolete code and tests from the pre-refactor
    shape?
11. Does the test suite prove the behavior that matters?
12. Are module purposes and public contracts documented, types accurate, and
    implementation markers present where applicable?
13. For Elixir code, are `@moduledoc`, `@doc`, `@impl`, and `@spec` present and
    accurate under the rules above?
14. Did the change use an appropriate red-green-refactor cycle or a justified
    alternative, and do the selected test levels cover its actual risks?
15. Are tests deterministic, focused on contracts, and free of redundant
    coverage that adds cost without detecting a distinct failure?
