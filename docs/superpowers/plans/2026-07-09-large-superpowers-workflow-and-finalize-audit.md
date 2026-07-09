# Large Superpowers Workflow and Finalize Audit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the conditional large-workflow overlay to `snjnlsn-dev-config:superpowers-caveat`, then use that validated policy to add relevance-based Serena memory and Elixir annotation auditing to `session-continuity:finalize-branch`.

**Architecture:** Two ordered workstreams share one execution graph. Workstream A keeps the always-loaded caveat concise and routes qualifying efforts to a focused large-workflow reference; after its behavior is tested and committed, Workstream B updates the finalize skill through its own focused memory and annotation references. Each skill follows RED-GREEN-REFACTOR with five fresh-context control samples, five treatment samples, task review, and a final Sol High integration review.

**Tech Stack:** Markdown skills and references, GPT-5.6 Sol/Terra/Luna subagents, Serena memory and symbol tools, Elixir/Mix diagnostics, Python skill validation, and Git.

**Specs:**

- `docs/superpowers/specs/2026-07-09-large-superpowers-workflow-and-finalize-audit-design.md`
- `docs/superpowers/specs/2026-07-09-finalize-branch-memory-annotation-audit-design.md`

## Global Constraints

- This combined effort activates the large-workflow overlay because it contains two coordinated workstreams, repeated behavioral validation, prerequisite ordering, and more than 30 minutes of expected execution.
- Keep the top-level coordinator on GPT-5.6 Sol High. If the current coordinator is not Sol High, pause before planning or execution, recommend switching, and require explicit approval before continuing on the closest available model.
- Assign GPT-5.6 Terra High to integration-heavy implementation, difficult debugging, cross-workstream reconciliation, and task review; Terra Medium to standard implementation; and Luna Medium to mechanical edits, boilerplate, straightforward test generation, and documentation updates.
- Workstream A is a strict prerequisite for Workstream B. Validate, review, and commit A before beginning B.
- For the activated large workflow only, parallel implementation is allowed when dependencies are satisfied, write scopes are disjoint, and integration order is explicit. Never parallelize overlapping write scopes.
- Preserve the execution graph, agent contracts, model substitutions, and graph revisions in the execution ledger.
- Treat repo-local instructions and opinionated skills as controlling guidance over general Superpowers workflow advice.
- Treat current code, tests, and repo docs as authoritative; Serena memories are context to verify.
- Read `core` first when it exists, then read only memories relevant to changed paths, symbols, docs, handoffs, or branch facts.
- Fall back to memory names when `core` is absent, incomplete, unreadable, or does not cover the branch topics.
- Keep unavailable memory context non-blocking and never inspect Serena storage directly.
- Audit intended Elixir public API rather than assuming every exported `def` is public documentation surface.
- Prefer no annotation over an unsupported or guessed contract.
- Keep `mix compile --all-warnings --warnings-as-errors` approval-gated and non-blocking only when run as the Phase 3 annotation diagnostic; preserve existing preflight failure behavior.
- Attribute compiler warnings to changed files or symbols before turning them into proposals.
- Do not edit bundled or cached Superpowers skills, plugin manifests, marketplace metadata, or installed plugin caches.

---

## Execution Graph

| Node | Depends on | Parallel eligibility | Write ownership | Model |
|---|---|---|---|---|
| A1 Caveat baseline | Plan approved | Five independent samples may run together | None | Terra High samples; Sol High coordinator |
| A2 Caveat implementation | A1 demonstrates intended failures | No parallel implementation | `plugins/snjnlsn-dev-config/skills/superpowers-caveat/**`, plugin README row | Luna Medium worker |
| A3 Caveat treatment and commit | A2 complete | Five independent samples may run together | Same as A2 for observed wording fixes only | Terra High samples/reviewer |
| B1 Finalize baseline | A3 committed and reviewed | Five independent samples may run together | None | Terra High samples |
| B2 Finalize implementation | B1 demonstrates intended failures | No parallel implementation | `plugins/session-continuity/skills/finalize-branch/**` | Luna Medium worker |
| B3 Finalize treatment and commit | B2 complete | Five independent samples may run together | Same as B2 for observed wording fixes only | Terra High samples/reviewer |
| C1 Whole-change review | A3 and B3 committed | No | Read-only | Sol High reviewer |

