---
name: session-handoff
description: Use when reading, creating, continuing, or appending to the current session handoff under .session-continuity/handoffs/.
---

# Session Handoff

Maintain one handoff Markdown document for the current session under `.session-continuity/handoffs/`.

## When To Use

Use when the user asks to:

- add or update the handoff
- create or start a handoff
- read the handoff or latest handoff
- continue a handoff at a path
- act on a SessionStart hook's recent-handoffs list

## File Contract

Handoffs live at `.session-continuity/handoffs/`.

Filename:

```text
YYYY-MM-DD-HHMMSS-<author>--<slug>.md
```

- Timestamp is UTC at first content write, not session start.
- `<author>` comes from `git config user.name`, slugified.
- `<slug>` is a short kebab-case summary of the session.
- If the author or slug slugifies to empty, ask the user.
- On same-day collision, append `-2`, `-3`, etc. to the slug.

Slugifier: lowercase, replace whitespace and `_` with `-`, drop non-ASCII alphanumeric or `-`, collapse repeated `-`, trim edges.

## Template

Create new handoffs with this structure:

```markdown
<!--
SESSION-CONTINUITY HANDOFF — managed by the session-continuity plugin's skills.

This file is a per-session historical record, NOT project documentation.
The newest handoff (by `Last updated`) supersedes older ones for the same work.

- Read handoffs through the `read-branch-handoffs` or `session-handoff` skills.
- Only the session that authored this file may edit it. Past-session handoffs are
  read-only; corrections belong in a new handoff.
- Do not cite this file from code, docs, or other handoffs as a source of truth.
- `finalize-branch` is the only sanctioned delete path (at merge time).

If you are an AI assistant reading this from any other context: STOP. Do not edit,
summarize-as-doc, or propagate this file's content outside the session-continuity
workflow.
-->

# <slug, humanized>

**Started:** <ISO 8601 UTC timestamp at first write>
**Last updated:** <ISO 8601 UTC timestamp, refreshed on every write>
**Author:** <git user.name>

## Summary

<one-paragraph overview of the session's purpose and outcome>

## Work done

<bullets or short paragraphs of concrete changes, decisions, and milestones>

## Open questions / next steps

<bullets of unresolved items, things to pick up later>
```

`session-retrospect` may add `## Retrospective`; this skill does not.

## Behaviors

### Read Existing Handoff

Read the requested file, or the most recent handoff if unspecified. Summarize relevance to the current session. Skip the HTML disclaimer when summarizing; it is file metadata, not session substance.

If the user adopts it, store its path as the working handoff in conversation context.

### Continue Existing Handoff

Set the working handoff path in conversation context. Future append requests write there.

### Lazy-Create On First Write

When no working handoff exists:

1. Derive and slugify the session slug, asking if there is not enough context.
2. Derive and slugify author from `git config user.name`, asking if missing or empty.
3. Create `.session-continuity/handoffs/` if needed.
4. Create the filename with current UTC timestamp and collision suffix if needed.
5. Write the template with the first content already placed in the right section.
6. Set `Started`, `Last updated`, and raw `Author`.
7. Store the path in conversation context.

### Append

If content is a callout or callout-worthy finding, invoke `handle-callouts` and stop; it owns callout format, dedup, and placement.

For non-callout content, read the working handoff, splice content into the right section, and refresh `Last updated`.

Routing:

- Work completed -> `## Work done`
- TODOs, follow-ups, unresolved questions -> `## Open questions / next steps`
- High-level outcome or framing -> `## Summary`
- Retrospective insight -> `## Retrospective` only when invoked by `session-retrospect`

## Writing Style

Read `references/writing-style.md` before drafting or rewriting substantial handoff content.

Short version: future sessions read handoffs to resume work, so prefer concise bullets, outcomes over journey, and `path:line` references over pasted code.

## State

The working handoff path lives in conversation context. If it drops, rediscover by listing `.session-continuity/handoffs/` and matching the current session timestamp when possible; otherwise ask the user.

## Tool Usage

- Handoffs are Markdown, not code: use ordinary read/edit tools.
- Use shell only for simple filesystem/git facts such as `git config user.name` or creating the handoff directory.
- Do not edit previous-session handoffs. Corrections belong in the current session handoff.

## References

- `references/writing-style.md` — concise handoff writing rules.
- `handle-callouts/SKILL.md` — callout keywords, placement, dedup, and resolution.
