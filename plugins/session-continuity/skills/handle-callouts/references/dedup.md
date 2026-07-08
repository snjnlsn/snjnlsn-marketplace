# Callout Dedup

Run this before writing a new callout to the working handoff.

## Scope

Scan only the working handoff. Cross-handoff dedup belongs to `finalize-branch`.

Check callout-shaped headings under `## Callouts` and inline under other sections.

## Match Signals

- Heading text match: lowercase, collapse whitespace, strip leading numbering.
- Body substance match: existing body already covers the new finding, even if the heading differs.

## Outcomes

- Existing still correct, no new info: flag as redundant; no update needed.
- Existing correct, new info adds detail: draft a body that folds both together.
- Existing partially wrong or superseded: draft a replacement body, and revise heading if it misframes the finding.
- Existing contradicts the new finding: draft a body that preserves the original reasoning and states the new conclusion.

Prompt with the drafted update visible:

- apply update
- replace with new and drop existing
- write new separately
- skip

Resolution-only callouts skip this flow; `finalize-branch` handles their cluster at branch end.
