# Session Handoff & Retrospect Skills Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add two skills (`session-handoff`, `session-retrospect`) to the `local_conf` plugin, with two helper hook scripts, two slash commands, and `SessionStart` + `Stop` hook entries.

**Architecture:** Skill-driven (Approach 1 from spec). All content manipulation goes through Claude's Read/Edit/Write tools driven by skill prompts. Two tiny shell scripts handle only discovery (recent-handoffs list) and rate-limiting (Stop nudge cooldown). Hooks emit `additionalContext` payloads pointing Claude at the skills.

**Tech Stack:** Bash + jq for hook scripts. Markdown for SKILL.md and slash commands. JSON for `hooks.json`.

**Spec:** `docs/superpowers/specs/2026-04-29-session-handoff-and-retrospect-skills-design.md`

---

## File structure

**Create:**
- `plugins/local_conf/skills/session-handoff/SKILL.md`
- `plugins/local_conf/skills/session-retrospect/SKILL.md`
- `plugins/local_conf/scripts/handoff-list-recent.sh`
- `plugins/local_conf/scripts/stop-nudge.sh`
- `plugins/local_conf/commands/handoff.md`
- `plugins/local_conf/commands/retrospect.md`

**Modify:**
- `plugins/local_conf/hooks/hooks.json` — add SessionStart + Stop entries
- `plugins/local_conf/README.md` — replace stub content (currently a stale copy of the `overrides` README) with real `local_conf` documentation including the new additions

**Bump:**
- `plugins/local_conf/.claude-plugin/plugin.json` — version 1.0.3 → 1.1.0

**Test approach:** No automated harness (per spec). Shell scripts verified via direct bash invocation with expected stdout. SKILL.md files and hooks verified via manual smoke test in a fresh Claude Code session at the end (Task 9).

---

### Task 1: Create `session-handoff` skill

**Files:**
- Create: `plugins/local_conf/skills/session-handoff/SKILL.md`

- [ ] **Step 1: Create the skill directory and SKILL.md**

```bash
mkdir -p plugins/local_conf/skills/session-handoff
```

Write `plugins/local_conf/skills/session-handoff/SKILL.md`:

````markdown
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
- Filename: `YYYY-MM-DD-HHMMSS-<slug>.md`.
- `YYYY-MM-DD-HHMMSS` is the timestamp at the moment of *first content write* (lazy creation), not session start. Use UTC.
- `<slug>` is a short kebab-case summary derived from the session's work so far. If too sparse to summarize, ask the user.
- On slug collision in the same day, append `-2`, `-3`, etc.

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

A `## Retrospective` section is added later by the `session-retrospect` skill if it runs. Do not add it from this skill.

## Behaviors

### Read existing handoff (for context)

Use the Read tool on the requested file (or the most recent file in `docs/handoffs/` if unspecified). Summarize relevance to the current session. If the user says to adopt it as the working handoff, do so.

### Continue / adopt existing handoff

Set the working handoff path in conversation context to that file. Subsequent "add to handoff" calls write there.

### Lazy-create on first write

On the first write request without a working handoff:

1. Derive a slug from session work so far. If insufficient context, ask the user.
2. Get current UTC ISO timestamp; format `YYYY-MM-DD-HHMMSS` for the filename.
3. Check for slug collision in `docs/handoffs/` for today's date prefix. On collision, append `-2`, `-3`, etc.
4. Create `docs/handoffs/` if missing (use Bash `mkdir -p docs/handoffs`).
5. Use Write to create the file with the template, with the first content already in the right section.
6. Set "Started" and "Last updated" to the current ISO timestamp.

### Append to existing handoff

1. Use Read to load the file.
2. Use Edit to splice content into the appropriate section (Summary, Work done, Open questions / next steps, Retrospective).
3. Use Edit to refresh the "Last updated" timestamp.

## Routing content to the right section