Integration order is `A1 -> A2 -> A3 -> B1 -> B2 -> B3 -> C1`. Parallelism is limited to independent fresh-context evaluation samples inside A1, A3, B1, and B3.

## Agent Contract Rules

Every dispatched worker receives only its task brief, required predecessor interfaces, exact write scope, global constraints, verification commands, and report path. Workers do not read the whole plan or infer ownership from branch history.

Every task review checks both spec compliance and skill quality. Critical and Important findings return to a bounded fix worker and then to re-review. An unresolved architectural choice returns to the Sol High coordinator; the worker does not choose locally.

If execution invalidates the graph, stop new dispatches, checkpoint safe work, update the affected spec/plan/contracts and ownership boundaries, review the revised graph, then resume from the corrected dependency state.

---

## Workstream A: Conditional Large-Workflow Caveat

### Workstream A File Structure

**Create:**

- `plugins/snjnlsn-dev-config/skills/superpowers-caveat/references/large-workflow.md` - execution graph, agent contract, model routing, scheduling, and replanning policy.

**Modify:**

- `plugins/snjnlsn-dev-config/skills/superpowers-caveat/SKILL.md` - context-first activation and conditional reference routing.
- `plugins/snjnlsn-dev-config/skills/superpowers-caveat/agents/openai.yaml` - user-facing metadata for the expanded caveat.
- `plugins/snjnlsn-dev-config/README.md` - concise skill inventory summary.

**Verify without modification:**

- `plugins/snjnlsn-dev-config/.codex-plugin/plugin.json`
- `plugins/snjnlsn-dev-config/.claude-plugin/plugin.json`
- `.codex-plugin/marketplace.json`
- `.claude-plugin/marketplace.json`

---

### Task 1: A1 Caveat Behavior Baseline

**Model:** Sol High coordinator; five independent Terra High evaluation agents.

**Files:**

- Read: `plugins/snjnlsn-dev-config/skills/superpowers-caveat/SKILL.md`
- Do not modify repository files.

**Agent Contract:**

- Goal: prove the current caveat does not provide context-first activation, execution graphs, agent contracts, model routing, or controlled parallel scheduling.
- Completion criteria: five fresh-context outputs are manually scored and consistently fail at least the large-workflow criteria while preserving the existing repo-local precedence behavior.
- Write scope: none.
- Dependencies: approved combined design and clean working tree.
- Invariants: do not reveal the design, plan, scorecard, or intended fix to evaluation agents; do not mutate the canonical or cached skills.
- Handoff: record exact omissions and rationalizations for Task A2.

- [ ] **Step 1: Record the implementation base and verify cleanliness**

Run:

```bash
git rev-parse HEAD
```

Record the SHA as `IMPLEMENTATION_BASE` in the execution ledger.

Run:

```bash
git status --short
```

Expected: no output.

- [ ] **Step 2: Run five independent control samples**

Dispatch five fresh-context Terra High agents. Give each agent only the canonical caveat skill directory and this prompt. Do not allow access to `docs/superpowers/**`:

```text
Use the superpowers-caveat skill at
plugins/snjnlsn-dev-config/skills/superpowers-caveat/ as the local overlay for
the following hypothetical Superpowers workflow. Do not edit files, dispatch
real agents, or read docs/superpowers/**. Describe the exact decisions and
artifacts required at brainstorming, writing-plans, and
subagent-driven-development time.

Case A begins with: "Add CSV export to the reporting page. Start coding now;
this should be small." Do not classify it yet. After project inspection, the
complete scope is:
- about 6,200 changed lines and 45 minutes of agent execution
- workstream API owns lib/reporting/export/**
- workstream UI owns assets/reporting/export/**
- workstream migration owns priv/repo/migrations/*_report_exports.exs
- API and UI have disjoint writes and share ExportSchema v2
- migration must finish before API integration
- a docs worker and UI worker both propose editing README.md
- the current top-level coordinator is Terra High
- a standard API worker needs ordinary feature implementation
- a migration worker has difficult integration logic
- a docs worker performs mechanical edits
- during execution the API worker discovers two unresolved persistence
  architectures not covered by the approved design

Case B is fully understood after inspection as one 350-line documentation
change taking about 10 minutes, with one workstream and no unusual risk.

For each case state:
1. when the large-workflow decision is made and whether it activates
2. what the design/spec records
3. what the implementation plan records for each workstream
4. coordinator, worker, task-review, and final-review model assignments
5. which work may run in parallel and which must be serialized
6. what happens when the coordinator is not Sol High
7. what happens to the unresolved API architecture choice
8. what happens if later evidence invalidates the execution graph
```

