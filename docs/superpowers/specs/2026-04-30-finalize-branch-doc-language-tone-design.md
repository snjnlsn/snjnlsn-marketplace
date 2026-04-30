# Finalize-branch: documentation language and tone guidance

## Context

The `finalize-branch` skill (`plugins/local_conf/skills/finalize-branch/SKILL.md`) drives two phases that produce written content:

- **Phase 2 — Inline code documentation.** Generates `@moduledoc`/`@doc`/docstring/JSDoc proposals.
- **Phase 3 — Architecture, business-logic, README, CLAUDE.md.** Generates prose edits to `docs/`, `README.md`, and `CLAUDE.md`.

The skill currently says nothing about *how* that prose should read. This is a preventive change: lock in language/tone guidance before the skill produces output that drifts toward marketing voice, narrating-the-obvious, or the other tells that signal "an LLM wrote this."

Out of scope: Phase 4's commit message (already constrained by a fixed template) and any change to the phase pipeline itself.

## Design

### Placement

A single canonical "Documentation language and tone" block lives near the top of `SKILL.md`, with one-line pointers from each consuming phase. This mirrors the pattern used by `overrides:using-overrides` for the MCP toolkit block — single source of truth, no drift, but visible at the moment of use.

- **New top-level section** `## Documentation language and tone`, slotted between `## Source-of-truth precedence` and `## Halt and exit messaging`. Both neighbors are "principles that govern downstream phases," so the section fits the existing structure.
- **Pointer at the top of `## Phase 2 — Inline code documentation`**, before "Step 1".
- **Pointer at the top of `## Phase 3 — Architecture, business-logic, README, CLAUDE.md`**, before "Working surface".

### Content of the shared section

Verbatim text to insert:

> ## Documentation language and tone
>
> Phases 2 and 3 produce written content. Apply these rules to every proposed `@moduledoc`/`@doc`/docstring/JSDoc and every prose edit to `docs/`/`README.md`/`CLAUDE.md`.
>
> **Match the surrounding voice.** Before drafting, sample 2–3 nearby docs of the same kind — for inline docs, other `@moduledoc`s/`@doc`s in the same file or sibling modules; for project docs, other entries in the same `docs/` subdirectory or other sections of the same file. Mirror their register: terseness, sentence length, headings vs. prose, presence/absence of examples. The doc should read as if the same person wrote it.
>
> **Anti-patterns** — these signal "an LLM wrote this" regardless of project voice. Avoid in every proposal:
>
> - **Marketing adjectives** — "seamless(ly)", "powerful", "robust", "elegant", "blazing", "simply", "easily", "effortless", "comprehensive". Cut them; the claim either survives without the adjective or shouldn't be made.
> - **Narrating the obvious** — "The `Foo` module is a module that handles foo." / "This function takes a user and returns a user." Lead with WHY/WHEN a caller reaches for it, not WHAT it does syntactically; the signature already says what.
> - **Referencing the change/PR/branch** — "As part of this change…", "Recently added…", "This PR introduces…". Docs describe the current state of the code, not the journey to it.
> - **Filler and hedges** — "In order to" → "to"; drop "It should be noted that…", "Please note", "It is important to", "Currently…". (Genuine counter-intuitive caveats are a separate case — flag them when they exist.)
> - **Restating the symbol name** — "`Acme.Users.invite/2` is a function that invites users." The reader already sees the name; spend the sentence on the meaningful part.
> - **Future-tense aspiration** — "This will eventually support…". If it's not implemented, don't document it.
> - **Editorial self-praise** — "This elegant solution…", "An efficient approach…". Let the code earn the adjective.
>
> **Per-surface notes:**
>
> - **`@moduledoc`** — one to three sentences on the module's responsibility and when a caller would reach for it. Skip if the module name plus public function list already make it obvious and no project convention requires one.
> - **`@doc`** — describe the contract: what the function does for the caller, important constraints, non-obvious return shape. Add examples only when they meaningfully clarify; don't pad with doctests.
> - **`@spec`** — propose only when the type is unambiguous. Never invent. (Already stated in Phase 2; restated here for completeness.)
> - **README / architecture docs** — when *updating*, change the smallest span of text that addresses the new fact; don't rewrite surrounding paragraphs for style. When *creating*, sample the existing `docs/` voice first.
>
> When in doubt, prefer a shorter doc over a more thorough one. Edits that *reduce* word count without losing information are usually correct.

### Pointers in each phase

Inserted as the first line of each phase's body, before any sub-heading:

- **Phase 2:** `Apply §Documentation language and tone to every proposed @moduledoc / @doc / docstring / JSDoc.`
- **Phase 3:** `Apply §Documentation language and tone to every proposed prose edit. The "match the surrounding voice" rule matters most here — docs/ files often have an established register that new prose must fit.`

### Resolved decisions during brainstorm

- **Scope:** Phase 2 + Phase 3. Phase 4's commit message stays out — it's already template-constrained.
- **Structure:** Hybrid — one canonical block plus per-phase pointers. (Same pattern as `overrides:using-overrides`.)
- **Direction:** "Match the surrounding voice" + universal anti-patterns, rather than a fixed prescriptive voice. The skill ships in a marketplace plugin and runs across many projects with different existing styles; pinning a voice would fight some codebases.
- **`Note that…` exclusion:** Dropped from the filler bullet. Genuine counter-intuitive caveats sometimes need explicit acknowledgment; the "match surrounding voice" rule and "shorter is usually correct" closer keep the use bounded.
- **`@spec` duplication:** Phase 2 says "never fabricate types where inference is unclear." This section restates it for completeness in the per-surface notes. Both stay.

## Files affected

- `plugins/local_conf/skills/finalize-branch/SKILL.md` — add the new section and the two pointers. No other changes.

## Out of scope

- Changes to Phase 0, 1, or 4.
- Restructuring existing Phase 2/3 steps.
- Updating the `local_conf` plugin version, README, or other downstream files (the skill body is self-contained; bump the version when actually shipping if that matches your release rhythm, but it's not part of this design).
- Updating the existing `2026-04-30-finalize-branch-skill-design.md` retroactively. This design stands on its own as a follow-up.