- A description of work completed → "Work done"
- A TODO, follow-up item, or unresolved question → "Open questions / next steps"
- A high-level framing or outcome statement → "Summary"
- Retrospective insight (only via `session-retrospect` skill) → "Retrospective"

## State

The working handoff path is held in conversation context. If conversation context drops it, re-discover by listing `docs/handoffs/` and picking the file whose timestamp matches the current session, or ask the user.
````

- [ ] **Step 2: Verify the file is well-formed**

Run: `head -3 plugins/local_conf/skills/session-handoff/SKILL.md`
Expected: shows `---` then `name: session-handoff` then `description: …`.

- [ ] **Step 3: Commit**

```bash
git add plugins/local_conf/skills/session-handoff/SKILL.md
git commit -m "Add session-handoff skill to local_conf"
```

---

### Task 2: Create `session-retrospect` skill

**Files:**
- Create: `plugins/local_conf/skills/session-retrospect/SKILL.md`

- [ ] **Step 1: Create the skill directory and SKILL.md**

```bash
mkdir -p plugins/local_conf/skills/session-retrospect
```

Write `plugins/local_conf/skills/session-retrospect/SKILL.md`:

````markdown
---
name: session-retrospect
description: Reflect on the current session — what went well, what didn't, and what concrete changes to make to skills, CLAUDE.md, settings, or hooks. Use when the user says "retrospect", "retrospect this session", "let's retro", frames "what went well / what didn't", or accepts the wrap-up nudge from the Stop hook. Nothing is persisted before the user approves.
---

# Session Retrospect

