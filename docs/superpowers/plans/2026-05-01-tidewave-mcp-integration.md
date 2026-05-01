# Tidewave MCP Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Tidewave as a fourth MCP across the `overrides` and `local_conf` plugins so subagents prefer Tidewave's runtime introspection over the static MCPs (Serena/HexDocs/Context7) whenever Tidewave is reachable.

**Architecture:** All edits are markdown wiring — no code paths, no runtime behavior changes. The canonical MCP toolkit block in `plugins/overrides/skills/using-overrides/SKILL.md` is the source of truth; six other markdown files inline a copy of it that must stay in sync, plus two READMEs that paraphrase the toolkit, one `finalize-branch` SKILL section that mirrors the HexDocs/Context7 portion, and two `plugin.json` version bumps.

**Tech Stack:** Markdown, YAML frontmatter, JSON (plugin manifests), Bash for verification commands.

**Spec:** `docs/superpowers/specs/2026-05-01-tidewave-mcp-integration-design.md` (commit `467d7f7`, already on the branch).

---

## Pre-flight context

### Already done

The spec doc itself was committed first as the first commit of this branch (per the spec's "Branch + commit shape" — commit #1 of 8). This plan covers commits #2 through #8. (After rebasing onto an updated `main`, the spec commit's SHA is `87e8e76`; before rebase it was `467d7f7`. Either SHA refers to the same content.)

### TDD adaptation

This is a docs/wiring feature. There's no programmatic behavior to test. Verification per task uses `git diff`, `grep`, and string-comparison checks rather than unit tests. "Failing test" steps are replaced by "snapshot the current state" steps that prove the edit hasn't happened yet.

### File Structure

| Path | Role | Touched in task |
|---|---|---|
| `plugins/overrides/skills/using-overrides/SKILL.md` | Canonical MCP toolkit block (source of truth) | Task 1 |
| `plugins/overrides/agents/code-explorer.md` | Override agent — frontmatter + inline MCP block | Task 2 |
| `plugins/overrides/agents/code-architect.md` | Override agent — frontmatter + inline MCP block | Task 2 |
| `plugins/overrides/agents/code-reviewer.md` | Override agent — frontmatter + inline MCP block (with reviewer-flavored phrasing on HexDocs + Tidewave-doc bullets) | Task 2 |
| `plugins/overrides/skills/subagent-driven-development/implementer-prompt.md` | Dispatch prompt template — MCP block inside fenced Task tool block | Task 3 |
| `plugins/overrides/skills/subagent-driven-development/spec-reviewer-prompt.md` | Dispatch prompt template — MCP block inside fenced Task tool block | Task 3 |
| `plugins/overrides/skills/subagent-driven-development/code-quality-reviewer-prompt.md` | Dispatch prompt template — MCP block in markdown body | Task 3 |
| `plugins/overrides/README.md` | Plugin README MCP-toolkit enumeration | Task 4 |
| `README.md` (top-level) | Marketplace README plugin-description cell | Task 4 |
| `plugins/overrides/.claude-plugin/plugin.json` | Plugin version | Task 5 |
| `plugins/local_conf/skills/finalize-branch/SKILL.md` | Tool usage section, single combined bullet → three bullets | Task 6 |
| `plugins/local_conf/.claude-plugin/plugin.json` | Plugin version | Task 7 |

---

## Task 1: Rewrite the canonical MCP toolkit block

**Files:**
- Modify: `plugins/overrides/skills/using-overrides/SKILL.md` (lines 59–90, the `## MCP toolkit (canonical)` section)

This task installs the new four-MCP block as the source of truth. Tasks 2 and 3 propagate copies of this block into agents and prompt templates.

- [ ] **Step 1: Snapshot the current canonical block**

Run:

```bash
sed -n '59,90p' plugins/overrides/skills/using-overrides/SKILL.md
```

Expected: section currently begins with `## MCP toolkit (canonical)` and enumerates only **three** MCPs (Serena, HexDocs, Context7). No mention of Tidewave anywhere. Save this output to a scratch file or just confirm visually — it's the "before" state.

- [ ] **Step 2: Replace the canonical block**

Use the `Edit` tool to replace the existing `## MCP toolkit (canonical)` section with the version below. The old `old_string` is the content of lines 59–90 of `plugins/overrides/skills/using-overrides/SKILL.md` (everything from `## MCP toolkit (canonical)` through the line ending with `for non-code files (Markdown, JSON, YAML).` — but **not** including the next `## Subagent dispatches must include the MCP toolkit preamble` heading or the blank line above it).

`new_string`:

```markdown
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
```

Note: the new block intentionally drops the old "**Do not** fall back to `WebSearch`…" sentence because the same prohibition is now folded into the opening paragraph ("Use them in preference to … `WebSearch`, or speculative code"). The "Reserve `Grep` … `Read` …" sentence is kept verbatim.

- [ ] **Step 3: Verify Tidewave is named and the hard-preference paragraph is intact**

Run:

```bash
grep -c "Tidewave" plugins/overrides/skills/using-overrides/SKILL.md
grep -c "primary tool whenever it's reachable" plugins/overrides/skills/using-overrides/SKILL.md
grep -c "mcp__tidewave__" plugins/overrides/skills/using-overrides/SKILL.md
```

Expected: first count ≥ 5 (four MCP-bullet refs + the hard-preference paragraph + the canonical paragraph mention); second count = 1; third count ≥ 1.

- [ ] **Step 4: Verify the section ends cleanly**

Run:

```bash
grep -n "^## " plugins/overrides/skills/using-overrides/SKILL.md
```

Expected: `## MCP toolkit (canonical)` is followed by `## Subagent dispatches must include the MCP toolkit preamble` (no orphaned headings, no duplicated `## MCP toolkit` blocks).

- [ ] **Step 5: Save the canonical block to a scratch reference file (working-tree only, not committed)**

This file is a scratch artifact — used by Tasks 2 and 3 to byte-compare against inlined copies. It will be deleted before the branch is finalized.

```bash
sed -n '/^## MCP toolkit (canonical)$/,/^## Subagent dispatches must include the MCP toolkit preamble$/p' \
  plugins/overrides/skills/using-overrides/SKILL.md \
  | sed '$d' > /tmp/canonical-mcp-block.md
wc -l /tmp/canonical-mcp-block.md
head -5 /tmp/canonical-mcp-block.md
```

Expected: `wc -l` ≥ 50 lines; `head -5` shows the heading and the "single source of truth" paragraph.

- [ ] **Step 6: Commit**

```bash
git add plugins/overrides/skills/using-overrides/SKILL.md
git commit -m "$(cat <<'EOF'
overrides: tidewave-first MCP toolkit (canonical)

Replace the three-MCP canonical block with a four-MCP version that names
Tidewave as the primary tool whenever it's reachable, with per-bullet
"preferred over X" callouts on the Tidewave bullets that displace
HexDocs/Serena equivalents. Falls back to the static MCPs only on tool
failure or server-down.

This is the source-of-truth edit; subsequent commits propagate the new
block into agents and dispatch prompt templates.
EOF
)"
```

Expected: commit lands cleanly. `git log --oneline -1` shows the new commit on top of `467d7f7`.

---

## Task 2: Propagate the canonical block to override agents

**Files:**
- Modify: `plugins/overrides/agents/code-explorer.md`
- Modify: `plugins/overrides/agents/code-architect.md`
- Modify: `plugins/overrides/agents/code-reviewer.md`

Each of the three override agents has three things that need updating:

1. Frontmatter `description:` — append `, and Tidewave` to the MCP enumeration so it reads `Uses Serena, HexDocs, Context7, and Tidewave MCPs…`.
2. Frontmatter `tools:` — append the 8 `mcp__tidewave__*` tool names.
3. Body — replace the inline `## MCP toolkit` block with a copy of the canonical block from `using-overrides/SKILL.md` (with the **kept-in-sync header preserved**, and one wording carve-out for `code-reviewer.md`).

