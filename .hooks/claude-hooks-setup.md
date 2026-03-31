# Claude Code Hooks Setup

Connects a Claude Code session to the observability dashboard via three lifecycle hooks.

---

<!--## Prerequisites

Set these env vars in your shell profile (`~/.zshrc` or `~/.bashrc`):

```bash
export CLAUDE_DASHBOARD_URL=https://your-dashboard.vercel.app
export CLAUDE_DASHBOARD_API_KEY=<your-api-key>
export CLAUDE_ACCOUNT_LABEL=my-project          # unique per agent/project
export CLAUDE_SESSION_ID=$(uuidgen)             # or any unique string per session

# Optional — only needed if FEATURE.md is not auto-discovered
export CLAUDE_FEATURE_MD_PATH=/path/to/FEATURE.md
```

Reload your shell: `source ~/.zshrc`

---

## Hook script

`hooks/ingest.sh` handles all three events. Make it executable:

```bash
chmod +x hooks/ingest.sh
```

---

## settings.json

Add the following to `.claude/settings.json` (replace the absolute path with the correct location for your machine):

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/absolute/path/to/hooks/ingest.sh heartbeat"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "/absolute/path/to/hooks/ingest.sh heartbeat"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/absolute/path/to/hooks/ingest.sh stop"
          }
        ]
      }
    ]
  }
}
```

---

## Hook behaviour

| Hook | Fires when | Payload | Dashboard effect |
|---|---|---|---|
| `UserPromptSubmit` | User submits a prompt | `heartbeat` | Status → `working` within ~2s of prompt submit |
| `PostToolUse` | After each tool call | `heartbeat` + feature sync | Keeps status `working`; updates feature backlog |
| `Stop` | Claude stops or waits | `stop` | Status → `stopped` |

**Why UserPromptSubmit matters:** without it, status stays `stopped` during the entire prompt-processing window (from user submit until the first tool call fires). For prompts that require reasoning before tool use, this gap can be several seconds. `UserPromptSubmit` closes it.

---

## Validation

After starting a Claude Code session, confirm events are reaching Neon:

```sql
-- Check session status updated to working
SELECT session_id, account_label, status, last_seen
FROM sessions
ORDER BY last_seen DESC
LIMIT 5;

-- Check heartbeat events recorded
SELECT session_id, tokens_used, snapshot_at
FROM token_events
ORDER BY snapshot_at DESC
LIMIT 5;
```

---

## Adding a second agent

On the remote machine's project:

```bash
mkdir -p hooks .claude
cp /path/to/this/repo/hooks/ingest.sh hooks/
cp /path/to/this/repo/.claude/settings.json .claude/
chmod +x hooks/ingest.sh
```

Set env vars with a unique `CLAUDE_ACCOUNT_LABEL` — the dashboard shows a separate card per label.-->
