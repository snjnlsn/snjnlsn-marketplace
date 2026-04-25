#!/usr/bin/env bash
set -euo pipefail

cmd=$(jq -r '.tool_input.command')

# Only inspect sed invocations
if ! echo "$cmd" | grep -qE '(^|[[:space:]]|[|;&`(])sed([[:space:]]|$)'; then
  exit 0
fi

# Match: -i (alone or combined with other short flags like -ni), or --in-place
if echo "$cmd" | grep -qE '(^|[[:space:]])(-[a-zA-Z]*i[a-zA-Z]*|--in-place)([[:space:]]|=|$)'; then
  cat <<'JSON'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "sed in-place editing (-i / --in-place) is blocked by local_conf"
  }
}
JSON
fi
