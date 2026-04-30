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
- Filename: `YYYY-MM-DD-HHMMSS-<author>--<slug>.md`. The `--` (double-hyphen) between `<author>` and `<slug>` is required so the boundary is unambiguous when parsing. The slugifier collapses runs of hyphens to single hyphens, so neither field contains `--` internally.
- `YYYY-MM-DD-HHMMSS` is the timestamp at the moment of *first content write* (lazy creation), not session start. Use UTC.
- `<author>` is derived from `git config user.name` via the slugifier (below). If `git config user.name` is unset or slugifies to empty, prompt the user for an explicit author slug for the session.
- `<slug>` is a short kebab-case summary derived from the session's work so far. If too sparse to summarize, ask the user.
- On slug collision in the same day, append `-2`, `-3`, etc. The `-N` suffix attaches to the slug, not the author: `…--<slug>-2.md`.

### Slugifier

Used for `<author>` (from `git config user.name`) and for `<slug>` (from a user-typed or model-generated topic):

1. Lowercase.
2. Replace whitespace and `_` with `-`.
3. Strip characters that are not ASCII alphanumeric or `-`.
4. Collapse runs of `-` to a single `-`.
5. Trim leading/trailing `-`.
6. If the result is empty, prompt the user for an explicit value.

Examples:
- `Sanjay Nelson` → `sanjay-nelson`
- `Jane Doe-Smith` → `jane-doe-smith`
- `日本語` → empty → prompt user

## Document template

Use this exact structure when creating a new handoff:

```markdown
# <slug, humanized>

> **Auto-generated handoff.** Written by the `session-handoff` skill to carry context across multiple sessions on an in-progress worktree, branch, or feature. The newest handoff (by `Last updated`) supersedes older ones for the same work. Handoffs do not survive completion — once the work merges, follow-up commits may invalidate the recorded state, so the `finalize-branch` skill deletes them at merge time.

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

A `## Retrospective` section is added later by the `session-retrospect` skill if it runs. Do not add it from this skill.

## Language and tone

Handoffs are read by future Claude sessions to resume work without re-deriving context. Every word should serve that goal.

**Be clear and concise first.** A handoff that takes five minutes to read replaces an hour of re-derivation — but only if it stays tight. When in doubt, cut. Bullets over paragraphs. `path:line` references over restated code. Decisions over deliberation.

**Anti-patterns** — these signal "an LLM wrote this" or pad bytes without earning them:

- **Marketing adjectives** — "seamless(ly)", "powerful", "robust", "elegant", "comprehensive". Cut them.
- **Narrating the obvious** — "We made a commit." The SHA plus a one-line summary is the substance; the act of committing is not.
- **Filler and hedges** — "In order to" → "to"; drop "It should be noted that…", "Please note", "It is important to". (Genuine counter-intuitive caveats are a separate case — flag them when they exist.)
- **Vague verbs without outcomes** — "explored the codebase", "investigated X", "discussed Y". Say what was decided, found, or changed. If nothing concrete came of it, the bullet doesn't belong in "Work done".
- **Restating the same fact across sections** — Summary frames, Work done details, Open questions lists what's unresolved. Hierarchy is fine; verbatim duplication is not.
- **Inline code dumps** — link to `path:line` instead of pasting blocks. A short snippet is fine when it's the *substance* of a decision; longer blocks belong in the file, not the handoff.
- **Editorial self-praise** — "This elegant solution…", "An efficient approach…". Let the work speak.
- **Vague future commitments** — distinguish honestly: `will` (confirmed), `should` (recommended), `might` (speculative). If you can't say what action would resolve an open question, leave it out.

**Per-section notes:**

- **Summary** — 1–3 sentences. The minimum a future reader needs to decide whether to read further. Lead with outcome, not journey.
- **Work done** — bullets. State the decision or change, not the path to it. Link to commits, files, or specs by reference.
- **Open questions / next steps** — actionable items. Each entry should be something a future session could pick up without re-deriving context.

When in doubt, prefer a shorter handoff over a longer one. Edits that *reduce* word count without losing information are almost always correct.

## Behaviors

On any session-touching invocation, run the migration check first (see `## Migration`). The user's response is honored for the rest of the session.

### Read existing handoff (for context)

Use the Read tool on the requested file (or the most recent file in `docs/handoffs/` if unspecified). Summarize relevance to the current session. If the user says to adopt it as the working handoff, do so.

