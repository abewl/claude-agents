# SPEC.md — Acceptance Criteria Glossary

AC items are append-only. Revise in place when behavior changes; never delete historical entries.

---

## Project Scaffold & Database Setup (F-01)

- AC-01: Next.js 14 app initialises and runs locally with no errors. Tailwind CSS applies base styles. Drizzle ORM is configured with the Neon serverless driver.
- AC-02: Drizzle migration runs successfully against Neon and creates `sessions`, `token_events`, and `github_events` tables with the schema defined in PROJECT.md.
- AC-03: Vercel project is linked to the repo. `CLAUDE_DASHBOARD_API_KEY` and `DATABASE_URL` environment variables are set and accessible to the app at runtime.

---

## Ingest API Endpoint (F-02)

- AC-04: POST to `/api/ingest` with a valid bearer token and `event: heartbeat` payload upserts the session row in Neon (creating if new, updating `status` to `working` and `last_seen` to now) and inserts a `token_events` row. Returns HTTP 200.
- AC-05: POST to `/api/ingest` with a valid bearer token and `event: stop` payload updates the session `status` to `stopped` and `last_seen` to now. Returns HTTP 200.
- AC-06: POST to `/api/ingest` with a missing or invalid bearer token returns HTTP 401 and does not write to the database.

---

## Claude Code Hook Configuration (F-03)

- AC-07: `.claude/settings.json` hook configuration fires a POST to `/api/ingest` with a `heartbeat` event on every `postToolUse` lifecycle event during a live Claude Code session. Confirmed by a corresponding row appearing in `token_events` in Neon.
- AC-08: `.claude/settings.json` hook configuration fires a POST to `/api/ingest` with a `stop` event when Claude Code stops. Confirmed by the session `status` updating to `stopped` in Neon.

---

## SSE Stream Endpoint (F-04)

- AC-09: GET to `/api/stream` returns a valid `text/event-stream` response. The stream emits an update within 5 seconds containing the latest session status and most recent token usage values from Neon.
- AC-10: When the browser client disconnects, the SSE connection closes cleanly with no unhandled errors or dangling Neon connections server-side.

---

## Dashboard Page & Layout (F-05)

- AC-11: `/dashboard` renders three visually distinct stacked rows in the correct order: Row 1 (instance status), Row 2 (token consumption), Row 3 (GitHub placeholder). Layout is responsive down to 768px width.
- AC-12: The dashboard page opens an SSE connection to `/api/stream` on load and updates row content reactively when stream events are received, without a full page reload.

---

## Instance Status Row — Animated Working State (F-06)

- AC-13: When session status is `working`, Row 1 displays a green indicator and an animated terminal-style blinking cursor with scrolling tool activity text. Animation runs continuously while status remains `working`.
- AC-14: When session status is `stopped`, Row 1 displays a grey indicator and static "Stopped" label. No animation.
- AC-15: When session status is `needs_attention`, Row 1 displays an amber indicator and static "Needs attention" label. No animation.

---

## Token Consumption Row (F-07)

- AC-16: Row 2 displays a horizontal progress bar. Bar fill width corresponds to `tokens_used / tokens_limit` as a percentage. Percentage label is shown numerically alongside the bar.
- AC-17: While session status is `working`, the progress bar updates its fill and label each time a new token_event arrives via the SSE stream.
- AC-18: When `tokens_used >= tokens_limit`, the bar renders at 100% fill in red and displays the label "Context limit reached". Normal colour scheme otherwise.

---

## GitHub Actions & PR Row — Placeholder (F-08)

- AC-19: Row 3 renders a clearly labelled placeholder section. Static tiles display each of the four CI states (pending, running, passed, failed) with distinct styled badges.
- AC-20: Static tiles display each of the three PR states (open, merged, closed) with distinct styled badges. All tiles are visually marked as placeholder (e.g. greyed border, "placeholder" label). No GitHub API calls are made.

---

## Session Staleness & Needs-Attention Detection (F-09)

- AC-21: A server-side process (API route or Neon scheduled function) checks sessions where `last_seen` is older than 5 minutes and `status` is not `stopped`. It updates those sessions' `status` to `needs_attention`.
- AC-22: The staleness threshold is configurable via an environment variable (`SESSION_STALE_THRESHOLD_MINUTES`, default 5). Changing the value takes effect without a code change.