The "kept-in-sync header" is the parenthetical comment that already prefaces the inline block in each agent: `(Kept in sync with **MCP toolkit (canonical)** in `overrides:using-overrides`. If you find drift, update this block to match.)` — preserve this verbatim.

The 8 Tidewave tools (used in step 3 of every sub-task below):

```
mcp__tidewave__project_eval, mcp__tidewave__execute_sql_query, mcp__tidewave__get_logs, mcp__tidewave__get_docs, mcp__tidewave__get_source_location, mcp__tidewave__search_package_docs, mcp__tidewave__get_ash_resources, mcp__tidewave__get_ecto_schemas
```

- [ ] **Step 1: Snapshot the three agents before edits**

Run:

```bash
for f in plugins/overrides/agents/code-explorer.md plugins/overrides/agents/code-architect.md plugins/overrides/agents/code-reviewer.md; do
  echo "=== $f ==="
  grep -c "Tidewave" "$f"
  grep -c "mcp__tidewave__" "$f"
done
```

Expected: every count is `0` (no Tidewave mentions yet, no allowlist entries yet).

- [ ] **Step 2: Update `code-explorer.md` — frontmatter `description:`**

Use `Edit` on `plugins/overrides/agents/code-explorer.md`:

`old_string`:

```
description: Deeply analyzes existing codebase features by tracing execution paths, mapping architecture layers, understanding patterns and abstractions, and documenting dependencies to inform new development. Uses Serena, HexDocs, and Context7 MCPs for precise code navigation and dependency lookup.
```

`new_string`:

```
description: Deeply analyzes existing codebase features by tracing execution paths, mapping architecture layers, understanding patterns and abstractions, and documenting dependencies to inform new development. Uses Tidewave, Serena, HexDocs, and Context7 MCPs for runtime introspection (when reachable), symbolic code navigation, and dependency lookup.
```

- [ ] **Step 3: Update `code-explorer.md` — frontmatter `tools:`**

Use `Edit` on `plugins/overrides/agents/code-explorer.md`:

`old_string`:

```
tools: Glob, Grep, LS, Read, NotebookRead, WebFetch, TodoWrite, WebSearch, KillShell, BashOutput, mcp__serena__check_onboarding_performed, mcp__serena__onboarding, mcp__serena__get_symbols_overview, mcp__serena__find_symbol, mcp__serena__find_referencing_symbols, mcp__serena__list_memories, mcp__serena__read_memory, mcp__hexdocs-mcp__fetch, mcp__hexdocs-mcp__search, mcp__context7__resolve-library-id, mcp__context7__query-docs
```

`new_string`:

```
tools: Glob, Grep, LS, Read, NotebookRead, WebFetch, TodoWrite, WebSearch, KillShell, BashOutput, mcp__serena__check_onboarding_performed, mcp__serena__onboarding, mcp__serena__get_symbols_overview, mcp__serena__find_symbol, mcp__serena__find_referencing_symbols, mcp__serena__list_memories, mcp__serena__read_memory, mcp__hexdocs-mcp__fetch, mcp__hexdocs-mcp__search, mcp__context7__resolve-library-id, mcp__context7__query-docs, mcp__tidewave__project_eval, mcp__tidewave__execute_sql_query, mcp__tidewave__get_logs, mcp__tidewave__get_docs, mcp__tidewave__get_source_location, mcp__tidewave__search_package_docs, mcp__tidewave__get_ash_resources, mcp__tidewave__get_ecto_schemas
```

- [ ] **Step 4: Update `code-explorer.md` — body MCP block**

Use `Edit` on `plugins/overrides/agents/code-explorer.md` to replace the inline `## MCP toolkit` block.

`old_string` (everything from `## MCP toolkit` through the line ending with `for non-code files (Markdown, JSON, YAML).`):

```
## MCP toolkit

(Kept in sync with **MCP toolkit (canonical)** in `overrides:using-overrides`. If you find drift, update this block to match.)

This project ships three MCP servers. Use them in preference to generic tools (`Read`/`Grep`/`Glob`), `WebSearch`, or speculative code:

- **Serena** (`mcp__serena__*`) — symbolic code navigation. Activate once per session with `mcp__serena__check_onboarding_performed` (or `mcp__serena__onboarding` if not yet onboarded). Then prefer:
  - `get_symbols_overview` to survey a file's structure without reading it whole
  - `find_symbol` with `name_path` and `include_body` for locating and reading specific functions, classes, or methods
  - `find_referencing_symbols` for locating callers or usages
  - `list_memories` / `read_memory` for project-specific context captured in prior sessions
- **HexDocs** (`mcp__hexdocs-mcp__*`) — for any Elixir/Hex package. Use `mcp__hexdocs-mcp__search` to look up function signatures, behaviour callbacks, and module docs. Run `mcp__hexdocs-mcp__fetch` first if the package isn't indexed yet.
- **Context7** (`mcp__context7__*`) — for non-Hex libraries, CLI tools, cloud services, version-specific guidance. Resolve with `mcp__context7__resolve-library-id`, then query with `mcp__context7__query-docs`.

**Do not** fall back to `WebSearch` or speculative code (e.g. `iex` snippets to guess how a stdlib function behaves) before trying these. Reserve `Grep` for text matches that aren't symbol names (error strings, log lines, config keys) and `Read` for non-code files (Markdown, JSON, YAML).
```

`new_string`:

```
## MCP toolkit

(Kept in sync with **MCP toolkit (canonical)** in `overrides:using-overrides`. If you find drift, update this block to match.)

This project ships four MCP servers. Use them in preference to generic tools (`Read`/`Grep`/`Glob`), `WebSearch`, or speculative code (e.g. `iex` snippets to guess how a function behaves).

**Tidewave is the primary tool whenever it's reachable.** It introspects the actual loaded application — including dynamically-defined Phoenix/Ash modules that static tools can't see. Always reach for Tidewave first for: evaluating code, querying the database, reading dev logs, looking up docs, finding source locations, or introspecting Ash/Ecto schemas. Fall back to the static MCPs only if Tidewave fails or the server is down.

- **Tidewave** (`mcp__tidewave__*`) — runtime introspection of the running Phoenix app:
  - `project_eval` — run Elixir in the app context (real config, real repos, real Ash registry — replaces `mix run -e` and ad-hoc `iex` snippets)
  - `execute_sql_query` — query the dev database
  - `get_logs` — read recent dev-server log output
  - `get_ash_resources` / `get_ecto_schemas` — live introspection of the Ash registry and Ecto schemas (correctly resolves meta-programmed shape)
  - `get_docs` — module/function docs for anything loaded into the app (**preferred over HexDocs MCP when the server is up**)
  - `get_source_location` — jump to a module/function definition (**preferred over Serena's `find_symbol` for "where is this defined?"**)
  - `search_package_docs` — search docs for any loaded Hex dep (**preferred over HexDocs MCP when the server is up**)
- **Serena** (`mcp__serena__*`) — symbolic code navigation and editing. Tidewave locates symbols; Serena reads them and edits them in place. Activate once per session with `mcp__serena__check_onboarding_performed` (or `mcp__serena__onboarding` if not yet onboarded). Then use:
  - `find_symbol` (with `include_body=True`) to read a symbol's body
  - `find_referencing_symbols` to find callers/usages — no Tidewave equivalent
  - `replace_symbol_body`, `insert_before_symbol`, `insert_after_symbol` for symbolic edits
  - `get_symbols_overview` to map a file's top-level structure
  - `list_memories` / `read_memory` for project context from prior sessions
- **HexDocs** (`mcp__hexdocs-mcp__*`) — fallback for Hex package docs when the dev server isn't running, or when Tidewave's `search_package_docs` doesn't surface what you need (e.g. a dep not loaded yet). Use `mcp__hexdocs-mcp__search`; run `mcp__hexdocs-mcp__fetch` first if the package isn't indexed.
- **Context7** (`mcp__context7__*`) — for non-Hex libraries, CLI tools, cloud services, version-specific guidance. Resolve with `mcp__context7__resolve-library-id`, then query with `mcp__context7__query-docs`.

Reserve `Grep` for text matches that aren't symbol names (error strings, log lines, config keys) and `Read` for non-code files (Markdown, JSON, YAML).
```