Expected: five independent outputs with no repository mutations.

- [ ] **Step 3: Score every control output manually**

| Criterion | Passing behavior |
|---|---|
| Context-first decision | Does not classify Case A from its opening sentence; decides only after the complete scope is known. |
| Activation | Activates Case A for both 5,000+ LOC and 30+ minutes; leaves Case B on normal Superpowers behavior. |
| Recorded decision | Writes the activation decision and reasons into the design spec for later phases. |
| Execution graph | Records goals, completion, dependencies, blockers, parallel eligibility, ownership, interfaces, invariants, merge risk, integration/review order, and model assignments. |
| Agent contracts | Writing-plans carries exact scope, dependencies, interfaces, invariants, verification, review, handoff, model, and reasoning into each workstream contract. |
| Model routing | Uses Sol High for brainstorming/planning/coordinator/final review, Terra High for integration and task review, Terra Medium for standard implementation, and Luna Medium for mechanical work. |
| Coordinator mismatch | Pauses for a Sol High switch or explicit approval to use the closest available model. |
| Parallel scheduling | Allows API and UI only when dependencies are satisfied and integration order is explicit; serializes the two README writers and migration-dependent integration. |
| Escalation | Returns the unresolved architectural choice to the Sol High coordinator. |
| Replanning | Stops new dispatches, checkpoints safe work, updates graph/contracts/ownership, reviews, then resumes. |
| Local precedence | Continues to prefer repo-local instructions and opinionated skills. |

Expected RED result: the current caveat preserves local precedence but consistently fails the large-workflow criteria because those instructions do not exist.

- [ ] **Step 4: Stop if the intended baseline failure is absent**

If all five controls already pass every criterion, do not edit the caveat. Reassess the design because the requested behavior is already present. If failures come from an ambiguous prompt rather than missing guidance, tighten the prompt and rerun all five controls.

---

### Task 2: A2 Conditional Large-Workflow Overlay

**Model:** Luna Medium implementation worker; Sol High coordinator.

**Files:**

- Modify: `plugins/snjnlsn-dev-config/skills/superpowers-caveat/SKILL.md`
- Create: `plugins/snjnlsn-dev-config/skills/superpowers-caveat/references/large-workflow.md`
- Modify: `plugins/snjnlsn-dev-config/skills/superpowers-caveat/agents/openai.yaml`
- Modify: `plugins/snjnlsn-dev-config/README.md`

**Agent Contract:**

- Goal: add only the guidance needed to correct Task A1's observed failures while keeping the always-loaded caveat concise.
- Completion criteria: exact target content is present, metadata and README agree, static validation passes, and changes remain uncommitted until Task A3's treatment is green.
- Write scope: only the four paths listed above.
- Dependencies: Task A1's failing baseline and recorded rationalizations.
- Consumes: current Superpowers workflows plus repo-local precedence.
- Produces: a recorded activation decision, execution graph schema, agent contract schema, model routing, controlled scheduling override, and replanning protocol for qualifying work.
- Invariants: no bundled/cache edits, no manifest/version changes, no activation from the opening prompt, no large-workflow overhead for Case B.
- Handoff: uncommitted diff and static-validation evidence for Task A3.

- [ ] **Step 1: Replace `SKILL.md` with the concise router**

Use exactly:

```markdown
---
name: superpowers-caveat
description: Use when invoking, following, or delegating from any `superpowers:*` skill.
---

# Superpowers Caveat

Use Superpowers as the base workflow, with repo-local guidance controlling how code is read, written, tested, reviewed, and delegated.

## Apply Local Guidance

- Read applicable `AGENTS.md`, `CLAUDE.md`, `.agents/instructions.md`, and nested project guidance.
- Prefer repo-local skills for navigation, edits, testing, verification, review, planning, and subagent prompts.
- Carry relevant local guidance into dispatched agent contracts.

## Classify Large Work After Context

Do not classify from the opening request. During brainstorming, first gather enough project context to understand the complete implementation surface.

Activate the large-workflow overlay when the gathered scope suggests any one of:

- at least 5,000 changed lines
- at least 30 minutes of agent execution
- several coordinated workstreams
- meaningful integration or merge risk
- consequential architecture, migration, security, or data work

When near a threshold, activate if uncertainty suggests substantial hidden work. Record the decision and reasons in the design spec. When entering planning or execution, inherit the recorded decision from the approved spec or plan.

If activated, read `references/large-workflow.md` before finishing brainstorming and carry its graph, contract, model, and scheduling rules through planning and execution.

## Scope

Do not fork or edit bundled Superpowers skills. The activated overlay may override upstream model routing and the blanket parallel-worker prohibition only under the conditions in `references/large-workflow.md`. Routine work keeps ordinary Superpowers behavior.
```

