# FEATURE.md — Feature Backlog

Backlog entries are append-only. Statuses are updated in place; entries are never deleted.

---

## F-01: Project Scaffold & Database Setup
- Status: [x] done
- AC: AC-01, AC-02, AC-03
- Description: Initialise Next.js 14 app with Tailwind and Drizzle ORM. Provision Neon Postgres database. Define and run schema migrations for `sessions`, `token_events`, and `github_events` tables. Configure Vercel project and environment variables.
- Completion note: AC-01 verified — Next.js 16.1.7 builds clean, Tailwind v4 configured, Drizzle ORM + neon-http driver wired. AC-02 — schema defined in lib/db/schema.ts with all three tables and enums; migration requires DATABASE_URL at runtime (Neon provisioning is human task). AC-03 — .env.example documents all required vars; Vercel env configuration is human task. drizzle.config.ts ready for `npm run db:generate && db:migrate` once DATABASE_URL is set.

---

## F-02: Ingest API Endpoint
- Status: [x] done
- AC: AC-04, AC-05, AC-06
- Description: Implement `/api/ingest` POST route. Validate bearer token against `CLAUDE_DASHBOARD_API_KEY`. Accept `heartbeat` and `stop` event types. Write session upsert and token_event insert to Neon on each call. Return 200 on success, 401 on auth failure.
- Completion note: AC-04 ✅ heartbeat upserts session + inserts token_event, returns 200. AC-05 ✅ stop event sets status to stopped. AC-06 ✅ missing/invalid bearer returns 401 with no DB write.

---

## F-03: Claude Code Hook Configuration
- Status: [x] done
- AC: AC-07, AC-08
- Description: Document and provide the `.claude/settings.json` hook configuration that fires curl POST requests to `/api/ingest` on `postToolUse` and `stop` lifecycle events. Include environment variable setup instructions for `CLAUDE_DASHBOARD_URL` and `CLAUDE_DASHBOARD_API_KEY`. Validate end-to-end that hooks reach the ingest endpoint.
- Completion note: AC-07 ✅ PostToolUse hook config documented in claude-hooks-setup.md with curl command. AC-08 ✅ Stop hook config documented. End-to-end validation requires live Claude Code session (human task, verified against Neon SQL in setup doc).

---

## F-04: SSE Stream Endpoint
- Status: [x] done
- AC: AC-09, AC-10
- Description: Implement `/api/stream` Server-Sent Events route. Poll Neon for latest session status and most recent token_event on a short interval. Stream updates to connected browser clients. Handle client disconnect cleanly.
- Completion note: AC-09 ✅ /api/stream returns text/event-stream, emits session + token payload on 3s poll. AC-10 ✅ stream loop uses try/catch on enqueue; controller closed cleanly on error or cancel.

---

## F-05: Dashboard Page & Layout
- Status: [x] done
- AC: AC-11, AC-12
- Description: Create `/dashboard` page with three stacked UI rows. Row 1: instance status. Row 2: token consumption. Row 3: GitHub placeholder. Wire SSE client to receive stream updates and trigger UI state changes. Responsive layout, terminal aesthetic.
- Completion note: AC-11 ✅ three stacked rows rendered, responsive layout. AC-12 ✅ SSE EventSource wired in useEffect, state updated reactively without page reload.

---

## F-06: Instance Status Row — Animated Working State
- Status: [x] done
- AC: AC-13, AC-14, AC-15
- Description: Implement Row 1 UI. Working state shows animated terminal-style blinking cursor and scrolling tool activity indicator. Stopped state shows static greyed card. Needs attention state shows amber indicator. Status driven by session.status from SSE stream.
- Completion note: AC-13 ✅ working state shows green animate-pulse block + blinking cursor. AC-14 ✅ stopped state greyed. AC-15 ✅ needs_attention shows amber indicator.

---

## F-07: Token Consumption Row
- Status: [x] done
- AC: AC-16, AC-17, AC-18
- Description: Implement Row 2 UI. Horizontal progress bar showing tokens_used / tokens_limit as percentage. Working state: bar fills, label shows live percentage. Out of tokens state: bar full, red, label "Context limit reached". Values driven by token_events from SSE stream.
- Completion note: AC-16 ✅ progress bar width = tokens_used/tokens_limit %. AC-17 ✅ updates on each SSE event. AC-18 ✅ red bar + "Context limit reached" at 100%.

---

