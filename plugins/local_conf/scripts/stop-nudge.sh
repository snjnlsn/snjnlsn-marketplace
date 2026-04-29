#!/usr/bin/env bash
set -euo pipefail

# Stop hook helper.
# Reads the Stop payload from stdin, computes whether to nudge the user
# toward wrapping up (handoff update / retrospective) based on:
#   - assistant turn count >= TURN_THRESHOLD, OR
#   - elapsed minutes since the first assistant turn >= ELAPSED_MIN_THRESHOLD
# Suppresses repeat nudges within COOLDOWN_MIN minutes per session.
#
# Always exits 0. On any internal error, emits no context.

TURN_THRESHOLD=20
ELAPSED_MIN_THRESHOLD=30
COOLDOWN_MIN=15

CACHE_DIR="${HOME}/.cache/local_conf/stop-nudge"
mkdir -p "$CACHE_DIR" 2>/dev/null || true

input=$(cat || true)
session_id=$(echo "$input" | jq -r '.session_id // empty' 2>/dev/null || echo "")
[[ "$session_id" =~ [^a-zA-Z0-9_.-] ]] && session_id=""
transcript_path=$(echo "$input" | jq -r '.transcript_path // empty' 2>/dev/null || echo "")

if [ -z "$session_id" ] || [ -z "$transcript_path" ] || [ ! -f "$transcript_path" ]; then
  exit 0
fi

# Count assistant turns. Transcript is JSONL; entries may have either
# .role at top-level or .message.role nested.
turn_count=$(jq -s '[.[] | select((.message.role // .role // "") == "assistant")] | length' "$transcript_path" 2>/dev/null || echo 0)
turn_count=${turn_count:-0}

# Earliest assistant timestamp (ISO 8601). Try .timestamp then .message.timestamp.
earliest_ts=$(jq -rs '
  [.[] | select((.message.role // .role // "") == "assistant")
       | (.timestamp // .message.timestamp // empty)]
  | map(select(. != null and . != ""))
  | first // empty
' "$transcript_path" 2>/dev/null || echo "")

now_epoch=$(date -u +%s)
earliest_epoch=0
if [ -n "$earliest_ts" ]; then
  ts="${earliest_ts%%.*}"   # strip fractional seconds
  ts="${ts%Z}"               # strip trailing Z
  ts="${ts%%+[0-9]*}"        # strip +HH:MM UTC offset if present
  earliest_epoch=$(date -juf "%Y-%m-%dT%H:%M:%S" "$ts" +%s 2>/dev/null || echo 0)
fi

elapsed_min=0
if [ "$earliest_epoch" -gt 0 ]; then
  elapsed_min=$(( (now_epoch - earliest_epoch) / 60 ))
fi

# Threshold check
if [ "$turn_count" -lt "$TURN_THRESHOLD" ] && [ "$elapsed_min" -lt "$ELAPSED_MIN_THRESHOLD" ]; then
  exit 0
fi

# Cooldown check
state_file="${CACHE_DIR}/${session_id}.ts"
if [ -f "$state_file" ]; then
  last_ts=$(cat "$state_file" 2>/dev/null || echo 0)
  last_ts=${last_ts:-0}
  [[ "$last_ts" =~ ^[0-9]+$ ]] || last_ts=0
  cooldown_sec=$((COOLDOWN_MIN * 60))
  if [ $((now_epoch - last_ts)) -lt "$cooldown_sec" ]; then
    exit 0
  fi
fi

# Update last-nudge timestamp (best-effort)
echo "$now_epoch" > "$state_file" 2>/dev/null || true

ctx="If this looks like a wrap-up moment, consider offering to update the handoff (\`session-handoff\` skill) or run a retrospective (\`session-retrospect\` skill). This nudge will not repeat for ${COOLDOWN_MIN} minutes."

jq -n --arg ctx "$ctx" '{
  hookSpecificOutput: {
    hookEventName: "Stop",
    additionalContext: $ctx
  }
}' 2>/dev/null || true