---

## Vercel Production Deploy & End-to-End Validation (F-10)

- AC-23: App deploys to Vercel production with zero build errors. Drizzle migrations run successfully against the Neon production database on first deploy.
- AC-24: A live Claude Code session with hooks configured fires heartbeat events that appear as `working` status and token_event rows in the Neon production database within 10 seconds of each tool call.
- AC-25: The production dashboard at the Vercel URL reflects the correct instance status, token consumption percentage, and placeholder GitHub row in real time, driven by the live SSE stream.

---

## CONFIG.md Schema, CLI Setup, and Stream Protocol (F-11)

- AC-26: When CONFIG.md does not exist and `[START]` is triggered, CLAUDE-PM presents the integration mode prompt — `[1] Integration` and `[2] MD-only` — before any other action. No batch authoring begins until the user replies.
- AC-27: After user selects a mode, CLAUDE-PM writes CONFIG.md to repo root containing: mode value, integration settings (Stream A only), and the full Context Stream Protocol block (all five sections) for the chosen mode.
- AC-28: Stream A CONFIG.md contains all five protocol sections with MCP references: Session Start, CLAUDE-PM Batch Start, CLAUDE-PM Feature Draft, CLAUDE-PM Batch Completion Assessment, Engineering Loop.
- AC-29: Stream B CONFIG.md contains the same five sections with no MCP references. Ticket and Confluence fields are absent. Engineering Loop section is identical to Stream A.

---

## Agent Session Start — CONFIG.md Protocol (F-12)

- AC-30: AGENT.md session start sequence lists CONFIG.md as the second file read, immediately after PROJECT.md and before FEATURE.md.
- AC-31: AGENT.md states that Claude follows the Session Start steps defined inside CONFIG.md, not a hardcoded sequence in AGENT.md itself.
- AC-32: AGENT.md context reset protocol states: if CONFIG.md is absent on reset, Claude issues a hard stop and prompts the human to run setup before proceeding. No iteration resumes without CONFIG.md.

---

## Context Stream Protocol — AGENT.md Decoupling (F-13)

- AC-33: AGENT.md CLAUDE-PM protocol sections reference CONFIG.md as the source of operational steps rather than defining them inline. AGENT.md describes structure and ownership; CONFIG.md carries execution.
- AC-34: AGENT.md engineering loop section contains no stream-conditional steps. It is identical regardless of integration mode.

---

## context/ Directory Protocol (F-14)

- AC-35: `context/` is listed in .gitignore at repo root. No context files are ever committed.
- AC-36: README documents the reset command (`rm -rf context/`), its purpose, and the per-project scope. Notes that context/ is safe for open source and multi-user use.
- AC-37: CLAUDE-PM.md states that in Stream A, CLAUDE-PM checks whether context/ exists and contains files before calling Confluence MCP. If context/ is populated, CLAUDE-PM reads existing files and skips the fetch unless the human explicitly requests a refresh.

---

## MCP Server Configuration (F-15)

- AC-38: `.claude/settings.json` template contains a `mcpServers` block with Confluence and Jira entries, each referencing their required env vars.
- AC-39: `.env.example` documents all MCP env vars: `CONFLUENCE_URL`, `CONFLUENCE_USERNAME`, `CONFLUENCE_API_TOKEN`, `CONFLUENCE_SPACE_KEY`, `JIRA_URL`, `JIRA_USERNAME`, `JIRA_API_TOKEN`, `JIRA_PROJECT_KEY`.
- AC-40: README MCP section clearly marks these vars as optional and Stream A only. Stream B users are not required to set them.

---

## CLAUDE-PM Confluence Enrichment Protocol — Stream A (F-16)

- AC-41: CLAUDE-PM.md contains a Batch Start section describing: call Confluence MCP with space_key from CONFIG.md, receive pages, write each to `context/<slug>.md`, read context/ before authoring FEATURE.md.
- AC-42: AGENT.md CLAUDE-PM batch start section states steps are defined in CONFIG.md and references CLAUDE-PM.md for Confluence-specific detail. No Confluence steps are hardcoded in AGENT.md.

---

## FEATURE.md Format — Ticket Field (F-17)

- AC-43: AGENT.md FEATURE.md backlog format includes `Ticket: PROJ-XXX` as a defined field between AC and Description lines.
- AC-44: AGENT.md AC coupling rules include a note that Ticket field is populated in Stream A and left blank in Stream B. A blank Ticket field in Stream B is not a protocol violation.

