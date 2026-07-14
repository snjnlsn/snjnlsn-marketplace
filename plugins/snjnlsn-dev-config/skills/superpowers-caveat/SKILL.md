---
name: superpowers-caveat
description: Use when invoking, following, or delegating from any `superpowers:*` skill, and when resuming a superpowers plan.
---

# Superpowers Caveat

Use Superpowers as base workflow; repo-local guidance controls work and delegation.

## Local Guidance

Read applicable `AGENTS.md`, `CLAUDE.md`, `.agents/instructions.md`, and nested guidance. Prefer repo-local skills for navigation, edits, testing, verification, review, planning, and subagent prompts. Carry it into dispatched agent contracts.

## Large Work

During brainstorming, gather context for the implementation surface before classification; never from the opening request.

Activate the overlay when scope suggests one of:

- at least 5,000 changed lines
- at least 30 minutes of agent execution
- several coordinated workstreams
- meaningful integration or merge risk
- consequential architecture, migration, security, or data work

Near a threshold, activate when uncertainty indicates substantial hidden work. Record the decision and reasons in the design spec. Planning and execution inherit it from the approved spec or plan.

If activated, read `references/large-workflow.md` before finishing brainstorming and carry its graph, contract, capability-selection, scheduling, and agent-closure rules through planning and execution.

## Resuming a Plan

When resuming `executing-plans` or `subagent-driven-development` after a context cutoff, read `references/resuming-plans.md` before dispatching work, changing the plan, or treating any task as complete. Reconstruct and continue the same execution flow from the approved artifacts and repository evidence, not conversation memory.

For an activated large-workflow overlay, also read the overlay-specific resume requirements in `references/large-workflow.md`. The overlay extends this protocol; it does not replace it.

## Scope

Do not fork or edit bundled Superpowers skills. Under `references/large-workflow.md`, the activated overlay may override only upstream capability selection and the blanket parallel-worker prohibition. Routine work keeps ordinary Superpowers behavior.
