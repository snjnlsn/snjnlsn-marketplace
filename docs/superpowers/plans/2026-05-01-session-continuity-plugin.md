# Extract `session-continuity` Plugin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extract the per-session/per-branch documentation lifecycle (four skills + two scripts + the SessionStart context-injection + the Stop wrap-up nudge) out of the `local_conf` plugin into a new standalone `session-continuity` plugin in the same marketplace.

**Architecture:** Refactor/move only — no behavioral changes. Five sequential commits on `main`: (1) scaffold the new plugin's manifest/hooks/README; (2) `git mv` the four skills + two scripts and apply two in-content fixups (stop-nudge cache namespace + a documentary path example); (3) trim `local_conf`'s `hooks.json`, `plugin.json`, and `README.md`; (4) update the marketplace catalog (`marketplace.json` + root `README.md`); (5) final straggler sweep + smoke test. Verification is by JSON parsing, `grep` checks, shell-syntax checks, executable-bit checks, and a `/reload-plugins` smoke test — there are no automated unit tests for plugin manifest content.

**Tech Stack:** Claude Code plugin JSON + Markdown + Bash. No build, no test runner. Working directory: `/Users/sanjay/Code/claude_stuff/snjnlsn-marketplace`.

**Spec:** `docs/superpowers/specs/2026-05-01-session-continuity-plugin-design.md`

**File inventory:**

- *New files:* `plugins/session-continuity/.claude-plugin/plugin.json`, `plugins/session-continuity/hooks/hooks.json`, `plugins/session-continuity/README.md`.
- *Renamed (`git mv`):* four `SKILL.md` files (`session-handoff`, `session-retrospect`, `handle-callouts`, `finalize-branch`) and two scripts (`handoff-list-recent.sh`, `stop-nudge.sh`) — all from `plugins/local_conf/...` to `plugins/session-continuity/...`.
- *Modified:* `plugins/session-continuity/scripts/stop-nudge.sh` (cache path), `plugins/session-continuity/skills/session-handoff/SKILL.md` (one documentary example line), `plugins/local_conf/hooks/hooks.json` (drop two hook entries), `plugins/local_conf/.claude-plugin/plugin.json` (version bump to 2.0.0), `plugins/local_conf/README.md` (drop session-workflow rows), `.claude-plugin/marketplace.json` (append entry), `README.md` (root — table updates).

---

## Phase 1 — Scaffold the new plugin (commit 1)

The new plugin's directory and manifest exist before any moves, so the `git mv` operations in Phase 2 land into an already-real plugin. Hooks reference scripts that won't exist until Phase 2; that's a transient mid-PR state, fine for an atomic-move PR.

### Task 1: Create the `session-continuity` plugin manifest

**Files:**
- Create: `plugins/session-continuity/.claude-plugin/plugin.json`

- [ ] **Step 1: Create the manifest file**

Write the file at `/Users/sanjay/Code/claude_stuff/snjnlsn-marketplace/plugins/session-continuity/.claude-plugin/plugin.json`:

```json
{
  "name": "session-continuity",
  "description": "Per-session and per-branch documentation lifecycle: handoffs, callouts, retrospects, branch finalization.",
  "version": "1.0.0",
  "author": {
    "name": "Sanjay Nelson"
  }
}
```

- [ ] **Step 2: Verify the JSON is valid and the file resolves**

```bash
python3 -c "import json; print(json.load(open('plugins/session-continuity/.claude-plugin/plugin.json'))['name'])"
```

Expected output: `session-continuity`

---

### Task 2: Create the `session-continuity` hooks file

**Files:**
- Create: `plugins/session-continuity/hooks/hooks.json`

- [ ] **Step 1: Write the hooks file**