---

## CLAUDE-PM Jira Ticket Creation — Stream A (F-18)

- AC-45: CLAUDE-PM.md contains a Feature Draft section describing: for each F-XX entry, call Jira MCP to create a Story in project_key with feature title, description, and AC items as acceptance criteria. Write returned ticket ID to FEATURE.md Ticket field.
- AC-46: AGENT.md CLAUDE-PM feature draft section states Jira creation steps are defined in CONFIG.md and references CLAUDE-PM.md for detail. No Jira steps hardcoded in AGENT.md.

---

## CLAUDE-PM Jira Lifecycle — Batch Completion Assessment — Stream A (F-19)

- AC-47: CLAUDE-PM.md contains a Batch Completion section describing three Jira transitions: `[x] done` → transition ticket to Done; `[!] blocked` → add comment with blocked reason, leave ticket open; `[-] deprecated` → close as Won't Do with deprecation reason.
- AC-48: AGENT.md batch completion section states Jira lifecycle steps are defined in CONFIG.md and references CLAUDE-PM.md for detail. Human monitors Jira independently — no dashboard action required.

---

## /api/data Polling Client — SSE Replacement & Client Fix (F-20)

- AC-49: GET `/api/data` returns `{ session, token }` as JSON. Runs the same staleness check as the stream loop. Returns `{ session: null, token: null }` with HTTP 500 on DB error (visible in console).
- AC-50: Dashboard page replaces `EventSource("/api/stream")` with `setInterval` polling `fetch("/api/data")` every 3 seconds. A `cancelled` flag prevents state updates after component unmount.
- AC-51: `InstanceRow` renders exactly one status label when `session` is null: `"○ no session"`. Status indicators (working/stopped/needs_attention) are guarded by `session &&` and do not render alongside the null label.

---

## Multi-Agent Dashboard Support (F-21)

- AC-52: `sessions` table contains a `features_json TEXT` column. `ParsedFeature` interface is exported from `schema.ts` as the canonical feature type used across ingest, API, and UI layers.
- AC-53: `hooks/ingest.sh` reads the local `FEATURE.md` and serialises it as `ParsedFeature[]` JSON on every heartbeat. `CLAUDE_FEATURE_MD_PATH` env var overrides path; if unset, the script auto-discovers `FEATURE.md` by walking up 3 parent directories. If FEATURE.md is not found or Python3 is unavailable, `features_json` is omitted silently without failing the hook.
- AC-54: GET `/api/data` returns `{ agents: AgentState[] }` — all sessions, deduplicated by `accountLabel` (latest row per label). Each `AgentState` includes parsed `ParsedFeature[]` deserialised from `features_json`.
- AC-55: Dashboard page renders one `InstanceRow` per agent in the `agents` array. Each card embeds `FeatureList` inline below the instance status line. When `agents` is empty, the page displays `"No active sessions."` in place of cards.

---

## GitHub Actions & PR Row — Live Data Integration (F-22)

- AC-56: GET `/api/github` fetches open PRs and recent workflow runs from the GitHub REST API using `GITHUB_TOKEN`, `GITHUB_OWNER`, `GITHUB_REPO`. Normalises raw GitHub statuses to dashboard enums: CI (`pending` / `running` / `passed` / `failed`), PR (`open` / `merged` / `closed`). Returns `{ pulls, runs }`.
- AC-57: `GithubRow` polls `/api/github` every 30 seconds. Live CI run rows show branch name, status badge, and link. Live PR rows show number, title, status badge, and link. Up to 5 CI runs and 10 PRs are displayed.
- AC-58: When `GITHUB_TOKEN`, `GITHUB_OWNER`, or `GITHUB_REPO` are missing, `/api/github` returns `{ error: "GitHub integration not configured", pulls: [], runs: [] }` with HTTP 200. `GithubRow` renders a "not configured" label and instructions to set env vars. No 5xx response or runtime crash.

---

## /api/features — Server-Side FEATURE.md Reader (F-23)

