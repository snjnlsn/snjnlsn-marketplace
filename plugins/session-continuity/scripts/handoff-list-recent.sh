#!/usr/bin/env bash
set -euo pipefail

# SessionStart hook helper.
# Lists up to MAX most recent files in $cwd/.claude/handoffs/ sorted by mtime,
# and emits a SessionStart additionalContext payload pointing Claude at
# the session-continuity skills (read-branch-handoffs, session-handoff,
# handle-callouts, session-retrospect).
#
# Always exits 0. On any internal error, emits no context (still exits 0)
# so the session is never blocked.

HANDOFF_DIR=".claude/handoffs"
MAX=5

emit_context() {
  jq -n --arg ctx "$1" '{
    hookSpecificOutput: {
      hookEventName: "SessionStart",
      additionalContext: $ctx
    }
  }'
}

list_recent() {
  if [ ! -d "$HANDOFF_DIR" ]; then
    return 0
  fi
  find "$HANDOFF_DIR" -maxdepth 1 -type f -name "*.md" ! -name "README.md" \
    -exec stat -f '%m %N' {} + 2>/dev/null \
    | sort -rn \
    | head -n "$MAX" \
    | while read -r mtime path; do
        iso=$(date -r "$mtime" -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "?")
        echo "- ${path#./} — ${iso}"
      done
}

# Suppress errors on the listing — we'd rather emit a degraded context than block.
recent=$(list_recent 2>/dev/null || true)

if [ -n "$recent" ]; then
  ctx=$(printf 'Recent session handoffs in %s/:\n%s\n\nFor full branch context (every handoff attributable to the current branch, committed + uncommitted), invoke the `read-branch-handoffs` skill — that is the sanctioned bulk read path. The `session-handoff` skill handles single-handoff create/read/continue/append; `handle-callouts` records findings; `session-retrospect` reflects at session end. %s/ is managed exclusively by these skills — do not list, edit, or delete handoff files directly.' "$HANDOFF_DIR" "$recent" "$HANDOFF_DIR")
else
  ctx=$(printf 'No prior handoffs found at %s/. If the directory does not exist yet, run the session-continuity plugin'\''s setup script (see the plugin README for the path) to bootstrap it. The `session-handoff` skill creates a handoff on demand; `read-branch-handoffs`, `handle-callouts`, and `session-retrospect` are also available.' "$HANDOFF_DIR")
fi

emit_context "$ctx" 2>/dev/null || true