Reflect on a session. Produce narrative insight (saved to the current session's handoff) plus a list of concrete edits to apply (only after user approval).

## When to use

Activate when the user says:
- "retrospect" / "retrospect this session" / "let's retro"
- frames "what went well" / "what didn't go well"

Also activate when the Stop hook has surfaced a wrap-up nudge and the user accepts.

## Process

1. **Analyze.** Look at the session transcript context. Identify:
   - What went well (decisions that paid off, smooth flows, useful tools)
   - What didn't (friction, dead ends, repeated corrections, missing context)
   - Candidate concrete changes:
     - Skills (in this marketplace's plugins or any other accessible skill location)
     - `~/.claude/CLAUDE.md` (global instructions)
     - Per-project CLAUDE.md
     - `~/.claude/settings.json`
     - Hooks
2. **Present.** Write the retrospective to the user as a structured message with three sections (well / not well / candidate changes). Each candidate change should name the file and the proposed edit clearly enough that approval is meaningful.
3. **Discuss.** The user can edit, add, remove, or reframe items. Keep the draft in conversation context. **Do not persist anything yet.**
4. **Apply on approval.** When the user gives a clear "persist" / "apply these" / "ok do it" signal:
   1. Append a `## Retrospective` section to the *current session's* handoff. If no handoff exists yet for this session, lazy-create one (delegate to the `session-handoff` skill flow: derive slug, compute filename, create file with template). The Retrospective section content is the agreed-upon narrative — what went well, what didn't — *not* the list of file changes.
   2. Apply each approved concrete change directly via Edit/Write tools to the affected files.
   3. Confirm what was written and what was edited.

## Constraints

- Nothing is persisted before the user approves.
- The "Retrospective" section in the handoff is narrative only (well / not well). Concrete file changes go to the files themselves; do not duplicate them in the handoff.
- If the user approves only narrative without applying changes, that's fine — apply just the handoff append.
- If the user approves only concrete changes without saving narrative, that's fine too.
- If the session was very short or the user explicitly skips the analysis step, do not invent observations. Say so plainly.
````

- [ ] **Step 2: Verify the file is well-formed**

Run: `head -3 plugins/local_conf/skills/session-retrospect/SKILL.md`
Expected: shows `---` then `name: session-retrospect` then `description: …`.

- [ ] **Step 3: Commit**

```bash
git add plugins/local_conf/skills/session-retrospect/SKILL.md
git commit -m "Add session-retrospect skill to local_conf"
```

---

### Task 3: Create `handoff-list-recent.sh`

**Files:**
- Create: `plugins/local_conf/scripts/handoff-list-recent.sh`

- [ ] **Step 1: Write the script**

Write `plugins/local_conf/scripts/handoff-list-recent.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# SessionStart hook helper.
# Lists up to MAX most recent files in $cwd/docs/handoffs/ sorted by mtime,
# and emits a SessionStart additionalContext payload pointing Claude at
# the session-handoff and session-retrospect skills.
#
# Always exits 0. On any internal error, emits no context (still exits 0)
# so the session is never blocked.

HANDOFF_DIR="docs/handoffs"
MAX=5

emit_context() {
  jq -n --arg ctx "$1" '{
    hookSpecificOutput: {
      hookEventName: "SessionStart",
      additionalContext: $ctx
    }
  }'
}

list_recent() {
  if [ ! -d "$HANDOFF_DIR" ]; then
    return 0
  fi
  find "$HANDOFF_DIR" -maxdepth 1 -type f -name "*.md" \
    -exec stat -f '%m %N' {} + 2>/dev/null \
    | sort -rn \
    | head -n "$MAX" \
    | while read -r mtime path; do
        iso=$(date -r "$mtime" -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "?")
        echo "- ${path#./} — ${iso}"
      done
}

# Suppress errors on the listing — we'd rather emit a degraded context than block.
recent=$(list_recent 2>/dev/null || true)

if [ -n "$recent" ]; then
  ctx=$(printf 'Recent session handoffs in %s/:\n%s\n\nThe `session-handoff` skill can read, continue, or start fresh. The `session-retrospect` skill is also available on demand. If a recent handoff is relevant, consider offering the user to read it for context or continue it.' "$HANDOFF_DIR" "$recent")
else
  ctx=$(printf 'No prior handoffs found at %s/. The `session-handoff` skill can start a fresh handoff on demand or when content first arrives. The `session-retrospect` skill is also available.' "$HANDOFF_DIR")
fi

emit_context "$ctx" 2>/dev/null || true
```

- [ ] **Step 2: Make it executable**

```bash
chmod +x plugins/local_conf/scripts/handoff-list-recent.sh
```

- [ ] **Step 3: Smoke-test with no handoffs directory**

```bash
mkdir -p /tmp/handoff-test-empty
cd /tmp/handoff-test-empty
/Users/sanjay/Code/claude_stuff/snjnlsn-marketplace/plugins/local_conf/scripts/handoff-list-recent.sh
cd -
rm -rf /tmp/handoff-test-empty
```

Expected: a JSON object with `hookSpecificOutput.additionalContext` containing the "No prior handoffs found" wording.

- [ ] **Step 4: Smoke-test with handoffs present**

```bash
mkdir -p /tmp/handoff-test-full/docs/handoffs
touch /tmp/handoff-test-full/docs/handoffs/2026-04-28-091200-first.md
sleep 1
touch /tmp/handoff-test-full/docs/handoffs/2026-04-28-152400-second.md
cd /tmp/handoff-test-full
/Users/sanjay/Code/claude_stuff/snjnlsn-marketplace/plugins/local_conf/scripts/handoff-list-recent.sh
cd -
rm -rf /tmp/handoff-test-full
```

Expected: JSON output where `additionalContext` lists `second.md` first (most recent), then `first.md`, both with ISO timestamps.

- [ ] **Step 5: Shellcheck**

```bash
shellcheck plugins/local_conf/scripts/handoff-list-recent.sh
```

Expected: no warnings, or only pedantic style warnings. Fix any error-level findings.

- [ ] **Step 6: Commit**

```bash
git add plugins/local_conf/scripts/handoff-list-recent.sh
git commit -m "Add handoff-list-recent.sh helper for SessionStart hook"
```

---

### Task 4: Create `stop-nudge.sh`

**Files:**
- Create: `plugins/local_conf/scripts/stop-nudge.sh`

This script reads the Stop hook's stdin payload, computes whether to emit a wrap-up nudge based on assistant turn count, elapsed time since the first assistant turn, and a per-session cooldown.

- [ ] **Step 1: Write the script**

Write `plugins/local_conf/scripts/stop-nudge.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Stop hook helper.
# Reads the Stop payload from stdin, computes whether to nudge the user
# toward wrapping up (handoff update / retrospective) based on:
#   - assistant turn count >= TURN_THRESHOLD, OR
#   - elapsed minutes since the first assistant turn >= ELAPSED_MIN_THRESHOLD
# Suppresses repeat nudges within COOLDOWN_MIN minutes per session.
#
# Always exits 0. On any internal error, emits no context.

TURN_THRESHOLD=20
ELAPSED_MIN_THRESHOLD=30
COOLDOWN_MIN=15

CACHE_DIR="${HOME}/.cache/local_conf/stop-nudge"
mkdir -p "$CACHE_DIR" 2>/dev/null || true

input=$(cat || true)
session_id=$(echo "$input" | jq -r '.session_id // empty' 2>/dev/null || echo "")
transcript_path=$(echo "$input" | jq -r '.transcript_path // empty' 2>/dev/null || echo "")

if [ -z "$session_id" ] || [ -z "$transcript_path" ] || [ ! -f "$transcript_path" ]; then
  exit 0
fi

# Count assistant turns. Transcript is JSONL; entries may have either
# .role at top-level or .message.role nested.
turn_count=$(jq -s '[.[] | select((.message.role // .role // "") == "assistant")] | length' "$transcript_path" 2>/dev/null || echo 0)
turn_count=${turn_count:-0}

# Earliest assistant timestamp (ISO 8601). Try .timestamp then .message.timestamp.
earliest_ts=$(jq -rs '
  [.[] | select((.message.role // .role // "") == "assistant")
       | (.timestamp // .message.timestamp // empty)]
  | map(select(. != null and . != ""))
  | first // empty
' "$transcript_path" 2>/dev/null || echo "")

now_epoch=$(date -u +%s)
earliest_epoch=0
if [ -n "$earliest_ts" ]; then
  ts="${earliest_ts%%.*}"   # strip fractional seconds
  ts="${ts%Z}"               # strip trailing Z
  earliest_epoch=$(date -juf "%Y-%m-%dT%H:%M:%S" "$ts" +%s 2>/dev/null || echo 0)
fi

elapsed_min=0
if [ "$earliest_epoch" -gt 0 ]; then
  elapsed_min=$(( (now_epoch - earliest_epoch) / 60 ))
fi

# Threshold check
if [ "$turn_count" -lt "$TURN_THRESHOLD" ] && [ "$elapsed_min" -lt "$ELAPSED_MIN_THRESHOLD" ]; then
  exit 0
fi

# Cooldown check
state_file="${CACHE_DIR}/${session_id}.ts"
if [ -f "$state_file" ]; then
  last_ts=$(cat "$state_file" 2>/dev/null || echo 0)
  last_ts=${last_ts:-0}
  cooldown_sec=$((COOLDOWN_MIN * 60))
  if [ $((now_epoch - last_ts)) -lt "$cooldown_sec" ]; then
    exit 0
  fi
fi

# Update last-nudge timestamp (best-effort)
echo "$now_epoch" > "$state_file" 2>/dev/null || true

ctx="If this looks like a wrap-up moment, consider offering to update the handoff (\`session-handoff\` skill) or run a retrospective (\`session-retrospect\` skill). This nudge will not repeat for ${COOLDOWN_MIN} minutes."

jq -n --arg ctx "$ctx" '{
  hookSpecificOutput: {
    hookEventName: "Stop",
    additionalContext: $ctx
  }
}' 2>/dev/null || true
```

- [ ] **Step 2: Make it executable**

```bash
chmod +x plugins/local_conf/scripts/stop-nudge.sh
```

- [ ] **Step 3: Smoke-test with no input (defensive path)**

```bash
echo '' | plugins/local_conf/scripts/stop-nudge.sh
echo "exit: $?"
```

Expected: empty output (or just whitespace), exit 0.

- [ ] **Step 4: Smoke-test with malformed input**

```bash
echo '{"foo": "bar"}' | plugins/local_conf/scripts/stop-nudge.sh
echo "exit: $?"
```

Expected: empty output, exit 0 (missing session_id and transcript_path → silent exit).

- [ ] **Step 5: Smoke-test with a synthetic transcript that meets the turn threshold**

```bash
# Build a fake transcript with 25 assistant turns, earliest 60min ago.
TRANS=$(mktemp)
EARLIEST=$(date -u -v-60M +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -d '60 min ago' +"%Y-%m-%dT%H:%M:%SZ")
{
  for i in $(seq 1 25); do
    printf '{"role":"assistant","timestamp":"%s"}\n' "$EARLIEST"
  done
} > "$TRANS"

# Clear any prior cooldown state for this fake session
rm -f ~/.cache/local_conf/stop-nudge/test-session-1.ts

printf '{"session_id":"test-session-1","transcript_path":"%s"}\n' "$TRANS" \
  | plugins/local_conf/scripts/stop-nudge.sh

rm -f "$TRANS" ~/.cache/local_conf/stop-nudge/test-session-1.ts
```

Expected: JSON object with `hookSpecificOutput.additionalContext` containing the wrap-up nudge text.

- [ ] **Step 6: Smoke-test cooldown suppression**

```bash
TRANS=$(mktemp)
EARLIEST=$(date -u -v-60M +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -d '60 min ago' +"%Y-%m-%dT%H:%M:%SZ")
{
  for i in $(seq 1 25); do
    printf '{"role":"assistant","timestamp":"%s"}\n' "$EARLIEST"
  done
} > "$TRANS"

# First call: should nudge.
printf '{"session_id":"test-session-2","transcript_path":"%s"}\n' "$TRANS" \
  | plugins/local_conf/scripts/stop-nudge.sh

# Second call immediately after: should suppress (cooldown).
printf '{"session_id":"test-session-2","transcript_path":"%s"}\n' "$TRANS" \
  | plugins/local_conf/scripts/stop-nudge.sh

rm -f "$TRANS" ~/.cache/local_conf/stop-nudge/test-session-2.ts
```

Expected: first call emits JSON; second call emits nothing (empty stdout).

- [ ] **Step 7: Shellcheck**

```bash
shellcheck plugins/local_conf/scripts/stop-nudge.sh
```

Expected: no error-level findings. Fix any error-level findings; warnings/info OK.

- [ ] **Step 8: Commit**

```bash
git add plugins/local_conf/scripts/stop-nudge.sh
git commit -m "Add stop-nudge.sh helper for Stop hook wrap-up reminder"
```

---

### Task 5: Add `/handoff` and `/retrospect` slash commands

**Files:**
- Create: `plugins/local_conf/commands/handoff.md`
- Create: `plugins/local_conf/commands/retrospect.md`

- [ ] **Step 1: Create the commands directory**

```bash
mkdir -p plugins/local_conf/commands
```

- [ ] **Step 2: Write `commands/handoff.md`**

```markdown
---
description: Manage the current session's handoff document under docs/handoffs/
---

Use the `session-handoff` skill to manage this session's handoff document. Available actions: read an existing handoff for context, continue an existing handoff, or create/update the current session's handoff.

If the user passed arguments after `/handoff`, treat them as the operation or content. Otherwise, ask the user what they'd like to do.
```

- [ ] **Step 3: Write `commands/retrospect.md`**

```markdown
---
description: Reflect on this session and propose changes to skills, CLAUDE.md, settings, or hooks
---

Use the `session-retrospect` skill to reflect on this session. Analyze the session, present a structured retrospective (what went well, what didn't go well, candidate concrete changes), and wait for the user's approval before persisting anything. On approval, append the narrative to the current session's handoff and apply concrete edits to the affected files.
```

- [ ] **Step 4: Commit**

```bash
git add plugins/local_conf/commands/handoff.md plugins/local_conf/commands/retrospect.md
git commit -m "Add /handoff and /retrospect slash commands to local_conf"
```

---

### Task 6: Wire SessionStart and Stop hooks in `hooks.json`

**Files:**
- Modify: `plugins/local_conf/hooks/hooks.json`

The existing file has `PreToolUse`, `SessionStart` (with one entry), and `Stop` (with one entry) keys. We add to the existing `SessionStart` and `Stop` arrays — do not replace them.

- [ ] **Step 1: Read the current hooks.json**

```bash
cat plugins/local_conf/hooks/hooks.json
```

Confirm the file matches what's shown in Step 2's "before" view. If it doesn't, reconcile manually before continuing.

- [ ] **Step 2: Replace with the updated version**

The current file:

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

Replace with:

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
          },
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
            "command": "serena-hooks cleanup --client=claude-code"
          },
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

