# `handle-callouts` Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `handle-callouts` skill to the `local_conf` plugin that captures session findings (discoveries, decisions, caveats, etc.) as properly-formatted callout headings in the current session's handoff.

**Architecture:** Markdown-only skill (no scripts, no hooks). Triggers on explicit phrases or proactive recognition. Delegates handoff lazy-create to the existing `session-handoff` skill via the Skill tool. Includes a `/callouts` slash command, a one-line terminology fix to `finalize-branch`, README updates, and a plugin version bump.

**Tech Stack:** Markdown for SKILL.md and slash command. JSON for `plugin.json` version bump.

**Spec:** `docs/superpowers/specs/2026-04-30-handle-callouts-design.md`

---

## File structure

**Create:**
- `plugins/local_conf/skills/handle-callouts/SKILL.md`
- `plugins/local_conf/commands/callouts.md`

**Modify:**
- `plugins/local_conf/skills/finalize-branch/SKILL.md` — terminology nit on line 345
- `plugins/local_conf/README.md` — add the new skill + slash command rows

**Bump:**
- `plugins/local_conf/.claude-plugin/plugin.json` — version 1.4.1 → 1.5.0

**Test approach:** No automated harness (skills are markdown). Each Task ends with a content-shape verification step (file exists, frontmatter parses, expected sections present). A final smoke test in Task 6 exercises the skill in a fresh Claude Code session.

---

### Task 1: Create the `handle-callouts` skill

**Files:**
- Create: `plugins/local_conf/skills/handle-callouts/SKILL.md`

- [ ] **Step 1: Create the skill directory**

```bash
mkdir -p plugins/local_conf/skills/handle-callouts
```

- [ ] **Step 2: Write `plugins/local_conf/skills/handle-callouts/SKILL.md`**

````markdown
---
name: handle-callouts
description: Capture session findings as callouts (discoveries, decisions, caveats, gotchas, lessons learned, known issues, complexities, edge cases) into the current session's handoff, in the format the `finalize-branch` skill later harvests. Use when the user says "this is a discovery", "save that as a decision", "that's a gotcha", "document this as a callout", or any singular/plural variant; or proactively when the session produces a non-obvious behavior just confirmed, a deliberate trade-off accepted, a constraint that surprised the session, a finding that explains repeated behavior elsewhere, or a decision that closes off an alternative explicitly considered. Delegates to session-handoff for lazy-create when no handoff exists.
---

# Handle Callouts

Capture findings worth surfacing across sessions — discoveries, decisions, caveats, and the like — as properly-formatted callout headings in the current session's handoff. Pairs with `session-handoff` (which owns the document) and `finalize-branch` (which harvests callouts at branch end).

## When to use

Activate when the user says:

- "this is a discovery / decision / caveat / gotcha / lesson learned / known issue / complexity / edge case" (singular or plural)
- "save that as a discovery / decision / caveat / gotcha / lesson / known issue / complexity / edge case"
- "that's a gotcha / discovery / decision / caveat / lesson / known issue / complexity / edge case"
- "document this as a callout" / "callout this" / "save that callout"

Also activate proactively when the session produces:

- A non-obvious behavior just confirmed (especially against a hypothesis)
- A deliberate trade-off accepted between two approaches
- A constraint that surprised the session (rate limit, schema gotcha, version pin, etc.)
- A finding that explains repeated behavior elsewhere
- A decision that closes off an alternative explicitly considered

Propose once per moment. If declined, don't re-propose for the same finding — the user can always trigger explicitly later.

## Terminology

**Callout** is the standard term — for the category as a whole, for individual instances when the type isn't named, and for skill/section/variable names. The eight keywords (Discovery, Decision, Caveat, Gotcha, Lesson learned, Known issue, Complexity, Edge case) are *types of callout*. They appear in headings (always) and in prose when:

