# Large Superpowers Workflow

Load only after gathered project context activates the large-workflow overlay. The activation decision belongs in the design spec and flows into the implementation plan and an execution ledger within the project's `.superpowers/sdd` directory. Upon completing the plan, the ledger and any SDD scratch files should be removed.

## Brainstorming Execution Graph

In addition to the ordinary approved design, define workstreams with:

- goal and completion criteria
- dependencies and blockers
- parallelization eligibility
- ready-work boundary: the exact predecessor state that makes the workstream dispatchable
- file or module ownership
- shared interfaces and invariants
- merge or integration risk
- integration and review order
- capability and reasoning needs

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
- capability and reasoning needs

Preserve graph dependencies, ownership, parallelization, and integration order explicitly. Linear numbering does not replace the graph.

## Capability Selection

Codex chooses the available model and reasoning level that fit each role. Use stronger reasoning for architecture, ambiguous cross-workstream decisions, difficult debugging, and whole-branch review; use an efficient capable option for bounded, low-risk mechanical work. Match the choice to complexity, risk, required context, and autonomy rather than a fixed model name. Record any material capability constraint or escalation in the execution ledger.

## Subagent Scheduling

Dispatch only work whose dependencies are satisfied. Treat every unblocked, independently reviewable workstream as ready work: organize the graph and contracts so it can start asynchronously, then dispatch it promptly instead of holding it behind unrelated work. Do not serialize ready work merely to keep a linear plan or to await an agent that is not a dependency.

For this activated overlay, independent implementation work may run in parallel only when:

- write scopes are disjoint
- shared interfaces and invariants are already defined
- integration order is explicit
- each workstream can be reviewed independently

This conditionally overrides the upstream blanket prohibition on parallel implementation subagents. Serialize or repartition work with overlapping write scopes. Return unresolved architectural choices to the top-level coordinator instead of choosing locally.

Run ready workstreams concurrently when capacity permits. While they run, coordinate integration-ready work, review completed outputs, and advance newly unblocked work; do not turn an otherwise asynchronous workflow into a sequence of blocking waits. Preserve a clearly owned integration lane for shared interfaces and final reconciliation.

Each subagent receives one bounded contract. Once it has delivered its completion evidence, review or collect it, explicitly close or terminate that subagent, and record the closure in the ledger. Never recycle a completed subagent for a different task; dispatch a new agent with a new contract instead.

Record task status, dependency changes, capability constraints, commits, reviews, integration state, and agent closures in the execution ledger.

## Resuming an Interrupted Plan

First apply `resuming-plans.md`. Execution must be recoverable without the prior chat context. Keep the approved design, approved plan, workstream contracts, execution ledger, and session handoffs available until the plan is verified complete and integrated. The ledger is the authoritative execution state, not a convenience note.

Before a resumed execution dispatches work, read the approved artifacts and the latest handoff, then reconcile them with repository evidence: current diff and status, commits, verification output, and any completed agent results. Reconstruct each original workstream as `not started`, `running or interrupted`, `completed`, `reviewed`, `integrated`, or `blocked`, including its dependencies, contract, ownership, and closure state.

Continue the same graph and contracts from the reconstructed dependency state. Dispatch only the original ready work; do not silently re-brainstorm, replace the plan, or guess at omitted context. If evidence invalidates the plan, follow **Scope Changes** before resuming. If an agent was active at cutoff, do not assume it is reusable: collect or close it, record the result, then dispatch a new agent with the same bounded contract if work remains.

At every material state change, update the ledger with the evidence location, next ready work, blockers, and integration position. Before an expected context cutoff, update the ledger and create a concise session handoff that names the exact artifacts to load and the next valid actions.

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
