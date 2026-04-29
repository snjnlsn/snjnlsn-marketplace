# Code Quality Reviewer Prompt Template

Use this template when dispatching a code quality reviewer subagent.

**Purpose:** Verify implementation is well-built (clean, tested, maintainable)

**Only dispatch after spec compliance review passes.**

```
Task tool (superpowers:code-reviewer):
  Use template at requesting-code-review/code-reviewer.md

  WHAT_WAS_IMPLEMENTED: [from implementer's report]
  PLAN_OR_REQUIREMENTS: Task N from [plan-file]
  BASE_SHA: [commit before task]
  HEAD_SHA: [current commit]
  DESCRIPTION: [task summary]
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