- Mirroring the user's framing — `"save that as a decision"` → `"Saved as ### Decision — …"`.
- Mirroring surrounding writing that already uses the keyword.
- The specific type is what the prose is about — "the Discovery you saved earlier covers this."

Otherwise, default to "callout."

## Format

A callout is a Markdown heading at any level (typically `###`) where the first words match a keyword (case-insensitive), optionally followed by a number, a separator (`—`, `-`, or `:`), then a title.

Keywords — singular and plural both detected:

- `Discovery` / `Discoveries`
- `Decision` / `Decisions`
- `Caveat` / `Caveats`
- `Gotcha` / `Gotchas`
- `Lesson learned` / `Lessons learned`
- `Known issue` / `Known issues`
- `Complexity` / `Complexities`
- `Edge case` / `Edge cases`

Valid heading examples:

- `### Discovery — JWT clock skew tolerance varies by platform`
- `### Discovery 4 — JWT clock skew tolerance varies by platform`
- `#### Decision: drop legacy session middleware`
- `### Edge cases — empty input handling`
- `### Known issues` (bare, no title)

Body: everything under the heading until the next heading. Write in normal session voice; `finalize-branch` rewrites bodies atemporally at routing time, so don't pre-strip "during this session" or "we found that".

**Title by finding, not task:** `### Discovery — JWT clock skew tolerance varies by platform`, not `### Discovery — investigated JWT auth`.

**Anti-pattern — bare callout-keyword parent sections:** never use `## Discoveries`, `## Decisions`, `## Caveats` as parent section names. Those headings themselves match the keyword pattern, so the entire section body harvests as one callout. `## Callouts` is safe (not on the keyword list).

## Interaction modes

| Source | Behavior |
|---|---|
| Explicit user request, type named ("save that as a decision") | Auto-write. One-line report: `Saved as ### Decision — drop legacy session middleware to <handoff path>.` |
| Explicit user request, type unspecified ("save that callout" / "callout this") | Propose type + title; confirm before write. |
| Implicit recognition (you notice a callout-worthy moment) | Propose type + title + body draft; confirm before write. Phrasing: "This looks like a discovery worth capturing: `### Discovery — JWT clock skew tolerance varies by platform`. Save?" |

## Authoring flow

When the skill fires:

1. **Determine working handoff path.**
   - If working handoff is in conversation context → use it.
   - Else → invoke `session-handoff` via the Skill tool. It handles lazy-create or context re-discovery. Resume here with the resolved path.

2. **Compose the callout.**
   - **Type** — from explicit user phrasing, or your classification (one of the 8 keywords). Prefer singular form for a single finding.
   - **Title** — short, names the *finding* not the *task*. Separator: ` — ` (em dash with spaces) by convention; the regex also accepts `-` and `:`. Don't auto-assign numbering.
   - **Body** — 1–3 sentences in normal session voice. Link to `path:line` over restating code. Don't pre-strip "during this session" or "we found that" — `finalize-branch` rewrites bodies atemporally at routing time.

3. **Confirm per the interaction-modes table above.** Skip on explicit-typed; show heading + body draft otherwise.

4. **Determine placement.**
   - **Default:** `## Callouts` section, positioned after `## Summary` and before `## Work done`. Create the section if missing.
   - **Override:** if the user explicitly asks for inline ("under the auth work-done item"), place there instead. If the named section doesn't exist, ask the user to point to an existing one or fall back to `## Callouts`.