Write the file at `/Users/sanjay/Code/claude_stuff/snjnlsn-marketplace/plugins/session-continuity/hooks/hooks.json`:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/handoff-list-recent.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/stop-nudge.sh"
          }
        ]
      }
    ]
  }
}
```

- [ ] **Step 2: Verify the JSON is valid**

```bash
python3 -c "import json; d = json.load(open('plugins/session-continuity/hooks/hooks.json')); print(list(d['hooks'].keys()))"
```

Expected output: `['SessionStart', 'Stop']`

---

### Task 3: Create the `session-continuity` README

**Files:**
- Create: `plugins/session-continuity/README.md`

- [ ] **Step 1: Write the README**

Write the file at `/Users/sanjay/Code/claude_stuff/snjnlsn-marketplace/plugins/session-continuity/README.md`:

```markdown
# session-continuity

Personal Claude Code plugin holding the per-session and per-branch documentation lifecycle: handoffs that carry context across sessions, callouts that capture findings inline, retrospects that reflect on the session, and a finalize step that harvests it all into permanent docs at branch end. Part of the [`snjnlsn-marketplace`](../../README.md).

## What's inside

### Skills

| Path | Purpose |
|---|---|
| `skills/session-handoff/` | Maintains a per-session handoff document under `docs/handoffs/`. Author-tagged filenames support multiple users sharing one repo; tone guidance keeps prose plain and disclaimer-marked; includes a one-shot migration path for legacy single-user filenames. |
| `skills/session-retrospect/` | End-of-session reflection. After explicit approval: narrative appended to the current handoff; concrete edits applied directly to the affected files (skills, `CLAUDE.md`, settings, hooks). |
| `skills/handle-callouts/` | Capture session findings as callouts (discoveries, decisions, caveats, gotchas, lessons learned, known issues, complexities, edge cases) in the current session's handoff. Triggers on explicit phrases or proactive recognition. |
| `skills/finalize-branch/` | End-of-branch pipeline — audits and updates inline code docs and project docs (with language/tone guidance), removes the branch's handoffs, produces one final commit; supports cancel-and-resume via stash. |

### Hooks

| Event | Behavior |
|---|---|
| `SessionStart` | Runs `scripts/handoff-list-recent.sh` — lists the most recent handoffs in `docs/handoffs/` and points the session at the `session-handoff` / `session-retrospect` skills. |
| `Stop` | Runs `scripts/stop-nudge.sh` — emits a wrap-up reminder when the session has run long enough, rate-limited per session. |

### Scripts

| Script | Used by | Purpose |
|---|---|---|
| `scripts/handoff-list-recent.sh` | `SessionStart` | List recent handoffs for context injection. |
| `scripts/stop-nudge.sh` | `Stop` | Rate-limited wrap-up reminder. |

## Installation

1. Install the marketplace in Claude Code:
   ```
   /plugin marketplace add @snjnlsn/snjnlsn-marketplace
   ```

2. Install the plugin:
   ```
   /plugin install session-continuity@snjnlsn-marketplace
   ```

## After structural changes

Run `/reload-plugins` in Claude Code, or restart.
```

- [ ] **Step 2: Verify the file was written**

```bash
head -3 plugins/session-continuity/README.md
```

Expected first line: `# session-continuity`

---

### Task 4: Commit the scaffold

- [ ] **Step 1: Stage the three new files**

```bash
git add plugins/session-continuity/.claude-plugin/plugin.json plugins/session-continuity/hooks/hooks.json plugins/session-continuity/README.md
```

- [ ] **Step 2: Confirm staged contents**

```bash
git status --short
```

Expected: three lines starting with `A ` for the three new files. No other changes staged.

- [ ] **Step 3: Commit**

```bash
git commit -m "$(cat <<'EOF'
Scaffold session-continuity plugin

Add the new plugin's manifest, hooks file, and README. Skills and
scripts move into it in the next commit. Hook entries reference
script paths that don't exist yet — transient state until the
move commit lands.
EOF
)"
```

Expected: commit succeeds, no pre-commit hook failures. (If hooks fail, fix the underlying issue and create a NEW commit — never `--amend`.)

---

## Phase 2 — Move skills and scripts (commit 2)

Six `git mv` operations plus two small in-content edits. After this commit, all moved files live at their new location and the new plugin's hooks resolve to existing scripts.

