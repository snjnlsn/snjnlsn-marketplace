# snjnlsn marketplace

Personal Claude Code plugin marketplace for me.

## Plugins

| Plugin | Purpose |
|---|---|
| [`overrides`](plugins/overrides/) | MCP-enabled overrides (Tidewave/Serena/HexDocs/Context7) of `superpowers` agents/skills, plus a routing skill that prefers the MCP-enabled variants. |
| [`local_conf`](plugins/local_conf/) | Personal hooks and helper scripts. Serena auto-approve/activate/cleanup, and `sed -i` guard. |
| [`session-continuity`](plugins/session-continuity/) | Per-session and per-branch documentation lifecycle: handoffs, callouts, retrospects, and branch finalization. Includes SessionStart context injection and a Stop wrap-up nudge. |

## Install

From GitHub:

```
/plugin marketplace add @snjnlsn/snjnlsn-marketplace
```

From local:

```
/plugin marketplace add $PATH_TO_REPO/
```

Then install individual plugins via `/plugin install <name>@snjnlsn-marketplace`.
