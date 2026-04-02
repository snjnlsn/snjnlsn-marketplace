# my-superpowers

Personal Claude Code skill overlay on top of [superpowers](https://github.com/obra/superpowers).

## Structure

- `skills/` — New skills and overrides of upstream superpowers skills
- `agents/` — Custom agent definitions
- `hooks/` — Custom hooks
- `commands/` — Custom slash commands

## Adding a new skill

1. Create `skills/<name>/SKILL.md`
2. Add frontmatter: `name:` and `description:` fields
3. Write skill content
4. Hot-reloads automatically — no reinstall needed

## Overriding an upstream superpowers skill

1. Copy `~/.claude/plugins/cache/claude-plugins-official/superpowers/<version>/skills/<name>/SKILL.md`
   to `skills/<name>/SKILL.md` in this repo
2. Edit as desired, keeping the same `name:` in frontmatter
3. Hot-reloads automatically

## Installation

### First time setup

1. Add this repo as a marketplace in `~/.claude/settings.json` under `extraKnownMarketplaces`:

```json
"my-superpowers-marketplace": {
  "source": {
    "source": "file",
    "path": "/Users/sanjay/Code/my-superpowers/marketplace.json"
  }
}
```

> Note: the path is machine-specific. Update it if cloning to a different location.

2. Add the plugin to `enabledPlugins`:

```json
"my-superpowers@my-superpowers-marketplace": true
```

3. Run `/reload-plugins` in Claude Code.

### On a new machine

```bash
git clone git@github.com:snjnlsn/my-superpowers.git ~/Code/my-superpowers
# Add marketplace + enabledPlugins entries to ~/.claude/settings.json (update path)
# Run /reload-plugins in Claude Code
```

## After structural changes (new agents, hooks, commands)

Run `/reload-plugins` in Claude Code, or restart.

## Keeping overrides in sync with upstream

Overridden skills do not auto-update when superpowers ships a new version.
To find the currently installed superpowers version:

```bash
ls ~/.claude/plugins/cache/claude-plugins-official/superpowers/
```

Then diff your override against upstream:

```bash
# Replace 5.0.7 with the version shown above
diff skills/<name>/SKILL.md \
  ~/.claude/plugins/cache/claude-plugins-official/superpowers/5.0.7/skills/<name>/SKILL.md
```