### Task 5: Move the four skill directories

**Files:**
- Move: `plugins/local_conf/skills/session-handoff/` → `plugins/session-continuity/skills/session-handoff/`
- Move: `plugins/local_conf/skills/session-retrospect/` → `plugins/session-continuity/skills/session-retrospect/`
- Move: `plugins/local_conf/skills/handle-callouts/` → `plugins/session-continuity/skills/handle-callouts/`
- Move: `plugins/local_conf/skills/finalize-branch/` → `plugins/session-continuity/skills/finalize-branch/`

- [ ] **Step 1: Run the four `git mv` commands**

```bash
git mv plugins/local_conf/skills/session-handoff plugins/session-continuity/skills/session-handoff
git mv plugins/local_conf/skills/session-retrospect plugins/session-continuity/skills/session-retrospect
git mv plugins/local_conf/skills/handle-callouts plugins/session-continuity/skills/handle-callouts
git mv plugins/local_conf/skills/finalize-branch plugins/session-continuity/skills/finalize-branch
```

- [ ] **Step 2: Verify all four moves were recorded as renames**

```bash
git status --short
```

Expected: four lines starting with `R ` (rename), one per `SKILL.md`, of the form
`R  plugins/local_conf/skills/<name>/SKILL.md -> plugins/session-continuity/skills/<name>/SKILL.md`.
No `D`/`A` pairs for the same content.

- [ ] **Step 3: Verify the source directory is empty**

```bash
ls plugins/local_conf/skills/ 2>/dev/null
```

Expected: empty output (the four subdirectories are gone).

---

### Task 6: Move the two scripts

**Files:**
- Move: `plugins/local_conf/scripts/handoff-list-recent.sh` → `plugins/session-continuity/scripts/handoff-list-recent.sh`
- Move: `plugins/local_conf/scripts/stop-nudge.sh` → `plugins/session-continuity/scripts/stop-nudge.sh`

- [ ] **Step 1: Run both `git mv` commands**

```bash
git mv plugins/local_conf/scripts/handoff-list-recent.sh plugins/session-continuity/scripts/handoff-list-recent.sh
git mv plugins/local_conf/scripts/stop-nudge.sh plugins/session-continuity/scripts/stop-nudge.sh
```

- [ ] **Step 2: Verify renames and that `sed-guard.sh` stays put**

```bash
git status --short
ls plugins/local_conf/scripts/
ls plugins/session-continuity/scripts/
```

Expected:
- Two new `R ` lines in `git status` for the moved scripts.
- `plugins/local_conf/scripts/` contains exactly `sed-guard.sh`.
- `plugins/session-continuity/scripts/` contains exactly `handoff-list-recent.sh` and `stop-nudge.sh`.

- [ ] **Step 3: Verify the executable bits were preserved**

```bash
ls -l plugins/session-continuity/scripts/
```

Expected: both `.sh` files show executable bits in the mode column (e.g., `-rwxr-xr-x`).

If they're not executable (a possibility on some filesystems), restore with:
```bash
chmod +x plugins/session-continuity/scripts/handoff-list-recent.sh plugins/session-continuity/scripts/stop-nudge.sh
git update-index --chmod=+x plugins/session-continuity/scripts/handoff-list-recent.sh plugins/session-continuity/scripts/stop-nudge.sh
```

---

### Task 7: Update `stop-nudge.sh` cache namespace

**Files:**
- Modify: `plugins/session-continuity/scripts/stop-nudge.sh:17`

- [ ] **Step 1: Apply the one-line edit**

In `/Users/sanjay/Code/claude_stuff/snjnlsn-marketplace/plugins/session-continuity/scripts/stop-nudge.sh`, replace:

```
CACHE_DIR="${HOME}/.cache/local_conf/stop-nudge"
```

with:

```
CACHE_DIR="${HOME}/.cache/session-continuity/stop-nudge"
```

(This is line 17 of the file. Use the Edit tool with the exact `old_string`/`new_string` above.)

- [ ] **Step 2: Verify the edit**

