# Callout Edge Cases

- Multiple callouts in one trigger: handle each as a separate authoring flow.
- User asks for an unsupported type: suggest the closest allowed keyword or ask them to choose.
- Working handoff missing: invoke `session-handoff` to create or rediscover a current-session handoff, then retry.
- Reading an old handoff: do not write there. Capture new callouts in the current session handoff.
- Conversation loses the working handoff path: invoke `session-handoff` to rediscover or ask.
- Reversing a resolution: remove the marker if it is in the working handoff, or write a new active callout if the only current record is resolution-only.
- Resolution-only callout has no older match: warn that `finalize-branch` will not count it as resolving an active callout unless a cluster match exists.
- Resolving a Discovery, Decision, or Lesson learned is allowed; `finalize-branch` will drop explicit resolved markers even when its heuristic would not infer resolution.
