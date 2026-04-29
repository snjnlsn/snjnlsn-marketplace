#!/usr/bin/env bash
set -euo pipefail

# SessionStart hook helper.
# Lists up to MAX most recent files in $cwd/docs/handoffs/ sorted by mtime,
# and emits a SessionStart additionalContext payload pointing Claude at
# the session-handoff and session-retrospect skills.
#
# Always exits 0. On any internal error, emits no context (still exits 0)
# so the session is never blocked.

HANDOFF_DIR="docs/handoffs"
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
  find "$HANDOFF_DIR" -maxdepth 1 -type f -name "*.md" \
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
  ctx=$(printf 'Recent session handoffs in %s/:\n%s\n\nThe `session-handoff` skill can read, continue, or start fresh. The `session-retrospect` skill is also available on demand. If a recent handoff is relevant, consider offering the user to read it for context or continue it.' "$HANDOFF_DIR" "$recent")
else
  ctx=$(printf 'No prior handoffs found at %s/. The `session-handoff` skill can start a fresh handoff on demand or when content first arrives. The `session-retrospect` skill is also available.' "$HANDOFF_DIR")
fi

emit_context "$ctx" 2>/dev/null || true
