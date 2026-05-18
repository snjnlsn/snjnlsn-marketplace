---
name: using-overrides
description: Use when about to invoke any skill or dispatch any subagent that has a same-named variant in the `overrides:` plugin — routes to the override instead of the upstream (`superpowers:`) variant, and supplies the canonical MCP toolkit guidance that all overrides reference.
---

# Route to the overrides plugin

## The problem this solves

The `overrides` plugin ships drop-in replacements for selected upstream skills and agents. Each override keeps the same `name:` as its upstream counterpart (so it reads as the same capability) but adds project-specific guidance — primarily MCP-first navigation (Tidewave, Context7, Serena) for both parent contexts and dispatched subagents.

Because Claude Code namespaces plugins rather than overriding them, both versions appear in the skill/agent list (`superpowers:brainstorming` **and** `overrides:brainstorming`). There is **no built-in precedence rule**. Without this skill, Claude picks arbitrarily — and any upstream cross-reference like "invoke `superpowers:writing-plans`" silently bypasses the override.

This skill is the bridge, and the canonical home for MCP toolkit guidance referenced by every other override.

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
| `superpowers:requesting-code-review` | `overrides:requesting-code-review` |
| `superpowers:subagent-driven-development` | `overrides:subagent-driven-development` |
| `superpowers:test-driven-development` | `overrides:test-driven-development` |
| `superpowers:dispatching-parallel-agents` | `overrides:dispatching-parallel-agents` |
| `superpowers:executing-plans` | `overrides:executing-plans` |
| `superpowers:verification-before-completion` | `overrides:verification-before-completion` |

### Agents

No agents are currently overridden. As of `superpowers` v5.1.0 the named
`superpowers:code-reviewer` agent was removed upstream; its dispatch persona
now lives in `overrides:requesting-code-review/code-reviewer.md` and is
dispatched via `Task (general-purpose)`.

### Prompt templates

Some overrides ship reusable prompt templates the dispatcher pastes into subagent prompts (rather than skills the subagent itself loads). These travel as part of the dispatch payload:

- `overrides:subagent-driven-development/implementer-prompt.md` — inlines the MCP toolkit preamble
- `overrides:subagent-driven-development/spec-reviewer-prompt.md` — inlines the MCP toolkit preamble
- `overrides:subagent-driven-development/code-quality-reviewer-prompt.md` — dispatches `Task (general-purpose)` against the template below; adds SDD-specific check bullets and a "trivial inline fixes" allowance
- `overrides:requesting-code-review/code-reviewer.md` — inlines the MCP toolkit preamble; reused by SDD's code-quality reviewer step and any other code-review dispatch

## MCP toolkit (canonical)

This block is the single source of truth for MCP tool guidance across the
overrides plugin. Other override skills, agents, and prompt templates
reference it by name and should not paraphrase or diverge.

This project ships three MCP servers (Tidewave, Context7, Serena). Use them
in preference to generic tools (`Read`/`Grep`/`Glob`), `WebSearch`, or
speculative code (e.g. `iex` snippets to guess how a function behaves).

**Reading a dependency — docs first, source as fallback.** Understand the dep
through docs before opening its source. Drop into Serena on `deps/` only when
docs leave you unsure.

**Reading project code — Serena directly.** No docs detour. Serena is how you
read and edit this codebase.

### Docs (any library — Hex packages, third-party libs, CLIs, cloud services), in fallback order

1. **Tidewave** — `mcp__tidewave__get_docs` for a specific module/function;
   `mcp__tidewave__search_package_docs` to grep across deps. Use when the dev
   server is up. Authoritative because it reads the *loaded* application,
   including dynamically-defined Phoenix/Ash modules that static tools can't see.
2. **Context7** — `mcp__context7__resolve-library-id` → `mcp__context7__query-docs`.
   For anything Tidewave doesn't surface or can't reach. Use even for well-known
   libraries; training data drifts.
3. **`mix usage_rules.docs <Module>` / `mix usage_rules.search_docs "query"`**
   — offline Mix-task fallback when both MCPs are unavailable.

### Runtime introspection (eval Elixir, query dev DB, read logs, list Ash resources / Ecto schemas)

**Tidewave only.** `mcp__tidewave__project_eval`, `execute_sql_query`,
`get_logs`, `get_ash_resources`, `get_ecto_schemas`, `get_source_location`.
No fallback — start the dev server.

### Source code

- **Project code** → **Serena** (`mcp__serena__*`) directly. Activate once per
  session with `mcp__serena__check_onboarding_performed` (or
  `mcp__serena__onboarding` if not yet onboarded). Then use:
  - `find_symbol` (with `include_body=True`) to read a symbol's body
  - `find_referencing_symbols` to find callers/usages — no Tidewave equivalent
  - `get_symbols_overview` to map a file's top-level structure
  - `replace_symbol_body`, `insert_before_symbol`, `insert_after_symbol` for edits
  - `list_memories` / `read_memory` for project context from prior sessions
- **Dependency code (under `deps/`)** → same Serena tools, but only after docs
  left you unsure. Don't lead with source for deps.

Reserve `Grep` for text matches that aren't symbol names (error strings, log
lines, config keys) and `Read` for non-code files (Markdown, JSON, YAML).

## Subagent dispatches must include the MCP toolkit preamble

Fresh subagent contexts do not load skills, so they do not see the canonical block above. Every dispatched `Agent` prompt for code work must paste the **MCP toolkit (canonical)** block at the top of the subagent prompt. The override prompt templates under `overrides:subagent-driven-development/` and `overrides:requesting-code-review/code-reviewer.md` already inline the block; reuse them when dispatching reviewers or implementers instead of hand-rolling.

## Exceptions

- **`Explore`, `Plan`, `general-purpose`** subagent types — use as-is; their tool allowlists already include MCP tools. Always paste the MCP toolkit preamble.
- **Explicit user request for a specific variant** — honor it, but flag the tradeoff ("you asked for `superpowers:brainstorming` — note there's an `overrides:brainstorming` with MCP-first exploration guidance; want that instead?").

## Adding a new override

When a new `overrides:<name>` skill, agent, or prompt template is added to this plugin, this skill's rule automatically covers it — no edit required. Update the tables above opportunistically for discoverability, but the general rule is what governs behavior. New overrides should reference the **MCP toolkit (canonical)** block above rather than introducing their own paraphrases.
