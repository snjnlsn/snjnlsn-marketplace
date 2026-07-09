---
name: finalize-branch
description: Use when the user explicitly asks to finalize, wrap up, or prepare a feature branch for merge.
---

# Finalize Branch

Finalize a feature branch by auditing branch changes, handoffs, and relevant project memories, updating docs where needed, deleting the branch's session handoffs, and producing one final commit.

The workflow is interactive. Each phase ends at an approval gate before the next phase begins. State lives in conversation context; cancellation means start over, except for the stash-based resume flow in `references/preflight.md`.

## When To Use

Activate only for explicit branch-finish requests such as:

- "finalize this branch"
- "wrap up this branch"
- "I'm done with this branch"
- "ready to merge this branch"

## Core Rules

- Resolve conflicts by this precedence: **current code > newest handoff > older handoffs**.
- Treat current code, tests, and repo docs as authoritative. Use Serena memories as project context to verify, never as authority that overrides current project evidence.
- End every premature exit with what failed and what the user should do next.
- Apply approved edits immediately, but stage only in the final phase.
- Do not delete handoffs until every extracted callout has a routing decision and every detected handoff reference has a resolution or explicit skip.
- Delete only the confirmed handoff files. Never remove `.session-continuity/handoffs/` or its `README.md`.
- Stage by explicit path. Never use `git add -A` or `git add .`.
- Never use `git commit --amend`, `--no-verify`, or `Co-Authored-By` trailers.

## Phase Flow

1. **Preflight and branch health** — Read `references/preflight.md`. Detect resume stashes, refuse unsafe branch states, identify the base branch, and run or record skipped branch checks.
2. **Audit handoffs, memories, and branch facts** - Confirm branch handoffs, audit relevant Serena memories, compare that context with code, resolve ambiguities, route callouts, and clean up in-code handoff references. Read `references/memory-audit.md` before the comparison. Read `references/callout-harvesting.md` and `references/handoff-reference-cleanup.md` when those steps have work.
3. **Inline code docs and annotations** - Propose focused updates to intended public API docs and language-specific annotations, with Elixir first, then apply approved edits. Read `references/inline-code-docs.md`.
4. **Repo docs** — Propose updates to live repo docs, excluding `docs/superpowers/**`, and apply approved edits. Read `references/repo-docs.md`.
5. **Handoff cleanup and final commit** — Review pending changes, delete confirmed handoffs, stage explicit paths, compose the commit, and report the result. Read `references/final-commit.md`.

## Documentation Style

Apply this style to every inline doc, README, and `docs/**` prose proposal:

- Prefer the shortest text that preserves the useful fact.
- Describe current system behavior, not the branch, PR, or session that produced it.
- Lead with why/when a caller or reader needs the fact; avoid restating symbol names.
- Cut marketing adjectives, filler, hedges, editorial praise, and future-tense aspirations.
- Match nearby docs only where the local voice helps clarity. Tighten adjacent bloated prose when it is already in the edit path.
- Add or correct specs and related annotations only when their contracts are supported by source, callers, tests, or compiler evidence.

## Tool Usage

- Project memories: use Serena (`list_memories`, `read_memory`). Never inspect Serena memory storage directly.
- Source symbols: prefer Serena (`get_symbols_overview`, `find_symbol`, `find_referencing_symbols`, `replace_symbol_body`, `insert_before_symbol`, `insert_after_symbol`).
- Markdown and config: use ordinary read/edit tools.
- Markdown heading extraction: parse headings from read content; do not use symbol tools.
- Text-level reference scans: use fast text search, then read context around matches.
- Git, Mix, package scripts, and test/build commands: use shell commands.
- Dependency docs: use Tidewave when the dev server is up, then Context7 or `mix usage_rules.*`.

## References

- `references/preflight.md` — resume, refusal, base detection, and branch-health checks.
- `references/memory-audit.md` - Serena memory discovery, relevance, fallback, authority, and audit-summary rules.
- `references/callout-harvesting.md` — extracting, deduping, resolving, and routing handoff callouts.
- `references/handoff-reference-cleanup.md` — scanning source comments/docs for handoff or callout references.
- `references/inline-code-docs.md` — inline documentation candidate selection and approval flow.
- `references/repo-docs.md` — README and `docs/**` proposal rules.
- `references/final-commit.md` — handoff deletion, staging, commit, cancellation retention, and edge cases.

Full design rationale and decision history: `docs/superpowers/specs/2026-04-30-finalize-branch-skill-design.md`.
