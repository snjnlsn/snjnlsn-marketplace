---
name: using-overrides
description: Use when about to invoke any skill or dispatch any subagent that has a same-named variant in the `overrides:` plugin — routes to the override instead of the upstream (`superpowers:`) variant, and supplies the canonical MCP toolkit guidance that all overrides reference.
---

# Route to the overrides plugin

## The problem this solves

The `overrides` plugin ships drop-in replacements for selected upstream skills and agents. Each override keeps the same `name:` as its upstream counterpart (so it reads as the same capability) but adds project-specific guidance — primarily MCP-first navigation (Serena, HexDocs, Context7) for both parent contexts and dispatched subagents.

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
| `superpowers:subagent-driven-development` | `overrides:subagent-driven-development` |

### Agents

| Task | Use `subagent_type` | Replaces |
|---|---|---|
| Reviewing completed work against plan + standards | `overrides:code-reviewer` | `superpowers:code-reviewer` |

### Prompt templates

Some overrides ship reusable prompt templates the dispatcher pastes into subagent prompts (rather than skills the subagent itself loads). These travel as part of the dispatch payload:

- `overrides:subagent-driven-development/implementer-prompt.md`
- `overrides:subagent-driven-development/spec-reviewer-prompt.md`
- `overrides:subagent-driven-development/code-quality-reviewer-prompt.md`

## MCP toolkit (canonical)

This block is the single source of truth for MCP tool guidance across the
overrides plugin. Other override skills, agents, and prompt templates
reference it by name and should not paraphrase or diverge.

This project ships four MCP servers. Use them in preference to generic tools
(`Read`/`Grep`/`Glob`), `WebSearch`, or speculative code (e.g. `iex` snippets
to guess how a function behaves).

**Tidewave is the primary tool whenever it's reachable.** It introspects the
actual loaded application — including dynamically-defined Phoenix/Ash modules
that static tools can't see. Always reach for Tidewave first for: evaluating
code, querying the database, reading dev logs, looking up docs, finding source
locations, or introspecting Ash/Ecto schemas. Fall back to the static MCPs
only if Tidewave fails or the server is down.

- **Tidewave** (`mcp__tidewave__*`) — runtime introspection of the running
  Phoenix app:
  - `project_eval` — run Elixir in the app context (real config, real repos,
    real Ash registry — replaces `mix run -e` and ad-hoc `iex` snippets)
  - `execute_sql_query` — query the dev database
  - `get_logs` — read recent dev-server log output
  - `get_ash_resources` / `get_ecto_schemas` — live introspection of the
    Ash registry and Ecto schemas (correctly resolves meta-programmed shape)
  - `get_docs` — module/function docs for anything loaded into the app
    (**preferred over HexDocs MCP when the server is up**)
  - `get_source_location` — jump to a module/function definition
    (**preferred over Serena's `find_symbol` for "where is this defined?"**)
  - `search_package_docs` — search docs for any loaded Hex dep
    (**preferred over HexDocs MCP when the server is up**)
- **Serena** (`mcp__serena__*`) — symbolic code navigation and editing.
  Tidewave locates symbols; Serena reads them and edits them in place.
  Activate once per session with `mcp__serena__check_onboarding_performed`
  (or `mcp__serena__onboarding` if not yet onboarded). Then use:
  - `find_symbol` (with `include_body=True`) to read a symbol's body
  - `find_referencing_symbols` to find callers/usages — no Tidewave equivalent
  - `replace_symbol_body`, `insert_before_symbol`, `insert_after_symbol`
    for symbolic edits
  - `get_symbols_overview` to map a file's top-level structure
  - `list_memories` / `read_memory` for project context from prior sessions
- **HexDocs** (`mcp__hexdocs-mcp__*`) — fallback for Hex package docs when
  the dev server isn't running, or when Tidewave's `search_package_docs`
  doesn't surface what you need (e.g. a dep not loaded yet). Use
  `mcp__hexdocs-mcp__search`; run `mcp__hexdocs-mcp__fetch` first if the
  package isn't indexed.
- **Context7** (`mcp__context7__*`) — for non-Hex libraries, CLI tools,
  cloud services, version-specific guidance. Resolve with
  `mcp__context7__resolve-library-id`, then query with
  `mcp__context7__query-docs`.

Reserve `Grep` for text matches that aren't symbol names (error strings, log
lines, config keys) and `Read` for non-code files (Markdown, JSON, YAML).

## Subagent dispatches must include the MCP toolkit preamble

Fresh subagent contexts do not load skills, so they do not see the canonical block above. Every dispatched `Agent` prompt for code work must paste the **MCP toolkit (canonical)** block (or the equivalent text from the agent's own system prompt) at the top of the subagent prompt. The override agent `overrides:code-reviewer` already inlines this block in its system prompt and inherits the full default tool set (no `tools:` allowlist — matching its `superpowers:code-reviewer` parent so trivial inline fixes via `Edit` / Serena's symbolic-edit tools work), so the MCPs are reachable — but paste the preamble anyway in case the agent definition drifts.

## Exceptions

- **`Explore`, `Plan`, `general-purpose`** subagent types — use as-is; their tool allowlists already include MCP tools. Always paste the MCP toolkit preamble.
- **Explicit user request for a specific variant** — honor it, but flag the tradeoff ("you asked for `superpowers:brainstorming` — note there's an `overrides:brainstorming` with MCP-first exploration guidance; want that instead?").

## Adding a new override

When a new `overrides:<name>` skill, agent, or prompt template is added to this plugin, this skill's rule automatically covers it — no edit required. Update the tables above opportunistically for discoverability, but the general rule is what governs behavior. New overrides should reference the **MCP toolkit (canonical)** block above rather than introducing their own paraphrases.
