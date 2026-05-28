# snjnlsn marketplace

Personal Claude Code and Codex plugin marketplace for me.

## Plugins

| Plugin | Purpose |
|---|---|
| [`overrides`](plugins/overrides/) | MCP-enabled overrides (Tidewave/Context7/Serena) of `superpowers` agents/skills, plus a routing skill that prefers the MCP-enabled variants. |
| [`local_conf`](plugins/local_conf/) | Personal hooks and helper scripts. Serena auto-approve/activate/cleanup, and `sed -i` guard. |
| [`session-continuity`](plugins/session-continuity/) | Per-session and per-branch documentation lifecycle: handoffs, callouts, retrospects, and branch finalization. Includes SessionStart context injection and a Stop wrap-up nudge. |

## Install

### Claude Code

From GitHub:

```
/plugin marketplace add @snjnlsn/snjnlsn-marketplace
```

From local:

```
/plugin marketplace add $PATH_TO_REPO/
```

Then install individual plugins via `/plugin install <name>@snjnlsn-marketplace`.

### Codex

This repo also ships a Codex marketplace catalog at
`.agents/plugins/marketplace.json`, plus `.codex-plugin/plugin.json` manifests
inside each plugin.

From GitHub:

```
codex plugin marketplace add github:snjnlsn/snjnlsn-marketplace
```

From local:

```
codex plugin marketplace add $PATH_TO_REPO
```

Then install individual plugins from the Codex plugin UI or marketplace flow.

The Claude catalog remains at `.claude-plugin/marketplace.json`; the two
marketplace formats are intentionally kept side by side.