- [ ] **Step 3: Validate JSON**

```bash
jq . plugins/local_conf/hooks/hooks.json > /dev/null && echo "valid"
```

Expected: `valid`.

- [ ] **Step 4: Commit**

```bash
git add plugins/local_conf/hooks/hooks.json
git commit -m "Wire SessionStart and Stop hooks for handoff/retrospect skills"
```

---

### Task 7: Bump plugin version

**Files:**
- Modify: `plugins/local_conf/.claude-plugin/plugin.json`

- [ ] **Step 1: Read current version**

```bash
cat plugins/local_conf/.claude-plugin/plugin.json
```

Expected: shows `"version": "1.0.3"`.

- [ ] **Step 2: Bump to 1.1.0**

Edit `plugins/local_conf/.claude-plugin/plugin.json` to set `"version": "1.1.0"` (single line change).

After edit, the file should be:

```json
{
  "name": "local_conf",
  "description": "My personal configuration",
  "version": "1.1.0",
  "author": {
    "name": "Sanjay Nelson"
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add plugins/local_conf/.claude-plugin/plugin.json
git commit -m "Bump local_conf to 1.1.0"
```

---

### Task 8: Replace `local_conf` README

**Files:**
- Modify: `plugins/local_conf/README.md`

The current README is a stale copy of the `overrides` README. Replace with real `local_conf` documentation.

