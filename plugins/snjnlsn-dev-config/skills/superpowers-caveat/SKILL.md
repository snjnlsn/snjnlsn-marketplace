---
name: superpowers-caveat
description: Use whenever invoking, following, or delegating from any `superpowers:*` skill. Adds a mandatory caveat: when using Superpowers skills, prefer and adhere to repo-local instructions and opinionated skills for reading, writing, and reviewing code.
---

# Superpowers Caveat

Use Superpowers skills as the base workflow, with this standing rule layered on
top:

**When using Superpowers skills, prefer and adhere to repo-local instructions
and opinionated skills for reading, writing, and reviewing code.**

## Apply This Rule

- Read and follow applicable repo-local instructions such as `AGENTS.md`,
  `CLAUDE.md`, `.agents/instructions.md`, and nested project guidance.
- Prefer repo-local skills or skill guidance for code navigation, code edits,
  testing, verification, review, planning, and subagent prompts.
- Carry the relevant local guidance into dispatched subagent prompts instead of
  assuming a fresh subagent will discover it.
- Treat Superpowers as the general workflow layer. Treat repo-local code-work
  instructions as the controlling layer for how code is read, written, tested,
  and reviewed.

## Scope

This skill does not route to replacement skills and does not copy or override
Superpowers workflows. It only injects the local-code-guidance rule that should
travel with Superpowers usage.
