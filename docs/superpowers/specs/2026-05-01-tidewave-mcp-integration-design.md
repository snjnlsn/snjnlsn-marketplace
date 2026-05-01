# Tidewave MCP integration across `overrides` and `local_conf`

**Date:** 2026-05-01
**Status:** Approved — ready for implementation plan

## Problem

The `overrides` plugin's canonical "MCP toolkit" block lists three MCP servers (Serena, HexDocs, Context7) and is propagated by reference into the override agents (`code-explorer`, `code-architect`, `code-reviewer`) and into the three subagent-dispatch prompt templates (`implementer-prompt`, `spec-reviewer-prompt`, `code-quality-reviewer-prompt`). The `local_conf:finalize-branch` skill mirrors the HexDocs/Context7 portion.

A fourth MCP — Tidewave — is becoming standard tooling for Phoenix projects. Tidewave does *runtime* introspection of the running Phoenix dev server: evaluating Elixir in the app context (`project_eval`), querying the dev DB (`execute_sql_query`), reading dev-server logs (`get_logs`), and resolving docs/source/Hex package docs through the actually-loaded application (`get_docs`, `get_source_location`, `search_package_docs`, `get_ash_resources`, `get_ecto_schemas`).

Tidewave is referenced **nowhere** in either plugin. As a result:

- Subagents dispatched through the override agents and prompt templates don't know Tidewave exists, can't reach for `project_eval` instead of speculative `iex` snippets, and can't introspect meta-programmed Phoenix/Ash modules that static tools (Serena, HexDocs) can't see.
- The override agents' YAML `tools:` allowlists don't include any `mcp__tidewave__*` tools, so even if the canonical block told them to, the dispatched subagent couldn't actually call Tidewave.

Tidewave's own setup docs ([HexDocs source](https://hexdocs.pm/tidewave/mcp.html)) take an explicit position on this:

> Tidewave MCP was designed to perform runtime analysis, rather than static one. This is especially important in the context of web frameworks where meta-programming is often used to avoid repetitive work… commands to execute code or capture telemetry information within the runtime, such as `project_eval`, `execute_sql_query`, and `get_logs`, simply do not exist in LSP. In other words, Tidewave MCP is about the runtime intelligence of your applications.
>
> If you want use both, we recommend keeping the existing Tidewave MCP tools, and use LSP for diagnostics and symbol search (`workspaceSymbol` and `findReferences`).

And the suggested coding-agent rule from the same page:

> Always use Tidewave's tools for evaluating code, querying the database, etc. Use `get_docs` to access documentation and the `get_source_location` tool to find module/function definitions.

## Goals

1. Make Tidewave the **first-choice MCP** whenever it's reachable, falling back to Serena/HexDocs/Context7 only when Tidewave is unavailable or doesn't cover the question.
2. Expose all 8 Tidewave tools to every subagent dispatched through the override agents and through the three subagent-dispatch prompt templates — including subagents that implement code and subagents that review code.
3. Keep the new guidance in sync across every place the canonical MCP block is currently inlined or paraphrased: the `using-overrides` skill, the 3 override agents, the 3 subagent-dispatch prompt templates, and the `finalize-branch` skill.
4. Apply the same "hard preference" wording everywhere the block appears, so the rule survives skim-reading and isn't softened by file-local rewording.

## Non-goals

