# Large Superpowers Workflow

Load only after gathered project context activates the large-workflow overlay. The activation decision belongs in the design spec and flows into the implementation plan and an execution ledger within the project's `.superpowers/sdd` directory. Upon completing the plan, the ledger and any SDD scratch files should be removed.

## Brainstorming Execution Graph

In addition to the ordinary approved design, define workstreams with:

- goal and completion criteria
- dependencies and blockers
- parallelization eligibility
- file or module ownership
- shared interfaces and invariants
- merge or integration risk
- integration and review order
- model and reasoning assignment

Include rollback, performance, migration, and observability considerations only when relevant.

## Writing-Plans Agent Contracts

Convert each workstream into a self-contained contract containing:

- goal and completion criteria
- exact write scope
- dependencies and required predecessor state
- consumed and produced interfaces
- invariants
- exact verification commands and expected results
- review expectations
- handoff and integration requirements
- model and reasoning assignment

Preserve graph dependencies, ownership, parallelization, and integration order explicitly. Linear numbering does not replace the graph.

## Model Routing

| Role | Model | Reasoning |
|---|---|---|
| Brainstorming, specification, planning, top-level coordination, architectural arbitration, final whole-branch review | `gpt-5.6-sol` | high |
| Integration-heavy implementation, difficult debugging, cross-workstream reconciliation, task review | `gpt-5.6-terra` | high |
| Standard implementation | `gpt-5.6-terra` | medium |
| Mechanical edits, boilerplate, repetitive migrations, straightforward test generation, documentation | `gpt-5.6-luna` | medium |

Keep the top-level coordinator on Sol High. If the current coordinator is not Sol High, pause before planning or execution, recommend switching, and require explicit approval before continuing on the closest available model.

If an assigned model is unavailable, use the closest capability tier and record the substitution. Escalate a worker to Sol High only for an architectural choice the approved graph and contracts do not resolve.

## Subagent Scheduling

Dispatch only work whose dependencies are satisfied.

For this activated overlay, independent implementation work may run in parallel only when:

- write scopes are disjoint
- shared interfaces and invariants are already defined
- integration order is explicit
- each workstream can be reviewed independently

This conditionally overrides the upstream blanket prohibition on parallel implementation subagents. Serialize or repartition work with overlapping write scopes. Return unresolved architectural choices to the Sol High coordinator instead of choosing locally.

Record task status, dependency changes, model substitutions, commits, reviews, and integration state in the execution ledger.

## Scope Changes

If execution invalidates the graph:

1. The discovering worker stops work that depends on the invalidated assumption, bubbles the evidence and impact to the top-level coordinator, and does not revise the approved graph locally.
2. Stop new dispatches.
3. The coordinator decides how to adapt the plan to best handle the invalidation and concisely records the evidence, decision, rationale, affected graph, and resume conditions in a session handoff document.
4. Let safe, non-conflicting work reach a stable checkpoint.
5. Update the design, plan, contracts, dependencies, interfaces, and ownership.
6. Review the changed graph.
7. Resume from the corrected dependency state.

Model strength does not compensate for unclear ownership, unresolved interfaces, or an obsolete plan.
