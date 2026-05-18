# Handoff Isolation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move session-continuity handoff storage out of `.claude/` and add a hardcoded LLM-facing disclaimer to every new handoff.

**Architecture:** Mechanical substring swap of the storage path (`.claude/handoffs/` → `.session-continuity/handoffs/`) across 7 files in the `session-continuity` plugin, plus a template rewrite in `session-handoff/SKILL.md` that replaces the existing visible blockquote disclaimer with an HTML-comment disclaimer placed above the H1. No migration code, no backward compatibility — change applies going forward.

**Tech Stack:** Bash scripts, Markdown SKILL files. No test framework — verification is via `grep` (path absence/presence) and manual smoke tests of the setup script and a newly created handoff.

**Spec:** `docs/superpowers/specs/2026-05-18-handoff-isolation-design.md`

---

## File map

Files modified (no new files):

- `plugins/session-continuity/scripts/setup-handoffs.sh` — `HANDOFF_DIR` constant, docstring/comment header, seeded README heading + body.
- `plugins/session-continuity/scripts/handoff-list-recent.sh` — `HANDOFF_DIR` constant, header comment.
- `plugins/session-continuity/skills/session-handoff/SKILL.md` — bulk path swap + template rewrite (blockquote → HTML comment) + migration logic update + edge-case bullet + read-path tolerance note.
- `plugins/session-continuity/skills/read-branch-handoffs/SKILL.md` — bulk path swap only.
- `plugins/session-continuity/skills/finalize-branch/SKILL.md` — bulk path swap only.
- `plugins/session-continuity/skills/handle-callouts/SKILL.md` — bulk path swap only.
- `plugins/session-continuity/README.md` — bulk path swap only.

Verification commands referenced throughout:

```bash
# All-references grep (expected zero after Task 3):
grep -rn '\.claude/handoffs' plugins/session-continuity
```

---

### Task 1: Update `setup-handoffs.sh`

**Files:**
- Modify: `plugins/session-continuity/scripts/setup-handoffs.sh`

- [ ] **Step 1: Open the script and review current state**

Read the full file. Current `HANDOFF_DIR=".claude/handoffs"` (line 15). Docstring/comment header at lines 4–13 mentions `.claude/handoffs/` in the description. Seeded README's heading on line 26 reads `# .claude/handoffs/`.

- [ ] **Step 2: Edit the constant + docstring + seeded README heading**

Apply these three edits in one pass:

1. Line 6: `# Creates `.claude/handoffs/` at the current working directory (intended to be` → `# Creates `.session-continuity/handoffs/` at the current working directory (intended to be`
2. Line 15: `HANDOFF_DIR=".claude/handoffs"` → `HANDOFF_DIR=".session-continuity/handoffs"`
3. Line 26 (inside the seeded README heredoc): `# .claude/handoffs/` → `# .session-continuity/handoffs/`

No other lines change. The script's logic (mkdir + idempotent README check + echo confirmation) stays identical.

- [ ] **Step 3: Verify the script still parses and runs cleanly in a throwaway dir**

```bash
bash -n plugins/session-continuity/scripts/setup-handoffs.sh
# (no output = OK)

# Smoke test in a tmp dir:
TMPDIR_TEST=$(mktemp -d) && (cd "$TMPDIR_TEST" && bash "$OLDPWD/plugins/session-continuity/scripts/setup-handoffs.sh")
# Expected output:
#   Created .session-continuity/handoffs/ and .session-continuity/handoffs/README.md.

# Inspect the seeded README's heading:
head -1 "$TMPDIR_TEST/.session-continuity/handoffs/README.md"
# Expected: # .session-continuity/handoffs/

# Second invocation must no-op:
(cd "$TMPDIR_TEST" && bash "$OLDPWD/plugins/session-continuity/scripts/setup-handoffs.sh")
# Expected output:
#   Already present: .session-continuity/handoffs/README.md (left intact).

rm -rf "$TMPDIR_TEST"
```

- [ ] **Step 4: Commit**

```bash
git add plugins/session-continuity/scripts/setup-handoffs.sh
git commit -m "setup-handoffs.sh: move handoff dir to .session-continuity/handoffs/"
```

---

### Task 2: Update `handoff-list-recent.sh`

**Files:**
- Modify: `plugins/session-continuity/scripts/handoff-list-recent.sh`

- [ ] **Step 1: Open the script and review current state**

Read the full file. Current `HANDOFF_DIR=".claude/handoffs"` (line 13). Header comment at line 5 reads `# Lists up to MAX most recent files in $cwd/.claude/handoffs/ sorted by mtime,`.

