# Extract `session-continuity` plugin from `local_conf`

**Date:** 2026-05-01
**Status:** Approved — ready for implementation plan

## Problem

`local_conf` currently bundles two unrelated concerns:

1. **Session and branch documentation lifecycle** — four interlinked skills (`session-handoff`, `session-retrospect`, `handle-callouts`, `finalize-branch`) plus the `SessionStart` context-injection (`handoff-list-recent.sh`) and `Stop` wrap-up nudge (`stop-nudge.sh`) that point at them.
2. **Local environment plumbing** — Serena auto-approve hook, Serena activate/cleanup hooks, and `sed -i` guard.

These groups have nothing to do with each other. They were colocated because `local_conf` was the only home for "personal stuff." The bundle obscures the documentation-lifecycle as a coherent system, makes the plugin harder to describe in one sentence, and forces anyone who wants only the documentation behavior to also accept the Serena/sed plumbing (and vice versa).

## Goal

Extract the documentation-lifecycle concern into a new standalone plugin, `session-continuity`, in the same marketplace. After the move, each plugin has one purpose:

- `local_conf` — local environment plumbing (Serena auto-approve/activate/cleanup, `sed -i` guard).
- `session-continuity` — per-session and per-branch documentation lifecycle (handoffs, callouts, retrospects, branch finalization, plus the SessionStart context-injection and Stop wrap-up nudge that surface them).

The two plugins compose cleanly: installing only one of them yields exactly the half of today's behavior it owns.

## Non-Goals

- No behavioral changes to any skill, hook, or script. Names, paths, and ownership only.
- No restructuring inside the moved skills (no flattening, no consolidation, no `lib/` directory).
- No changes to the `overrides` plugin.
- No deprecation period or backwards-compat shim — single-user marketplace, atomic move.
- No migration of the existing `~/.cache/local_conf/stop-nudge` directory contents (the files are session-scoped and rot harmlessly).

## Design

### Final marketplace layout

```
snjnlsn-marketplace/
├── .claude-plugin/marketplace.json       # 3 plugin entries: overrides, local_conf, session-continuity
├── README.md                              # plugin table updated for the third entry + tightened local_conf row
└── plugins/
    ├── overrides/                         # unchanged
    ├── local_conf/                        # shrunk: Serena/sed only
    │   ├── .claude-plugin/plugin.json     # version 2.0.0
    │   ├── README.md                      # session-workflow rows removed
    │   ├── hooks/hooks.json               # only Serena entries + sed-guard remain
    │   └── scripts/sed-guard.sh           # only remaining script
    └── session-continuity/                # NEW
        ├── .claude-plugin/plugin.json     # name: session-continuity, version 1.0.0
        ├── README.md                      # mirrors local_conf/README.md style
        ├── hooks/hooks.json               # SessionStart + Stop entries for the two scripts
        ├── scripts/
        │   ├── handoff-list-recent.sh     # moved from local_conf
        │   └── stop-nudge.sh              # moved from local_conf, with cache namespace rename
        └── skills/
            ├── session-handoff/SKILL.md
            ├── session-retrospect/SKILL.md
            ├── handle-callouts/SKILL.md
            └── finalize-branch/SKILL.md
```

### Hook ownership split

Each plugin keeps its own `SessionStart` and `Stop` entries, owning only its own commands. Claude Code merges hooks across installed plugins, so behavior with both plugins installed is identical to today.

**`plugins/local_conf/hooks/hooks.json`** (after the shrink):

```json
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "mcp__serena__*", "hooks": [{ "type": "command", "command": "serena-hooks auto-approve --client=claude-code" }] },
      { "matcher": "Bash",            "hooks": [{ "type": "command", "if": "Bash(sed *)", "command": "${CLAUDE_PLUGIN_ROOT}/scripts/sed-guard.sh" }] }
    ],
    "SessionStart": [
      { "matcher": "", "hooks": [{ "type": "command", "command": "serena-hooks activate --client=claude-code" }] }
    ],
    "Stop": [
      { "matcher": "", "hooks": [{ "type": "command", "command": "serena-hooks cleanup --client=claude-code" }] }
    ]
  }
}
```

**`plugins/session-continuity/hooks/hooks.json`** (new):

```json
{
  "hooks": {
    "SessionStart": [
      { "matcher": "", "hooks": [{ "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/scripts/handoff-list-recent.sh" }] }
    ],
    "Stop": [
      { "matcher": "", "hooks": [{ "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/scripts/stop-nudge.sh" }] }
    ]
  }
}
```

`${CLAUDE_PLUGIN_ROOT}` resolves to the registering plugin's root, so each script reference resolves correctly within its own plugin without changes.

The placeholder `plugins/local_conf/hooks/.gitkeep` and `plugins/local_conf/hooks/.unused-serena-hooks.json` files remain as they are.

### Skill content changes

The four skills move with `git mv`. Their bodies are unchanged except for one documentary fix:

**`plugins/session-continuity/skills/session-handoff/SKILL.md:202`** — example string currently reads:

```
plugins/local_conf/scripts/foo.sh:7  → '…cat docs/handoffs/2026-04-18-bar.md…'
```

Change to a plugin-agnostic example such as:

```
lib/worker.ex:42  → '…cat docs/handoffs/2026-04-18-bar.md…'
```

The example only illustrates what an embedded handoff reference looks like; the path is incidental.

The skills cross-reference each other by bare name (`session-handoff`, `handle-callouts`, `finalize-branch`, `session-retrospect`). Claude resolves skills by name across all installed plugins, so no other in-skill rewrites are needed.

### Script content changes

`handoff-list-recent.sh` moves with no changes.

`stop-nudge.sh` moves with one change at line 17:

```bash
# before
CACHE_DIR="${HOME}/.cache/local_conf/stop-nudge"

# after
CACHE_DIR="${HOME}/.cache/session-continuity/stop-nudge"
```

The cache holds one timestamp file per session ID, used solely for the 15-minute Stop-nudge cooldown within a session. After a session ends, the file is dead weight. Sessions active at the moment of the rename may receive one extra nudge; acceptable.

The old `~/.cache/local_conf/stop-nudge` directory is left in place. Removing it is optional and out of scope.

### Plugin manifests

**`plugins/session-continuity/.claude-plugin/plugin.json`** (new):

```json
{
  "name": "session-continuity",
  "description": "Per-session and per-branch documentation lifecycle: handoffs, callouts, retrospects, branch finalization.",
  "version": "1.0.0",
  "author": { "name": "Sanjay Nelson" }
}
```

**`plugins/local_conf/.claude-plugin/plugin.json`** — version bump only:

```json
{
  "name": "local_conf",
  "description": "My personal configuration",
  "version": "2.0.0",
  "author": { "name": "Sanjay Nelson" }
}
```

The `2.0.0` bump (from `1.10.0`) reflects that four skills and two scripts are removed. Anyone who had only `local_conf` installed loses those skills/scripts; tagging it major is the honest signal.

**`plugins/overrides/.claude-plugin/plugin.json`** — unchanged.

### Marketplace manifest

**`.claude-plugin/marketplace.json`** — append the third plugin entry:

```json
{
  "name": "snjnlsn-marketplace",
  "description": "Personal plugin marketplace",
  "owner": { "name": "Sanjay Nelson" },
  "plugins": [
    { "name": "overrides",          "description": "Personal plugin overrides — customizes and hooks into other Claude Code plugins.", "source": "./plugins/overrides" },
    { "name": "local_conf",         "description": "My personal configuration",                                                          "source": "./plugins/local_conf" },
    { "name": "session-continuity", "description": "Per-session and per-branch documentation lifecycle: handoffs, callouts, retrospects, branch finalization.", "source": "./plugins/session-continuity" }
  ]
}
```

### README updates

**`plugins/session-continuity/README.md`** (new) — mirrors `local_conf/README.md`'s style. Sections:

1. One-line purpose (per-session and per-branch documentation lifecycle).
2. **What's inside** — three tables: Skills (the four), Hooks (SessionStart, Stop), Scripts (the two).
3. **Installation** — `/plugin marketplace add @snjnlsn/snjnlsn-marketplace` then `/plugin install session-continuity@snjnlsn-marketplace`.
4. **After structural changes** — `/reload-plugins` note.

**`plugins/local_conf/README.md`** — drop:

- All four skill rows from the Skills table. Drop the Skills table heading entirely and replace the section body with a one-line note: `_No skills — the session-handoff, session-retrospect, handle-callouts, and finalize-branch skills moved to the `session-continuity` plugin._`
- The `handoff-list-recent.sh` and `stop-nudge.sh` rows from the Scripts table.
- The handoff/nudge mentions in the `SessionStart` and `Stop` rows of the Hooks table; those rows now describe only the Serena commands.
- Any prose mentioning the moved skills.

**`README.md` (marketplace root)** — update the plugins table:

- `local_conf` row description: trim to "Personal hooks and helper scripts. Serena auto-approve/activate/cleanup, and `sed -i` guard."
- New `session-continuity` row: "Per-session and per-branch documentation lifecycle: handoffs, callouts, retrospects, and branch finalization. Includes SessionStart context injection and a Stop wrap-up nudge."

### Sweep for stragglers

After the move, run:

```
grep -r "local_conf" plugins/session-continuity/
```

Expected: zero matches. If any remain (other than the documented foo.sh example fix), update them.

## Migration (one-time, manual)

After the change is merged:

1. `/plugin marketplace update @snjnlsn/snjnlsn-marketplace`
2. `/plugin install session-continuity@snjnlsn-marketplace`
3. `/reload-plugins` or restart.
4. Confirm: `session-handoff`, `session-retrospect`, `handle-callouts`, `finalize-branch` skills still appear in the available-skills list. Start a session in a repo with `docs/handoffs/`; confirm the SessionStart context-injection still fires (the recent-handoffs list appears in the SessionStart system reminder).

The existing `local_conf` install updates in place; no uninstall step needed.

## Verification before declaring done

- `grep -r "local_conf" plugins/session-continuity/` returns zero matches.
- `grep -r "session-handoff\|session-retrospect\|handle-callouts\|finalize-branch\|handoff-list-recent\|stop-nudge" plugins/local_conf/` returns zero matches.
- `marketplace.json` has three plugin entries; each `source` resolves to an existing directory.
- All four moved `SKILL.md` files retain valid frontmatter (`name:`, `description:`).
- `plugins/session-continuity/scripts/*.sh` are executable (`ls -l` shows `x` bits — preserved by `git mv`).
- `plugins/session-continuity/scripts/stop-nudge.sh` cache path reads `~/.cache/session-continuity/stop-nudge`.
- A live `/reload-plugins` followed by a fresh session shows the SessionStart recent-handoffs context still injected and the four skills still listed.

## Out of scope (explicit)

- Removing `~/.cache/local_conf/stop-nudge`. Optional cleanup; leave for a later tidy-up.
- Restructuring inside `session-continuity` (no `lib/`, no consolidation of the four skills, no flattening).
- Changes to the `overrides` plugin.
- Changes to the user's global `~/.claude/CLAUDE.md`.
- Generalizing the new plugin for non-personal use (e.g., removing `services@snjnlsn.co`-style references). The plugin remains personal-scoped, consistent with the rest of the marketplace.
- A `local_conf` deprecation period or backwards-compat shim. Single-user marketplace, atomic move.