- [ ] **Step 1: Replace the file contents**

Write `plugins/local_conf/README.md`:

````markdown
# local_conf

Personal Claude Code plugin holding hooks, helper scripts, skills, and slash commands for `services@snjnlsn.co`'s local setup. Part of the [`snjnlsn-marketplace`](../../README.md).

## What's inside

### Skills

| Path | Purpose |
|---|---|
| `skills/session-handoff/` | Maintains a per-session handoff document under `docs/handoffs/` |
| `skills/session-retrospect/` | End-of-session reflection — narrative to the handoff, concrete edits applied directly |

### Slash commands

| Command | Purpose |
|---|---|
| `/handoff` | Route to the `session-handoff` skill |
| `/retrospect` | Route to the `session-retrospect` skill |

### Hooks

| Event | Behavior |
|---|---|
| `SessionStart` | (1) Activates Serena. (2) Runs `scripts/handoff-list-recent.sh` to inject a list of recent handoffs into context. |
| `Stop` | (1) Serena cleanup. (2) Runs `scripts/stop-nudge.sh` — emits a wrap-up reminder when the session has run long enough, rate-limited per session. |
| `PreToolUse` | (1) Auto-approves `mcp__serena__*` tool calls. (2) `scripts/sed-guard.sh` blocks `sed -i` / `--in-place`. |

