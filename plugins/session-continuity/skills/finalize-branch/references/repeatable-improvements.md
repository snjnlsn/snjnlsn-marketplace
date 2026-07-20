# Repeatable Improvements

Load this reference after the branch-facts audit and before documentation proposals.

## Evidence

Review confirmed handoffs, callout decisions, the branch diff, commit history, review fixes, and test or lint changes. Look for:

- the same cleanup performed in multiple places;
- a convention newly established or made explicit by the branch;
- a mistake that recurred or required non-obvious investigation;
- review feedback that should apply beyond the touched code;
- a manual check that could reliably prevent the same defect.

Normally require two independent examples or corrections. A single instance qualifies only when corroborated by an existing convention or when tests, callers, or review evidence demonstrate a high-cost class of likely future occurrences. Verify every candidate against current code and existing instructions, skills, formatter, lint, and Credo configuration.

## Choose The Enforcement Surface

Use the narrowest durable mechanism that can prevent recurrence:

- **Static code or Credo rule** when a violation is mechanically detectable with low false-positive risk. Prefer configuring an existing rule before proposing a custom check.
- **Agent instruction** for a concise project-wide constraint or decision rule that requires judgment but should apply to most future work. Put it in the nearest applicable `AGENTS.md`, `CLAUDE.md`, or equivalent project instruction surface.
- **Skill update or new skill** for a reusable multi-step workflow, specialized technique, or decision process. Update an existing skill when it already owns the trigger; create a skill only when the behavior has a distinct trigger and enough substance to justify one.

Do not duplicate the same rule across surfaces. Static enforcement wins over prose for mechanical constraints; project instructions win over skills for project-specific conventions; skills win for reusable workflows spanning projects.

## Proposal Gate

Present one candidate at a time with:

- evidence from the handoff or branch;
- why recurrence is plausible and consequential;
- the proposed enforcement surface and exact target;
- a concise proposed rule or check;
- alternatives considered, including any existing mechanism that may already cover it.

Recommend `dismiss` when evidence is incidental, already enforced, obsolete, or specific to this branch. The user may mark each candidate already captured, route it to ordinary docs, queue a follow-up, request an exact proposal, revise it, or dismiss it. Require a routing decision before handoff deletion; routing does not authorize implementation.

After the user requests a proposal, show the exact instruction, skill, configuration, or code diff and obtain separate approval before applying it. Default new skills and custom static checks to a queued follow-up because they can materially expand branch scope. Queued follow-ups must contain enough standalone evidence and acceptance criteria to survive handoff deletion.

Apply only approved changes. Run focused validation for every changed instruction or skill. For static rules, test representative violating and compliant examples and run the relevant lint suite.

If no candidate meets the threshold, report that explicitly and continue. Summarize implemented, queued, already captured, documented, and dismissed candidates; do not carry deferred or dismissed candidates into permanent docs by default.
