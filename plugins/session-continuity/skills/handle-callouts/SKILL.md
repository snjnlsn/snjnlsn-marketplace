---
name: handle-callouts
description: Use when capturing or resolving a session callout such as a discovery, decision, caveat, known issue, complexity, or edge case.
---

# Handle Callouts

Capture findings worth carrying across sessions as callout headings in the current session handoff. `session-handoff` owns the document; this skill owns callout content, placement, dedup, and resolution markers.

## When To Use

Use when the user says something like:

- "this is a discovery"
- "save that as a decision"
- "that's a gotcha"
- "document this as a callout"
- "mark X resolved"
- "this is fixed"

Also propose once when the session produces a non-obvious finding, accepted trade-off, surprising constraint, repeated-behavior explanation, known issue, complexity, or edge case. If declined, do not re-propose the same finding.

## Keywords

Allowed callout types, singular or plural:

- Discovery
- Decision
- Caveat
- Gotcha
- Lesson learned
- Known issue
- Complexity
- Edge case

Do not invent new keywords. If the user asks for another type, suggest the closest allowed type or ask them to choose.

## Format

Callouts are Markdown headings, usually `###`, whose first words are an allowed keyword, optionally followed by a number, separator, and title.

Examples:

```markdown
### Discovery — JWT clock skew tolerance varies by platform
#### Decision: drop legacy session middleware
### Known issues
```

Title by finding, not task. Prefer unnumbered headings. Body is everything until the next heading.

Never create parent sections named with a bare callout keyword such as `## Discoveries` or `## Decisions`; `finalize-branch` harvests those as callouts. Use `## Callouts`.

## Authoring Flow

1. Determine the working handoff path from conversation context. If none exists, invoke `session-handoff` to lazy-create or rediscover it.
2. Compose type, title, and a 1-3 sentence body. Use normal session voice; `finalize-branch` rewrites atemporally when routing to repo docs.
3. Confirm unless the user explicitly named the type. Explicit typed requests can auto-write.
4. Place under `## Callouts` after `## Summary` by default. Inline placement is allowed only when the user asks for it and the target section exists.
5. Run the dedup check in `references/dedup.md`.
6. Write the callout, refresh `Last updated`, and report one line with the saved heading and path.

## Mark Resolved

When the user or current diff indicates a prior callout is resolved, read `references/mark-resolved.md`. Resolution writes a `> Resolved: ...` blockquote into the working handoff; older handoffs are read-only.

## Writing Style

- Lead with the finding.
- Keep body to 1-3 sentences unless data/code fences are the substance.
- Prefer `path:line` over restating code.
- Cut filler, hedges, marketing adjectives, and vague process narration.
- Preserve code/data fences verbatim when included.

## Coordination

- `session-handoff` delegates callout-shaped appends here.
- This skill may invoke `session-handoff` only to ensure a writable current-session handoff exists.
- Cross-handoff dedup and permanent repo-doc routing belong to `finalize-branch`.

## Tool Usage

- Read and edit handoffs as Markdown.
- Refresh `Last updated` on every write.
- Do not append callouts to an older handoff being read for context; write to the current session handoff.

## References

- `references/dedup.md` — same-handoff duplicate detection and update flow.
- `references/mark-resolved.md` — resolution marker flow.
- `references/edge-cases.md` — unusual cases and recovery behavior.
- `docs/superpowers/specs/2026-04-30-handle-callouts-design.md` — design rationale.