Note: this is the canonical block from Task 1, **except** the bulleted lines are unwrapped (single line per bullet rather than soft-wrapped at ~70 chars). Markdown renders both forms identically; agent files use the unwrapped form, matching how they currently format inline blocks.

- [ ] **Step 5: Update `code-architect.md` — frontmatter `description:`**

Use `Edit` on `plugins/overrides/agents/code-architect.md`:

`old_string`:

```
description: Designs feature architectures by analyzing existing codebase patterns and conventions, then providing comprehensive implementation blueprints with specific files to create/modify, component designs, data flows, and build sequences. Uses Serena, HexDocs, and Context7 MCPs for precise code navigation and dependency lookup.
```

`new_string`:

```
description: Designs feature architectures by analyzing existing codebase patterns and conventions, then providing comprehensive implementation blueprints with specific files to create/modify, component designs, data flows, and build sequences. Uses Tidewave, Serena, HexDocs, and Context7 MCPs for runtime introspection (when reachable), symbolic code navigation, and dependency lookup.
```

- [ ] **Step 6: Update `code-architect.md` — frontmatter `tools:`**

Same edit as Step 3 but on `plugins/overrides/agents/code-architect.md`. The `old_string` and `new_string` are identical to Step 3 (both files share the exact same `tools:` line — verified during inventory).

- [ ] **Step 7: Update `code-architect.md` — body MCP block**

Same edit as Step 4 but on `plugins/overrides/agents/code-architect.md`. The `old_string` and `new_string` are identical to Step 4 (`code-architect.md` and `code-explorer.md` ship the same inline block — verified during inventory).

- [ ] **Step 8: Update `code-reviewer.md` — frontmatter `description:`**

Use `Edit` on `plugins/overrides/agents/code-reviewer.md`:

`old_string`:

```
description: Reviews code for bugs, logic errors, security vulnerabilities, code quality issues, and adherence to project conventions, using confidence-based filtering to report only high-priority issues that truly matter. Uses Serena, HexDocs, and Context7 MCPs for precise code navigation and dependency lookup.
```

`new_string`:

```
description: Reviews code for bugs, logic errors, security vulnerabilities, code quality issues, and adherence to project conventions, using confidence-based filtering to report only high-priority issues that truly matter. Uses Tidewave, Serena, HexDocs, and Context7 MCPs for runtime introspection (when reachable), symbolic code navigation, and dependency lookup.
```

- [ ] **Step 9: Update `code-reviewer.md` — frontmatter `tools:`**

Same edit as Step 3 but on `plugins/overrides/agents/code-reviewer.md`. Identical `old_string` / `new_string`.

