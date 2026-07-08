---
name: using-overrides
description: Use when about to invoke any skill or dispatch any subagent that has a same-named variant in the `overrides:` plugin — routes to the override instead of the upstream (`superpowers:`) variant, and supplies canonical project-tooling guidance for parent contexts and subagent prompts.
---

# Route to the Overrides Plugin

## The problem this solves

The `overrides` plugin ships drop-in replacements for selected upstream skills.
Each override keeps the same `name:` as its upstream counterpart, but adds
project-tooling guidance and local workflow preferences.

Because skills from several sources appear together in the prompt, there is no
reliable precedence rule. Without this routing skill, a cross-reference like
"invoke `superpowers:writing-plans`" can silently bypass the override.

This skill is the bridge, and the canonical home for project-tooling guidance
referenced by the override workflow skills.

## The rule

**When you would invoke any skill or dispatch any subagent, and a same-name
override exists in the `overrides:` plugin, invoke the `overrides:` variant
instead of the upstream `superpowers:` variant.**

This applies regardless of how the invocation was triggered:
- Direct user request ("use the brainstorming skill")
- Cross-skill reference ("REQUIRED SUB-SKILL: Use superpowers:X")
- Workflow hand-off (brainstorming → writing-plans)
- Implicit description match (Claude deciding based on triggering conditions)
- Ad-hoc `Agent` / `Skill` tool calls

**How to check:** Scan the skill list in the system prompt for an
`overrides:<name>` entry matching the bare name you were about to invoke. If one
exists, use it. If not, proceed with the requested external variant.

## Current Overrides (for quick reference)

These are concrete at time of writing — but the **rule is general**: always
check the live list, don't trust this table alone.

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
`superpowers:code-reviewer` agent was removed upstream. This plugin's
code-review dispatch persona lives in
`overrides:requesting-code-review/code-reviewer.md` and is dispatched via
`Task (general-purpose)`.

### Prompt templates

Some overrides ship reusable prompt templates the dispatcher pastes into
subagent prompts. These travel as part of the dispatch payload because fresh
subagent contexts do not reliably load skills on their own:

- `overrides:subagent-driven-development/implementer-prompt.md` — inlines the
  concise project-tooling preamble and receives a project context payload
- `overrides:subagent-driven-development/spec-reviewer-prompt.md` — inlines the
  concise project-tooling preamble and receives a project context payload
- `overrides:subagent-driven-development/code-quality-reviewer-prompt.md` —
  dispatches `Task (general-purpose)` against
  `overrides:requesting-code-review/code-reviewer.md`; adds SDD-specific check
  bullets and a "trivial inline fixes" allowance
- `overrides:requesting-code-review/code-reviewer.md` — inlines the concise
  project-tooling preamble; reused by SDD's code-quality reviewer step and any
  other code-review dispatch

## Project Tooling (Full)

This is the full parent-context guidance. Override skills may reference this
section by name instead of restating it.

When Tidewave, Context7, or Serena are available, use them in preference to
generic tools (`Read`/`Grep`/`Glob`), `WebSearch`, or speculative code (for
example, runtime snippets to guess how a function behaves).

**Reading a dependency — docs first, source as fallback.** Understand the dep
through docs before opening its source. Drop into Serena on `deps/` only when
docs leave you unsure.

**Reading project code — Serena directly.** No docs detour. Serena is how you
read and edit this codebase.

### Docs (any library — Hex packages, third-party libs, CLIs, cloud services), in fallback order

1. **Tidewave** — `mcp__tidewave__get_docs` for a specific module/function;
   `mcp__tidewave__search_package_docs` to grep across deps. Use when the dev
   server is up. Authoritative because it reads the *loaded* application,
   including dynamically-defined modules that static tools can't see.
2. **Context7** — `mcp__context7__resolve-library-id` → `mcp__context7__query-docs`.
   For anything Tidewave doesn't surface or can't reach. Use even for well-known
   libraries; training data drifts.
3. **Project-local docs commands** — for example,
   `mix usage_rules.docs <Module>` / `mix usage_rules.search_docs "query"` in
   Elixir projects, when both MCPs are unavailable.

### Runtime introspection (eval code, query dev DB, read logs, inspect loaded schemas/resources)

Use Tidewave when available: `mcp__tidewave__project_eval`,
`execute_sql_query`, `get_logs`, resource/schema inspection tools, and
`get_source_location`. If the needed runtime surface is unavailable, start the
dev server or fall back to the project's normal verification command.