```bash
grep -n CACHE_DIR plugins/session-continuity/scripts/stop-nudge.sh
```

Expected: `17:CACHE_DIR="${HOME}/.cache/session-continuity/stop-nudge"`

- [ ] **Step 3: Verify shell syntax is still valid**

```bash
bash -n plugins/session-continuity/scripts/stop-nudge.sh && echo OK
```

Expected: `OK`

- [ ] **Step 4: Confirm no other `local_conf` references remain in the script**

```bash
grep -n local_conf plugins/session-continuity/scripts/stop-nudge.sh || echo NONE
```

Expected: `NONE`

---

### Task 8: Fix the documentary `foo.sh` example in `session-handoff`

**Files:**
- Modify: `plugins/session-continuity/skills/session-handoff/SKILL.md:202`

This line is part of a mock prompt block illustrating "what the skill might surface to the user when migrating handoff filenames." It lists four example file references; one of them currently points at a `local_conf`-relative path that no longer exists in this plugin. Generalize it.

- [ ] **Step 1: Apply the edit**

In `/Users/sanjay/Code/claude_stuff/snjnlsn-marketplace/plugins/session-continuity/skills/session-handoff/SKILL.md`, replace:

```
    plugins/local_conf/scripts/foo.sh:7  → '…cat docs/handoffs/2026-04-18-bar.md…'
```

with:

```
    bin/release-notes.sh:7   → '…cat docs/handoffs/2026-04-18-bar.md…'
```

(The space-padding before the `→` keeps column alignment with the surrounding lines. Use the Edit tool with the exact `old_string`/`new_string` above.)

- [ ] **Step 2: Verify the edit landed and the surrounding block still reads cleanly**

```bash
sed -n '199,204p' plugins/session-continuity/skills/session-handoff/SKILL.md
```

Expected output:
```
  References found in 4 file(s):
    docs/architecture.md:42  → '…see docs/handoffs/2026-04-15-foo.md…'
    CLAUDE.md:18             → '…the handoff at 2026-04-15-foo.md notes…'
    bin/release-notes.sh:7   → '…cat docs/handoffs/2026-04-18-bar.md…'
    docs/handoffs/2026-04-22-baz.md:14   → '…follows from 2026-04-18-bar.md…'
```

- [ ] **Step 3: Confirm no stray `local_conf` strings remain in the moved skill**

```bash
grep -n local_conf plugins/session-continuity/skills/session-handoff/SKILL.md || echo NONE
```

Expected: `NONE`

---

### Task 9: Commit the moves and fixups

- [ ] **Step 1: Stage all moves and edits**

```bash
git add -A plugins/local_conf/skills/ plugins/local_conf/scripts/ plugins/session-continuity/skills/ plugins/session-continuity/scripts/
```

(Using directory-scoped `git add -A` here rather than `git add .` to avoid sweeping in unrelated working-tree changes. The moves and edits are confined to these four directory trees.)

- [ ] **Step 2: Confirm staged contents**

```bash
git status --short
```

Expected: six `R ` rename lines (four skills + two scripts) plus `M ` modify lines for `plugins/session-continuity/skills/session-handoff/SKILL.md` and `plugins/session-continuity/scripts/stop-nudge.sh`. (Whether a renamed-with-edits file shows as `R ` with content changes or as `RM` depends on git version; both are correct.)

- [ ] **Step 3: Commit**

```bash
git commit -m "$(cat <<'EOF'
Move session-workflow skills and scripts into session-continuity

Relocate the four documentation-lifecycle skills (session-handoff,
session-retrospect, handle-callouts, finalize-branch) and the two
supporting scripts (handoff-list-recent.sh, stop-nudge.sh) from
local_conf into the new session-continuity plugin.

Two in-content fixups: stop-nudge.sh's cache namespace follows the
script to its new owner (~/.cache/session-continuity/stop-nudge);
session-handoff's documentary path example is generalized away
from the old plugin path.

Skills cross-reference each other by bare name, which Claude
resolves across plugins, so no other in-skill rewrites are needed.
EOF
)"
```

