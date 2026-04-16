# Rename `superpowers-override` → `overrides`

**Date:** 2026-04-16
**Status:** Approved — ready for implementation plan

## Problem

The `superpowers-override` plugin in this marketplace is named after a single upstream target (`superpowers`), but it is now used to override and hook into other Claude Code plugins too. The name is misleading, and the plugin's README, description, and internal framing are all scoped too narrowly.

## Goal

Rename the plugin to `overrides` and reframe it as a personal overlay that customizes and hooks into any Claude Code plugin — not just `superpowers`. Do a small round of cleanup in the same refactor.

## Non-Goals

- No changes to the behavior of any skill, agent, hook, or command. Names, paths, and framing only.
- No restructuring of files beyond the directory rename (no grouping by upstream plugin).
- No changes to the user's global `~/.claude/CLAUDE.md` (verified: no references to `superpowers-override` there today).
- No changes to the `snjnlsn-marketplace` repo or marketplace name itself — only the plugin inside it.

## Design

### Final file layout

```
snjnlsn-marketplace/
├── .claude-plugin/marketplace.json       # name: overrides, source: ./plugins/overrides
└── plugins/
    └── overrides/                         # (was: superpowers-override/)
        ├── .claude-plugin/plugin.json     # name: overrides, version 1.1.0
        ├── README.md                      # rewritten
        ├── agents/
        │   ├── code-reviewer.md           # agent ID: overrides:code-reviewer
        │   ├── code-explorer.md           # agent ID: overrides:code-explorer
        │   └── code-architect.md          # agent ID: overrides:code-architect
        ├── skills/
        │   ├── hello-overrides/SKILL.md   # renamed from hello-overlay
        │   └── use-serena-agents/SKILL.md
        ├── hooks/.gitkeep
        └── commands/.gitkeep
```

### Content changes by file

**`.claude-plugin/marketplace.json`**
- `plugins[0].name`: `superpowers-override` → `overrides`
- `plugins[0].source`: `./plugins/superpowers-override` → `./plugins/overrides`
- `plugins[0].description`: broadened to "Personal plugin overrides — customizes and hooks into other Claude Code plugins."

**`plugins/overrides/.claude-plugin/plugin.json`**
- `name`: `superpowers-override` → `overrides`
- `description`: broadened to "Personal plugin overrides — customizes and hooks into other Claude Code plugins."
- `version`: `1.0.0` → `1.1.0` (minor: rename + scope change, no behavioral break for new installs)

**`plugins/overrides/agents/*.md` (3 files)**
- No frontmatter changes — agent file frontmatter doesn't carry the plugin name.
- Add one-line header comment above frontmatter to self-document the upstream target, e.g.:
  ```
  <!-- Overrides: feature-dev:code-reviewer (adds Serena tools to allowlist) -->
  ```

**`plugins/overrides/skills/hello-overrides/SKILL.md`** (renamed from `hello-overlay`)
- Directory renamed via `git mv`
- `name:` frontmatter: `hello-overlay` → `hello-overrides`
- `description:` and body text updated from "my-superpowers overlay plugin" to "overrides overlay plugin"

**`plugins/overrides/skills/use-serena-agents/SKILL.md`**
- Every mention of `superpowers-override` → `overrides`, including:
  - The "superpowers-override plugin ships mirror agents" paragraph
  - The routing table's `subagent_type` column: `superpowers-override:code-explorer` → `overrides:code-explorer`, and likewise for `code-architect` and `code-reviewer`
  - The "Why this exists" section wording
- `description:` frontmatter updated to match the new name without changing the skill's behavior.

**`plugins/overrides/README.md`** — rewritten around the "plugin overrides" framing. Sections:
1. **What this is** — personal overrides plugin; customizes/hooks into other Claude Code plugins.
2. **What's inside** — small table: path → what upstream it targets (or "standalone" if greenfield).
3. **Adding a new override** — steps for overriding an upstream skill/agent/hook/command.
4. **Adding a new standalone skill/agent** — steps for greenfield additions.
5. **Installation** — including a migration note for users on the old `superpowers-override` name.
6. **Keeping overrides in sync with upstream** — existing `diff` instructions, generalized away from `superpowers`-specific paths.

**`.gitignore`** (new, at repo root)
- Add `.DS_Store`. Remove tracked `.DS_Store` files from the index.

### Git strategy

Three sequential commits so history stays easy to bisect/revert:

1. **`rename: superpowers-override → overrides`**
   - `git mv plugins/superpowers-override plugins/overrides`
   - `git mv plugins/overrides/skills/hello-overlay plugins/overrides/skills/hello-overrides`
   - Update **name references only** in: `marketplace.json` (`name`, `source`), `plugin.json` (`name`), `SKILL.md` frontmatter and bodies, hello smoke-test body. Descriptions are *not* touched in this commit — they move in commit 2.
   - Invariant at end of this commit: grep for `superpowers-override`, `my-superpowers`, `hello-overlay` returns zero matches outside `.git/` and `docs/superpowers/specs/` (the design doc is allowed to reference the old names as history).

2. **`chore: broaden scope framing and rewrite README`**
   - `plugin.json` and `marketplace.json` `description` field changes.
   - `plugin.json` `version` bump: `1.0.0` → `1.1.0`.
   - `README.md` rewrite around the new framing.
   - Add `<!-- Overrides: ... -->` header comments to the three agent files.

3. **`chore: ignore .DS_Store`**
   - Add `.gitignore`.
   - `git rm --cached` any tracked `.DS_Store` files.

### User migration (one-time, manual, documented in the new README)

1. `/plugin uninstall superpowers-override@snjnlsn-marketplace`
2. `/plugin marketplace update @snjnlsn/snjnlsn-marketplace` (or remove + re-add if the update doesn't pick up the rename)
3. `/plugin install overrides@snjnlsn-marketplace`
4. `/reload-plugins` or restart
5. Run `/hello-overrides` as smoke test — should print the overlay-loaded message.

### Verification before declaring done

- `grep -r "superpowers-override\|my-superpowers\|hello-overlay" .` returns zero matches outside `.git/` and `docs/superpowers/specs/`.
- `.claude-plugin/marketplace.json`'s `source` path resolves to an existing directory.
- All `SKILL.md` and agent `.md` files retain valid frontmatter with `name:` and `description:` fields.
- `hello-overrides` skill's `name:` matches its directory name.
- No tracked `.DS_Store` files remain (`git ls-files | grep DS_Store` returns empty).

## Out of scope (explicit)

- Not editing global `~/.claude/CLAUDE.md` (verified clean today).
- Not restructuring files into per-upstream subdirectories (Approach 2 from brainstorm, rejected as premature).
- Not changing the `snjnlsn-marketplace` repo name or marketplace identifier.
- Not touching any skill/agent behavior — if an override misbehaves, that's a separate task.
