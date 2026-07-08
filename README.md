# snjnlsn marketplace

Personal Claude Code and Codex plugin marketplace for me.

## Plugins

| Plugin | Purpose |
|---|---|
| [`overrides`](plugins/overrides/) | Deprecated Superpowers skill copies. Prefer the upstream `superpowers` plugin plus [`snjnlsn-dev-config`](plugins/snjnlsn-dev-config/) `superpowers-caveat` skill. |
| [`snjnlsn-dev-config`](plugins/snjnlsn-dev-config/) | Personal development hooks, helper scripts, `superpowers-caveat`, and `good-quality-code` guidance. |
| [`session-continuity`](plugins/session-continuity/) | Per-session and per-branch documentation lifecycle: handoffs, callouts, retrospects, and branch finalization. Includes SessionStart context injection and a Stop wrap-up nudge. |

## Deprecation note

The copied `overrides` skills are deprecated. The preferred workflow is to use
the upstream `superpowers` skills directly, with
`snjnlsn-dev-config:superpowers-caveat` layered in so agents prefer and adhere
to repo-local instructions and opinionated skills for reading, writing, and
reviewing code.

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
codex plugin marketplace add snjnlsn/snjnlsn-marketplace
```

From local:

```
codex plugin marketplace add $PATH_TO_REPO
```

Then install individual plugins from the Codex plugin UI or marketplace flow.

The Claude catalog remains at `.claude-plugin/marketplace.json`; the two
marketplace formats are intentionally kept side by side.
