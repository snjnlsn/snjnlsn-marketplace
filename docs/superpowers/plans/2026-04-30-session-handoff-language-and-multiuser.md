# Session-handoff language/tone + multi-user filenames + migration — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Update `plugins/local_conf/skills/session-handoff/SKILL.md` to add language/tone guidance, a multi-user filename format (with `**Author:**` template field and a top-of-file disclaimer), and an active migration flow with reference-updates for pre-existing handoffs.

**Architecture:** All edits land in a single Markdown file: `plugins/local_conf/skills/session-handoff/SKILL.md`. Edits are inserted/replaced via `Edit` tool calls anchored on existing text. No code, no tests — the skill's runtime is the model reading these instructions when invoked, so "implementation" is the prose itself. The post-edit file structure is:

```
# Session Handoff
## When to use
## File location and naming           ← updated (Task 3)
## Document template                  ← updated (Task 2)
## Language and tone                  ← NEW (Task 1)
## Behaviors                          ← lightly updated (Task 4: lazy-create steps)
## Migration                          ← NEW (Task 5)
## Routing content to the right section
## State
```

**Tech Stack:** Markdown only. Edits via the `Edit` tool with exact `old_string`/`new_string` anchors.

**Spec:** `docs/superpowers/specs/2026-04-30-session-handoff-language-and-multiuser-design.md`

---

## File Structure

Files modified:

- `plugins/local_conf/skills/session-handoff/SKILL.md` — five edits across the file:
  1. Insert `## Language and tone` between `## Document template` and `## Behaviors` (Task 1).
  2. Replace the document template code block to add the disclaimer blockquote and `**Author:**` field (Task 2).
  3. Update `## File location and naming` to specify the new filename format, the slugifier, and author derivation (Task 3).
  4. Update the steps under `### Lazy-create on first write` to produce the new filename and template (Task 4).
  5. Insert a new `## Migration` section between `## Behaviors` and `## Routing content to the right section`, plus a one-line cross-reference at the top of `## Behaviors` (Task 5).

Files created: none.
Files deleted: none.

The `plugin.json` version is intentionally not bumped here — defer to the user when finalizing the branch.

## Verification approach

There are no executable tests. Each task is verified by reading the file back and confirming the inserted/replaced content matches the spec's verbatim text and that surrounding anchors are unchanged. Task 6 runs holistic structural checks against the file and a final diff inspection before the single commit.

**Discipline note for the implementer:** The new `## Language and tone` section contains rules the implementer should also apply to *their own* SKILL.md edits. The block tells future Claude how to write handoff prose, but the same anti-patterns (marketing adjectives, narrating the obvious, filler) apply to every word being added in this implementation.

---

### Task 1: Insert the "Language and tone" section

**Files:**
- Modify: `plugins/local_conf/skills/session-handoff/SKILL.md` (insert between the existing `## Document template` body and the `## Behaviors` heading).

The anchor is the closing paragraph of `## Document template` (the `## Retrospective` carve-out) followed by `## Behaviors`.

- [ ] **Step 1: Read the surrounding region to confirm the anchor**

Run (via the `Read` tool):

```
Read plugins/local_conf/skills/session-handoff/SKILL.md offset=49 limit=10
```

Expected to see (line numbers approximate, content exact):

```
A `## Retrospective` section is added later by the `session-retrospect` skill if it runs. Do not add it from this skill.

## Behaviors
```

If the surrounding text differs, stop and re-derive anchors before proceeding.

- [ ] **Step 2: Insert the new section via `Edit`**

Use the `Edit` tool on `plugins/local_conf/skills/session-handoff/SKILL.md`:

`old_string`:

```
A `## Retrospective` section is added later by the `session-retrospect` skill if it runs. Do not add it from this skill.

## Behaviors
```

`new_string`:

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
```

- [ ] **Step 3: Verify the insertion**

Run (via `Read`):

```
Read plugins/local_conf/skills/session-handoff/SKILL.md offset=50 limit=45
```

Confirm:
- Line ~52 is still the `A `## Retrospective`…` paragraph (unchanged).
- The next heading is `## Language and tone`, not `## Behaviors`.
- The first paragraph under `## Language and tone` begins `Handoffs are read by future Claude sessions`.
- The section ends with the "When in doubt, prefer a shorter handoff…" closer.
- Immediately after the closer comes `## Behaviors`, intact.