5. **Dedup check before write.** Scan all callout-shaped headings in the working handoff — both inline-under-section placements and entries under `## Callouts`. Match on either signal:
   - **Heading text** — normalized match (lowercase, collapsed whitespace, leading numbering stripped).
   - **Body substance** — judge whether an existing callout's body covers the same finding the new draft covers, even if the heading differs.

   On a match, evaluate whether the existing callout is still correct given the new finding, and draft a proposed update:

   - **Existing still correct, no new info** → flag as redundant; no update drafted.
   - **Existing still correct, new info adds detail** → draft a body that folds both.
   - **Existing partially wrong / superseded** → draft a replacement body. If the heading itself misframes the finding, propose a heading edit too.
   - **Existing contradicts the new finding** → draft a body that records the supersession explicitly (preserves the original's reasoning, states the new conclusion).

   Then prompt with the drafted update visible: **apply update**, **replace with new (drop existing)**, **write new (separate, both stay)**, or **skip**.

   Scope: just the working handoff. Cross-handoff dedup is `finalize-branch`'s job.

6. **Apply the write** via Edit. Refresh the `**Last updated:**` timestamp.

7. **Report.** One line — `Saved as ### <type> — <title> to <handoff path>.`

## Writing style

Callouts follow the "Language and tone" rules from `session-handoff` SKILL.md (lines 74-97). The pertinent points:

- 1–3 sentences. Lead with the finding.
- Cut marketing adjectives, filler ("In order to" → "to"), hedges ("It should be noted that…"), narrating the obvious, vague verbs without outcomes.
- `path:line` references over restated code. Preserve code/data fences verbatim when they're the substance of the finding.

## Edge cases

- **Numbering.** Produce unnumbered headings (`### Discovery — title`) by default. Numbering is allowed by the regex but not auto-assigned. `finalize-branch` strips numbering during dedup, so unnumbered keeps things cleaner and avoids collision with manually-numbered entries.

- **Multiple callouts in one trigger** ("these last three are all decisions"). Iterate, treat each as a separate authoring flow. Per-callout confirmation still applies — explicit-but-untyped (user said "decisions" without titles) means confirm each title before write.

- **Type outside the 8 keywords** ("save this as a tip"). Don't invent a keyword. Suggest the closest match ("Sounds like a Discovery — use that?") or ask the user to pick from the list.

- **Working handoff file missing** (e.g., manually deleted mid-session). Edit will fail. Surface the error, re-invoke `session-handoff` to lazy-create, retry the write.

- **Reading an old handoff ≠ writing target.** Callouts always go to the working handoff for the current session. If the user is reading a prior handoff and wants to capture a callout, the write goes to *this* session's working handoff — lazy-create one if needed, don't append to the file being read.

- **Conversation context drops the working handoff path** mid-session. Step 1 re-invokes `session-handoff`, which handles re-discovery (list `docs/handoffs/`, match session timestamp, or ask).

## Coordination with `session-handoff`

`session-handoff` retains its callout safety-net role: when the user explicitly invokes it to "update the handoff" and there's a finding this skill missed, `session-handoff` can still write a properly-formatted callout. This skill is the primary author during the session; `session-handoff` is the safety net. Both write to the same handoff in the same format.

## Tool usage

- **Read the working handoff** to scan for existing callouts and dedup match — `Read` (handoffs are markdown, not code).
- **Write/edit the handoff** — `Edit`. Refresh `**Last updated:**` on every write.
- **Lazy-create when no handoff exists** — invoke `session-handoff` via the Skill tool; do not duplicate its lazy-create logic inline.

## Spec reference

Full design rationale: `docs/superpowers/specs/2026-04-30-handle-callouts-design.md`.
````

- [ ] **Step 3: Verify the file exists and frontmatter is valid**

```bash
test -f plugins/local_conf/skills/handle-callouts/SKILL.md && head -3 plugins/local_conf/skills/handle-callouts/SKILL.md
```

Expected: file exists, first line is `---`, second line starts with `name: handle-callouts`.

- [ ] **Step 4: Verify all expected sections are present**

```bash
grep -n "^## " plugins/local_conf/skills/handle-callouts/SKILL.md
```

Expected sections (in order): `When to use`, `Terminology`, `Format`, `Interaction modes`, `Authoring flow`, `Writing style`, `Edge cases`, `Coordination with`, `Tool usage`, `Spec reference`.

- [ ] **Step 5: Commit**

```bash
git add plugins/local_conf/skills/handle-callouts/SKILL.md
git commit -m "Add handle-callouts skill to local_conf

Captures session findings as callouts (discoveries, decisions, caveats,
etc.) in the current session's handoff. Triggers on explicit phrases or
proactive recognition; delegates lazy-create to session-handoff."
```

---

### Task 2: Create the `/callouts` slash command

**Files:**
- Create: `plugins/local_conf/commands/callouts.md`

- [ ] **Step 1: Write `plugins/local_conf/commands/callouts.md`**

```markdown
---
description: Capture session findings as callouts in the current session's handoff
---

Use the `handle-callouts` skill to capture a finding as a properly-formatted callout (discovery, decision, caveat, gotcha, lesson learned, known issue, complexity, or edge case) in the current session's handoff.

If the user passed arguments after `/callouts`, treat them as the content or instruction (e.g., "save the JWT thing we just found as a discovery"). Otherwise, ask the user what they'd like to capture.
```

- [ ] **Step 2: Verify the file**

```bash
test -f plugins/local_conf/commands/callouts.md && head -3 plugins/local_conf/commands/callouts.md
```

Expected: file exists, frontmatter has `description:`.

- [ ] **Step 3: Commit**

```bash
git add plugins/local_conf/commands/callouts.md
git commit -m "Add /callouts slash command to local_conf

Routes to the handle-callouts skill, parallel to /handoff and /retrospect."
```

---

### Task 3: Cross-skill terminology audit + fix

**Files:**
- Modify: `plugins/local_conf/skills/finalize-branch/SKILL.md:345`

The spec's Terminology section identified one prose nit: `finalize-branch` line 345 says "oldest discovery first" where "oldest callout first" is the standard term. This task applies that fix and verifies no other prose nits slipped in since the spec scan.

- [ ] **Step 1: Re-scan for keyword-in-prose patterns**

```bash
grep -n -i -E "oldest (discover|decision|caveat|gotcha|lesson|known issue|complexit|edge case)|first (discover|decision|caveat|gotcha|lesson|known issue|complexit|edge case)" plugins/local_conf/skills/*/SKILL.md
```

Expected: one match — `finalize-branch/SKILL.md:345: ...oldest discovery first...`.

If new matches appear (e.g., from other branches that landed since the spec was written), evaluate each against the Terminology rules in the new skill. Apply only changes that fall under the "single keyword in prose where 'callout' is standard" pattern. Skip matches that are mirroring user phrasing, in heading examples, in pattern-set listings, or in target-doc filename/section conventions.

- [ ] **Step 2: Read the target line for context**

Use the `Read` tool on `plugins/local_conf/skills/finalize-branch/SKILL.md` with `offset: 343, limit: 5` (or whatever range covers the line returned by Step 1's grep — line numbers may have drifted).

Expected content includes:

```
Entries land in routing order = Step 5 walk order = chronological order across handoffs (oldest discovery first). Produces a chronological log feel without requiring date prefixes inside the doc.
```

- [ ] **Step 3: Apply the fix**

Use `Edit` on `plugins/local_conf/skills/finalize-branch/SKILL.md`:

- old_string: `chronological order across handoffs (oldest discovery first).`
- new_string: `chronological order across handoffs (oldest callout first).`

- [ ] **Step 4: Verify the fix landed and no other instance remains**

```bash
grep -n "oldest discovery first" plugins/local_conf/skills/finalize-branch/SKILL.md
grep -n "oldest callout first" plugins/local_conf/skills/finalize-branch/SKILL.md
```

Expected: first command returns nothing; second returns the updated line.

- [ ] **Step 5: Commit**

```bash
git add plugins/local_conf/skills/finalize-branch/SKILL.md
git commit -m "Standardize 'callout' terminology in finalize-branch

Per the handle-callouts spec's terminology convention: 'callout' is the
standard term in prose. Replaces a single-keyword usage on line 345
('oldest discovery first' -> 'oldest callout first')."
```

---

### Task 4: Update `local_conf` README

**Files:**
- Modify: `plugins/local_conf/README.md`

Add the new skill row to the Skills table and the new slash command row to the Slash commands table.

- [ ] **Step 1: Read current state**

Use the `Read` tool on `plugins/local_conf/README.md` with `offset: 7, limit: 16` to view the Skills and Slash commands tables. Confirm the file matches the expected "before" state shown in Step 2's `old_string` values. If it doesn't, reconcile manually.

- [ ] **Step 2: Add the `handle-callouts` row to the Skills table**

Use `Edit` on `plugins/local_conf/README.md`:

- old_string:
  ```
  | `skills/finalize-branch/` | End-of-branch pipeline — audits and updates inline code docs and project docs (with language/tone guidance), removes the branch's handoffs, produces one final commit; supports cancel-and-resume via stash |
  ```
- new_string:
  ```
  | `skills/finalize-branch/` | End-of-branch pipeline — audits and updates inline code docs and project docs (with language/tone guidance), removes the branch's handoffs, produces one final commit; supports cancel-and-resume via stash |
  | `skills/handle-callouts/` | Capture session findings as callouts (discoveries, decisions, caveats, gotchas, lessons learned, known issues, complexities, edge cases) in the current session's handoff. Triggers on explicit phrases or proactive recognition. |
  ```

- [ ] **Step 3: Add the `/callouts` row to the Slash commands table**

Use `Edit` on `plugins/local_conf/README.md`:

- old_string:
  ```
  | `/finalize-branch` | Route to the `finalize-branch` skill |
  ```
- new_string:
  ```
  | `/finalize-branch` | Route to the `finalize-branch` skill |
  | `/callouts` | Route to the `handle-callouts` skill |
  ```

- [ ] **Step 4: Verify both rows landed**

```bash
grep -n "handle-callouts\|/callouts" plugins/local_conf/README.md
```

Expected: two matches — one for the Skills table row, one for the Slash commands table row.

- [ ] **Step 5: Commit**

```bash
git add plugins/local_conf/README.md
git commit -m "Document handle-callouts skill and /callouts command in README"
```

---

### Task 5: Bump `local_conf` plugin version

**Files:**
- Modify: `plugins/local_conf/.claude-plugin/plugin.json`

Bump the version from `1.4.1` to `1.5.0` (minor bump for a new skill + slash command).

- [ ] **Step 1: Read current version**

Use the `Read` tool on `plugins/local_conf/.claude-plugin/plugin.json`. Confirm `"version": "1.4.1"`. If it differs, reconcile manually before continuing.

- [ ] **Step 2: Apply the bump**

Use `Edit` on `plugins/local_conf/.claude-plugin/plugin.json`:

- old_string: `"version": "1.4.1",`
- new_string: `"version": "1.5.0",`

- [ ] **Step 3: Verify**

```bash
grep '"version"' plugins/local_conf/.claude-plugin/plugin.json
```

Expected: `"version": "1.5.0",`.

- [ ] **Step 4: Commit**

```bash
git add plugins/local_conf/.claude-plugin/plugin.json
git commit -m "Bump local_conf to 1.5.0 for handle-callouts skill"
```

---

### Task 6: Manual smoke test

**Files:** none (verification only)

Skills can't be tested in isolation — they only fire inside a live Claude Code session. This task is a checklist of manual verifications to run from a fresh session after the implementation is committed and the plugin is reloaded.

- [ ] **Step 1: Reload the plugin in Claude Code**

In a Claude Code session: `/reload-plugins` (or restart Claude Code).

- [ ] **Step 2: Confirm the skill is listed**

In Claude Code: type `/` and look for `/callouts`. The available-skills list (visible in the SessionStart system reminder or via the `Skill` tool) should include `local_conf:handle-callouts`.

- [ ] **Step 3: Smoke test — explicit-typed write (auto-write path)**

In a working repo without an existing handoff for the session, say: *"Save this as a discovery: the `mix test --warnings-as-errors` flag suppresses warnings emitted from `deps/`."*

Expected:
- Skill fires, invokes `session-handoff` via Skill tool to lazy-create a handoff.
- Writes `### Discovery — <title>` under a new `## Callouts` section.
- One-line report: `Saved as ### Discovery — <title> to <handoff path>.`

Verify the file exists at `docs/handoffs/<expected-name>.md` and contains the callout.

- [ ] **Step 4: Smoke test — explicit-untyped (confirm path)**

Same session: *"Callout this: we picked Tailwind over CSS modules because the team prefers utility-class density."*

Expected:
- Skill proposes `### Decision — Tailwind over CSS modules` (or similar) and asks for confirmation.
- On approval, writes to the same handoff under `## Callouts`.

- [ ] **Step 5: Smoke test — implicit recognition**

Continue work in the same session. Make a request that produces a non-obvious finding, e.g., *"Why is `Foo.bar/2` returning `nil` for empty inputs?"*. After investigation reveals the cause:

Expected:
- Claude proactively offers: "This looks like a discovery worth capturing: `### Discovery — …`. Save?"
- On approval, writes to the same handoff.
- On decline, doesn't re-propose for the same finding.

- [ ] **Step 6: Smoke test — dedup**

Trigger the same finding from Step 3 again with slightly different phrasing: *"Save a discovery about how `--warnings-as-errors` doesn't catch deps warnings."*

Expected:
- Skill detects the existing callout, evaluates "same finding, no new info," and reports it as redundant rather than writing a duplicate.

- [ ] **Step 7: Smoke test — `finalize-branch` integration**

If the test branch has at least one commit ahead of `main`, run `/finalize-branch`. At Phase 1 Step 5 (callout extraction), confirm the callouts written by `handle-callouts` are detected and routed normally.

Expected:
- Each callout from the handoff appears in the routing UX.
- Recommendations apply (`add-to-repo-docs` for general findings, etc.).
- The format matches what `finalize-branch` expects (no parsing errors).

- [ ] **Step 8: If any smoke test fails, document and fix**

Common failure modes and recovery:

- **Skill doesn't fire on explicit phrasing** — verify the `description` field made it through frontmatter parsing (Task 1 Step 3).
- **Lazy-create doesn't trigger** — verify the SKILL.md says to invoke `session-handoff` via the Skill tool, not just to read the file.
- **Callout heading not in `## Callouts` section** — verify the placement default in Step 4 of the authoring flow.
- **`finalize-branch` doesn't detect the callout** — compare the heading produced by `handle-callouts` against the regex in `finalize-branch/SKILL.md:162`. Both must match.

Fix forward in a new commit; do not amend. Re-run the affected smoke test.

- [ ] **Step 9: Final verification**

```bash
git log --oneline main..HEAD
```

Expected: 5 commits — one per Task 1 through Task 5. (Task 6 produces no commits unless a fix was needed.)

```bash
git diff main..HEAD --stat
```

Expected files changed:
- `plugins/local_conf/skills/handle-callouts/SKILL.md` (new)
- `plugins/local_conf/commands/callouts.md` (new)
- `plugins/local_conf/skills/finalize-branch/SKILL.md` (1-line change near line 345)
- `plugins/local_conf/README.md` (2 row additions)
- `plugins/local_conf/.claude-plugin/plugin.json` (version bump)

If anything else shows in the diff, reconcile before opening a PR.

---

## Notes

- **No automated tests.** Skills are markdown documents with no test harness. Verification is structural (frontmatter parses, sections exist) plus the live smoke tests in Task 6.
- **Order matters for review, not implementation.** Tasks 1–5 are independent and could run in any order; the listed order is reading-friendly (skill first, then command, then audit, then docs, then version). Tasks must all complete before Task 6 (smoke test against a reloaded plugin).
- **No `--no-verify` or `--amend`.** Per global rules. If a pre-commit hook fails, fix forward in a new commit.
