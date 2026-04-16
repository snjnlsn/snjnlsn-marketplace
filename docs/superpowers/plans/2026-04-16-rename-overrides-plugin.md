# Rename `superpowers-override` → `overrides` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rename the `superpowers-override` plugin to `overrides`, broaden its scope framing, clean up inconsistencies, and ignore `.DS_Store` files — all as three focused commits on `main`.

**Architecture:** This is a refactor/rename, not a feature. The plan has three phases, one per commit: (1) mechanical rename of directory + name references, (2) scope-framing rewrite of descriptions/README + agent header comments + version bump, (3) `.gitignore` hygiene. No behavioral code changes; verification is done via grep and file-existence checks, not unit tests.

**Tech Stack:** Claude Code plugin JSON + markdown files only. No build, no test runner, no package manager. Working directory: `/Users/sanjay/Code/claude_stuff/snjnlsn-marketplace`.

**Spec:** `docs/superpowers/specs/2026-04-16-rename-overrides-plugin-design.md`

---

## Phase 1 — Rename (commit 1)

### Task 1: Rename the plugin directory

**Files:**
- Move: `plugins/superpowers-override/` → `plugins/overrides/`

- [ ] **Step 1: Run the directory rename with `git mv`**

From the repo root (`/Users/sanjay/Code/claude_stuff/snjnlsn-marketplace`):

```bash
git mv plugins/superpowers-override plugins/overrides
```

- [ ] **Step 2: Verify the move was recorded as a rename**

```bash
git status
```

Expected: `renamed: plugins/superpowers-override/... -> plugins/overrides/...` lines (one per file inside the directory). No "deleted"/"new file" pairs for the renamed contents.

---

### Task 2: Rename the `hello-overlay` skill directory

**Files:**
- Move: `plugins/overrides/skills/hello-overlay/` → `plugins/overrides/skills/hello-overrides/`

- [ ] **Step 1: Run the skill directory rename**

```bash
git mv plugins/overrides/skills/hello-overlay plugins/overrides/skills/hello-overrides
```

- [ ] **Step 2: Verify**

```bash
git status
ls plugins/overrides/skills/
```

Expected: `git status` shows the rename; `ls` shows `hello-overrides` (and `use-serena-agents`), no `hello-overlay`.

---

### Task 3: Update name references in `marketplace.json`

**Files:**
- Modify: `.claude-plugin/marketplace.json`

- [ ] **Step 1: Read the current file**

Use the Read tool on `/Users/sanjay/Code/claude_stuff/snjnlsn-marketplace/.claude-plugin/marketplace.json`. Confirm it currently reads:

```json
{
  "name": "snjnlsn-marketplace",
  "description": "Personal plugin marketplace",
  "owner": {
    "name": "Sanjay Nelson"
  },
  "plugins": [
    {
      "name": "superpowers-override",
      "description": "Personal skill overlay — private additions and modifications to superpowers",
      "source": "./plugins/superpowers-override"
    }
  ]
}
```

- [ ] **Step 2: Replace the plugin `name` field**

Use the Edit tool. `old_string`: `      "name": "superpowers-override",`  →  `new_string`: `      "name": "overrides",`

- [ ] **Step 3: Replace the plugin `source` field**

Use the Edit tool. `old_string`: `      "source": "./plugins/superpowers-override"`  →  `new_string`: `      "source": "./plugins/overrides"`

**Do NOT change the `description` field yet — that happens in commit 2.**

---

### Task 4: Update name in `plugin.json`

**Files:**
- Modify: `plugins/overrides/.claude-plugin/plugin.json`

- [ ] **Step 1: Replace the `name` field**

Use the Edit tool on `/Users/sanjay/Code/claude_stuff/snjnlsn-marketplace/plugins/overrides/.claude-plugin/plugin.json`.

`old_string`:
```
  "name": "superpowers-override",
```

`new_string`:
```
  "name": "overrides",
```

**Do NOT change the `description` or `version` fields yet — those happen in commit 2.**

---

### Task 5: Update `hello-overrides/SKILL.md`

**Files:**
- Modify: `plugins/overrides/skills/hello-overrides/SKILL.md`

The file currently is:

```markdown
---
name: hello-overlay
description: Smoke test — confirms my-superpowers overlay plugin is loaded
user-invocable: true
---

# Hello Overlay

If you can read this, the my-superpowers personal overlay plugin is installed and working correctly.
```

- [ ] **Step 1: Rewrite the file**

Use the Write tool to replace the file contents with:

```markdown
---
name: hello-overrides
description: Smoke test — confirms overrides overlay plugin is loaded
user-invocable: true
---

# Hello Overrides

If you can read this, the overrides personal overlay plugin is installed and working correctly.
```

- [ ] **Step 2: Verify frontmatter matches directory name**

```bash
head -5 plugins/overrides/skills/hello-overrides/SKILL.md
```

Expected: `name: hello-overrides` is present.

---

### Task 6: Update `use-serena-agents/SKILL.md`

**Files:**
- Modify: `plugins/overrides/skills/use-serena-agents/SKILL.md`

This file has six occurrences of the literal string `superpowers-override` that must become `overrides`. The replacement is mechanical: every occurrence of the token should be replaced, nothing else touched.

- [ ] **Step 1: Replace all `superpowers-override` → `overrides`**

Use the Edit tool with `replace_all: true`.

`old_string`: `superpowers-override`
`new_string`: `overrides`
`replace_all`: `true`

- [ ] **Step 2: Verify**

```bash
grep -n "superpowers-override" plugins/overrides/skills/use-serena-agents/SKILL.md
```

Expected: no output (zero matches).

```bash
grep -n "overrides:code-" plugins/overrides/skills/use-serena-agents/SKILL.md
```

Expected: three matches (one each for `code-explorer`, `code-architect`, `code-reviewer`).

---

### Task 7: Final rename verification

**Goal:** prove no stale references remain before committing.

- [ ] **Step 1: Grep for all three old name tokens**

```bash
grep -rn "superpowers-override\|my-superpowers\|hello-overlay" \
  --exclude-dir=.git \
  --exclude-dir=docs \
  /Users/sanjay/Code/claude_stuff/snjnlsn-marketplace
```

Expected: zero matches. (`docs/` is excluded because the spec intentionally preserves the old names as history.)

- [ ] **Step 2: Confirm the plugin directory exists at the new path**

```bash
ls -la plugins/overrides/.claude-plugin/plugin.json
ls -la plugins/overrides/skills/hello-overrides/SKILL.md
```

Expected: both files exist.

- [ ] **Step 3: If any stale reference is found, fix it before continuing**

If Step 1 returned any output, re-check the file it points to and apply the corresponding rename there. Do not commit until Step 1 returns zero matches.

---

### Task 8: Commit 1

- [ ] **Step 1: Stage and review**

```bash
git status
git diff --cached --stat
```

Expected: changes under `.claude-plugin/marketplace.json`, `plugins/overrides/.claude-plugin/plugin.json`, `plugins/overrides/skills/hello-overrides/SKILL.md`, `plugins/overrides/skills/use-serena-agents/SKILL.md`, plus the directory renames.

- [ ] **Step 2: Stage any remaining changes and commit**

```bash
git add -A
git commit -m "$(cat <<'EOF'
rename: superpowers-override → overrides

Rename the plugin directory, update name references in marketplace.json,
plugin.json, and the SKILL.md files. Also rename the hello-overlay
smoke-test skill to hello-overrides to match.

No behavioral changes — description/framing and README remain unchanged
in this commit and are updated in the next commit.
EOF
)"
```

- [ ] **Step 3: Verify the commit**

```bash
git log -1 --stat
```

Expected: commit lists the moved files and the four modified files.

---

## Phase 2 — Scope framing (commit 2)

### Task 9: Broaden `plugin.json` description and bump version

**Files:**
- Modify: `plugins/overrides/.claude-plugin/plugin.json`

- [ ] **Step 1: Replace the `description` field**

Use the Edit tool on `/Users/sanjay/Code/claude_stuff/snjnlsn-marketplace/plugins/overrides/.claude-plugin/plugin.json`.

`old_string`:
```
  "description": "Personal skill overlay — private additions and modifications to superpowers",
```

`new_string`:
```
  "description": "Personal plugin overrides — customizes and hooks into other Claude Code plugins.",
```