---

## Phase 3 — Trim `local_conf` (commit 3)

`local_conf` is now Serena/sed plumbing only. Strip the references it no longer owns from its hooks, version, and README.

### Task 10: Trim `local_conf/hooks/hooks.json`

**Files:**
- Modify: `plugins/local_conf/hooks/hooks.json`

- [ ] **Step 1: Replace the whole file contents**

Write `/Users/sanjay/Code/claude_stuff/snjnlsn-marketplace/plugins/local_conf/hooks/hooks.json` with:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "mcp__serena__*",
        "hooks": [
          {
            "type": "command",
            "command": "serena-hooks auto-approve --client=claude-code"
          }
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "if": "Bash(sed *)",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/sed-guard.sh"
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "serena-hooks activate --client=claude-code"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "serena-hooks cleanup --client=claude-code"
          }
        ]
      }
    ]
  }
}
```

- [ ] **Step 2: Verify JSON validity and that no `handoff` / `nudge` references survived**

```bash
python3 -c "import json; d = json.load(open('plugins/local_conf/hooks/hooks.json')); print(sorted(d['hooks'].keys()))"
grep -niE "handoff|nudge|stop-nudge|handoff-list" plugins/local_conf/hooks/hooks.json || echo NONE
```

Expected output:
```
['PreToolUse', 'SessionStart', 'Stop']
NONE
```

---

### Task 11: Bump `local_conf` plugin version to 2.0.0

**Files:**
- Modify: `plugins/local_conf/.claude-plugin/plugin.json`

- [ ] **Step 1: Apply the version edit**

In `/Users/sanjay/Code/claude_stuff/snjnlsn-marketplace/plugins/local_conf/.claude-plugin/plugin.json`, replace:

```
  "version": "1.10.0",
```

with:

```
  "version": "2.0.0",
```

(Description and other fields stay as-is per the spec.)

- [ ] **Step 2: Verify**

```bash
python3 -c "import json; d = json.load(open('plugins/local_conf/.claude-plugin/plugin.json')); print(d['name'], d['version'])"
```

Expected output: `local_conf 2.0.0`

---

### Task 12: Trim `local_conf/README.md`

**Files:**
- Modify: `plugins/local_conf/README.md`

The current file (47 lines) has Skills, Hooks, and Scripts subsections under `## What's inside`. After this task: the Skills section becomes a one-line note pointing at the new plugin; the Scripts table loses two rows; the Hooks table's SessionStart and Stop rows lose their handoff/nudge halves.

- [ ] **Step 1: Read the current file to establish exact context for edits**

Read `/Users/sanjay/Code/claude_stuff/snjnlsn-marketplace/plugins/local_conf/README.md` in full. Confirm it matches the structure described above (Skills table with four rows, Hooks table with three rows, Scripts table with three rows).

- [ ] **Step 2: Replace the Skills subsection**

Replace this block (the `### Skills` heading and its table — lines 7–14 of the current file):

```markdown
### Skills

| Path | Purpose |
|---|---|
| `skills/session-handoff/` | Maintains a per-session handoff document under `docs/handoffs/`. Author-tagged filenames support multiple users sharing one repo; tone guidance keeps prose plain and disclaimer-marked; includes a one-shot migration path for legacy single-user filenames |
| `skills/session-retrospect/` | End-of-session reflection. After explicit approval: narrative appended to the current handoff; concrete edits applied directly to the affected files (skills, `CLAUDE.md`, settings, hooks). |
| `skills/finalize-branch/` | End-of-branch pipeline — audits and updates inline code docs and project docs (with language/tone guidance), removes the branch's handoffs, produces one final commit; supports cancel-and-resume via stash |
| `skills/handle-callouts/` | Capture session findings as callouts (discoveries, decisions, caveats, gotchas, lessons learned, known issues, complexities, edge cases) in the current session's handoff. Triggers on explicit phrases or proactive recognition. |
```

with:

```markdown
### Skills

_No skills — the `session-handoff`, `session-retrospect`, `handle-callouts`, and `finalize-branch` skills moved to the [`session-continuity`](../session-continuity/) plugin._
```

- [ ] **Step 3: Replace the Hooks table**

Replace:

```markdown
### Hooks

| Event | Behavior |
|---|---|
| `SessionStart` | (1) Activates Serena. (2) Runs `scripts/handoff-list-recent.sh` to inject a list of recent handoffs into context. |
| `Stop` | (1) Serena cleanup. (2) Runs `scripts/stop-nudge.sh` — emits a wrap-up reminder when the session has run long enough, rate-limited per session. |
| `PreToolUse` | (1) Auto-approves `mcp__serena__*` tool calls. (2) `scripts/sed-guard.sh` blocks `sed -i` / `--in-place`. |
```

with:

```markdown
### Hooks

| Event | Behavior |
|---|---|
| `SessionStart` | Activates Serena. |
| `Stop` | Serena cleanup. |
| `PreToolUse` | (1) Auto-approves `mcp__serena__*` tool calls. (2) `scripts/sed-guard.sh` blocks `sed -i` / `--in-place`. |
```

- [ ] **Step 4: Replace the Scripts table**

Replace:

```markdown
### Scripts

| Script | Used by | Purpose |
|---|---|---|
| `scripts/sed-guard.sh` | `PreToolUse` | Block in-place sed |
| `scripts/handoff-list-recent.sh` | `SessionStart` | List recent handoffs for context injection |
| `scripts/stop-nudge.sh` | `Stop` | Rate-limited wrap-up reminder |
```

with:

```markdown
### Scripts

| Script | Used by | Purpose |
|---|---|---|
| `scripts/sed-guard.sh` | `PreToolUse` | Block in-place sed |
```

- [ ] **Step 5: Verify all remaining references to moved content live only in the Skills pointer line**

```bash
grep -nE "session-handoff|session-retrospect|handle-callouts|finalize-branch|handoff-list-recent|stop-nudge|docs/handoffs" plugins/local_conf/README.md
```

Expected: exactly **one** match line — the Skills section's pointer note enumerating the four moved skill names. The match line should look like:

```
N:_No skills — the `session-handoff`, `session-retrospect`, `handle-callouts`, and `finalize-branch` skills moved to the [`session-continuity`](../session-continuity/) plugin._
```

(`N` is whatever line number the note ended up on.) If you see additional matches — anywhere in the Hooks table, Scripts table, or prose — investigate and re-edit before continuing. The pointer note is intentional; everything else is a leftover.

---

### Task 13: Commit the local_conf trim

- [ ] **Step 1: Stage**

```bash
git add plugins/local_conf/hooks/hooks.json plugins/local_conf/.claude-plugin/plugin.json plugins/local_conf/README.md
```

- [ ] **Step 2: Confirm**

```bash
git status --short
```

Expected: three `M ` lines for the three files above. Nothing else.

- [ ] **Step 3: Commit**

```bash
git commit -m "$(cat <<'EOF'
Trim local_conf to Serena and sed-guard only

Strip the SessionStart handoff-list and Stop wrap-up-nudge entries
from hooks.json (their scripts have moved to session-continuity).
Bump local_conf to 2.0.0 — removing four skills and two scripts
is a behavioral break for anyone with only local_conf installed.
Update the README to describe what local_conf actually owns now.
EOF
)"
```

---

## Phase 4 — Update the marketplace catalog (commit 4)

The new plugin only becomes visible to `/plugin install` once `marketplace.json` lists it.

### Task 14: Add the `session-continuity` entry to `marketplace.json`

**Files:**
- Modify: `.claude-plugin/marketplace.json`

- [ ] **Step 1: Replace the file contents**

Write `/Users/sanjay/Code/claude_stuff/snjnlsn-marketplace/.claude-plugin/marketplace.json` with:

