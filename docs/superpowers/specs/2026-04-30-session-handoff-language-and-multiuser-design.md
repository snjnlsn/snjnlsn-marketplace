# Session-handoff: language and tone + multi-user filenames + migration

## Context

The `session-handoff` skill (`plugins/local_conf/skills/session-handoff/SKILL.md`) maintains one Markdown handoff per session under `docs/handoffs/`. Five improvements ship together as one update:

1. **Language and tone guidance** for the prose the skill writes — kin to the recently-added section in `finalize-branch`, but tuned for handoff surfaces (handoffs are ephemeral working notes, not project documentation).
2. **Multi-user filename support** — current `YYYY-MM-DD-HHMMSS-<slug>.md` collides across users sharing a `docs/handoffs/` directory. New format adds an author slug.
3. **`**Author:**` template field** so the doc body identifies who wrote it independent of filename.
4. **Active migration** of any pre-existing handoffs to the new format, scoped to the current user's authored files.
5. **Top-of-file disclaimer block** clarifying that handoffs are auto-generated, ephemeral, and superseded by the newest one for the same work.

Out of scope: changes to the `session-retrospect` skill, the SessionStart hook, or other handoff consumers. The disclaimer mentions `finalize-branch` because that skill *deletes* handoffs at completion time — that link is informational, not a code dependency.

## Design

### 1. Language and tone

A new top-level section `## Language and tone` is added between `## Document template` and `## Behaviors`. The order goes: structure → voice → actions. The block is inline (no pointer indirection like in `finalize-branch`) because session-handoff is small and only its own behaviors consume the rules.

Verbatim text to insert:

> ## Language and tone
>
> Handoffs are read by future Claude sessions to resume work without re-deriving context. Every word should serve that goal.
>
> **Be clear and concise first.** A handoff that takes five minutes to read replaces an hour of re-derivation — but only if it stays tight. When in doubt, cut. Bullets over paragraphs. `path:line` references over restated code. Decisions over deliberation.
>
> **Anti-patterns** — these signal "an LLM wrote this" or pad bytes without earning them:
>
> - **Marketing adjectives** — "seamless(ly)", "powerful", "robust", "elegant", "comprehensive". Cut them.
> - **Narrating the obvious** — "We made a commit." The SHA plus a one-line summary is the substance; the act of committing is not.
> - **Filler and hedges** — "In order to" → "to"; drop "It should be noted that…", "Please note", "It is important to". (Genuine counter-intuitive caveats are a separate case — flag them when they exist.)
> - **Vague verbs without outcomes** — "explored the codebase", "investigated X", "discussed Y". Say what was decided, found, or changed. If nothing concrete came of it, the bullet doesn't belong in "Work done".
> - **Restating the same fact across sections** — Summary frames, Work done details, Open questions lists what's unresolved. Hierarchy is fine; verbatim duplication is not.
> - **Inline code dumps** — link to `path:line` instead of pasting blocks. A short snippet is fine when it's the *substance* of a decision; longer blocks belong in the file, not the handoff.
> - **Editorial self-praise** — "This elegant solution…", "An efficient approach…". Let the work speak.
> - **Vague future commitments** — distinguish honestly: `will` (confirmed), `should` (recommended), `might` (speculative). If you can't say what action would resolve an open question, leave it out.
>
> **Per-section notes:**
>
> - **Summary** — 1–3 sentences. The minimum a future reader needs to decide whether to read further. Lead with outcome, not journey.
> - **Work done** — bullets. State the decision or change, not the path to it. Link to commits, files, or specs by reference.
> - **Open questions / next steps** — actionable items. Each entry should be something a future session could pick up without re-deriving context.
>
> When in doubt, prefer a shorter handoff over a longer one. Edits that *reduce* word count without losing information are almost always correct.

### 2. Multi-user filename format

Filename change:

- **Old:** `YYYY-MM-DD-HHMMSS-<slug>.md`
- **New:** `YYYY-MM-DD-HHMMSS-<author>--<slug>.md`

The `--` (double-hyphen) separator between author and slug is required. Single-hyphen slugs cannot disambiguate `2026-04-30-141022-deploy-fix.md` between author=`deploy`/slug=`fix` and slug=`deploy-fix`; the double-hyphen makes the boundary unambiguous because the slugifier collapses runs of hyphens to single ones, so neither field contains `--` internally.

**Slugifier** (used for the `<author>` field and for `<slug>` from user-typed inputs):

1. Lowercase.
2. Replace whitespace and `_` with `-`.
3. Strip characters that are not ASCII alphanumeric or `-`.
4. Collapse runs of `-` to single `-`.
5. Trim leading/trailing `-`.
6. If the result is empty, prompt the user for an explicit slug.

**Author derivation for new handoffs:**

1. Run `git config user.name`. If non-empty, slugify and use as `<author>`.
2. If unset or slugifies to empty, prompt the user for an author slug for the session.

### 3. Template `**Author:**` field