- [ ] **Step 2: Bump the `version` field**

Use the Edit tool.

`old_string`:
```
  "version": "1.0.0",
```

`new_string`:
```
  "version": "1.1.0",
```

- [ ] **Step 3: Verify**

```bash
cat plugins/overrides/.claude-plugin/plugin.json
```

Expected: `name: overrides`, the new description, `version: 1.1.0`.

---

### Task 10: Broaden `marketplace.json` description

**Files:**
- Modify: `.claude-plugin/marketplace.json`

- [ ] **Step 1: Replace the plugin's `description` field**

Use the Edit tool on `/Users/sanjay/Code/claude_stuff/snjnlsn-marketplace/.claude-plugin/marketplace.json`.

`old_string`:
```
      "description": "Personal skill overlay — private additions and modifications to superpowers",
```

`new_string`:
```
      "description": "Personal plugin overrides — customizes and hooks into other Claude Code plugins.",
```

- [ ] **Step 2: Verify**

```bash
cat .claude-plugin/marketplace.json
```

Expected: plugin entry shows `name: overrides`, new description, `source: ./plugins/overrides`.

---

### Task 11: Add override-target header comment to `code-reviewer.md`

**Files:**
- Modify: `plugins/overrides/agents/code-reviewer.md`

Goal: add a one-line HTML comment above the frontmatter so readers can see at a glance what upstream agent this file overrides.

- [ ] **Step 1: Insert the comment at the top of the file**

Use the Edit tool. `old_string` is the existing first line of the file (the opening `---` delimiter followed by the frontmatter); `new_string` prepends the comment and a blank line.

`old_string`:
```
---
name: code-reviewer
```

`new_string`:
```
<!-- Overrides: feature-dev:code-reviewer (adds Serena MCP tools to the allowlist + Serena-first system-prompt instruction) -->

---
name: code-reviewer
```

- [ ] **Step 2: Verify**

```bash
head -3 plugins/overrides/agents/code-reviewer.md
```

Expected: first line is the HTML comment, second line is blank, third line is `---`.

---

### Task 12: Add override-target header comment to `code-explorer.md`

**Files:**
- Modify: `plugins/overrides/agents/code-explorer.md`

- [ ] **Step 1: Insert the comment**

Use the Edit tool.

`old_string`:
```
---
name: code-explorer
```

`new_string`:
```
<!-- Overrides: feature-dev:code-explorer (adds Serena MCP tools to the allowlist + Serena-first system-prompt instruction) -->

---
name: code-explorer
```

- [ ] **Step 2: Verify**

```bash
head -3 plugins/overrides/agents/code-explorer.md
```

Expected: first line is the HTML comment, second blank, third `---`.

---

### Task 13: Add override-target header comment to `code-architect.md`

**Files:**
- Modify: `plugins/overrides/agents/code-architect.md`

- [ ] **Step 1: Insert the comment**

Use the Edit tool.

`old_string`:
```
---
name: code-architect
```

`new_string`:
```
<!-- Overrides: feature-dev:code-architect (adds Serena MCP tools to the allowlist + Serena-first system-prompt instruction) -->

---
name: code-architect
```

- [ ] **Step 2: Verify**

```bash
head -3 plugins/overrides/agents/code-architect.md
```

Expected: first line is the HTML comment, second blank, third `---`.

---

### Task 14: Rewrite the plugin README

**Files:**
- Modify: `plugins/overrides/README.md`

- [ ] **Step 1: Replace the file contents**

Use the Write tool on `/Users/sanjay/Code/claude_stuff/snjnlsn-marketplace/plugins/overrides/README.md` with exactly this content:

````markdown
# overrides

Personal Claude Code plugin that customizes and hooks into other Claude Code plugins. Part of the [`snjnlsn-marketplace`](../../README.md).

## What's inside

| Path | Overrides | Purpose |
|---|---|---|
| `agents/code-reviewer.md` | `feature-dev:code-reviewer` | Adds Serena MCP tools + Serena-first system-prompt instruction |
| `agents/code-explorer.md` | `feature-dev:code-explorer` | Adds Serena MCP tools + Serena-first system-prompt instruction |
| `agents/code-architect.md` | `feature-dev:code-architect` | Adds Serena MCP tools + Serena-first system-prompt instruction |
| `skills/use-serena-agents/` | *standalone* | Routes code-work subagent dispatches to the Serena-enabled variants above |
| `skills/hello-overrides/` | *standalone* | Smoke test — confirms the plugin is loaded |

