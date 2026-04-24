# overrides

Personal Claude Code plugin that customizes and hooks into other Claude Code plugins. Part of the [`snjnlsn-marketplace`](../../README.md).

## What's inside

| Path | Overrides | Purpose |
|---|---|---|
| `agents/code-reviewer.md` | `feature-dev:code-reviewer` | Adds Serena MCP tools + Serena-first system-prompt instruction |
| `agents/code-explorer.md` | `feature-dev:code-explorer` | Adds Serena MCP tools + Serena-first system-prompt instruction |
| `agents/code-architect.md` | `feature-dev:code-architect` | Adds Serena MCP tools + Serena-first system-prompt instruction |
| `skills/using-overrides/` | *standalone* | Routing skill — instructs Claude to prefer any `overrides:` skill/agent over its upstream same-name counterpart, and ensures dispatched `Agent` prompts carry an explicit Serena activation line |
| `skills/systematic-debugging/` | `superpowers:systematic-debugging` | Adds Serena-first guidance to *Trace Data Flow* (`find_referencing_symbols` for backward tracing) and *Find Working Examples* (`get_symbols_overview` / `find_symbol`) |
| `skills/receiving-code-review/` | `superpowers:receiving-code-review` | Rewrites the YAGNI "grep codebase for usage" check to route symbol lookups through Serena's `find_referencing_symbols` |
| `skills/writing-plans/` | `superpowers:writing-plans` | Adds a Serena-first block to *File Structure* covering `get_symbols_overview`, `find_symbol`, and `find_referencing_symbols` for inventorying existing code when planning |
| `skills/brainstorming/` | `superpowers:brainstorming` | Adds a Serena-first bullet to *Working in existing codebases* so design exploration uses symbolic tools over `Read`/`Grep` |
| `skills/hello-overrides/` | *standalone* | Smoke test — confirms the plugin is loaded |

Empty directories (`hooks/`, `commands/`) are kept as `.gitkeep` placeholders for future additions.

## Adding a new override of an upstream skill/agent

1. Find the upstream file in `~/.claude/plugins/cache/claude-plugins-official/<plugin>/<version>/`
2. Copy it to the mirrored location here (e.g. `agents/<name>.md` or `skills/<name>/SKILL.md`)
3. Add a row to the "What's inside" table above documenting which upstream file this overrides and what's different
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