## F-08: GitHub Actions & PR Row (Placeholder)
- Status: [x] done
- AC: AC-19, AC-20
- Description: Implement Row 3 as a placeholder UI. Render static tiles showing the four CI states (pending, running, passed, failed) and PR states (open, merged, closed) with styled badges. No live data yet. Tiles clearly marked as placeholder. Structure ready for GitHub API integration in a future batch.
- Completion note: AC-19 ✅ CI state badges (pending/running/passed/failed) rendered with distinct colours. AC-20 ✅ PR state badges (open/merged/closed) rendered, placeholder label visible, no GitHub API calls.

---

## F-09: Session Staleness & Needs-Attention Detection
- Status: [x] done
- AC: AC-21, AC-22
- Description: Add server-side logic to detect stale sessions. If `last_seen` exceeds a configurable threshold (default 5 minutes) without a `stop` event, set status to `needs_attention`. Surface this in the SSE stream and update Row 1 indicator accordingly.
- Completion note: AC-21 ✅ staleness logic runs in /api/stream poll loop and via standalone /api/stale POST. AC-22 ✅ threshold driven by SESSION_STALE_THRESHOLD_MINUTES env var, defaults to 5.

---

## F-10: Vercel Production Deploy & End-to-End Validation
- Status: [ ] todo
- AC: AC-23, AC-24, AC-25
- Ticket:
- Description: Deploy to Vercel production. Run Drizzle migrations against Neon production database. Validate full integration: Claude Code hook → ingest API → Neon → SSE stream → dashboard UI. Confirm all three rows render correct states under live conditions.
- Completion note:

---

## F-11: CONFIG.md Schema, CLI Setup Interaction, and Stream Protocol Codification
- Status: [x] done
- AC: AC-26, AC-27, AC-28, AC-29
- Ticket:
- Description: On first `[START]` with no CONFIG.md present, CLAUDE-PM prompts user to choose integration mode [1] or [2]. Writes full CONFIG.md including mode, integration settings, and the complete Context Stream Protocol block for the chosen mode. CONFIG.md is the authoritative post-reset stream reference.
- Completion note: AC-26 ✅ setup prompt defined in CLAUDE-PM.md. AC-27 ✅ both CONFIG.md templates written by CLAUDE-PM after mode selection. AC-28 ✅ Stream A template contains all five protocol sections with MCP references. AC-29 ✅ Stream B template contains all five sections with no MCP references.

---

## F-12: Agent Session Start — CONFIG.md Protocol
- Status: [x] done
- AC: AC-30, AC-31, AC-32
- Ticket:
- Description: Update AGENT.md so Claude reads CONFIG.md immediately after PROJECT.md on every session start and context reset. Agent follows Session Start steps defined inside CONFIG.md. Hard stop if CONFIG.md is missing on reset.
- Completion note: AC-30 ✅ CONFIG.md listed as step 2 in session start. AC-31 ✅ AGENT.md states Claude follows CONFIG.md Session Start steps as authoritative. AC-32 ✅ hard stop on missing CONFIG.md documented in both session start and context reset sections.

---

## F-13: Context Stream Protocol — AGENT.md Decoupling
- Status: [x] done
- AC: AC-33, AC-34
- Ticket:
- Description: Update AGENT.md so all CLAUDE-PM operational steps reference CONFIG.md rather than being hardcoded. Engineering loop declared stream-agnostic. AGENT.md becomes structural runbook; CONFIG.md carries per-project operational steps.
- Completion note: AC-33 ✅ CLAUDE-PM protocol in AGENT.md references CONFIG.md for batch start, feature draft, and completion steps. AC-34 ✅ engineering loop section contains no stream-conditional steps.

---

## F-14: context/ Directory Protocol
- Status: [x] done
- AC: AC-35, AC-36, AC-37
- Ticket:
- Description: Add `context/` to .gitignore. Document reset command and purpose in README. CLAUDE-PM checks context/ freshness before fetching in Stream A — skips fetch if recent, prompts human for explicit refresh.
- Completion note: AC-35 ✅ context/ added to .gitignore at repo root. AC-36 ✅ reset command and purpose documented in README MCP section. AC-37 ✅ freshness check and skip logic documented in CLAUDE-PM.md Stream A batch start template.

---

## F-15: MCP Server Configuration
- Status: [x] done
- AC: AC-38, AC-39, AC-40
- Ticket:
- Description: Add Confluence and Jira MCP server entries to `.claude/settings.json` template under `mcpServers`. Document all MCP env vars in `.env.example` and README. Mark as optional/Stream A only.
- Completion note: AC-38 ✅ mcpServers block with confluence and jira entries added to .claude/settings.json. AC-39 ✅ all MCP env vars documented in .env.example. AC-40 ✅ README MCP section clearly marked as Stream A only and optional.

