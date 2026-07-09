# Finalize Branch Memory and Annotation Audit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Teach `session-continuity:finalize-branch` to use relevant Serena memories during branch-fact auditing and to perform an accurate, Elixir-first documentation and annotation audit.

**Architecture:** Keep the main skill as the phase router. Add one focused reference for Serena memory relevance and failure handling, and expand the existing inline-code reference for Elixir annotation selection, evidence, compiler diagnostics, and proposal categories. Validate the behavior with fresh-context control and treatment runs before committing the skill change.

**Tech Stack:** Markdown skills and references, Serena memory and symbol tools, Elixir/Mix diagnostics, fresh-context subagents, Python skill validation, and Git.

**Spec:** `docs/superpowers/specs/2026-07-09-finalize-branch-memory-annotation-audit-design.md`

## Global Constraints

- Treat current code, tests, and repo docs as authoritative; Serena memories are context to verify.
- Read `core` first when it exists, then read only memories relevant to changed paths, symbols, docs, handoffs, or branch facts.
- Fall back to memory names when `core` is absent, incomplete, unreadable, or does not cover the branch topics.
- Keep unavailable memory context non-blocking and never inspect Serena storage directly.
- Audit intended Elixir public API rather than assuming every exported `def` is public documentation surface.
- Prefer no annotation over an unsupported or guessed contract.
- Keep `mix compile --all-warnings --warnings-as-errors` approval-gated and non-blocking only when run as the Phase 3 annotation diagnostic; preserve existing preflight failure behavior.
- Attribute compiler warnings to changed files or symbols before turning them into proposals.
- Do not edit plugin manifests, marketplace metadata, installed plugin caches, or files outside the canonical skill source and this plan.

---

## File Structure

**Create:**

- `plugins/session-continuity/skills/finalize-branch/references/memory-audit.md` - Serena memory discovery, relevance, fallback, authority, and summary contract.

**Modify:**

- `plugins/session-continuity/skills/finalize-branch/SKILL.md` - route Phase 2 through the memory audit and generalize the annotation accuracy rule.
- `plugins/session-continuity/skills/finalize-branch/references/inline-code-docs.md` - define the Phase 3 Elixir-first annotation and compiler-diagnostic workflow.

**Verify without expected modification:**

- `plugins/session-continuity/skills/finalize-branch/agents/openai.yaml` - its trigger-independent display text remains accurate.
- `plugins/session-continuity/.codex-plugin/plugin.json` and `plugins/session-continuity/.claude-plugin/plugin.json` - no version or manifest changes are in scope.

---

### Task 1: Establish the Failing Skill Baseline

**Files:**

- Read: `plugins/session-continuity/skills/finalize-branch/SKILL.md`
- Read: `plugins/session-continuity/skills/finalize-branch/references/inline-code-docs.md`
- Do not modify repository files.

**Interfaces:**

- Consumes: the current canonical skill and the raw scenario below.
- Produces: five fresh-context outputs and a manually scored baseline showing the current skill omits at least the Serena-memory workflow and expanded Elixir annotation workflow.

- [ ] **Step 1: Confirm the working tree is clean before the RED run**

Run:

```bash
git status --short
```

Expected: no output. If the output is non-empty, preserve those changes and resolve their ownership before continuing.

- [ ] **Step 2: Run five independent no-guidance control samples**

Dispatch five fresh-context agents with no shared history. Give each agent only the canonical `finalize-branch` skill directory and this prompt; explicitly prohibit reading `docs/superpowers/**` so the design and plan cannot leak into the control:

```text
Use the finalize-branch skill at
plugins/session-continuity/skills/finalize-branch/ to describe the exact audit
actions and user-facing proposals you would make for this hypothetical branch.
Do not edit files, run real commands, or read docs/superpowers/**. Treat the
following as raw tool and source output.

Branch changes:
- lib/acme/checkout.ex adds public type result/0, behaviour CheckoutBehaviour,
  callback authorize/2, and an implementation module.
- lib/acme/internal/formatter.ex changes format/1 and retains @doc false.
- lib/acme/parser.ex changes parse/1, whose return shape varies by runtime data
  and cannot be inferred precisely from callers or tests.

Serena tool output:
- list_memories => ["core", "elixir_conventions", "deployment"]
- read_memory("core") => "For Elixir types and behaviours, consult
  mem:elixir_conventions. Deployment guidance applies only to release changes."
- read_memory("elixir_conventions") => "Public types have @typedoc. Behaviour
  implementations identify the behaviour with @impl SomeBehaviour."
- read_memory("deployment") => "Release and infrastructure conventions."

Current annotations:
- CheckoutBehaviour has @type result but no @typedoc. Its public docs describe
  authorize/2 as a callback, but it has no @callback declaration. A branch
  handoff says authorize/2 is optional, but there is no @optional_callbacks
  entry.
- The implementation declares @behaviour CheckoutBehaviour and uses @impl true.
- The internal formatter intentionally uses @doc false.
- parse/1 has no @spec and the accurate return contract is unclear.

Optional diagnostic output:
- lib/acme/checkout.ex has a warning about an undefined result/0 reference.
- lib/acme/legacy.ex has an unrelated pre-existing warning.

Return the ordered audit actions, any command you would offer, the proposals
you would show the user, and the final audit summary. State what you skip.
```

Expected: five independent outputs produced without repository mutations.

- [ ] **Step 3: Score every baseline output manually**

Use this scorecard for each output:

| Criterion | Passing behavior |
|---|---|
| Memory discovery | Calls `list_memories`, reads `core` first, reads `elixir_conventions`, and skips `deployment` by relevance. |
| Memory authority | Treats memory as context and current source/tests/docs as authoritative. |
| Public API selection | Audits checkout APIs while preserving the formatter's intentional `@doc false`. |
| Annotation coverage | Checks `@typedoc`, `@callback`, `@optional_callbacks`, `@behaviour`, and both `@impl` forms in addition to docs/specs/types. |
| Compiler diagnostic | Offers the exact Mix command with approval, separates changed-code and unrelated warnings, and keeps annotation-phase warning failure non-blocking. |
| Accuracy gate | Declines to invent a `parse/1` spec. |
| Summary shape | Names read memories, aggregates irrelevant skips, reports limitations, and categorizes annotation proposals. |

Expected RED result: at least the memory-discovery and expanded-annotation criteria fail consistently because the current skill has no such instructions. Record the exact omissions and rationalizations in execution notes.

- [ ] **Step 4: Stop if the control does not fail for the intended reason**

If all five outputs already pass every criterion, do not edit the skill. Reassess the spec because there is no demonstrated behavior gap. If failures are caused only by prompt misunderstanding, tighten the scenario and rerun all five controls before proceeding.

---

### Task 2: Implement the Minimal Memory and Annotation Guidance

**Files:**

- Modify: `plugins/session-continuity/skills/finalize-branch/SKILL.md:8`
- Create: `plugins/session-continuity/skills/finalize-branch/references/memory-audit.md`
- Modify: `plugins/session-continuity/skills/finalize-branch/references/inline-code-docs.md:1`

**Interfaces:**

- Consumes: the exact baseline failures from Task 1 and existing Phase 2/3 approval gates.
- Produces: a Phase 2 memory-audit contract and a Phase 3 Elixir annotation-audit contract linked from the main skill.

- [ ] **Step 1: Update the main skill's routing and authority rules**

Apply these exact textual changes to `SKILL.md`:

1. Replace the overview sentence with:

```markdown
Finalize a feature branch by auditing branch changes, handoffs, and relevant project memories, updating docs where needed, deleting the branch's session handoffs, and producing one final commit.
```

2. Insert this core rule after the existing source-precedence rule:

```markdown
- Treat current code, tests, and repo docs as authoritative. Use Serena memories as project context to verify, never as authority that overrides current project evidence.
```

3. Replace Phase 2 and Phase 3 in `## Phase Flow` with:

```markdown
2. **Audit handoffs, memories, and branch facts** - Confirm branch handoffs, audit relevant Serena memories, compare that context with code, resolve ambiguities, route callouts, and clean up in-code handoff references. Read `references/memory-audit.md` before the comparison. Read `references/callout-harvesting.md` and `references/handoff-reference-cleanup.md` when those steps have work.
3. **Inline code docs and annotations** - Propose focused updates to intended public API docs and language-specific annotations, with Elixir first, then apply approved edits. Read `references/inline-code-docs.md`.
```

4. Replace the final documentation-style bullet with:

```markdown
- Add or correct specs and related annotations only when their contracts are supported by source, callers, tests, or compiler evidence.
```

5. Insert this tool rule before the source-symbol rule:

```markdown
- Project memories: use Serena (`list_memories`, `read_memory`). Never inspect Serena memory storage directly.
```

6. Insert this reference before `callout-harvesting.md`:

```markdown
- `references/memory-audit.md` - Serena memory discovery, relevance, fallback, authority, and audit-summary rules.
```

- [ ] **Step 2: Create the focused memory-audit reference**

Create `references/memory-audit.md` with exactly:

```markdown
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

Treat memories as project context to verify against current code, tests, and repo docs. Current project evidence wins when it conflicts with memory.

If Serena memory tools are unavailable, do not inspect memory storage directly. Report that memory context was unavailable and continue. If no memories exist or none are relevant, report that briefly and continue.

## Audit Summary

Include:

- names of memories read
- count of memories skipped as irrelevant; name individual memories only when a name explains a decision or limitation
- unavailable or unreadable memory context
- memory guidance that affects a handoff, branch-fact, inline-doc, repo-doc, or annotation proposal
```

- [ ] **Step 3: Replace the inline-code reference with the Elixir-first workflow**

Replace `references/inline-code-docs.md` with exactly:

```markdown
# Inline Code Docs and Annotations

Load this reference for Phase 3 of `finalize-branch`.

## Candidate Selection

From `git diff --name-only <base>..HEAD`, inspect source files only. Skip generated files, lockfiles, fixtures, and binaries.

Use Serena symbol tools to inspect changed structure, symbol bodies, and callers. Include callouts routed to inline code docs and handoff-reference cleanup proposals, and tag those sources in the display.

## Elixir-First Audit

For changed Elixir files, first decide which symbols are intended public API. Inspect exported functions and macros, protocol implementations, behaviour callbacks, and public types. Honor `@doc false`, internal namespaces, and nearby project conventions; an exported `def` is not automatically intended public API.

Inspect presence and accuracy for:

- `@moduledoc` and `@doc`
- `@spec`
- `@type`, `@opaque`, and `@typedoc`
- `@callback`, `@macrocallback`, and `@optional_callbacks`
- `@behaviour`
- `@impl true` and `@impl SomeBehaviour`

Use source bodies, callers, tests, and compiler feedback as evidence. Propose an addition or correction only when that evidence supports the contract. Prefer no annotation over a guessed type, callback, behaviour, or implementation marker.

Do not add private or internal docs unless an existing private doc is stale.

## Compiler Diagnostic

When the branch changes Elixir source, `mix.exs` exists, and `mix` is available, offer:

```bash
mix compile --all-warnings --warnings-as-errors
```

Skip the offer if that exact command already succeeded during preflight. Otherwise run it only after user approval.

Classify its result before proposing changes:

- Warnings attributable to changed files or symbols may support an annotation proposal or bug report.
- Pre-existing or unrelated warnings are reported separately and do not expand branch scope.
- Environment or dependency failures are recorded as limitations.
- A nonzero exit caused by warnings does not halt the Phase 3 annotation audit and does not justify a speculative annotation.

This diagnostic rule does not change preflight's existing halt behavior for a user-selected branch-health command.

## Non-Elixir Fallback

For other changed source, inspect useful public inline docs and stale contracts using local conventions: Python docstrings, Rust `///`, and JS/TS JSDoc on exported symbols.