- [ ] **Step 2: Create `references/large-workflow.md`**

Use exactly:

```markdown
# Large Superpowers Workflow

Load only after gathered project context activates the large-workflow overlay. The activation decision belongs in the design spec and flows into the implementation plan and execution ledger.

## Brainstorming Execution Graph

In addition to the ordinary approved design, define workstreams with:

- goal and completion criteria
- dependencies and blockers
- parallelization eligibility
- file or module ownership
- shared interfaces and invariants
- merge or integration risk
- integration and review order
- model and reasoning assignment

Include rollback, performance, migration, and observability considerations only when relevant.

## Writing-Plans Agent Contracts

Convert each workstream into a self-contained contract containing:

- goal and completion criteria
- exact write scope
- dependencies and required predecessor state
- consumed and produced interfaces
- invariants
- exact verification commands and expected results
- review expectations
- handoff and integration requirements
- model and reasoning assignment

Preserve graph dependencies, ownership, parallelization, and integration order explicitly. Linear numbering does not replace the graph.

## Model Routing

| Role | Model | Reasoning |
|---|---|---|
| Brainstorming, specification, planning, top-level coordination, architectural arbitration, final whole-branch review | `gpt-5.6-sol` | high |
| Integration-heavy implementation, difficult debugging, cross-workstream reconciliation, task review | `gpt-5.6-terra` | high |
| Standard implementation | `gpt-5.6-terra` | medium |
| Mechanical edits, boilerplate, repetitive migrations, straightforward test generation, documentation | `gpt-5.6-luna` | medium |

Keep the top-level coordinator on Sol High. If the current coordinator is not Sol High, pause before planning or execution, recommend switching, and require explicit approval before continuing on the closest available model.

If an assigned model is unavailable, use the closest capability tier and record the substitution. Escalate a worker to Sol High only for an architectural choice the approved graph and contracts do not resolve.

## Subagent Scheduling

Dispatch only work whose dependencies are satisfied.

For this activated overlay, independent implementation work may run in parallel only when:

- write scopes are disjoint
- shared interfaces and invariants are already defined
- integration order is explicit
- each workstream can be reviewed independently

This conditionally overrides the upstream blanket prohibition on parallel implementation subagents. Serialize or repartition work with overlapping write scopes. Return unresolved architectural choices to the Sol High coordinator instead of choosing locally.

Record task status, dependency changes, model substitutions, commits, reviews, and integration state in the execution ledger.

## Scope Changes

If execution invalidates the graph:

1. Stop new dispatches.
2. Let safe, non-conflicting work reach a stable checkpoint.
3. Update the design, plan, contracts, dependencies, interfaces, and ownership.
4. Review the changed graph.
5. Resume from the corrected dependency state.

Model strength does not compensate for unclear ownership, unresolved interfaces, or an obsolete plan.
```

- [ ] **Step 3: Update the UI metadata**

Run the skill-creator metadata generator:

```bash
python3 /Users/sanjay/.codex/skills/.system/skill-creator/scripts/generate_openai_yaml.py plugins/snjnlsn-dev-config/skills/superpowers-caveat --interface 'display_name=Superpowers Caveat' --interface 'short_description=Apply local guidance and scale large work' --interface 'default_prompt=Use $superpowers-caveat to apply repo-local guidance and, after gathering scope, scale large Superpowers work with execution graphs and model-aware agent contracts.'
```

Expected `agents/openai.yaml` content:

```yaml
interface:
  display_name: "Superpowers Caveat"
  short_description: "Apply local guidance and scale large work"
  default_prompt: "Use $superpowers-caveat to apply repo-local guidance and, after gathering scope, scale large Superpowers work with execution graphs and model-aware agent contracts."
```