### Scripts

| Script | Used by | Purpose |
|---|---|---|
| `scripts/sed-guard.sh` | `PreToolUse` | Block in-place sed |
| `scripts/handoff-list-recent.sh` | `SessionStart` | List recent handoffs for context injection |
| `scripts/stop-nudge.sh` | `Stop` | Rate-limited wrap-up reminder |

## Installation

1. Install the marketplace in Claude Code:
   ```
   /plugin marketplace add @snjnlsn/snjnlsn-marketplace
   ```

2. Install the plugin:
   ```
   /plugin install local_conf@snjnlsn-marketplace
   ```

## After structural changes

Run `/reload-plugins` in Claude Code, or restart.
````

- [ ] **Step 2: Commit**

```bash
git add plugins/local_conf/README.md
git commit -m "Replace local_conf README with real plugin documentation"
```

---

### Task 9: End-to-end smoke verification (manual)

Done by the user, not the implementer. The implementer should write up the verification steps in the final report.

The verification steps:

- [ ] **Step 1: Reload plugins**

In Claude Code: `/reload-plugins`. Expect to see counts include the new skills and hooks.

- [ ] **Step 2: Verify SessionStart hook injection**

Start a fresh Claude Code session in this repo (or any repo). Ask Claude what context the SessionStart hook just injected. Expect: a reference to `docs/handoffs/` and the two skills. If `docs/handoffs/` exists with files, expect them listed by mtime.

