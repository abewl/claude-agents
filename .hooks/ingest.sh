# #!/usr/bin/env bash
# # Claude Code hook — fires heartbeat or stop event to the observability dashboard.
# # Always exits 0 so Claude Code is never blocked by dashboard unavailability.

# EVENT="${1:-heartbeat}"

# # Load env vars from shell profile if not already set
# if [ -z "$CLAUDE_DASHBOARD_URL" ]; then
#   # shellcheck disable=SC1090
#   source ~/.zshrc 2>/dev/null || source ~/.bashrc 2>/dev/null || true
# fi

# # Bail silently if still not configured
# if [ -z "$CLAUDE_DASHBOARD_URL" ] || [ -z "$CLAUDE_DASHBOARD_API_KEY" ]; then
#   exit 0
# fi

# SESSION_ID="${CLAUDE_SESSION_ID:-default}"
# ACCOUNT_LABEL="${CLAUDE_ACCOUNT_LABEL:-default}"

# # ── Feature backlog sync ────────────────────────────────────────────────────
# # Reads FEATURE.md and serialises it as JSON for the dashboard.
# # Set CLAUDE_FEATURE_MD_PATH to override; otherwise searches common locations.
# FEATURES_JSON=""

# resolve_feature_md() {
#   if [ -n "$CLAUDE_FEATURE_MD_PATH" ] && [ -f "$CLAUDE_FEATURE_MD_PATH" ]; then
#     echo "$CLAUDE_FEATURE_MD_PATH"
#     return
#   fi
#   # Walk up from the script's directory
#   local dir
#   dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   for _ in 1 2 3; do
#     dir="$(dirname "$dir")"
#     [ -f "$dir/FEATURE.md" ] && echo "$dir/FEATURE.md" && return
#   done
# }

# FEATURE_MD="$(resolve_feature_md)"

# if [ -n "$FEATURE_MD" ]; then
#   FEATURES_JSON=$(python3 - "$FEATURE_MD" <<'PYEOF'
# import sys, json, re

# path = sys.argv[1]
# features = []
# current = None

# with open(path, encoding="utf-8") as f:
#   for line in f:
#     line = line.rstrip()
#     m = re.match(r'^## (F-\d+): (.+)$', line)
#     if m:
#       if current:
#         features.append(current)
#       current = {"id": m.group(1), "title": m.group(2).strip(), "status": "todo"}
#       continue
#     if current and line.startswith("- Status:"):
#       raw = line.replace("- Status:", "").strip()
#       if raw.startswith("[x]"):
#         current["status"] = "done"
#       elif raw.startswith("[~]"):
#         current["status"] = "in_progress"
#       else:
#         current["status"] = "todo"

# if current:
#   features.append(current)

# print(json.dumps(features))
# PYEOF
#   ) 2>/dev/null || FEATURES_JSON=""
# fi

# # ── Usage data (stop events only) ───────────────────────────────────────────
# # Reads transcript_path from Claude Code hook stdin JSON, parses the JSONL to
# # sum token counts, count tool calls, compute duration, and estimate cost.
# USAGE_FIELDS=""

# if [ "$EVENT" = "stop" ]; then
#   STDIN_DATA=$(cat)

#   # Step 1: extract transcript_path from hook stdin JSON (short -c, reads stdin via argv)
#   TRANSCRIPT_PATH=$(python3 -c "import json,sys; d=json.loads(sys.argv[1]); print(d.get('transcript_path',''))" \
#     "$STDIN_DATA" 2>/dev/null) || TRANSCRIPT_PATH=""

#   # Step 2: parse transcript file — pass path as argv[1] so stdin is free for data
#   if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
#     USAGE_FIELDS=$(python3 - "$TRANSCRIPT_PATH" <<'PYEOF' 2>/dev/null
# import sys, json

# try:
#     transcript_path = sys.argv[1]

#     input_tokens = 0
#     output_tokens = 0
#     cache_read_tokens = 0
#     cache_write_tokens = 0
#     tool_call_count = 0
#     first_ts = None
#     last_ts = None

#     with open(transcript_path, encoding="utf-8") as f:
#         for line in f:
#             line = line.strip()
#             if not line:
#                 continue
#             try:
#                 msg = json.loads(line)
#             except Exception:
#                 continue

