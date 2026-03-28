# PROJECT.md — Agentic Workflow Observability Dashboard

## Overview

A real-time observability dashboard that integrates with Claude Code CLI (and other terminal-based agentic LLM tools) to surface instance status, token consumption, and CI/PR activity in a single UI. Built for developers running agentic workflows who need visibility into what Claude is doing, how much token budget remains, and what state their GitHub pipeline is in — without leaving the browser.

Initial scope: single Claude Code instance. Architecture supports multi-instance expansion.

---

## Tech Stack

| Layer | Choice | Reason |
|---|---|---|
| Frontend | Next.js 14 (App Router) | SSR + API routes in one deploy, good real-time support |
| Database | Neon Postgres (serverless) | Vercel-native, free tier, scales to zero |
| Hosting | Vercel (free tier) | Zero-config deploy, edge functions, pairs with Neon |
| Realtime | Server-Sent Events (SSE) via Next.js route handlers | No extra infra, works on Vercel free tier |
| Styling | Tailwind CSS | Utility-first, terminal aesthetic easy to achieve |
| ORM | Drizzle ORM | Lightweight, type-safe, works well with Neon serverless driver |

---

## Architecture

```
Claude Code CLI (local)
    │
    │  Claude Code hooks (postToolUse, stop)
    │  → HTTP POST to /api/ingest (webhook)
    │  → Auth: CLAUDE_DASHBOARD_API_KEY env var
    │
    ▼
Vercel (Next.js)
    ├── /api/ingest        — receives hook events, writes to Neon
    ├── /api/stream        — SSE endpoint, polls Neon and streams to browser
    ├── /api/github        — fetches GitHub Actions + PR status (GitHub API)
    └── /dashboard         — UI page
    │
    ▼
Neon Postgres
    ├── sessions           — instance identity and status
    ├── token_events       — token usage snapshots per session
    └── github_events      — CI run and PR state snapshots (placeholder)
```

---

## Claude Code Integration

### How events are captured

Claude Code supports hooks: shell commands that fire on lifecycle events. Two hooks are used:

- `postToolUse` — fires after each tool call. Sends a working heartbeat with token snapshot.
- `stop` — fires when Claude stops (session end or wait). Sends a stopped or needs_attention status.

Hooks are configured in `.claude/settings.json`:

```json
{
  "hooks": {
    "postToolUse": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "curl -s -X POST $CLAUDE_DASHBOARD_URL/api/ingest -H 'Content-Type: application/json' -H 'Authorization: Bearer $CLAUDE_DASHBOARD_API_KEY' -d '{\"event\":\"heartbeat\",\"session_id\":\"$CLAUDE_SESSION_ID\"}'"
          }
        ]
      }
    ],
    "stop": [
      {
        "type": "command",
        "command": "curl -s -X POST $CLAUDE_DASHBOARD_URL/api/ingest -H 'Content-Type: application/json' -H 'Authorization: Bearer $CLAUDE_DASHBOARD_API_KEY' -d '{\"event\":\"stop\",\"session_id\":\"$CLAUDE_SESSION_ID\"}'"
      }
    ]
  }
}
```

### Credentials

| Variable | Where set | Purpose |
|---|---|---|
| `CLAUDE_DASHBOARD_URL` | local shell / `.env` | Dashboard Vercel URL |
| `CLAUDE_DASHBOARD_API_KEY` | local shell / `.env` | Bearer token for /api/ingest |

The same `CLAUDE_DASHBOARD_API_KEY` is set as a Vercel environment variable and validated server-side on every ingest request.

---

## Database Schema

### sessions
| Column | Type | Notes |
|---|---|---|
| id | uuid PK | |
| session_id | text unique | from Claude Code env |
| account_label | text | human-readable instance name |
| status | enum | working / stopped / needs_attention |
| last_seen | timestamptz | updated on every heartbeat |
| created_at | timestamptz | |

### token_events
| Column | Type | Notes |
|---|---|---|
| id | uuid PK | |
| session_id | text FK | |
| tokens_used | int | cumulative for session |
| tokens_limit | int | context window max |
| snapshot_at | timestamptz | |

### github_events (placeholder)
| Column | Type | Notes |
|---|---|---|
| id | uuid PK | |
| session_id | text FK | |
| pr_number | int | |
| pr_status | enum | open / merged / closed |
| ci_status | enum | pending / running / passed / failed |
| recorded_at | timestamptz | |

---

## Dashboard UI

The dashboard is a single `/dashboard` page with three stacked UI rows.

### Row 1 — Instance Status
Displays the Claude Code instance as a card. States:
- **Working** — animated terminal-style blinking cursor + scrolling tool activity text. Green indicator.
- **Stopped** — static, greyed out. Grey indicator.
- **Needs attention** — amber indicator, static label. Triggered when Claude stops mid-iteration (hard stop flag or blocked state).

### Row 2 — Token Consumption
Displays a horizontal progress bar for token usage (used / limit). States:
- **Working** — bar fills progressively, label shows percentage.
- **Out of tokens** — bar full, red state, label "Context limit reached".

### Row 3 — GitHub Actions & Pull Requests (placeholder)
Placeholder row showing:
- CI run status per feature branch: pending / running / passed / failed.
- Open PRs per iteration with status badge.
- Populated via GitHub API (PAT or GitHub App). Placeholder tiles with hardcoded states for initial scaffold.

---

## Deployment

1. Push repo to GitHub.
2. Connect to Vercel. Set env vars: `CLAUDE_DASHBOARD_API_KEY`, `DATABASE_URL` (from Neon).
3. Run Drizzle migrations against Neon on first deploy.
4. Set `CLAUDE_DASHBOARD_URL` and `CLAUDE_DASHBOARD_API_KEY` in local shell.
5. Add hooks config to `.claude/settings.json`.

No additional infra required. All within Vercel + Neon free tiers for single-instance use.