Empty directories (`hooks/`, `commands/`) are kept as `.gitkeep` placeholders for future additions.

## Adding a new override of an upstream skill/agent

1. Find the upstream file in `~/.claude/plugins/cache/claude-plugins-official/<plugin>/<version>/`
2. Copy it to the mirrored location here (e.g. `agents/<name>.md` or `skills/<name>/SKILL.md`)
3. Add a header comment above the frontmatter documenting the override target:
   ```
   <!-- Overrides: <plugin>:<name> (what's different) -->
   ```
4. Edit as desired, keeping the same `name:` in frontmatter
5. Hot-reloads automatically — no reinstall needed

## Adding a new standalone skill/agent

1. Create `skills/<name>/SKILL.md` or `agents/<name>.md`
2. Add frontmatter: `name:` and `description:` fields
3. Write the content
4. Hot-reloads automatically

## Installation

1. Install the marketplace in Claude Code:
   ```
   /plugin marketplace add @snjnlsn/snjnlsn-marketplace
   ```

2. Install the plugin:
   ```
   /plugin install overrides@snjnlsn-marketplace
   ```

### Migrating from `superpowers-override`

If you previously had this plugin installed under its old name:

1. `/plugin uninstall superpowers-override@snjnlsn-marketplace`
2. `/plugin marketplace update @snjnlsn/snjnlsn-marketplace` (or remove + re-add if the update doesn't pick up the rename)
3. `/plugin install overrides@snjnlsn-marketplace`
4. `/reload-plugins` or restart Claude Code
5. Run `/hello-overrides` as a smoke test — should print the overlay-loaded message.

## After structural changes (new agents, hooks, commands)

Run `/reload-plugins` in Claude Code, or restart.

## Keeping overrides in sync with upstream

Overridden skills and agents do not auto-update when the upstream plugin ships a new version.

To find the currently installed version of an upstream plugin (example: `superpowers`):

```bash
ls ~/.claude/plugins/cache/claude-plugins-official/superpowers/
```

Then diff your override against upstream:

```bash
# Replace 5.0.7 with the version shown above
diff skills/<name>/SKILL.md \
  ~/.claude/plugins/cache/claude-plugins-official/superpowers/5.0.7/skills/<name>/SKILL.md
```
````

- [ ] **Step 2: Verify**

```bash
head -5 plugins/overrides/README.md
grep -c "superpowers-override" plugins/overrides/README.md
```

Expected: first line is `# overrides`. The grep should return `2` — both mentions are inside the "Migrating from `superpowers-override`" section (the heading itself, and the `/plugin uninstall` command), which is intentional.

---

### Task 15: Commit 2

- [ ] **Step 1: Stage and review**

```bash
git status
git diff --cached --stat
```

Expected: changes in `.claude-plugin/marketplace.json`, `plugins/overrides/.claude-plugin/plugin.json`, three agent files, and `plugins/overrides/README.md`.

- [ ] **Step 2: Commit**

```bash
git add -A
git commit -m "$(cat <<'EOF'
chore: broaden scope framing and rewrite README

Reframe the plugin as "plugin overrides" rather than scoped specifically
to superpowers: update descriptions in plugin.json and marketplace.json,
bump plugin version to 1.1.0, rewrite the plugin README around the new
framing (with a migration note for the old name), and add one-line
"Overrides: <upstream>" header comments to the three feature-dev agent
overrides for self-documentation.
EOF
)"
```

- [ ] **Step 3: Verify**

```bash
git log -1 --stat
```

Expected: 6 files changed (marketplace.json, plugin.json, 3 agent files, README.md).

---

## Phase 3 — .gitignore hygiene (commit 3)

### Task 16: Create `.gitignore` and untrack `.DS_Store` files

**Files:**
- Create: `.gitignore`
- Untrack: `.DS_Store`, `plugins/.DS_Store`, `plugins/overrides/.DS_Store`

Context: `git ls-files | grep DS_Store` currently lists three tracked `.DS_Store` files. After rename, the third is at `plugins/overrides/.DS_Store` (moved from `plugins/superpowers-override/.DS_Store` in commit 1).

- [ ] **Step 1: Create `.gitignore`**

Use the Write tool on `/Users/sanjay/Code/claude_stuff/snjnlsn-marketplace/.gitignore` with:

```
.DS_Store
```

- [ ] **Step 2: Untrack the three `.DS_Store` files**

```bash
git rm --cached .DS_Store plugins/.DS_Store plugins/overrides/.DS_Store
```

Expected: `rm '.DS_Store'`, `rm 'plugins/.DS_Store'`, `rm 'plugins/overrides/.DS_Store'`.

- [ ] **Step 3: Verify**

```bash
git ls-files | grep -i DS_Store || echo "no tracked .DS_Store files — good"
cat .gitignore
```

Expected: first command prints `no tracked .DS_Store files — good`; second prints `.DS_Store`.

---

### Task 17: Commit 3

- [ ] **Step 1: Stage and review**

```bash
git status
```

Expected: new file `.gitignore`; three deleted `.DS_Store` files staged.

- [ ] **Step 2: Commit**

```bash
git add -A
git commit -m "$(cat <<'EOF'
chore: ignore .DS_Store

Add .gitignore and untrack the three .DS_Store files that snuck into
the repo. macOS will keep creating them; they just won't be tracked.
EOF
)"
```

- [ ] **Step 3: Verify final state**

```bash
git log --oneline -5
git status
```

Expected: three new commits at the tip (`chore: ignore .DS_Store`, `chore: broaden scope framing...`, `rename: superpowers-override → overrides`). Working tree clean.

---

## Final Verification

### Task 18: End-to-end invariants

Run these checks to confirm the whole refactor landed cleanly.

- [ ] **Step 1: No stale name references anywhere outside `.git/` and `docs/`**

```bash
grep -rn "superpowers-override\|my-superpowers\|hello-overlay" \
  --exclude-dir=.git \
  --exclude-dir=docs \
  /Users/sanjay/Code/claude_stuff/snjnlsn-marketplace
```

Expected: exactly two matches — both inside `plugins/overrides/README.md` under the "Migrating from `superpowers-override`" section (the heading, and the `/plugin uninstall` command). (These are intentional; the migration instructions reference the old name so users can uninstall it.)

If any other matches appear, they are bugs — fix them in a follow-up commit.

- [ ] **Step 2: marketplace.json source path resolves**

```bash
test -d "$(jq -r '.plugins[0].source' .claude-plugin/marketplace.json)" && echo "source path OK" || echo "BROKEN"
```

Expected: `source path OK`.

- [ ] **Step 3: Frontmatter sanity on all skill/agent files**

```bash
for f in plugins/overrides/skills/*/SKILL.md plugins/overrides/agents/*.md; do
  head -10 "$f" | grep -q "^name:" || echo "MISSING name: in $f"
  head -10 "$f" | grep -q "^description:" || echo "MISSING description: in $f"
done
echo "frontmatter check done"
```

Expected: only `frontmatter check done` printed — no `MISSING` lines.

- [ ] **Step 4: Skill directory name matches frontmatter `name:`**

```bash
for d in plugins/overrides/skills/*/; do
  skill_dir=$(basename "$d")
  skill_name=$(grep -m1 "^name:" "$d/SKILL.md" | awk '{print $2}')
  [ "$skill_dir" = "$skill_name" ] || echo "MISMATCH: dir=$skill_dir name=$skill_name"
done
echo "skill name check done"
```

Expected: only `skill name check done` — no `MISMATCH` lines.

- [ ] **Step 5: No tracked `.DS_Store` files**

```bash
git ls-files | grep -i DS_Store && echo "STILL TRACKED — BAD" || echo "none tracked — good"
```

Expected: `none tracked — good`.

- [ ] **Step 6: Report to user**

Summarize to the user:
- Three commits landed cleanly.
- Verification steps all passed.
- **User action still required:** run the migration steps in `plugins/overrides/README.md` (uninstall old plugin, update marketplace, install new plugin, `/reload-plugins`, run `/hello-overrides`).