## Proposal and Approval Flow

Work one file at a time, or in chunks of 3-5 files for large branches. Number proposals and show concise proposed text or a current/proposed diff. Label each outcome as:

- missing annotation
- stale or inaccurate annotation
- compiler-warning-driven proposal
- no proposal because the accurate type or contract is unclear

User choices:

- approve all
- approve specific numbers
- `nuance: ...`
- skip file
- skip phase

When nuanced, revise only that proposal and re-prompt for approval, another nuance, or revoke.

## Apply Changes

Apply approved changes immediately. Prefer Serena symbolic edits for symbol-attached docs and annotations. Use direct textual edits only when the content is not cleanly tied to a symbol.

After all files, summarize applied and skipped changes, then ask whether to proceed to repo docs.
```

- [ ] **Step 4: Verify the structural edit before behavioral testing**

Run:

```bash
rg -n 'memory-audit|list_memories|read_memory|Inline code docs and annotations|@typedoc|@macrocallback|@optional_callbacks|@behaviour|@impl SomeBehaviour|mix compile --all-warnings --warnings-as-errors' plugins/session-continuity/skills/finalize-branch
```

Expected: matches in `SKILL.md`, `references/memory-audit.md`, and `references/inline-code-docs.md`; no matches in plugin manifests or cache paths.

Run:

```bash
git diff --check
```

Expected: no output.

- [ ] **Step 5: Do not commit until the treatment runs pass**

Keep the skill edits unstaged while Task 3 exercises the exact behavior that failed in Task 1.

---

### Task 3: Prove the Revised Skill and Commit It

**Files:**

- Verify: `plugins/session-continuity/skills/finalize-branch/SKILL.md`
- Verify: `plugins/session-continuity/skills/finalize-branch/references/memory-audit.md`
- Verify: `plugins/session-continuity/skills/finalize-branch/references/inline-code-docs.md`
- Verify unchanged: `plugins/session-continuity/skills/finalize-branch/agents/openai.yaml`

**Interfaces:**

- Consumes: the revised skill from Task 2 and the unchanged Task 1 scenario and scorecard.
- Produces: convergent passing treatment outputs, passing edge cases, a validated skill folder, and one focused implementation commit.

- [ ] **Step 1: Run five independent treatment samples**

Dispatch five new fresh-context agents with the exact Task 1 prompt and the revised canonical skill directory. Do not pass the scorecard, baseline outputs, intended fixes, spec, or plan to the agents.

Expected GREEN result: every output passes all seven Task 1 scorecard criteria. Manually read each output; do not rely only on keyword counts.

- [ ] **Step 2: Check convergence and close only observed gaps**

Compare the five treatment outputs. Expected: they select the same relevant memory, preserve `@doc false`, cover the same annotation relationships, offer the same command conditionally, separate the two warnings, and decline the unclear spec.

If any criterion fails or the outputs materially disagree, update only the wording responsible for that observed failure, then rerun five fresh-context treatment samples. Do not add guidance for hypothetical failures that did not occur.

- [ ] **Step 3: Run the incomplete-memory edge scenario**

Dispatch one fresh-context agent with the revised skill and this prompt:

```text
Use the finalize-branch skill at
plugins/session-continuity/skills/finalize-branch/ to describe the Phase 2 memory
audit for two cases. Do not edit files or read docs/superpowers/**.

Branch topics: changed Elixir callbacks and types.
Available memory names: ["core", "elixir_types", "deployment"].

Case A: reading core fails, but reading elixir_types succeeds and describes
callback/type conventions.
Case B: Serena memory tools are unavailable.

For each case, state which memories you attempt to read, what fallback you use,
what you report, whether finalization continues, and what evidence is
authoritative.
```

Expected:

- Case A falls back from unreadable `core` to the relevant `elixir_types` name, skips `deployment`, reports the limitation, and continues.
- Case B does not inspect memory storage, reports unavailable context, and continues.
- Both cases keep current code, tests, and repo docs authoritative.

- [ ] **Step 4: Validate the skill folder and metadata**

Run:

```bash
python3 /Users/sanjay/.codex/skills/.system/skill-creator/scripts/quick_validate.py plugins/session-continuity/skills/finalize-branch
```

Expected: validation succeeds with no frontmatter or naming errors.

Read `agents/openai.yaml` and compare it with the revised trigger and outcome. Expected: `Finalize Branch`, `Prepare a branch for merge`, and the existing default prompt remain accurate, so the file stays unchanged.

Run:

```bash
git diff --exit-code -- plugins/session-continuity/skills/finalize-branch/agents/openai.yaml plugins/session-continuity/.codex-plugin/plugin.json plugins/session-continuity/.claude-plugin/plugin.json
```

Expected: no output and exit code 0.

- [ ] **Step 5: Run final static verification**

Run:

```bash
rg -n '^Load this reference for Phase 3|@typedoc|@macrocallback|@optional_callbacks|@behaviour|@impl true|@impl SomeBehaviour|mix compile --all-warnings --warnings-as-errors' plugins/session-continuity/skills/finalize-branch/references/inline-code-docs.md
```

Expected: the Phase 3 label, complete annotation set, and exact diagnostic command are present.

Run:

```bash
rg -n 'core|memory names|authoritative|unavailable|skipped as irrelevant' plugins/session-continuity/skills/finalize-branch/references/memory-audit.md
```

Expected: the primary map, fallback, authority, unavailable-tool behavior, and concise summary contract are present.

Run:

```bash
git diff --check
```

Expected: no output.

- [ ] **Step 6: Inspect and commit the focused change**

Run:

```bash
git diff -- plugins/session-continuity/skills/finalize-branch
```

Confirm the diff contains only the approved main-skill routing changes, the new memory reference, and the expanded inline-code reference.

Stage explicit paths:

```bash
git add plugins/session-continuity/skills/finalize-branch/SKILL.md plugins/session-continuity/skills/finalize-branch/references/memory-audit.md plugins/session-continuity/skills/finalize-branch/references/inline-code-docs.md
```

Commit:

```bash
git commit -m "feat: strengthen finalize branch audits"
```

Expected: one commit containing three skill files, with no manifest, metadata, marketplace, cache, or unrelated changes.

- [ ] **Step 7: Confirm repository state**

Run:

```bash
git status --short
```

Expected: no output.

Run:

```bash
git show --stat --oneline --summary HEAD
```

Expected: `feat: strengthen finalize branch audits` and exactly the three intended skill paths.

---

## Self-Review

- Spec Memory Audit requirements map to Task 2 Steps 1-2 and Task 3 Step 3.
- Elixir annotation coverage and public API selection map to Task 2 Step 3 and Task 3 Steps 1 and 5.
- Compiler approval, attribution, and non-blocking diagnostic behavior map to Task 2 Step 3 and the Task 1/3 treatment scenario.
- Concise skipped-memory reporting and unavailable-tool handling map to `memory-audit.md` and the edge scenario.
- RED-before-GREEN skill testing maps to five Task 1 controls and five Task 3 treatments.
- Phase-label correction maps to the exact replacement content in Task 2 Step 3.
- Metadata, manifest, and cache boundaries map to Global Constraints and Task 3 Step 4.
- Skill/frontmatter validation maps to Task 3 Step 4.
- No placeholders, unspecified code steps, or unresolved decisions remain.