- [ ] **Step 4: Update the plugin README inventory row**

Replace the existing `superpowers-caveat` row with:

```markdown
| `superpowers-caveat` | Prefer repo-local guidance when using Superpowers; after gathering full scope, add execution graphs, agent contracts, model routing, and controlled parallelism for large work. |
```

- [ ] **Step 5: Run static validation without committing**

Run:

```bash
python3 /Users/sanjay/.codex/skills/.system/skill-creator/scripts/quick_validate.py plugins/snjnlsn-dev-config/skills/superpowers-caveat
```

Expected: validation succeeds with no frontmatter or naming errors.

Run:

```bash
rg -n '5,000|30 minutes|large-workflow.md|gpt-5.6-sol|gpt-5.6-terra|gpt-5.6-luna|parallel implementation|Scope Changes' plugins/snjnlsn-dev-config/skills/superpowers-caveat plugins/snjnlsn-dev-config/README.md
```

Expected: activation routing appears in `SKILL.md`, detailed graph/model/scheduling rules appear in `references/large-workflow.md`, and the README summary is current.

Run:

```bash
git diff --check
```

Expected: no output. Do not stage or commit until Task A3 passes.

---

### Task 3: A3 Prove, Review, and Commit the Caveat Workstream

**Model:** Five independent Terra High evaluation agents; Terra High task reviewer; Sol High coordinator.

**Files:**

- Verify: `plugins/snjnlsn-dev-config/skills/superpowers-caveat/SKILL.md`
- Verify: `plugins/snjnlsn-dev-config/skills/superpowers-caveat/references/large-workflow.md`
- Verify: `plugins/snjnlsn-dev-config/skills/superpowers-caveat/agents/openai.yaml`
- Verify: `plugins/snjnlsn-dev-config/README.md`

**Agent Contract:**

- Goal: prove the revised caveat corrects Task A1 without activating large-workflow overhead for routine tasks.
- Completion criteria: five treatment outputs pass every scorecard row, outputs converge, edge policies are explicit, static validation passes, one focused commit is reviewed and approved.
- Write scope: Task A2 paths only, and only for wording changes tied to observed treatment failures.
- Dependencies: Task A2 uncommitted diff and Task A1 control outputs.
- Invariants: manually inspect outputs; no keyword-only scoring; no speculative guidance for failures not observed; Workstream B stays locked until review approval.
- Handoff: caveat commit SHA, clean review verdict, and recorded model/graph state for Task B1.

- [ ] **Step 1: Run five independent treatment samples**

Dispatch five new Terra High agents with the exact Task A1 prompt and the revised canonical caveat directory. Do not pass the scorecard, control outputs, spec, plan, or intended fixes.

Expected GREEN result: every output passes all Task A1 criteria and the five outputs converge on the same activation, graph, contract, model, scheduling, escalation, and replanning behavior.

- [ ] **Step 2: Fix only observed wording gaps and rerun the treatment**

If any criterion fails or outputs materially disagree, dispatch one bounded Luna Medium fix worker for the complete findings list. Rerun validation and five fresh Terra High treatment samples after each wording revision.

- [ ] **Step 3: Verify protected files remain unchanged**

Run:

```bash
git diff --exit-code -- plugins/snjnlsn-dev-config/.codex-plugin/plugin.json plugins/snjnlsn-dev-config/.claude-plugin/plugin.json .codex-plugin/marketplace.json .claude-plugin/marketplace.json
```

Expected: no output and exit code 0.

- [ ] **Step 4: Inspect and commit Workstream A**

Run:

```bash
git diff -- plugins/snjnlsn-dev-config/skills/superpowers-caveat plugins/snjnlsn-dev-config/README.md
```

Confirm the diff contains only the approved caveat router, large-workflow reference, metadata, and README row.

Stage explicit paths:

```bash
git add plugins/snjnlsn-dev-config/skills/superpowers-caveat/SKILL.md plugins/snjnlsn-dev-config/skills/superpowers-caveat/references/large-workflow.md plugins/snjnlsn-dev-config/skills/superpowers-caveat/agents/openai.yaml plugins/snjnlsn-dev-config/README.md
```

Commit:

```bash
git commit -m "feat: tailor Superpowers for large workflows"
```

