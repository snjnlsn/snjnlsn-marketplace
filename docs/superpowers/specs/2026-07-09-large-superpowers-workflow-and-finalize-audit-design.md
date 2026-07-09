# Large Superpowers Workflow and Finalize Audit Design

## Goal

Extend `snjnlsn-dev-config:superpowers-caveat` with a conditional large-workflow overlay for `superpowers:brainstorming`, `superpowers:writing-plans`, and `superpowers:subagent-driven-development`, then execute the approved `session-continuity:finalize-branch` memory and Elixir annotation update under that policy.

The combined implementation must produce one execution plan with two ordered workstreams. The caveat workstream is a strict prerequisite for the finalize-branch workstream.

## Chosen Structure

Keep the always-loaded caveat concise. Add a focused reference containing the large-workflow policy, and require the caveat to load that reference only after the gathered project context shows that the overlay applies.

This preserves the caveat's current repo-local precedence rule without charging routine Superpowers work for a large orchestration policy it does not need.

## Activation Timing

Do not classify an effort from its opening request.

During `superpowers:brainstorming`:

1. Inspect the codebase, affected systems, constraints, dependencies, migrations, testing surface, and likely workstreams.
2. Build the big-picture view of all work needed to satisfy the request.
3. Only then decide whether the large-workflow overlay applies.
4. Record the decision and its reasons in the design spec so later phases inherit it without reclassification.

When entering through `superpowers:writing-plans` or `superpowers:subagent-driven-development`, derive the decision from the approved spec or plan. Do not reclassify from a short execution prompt.

Activate the overlay when the gathered scope suggests any one of:

- at least 5,000 lines of implementation change
- at least 30 minutes of agent execution
- several coordinated workstreams
- meaningful cross-workstream integration or merge risk
- unusually consequential architecture, migration, security, or data work

When an estimate is near a threshold, or uncertainty itself suggests substantial hidden work, activate the overlay.

### Decision for This Effort

Activate the large-workflow overlay for the combined caveat and finalize-branch work. It has two coordinated skill workstreams, repeated fresh-context behavioral validation, prerequisite ordering, and an expected execution time above 30 minutes.

## Workflow Contract

### Brainstorming

For an activated effort, `superpowers:brainstorming` must produce an execution graph in addition to the ordinary approved design.

Each workstream records:

- goal and completion criteria
- dependencies and blockers
- parallelization eligibility
- file or module ownership
- shared interfaces and invariants
- merge or integration risk
- integration and review order
- assigned model and reasoning effort

Include rollback, performance, migration, and observability considerations only when relevant to the workstream.

### Writing Plans

`superpowers:writing-plans` converts every workstream into a self-contained agent contract. Each contract includes:

- goal and completion criteria
- exact write scope
- dependencies and required predecessor state
- consumed and produced interfaces
- invariants that must remain true
- exact verification commands and expected results
- review expectations
- handoff and integration requirements
- model and reasoning assignment

The plan preserves the graph explicitly. Linear task numbering must not erase dependency, ownership, parallelization, or integration information.

### Subagent-Driven Development

`superpowers:subagent-driven-development` consumes the graph and contracts as binding execution inputs.

- Keep the top-level coordinator on GPT-5.6 Sol High throughout the run.
- Dispatch only workers whose dependencies are satisfied.
- For the activated large workflow only, override the upstream blanket prohibition on parallel implementation subagents when workstreams have satisfied dependencies, disjoint write scopes, and an explicit integration order.
- Never run workers with overlapping write scopes in parallel. Serialize them or repartition ownership before dispatch.
- Integrate and review work in graph order rather than assuming numeric task order is sufficient.
- Require workers to return unresolved architectural choices to the coordinator instead of choosing locally.
- Record model substitutions and graph revisions in the execution ledger.

## Model Routing

| Role | Default model |
|---|---|
| Brainstorming, specification, implementation planning, top-level coordination, architectural arbitration, final whole-branch review | GPT-5.6 Sol High |
| Integration-heavy implementation, difficult debugging, cross-workstream reconciliation, task review | GPT-5.6 Terra High |
| Standard implementation workers | GPT-5.6 Terra Medium |
| Mechanical edits, boilerplate, repetitive migrations, straightforward test generation, documentation updates | GPT-5.6 Luna Medium |

Escalate a worker to Sol High only when the approved graph and contracts do not resolve an architectural decision. If a named model is unavailable, choose the closest available capability tier and record the substitution.

The caveat cannot always switch the current top-level session. When the large workflow activates and the coordinator is not Sol High, pause before planning or execution, recommend switching to Sol High, and require explicit user approval before continuing on the closest available model.

## Scope Change Handling

If execution reveals that the graph is materially wrong:

1. Stop dispatching new work.
2. Let currently safe, non-conflicting work reach a stable checkpoint.
3. Update the design, plan, affected contracts, dependencies, and ownership boundaries.
4. Re-review the changed graph.
5. Resume from the corrected dependency state.

Model strength does not compensate for unclear ownership, unresolved interfaces, or an obsolete plan.

## Combined Workstreams

### Workstream A: Large-Workflow Caveat

Update the canonical `superpowers-caveat` skill to route qualifying efforts to the large-workflow reference while retaining the existing repo-local precedence rule.

Expected source files:

- `plugins/snjnlsn-dev-config/skills/superpowers-caveat/SKILL.md`
- `plugins/snjnlsn-dev-config/skills/superpowers-caveat/references/large-workflow.md`
- `plugins/snjnlsn-dev-config/skills/superpowers-caveat/agents/openai.yaml` if its user-facing metadata becomes stale
- `plugins/snjnlsn-dev-config/README.md` if its skill summary becomes stale

Workstream A must be behaviorally validated and committed before Workstream B begins.

### Workstream B: Finalize-Branch Memory and Annotation Audit

Absorb every requirement from:

- `docs/superpowers/specs/2026-07-09-finalize-branch-memory-annotation-audit-design.md`
- `docs/superpowers/plans/2026-07-09-finalize-branch-memory-annotation-audit.md`

The combined implementation plan becomes the sole execution artifact. It must inline the existing finalize tasks, prompts, scorecards, file boundaries, and verification steps rather than telling an executor to run the old plan separately.

Workstream B retains these core outcomes:

- relevance-based Serena memory auditing during the handoff and branch-facts phase
- `core`-first relevance mapping with memory-name fallback
- current code, tests, and repo docs as authority over memory
- an Elixir-first annotation audit covering docs, specs, types and type docs, callbacks, behaviours, and implementation annotations
- public API selection that honors `@doc false`, internal namespaces, protocols, macros, and local conventions
- approval-gated `mix compile --all-warnings --warnings-as-errors` evidence scoped to changed code
- no speculative types or contracts
- behavioral baseline and treatment testing before deployment

Expected source files:

- `plugins/session-continuity/skills/finalize-branch/SKILL.md`
- `plugins/session-continuity/skills/finalize-branch/references/memory-audit.md`
- `plugins/session-continuity/skills/finalize-branch/references/inline-code-docs.md`
- `plugins/session-continuity/skills/finalize-branch/agents/openai.yaml` only if metadata becomes stale

## Validation

### Caveat Baseline and Treatment

Before editing Workstream A, run fresh-context scenarios against the current caveat and record the baseline behavior. Re-run the same scenarios after the change.

Required scenarios:

1. A small task remains on ordinary Superpowers behavior.
2. A request that initially appears small grows beyond 5,000 lines only after project context is gathered; activation occurs after the big picture is known.
3. A 30-minute-or-longer effort produces an execution graph, agent contracts, and explicit model assignments.
4. Independent workstreams with satisfied dependencies, disjoint write scopes, and explicit integration order may run in parallel.
5. Overlapping write scopes are serialized or repartitioned before dispatch.
6. An unresolved worker-level architectural decision returns to the Sol High coordinator.
7. A non-Sol coordinator pauses for a model switch or explicit fallback approval.

Use multiple fresh-context repetitions for behavior-shaping wording, manually inspect every output, and require convergence rather than relying only on keyword matching.

### Finalize Baseline and Treatment

Run the control, treatment, and incomplete-memory scenarios defined by the existing finalize plan. Confirm the revised skill selects relevant memory, covers the complete Elixir annotation relationships, attributes compiler warnings to changed code, preserves intentional internal documentation choices, and declines unclear specs.

### Static and Integration Checks

- Run skill/frontmatter validation for both changed skill folders.
- Verify `agents/openai.yaml` files still match their skills; regenerate only stale metadata.
- Verify plugin manifests, marketplace files, and installed cache copies are unchanged unless a separately approved release step requires them.
- Review each workstream independently before its commit.
- Run a Sol High whole-branch review after both workstreams pass.
- Confirm Workstream B did not begin before Workstream A was validated and committed.

## Non-Goals

- Do not edit bundled or cached Superpowers skills.
- Do not fork or wholesale replace Superpowers workflows. Limit overrides to the activated model-routing, contract, and disjoint-workstream scheduling rules defined here.
- Do not activate the large workflow before gathering enough context to understand the complete effort.
- Do not force execution graphs, model routing, or agent contracts onto routine work below the activation criteria.
- Do not parallelize implementation work outside the activated large workflow or without satisfied dependencies, disjoint write scopes, and explicit integration order.
- Do not modify installed plugin-cache copies as canonical source.
