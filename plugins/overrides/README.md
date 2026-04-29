# overrides

Personal Claude Code plugin that customizes and hooks into other Claude Code plugins. Part of the [`snjnlsn-marketplace`](../../README.md).

## What's inside

The plugin standardizes on a single **MCP toolkit** (Serena + HexDocs + Context7) defined canonically in `skills/using-overrides/SKILL.md`. Every other override either references that block (skills loaded into the parent context) or carries a "kept in sync with" copy of it (agents and dispatch prompt templates, which fresh contexts can't load skills into).

### Agents

| Path | Overrides | Purpose |
|---|---|---|
| `agents/code-reviewer.md` | `feature-dev:code-reviewer` | MCP toolkit in tool allowlist + system prompt; replaces `feature-dev:code-reviewer` for review-style dispatches |
| `agents/code-explorer.md` | `feature-dev:code-explorer` | MCP toolkit in tool allowlist + system prompt; replaces `feature-dev:code-explorer` for exploration-style dispatches |
| `agents/code-architect.md` | `feature-dev:code-architect` | MCP toolkit in tool allowlist + system prompt; replaces `feature-dev:code-architect` for architecture-design dispatches |

### Skills

| Path | Overrides | Purpose |
|---|---|---|
| `skills/using-overrides/` | *standalone* | Routing skill **and** canonical home for the MCP toolkit. Tells Claude to prefer any `overrides:` skill/agent over its upstream same-name counterpart, defines the MCP toolkit block referenced by every other override, and specifies the dispatch preamble for fresh subagent prompts |
| `skills/brainstorming/` | `superpowers:brainstorming` | Replaces the upstream's "use Serena for code exploration" bullet with a pointer to the unified MCP toolkit (Serena + HexDocs + Context7) |
| `skills/writing-plans/` | `superpowers:writing-plans` | Replaces the upstream's "Inventorying existing code" Serena block with a pointer to the unified MCP toolkit, keeping the situational hint that `find_referencing_symbols` is essential for scoping caller-impact |
| `skills/systematic-debugging/` | `superpowers:systematic-debugging` | Points *Trace Data Flow* and *Find Working Examples* at the unified MCP toolkit, including HexDocs/Context7 for verifying dependency behavior before assuming a bug |
| `skills/receiving-code-review/` | `superpowers:receiving-code-review` | Routes the YAGNI "find actual usage" check through the MCP toolkit (Serena for symbols, HexDocs/Context7 for verifying a dependency's API before pushing back) |
| `skills/subagent-driven-development/` | `superpowers:subagent-driven-development` | Adds scope discipline (>2 files beyond plan = STOP) and golden-file immutability rules to the implementer prompt, allows trivial inline fixes by the code-quality reviewer with explicit guards, and pastes the MCP toolkit preamble into all three dispatch templates so fresh subagents reach for the right tools |
| `skills/hello-overrides/` | *standalone* | Smoke test — confirms the plugin is loaded |

### Prompt templates (a third kind of override)

The `subagent-driven-development` override ships three reusable prompt templates that the *dispatcher* pastes into subagent prompts (rather than skills the subagent itself loads):

- `skills/subagent-driven-development/implementer-prompt.md`
- `skills/subagent-driven-development/spec-reviewer-prompt.md`
- `skills/subagent-driven-development/code-quality-reviewer-prompt.md`

Each leads with the MCP toolkit preamble and is marked "kept in sync with `overrides:using-overrides`" so drift is detectable on review.

Empty directories (`hooks/`, `commands/`) are kept as `.gitkeep` placeholders for future additions.

## Adding a new override of an upstream skill/agent

1. Find the upstream file in `~/.claude/plugins/cache/claude-plugins-official/<plugin>/<version>/`
2. Copy it (and any sibling support files — prompt templates, references) to the mirrored location here (e.g. `agents/<name>.md` or `skills/<name>/SKILL.md`)
3. Add a row to the "What's inside" table above documenting which upstream file this overrides and what's different
4. Edit as desired, keeping the same `name:` in frontmatter
5. **MCP guidance:** reference `overrides:using-overrides`'s **MCP toolkit (canonical)** block by name from skill bodies; for agents and any subagent-dispatch prompt templates, paste the block inline with a "kept in sync with" comment (since fresh contexts don't load skills). Do not paraphrase
6. Hot-reloads automatically — no reinstall needed

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
