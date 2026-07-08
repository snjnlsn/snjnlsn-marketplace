# Handoff Reference Cleanup

Load this reference after callout routing when the branch has handoffs to delete or callouts were extracted.

## Scope

Scan source files across the repo, not just the branch diff. Skip generated files, fixtures, lockfiles, binary files, and non-source docs.

This is text-level work. Search for matches, then read 1-3 lines of surrounding context.

## Match Families

- Handoff path references: `.session-continuity/handoffs/<filename>` or equivalent confirmed deletion paths.
- Callout identifier references: `<callout keyword> <number>`, such as `Discovery 4`, when the identifier exists in extracted handoffs.

Matches in comments and docstrings are normal cleanup candidates. Matches in string literals or path arguments should be flagged as possible real code dependencies and usually skipped.

## Resolution Choices

Each match becomes an inline-code-doc proposal resolved during Phase 2:

- `inline`: replace the reference with the relevant fact in the comment/doc itself.
- `redirect`: replace it with a pointer to the repo-doc destination and rewritten title. Only available when the referenced callout was routed to repo docs.
- `remove`: delete the reference when surrounding text remains self-contained or the concern was dismissed/resolved.
- `skip`: leave as-is. Warn that it may dangle after handoff deletion.

Recommend:

- `redirect` for callouts routed to repo docs.
- `inline` for callouts routed to inline docs near the matched symbol.
- `remove` for dismissed, already-captured, or resolved callouts.
- `skip` when no matching branch callout or deletion-path relation exists.

Every detected reference must have a resolution or explicit skip before handoff deletion. A recorded skip does not block finalization, but the phase summary must call it out.
