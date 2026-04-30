---
description: Finalize a feature branch — audit and update inline code docs and project docs, remove the branch's handoffs, produce one final commit
---

Use the `finalize-branch` skill to walk the end-of-branch pipeline. The skill is interactive throughout: it runs pre-flight + branch health checks, audits the branch's handoffs and changes, asks clarifying questions, proposes inline code doc and project doc updates with per-item approval, deletes the branch's handoff documents, and produces one final commit.

If the user passed arguments after `/finalize-branch`, treat them as additional context or instructions for the skill (e.g., "finalize this branch, skip the docs update for X"). Otherwise just hand control to the skill.