- [ ] **Step 2: Edit the constant + header comment**

1. Line 5: `# Lists up to MAX most recent files in $cwd/.claude/handoffs/ sorted by mtime,` → `# Lists up to MAX most recent files in $cwd/.session-continuity/handoffs/ sorted by mtime,`
2. Line 13: `HANDOFF_DIR=".claude/handoffs"` → `HANDOFF_DIR=".session-continuity/handoffs"`

The two `printf` calls (lines 43 and 45) use `$HANDOFF_DIR` interpolated — they pick up the new value automatically, no edits needed there.

- [ ] **Step 3: Verify the script parses**

```bash
bash -n plugins/session-continuity/scripts/handoff-list-recent.sh
# (no output = OK)
```

- [ ] **Step 4: Verify no stale string in the script body**

```bash
grep -n '\.claude/handoffs' plugins/session-continuity/scripts/handoff-list-recent.sh
# Expected: (no output)
```

- [ ] **Step 5: Commit**

```bash
git add plugins/session-continuity/scripts/handoff-list-recent.sh
git commit -m "handoff-list-recent.sh: move handoff dir to .session-continuity/handoffs/"
```

---

### Task 3: Bulk path swap across markdown files

Applies the substring swap `.claude/handoffs` → `.session-continuity/handoffs` across all SKILL.md files and the plugin README. This is purely mechanical — no semantic changes.

**Files:**
- Modify: `plugins/session-continuity/skills/session-handoff/SKILL.md`
- Modify: `plugins/session-continuity/skills/read-branch-handoffs/SKILL.md`
- Modify: `plugins/session-continuity/skills/finalize-branch/SKILL.md`
- Modify: `plugins/session-continuity/skills/handle-callouts/SKILL.md`
- Modify: `plugins/session-continuity/README.md`

- [ ] **Step 1: Pre-edit grep — record baseline count**

```bash
grep -rn '\.claude/handoffs' plugins/session-continuity/skills plugins/session-continuity/README.md | wc -l
# Expected baseline: 47 matches (the markdown references; the 5 script references are already done in Tasks 1+2).
```

If the count is materially different, stop and investigate before bulk-replacing — something has shifted.

- [ ] **Step 2: Apply the substring swap**

Use `sed` in-place across the five files:

```bash
# macOS sed requires '' after -i; on Linux drop the ''.
for f in \
  plugins/session-continuity/skills/session-handoff/SKILL.md \
  plugins/session-continuity/skills/read-branch-handoffs/SKILL.md \
  plugins/session-continuity/skills/finalize-branch/SKILL.md \
  plugins/session-continuity/skills/handle-callouts/SKILL.md \
  plugins/session-continuity/README.md; do
  sed -i '' 's|\.claude/handoffs|.session-continuity/handoffs|g' "$f"
done
```

- [ ] **Step 3: Verify zero stale references remain across the whole plugin tree**

```bash
grep -rn '\.claude/handoffs' plugins/session-continuity
# Expected: (no output)
```

- [ ] **Step 4: Verify the new path appears in each file**

```bash
for f in \
  plugins/session-continuity/skills/session-handoff/SKILL.md \
  plugins/session-continuity/skills/read-branch-handoffs/SKILL.md \
  plugins/session-continuity/skills/finalize-branch/SKILL.md \
  plugins/session-continuity/skills/handle-callouts/SKILL.md \
  plugins/session-continuity/README.md; do
  count=$(grep -c '\.session-continuity/handoffs' "$f")
  echo "$count	$f"
done
# Expected: every line shows a positive count (no zeros).
```

- [ ] **Step 5: Spot-check the session-handoff SKILL.md frontmatter description**

```bash
sed -n '3p' plugins/session-continuity/skills/session-handoff/SKILL.md
# Expected first ~80 chars:
#   description: Maintain a per-session handoff document under .session-continuity/handoffs/. Use when the user says ...
```

Frontmatter descriptions are surfaced by the harness for skill routing; the path swap there is the only user-visible signal that the storage location has moved.

- [ ] **Step 6: Commit**

```bash
git add plugins/session-continuity/skills plugins/session-continuity/README.md
git commit -m "session-continuity: swap handoff path .claude/handoffs/ → .session-continuity/handoffs/"
```

---

### Task 4: Replace the template's blockquote disclaimer with HTML-comment disclaimer

**Files:**
- Modify: `plugins/session-continuity/skills/session-handoff/SKILL.md` (template section, lines ~46–70)

- [ ] **Step 1: Open the file and locate the template**

Read the `## Document template` section (line 46 onward). The current template, inside its ```markdown``` fence, looks like this:

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