- AC-59: GET `/api/features` reads `FEATURE.md` from the filesystem at `path.join(process.cwd(), '..', 'FEATURE.md')`. Parses `## F-XX: Title` headings and `- Status:` lines into a `Feature[]` array (`id`, `title`, `status`). Returns `{ features: Feature[] }`.
- AC-60: If `FEATURE.md` is not found or cannot be read, `/api/features` returns `{ features: [] }` with HTTP 500. The route does not throw an unhandled error.

---

## Token Bar — Re-integration in Multi-Agent Layout (F-24)

> **Deprecated** — token bar de-prioritised. Hook sends tokens_used: 0 (PostToolUse stdin does not expose token counts), making the bar non-functional regardless of layout fix. ACs below are void.

- AC-61: ~~`AgentState` interface in `/api/data` includes `tokensUsed: number` and `tokensLimit: number`.~~ (deprecated)
- AC-62: ~~`TokenRow` is rendered inside `InstanceRow` for each agent.~~ (deprecated)
- AC-63: ~~When `tokensUsed >= tokensLimit`, red bar + "Context limit reached".~~ (deprecated)

---

## UserPromptSubmit Hook — Prompt-Processing Status Fix (F-25)

- AC-64: `.claude/settings.json` contains a `UserPromptSubmit` hook entry that calls `hooks/ingest.sh heartbeat`. The hook fires as soon as the user submits a prompt, before any tool call occurs.
- AC-65: After a user submits a prompt, the session status in Neon updates to `working` within 3 seconds (network round-trip for the heartbeat curl call). The dashboard UI reflects `working` state on the next poll cycle (≤3s further). Total observable latency from prompt submit to dashboard update: ≤6s.
- AC-66: `claude-hooks-setup.md` and the `hooks` section of `PROJECT.md` are updated to document the `UserPromptSubmit` hook alongside the existing `PostToolUse` and `Stop` hooks.

---

## Per-Instance Usage Panel (F-26)

- AC-67: `sessions` table has a `usage_json TEXT` column. Drizzle migration is generated and applied. Column is nullable — null until a stop event with transcript data is received.

- AC-68: On `Stop` hook, `ingest.sh` reads stdin JSON and extracts `transcript_path`. An embedded Python3 script parses the JSONL transcript and computes: `input_tokens` (sum of all `usage.input_tokens`), `output_tokens` (sum of all `usage.output_tokens`), `cache_read_tokens` (sum of `usage.cache_read_input_tokens`), `cache_write_tokens` (sum of `usage.cache_creation_input_tokens`), `tool_call_count` (count of `tool_use` content blocks), `duration_seconds` (timestamp of last message minus first message). `cost_usd` is calculated at fixed rates: input $3/M, output $15/M, cache_read $0.30/M, cache_write $3.75/M. All fields are included in the stop payload. If `transcript_path` is absent or the parse fails, stop event is sent without usage fields (graceful omission, existing stop logic unaffected).

- AC-69: `/api/ingest` stop handler accepts optional usage fields (`input_tokens`, `output_tokens`, `cache_read_tokens`, `cache_write_tokens`, `cost_usd`, `duration_seconds`, `tool_call_count`) and writes them as a JSON object to `sessions.usage_json`. Existing stop logic (status → `stopped`, `last_seen` updated) is unchanged.

- AC-70: `AgentState` in `/api/data` includes `usage: UsageData | null`. `UsageData` has fields: `inputTokens`, `outputTokens`, `cacheReadTokens`, `cacheWriteTokens`, `costUsd`, `durationSeconds`, `toolCallCount`. Populated by deserialising `sessions.usage_json`; null if column is null.

- AC-71: `UsageBar` component renders a segmented horizontal bar inside `InstanceRow` after `FeatureList`. Bar segments are colour-coded: input tokens (green), output tokens (blue), cache read tokens (amber), cache write tokens (purple) — sized proportionally to total tokens. Above the bar: total token count and formatted cost (`$X.XXX`). Only renders when `agent.usage !== null`.

- AC-72: `UsageTable` component renders a compact two-column table (label / value) below `UsageBar` with all `UsageData` fields: Input tokens, Output tokens, Cache read, Cache write, Estimated cost, Duration (formatted as `Xm Xs`), Tool calls. Only renders when `agent.usage !== null`.

- AC-73: Usage panel data is available within 3 seconds of Claude stopping. On the next `/api/data` poll cycle after the stop event is processed, `agent.usage` is non-null and both `UsageBar` and `UsageTable` reflect the completed session values.
