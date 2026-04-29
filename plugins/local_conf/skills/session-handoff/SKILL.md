---
name: session-handoff
description: Maintain a per-session handoff document under docs/handoffs/. Use when the user says "add this to the handoff", "update the handoff", "create a handoff", "start a handoff", "read the handoff", "continue the handoff at <path>", or after the SessionStart hook surfaces a recent-handoffs list and the user wants to read, continue, or start fresh.
---

# Session Handoff

Maintain one handoff markdown document per session under `docs/handoffs/`, written incrementally during the session.

## When to use

Activate when the user says:
- "add this/that to the handoff"
- "update the handoff"
- "create a handoff" / "start a handoff for this session"
- "read the handoff" / "read the latest handoff"
- "continue the handoff" / "continue the handoff at <path>"

Also activate when the SessionStart hook has surfaced a recent-handoffs list and the user has chosen to read, continue, or start fresh.

## File location and naming

- Handoffs live at `docs/handoffs/` relative to the working repo's cwd.
- Filename: `YYYY-MM-DD-HHMMSS-<slug>.md`.
- `YYYY-MM-DD-HHMMSS` is the timestamp at the moment of *first content write* (lazy creation), not session start. Use UTC.
- `<slug>` is a short kebab-case summary derived from the session's work so far. If too sparse to summarize, ask the user.
- On slug collision in the same day, append `-2`, `-3`, etc.

## Document template

Use this exact structure when creating a new handoff:

```markdown
# <slug, humanized>

**Started:** <ISO 8601 UTC timestamp at first write>
**Last updated:** <ISO 8601 UTC timestamp, refreshed on every write>

## Summary

<one-paragraph overview of the session's purpose and outcome>

## Work done

<bullets or short paragraphs of concrete changes, decisions, and milestones>

## Open questions / next steps

<bullets of unresolved items, things to pick up later>
```

A `## Retrospective` section is added later by the `session-retrospect` skill if it runs. Do not add it from this skill.

## Behaviors

### Read existing handoff (for context)

Use the Read tool on the requested file (or the most recent file in `docs/handoffs/` if unspecified). Summarize relevance to the current session. If the user says to adopt it as the working handoff, do so.

### Continue / adopt existing handoff

Set the working handoff path in conversation context to that file. Subsequent "add to handoff" calls write there.

### Lazy-create on first write

On the first write request without a working handoff:

1. Derive a slug from session work so far. If insufficient context, ask the user.
2. Get current UTC ISO timestamp; format `YYYY-MM-DD-HHMMSS` for the filename.
3. Check for slug collision in `docs/handoffs/` for today's date prefix. On collision, append `-2`, `-3`, etc.
4. Create `docs/handoffs/` if missing (use Bash `mkdir -p docs/handoffs`).
5. Use Write to create the file with the template, with the first content already in the right section.
6. Set "Started" and "Last updated" to the current ISO timestamp.

### Append to existing handoff

1. Use Read to load the file.
2. Use Edit to splice content into the appropriate section (Summary, Work done, Open questions / next steps, Retrospective).
3. Use Edit to refresh the "Last updated" timestamp.

## Routing content to the right section

- A description of work completed → "Work done"
- A TODO, follow-up item, or unresolved question → "Open questions / next steps"
- A high-level framing or outcome statement → "Summary"
- Retrospective insight (only via `session-retrospect` skill) → "Retrospective"

## State

The working handoff path is held in conversation context. If conversation context drops it, re-discover by listing `docs/handoffs/` and picking the file whose timestamp matches the current session, or ask the user.
