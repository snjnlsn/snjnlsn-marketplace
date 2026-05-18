# overrides

Personal Claude Code plugin that customizes and hooks into other Claude Code plugins. Part of the [`snjnlsn-marketplace`](../../README.md).

## What's inside

The plugin standardizes on a single **MCP toolkit** (Tidewave + Context7 + Serena) defined canonically in `skills/using-overrides/SKILL.md`. Every other override either references that block (skills loaded into the parent context) or carries a "kept in sync with" copy of it (agents and dispatch prompt templates, which fresh contexts can't load skills into).

### Agents

No agents are currently overridden. As of `superpowers` v5.1.0 the named
`superpowers:code-reviewer` agent was removed upstream; its dispatch persona
now lives in `skills/requesting-code-review/code-reviewer.md` (carrying the
MCP toolkit preamble) and is dispatched via `Task (general-purpose)`.

### Skills

| Path | Overrides | Purpose |
|---|---|---|
| `skills/using-overrides/` | *standalone* | Routing skill **and** canonical home for the MCP toolkit. Tells Claude to prefer any `overrides:` skill/agent over its upstream same-name counterpart, defines the MCP toolkit block referenced by every other override, and specifies the dispatch preamble for fresh subagent prompts |
| `skills/brainstorming/` | `superpowers:brainstorming` | Replaces the upstream's "use Serena for code exploration" bullet with a pointer to the unified MCP toolkit (Tidewave + Context7 + Serena) |
| `skills/writing-plans/` | `superpowers:writing-plans` | Replaces the upstream's "Inventorying existing code" Serena block with a pointer to the unified MCP toolkit, keeping the situational hint that `find_referencing_symbols` is essential for scoping caller-impact |
| `skills/systematic-debugging/` | `superpowers:systematic-debugging` | Points *Trace Data Flow* and *Find Working Examples* at the unified MCP toolkit, including Context7 for verifying dependency behavior before assuming a bug |
| `skills/receiving-code-review/` | `superpowers:receiving-code-review` | Routes the YAGNI "find actual usage" check through the MCP toolkit (Context7 for verifying a dependency's API before pushing back, Serena for source when docs leave you unsure) |
| `skills/requesting-code-review/` | `superpowers:requesting-code-review` | Inlines the canonical MCP toolkit preamble into `code-reviewer.md` so any subagent dispatched against the template (including SDD's code-quality reviewer step) inherits the MCP guidance without the dispatcher having to paste it |
| `skills/subagent-driven-development/` | `superpowers:subagent-driven-development` | Adds scope discipline (>2 files beyond plan = STOP) and golden-file immutability rules to the implementer prompt, allows trivial inline fixes by the code-quality reviewer with explicit guards, and pastes the MCP toolkit preamble into the implementer/spec-reviewer dispatch templates so fresh subagents reach for the right tools |
| `skills/test-driven-development/` | `superpowers:test-driven-development` | Adds an MCP-toolkit pointer for locating the symbol under test, scoping caller impact (`find_referencing_symbols`), and verifying dependency behavior at runtime via Tidewave's `project_eval` instead of speculative `iex` snippets |
| `skills/dispatching-parallel-agents/` | `superpowers:dispatching-parallel-agents` | Reinforces that every dispatched subagent prompt for code work must paste the **MCP toolkit (canonical)** block (or reuse one of the override prompt templates) so parallel agents don't silently fall back to generic tools |
| `skills/executing-plans/` | `superpowers:executing-plans` | Adds the MCP-toolkit pointer for code-touching steps; defensive override for runs on harnesses without subagent support |
| `skills/verification-before-completion/` | `superpowers:verification-before-completion` | Augments the iron-law "run the verification command" guidance with Tidewave-specific verification surfaces (`get_logs` for ignored warnings, `project_eval` for runtime-confirming a claim, `execute_sql_query` for DB-side effects) |
| `skills/hello-overrides/` | *standalone* | Smoke test — confirms the plugin is loaded |

### Prompt templates (a third kind of override)

Override-shipped prompt templates that the *dispatcher* pastes into subagent prompts (rather than skills the subagent itself loads):

- `skills/subagent-driven-development/implementer-prompt.md` — inlines the MCP toolkit preamble
- `skills/subagent-driven-development/spec-reviewer-prompt.md` — inlines the MCP toolkit preamble
- `skills/subagent-driven-development/code-quality-reviewer-prompt.md` — dispatches `Task (general-purpose)` against `overrides:requesting-code-review/code-reviewer.md` (which carries the preamble); adds SDD-specific check bullets and a "trivial inline fixes" allowance with guards
- `skills/requesting-code-review/code-reviewer.md` — inlines the MCP toolkit preamble; reused by SDD's code-quality reviewer step and any other code-review dispatch

Each preamble-bearing template is marked "kept in sync with `overrides:using-overrides`" so drift is detectable on review.

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
