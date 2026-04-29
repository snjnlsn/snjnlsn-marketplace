# snjnlsn marketplace

Personal Claude Code plugin marketplace for me.

## Plugins

| Plugin | Purpose |
|---|---|
| [`overrides`](plugins/overrides/) | Overlays upstream Claude Code plugins — Serena-enabled overrides of `feature-dev` and `superpowers` agents/skills, plus a routing skill that prefers the Serena-enabled variants. |
| [`local_conf`](plugins/local_conf/) | Personal hooks, helper scripts, skills, and slash commands. Includes session-handoff and session-retrospect skills, Serena auto-approval, in-place sed guard, and end-of-session wrap-up nudge. |

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
