# Repo Docs

Load this reference for Phase 3 of `finalize-branch`.

## Surfaces

Consider live project docs:

- `docs/**`, excluding `docs/superpowers/**`
- root `README.md`
- root `CLAUDE.md` and any nested `CLAUDE.md` surfaced by audit

Do not edit `.claude/**`. Do not edit `.session-continuity/handoffs/**` here; handoff deletion belongs to the final phase.

## Proposal Buckets

- `Update`: existing doc says something stale because of this branch.
- `Augment`: existing doc is correct but missing a branch-relevant fact.
- `Create`: no existing doc covers a significant new topic. Always opt in per file.
- `Reorganize`: bounded merge/move/split suggestions only when this branch makes the overlap relevant. Always opt in.

Callouts routed to repo docs become `Augment` proposals against the resolved destination. If the destination is bootstrapped, it becomes a `Create` proposal.

## Surface Rules

- `CLAUDE.md`: propose additions only when absence would actively mislead future Claude sessions, such as changed commands or conventions.
- `README.md`: change only when the branch touches install steps, usage commands, or public surfaces the README already covers.
- New docs: scan nearby `docs/` structure and propose a fitting path; default to `docs/<kebab-topic>.md`.

## Approval Flow

Use one document as the unit. For create proposals, show path, rationale, and full body. For reorganize proposals, show file moves and combined diffs.

Apply approved edits immediately. Summarize updated, augmented, created, reorganized, and skipped docs, then ask whether to proceed to handoff cleanup and final commit.