### Continue / adopt existing handoff

Set the working handoff path in conversation context to that file. Subsequent "add to handoff" calls write there.

### Lazy-create on first write

On the first write request without a working handoff:

1. Derive a slug from session work so far. If insufficient context, ask the user. Run the slugifier on the result.
2. Derive `<author>`: read `git config user.name`, run the slugifier. If unset or empty after slugifying, prompt the user for an explicit author slug.
3. Get current UTC ISO timestamp; format `YYYY-MM-DD-HHMMSS` for the filename.
4. Compose the filename as `YYYY-MM-DD-HHMMSS-<author>--<slug>.md`.
5. Check for collision in `docs/handoffs/` for the same date prefix and full filename. On collision, append `-2`, `-3`, etc. to the slug portion (i.e., `…--<slug>-2.md`).
6. Create `docs/handoffs/` if missing (use Bash `mkdir -p docs/handoffs`).
7. Use Write to create the file with the template (including the disclaimer blockquote and `**Author:**` field), with the first content already in the right section.
8. Set "Started" and "Last updated" to the current ISO timestamp; set "Author" to the raw `git config user.name` (unslugified). If the user provided an explicit author for the slug because git was unset, also use that value (raw form) for the `**Author:**` field.

### Append to existing handoff

1. Use Read to load the file.
2. Use Edit to splice content into the appropriate section (Summary, Work done, Open questions / next steps, Retrospective).
3. Use Edit to refresh the "Last updated" timestamp.

## Migration

On any session-touching invocation (read, list, write), scan `docs/handoffs/` for files that don't match the new format. If any exist, prompt **once per session** to migrate. The user's response (`yes` / `no` / `show` / `details`) is honored for the rest of the session — `no` does not re-prompt within the same session.

### Files in scope

A `.md` file directly under `docs/handoffs/` is a migration candidate if **all** of:

1. Its filename does **not** match `YYYY-MM-DD-HHMMSS-<author>--<slug>.md` (i.e., no `--` after a `YYYY-MM-DD-HHMMSS` prefix).
2. Its git author matches the current `git config user.name`.

The git-author filter is a safety mechanism: never rename a file authored by someone else, even if the filename looks weird. Untracked files are treated as authored by the current user.

Filename detection is intentionally permissive. All of these qualify, given the git-author filter:

- `YYYY-MM-DD-HHMMSS-<slug>.md` (the original old format)
- `YYYY-MM-DD-<slug>.md` (date only)
- `YYYY-MM-DD-HHMM-<slug>.md` (no seconds)
- `YYYYMMDD-<anything>.md`
- `<slug>.md` (no date prefix)
- Anything else `.md` in `docs/handoffs/` authored by the current user

### Field derivation per file

For each candidate, compute the components of the new filename via fallback chains:

1. **Author (raw, for template)** — `git log --diff-filter=A --pretty=format:'%an' -- <path> | head -1` (author of the commit that introduced the file). Fall back to `git config user.name` for untracked files. Slugify for the filename's `<author>` segment.
2. **Date + time** —
   1. Parse a leading `YYYY-MM-DD[-HHMM[SS]]` from the original filename. Pad time to `HHMMSS` with zeros if missing.
   2. `git log --diff-filter=A --pretty=format:'%aI' -- <path> | head -1` → split into date and `HHMMSS` (UTC).
   3. File `mtime` in UTC.
3. **Slug** — strip extension and any recognized leading date prefix, then run the slugifier on the remainder. If empty, prompt the user for a slug for that specific file.

### Reference scan

Before any rename, scan the repo for occurrences of each candidate's bare filename (e.g., `2026-04-15-foo.md`).

- Use `git grep <bare-filename>` to honor `.gitignore` automatically. Fall back to `Grep` with manual excludes (`.git/`) if the working directory is not a git repo.
- Search query is the bare filename, not the full path. This catches references in any reasonable form (`docs/handoffs/<file>`, `handoffs/<file>`, `./docs/handoffs/<file>`, or just `<file>` in prose).
- Show each match with three lines of surrounding context in the migration prompt so the user can sanity-check for false positives.

### Migration prompt

Present a unified preview before any change is applied:

```
Found handoffs that don't match the new naming format:

  Eligible for migration (3 by `Sanjay Nelson`):
    2026-04-15-foo.md → 2026-04-15-000000-sanjay-nelson--foo.md
    2026-04-18-bar.md → 2026-04-18-000000-sanjay-nelson--bar.md
    2026-04-22-baz.md → 2026-04-22-000000-sanjay-nelson--baz.md

  Skipped (2 by `Other Person`)

  References found in 4 file(s):
    docs/architecture.md:42  → '…see docs/handoffs/2026-04-15-foo.md…'
    CLAUDE.md:18             → '…the handoff at 2026-04-15-foo.md notes…'
    plugins/local_conf/scripts/foo.sh:7  → '…cat docs/handoffs/2026-04-18-bar.md…'
    docs/handoffs/2026-04-22-baz.md:14   → '…follows from 2026-04-18-bar.md…'

Apply renames + reference updates? (`yes` / `no` / `show full diff` / `exclude <line>` / `exclude refs` — rename only)
```

`details` (selectable before the main prompt response) elaborates on each skipped file's reason.

### Application order

On `yes`:

1. **Update file contents first** — apply all reference replacements (old filename → new filename) across the matched files. Includes handoff files in the rename set, since they may cross-reference each other. Replacement is bare-filename → new-bare-filename; full-path occurrences naturally pick up the new name as a substring.
2. **Apply renames second** — `git mv <old> <new>` for tracked files (preserves history); plain `mv` for untracked.
3. **Insert `**Author:**`** in the renamed file's body if absent. Detection: any line matching `^\*\*Author:\*\*` between the H1 and the first `##` heading counts as present, regardless of value (don't silently overwrite a manually-set author). Insertion point: after `**Last updated:**` if present, otherwise immediately before the first `##` heading.
4. **Insert the disclaimer blockquote** if absent. Detection logic:
   - If a verbatim copy of the disclaimer already exists between the H1 and the metadata fields, skip silently.
   - If any *other* blockquote (lines starting with `> `) exists in that region, prompt: `below` (insert disclaimer after the existing blockquote) / `replace` (delete the existing blockquote and insert the disclaimer) / `skip` (leave the file alone).
   - Otherwise insert the disclaimer immediately under the H1, followed by a blank line.

Edits run before renames so each replacement targets the file at its current path. After step 2, the file is at its new path and steps 3/4 operate there.

The skill **does not auto-commit** migration. Renames and edits sit in the working tree for the user to commit at their own cadence (recommended: a single "migrate handoffs to new format" commit).

### Read tolerance after migration

Read and list logic tolerates **any** filename in `docs/handoffs/`, not just the two enumerated formats. Some users will answer `no` to migration; some external dumps may use the old format.

When parsing a filename:
- If `--` is present after a `YYYY-MM-DD-HHMMSS` prefix: split on first `--`, segment before is `<author>`, segment after is `<slug>`.
- Otherwise: entire post-prefix segment (or full stem if no recognizable prefix) is treated as `<slug>`; no `<author>` component, fall back to the document body's `**Author:**` line if present.

### Edge cases

- **Multiple authors in a file's history** — use the original author from `--diff-filter=A`. Don't reflect the latest editor.
- **`git mv` fails mid-migration** — abort that file's migration with a clear error and continue with the rest. Report which renames succeeded.
- **Reference inside a binary file** — `git grep` skips binaries by default; preserve.
- **A reference uses a wrong/old slug** — won't be matched; that's correct: only update references that point at files we're renaming.
- **External references** (other repos, Slack, browser bookmarks) — out of scope.
- **`docs/handoffs/` empty or missing** — no migration to do; skip silently.
- **Disclaimer already present verbatim** — skip silently. **Other blockquote present in the same region** — prompt with `below` / `replace` / `skip`.
- **`git config user.name` unset** — prompt the user (no silent default).
- **User answers `no` in session A, session B starts** — the prompt re-fires in B. Per-session, not per-repo.

## Routing content to the right section

- A description of work completed → "Work done"
- A TODO, follow-up item, or unresolved question → "Open questions / next steps"
- A high-level framing or outcome statement → "Summary"
- Retrospective insight (only via `session-retrospect` skill) → "Retrospective"

## State

The working handoff path is held in conversation context. If conversation context drops it, re-discover by listing `docs/handoffs/` and picking the file whose timestamp matches the current session, or ask the user.