The document template gains an `**Author:**` line, between `**Last updated:**` and the first `##` heading. The value is the raw `git config user.name` (e.g., `Sanjay Nelson`), not the slugified form — readable in the doc body, slugified only for the filename.

If `git config user.name` is unset, prompt for a display name when first writing the file.

### 4. Top-of-file disclaimer block

Inserted as a Markdown blockquote immediately under the H1 title, before the metadata fields. Verbatim text:

> **Auto-generated handoff.** Written by the `session-handoff` skill to carry context across multiple sessions on an in-progress worktree, branch, or feature. The newest handoff (by `Last updated`) supersedes older ones for the same work. Handoffs do not survive completion — once the work merges, follow-up commits may invalidate the recorded state, so the `finalize-branch` skill deletes them at merge time.

Three sentences carry distinct messages: what the file is, recency rule, lifecycle rule. The text is fixed (not parametrized).

### Updated document template

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

The `## Retrospective` section is still added later by `session-retrospect` if it runs. No change to that flow.

### 5. Active migration of pre-existing handoffs

#### When migration runs

On any session-touching invocation of the skill (read, list, write), scan `docs/handoffs/` for files that don't match the new format. If any exist, prompt **once per session** to migrate. The user's response (`yes` / `no` / `show` / `details`) is honored for the rest of the session — `no` does not re-prompt.

#### Files in scope

A `.md` file directly under `docs/handoffs/` is a migration candidate if **all** of:

1. Its filename does **not** match `YYYY-MM-DD-HHMMSS-<author>--<slug>.md` (i.e., no `--` after a `YYYY-MM-DD-HHMMSS` prefix).
2. Its git author matches the current `git config user.name`.

The git-author filter is a safety mechanism: the skill never renames a file authored by someone else. Untracked files are treated as authored by the current user.

#### Filename detection (intentionally permissive)

Any of these (and unanticipated variants) qualify, as long as the git-author filter is satisfied:

- `YYYY-MM-DD-HHMMSS-<slug>.md` (the original old format)
- `YYYY-MM-DD-<slug>.md` (date only)
- `YYYY-MM-DD-HHMM-<slug>.md` (no seconds)
- `YYYYMMDD-<anything>.md`
- `<slug>.md` (no date prefix)
- Anything else `.md` in `docs/handoffs/` authored by the current user

#### Field derivation per file

For each candidate, compute the components of the new filename via fallback chains:

1. **Author (raw, for template)** — `git log --diff-filter=A --pretty=format:'%an' -- <path> | head -1` (author of the commit that introduced the file). Fall back to `git config user.name` for untracked files. Slugify for the filename's `<author>` segment.
2. **Date + time** —
   1. Parse a leading `YYYY-MM-DD[-HHMM[SS]]` from the original filename. Pad time to `HHMMSS` with zeros if missing.
   2. `git log --diff-filter=A --pretty=format:'%aI' -- <path> | head -1` → split into date and `HHMMSS` (UTC).
   3. File `mtime` in UTC.
3. **Slug** — strip extension and any recognized leading date prefix, then run the slugifier on the remainder. If empty, prompt the user for a slug for that specific file.

#### Migration prompt

> "Found handoffs that don't match the new naming format:
>
>   Eligible for migration (3 by `Sanjay Nelson`):
>     2026-04-15-foo.md → 2026-04-15-000000-sanjay-nelson--foo.md
>     2026-04-18-bar.md → 2026-04-18-000000-sanjay-nelson--bar.md
>     2026-04-22-baz.md → 2026-04-22-000000-sanjay-nelson--baz.md
>
>   Skipped (2 by `Other Person`)
>
>   References found in 4 file(s):
>     docs/architecture.md:42  → '…see docs/handoffs/2026-04-15-foo.md…'
>     CLAUDE.md:18             → '…the handoff at 2026-04-15-foo.md notes…'
>     plugins/local_conf/scripts/foo.sh:7  → '…cat docs/handoffs/2026-04-18-bar.md…'
>     docs/handoffs/2026-04-22-baz.md:14   → '…follows from 2026-04-18-bar.md…'
>
> Apply renames + reference updates? (`yes` / `no` / `show full diff` / `exclude <line>` / `exclude refs` — rename only)"

`details` (selected before the main prompt response) elaborates on each skipped file's reason.

#### Reference updates

Before any rename, the skill scans the repo for occurrences of each candidate's bare filename (e.g., `2026-04-15-foo.md`).

- **Search tool**: `git grep` to honor `.gitignore` automatically; falls back to `Grep` with manual excludes (`.git/`) if the working dir is not a git repo.
- **Search query**: bare filename, not full path. Catches references in any reasonable form (`docs/handoffs/<file>`, `handoffs/<file>`, `./docs/handoffs/<file>`, or just `<file>` in prose).
- **False-match safety**: each match is shown with three lines of surrounding context before approval; the user can `exclude <line>` per-match or `exclude refs` to skip reference-updates entirely (renames still apply).