#             # Token usage (nested under message.usage in transcript)
#             usage = msg.get("usage") or msg.get("message", {}).get("usage", {})
#             if not isinstance(usage, dict):
#                 usage = {}
#             input_tokens       += usage.get("input_tokens", 0)
#             output_tokens      += usage.get("output_tokens", 0)
#             cache_read_tokens  += usage.get("cache_read_input_tokens", 0)
#             cache_write_tokens += usage.get("cache_creation_input_tokens", 0)

#             # Tool calls
#             content = msg.get("content") or msg.get("message", {}).get("content", [])
#             if isinstance(content, list):
#                 tool_call_count += sum(1 for b in content if isinstance(b, dict) and b.get("type") == "tool_use")

#             # Duration
#             ts = msg.get("timestamp")
#             if ts:
#                 if first_ts is None:
#                     first_ts = ts
#                 last_ts = ts

#     # Cost at fixed rates (per 1M tokens)
#     cost = (
#         input_tokens       * 3.00 / 1_000_000 +
#         output_tokens      * 15.00 / 1_000_000 +
#         cache_read_tokens  * 0.30  / 1_000_000 +
#         cache_write_tokens * 3.75  / 1_000_000
#     )

#     duration = 0
#     if first_ts and last_ts and first_ts != last_ts:
#         from datetime import datetime
#         def parse_ts(s):
#             s = s.replace("Z", "+00:00")
#             return datetime.fromisoformat(s)
#         try:
#             duration = int((parse_ts(last_ts) - parse_ts(first_ts)).total_seconds())
#         except Exception:
#             duration = 0

#     print(json.dumps({
#         "input_tokens":       input_tokens,
#         "output_tokens":      output_tokens,
#         "cache_read_tokens":  cache_read_tokens,
#         "cache_write_tokens": cache_write_tokens,
#         "cost_usd":           round(cost, 6),
#         "duration_seconds":   duration,
#         "tool_call_count":    tool_call_count,
#     }))
# except Exception:
#     pass
# PYEOF
#     ) || USAGE_FIELDS=""
#   fi
# fi

# # ── Build payload ───────────────────────────────────────────────────────────
# if [ "$EVENT" = "stop" ]; then
#   if [ -n "$USAGE_FIELDS" ]; then
#     # Merge usage fields into stop payload
#     PAYLOAD=$(python3 -c "
# import json, sys
# base = {\"event\":\"stop\",\"session_id\":\"$SESSION_ID\",\"account_label\":\"$ACCOUNT_LABEL\"}
# usage = json.loads(sys.argv[1])
# base.update(usage)
# print(json.dumps(base))
# " "$USAGE_FIELDS" 2>/dev/null) || \
#     PAYLOAD="{\"event\":\"stop\",\"session_id\":\"$SESSION_ID\",\"account_label\":\"$ACCOUNT_LABEL\"}"
#   else
#     PAYLOAD="{\"event\":\"stop\",\"session_id\":\"$SESSION_ID\",\"account_label\":\"$ACCOUNT_LABEL\"}"
#   fi
# else
#   if [ -n "$FEATURES_JSON" ]; then
#     FEATURES_ESCAPED=$(echo "$FEATURES_JSON" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read().strip()))")
#     PAYLOAD="{\"event\":\"heartbeat\",\"session_id\":\"$SESSION_ID\",\"tokens_used\":0,\"tokens_limit\":200000,\"account_label\":\"$ACCOUNT_LABEL\",\"features_json\":$FEATURES_ESCAPED}"
#   else
#     PAYLOAD="{\"event\":\"heartbeat\",\"session_id\":\"$SESSION_ID\",\"tokens_used\":0,\"tokens_limit\":200000,\"account_label\":\"$ACCOUNT_LABEL\"}"
#   fi
# fi

# curl -s -o /dev/null -m 3 \
#   -X POST "$CLAUDE_DASHBOARD_URL/api/ingest" \
#   -H "Content-Type: application/json" \
#   -H "Authorization: Bearer $CLAUDE_DASHBOARD_API_KEY" \
#   -d "$PAYLOAD" || true

# exit 0