- [ ] **Step 3: Smoke-test `session-handoff`**

In a fresh session, do some trivial work (e.g., read a file, edit a file), then say: "add this to the handoff: <something>". Expect Claude to lazy-create `docs/handoffs/<timestamp>-<slug>.md` with the template, content placed in the right section, and `Started`/`Last updated` populated.

- [ ] **Step 4: Smoke-test `session-retrospect`**

Same session, say: "retrospect this session". Expect a structured retrospective (well / not well / candidate changes). Edit one item, then approve. Expect a `## Retrospective` section appended to the handoff, plus any approved file edits applied.

- [ ] **Step 5: Smoke-test slash commands**

In the same session, run `/handoff` and `/retrospect`. Expect each to invoke the corresponding skill.

- [ ] **Step 6: Smoke-test Stop nudge**

Run a session for 30+ min or 20+ assistant turns. After the threshold, expect Claude to surface a wrap-up nudge in a turn following Stop. Continue beyond the cooldown (15 min) to confirm the nudge can re-fire later but is suppressed in between.

- [ ] **Step 7: Commit any tweaks**

If any of Steps 1-6 surface issues — wording, threshold, or behavior tweaks — make targeted fixes and commit them with messages explaining the tweak.

---

## Self-review notes

- **Spec coverage:** Each spec section has at least one task — skills (1, 2), helper scripts (3, 4), hooks (6), README (8), version bump (7), slash commands (5, deferred-detail from spec resolved here), end-to-end verification (9).
- **Open implementation details from spec:** All resolved — slash commands added (Task 5), README copy written (Task 8), thresholds set (20 turns / 30 min / 15 min cooldown in Task 4 script). Skill `description` field wording finalized in Tasks 1 & 2.
- **Type/name consistency:** Skill names match across all references (`session-handoff`, `session-retrospect`). Script paths consistent. `${CLAUDE_PLUGIN_ROOT}` matches existing convention in `hooks.json`.
- **Risk noted:** Whether the Stop hook's `additionalContext` field is honored by Claude Code is not confirmed by docs read at plan time. The end-to-end smoke (Task 9 Step 6) is the verification gate. If the field is ignored for Stop, fall back to outputting the nudge text on stdout (the Claude Code Stop hook's `output` field), which is then surfaced into context — adjust `stop-nudge.sh` accordingly and re-test. This adjustment is small (different JSON envelope) and does not affect any other task.