```json
{
  "name": "snjnlsn-marketplace",
  "description": "Personal plugin marketplace",
  "owner": {
    "name": "Sanjay Nelson"
  },
  "plugins": [
    {
      "name": "overrides",
      "description": "Personal plugin overrides — customizes and hooks into other Claude Code plugins.",
      "source": "./plugins/overrides"
    },
    {
      "name": "local_conf",
      "description": "My personal configuration",
      "source": "./plugins/local_conf"
    },
    {
      "name": "session-continuity",
      "description": "Per-session and per-branch documentation lifecycle: handoffs, callouts, retrospects, branch finalization.",
      "source": "./plugins/session-continuity"
    }
  ]
}
```

- [ ] **Step 2: Verify JSON validity, plugin count, and that every `source` resolves**

```bash
python3 -c "
import json, os
d = json.load(open('.claude-plugin/marketplace.json'))
print('plugins:', [p['name'] for p in d['plugins']])
for p in d['plugins']:
    src = p['source']
    print(f'  {p[\"name\"]}: source={src} exists={os.path.isdir(src)}')
"
```

Expected output:
```
plugins: ['overrides', 'local_conf', 'session-continuity']
  overrides: source=./plugins/overrides exists=True
  local_conf: source=./plugins/local_conf exists=True
  session-continuity: source=./plugins/session-continuity exists=True
```

---

### Task 15: Update the marketplace root README

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Replace the plugins table**

Replace this block (lines 7–10 of the current file):

```markdown
| Plugin | Purpose |
|---|---|
| [`overrides`](plugins/overrides/) | MCP-enabled overrides (Tidewave/Serena/HexDocs/Context7) of `superpowers` agents/skills, plus a routing skill that prefers the MCP-enabled variants. |
| [`local_conf`](plugins/local_conf/) | Personal hooks, helper scripts, skills, and slash commands. Includes session-handoff, session-retrospect, and finalize-branch skills, Serena auto-approval, in-place sed guard, and end-of-session wrap-up nudge. |
```

with:

```markdown
| Plugin | Purpose |
|---|---|
| [`overrides`](plugins/overrides/) | MCP-enabled overrides (Tidewave/Serena/HexDocs/Context7) of `superpowers` agents/skills, plus a routing skill that prefers the MCP-enabled variants. |
| [`local_conf`](plugins/local_conf/) | Personal hooks and helper scripts. Serena auto-approve/activate/cleanup, and `sed -i` guard. |
| [`session-continuity`](plugins/session-continuity/) | Per-session and per-branch documentation lifecycle: handoffs, callouts, retrospects, and branch finalization. Includes SessionStart context injection and a Stop wrap-up nudge. |
```

- [ ] **Step 2: Verify the table reads cleanly and lists three plugins**

```bash
grep -E '^\| \[`' README.md
```

Expected: three lines, one per plugin (`overrides`, `local_conf`, `session-continuity`), in that order.

---

### Task 16: Commit the marketplace catalog update

- [ ] **Step 1: Stage**

```bash
git add .claude-plugin/marketplace.json README.md
```

- [ ] **Step 2: Confirm**

```bash
git status --short
```

Expected: two `M ` lines.

- [ ] **Step 3: Commit**

```bash
git commit -m "$(cat <<'EOF'
Register session-continuity in the marketplace catalog

