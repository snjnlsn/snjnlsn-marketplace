# Session-Handoff Callout Delegation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the dedup-alignment gap left by PR #7. `session-handoff`'s safety-net path delegates callout writes to `handle-callouts` via the Skill tool, so dedup runs at every callsite that writes a callout.

**Architecture:** Markdown-only edits across two SKILL.md files plus a plugin version bump. `session-handoff/SKILL.md` gets a new Step 0 in its `### Append to existing handoff` flow that delegates whenever content matches any of `handle-callouts`' triggers. The duplicated callout format spec in `session-handoff/SKILL.md`'s `## Callouts: discoveries, decisions, caveats` section is slimmed to a pointer + the placement guidance. `handle-callouts/SKILL.md`'s `## Coordination with session-handoff` section is rewritten to reflect the delegation model. No code, no scripts.

**Tech Stack:** Markdown for SKILL.md edits. JSON for `plugin.json` version bump.

**Spec:** `docs/superpowers/specs/2026-04-30-session-handoff-callout-delegation-design.md`

---

## File structure

**Modify:**
- `plugins/local_conf/skills/session-handoff/SKILL.md` — add `### Append to existing handoff` Step 0; replace `## Callouts: discoveries, decisions, caveats` body; update one bullet in `## Routing content to the right section`.
- `plugins/local_conf/skills/handle-callouts/SKILL.md` — replace the `## Coordination with session-handoff` section body.

**Bump:**
- `plugins/local_conf/.claude-plugin/plugin.json` — version `1.6.0` → `1.7.0`.

**Test approach:** No automated harness (skills are markdown). Each task ends with a Read-based structural verification. A final manual smoke test in Task 6 exercises delegation in a fresh Claude Code session.

---

### Task 1: Add Step 0 (callout delegation) to session-handoff's append flow

**Files:**
- Modify: `plugins/local_conf/skills/session-handoff/SKILL.md` — `### Append to existing handoff` subsection.

The current `### Append to existing handoff` subsection has three numbered steps. We prepend a Step 0 that delegates callout-shaped content to `handle-callouts`.

- [ ] **Step 1: Read the current section to verify the anchor**

Use the `Read` tool on `plugins/local_conf/skills/session-handoff/SKILL.md` with `offset: 167, limit: 8`. Confirm the content matches the `old_string` block in step 2. Line numbers may have drifted; if so, locate `### Append to existing handoff` by heading and re-anchor.

- [ ] **Step 2: Apply the edit**

Use the `Edit` tool on `plugins/local_conf/skills/session-handoff/SKILL.md`:

- old_string:

  ````
  ### Append to existing handoff

  1. Use Read to load the file.
  2. Use Edit to splice content into the appropriate section (Summary, Work done, Open questions / next steps, Retrospective).
  3. Use Edit to refresh the "Last updated" timestamp.
  ````

- new_string:

  ````
  ### Append to existing handoff

  0. **Callout delegation.** If the content matches any trigger in `handle-callouts/SKILL.md`'s `## When to use` section (callout-shaped headings, callout-worthy findings, and — once the resolution-detection spec ships — resolution-shaped phrases), invoke `handle-callouts` via the Skill tool and stop. The remaining steps handle non-callout content only.
  1. Use Read to load the file.
  2. Use Edit to splice content into the appropriate section (Summary, Work done, Open questions / next steps, Retrospective).
  3. Use Edit to refresh the "Last updated" timestamp.
  ````

- [ ] **Step 3: Verify**

Re-Read the section. Confirm Step 0 appears with the delegation language, the existing three steps remain unchanged, and no surrounding text was disturbed.

- [ ] **Step 4: Commit**

```bash
git add plugins/local_conf/skills/session-handoff/SKILL.md
git commit -m "session-handoff: delegate callout writes to handle-callouts via Step 0"
```

---

### Task 2: Slim the duplicated `## Callouts: discoveries, decisions, caveats` section

**Files:**
- Modify: `plugins/local_conf/skills/session-handoff/SKILL.md` — `## Callouts: discoveries, decisions, caveats` section.

The current section duplicates `handle-callouts`' format spec (keyword list, heading examples, when-to-write guidance). Replace with a pointer + the placement guidance (which remains relevant for both skills).

