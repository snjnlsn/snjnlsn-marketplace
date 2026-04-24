---
name: using-overrides
description: Use when about to invoke any skill or dispatch any subagent that has a same-named variant in the `overrides:` plugin — routes to the override instead of the upstream (`superpowers:`, `feature-dev:`) variant, and ensures dispatched Agent prompts carry an explicit Serena activation instruction.
---

# Route to the overrides plugin

## The problem this solves

The `overrides` plugin ships drop-in replacements for selected upstream skills and agents. Each override keeps the same `name:` as its upstream counterpart (so it reads as the same capability) but adds project-specific guidance — primarily Serena-first navigation and Serena MCP tools for subagents.

Because Claude Code namespaces plugins rather than overriding them, both versions appear in the skill/agent list (`superpowers:brainstorming` **and** `overrides:brainstorming`). There is **no built-in precedence rule**. Without this skill, Claude picks arbitrarily — and any upstream cross-reference like "invoke `superpowers:writing-plans`" silently bypasses the override.

This skill is the bridge.

## The rule

**When you would invoke any skill or dispatch any subagent, and an override of the same name exists in the `overrides:` plugin, invoke the `overrides:` variant instead.**

This applies regardless of how the invocation was triggered:
- Direct user request ("use the brainstorming skill")
- Cross-skill reference (a superpowers skill saying "REQUIRED SUB-SKILL: Use superpowers:X")
- Workflow hand-off (brainstorming → writing-plans)
- Implicit description match (Claude deciding based on triggering conditions)
- Ad-hoc `Agent` / `Skill` tool calls

**How to check:** Scan the skill and agent lists in the system prompt for an `overrides:<name>` entry matching the bare name you were about to invoke. If one exists, use it. If not, proceed with the upstream variant.

## Current overrides (for quick reference)

These are concrete at time of writing — but the **rule is general**: always check the live list, don't trust this table alone.

### Skills

| If you'd invoke… | Use instead |
|---|---|
| `superpowers:brainstorming` | `overrides:brainstorming` |
| `superpowers:systematic-debugging` | `overrides:systematic-debugging` |
| `superpowers:writing-plans` | `overrides:writing-plans` |
| `superpowers:receiving-code-review` | `overrides:receiving-code-review` |

### Agents

| Task | Use `subagent_type` | Replaces |
|---|---|---|
| Exploring or understanding an existing feature | `overrides:code-explorer` | `feature-dev:code-explorer` |
| Designing a new feature architecture | `overrides:code-architect` | `feature-dev:code-architect` |
| Reviewing code for bugs / convention compliance | `overrides:code-reviewer` | `feature-dev:code-reviewer` |

## Subagent dispatches must include Serena activation

In addition to routing to the `overrides:` `subagent_type`, every dispatched `Agent` prompt for code work must begin with a one-line activation instruction. Fresh subagent contexts do not inherit Serena activation from the parent session:

> "First, call `mcp__serena__check_onboarding_performed` to activate Serena for this project. Prefer Serena's symbolic tools (`find_symbol`, `get_symbols_overview`, `find_referencing_symbols`) over `Read`/`Grep`/`Glob` for code navigation."

The override agents' system prompts already contain this instruction, so it's belt-and-suspenders — but costs nothing and prevents silent regressions if an agent definition drifts.

## Exceptions

- **`superpowers:code-reviewer`** (the superpowers plugin's own code-reviewer subagent) exposes its full tools list, so Serena already works there. Keep it if a workflow explicitly calls for it — and always include the Serena activation line.
- **`Explore`, `Plan`, `general-purpose`** subagent types — use as-is; their tool allowlists already include MCP tools. Always include the Serena activation line.
- **Explicit user request for a specific variant** — honor it, but flag the tradeoff ("you asked for `superpowers:brainstorming` — note there's an `overrides:brainstorming` with Serena-first exploration guidance; want that instead?").

## Adding a new override

When a new `overrides:<name>` skill or agent is added to this plugin, this skill's rule automatically covers it — no edit required. Update the tables above opportunistically for discoverability, but the general rule is what governs behavior.
