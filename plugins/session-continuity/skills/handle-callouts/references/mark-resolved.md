# Mark Resolved

Use when the user or current diff closes out a previously recorded callout.

## Target

Resolve against the working handoff first. If not found there, scan older branch handoffs read-only and surface likely matches for confirmation.

If no target is clear, ask the user for the heading or body.

## Marker

Write a blockquote as the first body line:

```markdown
> Resolved: <note or commit ref>
```

Bare `> Resolved` is allowed. Show the proposed marker when there is ambiguity or when recognition is proactive.

## Write Rules

- Target in working handoff: insert the marker under the existing callout heading and refresh `Last updated`.
- Target in older handoff: write a resolution-only callout to the working handoff. Copy the old heading and use only the marker as the body.
- Existing marker: ask whether to replace, keep existing, or cancel.

Report one line naming the resolved heading and path.
