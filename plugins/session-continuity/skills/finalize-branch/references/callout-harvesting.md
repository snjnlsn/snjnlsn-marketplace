# Callout Harvesting

Load this reference during audit Phase 1 when confirmed branch handoffs contain callout-shaped headings.

## Audit Setup

Confirm handoffs with:

```bash
git log --name-only --pretty=format: <base>..HEAD -- .session-continuity/handoffs/
```

Show the list oldest to newest and ask the user to proceed or edit. If none exist, report that context comes from commits and diffs only.

Build the source-of-truth picture from `git diff <base>..HEAD`, diff stat, and confirmed handoffs. Resolve conflicts by **current code > newest handoff > older handoffs**. Ask ambiguity questions in small chunks; each question gets a recommended answer and supports `accept`, `change: ...`, or `skip`.

## Callout Matching

A callout is a Markdown heading whose text starts with one of these singular or plural keywords:

- Discovery / Discoveries
- Decision / Decisions
- Caveat / Caveats
- Gotcha / Gotchas
- Lesson learned / Lessons learned
- Known issue / Known issues
- Complexity / Complexities
- Edge case / Edge cases

Allow optional numbering and a separator after the keyword. Ignore matches inside fenced code blocks and plain prose mentions.

## Dedup And Resolution

Cluster callouts when either normalized heading text matches or the body describes the same finding. Ignore `> Resolved...` marker lines when comparing body substance.

Collapse exact duplicates silently. Prompt for divergent matches with a short excerpt from each source and a proposed synthesis. Choices:

- `m`: merge the synthesis.
- `f`: keep earliest.
- `l`: keep latest.
- `b`: keep both.
- `nuance: ...`: revise and re-prompt.

If the newest cluster member has a `> Resolved...` marker, skip routing that cluster and count it as resolved. If an older member was resolved but a newer member is active, treat the cluster as reopened and mention that history in the prompt.

For issue-shaped active callouts (`Known issue`, `Caveat`, `Gotcha`, `Edge case`, `Complexity`), optionally run a diff-evidence scan. If mentioned paths or symbols changed substantially, ask whether to mark resolved, route normally, or show diff.

## Destination

Route repo-doc callouts to the project discovery destination:

1. If `.claude/finalize-branch.toml` or `.claude/finalize-branch.json` exists, parse `discoveries.destination`, optional `section`, and optional `patterns`. Halt on parse error or missing destination file.
2. Otherwise scan `docs/` one level deep for a single matching file: `discoveries.md`, `decisions.md`, `findings.md`, `lessons.md`, `caveats.md`, `gotchas.md`, or `notes.md`.
3. If none exist, ask to create `docs/discoveries.md` or accept a nuanced path.
4. If multiple exist, ask whether to pick one for this branch, queue a bounded merge proposal for repo docs, or halt so the user can add an override.

Default section is `## Discoveries`; create it in the repo-doc proposal if missing.

## Routing Walk

Walk active callouts one at a time. Show source handoff, heading, short body excerpt, recommendation, and reason.

Choices:

- `a`: already captured in code/docs.
- `c`: add to inline code docs.
- `r`: add to repo docs.
- `d`: dismiss as transient.
- `nuance: ...`: revise recommendation and re-prompt.

Recommendations:

- `add-to-repo-docs`: API/data contracts, project-wide conventions, or external-system facts.
- `add-to-inline-code`: tightly bound to a modified symbol.
- `already-captured`: heading/fact already appears in non-handoff code or docs.
- `dismiss`: transient session history with no permanent value.

Every extracted callout must have an explicit routing decision before leaving the audit phase.

## Repo-Doc Rewrite

When routing to repo docs:

- Strip session, branch, PR, and plan references.
- Convert to present tense system behavior.
- Promote `### Discovery N - title` to `### title`.
- Keep code fences, data fences, and tables verbatim.
- Do not link back to handoffs; they will be deleted.

Queue the rewritten entry as a repo-doc augment/create proposal. Preserve chronological routing order.
