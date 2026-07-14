# Resuming Plan Execution

Use before continuing an interrupted `executing-plans` or `subagent-driven-development` run. The approved plan and durable execution evidence are the source of truth; the previous conversation is not.

1. Load the approved plan, its task list or todos, the latest progress ledger and session handoff when present, prior agent reports, review artifacts, and required project guidance.
2. Reconcile those artifacts with repository evidence: current diff and status, commits, generated artifacts, and verification output. For every plan task, record `not started`, `in progress or interrupted`, `implemented`, `reviewed`, `complete`, or `blocked`, with the evidence that proves the state.
3. Continue the same task order, review gates, contracts, and verification commands from the first task that is not proven complete. Never re-dispatch a task merely because its prior conversation is unavailable.
4. If a subagent was active at cutoff, collect its result if available; otherwise explicitly close it as interrupted. Do not reuse it. If work remains, dispatch a fresh agent with the original bounded contract and the durable artifacts it needs.
5. Resume only work allowed by the reconstructed state. Do not silently re-plan, skip review or verification, or invent missing context. If evidence exposes a contradiction, gap, or invalid assumption, follow the active workflow's blocker or scope-change procedure before continuing.
6. At each material transition, update the progress record with task state, evidence location, verification or review result, blocker, and next valid action. Before an expected cutoff, write the same information to a concise session handoff that identifies exactly what the next session must load.

The resumed session uses the same selected Superpowers workflow and its normal steps; this protocol restores its precise state rather than substituting a new workflow.