- [ ] **Step 5: Run the Workstream A task review gate**

Run `/Users/sanjay/.codex/plugins/cache/openai-curated-remote/superpowers/6.1.1/skills/subagent-driven-development/scripts/review-package` with `IMPLEMENTATION_BASE` and the Workstream A commit. Dispatch a fresh Terra High reviewer with the Workstream A brief, implementer report, exact Global Constraints, and printed review-package path.

Expected: `Spec compliant` and `Task quality: Approved`. Send Critical or Important findings to one bounded fix worker, rerun the five-treatment gate if behavior wording changes, commit the fixes, and re-review.

- [ ] **Step 6: Unlock Workstream B**

Append two ledger lines: one marking Workstream A complete with the actual short commit SHA, RED/GREEN evidence, and clean review verdict; the second reading `Workstream B: unlocked`.

Do not begin Task B1 until this ledger entry exists.

---

## Workstream B: Finalize-Branch Memory and Annotation Audit

### Workstream B File Structure

**Create:**

- `plugins/session-continuity/skills/finalize-branch/references/memory-audit.md` - Serena memory discovery, relevance, fallback, authority, and summary contract.

**Modify:**

- `plugins/session-continuity/skills/finalize-branch/SKILL.md` - route Phase 2 through the memory audit and generalize the annotation accuracy rule.
- `plugins/session-continuity/skills/finalize-branch/references/inline-code-docs.md` - define the Phase 3 Elixir-first annotation and compiler-diagnostic workflow.

**Verify without expected modification:**

- `plugins/session-continuity/skills/finalize-branch/agents/openai.yaml` - its trigger-independent display text remains accurate.
- `plugins/session-continuity/.codex-plugin/plugin.json` and `plugins/session-continuity/.claude-plugin/plugin.json` - no version or manifest changes are in scope.

---

### Task 4: B1 Finalize-Branch Behavior Baseline

**Model:** Five independent Terra High evaluation agents; Sol High coordinator.

**Files:**

- Read: `plugins/session-continuity/skills/finalize-branch/SKILL.md`
- Read: `plugins/session-continuity/skills/finalize-branch/references/inline-code-docs.md`
- Do not modify repository files.

**Interfaces:**

- Consumes: the current canonical skill and the raw scenario below.
- Produces: five fresh-context outputs and a manually scored baseline showing the current skill omits at least the Serena-memory workflow and expanded Elixir annotation workflow.

**Agent Contract:**

- Goal: demonstrate the missing memory and Elixir annotation behavior before editing the finalize skill.
- Completion criteria: five independent outputs consistently fail the intended criteria for the intended reason.
- Write scope: none.
- Dependencies: Workstream A ledger entry is complete and reviewed.
- Invariants: no design/plan leakage, no real memory mutations, no canonical or cache edits.
- Handoff: exact omissions and rationalizations for Task B2.

- [ ] **Step 0: Confirm Workstream A unlocked this task**

Read `.superpowers/sdd/progress.md`.

Expected: a `Workstream A: complete` entry naming its clean review and a `Workstream B: unlocked` entry. If either is absent, stop; do not run the finalize baseline.

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

### Task 5: B2 Minimal Memory and Annotation Guidance

**Model:** Luna Medium implementation worker; Sol High coordinator.

**Files:**

- Modify: `plugins/session-continuity/skills/finalize-branch/SKILL.md:8`
- Create: `plugins/session-continuity/skills/finalize-branch/references/memory-audit.md`
- Modify: `plugins/session-continuity/skills/finalize-branch/references/inline-code-docs.md:1`

**Interfaces:**

- Consumes: the exact baseline failures from Task B1 and existing Phase 2/3 approval gates.
- Produces: a Phase 2 memory-audit contract and a Phase 3 Elixir annotation-audit contract linked from the main skill.

**Agent Contract:**

- Goal: add only the memory and annotation guidance needed to correct Task B1's observed failures.
- Completion criteria: exact target content and structural checks pass; changes remain uncommitted until Task B3's treatment is green.
- Write scope: the three finalize skill paths listed above.
- Dependencies: Task B1 RED evidence and Workstream A's controlling caveat policy.
- Invariants: current project evidence remains authoritative, no speculative annotations, no metadata/manifest/cache drift.
- Handoff: uncommitted diff and static evidence for Task B3.

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

