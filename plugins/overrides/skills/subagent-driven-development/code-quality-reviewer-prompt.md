# Code Quality Reviewer Prompt Template

Use this template when dispatching a code quality reviewer subagent.

**Purpose:** Verify implementation is well-built (clean, tested, maintainable)

**Only dispatch after spec compliance review passes.**

```
Task tool (overrides:code-reviewer):
  Use template at requesting-code-review/code-reviewer.md

  WHAT_WAS_IMPLEMENTED: [from implementer's report]
  PLAN_OR_REQUIREMENTS: Task N from [plan-file]
  BASE_SHA: [commit before task]
  HEAD_SHA: [current commit]
  DESCRIPTION: [task summary]
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
    docs  - `get_source_location` — jump to a module/function definition to confirm
    the implementer is calling the real thing (**preferred over Serena's
    `find_symbol` for "where is this defined?"**)
  - `search_package_docs` — search docs for any loaded Hex dep
   - **Serena** (`mcp__serena__*`) — symbolic code navigation. Tidewave locates
  symbols; Serena reads them. First call
  `mcp__serena__check_onboarding_performed` to activate (or
  `mcp__serena__onboarding` if not yet onboarded). Then prefer
  `get_symbols_overview`, `find_symbol`, and `find_referencing_symbols` over
  reading whole files. For "is this called elsewhere?" or "does this match
  the pattern in the rest of the codebase?", use `find_referencing_symbols`
  rather than `Grep` (no Tidewave equivalent).
- **`mix usage_rules.docs <Module>` / `mix usage_rules.search_docs "query"`**
  — offline Mix-task fallback for Hex package docs when Tidewave is down.
- **Context7** (`mcp__context7__*`) — for non-Hex libraries, CLI tools,
  cloud services, version-specific guidance. Resolve with
  `mcp__context7__resolve-library-id`, then query with
  `mcp__context7__query-docs`.

**Do not** fall back to `WebSearch` or speculative code (e.g. `iex` snippets
to guess how a stdlib function behaves) before trying these. Look it up via
Tidewave's `get_docs` / `search_package_docs` if the server is up, Context7
otherwise. Read source via Serena (in-repo modules and `deps/`) only if docs
leave you unsure.

**In addition to standard code quality concerns, the reviewer should check:**
- Does each file have one clear responsibility with a well-defined interface?
- Are units decomposed so they can be understood and tested independently?
- Is the implementation following the file structure from the plan?
- Did this implementation create new files that are already large, or significantly grow existing files? (Don't flag pre-existing file sizes — focus on what this change contributed.)

**Code reviewer returns:** Strengths, Issues (Critical/Important/Minor), Assessment

**Trivial inline fixes are allowed.** If the reviewer spots a clearly trivial
issue (typo, magic number, naming nit, missing constant extraction, dead
import, formatting), it may fix it inline rather than bouncing back to the
implementer — but only under these guards:

- The fix is contained to code already in the diff under review (no new files,
  no edits outside the changed surface).
- No scope expansion: don't add features, refactor adjacent code, or rename
  symbols beyond the trivial fix.
- After the fix, run the relevant tests AND `mix compile` (or the project's
  equivalent build/typecheck) and confirm both pass before reporting.
- Report the inline fixes explicitly in the review output so the controller
  sees what changed.

Anything that isn't trivially contained — logic changes, multi-file edits,
behavior changes, anything requiring judgment about intent — must go back to
the implementer as a normal review issue.