Append the new plugin to marketplace.json and add its row to the
top-level README plugins table. Tighten the local_conf row's
description to match what local_conf actually contains now.
EOF
)"
```

---

## Phase 5 — Final verification (commit 5, only if cleanup needed)

Run the spec's verification commands and a `/reload-plugins` smoke test. Most likely no new commit is needed — this phase is the safety net.

### Task 17: Run the verification sweep

- [ ] **Step 1: Confirm no `local_conf` references survived in the new plugin**

```bash
grep -rn local_conf plugins/session-continuity/ || echo NONE
```

Expected: `NONE`. (If anything appears, investigate, fix with an Edit, and stage for an additional commit at the end of this phase.)

- [ ] **Step 2: Confirm `local_conf` only mentions moved content in its README pointer note**

```bash
grep -rnE "session-handoff|session-retrospect|handle-callouts|finalize-branch|handoff-list-recent|stop-nudge" plugins/local_conf/
```

Expected: exactly **one** match — the `plugins/local_conf/README.md` Skills pointer note that enumerates the four moved skills and links to `session-continuity`. Any match outside that single line (in `hooks/hooks.json`, `scripts/sed-guard.sh`, the Hooks/Scripts tables of the README, etc.) is a leftover; investigate and fix with an inline edit.

- [ ] **Step 3: Confirm all four moved `SKILL.md` files retain valid frontmatter**

```bash
for f in plugins/session-continuity/skills/*/SKILL.md; do
  echo "=== $f ==="
  head -5 "$f"
done
```

Expected: each file starts with `---`, has `name:` and `description:` lines in its frontmatter, and ends the frontmatter with `---`.

- [ ] **Step 4: Confirm both moved scripts are executable and parse**

```bash
ls -l plugins/session-continuity/scripts/
bash -n plugins/session-continuity/scripts/handoff-list-recent.sh && echo handoff-list OK
bash -n plugins/session-continuity/scripts/stop-nudge.sh && echo stop-nudge OK
```

Expected: both files show `x` bits in the mode column; both `bash -n` runs print `OK`.

- [ ] **Step 5: Confirm `stop-nudge.sh` cache path is the new namespace**

```bash
grep -n CACHE_DIR plugins/session-continuity/scripts/stop-nudge.sh
```

Expected: `17:CACHE_DIR="${HOME}/.cache/session-continuity/stop-nudge"`

- [ ] **Step 6: Confirm marketplace.json points at three real directories**

```bash
python3 -c "
import json, os
d = json.load(open('.claude-plugin/marketplace.json'))
assert len(d['plugins']) == 3, f'expected 3 plugins, got {len(d[\"plugins\"])}'
for p in d['plugins']:
    assert os.path.isdir(p['source']), f'missing dir for {p[\"name\"]}: {p[\"source\"]}'
print('OK')
"
```

Expected: `OK`

- [ ] **Step 7: Run `/reload-plugins` and a fresh-session smoke test (manual, by the user)**

This step is performed by the user, not the agent. Report to the user:

> "Plan execution complete. Please run `/plugin marketplace update @snjnlsn/snjnlsn-marketplace`, then `/plugin install session-continuity@snjnlsn-marketplace`, then `/reload-plugins` (or restart Claude Code). In a fresh session, confirm: (1) `session-handoff`, `session-retrospect`, `handle-callouts`, and `finalize-branch` skills appear in the available-skills list; (2) when started in a repo with `docs/handoffs/`, the SessionStart system reminder includes the recent-handoffs list."

- [ ] **Step 8: If any verification step turned up issues, fix and commit**

If steps 1–6 surfaced anything that needed an inline fix, stage the fix:

```bash
git status --short
git add <fixed files>
git commit -m "Fix verification-sweep issue: <one-line description>"
```

If the sweep was clean, no additional commit is needed; this task ends here.

---

## Notes for the executing agent

- **Working directory:** `/Users/sanjay/Code/claude_stuff/snjnlsn-marketplace`. All paths in this plan are relative to this directory unless otherwise marked. Don't `cd` mid-execution; use absolute or repo-relative paths.
- **Use the Edit tool for all in-content edits**, not `sed`. The `local_conf` plugin's PreToolUse hook will be active during execution and blocks `sed -i`.
- **Edits to moved files (Tasks 7, 8) target the post-move path** — `plugins/session-continuity/...`, not `plugins/local_conf/...`. Tasks 5–6 must complete before Tasks 7–8.
- **Never `--amend`.** Per global rules: if a pre-commit hook fails, fix and create a NEW commit. Skill cross-references resolve by bare name across plugins, so commits 1 and 2 are mid-PR-bisect-broken (the new plugin's hooks point at scripts that don't exist until commit 2; that's expected and acceptable for an atomic move).
- **Use Serena's symbolic tools** for any code navigation; reserve `Read`/`Grep` for the markdown/JSON/shell text edits in this plan (none of which are code symbols).