(The directive in the spec is "always exposed, including for subagents that are implementing or reviewing my code." `project_eval` and `execute_sql_query` go into the reviewer's allowlist alongside the others — no carve-outs.)

- [ ] **Step 10: Update `code-reviewer.md` — body MCP block (with reviewer-flavored phrasing)**

This is the one carve-out from the canonical block. The HexDocs bullet has reviewer-specific phrasing ("verify the implementer's API usage against documented signatures and behaviour callbacks") that must be preserved. Apply the same reviewer-flavored phrasing to the Tidewave `get_docs` and `search_package_docs` bullets so the reviewer's body block reads consistently.

Use `Edit` on `plugins/overrides/agents/code-reviewer.md`:

`old_string` (everything from `## MCP toolkit` through the line ending with `for non-code files (Markdown, JSON, YAML).`):

```
## MCP toolkit

(Kept in sync with **MCP toolkit (canonical)** in `overrides:using-overrides`. If you find drift, update this block to match.)

This project ships three MCP servers. Use them in preference to generic tools (`Read`/`Grep`/`Glob`), `WebSearch`, or speculative code:

- **Serena** (`mcp__serena__*`) — symbolic code navigation. Activate once per session with `mcp__serena__check_onboarding_performed` (or `mcp__serena__onboarding` if not yet onboarded). Then prefer:
  - `get_symbols_overview` to understand a file's surrounding structure without reading the whole thing
  - `find_symbol` with `name_path` and `include_body` for locating and reading specific functions, classes, or methods
  - `find_referencing_symbols` for verifying how a changed symbol is used elsewhere — critical for assessing blast radius
  - `list_memories` / `read_memory` for project-specific context captured in prior sessions
- **HexDocs** (`mcp__hexdocs-mcp__*`) — for any Elixir/Hex package. Use `mcp__hexdocs-mcp__search` to verify the implementer's API usage against documented signatures and behaviour callbacks. Run `mcp__hexdocs-mcp__fetch` first if the package isn't indexed yet.
- **Context7** (`mcp__context7__*`) — for non-Hex libraries, CLI tools, cloud services, version-specific guidance. Resolve with `mcp__context7__resolve-library-id`, then query with `mcp__context7__query-docs`.

**Do not** fall back to `WebSearch` or speculative code (e.g. `iex` snippets to guess how a stdlib function behaves) before trying these. Reserve `Grep` for text matches that aren't symbol names (error strings, log lines, config keys) and `Read` for non-code files (Markdown, JSON, YAML).
```

`new_string`:

```
## MCP toolkit

(Kept in sync with **MCP toolkit (canonical)** in `overrides:using-overrides`. If you find drift, update this block to match.)

This project ships four MCP servers. Use them in preference to generic tools (`Read`/`Grep`/`Glob`), `WebSearch`, or speculative code (e.g. `iex` snippets to guess how a function behaves).

**Tidewave is the primary tool whenever it's reachable.** It introspects the actual loaded application — including dynamically-defined Phoenix/Ash modules that static tools can't see. Always reach for Tidewave first for: evaluating code, querying the database, reading dev logs, looking up docs, finding source locations, or introspecting Ash/Ecto schemas. Fall back to the static MCPs only if Tidewave fails or the server is down.

- **Tidewave** (`mcp__tidewave__*`) — runtime introspection of the running Phoenix app:
  - `project_eval` — run Elixir in the app context (real config, real repos, real Ash registry — replaces `mix run -e` and ad-hoc `iex` snippets)
  - `execute_sql_query` — query the dev database
  - `get_logs` — read recent dev-server log output
  - `get_ash_resources` / `get_ecto_schemas` — live introspection of the Ash registry and Ecto schemas (correctly resolves meta-programmed shape)
  - `get_docs` — verify the implementer's API usage against the docs of anything loaded into the app (**preferred over HexDocs MCP when the server is up**)
  - `get_source_location` — jump to a module/function definition to verify the implementer is calling the real thing (**preferred over Serena's `find_symbol` for "where is this defined?"**)
  - `search_package_docs` — search docs for any loaded Hex dep when verifying API usage (**preferred over HexDocs MCP when the server is up**)
- **Serena** (`mcp__serena__*`) — symbolic code navigation and editing. Tidewave locates symbols; Serena reads them and edits them in place. Activate once per session with `mcp__serena__check_onboarding_performed` (or `mcp__serena__onboarding` if not yet onboarded). Then use:
  - `find_symbol` (with `include_body=True`) to read a symbol's body
  - `find_referencing_symbols` for verifying how a changed symbol is used elsewhere — critical for assessing blast radius; no Tidewave equivalent
  - `replace_symbol_body`, `insert_before_symbol`, `insert_after_symbol` for symbolic edits
  - `get_symbols_overview` to map a file's top-level structure
  - `list_memories` / `read_memory` for project context from prior sessions
- **HexDocs** (`mcp__hexdocs-mcp__*`) — fallback for Hex package docs when the dev server isn't running, or when Tidewave's `search_package_docs` doesn't surface what you need (e.g. a dep not loaded yet). Use `mcp__hexdocs-mcp__search` to verify the implementer's API usage against documented signatures and behaviour callbacks; run `mcp__hexdocs-mcp__fetch` first if the package isn't indexed.
- **Context7** (`mcp__context7__*`) — for non-Hex libraries, CLI tools, cloud services, version-specific guidance. Resolve with `mcp__context7__resolve-library-id`, then query with `mcp__context7__query-docs`.

Reserve `Grep` for text matches that aren't symbol names (error strings, log lines, config keys) and `Read` for non-code files (Markdown, JSON, YAML).
```

Reviewer-flavored phrasing diffs from the canonical block:

- Serena `find_referencing_symbols` bullet keeps "for verifying how a changed symbol is used elsewhere — critical for assessing blast radius" instead of the canonical "to find callers/usages — no Tidewave equivalent" — but the "no Tidewave equivalent" tail is appended to keep the cross-reference.
- Tidewave `get_docs` / `get_source_location` / `search_package_docs` bullets each pick up "verify the implementer's API usage" / "verify the implementer is calling the real thing" / "when verifying API usage" framing.
- HexDocs bullet keeps "verify the implementer's API usage against documented signatures and behaviour callbacks."
- Everything else matches canonical.

- [ ] **Step 11: Verify all three agents now name Tidewave**

Run:

```bash
for f in plugins/overrides/agents/code-explorer.md plugins/overrides/agents/code-architect.md plugins/overrides/agents/code-reviewer.md; do
  echo "=== $f ==="
  echo "Tidewave mentions: $(grep -c "Tidewave" "$f")"
  echo "mcp__tidewave__ tool refs: $(grep -c "mcp__tidewave__" "$f")"
  echo "primary tool whenever it's reachable: $(grep -c "primary tool whenever it's reachable" "$f")"
  echo "'ships four MCP servers' (canonical body): $(grep -c "ships four MCP servers" "$f")"
done
```

Expected: each file has `Tidewave` count ≥ 8 (frontmatter + body bullets + hard-preference paragraph), `mcp__tidewave__` count ≥ 8 (8 entries in `tools:` line + the `(mcp__tidewave__*)` reference in the body), `primary tool whenever it's reachable` count = 1, `ships four MCP servers` count = 1.

- [ ] **Step 12: Verify the canonical-block body is byte-for-byte identical between code-explorer and code-architect**

Run:

```bash
diff \
  <(sed -n '/^## MCP toolkit$/,/^## Core Mission$/p' plugins/overrides/agents/code-explorer.md) \
  <(sed -n '/^## MCP toolkit$/,/^## Core Process$/p' plugins/overrides/agents/code-architect.md)
```

Expected: only divergence is the trailing `## Core Mission` vs `## Core Process` heading (each agent's next section header). The MCP toolkit body lines must match exactly.

- [ ] **Step 13: Spot-check that code-reviewer keeps the reviewer-flavored phrasing**

Run:

```bash
grep -c "verify the implementer's API usage" plugins/overrides/agents/code-reviewer.md
grep -c "blast radius" plugins/overrides/agents/code-reviewer.md
```

Expected: first count = 3 (HexDocs bullet + Tidewave `get_docs` bullet + Tidewave `search_package_docs` bullet); second count = 1 (Serena `find_referencing_symbols` bullet).

- [ ] **Step 14: Commit**

```bash
git add plugins/overrides/agents/code-explorer.md plugins/overrides/agents/code-architect.md plugins/overrides/agents/code-reviewer.md
git commit -m "$(cat <<'EOF'
overrides: propagate tidewave to agents

Update the three override agents (code-explorer, code-architect,
code-reviewer) to match the new canonical MCP toolkit:

- description frontmatter: enumerate Tidewave alongside Serena/HexDocs/Context7
- tools frontmatter: add the eight mcp__tidewave__* entries to each agent's
  allowlist (no carve-outs by role per the spec)
- body MCP block: replace the three-MCP inline copy with the four-MCP
  canonical block; code-reviewer keeps its reviewer-flavored phrasing on
  the HexDocs bullet and gets analogous reviewer-flavored phrasing on the
  Tidewave doc/source-location bullets
EOF
)"
```

Expected: commit lands cleanly; `git diff HEAD~1 --stat` shows three files changed.

---

## Task 3: Propagate the canonical block to subagent-dispatch prompt templates

**Files:**
- Modify: `plugins/overrides/skills/subagent-driven-development/implementer-prompt.md`
- Modify: `plugins/overrides/skills/subagent-driven-development/spec-reviewer-prompt.md`
- Modify: `plugins/overrides/skills/subagent-driven-development/code-quality-reviewer-prompt.md`

The three prompt templates each carry an MCP block. `implementer-prompt.md` and `spec-reviewer-prompt.md` carry it inside a fenced `Task tool: …` code block (so the dispatched subagent sees it indented inside the prompt body). `code-quality-reviewer-prompt.md` carries it in the markdown body, outside the fenced block (the subagent reads it as part of the template, not the dispatch).

The closing "Do not guess at a dependency's API…" / "Do not fall back…" paragraphs in each template need to be reworded to mention Tidewave first.

The `code-quality-reviewer-prompt.md` block has reviewer-flavored phrasing for the HexDocs bullet — preserve it (same carve-out pattern as code-reviewer.md in Task 2).

- [ ] **Step 1: Snapshot the three prompt templates**

Run:

```bash
for f in plugins/overrides/skills/subagent-driven-development/implementer-prompt.md plugins/overrides/skills/subagent-driven-development/spec-reviewer-prompt.md plugins/overrides/skills/subagent-driven-development/code-quality-reviewer-prompt.md; do
  echo "=== $f ==="
  grep -c "Tidewave" "$f"
done
```

Expected: each count is `0`.

- [ ] **Step 2: Update `implementer-prompt.md` — replace the MCP block inside the fenced Task tool**

Use `Edit` on `plugins/overrides/skills/subagent-driven-development/implementer-prompt.md`.

`old_string` (lines 11–40 — the entire MCP section starting with `## MCP Tools Available — …` and ending with the `… escalate as NEEDS_CONTEXT rather than guessing.` paragraph; preserve indentation — every line begins with four spaces because it's inside the fenced Task tool block):

```
    ## MCP Tools Available — Prefer These Over Generic Tools or Web Search

    (Kept in sync with **MCP toolkit (canonical)** in `overrides:using-overrides`.
    If you find drift, update this block to match.)

    This project has MCP servers. Use them instead of `Read`/`Grep`/`Glob` for
    code navigation, and instead of `WebSearch` or speculative code (e.g. `iex`
    snippets to guess how a stdlib function works) for understanding
    dependencies:

    - **Serena** (`mcp__serena__*`) — symbolic code navigation. First call
      `mcp__serena__check_onboarding_performed` to activate (or
      `mcp__serena__onboarding` if not yet onboarded). Then prefer
      `get_symbols_overview`, `find_symbol`, and `find_referencing_symbols`
      over reading whole files. Use `find_referencing_symbols` to scope your
      changes — it tells you who calls a symbol you're modifying.
    - **HexDocs** (`mcp__hexdocs-mcp__*`) — for any Elixir/Hex package. Use
      `mcp__hexdocs-mcp__search` to look up function signatures, behaviour
      callbacks, and module docs **before** writing code that calls into the
      dependency. Run `mcp__hexdocs-mcp__fetch` first if the package isn't
      indexed yet.
    - **Context7** (`mcp__context7__*`) — for non-Hex libraries, CLI tools,
      cloud services, version-specific guidance. Resolve with
      `mcp__context7__resolve-library-id`, then query with
      `mcp__context7__query-docs`.

    **Do not** guess at a dependency's API or run speculative code to figure
    it out. Look it up via HexDocs (Hex packages) or read the source via
    Serena (in-repo modules and `deps/`). If you can't confirm the API after
    consulting these MCPs, escalate as NEEDS_CONTEXT rather than guessing.
```

`new_string`:

```
    ## MCP Tools Available — Prefer These Over Generic Tools or Web Search

    (Kept in sync with **MCP toolkit (canonical)** in `overrides:using-overrides`.
    If you find drift, update this block to match.)

    This project has four MCP servers. Use them in preference to
    `Read`/`Grep`/`Glob` for code navigation, and instead of `WebSearch` or
    speculative code (e.g. `iex` snippets to guess how a stdlib function
    works) for understanding dependencies.

    **Tidewave is the primary tool whenever it's reachable.** It introspects
    the actual loaded application — including dynamically-defined Phoenix/Ash
    modules that static tools can't see. Always reach for Tidewave first for:
    evaluating code, querying the database, reading dev logs, looking up
    docs, finding source locations, or introspecting Ash/Ecto schemas. Fall
    back to the static MCPs only if Tidewave fails or the server is down.

    - **Tidewave** (`mcp__tidewave__*`) — runtime introspection of the running
      Phoenix app:
      - `project_eval` — run Elixir in the app context (replaces ad-hoc
        `iex` snippets when validating an API call)
      - `execute_sql_query` — query the dev database
      - `get_logs` — read recent dev-server log output
      - `get_ash_resources` / `get_ecto_schemas` — live introspection of
        the Ash registry and Ecto schemas
      - `get_docs` — module/function docs for anything loaded into the app
        (**preferred over HexDocs MCP when the server is up**)
      - `get_source_location` — jump to a module/function definition
        (**preferred over Serena's `find_symbol` for "where is this
        defined?"**)
      - `search_package_docs` — search docs for any loaded Hex dep
        (**preferred over HexDocs MCP when the server is up**)
    - **Serena** (`mcp__serena__*`) — symbolic code navigation and editing.
      Tidewave locates symbols; Serena reads and edits them. First call
      `mcp__serena__check_onboarding_performed` to activate (or
      `mcp__serena__onboarding` if not yet onboarded). Then prefer
      `get_symbols_overview`, `find_symbol`, and `find_referencing_symbols`
      over reading whole files. Use `find_referencing_symbols` to scope your
      changes — it tells you who calls a symbol you're modifying (no
      Tidewave equivalent).
    - **HexDocs** (`mcp__hexdocs-mcp__*`) — fallback for Hex package docs
      when the dev server isn't running, or for deps not loaded into the app.
      Use `mcp__hexdocs-mcp__search`; run `mcp__hexdocs-mcp__fetch` first if
      the package isn't indexed yet.
    - **Context7** (`mcp__context7__*`) — for non-Hex libraries, CLI tools,
      cloud services, version-specific guidance. Resolve with
      `mcp__context7__resolve-library-id`, then query with
      `mcp__context7__query-docs`.

    **Do not** guess at a dependency's API or run speculative code to figure
    it out. Look it up via Tidewave's `get_docs` / `search_package_docs` if
    the server is up, HexDocs MCP otherwise, and read source via Serena
    (in-repo modules and `deps/`). If you can't confirm the API after
    consulting these MCPs, escalate as NEEDS_CONTEXT rather than guessing.
```

Note: every line begins with four spaces (the fenced Task tool block indentation). Bulleted Tidewave sub-items use six-space indents. The closing paragraph names Tidewave first.

- [ ] **Step 3: Update `spec-reviewer-prompt.md` — replace the MCP block inside the fenced Task tool**

Use `Edit` on `plugins/overrides/skills/subagent-driven-development/spec-reviewer-prompt.md`.

`old_string` (lines 13–41 — the MCP section through the `… read the source via Serena (in-repo modules and `deps/`).` paragraph):

```
    ## MCP Tools Available — Prefer These Over Generic Tools or Web Search

    (Kept in sync with **MCP toolkit (canonical)** in `overrides:using-overrides`.
    If you find drift, update this block to match.)

    This project has MCP servers. Use them instead of `Read`/`Grep`/`Glob` for
    code navigation, and instead of `WebSearch` or speculative code for
    understanding dependencies:

    - **Serena** (`mcp__serena__*`) — symbolic code navigation. First call
      `mcp__serena__check_onboarding_performed` to activate (or
      `mcp__serena__onboarding` if not yet onboarded). Then prefer
      `get_symbols_overview`, `find_symbol`, and `find_referencing_symbols`
      over reading whole files. Read the implementer's actual code
      symbol-by-symbol — it's how you'll catch missing or extra behavior
      most efficiently.
    - **HexDocs** (`mcp__hexdocs-mcp__*`) — for any Elixir/Hex package. Use
      `mcp__hexdocs-mcp__search` to look up function signatures, behaviour
      callbacks, and module docs. Run `mcp__hexdocs-mcp__fetch` first if the
      package isn't indexed yet.
    - **Context7** (`mcp__context7__*`) — for non-Hex libraries, CLI tools,
      cloud services, version-specific guidance. Resolve with
      `mcp__context7__resolve-library-id`, then query with
      `mcp__context7__query-docs`.

    **Do not** fall back to `WebSearch` or speculative code (e.g. `iex` snippets
    to guess how a stdlib function behaves) before trying these. Look it up via
    HexDocs (Hex packages) or read the source via Serena (in-repo modules and
    `deps/`).
```

`new_string`:

```
    ## MCP Tools Available — Prefer These Over Generic Tools or Web Search

    (Kept in sync with **MCP toolkit (canonical)** in `overrides:using-overrides`.
    If you find drift, update this block to match.)

    This project has four MCP servers. Use them in preference to
    `Read`/`Grep`/`Glob` for code navigation, and instead of `WebSearch` or
    speculative code for understanding dependencies.

    **Tidewave is the primary tool whenever it's reachable.** It introspects
    the actual loaded application — including dynamically-defined Phoenix/Ash
    modules that static tools can't see. Always reach for Tidewave first for:
    evaluating code, querying the database, reading dev logs, looking up
    docs, finding source locations, or introspecting Ash/Ecto schemas. Fall
    back to the static MCPs only if Tidewave fails or the server is down.

    - **Tidewave** (`mcp__tidewave__*`) — runtime introspection of the running
      Phoenix app:
      - `project_eval` — evaluate Elixir in the app context to check what
        the implementer's code actually does at runtime
      - `execute_sql_query` — query the dev database to verify schema /
        migration changes
      - `get_logs` — read recent dev-server log output for warnings the
        implementer may have ignored
      - `get_ash_resources` / `get_ecto_schemas` — live introspection of
        the Ash registry and Ecto schemas
      - `get_docs` — verify the implementer's API usage against module/
        function docs (**preferred over HexDocs MCP when the server is up**)
      - `get_source_location` — jump to a module/function definition to
        confirm the implementer is calling the real thing (**preferred
        over Serena's `find_symbol` for "where is this defined?"**)
      - `search_package_docs` — search docs for any loaded Hex dep
        (**preferred over HexDocs MCP when the server is up**)
    - **Serena** (`mcp__serena__*`) — symbolic code navigation. Tidewave
      locates symbols; Serena reads them. First call
      `mcp__serena__check_onboarding_performed` to activate (or
      `mcp__serena__onboarding` if not yet onboarded). Then prefer
      `get_symbols_overview`, `find_symbol`, and `find_referencing_symbols`
      over reading whole files. Read the implementer's actual code
      symbol-by-symbol — it's how you'll catch missing or extra behavior
      most efficiently.
    - **HexDocs** (`mcp__hexdocs-mcp__*`) — fallback for Hex package docs
      when the dev server isn't running, or for deps not loaded into the app.
      Use `mcp__hexdocs-mcp__search`; run `mcp__hexdocs-mcp__fetch` first if
      the package isn't indexed yet.
    - **Context7** (`mcp__context7__*`) — for non-Hex libraries, CLI tools,
      cloud services, version-specific guidance. Resolve with
      `mcp__context7__resolve-library-id`, then query with
      `mcp__context7__query-docs`.

    **Do not** fall back to `WebSearch` or speculative code (e.g. `iex`
    snippets to guess how a stdlib function behaves) before trying these.
    Look it up via Tidewave's `get_docs` / `search_package_docs` if the
    server is up, HexDocs MCP otherwise, and read the source via Serena
    (in-repo modules and `deps/`).
```

- [ ] **Step 4: Update `code-quality-reviewer-prompt.md` — replace the MCP block in the markdown body**

The MCP block here is **outside** the fenced Task tool block (lines 20–41 of the current file), so lines have **no leading indentation**. Preserve the reviewer-flavored phrasing on HexDocs (`verify the implementer's API usage against documented signatures and behaviour callbacks`).

Use `Edit` on `plugins/overrides/skills/subagent-driven-development/code-quality-reviewer-prompt.md`.

`old_string`:

```
**MCP tools available to the reviewer — prefer these over generic tools or web search.** (Kept in sync with **MCP toolkit (canonical)** in `overrides:using-overrides`. If you find drift, update this block to match.)

- **Serena** (`mcp__serena__*`) — symbolic code navigation. First call
  `mcp__serena__check_onboarding_performed` to activate (or
  `mcp__serena__onboarding` if not yet onboarded). Then prefer
  `get_symbols_overview`, `find_symbol`, and `find_referencing_symbols` over
  reading whole files. For "is this called elsewhere?" or "does this match
  the pattern in the rest of the codebase?", use `find_referencing_symbols`
  rather than `Grep`.
- **HexDocs** (`mcp__hexdocs-mcp__*`) — for any Elixir/Hex package. Use
  `mcp__hexdocs-mcp__search` to verify the implementer's API usage against
  documented signatures and behaviour callbacks. Run `mcp__hexdocs-mcp__fetch`
  first if the package isn't indexed yet.
- **Context7** (`mcp__context7__*`) — for non-Hex libraries, CLI tools,
  cloud services, version-specific guidance. Resolve with
  `mcp__context7__resolve-library-id`, then query with
  `mcp__context7__query-docs`.

**Do not** fall back to `WebSearch` or speculative code (e.g. `iex` snippets
to guess how a stdlib function behaves) before trying these. Look it up via
HexDocs (Hex packages) or read the source via Serena (in-repo modules and
`deps/`).
```

`new_string`:

```
**MCP tools available to the reviewer — prefer these over generic tools or web search.** (Kept in sync with **MCP toolkit (canonical)** in `overrides:using-overrides`. If you find drift, update this block to match.)

**Tidewave is the primary tool whenever it's reachable.** It introspects the
actual loaded application — including dynamically-defined Phoenix/Ash modules
that static tools can't see. Always reach for Tidewave first for: evaluating
code, querying the database, reading dev logs, looking up docs, finding
source locations, or introspecting Ash/Ecto schemas. Fall back to the static
MCPs only if Tidewave fails or the server is down.

- **Tidewave** (`mcp__tidewave__*`) — runtime introspection of the running
  Phoenix app:
  - `project_eval` — evaluate Elixir in the app context to verify what the
    implementer's code does at runtime
  - `execute_sql_query` — query the dev database when reviewing migrations
    or schema changes
  - `get_logs` — read recent dev-server log output for warnings the
    implementer may have ignored
  - `get_ash_resources` / `get_ecto_schemas` — live introspection of the
    Ash registry and Ecto schemas
  - `get_docs` — verify the implementer's API usage against module/function
    docs (**preferred over HexDocs MCP when the server is up**)
  - `get_source_location` — jump to a module/function definition to confirm
    the implementer is calling the real thing (**preferred over Serena's
    `find_symbol` for "where is this defined?"**)
  - `search_package_docs` — search docs for any loaded Hex dep
    (**preferred over HexDocs MCP when the server is up**)
- **Serena** (`mcp__serena__*`) — symbolic code navigation. Tidewave locates
  symbols; Serena reads them. First call
  `mcp__serena__check_onboarding_performed` to activate (or
  `mcp__serena__onboarding` if not yet onboarded). Then prefer
  `get_symbols_overview`, `find_symbol`, and `find_referencing_symbols` over
  reading whole files. For "is this called elsewhere?" or "does this match
  the pattern in the rest of the codebase?", use `find_referencing_symbols`
  rather than `Grep` (no Tidewave equivalent).
- **HexDocs** (`mcp__hexdocs-mcp__*`) — fallback for Hex package docs when
  the dev server isn't running, or for deps not loaded into the app. Use
  `mcp__hexdocs-mcp__search` to verify the implementer's API usage against
  documented signatures and behaviour callbacks; run `mcp__hexdocs-mcp__fetch`
  first if the package isn't indexed yet.
- **Context7** (`mcp__context7__*`) — for non-Hex libraries, CLI tools,
  cloud services, version-specific guidance. Resolve with
  `mcp__context7__resolve-library-id`, then query with
  `mcp__context7__query-docs`.

**Do not** fall back to `WebSearch` or speculative code (e.g. `iex` snippets
to guess how a stdlib function behaves) before trying these. Look it up via
Tidewave's `get_docs` / `search_package_docs` if the server is up, HexDocs
MCP otherwise, and read the source via Serena (in-repo modules and `deps/`).
```

- [ ] **Step 5: Verify all three templates name Tidewave**

Run:

```bash
for f in plugins/overrides/skills/subagent-driven-development/implementer-prompt.md plugins/overrides/skills/subagent-driven-development/spec-reviewer-prompt.md plugins/overrides/skills/subagent-driven-development/code-quality-reviewer-prompt.md; do
  echo "=== $f ==="
  echo "Tidewave mentions: $(grep -c "Tidewave" "$f")"
  echo "primary tool whenever it's reachable: $(grep -c "primary tool whenever it's reachable" "$f")"
  echo "preferred over HexDocs MCP when the server is up: $(grep -c "preferred over HexDocs MCP when the server is up" "$f")"
done
```

Expected: each file has `Tidewave` count ≥ 5, `primary tool whenever it's reachable` count = 1, `preferred over HexDocs MCP when the server is up` count = 2 (one for `get_docs`, one for `search_package_docs`).

- [ ] **Step 6: Verify code-quality-reviewer keeps the reviewer-flavored HexDocs phrasing**

Run:

```bash
grep -c "verify the implementer's API usage against documented signatures and behaviour callbacks" plugins/overrides/skills/subagent-driven-development/code-quality-reviewer-prompt.md
```

Expected: count = 1.

- [ ] **Step 7: Verify the closing paragraph in implementer + spec-reviewer leads with Tidewave**

Run:

```bash
grep -c "Tidewave's \`get_docs\` / \`search_package_docs\`" plugins/overrides/skills/subagent-driven-development/implementer-prompt.md
grep -c "Tidewave's \`get_docs\` / \`search_package_docs\`" plugins/overrides/skills/subagent-driven-development/spec-reviewer-prompt.md
grep -c "Tidewave's \`get_docs\` / \`search_package_docs\`" plugins/overrides/skills/subagent-driven-development/code-quality-reviewer-prompt.md
```

Expected: each count = 1 (closing "Do not …" paragraph in each template names Tidewave first).

- [ ] **Step 8: Commit**

```bash
git add plugins/overrides/skills/subagent-driven-development/implementer-prompt.md plugins/overrides/skills/subagent-driven-development/spec-reviewer-prompt.md plugins/overrides/skills/subagent-driven-development/code-quality-reviewer-prompt.md
git commit -m "$(cat <<'EOF'
overrides: propagate tidewave to subagent-dispatch prompts

Update the three prompt templates pasted into fresh subagent dispatches
(implementer, spec-reviewer, code-quality-reviewer) to match the new
canonical MCP toolkit. The block content matches the canonical with two
adaptations:

- code-quality-reviewer-prompt keeps reviewer-flavored phrasing on the
  HexDocs and Tidewave doc/source-location bullets (parallel to the
  carve-out applied to overrides:code-reviewer in the previous commit).
- The closing "Do not guess at a dependency's API …" / "Do not fall back
  …" paragraph in each template now names Tidewave first as the lookup
  source, then HexDocs, then Serena for source.

These templates dispatch to general-purpose / superpowers:code-reviewer
agents whose tool allowlists already include the Tidewave tools, so no
allowlist changes are needed here.
EOF
)"
```

---

## Task 4: Refresh README MCP enumerations

**Files:**
- Modify: `plugins/overrides/README.md`
- Modify: `README.md` (top-level marketplace README)

Two paraphrased enumerations of the MCP toolkit (Serena + HexDocs + Context7) need to gain Tidewave. No structural changes — just enumeration updates so prose matches the canonical block.

- [ ] **Step 1: Update `plugins/overrides/README.md` — opening MCP toolkit definition**

Use `Edit`:

`old_string`:

```
The plugin standardizes on a single **MCP toolkit** (Serena + HexDocs + Context7) defined canonically in `skills/using-overrides/SKILL.md`. Every other override either references that block (skills loaded into the parent context) or carries a "kept in sync with" copy of it (agents and dispatch prompt templates, which fresh contexts can't load skills into).
```

`new_string`:

```
The plugin standardizes on a single **MCP toolkit** (Tidewave + Serena + HexDocs + Context7) defined canonically in `skills/using-overrides/SKILL.md`. Every other override either references that block (skills loaded into the parent context) or carries a "kept in sync with" copy of it (agents and dispatch prompt templates, which fresh contexts can't load skills into).
```

- [ ] **Step 2: Update `plugins/overrides/README.md` — `skills/brainstorming/` table row**

Use `Edit`:

`old_string`:

```
| `skills/brainstorming/` | `superpowers:brainstorming` | Replaces the upstream's "use Serena for code exploration" bullet with a pointer to the unified MCP toolkit (Serena + HexDocs + Context7) |
```

`new_string`:

```
| `skills/brainstorming/` | `superpowers:brainstorming` | Replaces the upstream's "use Serena for code exploration" bullet with a pointer to the unified MCP toolkit (Tidewave + Serena + HexDocs + Context7) |
```

- [ ] **Step 3: Update top-level `README.md` — overrides plugin description**

Use `Edit`:

`old_string`:

```
| [`overrides`](plugins/overrides/) | Overlays upstream Claude Code plugins — Serena-enabled overrides of `feature-dev` and `superpowers` agents/skills, plus a routing skill that prefers the Serena-enabled variants. |
```

`new_string`:

```
| [`overrides`](plugins/overrides/) | MCP-enabled overrides (Tidewave/Serena/HexDocs/Context7) of `feature-dev` and `superpowers` agents/skills, plus a routing skill that prefers the MCP-enabled variants. |
```

- [ ] **Step 4: Verify Tidewave appears in both READMEs**

Run:

```bash
grep -c "Tidewave" plugins/overrides/README.md
grep -c "Tidewave" README.md
```

Expected: first count = 2 (opening paragraph + brainstorming row); second count = 1 (overrides description cell).

- [ ] **Step 5: Verify no stale "Serena + HexDocs + Context7" enumerations remain in either README**

Run:

```bash
grep -n "Serena + HexDocs + Context7" plugins/overrides/README.md README.md
```

Expected: no matches (zero exit code OK; the grep should print nothing).

- [ ] **Step 6: Commit**

```bash
git add plugins/overrides/README.md README.md
git commit -m "$(cat <<'EOF'
overrides: refresh README MCP enumerations

Update the two paraphrased toolkit enumerations to name Tidewave
alongside Serena/HexDocs/Context7:

- plugins/overrides/README.md — opening MCP toolkit paragraph and the
  skills/brainstorming/ table row
- README.md (top-level) — overrides plugin description cell, reframed
  from "Serena-enabled" to "MCP-enabled (Tidewave/Serena/HexDocs/Context7)"

Prose-only update; no structural or behavioral change.
EOF
)"
```

---

## Task 5: Bump overrides plugin version to 1.2.0

**Files:**
- Modify: `plugins/overrides/.claude-plugin/plugin.json`

- [ ] **Step 1: Verify current version**

Run:

```bash
cat plugins/overrides/.claude-plugin/plugin.json
```

Expected: contains `"version": "1.1.2"`.

- [ ] **Step 2: Edit the version**

Use `Edit` on `plugins/overrides/.claude-plugin/plugin.json`:

`old_string`: `"version": "1.1.2"`
`new_string`: `"version": "1.2.0"`

- [ ] **Step 3: Verify the file is still valid JSON**

Run:

```bash
python3 -c 'import json,sys; print(json.load(open("plugins/overrides/.claude-plugin/plugin.json"))["version"])'
```

Expected: prints `1.2.0`.

- [ ] **Step 4: Commit**

```bash
git add plugins/overrides/.claude-plugin/plugin.json
git commit -m "$(cat <<'EOF'
overrides: bump to 1.2.0

Feature-grade change — adds Tidewave as a fourth MCP across the canonical
block, all three override agents, and all three subagent-dispatch prompt
templates.
EOF
)"
```

---

## Task 6: Tidewave in finalize-branch tool guidance

**Files:**
- Modify: `plugins/local_conf/skills/finalize-branch/SKILL.md` (the `## Tool usage` section, currently at line 774; the bullet to replace is at line 779)

Replace the single combined HexDocs/Context7 bullet with three bullets per the spec.

- [ ] **Step 1: Snapshot the current bullet**

Run:

```bash
sed -n '774,782p' plugins/local_conf/skills/finalize-branch/SKILL.md
```

Expected: shows the `## Tool usage` heading and the four current bullets, including the line beginning `- **HexDocs MCP** for Hex package API context`.

- [ ] **Step 2: Replace the bullet**

Use `Edit` on `plugins/local_conf/skills/finalize-branch/SKILL.md`:

`old_string`:

```
- **HexDocs MCP** for Hex package API context if the branch's changes touch a Hex dependency's surface; **Context7 MCP** for non-Hex libraries.
```

`new_string`:

```
- **Tidewave MCP** when the dev server is up — `project_eval` to actually run the changed code, `execute_sql_query` to verify migrations, `get_logs` to scan for warnings during a verification run, `get_docs` / `get_source_location` for module/dep questions raised by the diff.
- **HexDocs MCP** as the fallback when the server is down or for deps not loaded into the app — Hex package API context if the branch's changes touch a Hex dependency's surface.
- **Context7 MCP** for non-Hex libraries.
```

- [ ] **Step 3: Verify the section now has three MCP bullets**

Run:

```bash
sed -n '774,786p' plugins/local_conf/skills/finalize-branch/SKILL.md
grep -c "Tidewave MCP" plugins/local_conf/skills/finalize-branch/SKILL.md
```

Expected: the printed range shows three MCP bullets (Tidewave, HexDocs, Context7) in that order; `Tidewave MCP` count = 1.

- [ ] **Step 4: Verify nothing else in the file mentions Tidewave (we only edit the one bullet)**

Run:

```bash
grep -c "Tidewave" plugins/local_conf/skills/finalize-branch/SKILL.md
```

Expected: count = 1 (just the new bullet).

- [ ] **Step 5: Commit**

```bash
git add plugins/local_conf/skills/finalize-branch/SKILL.md
git commit -m "$(cat <<'EOF'
local_conf: tidewave in finalize-branch tool guidance

Split the combined HexDocs/Context7 bullet in the finalize-branch
tool-usage list into three: Tidewave first (project_eval / execute_sql_query
/ get_logs / get_docs / get_source_location for verifying the branch's diff),
HexDocs as the server-down fallback, Context7 unchanged.
EOF
)"
```

---

## Task 7: Bump local_conf plugin version to 1.10.0

**Files:**
- Modify: `plugins/local_conf/.claude-plugin/plugin.json`

- [ ] **Step 1: Verify current version**

Run:

```bash
cat plugins/local_conf/.claude-plugin/plugin.json
```

Expected: contains `"version": "1.9.1"`.

- [ ] **Step 2: Edit the version**

Use `Edit` on `plugins/local_conf/.claude-plugin/plugin.json`:

`old_string`: `"version": "1.9.1"`
`new_string`: `"version": "1.10.0"`

- [ ] **Step 3: Verify the file is still valid JSON**

Run:

```bash
python3 -c 'import json,sys; print(json.load(open("plugins/local_conf/.claude-plugin/plugin.json"))["version"])'
```

Expected: prints `1.10.0`.

- [ ] **Step 4: Commit**

```bash
git add plugins/local_conf/.claude-plugin/plugin.json
git commit -m "$(cat <<'EOF'
local_conf: bump to 1.10.0

Matching minor bump for the finalize-branch tool-usage change in the
previous commit, which adds Tidewave as the preferred MCP for runtime
checks during branch finalization.
EOF
)"
```

---

## Post-task verification

After all 7 tasks land, run these end-to-end checks before opening the PR:

- [ ] **End-to-end Step 1: Commit count and shape**

```bash
git log --oneline main..HEAD
```

Expected: 8 commits — the original `467d7f7 docs: spec for tidewave MCP integration` plus the 7 commits from Tasks 1–7, in order:

1. `docs: spec for tidewave MCP integration`
2. `overrides: tidewave-first MCP toolkit (canonical)`
3. `overrides: propagate tidewave to agents`
4. `overrides: propagate tidewave to subagent-dispatch prompts`
5. `overrides: refresh README MCP enumerations`
6. `overrides: bump to 1.2.0`
7. `local_conf: tidewave in finalize-branch tool guidance`
8. `local_conf: bump to 1.10.0`

- [ ] **End-to-end Step 2: Working tree is clean**

```bash
git status
rm -f /tmp/canonical-mcp-block.md
```

Expected: `git status` reports a clean working tree. Scratch reference file from Task 1 is removed.

- [ ] **End-to-end Step 3: Tidewave appears in every expected file**

```bash
for f in \
  plugins/overrides/skills/using-overrides/SKILL.md \
  plugins/overrides/agents/code-explorer.md \
  plugins/overrides/agents/code-architect.md \
  plugins/overrides/agents/code-reviewer.md \
  plugins/overrides/skills/subagent-driven-development/implementer-prompt.md \
  plugins/overrides/skills/subagent-driven-development/spec-reviewer-prompt.md \
  plugins/overrides/skills/subagent-driven-development/code-quality-reviewer-prompt.md \
  plugins/overrides/README.md \
  README.md \
  plugins/local_conf/skills/finalize-branch/SKILL.md; do
  count=$(grep -c "Tidewave" "$f")
  echo "$count  $f"
done
```

Expected: every count ≥ 1. Specifically: `using-overrides/SKILL.md` ≥ 8, the 3 agents ≥ 8 each, the 3 prompt templates ≥ 5 each, `plugins/overrides/README.md` = 2, top-level `README.md` = 1, `finalize-branch/SKILL.md` = 1.

- [ ] **End-to-end Step 4: Tidewave allowlist entries appear in every override agent**

```bash
for f in plugins/overrides/agents/code-explorer.md plugins/overrides/agents/code-architect.md plugins/overrides/agents/code-reviewer.md; do
  count=$(grep -o "mcp__tidewave__[a-z_]*" "$f" | sort -u | wc -l)
  echo "$count  $f"
done
```

Expected: each count = 8 (one for each Tidewave tool, distinct, sorted-uniqued).

- [ ] **End-to-end Step 5: Versions bumped**

```bash
python3 -c 'import json; print("overrides:", json.load(open("plugins/overrides/.claude-plugin/plugin.json"))["version"])'
python3 -c 'import json; print("local_conf:", json.load(open("plugins/local_conf/.claude-plugin/plugin.json"))["version"])'
```

Expected: prints `overrides: 1.2.0` and `local_conf: 1.10.0`.

- [ ] **End-to-end Step 6: No "Serena + HexDocs + Context7" prose enumerations remain**

```bash
grep -rn "Serena + HexDocs + Context7" plugins/ README.md docs/
grep -rn "Serena, HexDocs, and Context7 MCPs" plugins/ README.md docs/
```

Expected: no matches in either grep. (The first form is the README enumeration style; the second is the agent-frontmatter description style.)

---

## Self-review notes

This is the writer's self-review against the spec — to be done before handing off.

**1. Spec coverage**

Each item in the spec's "Per-file edit map":
- `using-overrides/SKILL.md` (canonical block) → Task 1.
- `code-explorer.md`, `code-architect.md`, `code-reviewer.md` (description + tools + body) → Task 2.
- `implementer-prompt.md`, `spec-reviewer-prompt.md`, `code-quality-reviewer-prompt.md` → Task 3.
- `plugins/overrides/README.md` (two enumerations) → Task 4.
- Top-level `README.md` → Task 4.
- `finalize-branch/SKILL.md` → Task 6.
- Versioning (overrides 1.1.2→1.2.0, local_conf →1.10.0) → Tasks 5 and 7.

Spec's "Branch + commit shape" calls for 8 commits; Task 1 of this plan is commit #2 (commit #1 is already on the branch as `467d7f7`), and Tasks 2–7 are commits #3–#8. Cross-checked. No gaps.

**2. Placeholder scan**

No "TBD"/"TODO"/"implement later". Every step shows the actual content (Edit `old_string` / `new_string` pairs, exact bash commands, exact commit messages).

**3. Type / signature consistency**

- `description:` frontmatter strings are concrete and identical in shape across the three agents.
- `tools:` frontmatter `new_string` is byte-identical across Steps 3, 6, and 9 of Task 2 (verified by reading all three current frontmatter `tools:` lines during inventory — they're identical, so the same edit applies).
- The 8 Tidewave tool names match the spec's "Tool allowlist additions" verbatim and match the names used in the canonical block's bullets.
- The "kept-in-sync" header text is preserved verbatim across all 6 inlined copies.
- Reviewer-flavored phrasing is applied identically in `code-reviewer.md` (Task 2 Step 10) and `code-quality-reviewer-prompt.md` (Task 3 Step 4) — both keep "verify the implementer's API usage against documented signatures and behaviour callbacks" on HexDocs and apply parallel verification framing to the Tidewave doc/source bullets.

**4. Ambiguity check**

- "Reachable" is left as a behavioral concept (tool call succeeds vs. fails). This is consistent across all inlined copies and matches the canonical's "Fall back to the static MCPs only if Tidewave fails or the server is down" definition.
- The local_conf version (`1.9.1`) and overrides version (`1.1.2`) are stated as exact `old_string` matches in Tasks 7 and 5 respectively, so a future bump on either plugin would surface as an `Edit` failure rather than a silent miss.

No issues found in self-review.
