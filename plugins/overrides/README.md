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
