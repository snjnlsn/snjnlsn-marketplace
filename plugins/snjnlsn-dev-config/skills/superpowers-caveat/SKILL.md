---
name: superpowers-caveat
description: Use when invoking, following, or delegating from any `superpowers:*` skill.
---

# Superpowers Caveat

Use Superpowers as the base workflow, with repo-local guidance controlling how code is read, written, tested, reviewed, and delegated.

## Apply Local Guidance

- Read applicable `AGENTS.md`, `CLAUDE.md`, `.agents/instructions.md`, and nested project guidance.
- Prefer repo-local skills for navigation, edits, testing, verification, review, planning, and subagent prompts.
- Carry relevant local guidance into dispatched agent contracts.

## Classify Large Work After Context

Do not classify from the opening request. During brainstorming, first gather enough project context to understand the complete implementation surface.

Activate the large-workflow overlay when the gathered scope suggests any one of:

- at least 5,000 changed lines
- at least 30 minutes of agent execution
- several coordinated workstreams
- meaningful integration or merge risk
- consequential architecture, migration, security, or data work

When near a threshold, activate if uncertainty suggests substantial hidden work. Record the decision and reasons in the design spec. When entering planning or execution, inherit the recorded decision from the approved spec or plan.

If activated, read `references/large-workflow.md` before finishing brainstorming and carry its graph, contract, model, and scheduling rules through planning and execution.

## Scope

Do not fork or edit bundled Superpowers skills. The activated overlay may override upstream model routing and the blanket parallel-worker prohibition only under the conditions in `references/large-workflow.md`. Routine work keeps ordinary Superpowers behavior.