The section heading `## Callouts: discoveries, decisions, caveats` stays unchanged (per Spec A's Out-of-scope clause: "Renaming of `session-handoff`'s `## Callouts` section." — explicitly out of scope).

- [ ] **Step 1: Read the current section**

Use `Read` on `plugins/local_conf/skills/session-handoff/SKILL.md` with `offset: 99, limit: 42`. Confirm the section spans from `## Callouts: discoveries, decisions, caveats` through the final paragraph before `## Behaviors` (the `Title by the *finding*…` line).

- [ ] **Step 2: Apply the replacement**

Use the `Edit` tool on `plugins/local_conf/skills/session-handoff/SKILL.md`:

- old_string:

  ````
  ## Callouts: discoveries, decisions, caveats

  When the session produces a finding worth surfacing across sessions or sending to a permanent home (project doc, inline `@doc`), record it as a **callout heading** — not a bullet. The `finalize-branch` skill harvests these at branch end and routes them to inline code docs or project docs; bullets in `## Work done` are not harvested.

  ### Format

  A callout is a Markdown heading at any level (typically `###`) whose first words match one of the supported keywords (case-insensitive), optionally followed by a number, then a separator (`—`, `-`, `:`), then a title:

  - `Discovery` / `Discoveries`
  - `Decision` / `Decisions`
  - `Caveat` / `Caveats`
  - `Gotcha` / `Gotchas`
  - `Lesson learned` / `Lessons learned`
  - `Known issue` / `Known issues`
  - `Complexity` / `Complexities`
  - `Edge case` / `Edge cases`

  These all match:

  - `### Discovery — JWT clock skew tolerance varies by platform`
  - `### Discovery 4 — JWT clock skew tolerance varies by platform`
  - `#### Decision: drop legacy session middleware`
  - `### Edge cases — empty input handling`
  - `### Known issues` (bare, no title)

  The body is everything under the heading until the next heading. Write it in normal session voice — `finalize-branch` rewrites callout bodies atemporally when routing to a permanent home, so don't pre-strip "during this session" or "we found that".

  ### Where callouts live in the handoff

  Two valid placements; `finalize-branch` harvests both:

  - **Inline under an existing section** — e.g., `### Discovery 2 — …` inside `## Work done`. Use when the callout is tied to that section's narrative.
  - **In a dedicated `## Callouts` section** at the top of the body. Use when there are multiple cross-cutting findings.

  Do **not** name a parent section with a bare callout keyword (e.g. `## Discoveries`, `## Decisions`, `## Caveats`). Those headings themselves match the callout pattern, so the whole section body would be harvested as a single callout. `## Callouts` is safe — it's not on the keyword list.

  ### When to write one

  When the user says "this is a discovery", "save this as a decision", "that caveat needs to land somewhere", or describes a finding that a future session — or the eventual reader of a project doc — would want without re-deriving it. Proactively recognize callout-worthy moments: a non-obvious behavior just confirmed, a deliberate trade-off, a constraint that surprised the session. Ask before writing if the framing isn't clear.

  Title by the *finding*, not the *task* — `### Discovery — JWT clock skew tolerance varies by platform`, not `### Discovery — investigated JWT auth`.
  ````

- new_string:

  ````
  ## Callouts: discoveries, decisions, caveats

  `handle-callouts` is the primary author for any callout — discoveries, decisions, caveats, gotchas, lessons learned, known issues, complexities, edge cases. See its SKILL.md for the keyword list, heading format, dedup logic, and authoring flow. The `### Append to existing handoff` flow's Step 0 delegates callout writes to it.

  ### Where callouts live in the handoff

  Two valid placements; `finalize-branch` harvests both:

  - **Inline under an existing section** — e.g., `### Discovery 2 — …` inside `## Work done`. Use when the callout is tied to that section's narrative.
  - **In a dedicated `## Callouts` section** at the top of the body. Use when there are multiple cross-cutting findings.

  Do **not** name a parent section with a bare callout keyword (e.g. `## Discoveries`, `## Decisions`, `## Caveats`). Those headings themselves match the callout pattern, so the whole section body would be harvested as a single callout. `## Callouts` is safe — it's not on the keyword list.
  ````

- [ ] **Step 3: Verify**

Re-Read the section. Confirm:
- Heading is unchanged (`## Callouts: discoveries, decisions, caveats`).
- The body is now ~12 lines, opens with the pointer to `handle-callouts`, and keeps the `### Where callouts live in the handoff` subsection verbatim.
- The dropped subsections (`### Format`, `### When to write one`) are gone.
- The next section (`## Behaviors`) immediately follows.

- [ ] **Step 4: Commit**

```bash
git add plugins/local_conf/skills/session-handoff/SKILL.md
git commit -m "session-handoff: slim Callouts section to pointer + placement guidance"
```

---

### Task 3: Update the routing bullet to delegate

**Files:**
- Modify: `plugins/local_conf/skills/session-handoff/SKILL.md` — `## Routing content to the right section` section.

The bullet currently says callouts go to "a callout heading"; update it to say they delegate to `handle-callouts`.

- [ ] **Step 1: Read the current bullet list**

Use `Read` on `plugins/local_conf/skills/session-handoff/SKILL.md` with `offset: 274, limit: 9`. Confirm the bullet list matches the `old_string` below; if line numbers drifted, anchor by the `## Routing content to the right section` heading.

- [ ] **Step 2: Apply the edit**

Use the `Edit` tool on `plugins/local_conf/skills/session-handoff/SKILL.md`:

- old_string:

  ````
  - A discovery, decision, caveat, gotcha, lesson learned, known issue, complexity, or edge case worth a permanent home → a callout heading (see "Callouts: discoveries, decisions, caveats"), **not** a bullet under "Work done"
  ````

- new_string:

  ````
  - A discovery, decision, caveat, gotcha, lesson learned, known issue, complexity, or edge case worth a permanent home → delegate to `handle-callouts` (it writes the callout heading; **not** a bullet under "Work done")
  ````

- [ ] **Step 3: Verify**

Re-Read the section. Confirm the callout bullet now references delegation; the four other bullets are untouched.

- [ ] **Step 4: Commit**

```bash
git add plugins/local_conf/skills/session-handoff/SKILL.md
git commit -m "session-handoff: route callout bullet through handle-callouts delegation"
```

---

### Task 4: Rewrite handle-callouts' coordination section

**Files:**
- Modify: `plugins/local_conf/skills/handle-callouts/SKILL.md` — `## Coordination with session-handoff` section body.

The current section describes a "safety net" model where `session-handoff` may write callouts itself. With Step 0 delegation in place, that's no longer accurate — every callout write flows through this skill.

- [ ] **Step 1: Read the current section**

Use `Read` on `plugins/local_conf/skills/handle-callouts/SKILL.md` with `offset: 136, limit: 5`. Confirm the body matches the `old_string` below.

- [ ] **Step 2: Apply the edit**

Use the `Edit` tool on `plugins/local_conf/skills/handle-callouts/SKILL.md`:

- old_string:

  ````
  ## Coordination with `session-handoff`

  `session-handoff` retains its callout safety-net role: when the user explicitly invokes it to "update the handoff" and there's a finding this skill missed, `session-handoff` can still write a properly-formatted callout. This skill is the primary author during the session; `session-handoff` is the safety net. Both write to the same handoff in the same format.
  ````

- new_string:

  ````
  ## Coordination with `session-handoff`

  `session-handoff` recognizes callout-shaped content during its append flow and **delegates to this skill** via the Skill tool. This skill owns all callout writes: format, dedup, placement. `session-handoff` owns the handoff document lifecycle (create, read, route non-callout content, migrate). The two skills are mutually-recursive in trigger but mutually-exclusive in execution — `session-handoff`'s lazy-create runs only when no handoff exists; the delegation runs only when one does.
  ````

- [ ] **Step 3: Verify**

Re-Read the section. Confirm the new text replaces the old in full; surrounding sections (`## Tool usage` after, `## Edge cases` before) are untouched.

- [ ] **Step 4: Commit**

```bash
git add plugins/local_conf/skills/handle-callouts/SKILL.md
git commit -m "handle-callouts: rewrite session-handoff coordination as delegation"
```

---

### Task 5: Bump local_conf plugin version

**Files:**
- Modify: `plugins/local_conf/.claude-plugin/plugin.json` — `version` field.

User-visible behavior changes (delegation routing). Minor bump.

- [ ] **Step 1: Read the file**

Use `Read` on `plugins/local_conf/.claude-plugin/plugin.json`. Confirm `"version": "1.6.0"`.

- [ ] **Step 2: Apply the edit**

Use the `Edit` tool on `plugins/local_conf/.claude-plugin/plugin.json`:

- old_string: `"version": "1.6.0",`
- new_string: `"version": "1.7.0",`

- [ ] **Step 3: Verify**

Re-Read the file. Confirm the version is now `1.7.0` and the rest of the JSON is untouched (valid JSON).

- [ ] **Step 4: Commit**

```bash
git add plugins/local_conf/.claude-plugin/plugin.json
git commit -m "local_conf: bump to 1.7.0"
```

---

### Task 6: Manual smoke test (no commit)

This task is a hands-on verification in a fresh Claude Code session. It does not produce file changes; it exists to confirm the documented delegation behavior works in practice.

- [ ] **Step 1: Cross-file coherence read**

Open `session-handoff/SKILL.md` and `handle-callouts/SKILL.md` side by side. Verify:
- `session-handoff`'s Step 0 references `handle-callouts/SKILL.md`'s `## When to use` section, and that section actually exists in `handle-callouts/SKILL.md`.
- `session-handoff`'s slimmed `## Callouts: discoveries, decisions, caveats` section points readers at `handle-callouts`.
- `handle-callouts`' `## Coordination with session-handoff` section describes delegation, not safety-net.

- [ ] **Step 2: Live delegation check**

Start a fresh Claude Code session in a worktree. Have a working handoff already in place (or let the session create one). Then say: "add this Discovery to the handoff: JWT clock skew tolerance varies by platform — tokens minted on macOS fail validation on Linux when…"

Expected: Claude invokes `session-handoff`, which detects callout-shaped content and delegates to `handle-callouts`. `handle-callouts` runs its dedup and writes the callout. The session-handoff skill does not write the callout itself.

- [ ] **Step 3: Non-callout routing check**

In the same session, say: "add this to the handoff: finished the auth refactor."

Expected: `session-handoff`'s Step 0 detects no callout shape, falls through to the existing append flow, writes the bullet under `## Work done`. `handle-callouts` is not invoked.

- [ ] **Step 4: No-loop check**

In a fresh worktree with no handoffs yet, say: "this is a Discovery: JWT clock skew tolerance varies by platform."

Expected: `handle-callouts` activates first, has no working handoff, invokes `session-handoff` for lazy-create, then writes the callout. There is no further recursion back into `handle-callouts` from within the lazy-create flow.

If any of these checks fail, the implementation diverged from the spec — re-open the affected task and fix.