- **No changes to any user-authored `CLAUDE.md`** (global or project-level). Tidewave is per-project tooling — only meaningful when a project has it configured. Plugin guidance is the right home: it activates conditionally when subagents go through the override flow, rather than as always-on instructions that apply across every project.
- **No MCP guidance added to the workflow-only `local_conf` skills** (`session-handoff`, `handle-callouts`, `session-retrospect`). They don't navigate code; the parent context's canonical block already covers them.
- **No new `Bash` permission for the override agents.** The agents currently have `KillShell, BashOutput` but not `Bash`, so they can't run arbitrary shell. Tidewave's `project_eval` partially fills that gap (Elixir-in-app evaluation) but does not unlock `mix test` etc. — which is fine for these agents' scope. Out of scope for this work.
- **No carve-out of Tidewave tools by agent role.** The user's directive is "always exposed, including for subagents that are implementing or reviewing my code." All 8 Tidewave tools land in all 3 override agents.
- **No restructuring of how plugins reference each other** (e.g. local_conf doesn't start importing from overrides). The canonical block continues to live in `overrides:using-overrides` and continues to be propagated by inlining.

## Design

### The new canonical MCP toolkit block

This block lives in `plugins/overrides/skills/using-overrides/SKILL.md` as the **MCP toolkit (canonical)** section. It is the source of truth that every other inlined copy must match.

```markdown
## MCP toolkit (canonical)

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
```

#### Why this shape

- **Hard preference at the top, in its own paragraph**, not buried inside a bullet. Survives skim-reading and matches Tidewave's own suggested wording.
- **Per-bullet "preferred over X" callouts** repeat the rule at the decision point — i.e. inside the Tidewave bullet, next to the tool name the agent is about to call. Forces the rule to register where the choice is actually being made.
- **Server-down fallback acknowledged once at the top, not repeated per bullet.** Tidewave tools fail with connection errors when the server is down; the model handles fallback naturally on tool failure. Repeating the caveat in every bullet would dilute the hard preference.
- **No bullet for a `find_referencing_symbols` equivalent in Tidewave** — it doesn't exist. Tidewave's docs themselves recommend keeping LSP/Serena for `findReferences`. The Serena bullet calls that out explicitly so the agent knows when Serena is still required.

### Decision table (informational, not pasted into the block)

| Job | Preferred (when dev server up) | Fallback / complementary |
|---|---|---|
| Eval Elixir in app context | Tidewave `project_eval` | — (no equivalent) |
| Query DB | Tidewave `execute_sql_query` | — |
| Tail dev logs | Tidewave `get_logs` | — |
| Live Ash/Ecto schema | Tidewave `get_ash_resources` / `get_ecto_schemas` | — |
| Module/function docs | Tidewave `get_docs` | HexDocs MCP `search` |
| Find module/fn definition | Tidewave `get_source_location` | Serena `find_symbol` |
| Search Hex package docs | Tidewave `search_package_docs` | HexDocs MCP `search` |
| Read symbol body | Serena `find_symbol` (`include_body=True`) | — |
| Find callers / references | Serena `find_referencing_symbols` | — |
| Symbolic edits | Serena `replace_symbol_body` etc. | — |
| Non-Hex library docs | Context7 | WebSearch (last resort) |

### Server-down behavior

When the dev server isn't running, Tidewave tool calls fail with a connection error. The agent is expected to:

1. Recognize the failure mode from the tool's error response.
2. Fall back per the table above (`get_docs`/`search_package_docs` → HexDocs MCP; `get_source_location` → Serena `find_symbol`; `project_eval`/`execute_sql_query`/`get_logs`/`get_ash_resources`/`get_ecto_schemas` have no fallback — those questions become unanswerable without bringing the server up).
3. Surface the unavailability if a runtime-only question can't be answered, rather than papering over it with speculation.

This behavior is implicit in the canonical block's "Fall back to the static MCPs only if Tidewave fails or the server is down" sentence. No additional per-tool guidance is added.

## Per-file edit map

Paths below are relative to the repo root (this spec lives in the same repo).

### `plugins/overrides/`

1. **`skills/using-overrides/SKILL.md`** — replace the **MCP toolkit (canonical)** section with the block above. The "Subagent dispatches must include the MCP toolkit preamble" paragraph is unchanged (it already references the canonical by name and continues to apply).

2. **`agents/code-explorer.md`** — three changes:
   - Frontmatter `description:` add ", and Tidewave" to the MCP enumeration ("Uses Serena, HexDocs, Context7, **and Tidewave** MCPs…").
   - Frontmatter `tools:` append the 8 Tidewave tools (see "Tool allowlist additions" below).
   - Body: replace the inline MCP block with the canonical block.

3. **`agents/code-architect.md`** — same three changes as code-explorer.

4. **`agents/code-reviewer.md`** — same three changes, with one wording carveout: the existing inline block has reviewer-specific phrasing for HexDocs ("verify the implementer's API usage against documented signatures and behaviour callbacks"). Preserve that phrasing on the HexDocs bullet only; everything else matches the canonical. The Tidewave bullets get analogous reviewer-flavored hints where natural (e.g. `get_docs`/`search_package_docs` for "verify the implementer's API usage").

5. **`skills/subagent-driven-development/implementer-prompt.md`** — the prompt template carries the MCP block inside a fenced `Task tool: …` code block (lines 11–40). Replace that section with the canonical block. The closing "Do not guess at a dependency's API or run speculative code…" paragraph is reworded so its examples match the new ordering: "look it up via Tidewave's `get_docs` / `search_package_docs` if the server is up; HexDocs MCP otherwise; read source via Serena (in-repo modules and `deps/`)."

6. **`skills/subagent-driven-development/spec-reviewer-prompt.md`** — same shape of edit as implementer-prompt: the MCP section inside the fenced Task tool block, plus the closing "Do not fall back…" paragraph reworded to mention Tidewave first.

7. **`skills/subagent-driven-development/code-quality-reviewer-prompt.md`** — the MCP block is in the markdown body, not inside a fenced Task tool block. Same content swap, preserving the reviewer-specific phrasing for the HexDocs bullet.

### `plugins/local_conf/`

8. **`skills/finalize-branch/SKILL.md`** — update the "Tool usage" section (around line 774). Replace the single combined HexDocs/Context7 bullet with three:
   - **Tidewave MCP** when the dev server is up — `project_eval` to actually run the changed code, `execute_sql_query` to verify migrations, `get_logs` to scan for warnings during a verification run, `get_docs` / `get_source_location` for module/dep questions raised by the diff.
   - **HexDocs MCP** as the fallback when the server is down or for deps not loaded into the app.
   - **Context7 MCP** for non-Hex libraries.

### Prose READMEs that name the toolkit

9. **`plugins/overrides/README.md`** — update the inline "Serena + HexDocs + Context7" enumerations to include Tidewave. Two known instances:
   - The opening paragraph that defines the MCP toolkit ("Serena + HexDocs + Context7") at the top of the file.
   - The `skills/brainstorming/` table row that says "(Serena + HexDocs + Context7)".
   No structural changes — just enumeration updates so the README's prose matches the canonical block. Other "MCP toolkit" mentions in this file are generic (don't enumerate the MCPs) and don't need edits.

