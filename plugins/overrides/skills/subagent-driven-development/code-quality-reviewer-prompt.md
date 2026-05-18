# Code Quality Reviewer Prompt Template

Use this template when dispatching a code quality reviewer subagent.

**Purpose:** Verify implementation is well-built (clean, tested, maintainable)

**Only dispatch after spec compliance review passes.**

```
Task tool (general-purpose):
  Use template at overrides:requesting-code-review/code-reviewer.md

  DESCRIPTION: [task summary, from implementer's report]
  PLAN_OR_REQUIREMENTS: Task N from [plan-file]
  BASE_SHA: [commit before task]
  HEAD_SHA: [current commit]
```

The MCP toolkit preamble is already inlined in
`overrides:requesting-code-review/code-reviewer.md`, so any subagent
dispatched against that template inherits the MCP guidance automatically. Do
not re-paste it here.

**In addition to standard code quality concerns, the reviewer should check:**
- Does each file have one clear responsibility with a well-defined interface?
- Are units decomposed so they can be understood and tested independently?
- Is the implementation following the file structure from the plan?
- Did this implementation create new files that are already large, or significantly grow existing files? (Don't flag pre-existing file sizes — focus on what this change contributed.)

**Code reviewer returns:** Strengths, Issues (Critical/Important/Minor), Assessment

**Trivial inline fixes are allowed.** If the reviewer spots a clearly trivial
issue (typo, magic number, naming nit, missing constant extraction, dead
import, formatting), it may fix it inline rather than bouncing back to the
implementer — but only under these guards:

- The fix is contained to code already in the diff under review (no new files,
  no edits outside the changed surface).
- No scope expansion: don't add features, refactor adjacent code, or rename
  symbols beyond the trivial fix.
- After the fix, run the relevant tests AND `mix compile` (or the project's
  equivalent build/typecheck) and confirm both pass before reporting.
- Report the inline fixes explicitly in the review output so the controller
  sees what changed.

Anything that isn't trivially contained — logic changes, multi-file edits,
behavior changes, anything requiring judgment about intent — must go back to
the implementer as a normal review issue.