### Source code

- **Project code** → **Serena** (`mcp__serena__*`) directly. Activate the
  project and read Serena's initial instructions once per session using the
  available Serena setup tools; run onboarding if the project is not onboarded.
  Then use:
  - `find_symbol` (with `include_body=True`) to read a symbol's body
  - `find_referencing_symbols` to find callers/usages — no Tidewave equivalent
  - `get_symbols_overview` to map a file's top-level structure
  - `replace_symbol_body`, `insert_before_symbol`, `insert_after_symbol` for edits
  - `list_memories` / `read_memory` for project context from prior sessions
- **Dependency code (under `deps/`)** → same Serena tools, but only after docs
  left you unsure. Don't lead with source for deps.

Reserve `Grep` for text matches that aren't symbol names (error strings, log
lines, config keys) and `Read` for non-code files (Markdown, JSON, YAML).

### Scripting fallback (`python3 -c`, `bash -c`)

When the project tooling doesn't cover a one-off computation (cross-file counts,
custom data munging, ad-hoc analysis), **do not** use `python3 -c "..."` or
`bash -c "..."` with a multi-line body. Claude Code's Bash command validator
parses arguments with tree-sitter and cannot validate those reliably:

- Multi-line `-c` bodies often surface `Unhandled node type: string` — the
  parser bails on certain quoted constructs (ANSI-C `$'...'` strings, nested
  heredocs, complex command substitution) and forces a user approval prompt
  before the allowlist is even consulted.
- A newline followed by `#` inside a quoted argument trips a deliberate
  safety check (`Newline followed by # inside a quoted argument can hide
  arguments from path validation`). Multi-line scripts with comments are
  the textbook trigger.

Allowlist entries can't suppress either prompt — both failures happen
upstream of the permissions check. Instead:

1. Try `Grep` / `Glob` / `Read` first; they cover the vast majority of
   what subagents reach for scripting to do.
2. If you genuinely need a script, `Write` it to a scratch file
   (`/tmp/scratch.py`, `/tmp/scratch.sh`) and run it as
   `python3 /tmp/scratch.py` or `bash /tmp/scratch.sh`. The executable path
   is then a single token the validator can check, and the script body
   never passes through the Bash argument parser.

## Project Tooling (Concise Subagent Preamble)

Fresh subagent contexts do not reliably load skills, so prompts for code work
must inline this concise preamble near the top:

> Activate Serena before code work and prefer symbolic tools for project code.
> Use Tidewave for runtime introspection when the dev server is up. Read
> dependency docs through Tidewave, Context7, or `mix usage_rules.*` before
> reading dependency source. Use text/file tools for Markdown, JSON, YAML,
> config, and literal string search. Avoid multi-line `python3 -c` or
> `bash -c`; write scratch scripts to `/tmp` when needed.

## Repo Context Payload

When dispatching implementers or reviewers, paste task-relevant repo guidance
from the plan, AGENTS.md/CLAUDE.md, project docs, or explicitly selected skills
into the prompt instead of assuming the subagent will load that context:

- Code quality expectations for readability, naming, boundaries, restrained
  abstraction, and behavior-focused tests
- Domain-specific obligations that apply to the task, such as migration,
  compatibility, security, data-shape, or integration constraints
- Any plan-specific quality gates, fixture facts, slice obligations, or
  verification commands the subagent must satisfy before reporting done

Keep this payload scoped to the task. The goal is enough local guidance to make
the subagent effective, not a dump of every repo skill.

## Subagent dispatches must include local guidance

Use the prompt templates under `subagent-driven-development/` and
`requesting-code-review/code-reviewer.md` when dispatching reviewers or
implementers. They already inline the concise project-tooling preamble and
contain placeholders for the repo context payload.

## Exceptions

- **`Explore`, `Plan`, `general-purpose`** subagent types — use as-is; their
  tool allowlists already include MCP tools. Always paste the concise
  project-tooling preamble and any needed repo context payload.
- **Explicit user request for a specific external variant** — honor it, but
  flag the tradeoff ("you asked for `superpowers:brainstorming` — note this
  plugin has `overrides:brainstorming` with project-tooling guidance; want that
  instead?").

## Adding a New Override

When a new `overrides:<name>` skill, agent persona, or prompt template is added
to this plugin, this skill's rule automatically covers it. Update the tables
above opportunistically for discoverability, but the general rule is what
governs behavior.
