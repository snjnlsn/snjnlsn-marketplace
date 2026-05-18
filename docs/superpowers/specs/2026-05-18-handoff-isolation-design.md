# Handoff isolation: storage move + self-marking disclaimer

Two fixes to the session-continuity plugin that, together, make handoff files
more clearly skill-internal:

1. **Move handoff storage** out of `.claude/` to `.session-continuity/handoffs/`
   so the harness's permission gating stops prompting on every read/write.
2. **Bake a hardcoded disclaimer** into every new handoff file at creation, so
   any LLM that reads one knows it's a per-session historical record, not
   editable from outside the authoring session, and not citable as project
   documentation.

No migration is provided. Existing repos with `.claude/handoffs/` keep that
directory as-is; this change applies going forward.

## Storage path change

New canonical path: **`.session-continuity/handoffs/`** at the consuming repo's
root.

All current references to `.claude/handoffs/` are replaced with
`.session-continuity/handoffs/` — substring-mechanical change with no behavioral
difference. Files affected:

- `plugins/session-continuity/scripts/setup-handoffs.sh`
  — `HANDOFF_DIR=` constant, docstring/comment header, the seeded `README.md`
  heading.
- `plugins/session-continuity/scripts/handoff-list-recent.sh`
  — `HANDOFF_DIR=` constant, header comment.
- `plugins/session-continuity/skills/session-handoff/SKILL.md`
  — frontmatter `description`, all body references.
- `plugins/session-continuity/skills/read-branch-handoffs/SKILL.md`
  — all references, including the `git log --name-only ... -- <dir>` examples.
- `plugins/session-continuity/skills/finalize-branch/SKILL.md`
  — all references, including the `git log` examples, the file-listing
  examples ("`.claude/handoffs/2026-04-15-…`" → new path), and the
  must-not-delete invariants (`README.md` sentinel, directory itself).
- `plugins/session-continuity/skills/handle-callouts/SKILL.md`
  — both references.
- `plugins/session-continuity/README.md`
  — all references, including the directory-tree illustration.

The seeded sentinel `README.md` keeps the same body content; only its
first-line heading changes (`# .session-continuity/handoffs/`).

## `finalize-branch`'s in-code reference scrubber

`finalize-branch`'s Phase 4 (or equivalent) currently greps for literal
`.claude/handoffs/<filename>` substrings in code and docs as part of pruning
stale references to deleted handoffs. That substring becomes
`.session-continuity/handoffs/<filename>`.

**No backward-compat search is added** for the old path. Rationale: once a
repo moves to the new path, references to the old path in code/docs are stale
by definition; cleanup is a one-time manual `grep -r '\.claude/handoffs'` for
the user (or simply ignored, since the references no longer point anywhere
meaningful). The skill does not need to carry permanent dead-path detection.

## Setup script

`setup-handoffs.sh` keeps its current idempotent shape — create the directory
if missing, seed the README if missing, no-op otherwise. Only the
`HANDOFF_DIR` constant and the seeded README's heading change. No migration
branch, no detection of legacy `.claude/handoffs/`, no `git mv`.

The script is run per consuming repo as before.

## Disclaimer

`session-handoff` prepends this exact HTML comment block to every new handoff
file at creation:

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
```

Placement: very top of the file, before the document title and any other
content. HTML comment chosen so it is invisible in rendered markdown but
reliably read by any LLM consuming the raw text. The intended audience is
LLMs; humans already know the rule.

The block is a single hardcoded string in `session-handoff`'s "create new
handoff" flow. It is not parameterized (no session timestamp, no author) —
keeping it byte-identical across all new handoffs makes the file's role
unambiguous and trivially recognizable.

### Replaces the existing blockquote disclaimer

The current template (line 53 of `session-handoff/SKILL.md`) opens with a
visible `> **Auto-generated handoff.**` blockquote that explains skill
ownership, supersession, and finalize-branch deletion to human readers. The
new HTML comment **replaces** that blockquote; both are not retained. The
HTML comment absorbs the supersession point (second sentence) so nothing
content-wise is lost. The visible-to-humans framing is sacrificed; in
practice humans interact with handoffs almost exclusively through the
session-continuity skills, not by reading raw files.

Three places in the existing skill reference the blockquote and need to
follow the replacement:

- **Template (line ~53)** — replace the `> **Auto-generated handoff.**`
  blockquote with the HTML comment, placed above the H1 (the template's
  current order has the blockquote under the H1; the new order places the
  comment first, then the H1).
- **Migration flow "Insert the disclaimer blockquote" step (lines ~217–220)**
  — repurpose to insert the HTML comment instead. The detection logic
  (verbatim-present check, other-blockquote-in-region prompt) becomes
  verbatim-HTML-comment-present check + "any HTML comment in the
  pre-content region" prompt. The prompt options become `replace` / `keep` / `skip` — `keep` inserts the disclaimer above the existing comment so the disclaimer remains at position 0 (the existing comment shifts to position 1). This is a refinement from the legacy `below` semantic, which would have placed the disclaimer second and defeated the position-0 invariant.
- **Edge case bullet (line ~242)** — restate in terms of the HTML comment.

### Existing handoffs are not retroactively rewritten

Past-session handoffs (already on disk in any repo) are **not** updated with
the new disclaimer. Doing so would itself be a past-session edit, defeating
the discipline the disclaimer is meant to encourage. Only new handoffs
created after this change ships carry the block. Older handoffs continue to
work normally — the skills' read paths tolerate handoffs without the block
and handoffs with the legacy blockquote.

### Read path: treat the block as metadata, not content

`session-handoff`'s "read existing handoff" flow (and any other read that
summarizes or quotes from a handoff) recognizes this HTML comment block as
file-format metadata and does not echo it back as part of the handoff's
substance. Practically: when summarizing, skip the block; when copying
content into context, the block can be retained verbatim (it is short and
self-explanatory) but it is not treated as content needing summary.

## Out of scope

- `PreToolUse` / hook-based enforcement that would *block* edits to past
  handoff files. The disclaimer is advisory only. Reach for hook enforcement
  later if the advisory disclaimer proves insufficient.
- Retroactive disclaimers on pre-existing handoffs.
- Migration of `.claude/handoffs/` to `.session-continuity/handoffs/` —
  intentionally omitted per design discussion.
- Backward-compat reads from `.claude/handoffs/` after the path change.

## Validation

- `grep -rn '\.claude/handoffs' plugins/session-continuity` returns zero
  matches after the changes land.
- `bash plugins/session-continuity/scripts/setup-handoffs.sh` run in a fresh
  repo creates `.session-continuity/handoffs/` and seeds the README with the
  updated heading. A second invocation is a no-op.
- A newly-created handoff (via `session-handoff`) contains the HTML comment
  block as its first content, before the title.
- Rendered markdown view of a new handoff does not show the disclaimer
  (sanity check that the HTML comment is well-formed).
