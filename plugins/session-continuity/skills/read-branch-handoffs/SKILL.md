---
name: read-branch-handoffs
description: Read every handoff attributable to the current git branch (committed on the branch + uncommitted in the working tree) and present them in chronological order. Use when the user says "read the branch handoffs", "load the handoff context", "catch me up on this branch's prior sessions", "what handoffs are on this branch", or accepts the SessionStart hook's hint to load branch handoff context.
---

# Read Branch Handoffs

Load every handoff document attributable to the current git branch and present them in chronological order as session context. This is the sanctioned read path for prior-session handoffs other than the working session's own handoff (which `session-handoff` owns).

`.claude/handoffs/` is a skill-managed directory: outside this skill and `session-handoff`, do not list, read, edit, or delete files there.

## When to use

Activate when the user says:

- "read the branch handoffs" / "load the handoff context" / "load handoff context"
- "what handoffs are on this branch" / "show me the branch handoffs"
- "catch me up on this branch's prior sessions"

Also activate when the SessionStart hook surfaces a branch-handoffs hint and the user accepts.

## Process

### Step 1 — Resolve base branch

Detect via `git symbolic-ref refs/remotes/origin/HEAD`. Fallback chain: `main` → `master` → ask the user.

If the current branch *is* the base (e.g., currently on `main`), the `<base>..HEAD` filter is meaningless. Drop the branch-scope filter and treat every `.md` file directly under `.claude/handoffs/` as a candidate, sorted chronologically.

### Step 2 — Collect candidates

Two sources merged and deduped:

1. **Committed on this branch** —
   ```
   git log --name-only --diff-filter=AM --pretty=format: <base>..HEAD -- .claude/handoffs/
   ```
   `--diff-filter=AM` keeps added and modified files; deleted handoffs are not candidates.
2. **Uncommitted / untracked in the working tree** — `git status --porcelain -- .claude/handoffs/`. Include modified, added, and untracked `.md` files. Exclude entries marked deleted.

After merging, drop:
- Non-`.md` files.
- `.claude/handoffs/README.md` (the sentinel, not a handoff).
- Any path that no longer exists in the working tree.

### Step 3 — Sort chronologically

Parse the `YYYY-MM-DD-HHMMSS` prefix from each filename. For files lacking that prefix (legacy or tolerated formats — see `session-handoff/SKILL.md` § "Read tolerance after migration"), fall back to file `mtime`. Sort oldest → newest.

### Step 4 — Read and present

Use `Read` on each candidate. Present a structured summary:

- One block per handoff in chronological order.
- For each: filename, `**Author:**`, the verbatim `## Summary` section, and counts of `## Work done` bullets and `## Open questions / next steps` items.
- Cross-handoff: when a newer handoff supersedes an older one for the same work (matching slug or topic), note the supersession explicitly.

If a working handoff exists in conversation context (set by `session-handoff` earlier in the session), flag it as such: `Working handoff: <path> — the active document for this session.`

### Step 5 — Offer next steps

Based on what was found, suggest one of:

- **Newest handoff has unresolved open questions** → "Resume from the last session's open items?"
- **Multiple stale handoffs across several sessions** → suggest the most recent as the resume anchor, but mention the older ones as background.
- **No actionable next step** → just present and let the user direct.

Never auto-adopt a found handoff as the working handoff — adoption is `session-handoff`'s job and requires explicit user intent.

## Constraints

- **Read-only.** This skill never writes, edits, renames, or deletes handoffs. Writes route through `session-handoff` or `handle-callouts`; branch-end deletion routes through `finalize-branch`.
- **Tolerate legacy filenames.** Some handoffs predate the `YYYY-MM-DD-HHMMSS-<author>--<slug>.md` convention; still read them. Migration prompts are `session-handoff`'s job, not this skill's.
- **Empty result is fine.** Zero handoffs on the branch → report "No handoffs found on this branch" and exit; do not invent context.
- **Don't list `.claude/handoffs/` from outside this skill.** Even for "just curious" questions, route here so the contract holds.

## Edge cases

- **`.claude/handoffs/` missing.** Report it; suggest the user run the plugin's `scripts/setup-handoffs.sh` (see the plugin README for path).
- **Only `README.md` present.** Treat as empty.
- **Base branch undetectable.** Try `main` → `master` → ask the user.
- **Detached HEAD.** No branch scope to filter against; fall back to "all handoffs in `.claude/handoffs/`" with a note that the listing isn't branch-filtered.
- **Worktrees.** Operate on `cwd`; the git queries naturally scope to the worktree's HEAD.
- **Handoff renamed mid-branch** (e.g., by `session-handoff`'s migration flow). `git log` surfaces both old and new names with `--diff-filter=AM` — filter to whichever still exists in the working tree.

## Tool usage

- **`Bash`** for `git symbolic-ref`, `git log`, `git status`.
- **`Read`** for handoff contents (markdown, not code — Serena's symbolic tools don't apply).
- Never `Edit` / `Write` here.