#### Application order

On `yes`:

1. **Update file contents first** — apply all reference replacements (old filename → new filename) across the matched files. Includes handoff files in the rename set, since they may cross-reference each other.
2. **Apply renames second** — `git mv` (tracked files, preserves history) or plain `mv` (untracked).
3. **Insert `**Author:**`** in the renamed file's body if absent. Detection: any line matching `^\*\*Author:\*\*` between the H1 and the first `##` heading counts as present, regardless of value (don't silently overwrite a manually-set author). Insertion point: after `**Last updated:**` if present, otherwise immediately before the first `##` heading.
4. **Insert the disclaimer blockquote** if absent. Detection logic:
   - If a verbatim copy of the disclaimer already exists between the H1 and the metadata fields, skip silently.
   - If any *other* blockquote (lines starting with `> `) exists in that region (e.g., a hand-added warning), prompt: `below` (insert disclaimer after the existing blockquote) / `replace` (delete the existing blockquote and insert the disclaimer) / `skip` (leave the file alone).
   - Otherwise insert the disclaimer immediately under the H1, followed by a blank line.

Edits run before renames so each replacement targets the file at its current path. After step 2 succeeds, the file is at its new path and step 3/4 edits operate there.

The skill **does not auto-commit** migration. Renames and edits sit in the working tree for the user to commit at their own cadence (recommended: a single "migrate handoffs to new format" commit).

#### Read tolerance after migration

The skill's read/list logic tolerates **any** filename in `docs/handoffs/`, not just the two enumerated formats. Some users will answer `no` to migration; some external dumps may use the old format. Display logic prefers the new format's parsed components when available; for non-conforming files, the filename is shown as-is and the document body's `**Author:**` (if present) supplies the author.

### Edge cases

- **Multiple authors in a file's history** (file modified by different people) — use the original author from `--diff-filter=A`. Don't reflect the latest editor.
- **`git mv` fails mid-migration** (e.g., destination already exists from a prior failed attempt) — abort that file's migration with a clear error and continue with the rest. Report which renames succeeded.
- **Reference inside a binary file** — `git grep` skips binaries by default; preserve.
- **A reference uses a wrong/old slug** (e.g., somebody hand-edited a filename earlier and broke a reference) — won't be matched; that's correct: only update references that point at files we're renaming.
- **External references** (other repos, Slack messages, browser bookmarks) — out of scope.
- **`docs/handoffs/` is empty or missing** — no migration to do; skip silently.
- **Disclaimer already present verbatim** — skip silently. **Other blockquote present in the same region** — prompt with `below` / `replace` / `skip`. (See step 4 of application order.)
- **`git config user.name` unset** — prompt the user (no silent default to avoid a confusing `unknown` author appearing in slugs).
- **User answers `no` to migration** in session A, then session B starts — the prompt re-fires in B. Per-session, not per-repo.

## Resolved decisions during brainstorm

- **Adapt rather than copy** — the language/tone block from `finalize-branch` doesn't transfer wholesale (handoffs *are* change narratives, *do* aspire to future, etc.). The new section keeps the universal anti-patterns and the clarity-first lead but rewrites surface-specific rules for handoff sections.
- **Drop "Re-narrating user prompts" anti-pattern** — false-positive risk; sometimes a prompt is a meaningful pivot worth recording as a decision.
- **Drop the `≤3 lines` snippet threshold** — arbitrary; "substance of a decision" is the real test.
- **Double-hyphen separator** in filenames between author and slug — single-hyphen is ambiguous for migration parsing.
- **Slugifier is mechanical**, derived from `git config user.name` rather than GitHub login. No network or auth plumbing required.
- **Migration scope is permissive** — any non-new-format file in `docs/handoffs/` authored by the current user is in scope, not just the original old format. Caught the "what about that handoff with the weird date format" case.
- **Migration is prompted, not automatic** — once-per-session prompt; user can defer indefinitely.
- **Migration does not auto-commit** — renames and edits sit in the working tree for user-chosen commit cadence.
- **Disclaimer placement** under H1 as a blockquote — Markdown-idiomatic callout, preserves H1 as the first heading.
- **Disclaimer text is fixed** — not parametrized, no skill-version reference.

## Files affected

- `plugins/local_conf/skills/session-handoff/SKILL.md` — adds the language/tone section, the disclaimer in the template, the `**Author:**` field in the template, the new filename format spec, and the migration logic spec.

No other files in the repo are affected. The `local_conf` plugin version (`plugin.json`) is intentionally not bumped here — bump on completion if shipping cadence calls for it.

## Out of scope

- Changes to `session-retrospect`, the SessionStart hook, or any other handoff consumer.
- Migration of handoffs in repos other than the current cwd.
- A standalone migration command/script — migration is folded into the skill's normal invocation.
- Updating any external references to handoffs (Slack, GitHub issues, etc.).
- Plugin version bump.
