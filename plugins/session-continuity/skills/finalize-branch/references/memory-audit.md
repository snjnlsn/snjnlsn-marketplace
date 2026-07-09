# Serena Memory Audit

Load this reference for Phase 2 of `finalize-branch` before comparing handoffs and branch facts with current code.

## Relevance Workflow

1. Call `list_memories`.
2. Build branch topics from changed paths and symbols, changed docs, handoff claims, and branch facts.
3. If `core` exists, read it first. Use its topics and `mem:` references as the primary map from branch topics to other memories.
4. Read only mapped memories whose topics could affect the branch audit.
5. If `core` is absent, incomplete, unreadable, or does not cover a branch topic, compare that topic with the remaining memory names and read only likely matches.

Do not read every memory by default. If a referenced memory cannot be read, record the limitation and continue with available evidence.

## Authority and Availability

Treat memories as project context to verify against current code, tests, and repo docs. Current project evidence wins when it conflicts with memory. Applicable memory guidance may support a proposal when it does not conflict with current evidence; syntactic validity of a current annotation is not, by itself, a conflict with a more specific project convention.

If Serena memory tools are unavailable, do not inspect memory storage directly. Report that memory context was unavailable and continue. If no memories exist or none are relevant, report that briefly and continue.

## Audit Summary

Include:

- names of memories read
- count of memories skipped as irrelevant; name individual memories only when a name explains a decision or limitation
- unavailable or unreadable memory context
- memory guidance that affects a handoff, branch-fact, inline-doc, repo-doc, or annotation proposal
