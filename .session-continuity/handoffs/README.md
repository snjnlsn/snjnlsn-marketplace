# .session-continuity/handoffs/

This directory is managed exclusively by the `session-continuity` plugin's skills. **Do not read, edit, list, or delete the handoff files directly — route every operation through a skill.**

| Operation | Skill |
|---|---|
| Create / continue / append to the current session's handoff | `session-handoff` |
| Record a finding (discovery, decision, caveat, gotcha, etc.) | `handle-callouts` |
| Read every handoff attributable to the current git branch | `read-branch-handoffs` |
| Reflect at session end (narrative + concrete edits) | `session-retrospect` |
| Harvest callouts into permanent docs and delete the branch's handoffs | `finalize-branch` |

Handoffs are per-session historical records. The newest handoff (by `Last updated`) supersedes older ones for the same work; older handoffs are read-only context, not editable working documents. `finalize-branch` removes the branch's handoffs at merge time.

The directory itself and this README must survive every `finalize-branch` run; only the specific handoff files in the branch's confirmed list are deleted.
