---
name: use-serena-agents
description: Use when dispatching a subagent for code exploration, architecture design, or code review — routes to the Serena-enabled variants in the overrides plugin instead of the stock feature-dev agents, and ensures every dispatched Agent prompt carries an explicit Serena activation instruction.
---

# Route code-work subagents to Serena-enabled variants

## The problem this solves

The stock `feature-dev:code-explorer`, `feature-dev:code-architect`, and `feature-dev:code-reviewer` agents declare a restricted `tools:` allowlist that omits Serena's MCP tools — so even when the user's CLAUDE.md instructs Serena-first navigation, these subagents *cannot* call Serena. They fall back to `Grep` + `Read`, which is slower and less semantic.

The `overrides` plugin ships mirror agents with identical behavior plus Serena tools in the allowlist and a Serena-first instruction at the top of each system prompt.

## The rule

When dispatching a subagent via the `Agent` tool for any of the following tasks, **always prefer the `overrides:` variant over the `feature-dev:` variant**:

| Task | Use this `subagent_type` | NOT this |
|---|---|---|
| Exploring or understanding an existing feature | `overrides:code-explorer` | `feature-dev:code-explorer` |
| Designing a new feature architecture | `overrides:code-architect` | `feature-dev:code-architect` |
| Reviewing code for bugs / convention compliance | `overrides:code-reviewer` | `feature-dev:code-reviewer` |

This applies regardless of which upstream skill is doing the dispatching — `subagent-driven-development`, `dispatching-parallel-agents`, `executing-plans`, `feature-dev:feature-dev`, ad-hoc direct Agent calls, etc. The override variants are drop-in replacements.

## Always include Serena activation in the prompt

In addition to using the correct `subagent_type`, every dispatched `Agent` prompt for code work must begin with a one-line activation instruction, since fresh subagent contexts do not inherit Serena activation from the parent session:

> "First, call `mcp__serena__check_onboarding_performed` to activate Serena for this project. Prefer Serena's symbolic tools (`find_symbol`, `get_symbols_overview`, `find_referencing_symbols`) over `Read`/`Grep`/`Glob` for code navigation."

The override agents' own system prompts already contain this instruction, so this line is belt-and-suspenders — but it costs nothing and prevents silent regressions if the agent definition ever drifts.

## Exceptions

- `superpowers:code-reviewer` (the superpowers plugin's own code-reviewer) does **not** restrict its tools list, so Serena already works there. If a workflow explicitly calls for it, don't re-route — just include the Serena activation line in the prompt.
- For `Explore`, `Plan`, or `general-purpose` subagent types, no re-routing is needed; their tool allowlists already include MCP tools. Still include the Serena activation line.
- If the user explicitly requests a `feature-dev:*` variant by name, honor that — but flag the tradeoff so they can decide.

## Why this exists

Without this skill, the consistency of Serena usage across subagents depends on whichever skill is building the `Agent` prompt remembering to set the right `subagent_type` and inject the activation line. Those upstream skills are tool-agnostic and don't know about Serena. This skill is the bridge.
