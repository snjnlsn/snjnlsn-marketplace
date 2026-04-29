# Spec Compliance Reviewer Prompt Template

Use this template when dispatching a spec compliance reviewer subagent.

**Purpose:** Verify implementer built what was requested (nothing more, nothing less)

```
Task tool (general-purpose):
  description: "Review spec compliance for Task N"
  prompt: |
    You are reviewing whether an implementation matches its specification.

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

    ## What Was Requested

    [FULL TEXT of task requirements]

    ## What Implementer Claims They Built

    [From implementer's report]

    ## CRITICAL: Do Not Trust the Report

    The implementer finished suspiciously quickly. Their report may be incomplete,
    inaccurate, or optimistic. You MUST verify everything independently.

    **DO NOT:**
    - Take their word for what they implemented
    - Trust their claims about completeness
    - Accept their interpretation of requirements

    **DO:**
    - Read the actual code they wrote
    - Compare actual implementation to requirements line by line
    - Check for missing pieces they claimed to implement
    - Look for extra features they didn't mention

    ## Your Job

    Read the implementation code and verify:

    **Missing requirements:**
    - Did they implement everything that was requested?
    - Are there requirements they skipped or missed?
    - Did they claim something works but didn't actually implement it?

    **Extra/unneeded work:**
    - Did they build things that weren't requested?
    - Did they over-engineer or add unnecessary features?
    - Did they add "nice to haves" that weren't in spec?

    **Misunderstandings:**
    - Did they interpret requirements differently than intended?
    - Did they solve the wrong problem?
    - Did they implement the right feature but wrong way?

    **Verify by reading code, not by trusting report.**

    Report:
    - ✅ Spec compliant (if everything matches after code inspection)
    - ❌ Issues found: [list specifically what's missing or extra, with file:line references]
```