- [ ] **Step 2: Rewrite the template body inside the fence**

Replace the template (between the ```markdown ... ``` fences in the `## Document template` section) with this exact content:

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

Key differences from the current template:
1. HTML comment block added at the very top, before the H1.
2. `> **Auto-generated handoff.** ...` blockquote removed (its content is absorbed into the HTML comment's second sentence).
3. No other changes — metadata fields, sections, placeholders stay identical.

- [ ] **Step 3: Verify the file**

```bash
# Spot-check: the visible blockquote should be gone from the template:
grep -n '^> \*\*Auto-generated handoff' plugins/session-continuity/skills/session-handoff/SKILL.md
# Expected: (no output)

# Spot-check: HTML comment marker present in the template fence:
grep -n 'SESSION-CONTINUITY HANDOFF' plugins/session-continuity/skills/session-handoff/SKILL.md
# Expected: at least one line citing the marker (inside the template fence).
```

- [ ] **Step 4: Commit**

```bash
git add plugins/session-continuity/skills/session-handoff/SKILL.md
git commit -m "session-handoff: replace template blockquote with HTML-comment disclaimer"
```

---

### Task 5: Update create-flow wording + migration logic to reference the HTML comment

**Files:**
- Modify: `plugins/session-continuity/skills/session-handoff/SKILL.md` (create-flow step, migration "Insert disclaimer" step, edge-case bullet)

- [ ] **Step 1: Update the create-flow's template-writing step**

Locate the `### Lazy-create on first write` section, step 7. Current line ~134 reads:

```
7. Use Write to create the file with the template (including the disclaimer blockquote and `**Author:**` field), with the first content already in the right section.
```

Change `disclaimer blockquote` → `disclaimer comment`:

```
7. Use Write to create the file with the template (including the disclaimer comment and `**Author:**` field), with the first content already in the right section.
```

- [ ] **Step 2: Update the migration "Insert the disclaimer blockquote" step**

Locate `### Application order` section, step 4 (current lines ~217–220). Replace the entire step 4 with:

```
4. **Insert the disclaimer comment** if absent. Detection logic:
   - If a verbatim copy of the HTML disclaimer comment already exists at the top of the file (before the H1), skip the insertion silently. (Still process the legacy-blockquote cleanup below.)
   - If an unrecognized HTML comment exists in that position, prompt: `replace` (delete the existing comment and insert the disclaimer) / `keep` (insert the disclaimer below the existing comment) / `skip` (leave the file alone).
   - Otherwise insert the disclaimer at the very top of the file, followed by a blank line, then the H1.
5. **Delete the legacy `> **Auto-generated handoff.**` blockquote** if present anywhere between the H1 and the first metadata field. Its content is fully absorbed by the new HTML comment, so deletion is silent (no prompt).
```

This converts the old step 4 (insert blockquote) into a step that handles the new HTML comment, and adds a new step 5 (delete legacy blockquote) so a migrated file ends up with the new disclaimer above the H1 and no orphan blockquote below.

The current `Application order` section has only steps 1–4 (no further numbered steps), so no renumbering of later items is needed.

Also update the immediately-following clarifying paragraph (current line ~222):

```
Edits run before renames so each replacement targets the file at its current path. After step 2, the file is at its new path and steps 3/4 operate there.
```

→

```
Edits run before renames so each replacement targets the file at its current path. After step 2, the file is at its new path and steps 3/4/5 operate there.
```

- [ ] **Step 3: Update the edge-case bullet about the disclaimer**

Locate the `### Edge cases` section. Current line ~242 reads:

```
- **Disclaimer already present verbatim** — skip silently. **Other blockquote present in the same region** — prompt with `below` / `replace` / `skip`.
```

Replace with:

```
- **HTML disclaimer comment already present verbatim** — skip silently. **Other HTML comment present at the top of the file** — prompt with `replace` / `keep` / `skip`. **Legacy `> **Auto-generated handoff.**` blockquote present** — silently delete (content fully absorbed by the new HTML comment).
```

- [ ] **Step 4: Verify the section reads coherently**

Read the entire `### Application order` and `### Edge cases` sections end-to-end. Confirm:
- Step numbering is consecutive in `Application order`.
- The migration flow's "insert disclaimer at top of file (before H1)" placement matches the template change from Task 4.
- The edge case covers: present-verbatim, other-comment-present, legacy-blockquote-present.

- [ ] **Step 5: Verify no leftover references to "disclaimer blockquote"**

```bash
grep -n 'disclaimer blockquote' plugins/session-continuity/skills/session-handoff/SKILL.md
# Expected: (no output)
```

- [ ] **Step 6: Commit**

```bash
git add plugins/session-continuity/skills/session-handoff/SKILL.md
git commit -m "session-handoff: update migration + create flow to insert HTML disclaimer comment"
```

---

### Task 6: Add HTML-comment metadata note to the read path

**Files:**
- Modify: `plugins/session-continuity/skills/session-handoff/SKILL.md` (read-existing-handoff section)

- [ ] **Step 1: Locate the read section**

Find the `### Read existing handoff (for context)` section (current line ~116–118). It currently reads:

```
### Read existing handoff (for context)

Use the Read tool on the requested file (or the most recent file in `.session-continuity/handoffs/` if unspecified). Summarize relevance to the current session. If the user says to adopt it as the working handoff, do so.
```

(Note: path is `.session-continuity/handoffs/` post-Task 3.)

- [ ] **Step 2: Append the metadata-not-content note**

Add a new paragraph after the existing one:

```
The handoff's HTML disclaimer comment (the `<!-- SESSION-CONTINUITY HANDOFF ... -->` block at the top) is file-format metadata, not content. When summarizing the handoff, skip it; do not echo its rules back as substance of the session's work. When copying handoff content into the current context, the block may be retained verbatim — it is short and self-explanatory — but it is not itself something to summarize or act on.
```

The resulting section should be:

```
### Read existing handoff (for context)

Use the Read tool on the requested file (or the most recent file in `.session-continuity/handoffs/` if unspecified). Summarize relevance to the current session. If the user says to adopt it as the working handoff, do so.

The handoff's HTML disclaimer comment (the `<!-- SESSION-CONTINUITY HANDOFF ... -->` block at the top) is file-format metadata, not content. When summarizing the handoff, skip it; do not echo its rules back as substance of the session's work. When copying handoff content into the current context, the block may be retained verbatim — it is short and self-explanatory — but it is not itself something to summarize or act on.
```

- [ ] **Step 3: Commit**

```bash
git add plugins/session-continuity/skills/session-handoff/SKILL.md
git commit -m "session-handoff: read path treats HTML disclaimer comment as metadata"
```

---

### Task 7: Final integration verification

No code changes — this task only runs verification commands and inspects results.

- [ ] **Step 1: Full-tree path grep — must be zero**

```bash
grep -rn '\.claude/handoffs' plugins/session-continuity
# Expected: (no output)
```

If any matches appear, identify which task missed them and fix in a follow-up commit.

- [ ] **Step 2: Setup-script smoke test in a fresh dir**

```bash
TMPDIR_TEST=$(mktemp -d)
(cd "$TMPDIR_TEST" && bash "$OLDPWD/plugins/session-continuity/scripts/setup-handoffs.sh")
# Expected: 'Created .session-continuity/handoffs/ and .session-continuity/handoffs/README.md.'

ls -la "$TMPDIR_TEST/.session-continuity/handoffs/"
# Expected: README.md present.

head -1 "$TMPDIR_TEST/.session-continuity/handoffs/README.md"
# Expected: # .session-continuity/handoffs/

# Re-run to confirm idempotence:
(cd "$TMPDIR_TEST" && bash "$OLDPWD/plugins/session-continuity/scripts/setup-handoffs.sh")
# Expected: 'Already present: .session-continuity/handoffs/README.md (left intact).'

rm -rf "$TMPDIR_TEST"
```

- [ ] **Step 3: Manual handoff-template readback**

Read the `## Document template` section of `plugins/session-continuity/skills/session-handoff/SKILL.md`. Visually confirm:
- The HTML comment block is present at the top of the template's example body, before the H1.
- The `> **Auto-generated handoff.**` blockquote is gone.
- The metadata fields and section headings are unchanged.

- [ ] **Step 4: Confirm the disclaimer text is byte-identical between the spec and the SKILL.md template**

```bash
diff <(sed -n '/^<!--$/,/^-->$/p' docs/superpowers/specs/2026-05-18-handoff-isolation-design.md | head -20) \
     <(sed -n '/^<!--$/,/^-->$/p' plugins/session-continuity/skills/session-handoff/SKILL.md | head -20)
# Expected: (no output — identical)
```

If the two diverge, treat the spec as the source of truth and update the SKILL.md template to match.

- [ ] **Step 5: Final commit (only if Step 4 surfaced a divergence)**

```bash
git add plugins/session-continuity/skills/session-handoff/SKILL.md
git commit -m "session-handoff: align template disclaimer with spec"
```

If Step 4 was clean, no commit needed — the plan is complete and ready for PR.