If any of those conditions fails, revert with `git restore plugins/local_conf/skills/session-handoff/SKILL.md` and redo.

- [ ] **Step 4: Do not commit yet**

All five tasks land in a single commit at the end of Task 6.

---

### Task 2: Update the document template (disclaimer + Author field)

**Files:**
- Modify: `plugins/local_conf/skills/session-handoff/SKILL.md` (replace the existing template code block under `## Document template`).

- [ ] **Step 1: Read the current template**

Run (via `Read`):

```
Read plugins/local_conf/skills/session-handoff/SKILL.md offset=29 limit=22
```

Expected (lines 29-50 approximately):

```
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
```

- [ ] **Step 2: Replace the template code block**

Use the `Edit` tool. Note: the `old_string` and `new_string` below contain a full Markdown code fence (```` ```markdown ... ``` ````). The `Edit` tool treats them as literal strings — there is no escaping issue, but be careful to copy the fences exactly.

`old_string`:

````
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
````

`new_string`:

````
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
````

- [ ] **Step 3: Verify the replacement**

Run (via `Read`) on the template region. Confirm:
- The code block under `## Document template` now contains the disclaimer blockquote (line starting `> **Auto-generated handoff.**`) immediately after `# <slug, humanized>`.
- A `**Author:** <git user.name>` line follows `**Last updated:**`.
- All three `##` sub-section headings (`## Summary`, `## Work done`, `## Open questions / next steps`) are present and unchanged.
- The closing ` ``` ` of the code block is intact.
- The `A `## Retrospective` section is added later…` paragraph still follows the code block.

---

### Task 3: Update the "File location and naming" section

**Files:**
- Modify: `plugins/local_conf/skills/session-handoff/SKILL.md` (replace the bullet list under `## File location and naming`).

- [ ] **Step 1: Read the current section**

Run (via `Read`):

```
Read plugins/local_conf/skills/session-handoff/SKILL.md offset=21 limit=8
```

Expected (lines 21-28 approximately):

```
## File location and naming

- Handoffs live at `docs/handoffs/` relative to the working repo's cwd.
- Filename: `YYYY-MM-DD-HHMMSS-<slug>.md`.
- `YYYY-MM-DD-HHMMSS` is the timestamp at the moment of *first content write* (lazy creation), not session start. Use UTC.
- `<slug>` is a short kebab-case summary derived from the session's work so far. If too sparse to summarize, ask the user.
- On slug collision in the same day, append `-2`, `-3`, etc.
```

- [ ] **Step 2: Replace the bullet list**

Use the `Edit` tool.

`old_string`:

```
## File location and naming

- Handoffs live at `docs/handoffs/` relative to the working repo's cwd.
- Filename: `YYYY-MM-DD-HHMMSS-<slug>.md`.
- `YYYY-MM-DD-HHMMSS` is the timestamp at the moment of *first content write* (lazy creation), not session start. Use UTC.
- `<slug>` is a short kebab-case summary derived from the session's work so far. If too sparse to summarize, ask the user.
- On slug collision in the same day, append `-2`, `-3`, etc.
```

`new_string`:

```
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
```

- [ ] **Step 3: Verify the replacement**

Run (via `Read`) on the section. Confirm:
- The filename format line now reads `YYYY-MM-DD-HHMMSS-<author>--<slug>.md` (with the `--` separator).
- A `<author>` derivation bullet is present.
- The collision-suffix bullet now states the `-N` attaches to the slug.
- A `### Slugifier` subsection follows the bullet list with the six-step procedure and three examples.
- The `## Document template` heading still follows immediately after.

---

### Task 4: Update the "Lazy-create on first write" steps

**Files:**
- Modify: `plugins/local_conf/skills/session-handoff/SKILL.md` (replace the numbered step list under `### Lazy-create on first write`).

- [ ] **Step 1: Read the current behavior**

Run (via `Read`):

```
Read plugins/local_conf/skills/session-handoff/SKILL.md offset=64 limit=14
```