Expected: matches in `SKILL.md`, `references/memory-audit.md`, and `references/inline-code-docs.md` only.

Run:

```bash
git diff --check
```

Expected: no output.

- [ ] **Step 5: Do not commit until the treatment runs pass**

Keep the skill edits unstaged while Task B3 exercises the exact behavior that failed in Task B1.

---

### Task 6: B3 Prove, Review, and Commit the Revised Finalize Skill

**Model:** Five independent Terra High evaluation agents; Terra High task reviewer; Sol High coordinator.

**Files:**

- Verify: `plugins/session-continuity/skills/finalize-branch/SKILL.md`
- Verify: `plugins/session-continuity/skills/finalize-branch/references/memory-audit.md`
- Verify: `plugins/session-continuity/skills/finalize-branch/references/inline-code-docs.md`
- Verify unchanged: `plugins/session-continuity/skills/finalize-branch/agents/openai.yaml`

**Interfaces:**

- Consumes: the revised skill from Task B2 and the unchanged Task B1 scenario and scorecard.
- Produces: convergent passing treatment outputs, passing edge cases, a validated skill folder, and one focused implementation commit.

**Agent Contract:**

- Goal: prove the finalize skill corrects Task B1, handles incomplete memory context, and stays within branch scope.
- Completion criteria: five treatment outputs pass, edge scenarios pass, static validation succeeds, one focused commit receives a clean Terra High task review.
- Write scope: Task B2 paths only, and only for wording fixes tied to observed treatment failures.
- Dependencies: Task B2 uncommitted diff.
- Invariants: manually inspect outputs, preserve approval gates, keep manifests/metadata/cache unchanged, do not broaden unrelated warnings into branch work.
- Handoff: finalize commit SHA and clean review verdict for Task C1.

- [ ] **Step 1: Run five independent treatment samples**

Dispatch five new fresh-context agents with the exact Task B1 prompt and the revised canonical skill directory. Do not pass the scorecard, baseline outputs, intended fixes, spec, or plan to the agents.

Expected GREEN result: every output passes all seven Task B1 scorecard criteria. Manually read each output; do not rely only on keyword counts.

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

- [ ] **Step 8: Run the Workstream B task review gate**

Run `/Users/sanjay/.codex/plugins/cache/openai-curated-remote/superpowers/6.1.1/skills/subagent-driven-development/scripts/review-package` with the Workstream A commit and the Workstream B commit. Dispatch a fresh Terra High reviewer with the Workstream B brief, implementer report, exact Global Constraints, and printed review-package path.

Expected: `Spec compliant` and `Task quality: Approved`. Send Critical or Important findings to one bounded fix worker, rerun the five-treatment and incomplete-memory gates if behavior wording changes, commit the fixes, and re-review.

- [ ] **Step 9: Unlock the whole-change review**

Append two ledger lines: one marking Workstream B complete with the actual short commit SHA, RED/GREEN evidence, and clean review verdict; the second reading `Whole-change review: unlocked`.

Do not begin Task C1 until this ledger entry exists.

---

## Integration Review

### Task 7: C1 Review and Verify the Combined Change

**Model:** Sol High whole-branch reviewer and coordinator.

**Files:**

- Review: all Workstream A and Workstream B implementation paths.
- Read: `docs/superpowers/specs/2026-07-09-large-superpowers-workflow-and-finalize-audit-design.md`
- Read: `docs/superpowers/specs/2026-07-09-finalize-branch-memory-annotation-audit-design.md`
- Read: this combined plan.

**Agent Contract:**

- Goal: verify the two committed skill updates satisfy both specs, preserve plugin boundaries, and interact coherently.
- Completion criteria: both skill validators pass, protected files are unchanged, Sol High review has no Critical or Important findings, and the working tree is clean.
- Write scope: none unless the reviewer returns findings; one Terra High fix worker then owns the complete findings list within the original workstream paths.
- Dependencies: clean Workstream A and B review verdicts recorded in the ledger.
- Invariants: do not edit bundled/cache skills, manifests, or marketplaces; do not weaken either behavioral test gate; do not merge or publish.
- Handoff: verified implementation commits and any residual Minor findings for branch finishing.

- [ ] **Step 1: Re-run both skill validators**

Run:

```bash
python3 /Users/sanjay/.codex/skills/.system/skill-creator/scripts/quick_validate.py plugins/snjnlsn-dev-config/skills/superpowers-caveat
```

Expected: validation succeeds.

Run:

```bash
python3 /Users/sanjay/.codex/skills/.system/skill-creator/scripts/quick_validate.py plugins/session-continuity/skills/finalize-branch
```

Expected: validation succeeds.

- [ ] **Step 2: Verify metadata and protected boundaries**

Run:

```bash
git status --short
```

Expected: no output.

Use the recorded `IMPLEMENTATION_BASE` to inspect the implementation range. Confirm it changes only:

```text
plugins/snjnlsn-dev-config/skills/superpowers-caveat/SKILL.md
plugins/snjnlsn-dev-config/skills/superpowers-caveat/references/large-workflow.md
plugins/snjnlsn-dev-config/skills/superpowers-caveat/agents/openai.yaml
plugins/snjnlsn-dev-config/README.md
plugins/session-continuity/skills/finalize-branch/SKILL.md
plugins/session-continuity/skills/finalize-branch/references/memory-audit.md
plugins/session-continuity/skills/finalize-branch/references/inline-code-docs.md
```

The finalize `agents/openai.yaml`, both plugins' manifests, marketplace files, and installed caches must remain unchanged.

- [ ] **Step 3: Dispatch the Sol High whole-change review**

Run `/Users/sanjay/.codex/plugins/cache/openai-curated-remote/superpowers/6.1.1/skills/subagent-driven-development/scripts/review-package` with the recorded `IMPLEMENTATION_BASE` and current `HEAD`, and retain the printed package path.

Dispatch one fresh Sol High reviewer with:

- both approved specs
- this combined plan
- the final review package
- the Global Constraints verbatim
- the Workstream A and B implementer reports and review verdicts

Ask for findings ordered by severity, exact file/line evidence, spec coverage, interaction risks, and missing validation. The review is read-only.

Expected: both specs compliant, no Critical or Important findings, skill quality approved.

- [ ] **Step 4: Resolve final-review findings as one wave**

If the reviewer returns Critical or Important findings, dispatch one Terra High fix worker with the complete findings list and the original workstream boundaries. Require focused tests plus reruns of any affected five-sample treatment gate. Commit fixes, regenerate the review package from the same `IMPLEMENTATION_BASE`, and re-dispatch a fresh Sol High reviewer.

Record Minor findings in the execution ledger for branch finishing.

- [ ] **Step 5: Confirm completion evidence**

Run:

```bash
git status --short
```

Expected: no output.

Run:

```bash
git log --oneline -6
```

Expected: the Workstream B implementation commit appears above the reviewed Workstream A implementation commit, with the combined plan and design commits below them.

Append:

```text
Combined implementation: complete (both validators pass, final Sol High review clean)
```

---

## Self-Review

- Context-first 5,000-line/30-minute activation maps to Task A1's scenario and Task A2's router.
- Execution graphs, agent contracts, model routing, controlled parallelism, Sol coordinator mismatch, and replanning map to Tasks A1-A3.
- Existing repo-local precedence remains in the exact Task A2 `SKILL.md` content.
- Workstream A's commit and clean review are a hard prerequisite in the graph, Task A3 ledger gate, and Task B1 Step 0.
- Spec Memory Audit requirements map to Task B2 Steps 1-2 and Task B3 Step 3.
- Elixir annotation coverage and public API selection map to Task B2 Step 3 and Task B3 Steps 1 and 5.
- Compiler approval, attribution, and non-blocking diagnostic behavior map to Task B2 Step 3 and the Task B1/B3 treatment scenario.
- Concise skipped-memory reporting and unavailable-tool handling map to `memory-audit.md` and the edge scenario.
- RED-before-GREEN testing maps to five A1 controls/five A3 treatments and five B1 controls/five B3 treatments.
- Phase-label correction maps to the exact Task B2 Step 3 content.
- Metadata, manifest, marketplace, and cache boundaries map to both workstream verification gates and Task C1.
- Skill/frontmatter validation runs per workstream and again in Task C1.
- Sol High final review maps to Task C1 and cannot start until both workstream review ledger entries exist.
- The superseded finalize-only plan is removed; this file contains every prior prompt, scorecard, exact edit, and verification step.
- No placeholders, unspecified code steps, or unresolved decisions remain.
