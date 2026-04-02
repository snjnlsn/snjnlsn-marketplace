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

1. Install the marketplace in claude code
   `/plugin marketplace add @snjnlsn/snjnlsn-marketplace`

2. Install the plugin
   `/plugin install superpowers-override@snjnlsn-marketplace`

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