Expected (lines 64-77 approximately, line numbers shifted by Task 1's insertion — search for `### Lazy-create on first write`):

```
### Lazy-create on first write

On the first write request without a working handoff:

1. Derive a slug from session work so far. If insufficient context, ask the user.
2. Get current UTC ISO timestamp; format `YYYY-MM-DD-HHMMSS` for the filename.
3. Check for slug collision in `docs/handoffs/` for today's date prefix. On collision, append `-2`, `-3`, etc.
4. Create `docs/handoffs/` if missing (use Bash `mkdir -p docs/handoffs`).
5. Use Write to create the file with the template, with the first content already in the right section.
6. Set "Started" and "Last updated" to the current ISO timestamp.
```

- [ ] **Step 2: Replace the step list**

Use the `Edit` tool.

`old_string`:

```
### Lazy-create on first write

On the first write request without a working handoff:

1. Derive a slug from session work so far. If insufficient context, ask the user.
2. Get current UTC ISO timestamp; format `YYYY-MM-DD-HHMMSS` for the filename.
3. Check for slug collision in `docs/handoffs/` for today's date prefix. On collision, append `-2`, `-3`, etc.
4. Create `docs/handoffs/` if missing (use Bash `mkdir -p docs/handoffs`).
5. Use Write to create the file with the template, with the first content already in the right section.
6. Set "Started" and "Last updated" to the current ISO timestamp.
```

`new_string`:

```
### Lazy-create on first write

On the first write request without a working handoff:

1. Derive a slug from session work so far. If insufficient context, ask the user. Run the slugifier on the result.
2. Derive `<author>`: read `git config user.name`, run the slugifier. If unset or empty after slugifying, prompt the user for an explicit author slug.
3. Get current UTC ISO timestamp; format `YYYY-MM-DD-HHMMSS` for the filename.
4. Compose the filename as `YYYY-MM-DD-HHMMSS-<author>--<slug>.md`.
5. Check for collision in `docs/handoffs/` for the same date prefix and full filename. On collision, append `-2`, `-3`, etc. to the slug portion (i.e., `…--<slug>-2.md`).
6. Create `docs/handoffs/` if missing (use Bash `mkdir -p docs/handoffs`).
7. Use Write to create the file with the template (including the disclaimer blockquote and `**Author:**` field), with the first content already in the right section.
8. Set "Started" and "Last updated" to the current ISO timestamp; set "Author" to the raw `git config user.name` (unsulgified). If the user provided an explicit author for the slug because git was unset, also use that value (raw form) for the `**Author:**` field.
```

- [ ] **Step 3: Verify the replacement**

Run (via `Read`) on the section. Confirm:
- The list now has 8 steps.
- Step 2 derives `<author>`.
- Step 4 composes the new filename.
- Step 7 references the disclaimer blockquote and `**Author:**` field.
- The `### Append to existing handoff` subsection still follows immediately.

---

### Task 5: Add the "Migration" section + cross-reference

**Files:**
- Modify: `plugins/local_conf/skills/session-handoff/SKILL.md`:
  - Insert a one-line cross-reference at the top of `## Behaviors`.
  - Insert a new `## Migration` section between `## Behaviors` (and its sub-behaviors) and `## Routing content to the right section`.

- [ ] **Step 1: Read the area where the cross-reference goes**

Run (via `Read`) and locate `## Behaviors`. Confirm the current state is:

```
## Behaviors

### Read existing handoff (for context)
```

- [ ] **Step 2: Insert the cross-reference under `## Behaviors`**

Use the `Edit` tool.

`old_string`:

```
## Behaviors

### Read existing handoff (for context)
```

`new_string`:

```
## Behaviors

On any session-touching invocation, run the migration check first (see `## Migration`). The user's response is honored for the rest of the session.

### Read existing handoff (for context)
```

- [ ] **Step 3: Locate the insertion point for the new `## Migration` section**

The new section goes between the `### Append to existing handoff` subsection and the existing `## Routing content to the right section` heading. Read the boundary.

Run (via `Read`) and locate the end of `### Append to existing handoff`. The current shape is:

```
### Append to existing handoff

1. Use Read to load the file.
2. Use Edit to splice content into the appropriate section (Summary, Work done, Open questions / next steps, Retrospective).
3. Use Edit to refresh the "Last updated" timestamp.

## Routing content to the right section
```

- [ ] **Step 4: Insert the new `## Migration` section**

Use the `Edit` tool.

`old_string`:

```
### Append to existing handoff

1. Use Read to load the file.
2. Use Edit to splice content into the appropriate section (Summary, Work done, Open questions / next steps, Retrospective).
3. Use Edit to refresh the "Last updated" timestamp.

## Routing content to the right section
```

`new_string`:

```
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
```

- [ ] **Step 5: Verify the insertions**

Run (via `Read`) and locate the file end-to-end. Confirm:
- A line "On any session-touching invocation, run the migration check first…" appears immediately under `## Behaviors`.
- The four sub-behaviors (`Read existing handoff`, `Continue / adopt existing handoff`, `Lazy-create on first write`, `Append to existing handoff`) are intact in their original order.
- A new `## Migration` section appears immediately after `### Append to existing handoff` and before `## Routing content to the right section`.
- The `## Migration` section contains the six sub-headings: `### Files in scope`, `### Field derivation per file`, `### Reference scan`, `### Migration prompt`, `### Application order`, `### Read tolerance after migration`, `### Edge cases`. (Seven sub-headings total.)
- `## Routing content to the right section` and `## State` follow unchanged.

---

### Task 6: Final verification, diff inspection, and commit

**Files:**
- All edits are in: `plugins/local_conf/skills/session-handoff/SKILL.md`.

- [ ] **Step 1: Run a top-level structural check**

Run:

```bash
grep -n '^## ' plugins/local_conf/skills/session-handoff/SKILL.md
```

Expected output (order matters; line numbers will shift due to insertions):

```
<line>:## When to use
<line>:## File location and naming
<line>:## Document template
<line>:## Language and tone
<line>:## Behaviors
<line>:## Migration
<line>:## Routing content to the right section
<line>:## State
```

If the order is wrong, fix before committing.

- [ ] **Step 2: Confirm the new top-level sections are present**

Run:

```bash
grep -cE '^## (Language and tone|Migration)$' plugins/local_conf/skills/session-handoff/SKILL.md
```

Expected: `2`

- [ ] **Step 3: Confirm key Migration sub-sections**

Run:

```bash
grep -nE '^### (Files in scope|Field derivation per file|Reference scan|Migration prompt|Application order|Read tolerance after migration|Edge cases)$' plugins/local_conf/skills/session-handoff/SKILL.md
```

Expected: 7 lines, in the order shown.

- [ ] **Step 4: Confirm Slugifier subsection inside File location and naming**

Run:

```bash
grep -nE '^### Slugifier$' plugins/local_conf/skills/session-handoff/SKILL.md
```

Expected: 1 match.

- [ ] **Step 5: Confirm the new template fields are present**

Run:

```bash
grep -nE '^\*\*Author:\*\* <git user\.name>$' plugins/local_conf/skills/session-handoff/SKILL.md
```

Expected: 1 match (inside the document template code block).

Run:

```bash
grep -n 'Auto-generated handoff' plugins/local_conf/skills/session-handoff/SKILL.md
```

Expected: at least 1 match (inside the template; possibly more if the migration prompt or edge cases reference it).

- [ ] **Step 6: Confirm the Behaviors cross-reference**

Run:

```bash
grep -n 'run the migration check first' plugins/local_conf/skills/session-handoff/SKILL.md
```

Expected: 1 match, immediately under the `## Behaviors` heading.

- [ ] **Step 7: Confirm the new filename format is documented**

Run:

```bash
grep -n 'YYYY-MM-DD-HHMMSS-<author>--<slug>\.md' plugins/local_conf/skills/session-handoff/SKILL.md
```

Expected: at least 2 matches (in `## File location and naming` and in `## Migration`'s "Files in scope").

- [ ] **Step 8: Inspect the diff**

Run:

```bash
git diff --stat plugins/local_conf/skills/session-handoff/SKILL.md
```

Expected: shows insertions roughly 150–180 lines added, with a small number of deletions (only the bullet list and template code block that were replaced in Tasks 2 and 3, plus the lazy-create steps replaced in Task 4).

Run:

```bash
git diff plugins/local_conf/skills/session-handoff/SKILL.md | head -60
```

Spot-check the first chunk of the diff. Confirm the insertions/replacements correspond to Tasks 1–5 and that no unrelated content has been disturbed (e.g., `## When to use`, `## Routing content to the right section`, `## State` should be untouched).

If the diff shows anything unexpected, revert the offending section and redo.

- [ ] **Step 9: Read the file end-to-end against the spec**

Open the spec (`docs/superpowers/specs/2026-04-30-session-handoff-language-and-multiuser-design.md`) and the edited SKILL.md side-by-side. Confirm:
- `## Language and tone` matches the spec's verbatim block (8-item anti-pattern list, 3-item per-section notes, "When in doubt…" closer).
- The disclaimer text in the document template matches the spec's verbatim disclaimer.
- The filename format is `YYYY-MM-DD-HHMMSS-<author>--<slug>.md` everywhere.
- The slugifier's six steps are present in `## File location and naming`.
- The migration scope, field derivation, prompt, reference scan, application order, and read tolerance subsections all match the spec.

If any text drifts from the spec, fix and re-verify.

- [ ] **Step 10: Stage and commit**

Run:

```bash
git add plugins/local_conf/skills/session-handoff/SKILL.md
git commit -m "$(cat <<'EOF'
Update session-handoff: tone guidance + multi-user filenames + migration

Adds:
- Language and tone section tailored to handoff prose
- Top-of-file disclaimer blockquote in the document template
- **Author:** field in the document template
- New filename format YYYY-MM-DD-HHMMSS-<author>--<slug>.md
- Slugifier procedure
- Migration section covering eligibility, field derivation,
  reference scan, prompt, application order, and read tolerance

Spec: docs/superpowers/specs/2026-04-30-session-handoff-language-and-multiuser-design.md
EOF
)"
```

Expected: a single new commit on `feat/session-handoff-language-and-multiuser`, one file changed.

- [ ] **Step 11: Confirm commit landed**

Run:

```bash
git log --oneline -3
```

Expected: the new commit on top, followed by the spec commit (`Spec session-handoff language/tone…`).

Run:

```bash
git status
```

Expected: working tree clean.

---

## Self-review — issues found and resolved

**Spec coverage check:**

- Spec § "1. Language and tone" → Task 1 inserts the verbatim block. ✓
- Spec § "2. Multi-user filename format" → Task 3 updates the filename spec and adds the slugifier subsection. ✓
- Spec § "3. Template `**Author:**` field" → Task 2 adds the field to the template. ✓
- Spec § "4. Top-of-file disclaimer block" → Task 2 adds the disclaimer blockquote to the template; Task 5's "Application order" handles disclaimer insertion during migration. ✓
- Spec § "5. Active migration" → Task 5 adds the entire `## Migration` section (when migration runs, files in scope, field derivation, prompt, reference updates, application order, read tolerance, edge cases). ✓
- Spec § "Updated document template" → Task 2 produces this template verbatim. ✓
- Spec § "Resolved decisions" — captured in the spec; no separate task needed. ✓
- Spec § "Files affected" → only `SKILL.md`; Task 6 Step 8 diff check confirms no other file changed. ✓
- Spec § "Out of scope" — no version bump, no SessionStart-hook touch, no session-retrospect touch. No task in this plan touches those. ✓

**Placeholder scan:**

- No "TBD"/"TODO"/"implement later" anywhere. ✓
- All `old_string` and `new_string` blocks contain the exact verbatim Markdown to insert/replace. ✓
- Verification commands include the exact regex/string to search for and the expected match count or content. ✓
- Commit message is provided in full via heredoc. ✓

**Type/text consistency:**

- The disclaimer text in Task 2 (`new_string`) matches the disclaimer text in the spec character-for-character.
- The Language and tone section in Task 1 (`new_string`) matches the spec's verbatim block character-for-character.
- The slugifier procedure in Task 3 (`new_string`) matches the spec's six steps.
- The migration section in Task 5 (`new_string`) carries the same field derivation chains, prompt format, application order, and edge cases as the spec.
- The new filename format `YYYY-MM-DD-HHMMSS-<author>--<slug>.md` (with `--` separator) is consistent across Tasks 3, 4, and 5.

No fixes needed.