10. **`README.md`** (marketplace top-level) — refresh the `overrides` plugin description in the plugins table. The current wording is "Serena-enabled overrides of `feature-dev` and `superpowers` agents/skills, plus a routing skill that prefers the Serena-enabled variants." Adjust to a four-MCP framing without expanding the cell unnecessarily — e.g. "MCP-enabled overrides (Tidewave/Serena/HexDocs/Context7) of `feature-dev` and `superpowers` agents/skills, plus a routing skill that prefers the MCP-enabled variants." Lowest-stakes edit in the set; lands with the same commit as #9 to keep the prose-update commit cohesive.

## Tool allowlist additions

All 8 Tidewave tools get appended to the YAML `tools:` line in each of the 3 override agent files (`agents/code-explorer.md`, `agents/code-architect.md`, `agents/code-reviewer.md`):

```
mcp__tidewave__project_eval,
mcp__tidewave__execute_sql_query,
mcp__tidewave__get_logs,
mcp__tidewave__get_docs,
mcp__tidewave__get_source_location,
mcp__tidewave__search_package_docs,
mcp__tidewave__get_ash_resources,
mcp__tidewave__get_ecto_schemas
```

No carve-outs by agent role: the user's directive is "always exposed, including for subagents that are implementing or reviewing my code." `project_eval` and `execute_sql_query` (the two with mutation potential) go into the code-reviewer's allowlist alongside the others.

The 3 subagent-dispatch prompt templates do **not** need allowlist changes:

- `implementer-prompt.md` and `spec-reviewer-prompt.md` dispatch to the `general-purpose` agent, which inherits the parent's full tool list.
- `code-quality-reviewer-prompt.md` dispatches to `superpowers:code-reviewer`, which exposes its full tools list (the `using-overrides` skill notes this exception).

In all three cases Tidewave is already reachable from the dispatched subagent's environment; the prompt templates only need their content (the MCP block) updated so the subagent knows to use it.

## Versioning

- `plugins/overrides/.claude-plugin/plugin.json`: `1.1.2` → `1.2.0` (new MCP integrated — feature-grade change).
- `plugins/local_conf/.claude-plugin/plugin.json`: `1.9.1` → `1.10.0` (matching minor bump for the `finalize-branch` change).

## Branch + commit shape

Feature branch off `main`, named `feat/tidewave-mcp-integration`. Commits in this order:

1. **`docs: spec for tidewave MCP integration`** — adds this spec doc. Lands first so the rest of the diff is anchored to a written rationale.
2. **`overrides: tidewave-first MCP toolkit (canonical)`** — rewrites `skills/using-overrides/SKILL.md` canonical block.
3. **`overrides: propagate tidewave to agents`** — updates `agents/code-explorer.md`, `agents/code-architect.md`, `agents/code-reviewer.md` (description, `tools:`, inline block).
4. **`overrides: propagate tidewave to subagent-dispatch prompts`** — updates the 3 prompt templates under `skills/subagent-driven-development/`.
5. **`overrides: refresh README MCP enumerations`** — updates `plugins/overrides/README.md` and the marketplace top-level `README.md` to name Tidewave alongside Serena/HexDocs/Context7.
6. **`overrides: bump to 1.2.0`** — `plugins/overrides/.claude-plugin/plugin.json`.
7. **`local_conf: tidewave in finalize-branch tool guidance`** — updates `skills/finalize-branch/SKILL.md`.
8. **`local_conf: bump to 1.10.0`** — `plugins/local_conf/.claude-plugin/plugin.json`.

Single PR for the whole branch.

## Verification

The wiring is text — there's no runtime test. Two checks after the edits land:

1. **Spec self-review pass** — once the spec doc is written, do the placeholder/consistency/scope/ambiguity sweep the brainstorming skill prescribes. Fix inline.
2. **Smoke test in a fresh session** — after the PR merges and the local plugin cache refreshes, open a fresh session in any Phoenix project that has Tidewave configured and invoke the `overrides:using-overrides` skill. Confirm the new canonical block renders with Tidewave at the top of the preference order. Optional: dispatch a `code-explorer` subagent and confirm a Tidewave tool (e.g. `mcp__tidewave__get_ash_resources`) is callable from inside it — proves the `tools:` allowlist took effect.

## Risks and tradeoffs

- **Drift across inlined copies.** The canonical block is propagated by inlining into 6 files (using-overrides, 3 agents, 3 prompt templates) plus partly mirrored in `finalize-branch`. Future edits risk drifting one copy from another. Mitigation: every inlined copy already carries a "Kept in sync with **MCP toolkit (canonical)** in `overrides:using-overrides`. If you find drift, update this block to match." pointer. This work preserves those pointers.
- **Hard preference may misfire when the dev server is down.** Tidewave tools fail with connection errors; the agent handles fallback on tool failure. The risk is wasted tokens/turns when the server is reliably down. Acceptable cost: when the server is up, Tidewave gives objectively better answers than the static MCPs for questions Tidewave covers, and the dev server is up most of the time during active work.
- **`project_eval` / `execute_sql_query` exposure to code-reviewer agents.** Both are mutation-capable. The user's directive is to expose them anyway. Trust assumption: the reviewer agent is being asked to verify behavior, and read-only use of these tools (the dominant case) outweighs the small risk of unintended writes. If this turns out to misfire in practice, a future change can carve them out.

## Alternatives considered

- **Flat list (Tidewave as 4th bullet, no preference rule).** Considered and rejected: under-guides the agent on *when* to choose Tidewave vs. the others. The user's directive "use Tidewave when it has pertinent tooling instead of other existing tooling" is a real preference rule that needs to be spelled out, not flattened into a list.
- **Two-section structural split (live vs. static).** Considered: gives the cleanest information shape, but multiplies the maintenance burden across 6+ inlined copies for marginal benefit over the chosen approach (hard preference at top + per-bullet callouts at decision points).
- **Carving out `project_eval` / `execute_sql_query` from the code-reviewer's allowlist.** Considered and rejected per the user's explicit directive to expose all Tidewave tools to all subagents.
- **Adding Tidewave guidance to any user-authored `CLAUDE.md`** (global or project). Considered and rejected: Tidewave is per-project tooling. Plugin-layer guidance activates only when subagents enter the override flow; CLAUDE.md instructions apply unconditionally — including in projects without Tidewave configured.
- **Adding Tidewave guidance to the workflow-only `local_conf` skills (`session-handoff`, `handle-callouts`, `session-retrospect`).** Considered and rejected: those skills don't navigate code; the parent context's canonical block already covers them when needed.

## Implementation entry point

After this spec is approved, hand off to the writing-plans skill to produce the per-commit implementation plan. The plan should follow the commit ordering in "Branch + commit shape" above and treat each numbered commit as a discrete task.