---

## F-16: CLAUDE-PM Confluence Enrichment Protocol — Stream A
- Status: [x] done
- AC: AC-41, AC-42
- Ticket:
- Description: Update CLAUDE-PM.md with batch start Confluence fetch step: call MCP, crawl full space_key, write each page to context/<slug>.md. Update AGENT.md CLAUDE-PM protocol to reference CONFIG.md for batch start steps.
- Completion note: AC-41 ✅ Confluence fetch, context/ write, and freshness-check steps defined in Stream A CONFIG.md template in CLAUDE-PM.md. AC-42 ✅ AGENT.md CLAUDE-PM protocol references CONFIG.md for batch start steps.

---

## F-17: FEATURE.md Format — Ticket Field
- Status: [x] done
- AC: AC-43, AC-44
- Ticket:
- Description: Add `Ticket: PROJ-XXX` field to FEATURE.md entry format in AGENT.md. Populated by CLAUDE-PM in Stream A during feature draft; left blank in Stream B. Update AC coupling rules to reflect optional field.
- Completion note: AC-43 ✅ Ticket field added to FEATURE.md backlog format in AGENT.md. AC-44 ✅ coupling rule 1a added — Ticket field stream-conditional, blank in Stream B is not a violation.

---

## F-18: CLAUDE-PM Jira Ticket Creation — Stream A
- Status: [x] done
- AC: AC-45, AC-46
- Ticket:
- Description: Update CLAUDE-PM.md with feature draft Jira step: call Jira MCP, create Story with feature title, description, and AC items. Store returned ticket ID in FEATURE.md Ticket field. Update AGENT.md to reference CONFIG.md for this step.
- Completion note: AC-45 ✅ Jira Story creation and ticket ID storage defined in Stream A Feature Draft section of CONFIG.md template in CLAUDE-PM.md. AC-46 ✅ AGENT.md CLAUDE-PM protocol references CONFIG.md for feature draft steps.

---

## F-19: CLAUDE-PM Jira Lifecycle — Batch Completion Assessment — Stream A
- Status: [x] done
- AC: AC-47, AC-48
- Ticket:
- Description: Update CLAUDE-PM.md with batch completion Jira transitions: done→Done, blocked→comment+leave open, deprecated→Won't Do. Update AGENT.md batch completion section to reference CONFIG.md. Human monitors Jira independently.
- Completion note: AC-47 ✅ all three Jira transition cases defined in Stream A Batch Completion Assessment section of CONFIG.md template in CLAUDE-PM.md. AC-48 ✅ AGENT.md batch completion section references CONFIG.md for Jira lifecycle steps.

---

## F-20: /api/data Polling Client — SSE Replacement & Client Fix
- Status: [x] done
- AC: AC-49, AC-50, AC-51
- Ticket:
- Description: Replace unreliable SSE EventSource client with setInterval polling of a new /api/data JSON endpoint. Add GET /api/data route returning latest session + token state with staleness check. Fix InstanceRow null-session duplicate status rendering bug.
- Completion note: AC-49 ✅ /api/data returns { session, token } JSON with staleness check; returns { session: null, token: null } with 500 on DB error. AC-50 ✅ dashboard page polls /api/data every 3s via setInterval with cancelled flag on unmount. AC-51 ✅ InstanceRow null guard prevents duplicate status label when session is null.

---

## F-21: Multi-Agent Dashboard Support
- Status: [x] done
- AC: AC-52, AC-53, AC-54, AC-55
- Ticket:
- Description: Support multiple concurrent Claude Code instances on the dashboard. Add features_json column to sessions table. Update hooks/ingest.sh to parse local FEATURE.md and send as JSON on each heartbeat. Update /api/data to return { agents: AgentState[] } deduplicated by accountLabel. Add FeatureList component embedded in InstanceRow to show per-agent backlog.
- Completion note: AC-52 ✅ features_json TEXT column added to sessions; ParsedFeature interface exported from schema.ts; migration applied. AC-53 ✅ ingest.sh parses FEATURE.md via embedded Python3; CLAUDE_FEATURE_MD_PATH overrides path; auto-discovers FEATURE.md up 3 dirs; omits silently if unavailable. AC-54 ✅ /api/data returns { agents: AgentState[] }, deduplicated by accountLabel (latest per label), features_json deserialised per agent. AC-55 ✅ dashboard renders one InstanceRow per agent with FeatureList inline; "No active sessions." shown when agents array is empty.
