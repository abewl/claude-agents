# DICT.md — Function & Pattern Glossary

Project-specific patterns, naming conventions, and function signatures. Updated by CLAUDE-PM when a feature introduces or deprecates a pattern. Claude-as-engineer reads this before implementing; does not edit directly.

---

## Naming Conventions

- API routes: `app/api/<resource>/route.ts` — one file per resource, named by noun not verb
- Components: PascalCase, co-located under `app/dashboard/components/`
- DB exports: `sessions`, `tokenEvents`, `githubEvents` — camelCase table references
- Types: inferred from schema via `typeof table.$inferSelect`, exported from `schema.ts`
- Env vars: `SCREAMING_SNAKE_CASE`, documented in `.env.example`

---

## API Route Patterns

**Auth check (ingest endpoint)**
```ts
function authenticate(request: NextRequest): boolean {
  const authHeader = request.headers.get("authorization");
  if (!authHeader?.startsWith("Bearer ")) return false;
  return authHeader.slice(7) === process.env.CLAUDE_DASHBOARD_API_KEY;
}
```

**`/api/data` — multi-agent state endpoint**
- GET returns `{ agents: AgentState[] }`, deduplicated by `accountLabel` (latest session per label)
- Runs staleness check inline before responding
- Returns HTTP 500 with `{ agents: [] }` on DB error (never silently drops data)
- Will include `tokensUsed` / `tokensLimit` per agent once F-24 is implemented

**`/api/features` — server-side FEATURE.md reader**
- GET reads FEATURE.md from `path.join(process.cwd(), '..', 'FEATURE.md')` and returns `{ features: Feature[] }`
- Local dev fallback for when `ingest.sh` is not running (complements hook-based `features_json`)
- Returns `{ features: [] }` with HTTP 500 on read error

**`/api/github` — GitHub Actions & PR live data**
- GET fetches open PRs and recent workflow runs via GitHub REST API
- Requires `GITHUB_TOKEN`, `GITHUB_OWNER`, `GITHUB_REPO` env vars
- Returns `{ error, pulls: [], runs: [] }` HTTP 200 when unconfigured (graceful degradation pattern)

**Graceful degradation (GitHub route)**
- When env vars are missing, return `{ error: "...", pulls: [], runs: [] }` with HTTP 200
- Never return a 5xx for missing config — UI handles the unconfigured state

**SSE stream pattern**
```ts
const stream = new ReadableStream({
  async start(controller) {
    let active = true;
    while (active) {
      try {
        controller.enqueue(encoder.encode(`data: ${JSON.stringify(payload)}\n\n`));
      } catch { active = false; }
      await new Promise(r => setTimeout(r, POLL_INTERVAL_MS));
    }
    try { controller.close(); } catch {}
  }
});
return new NextResponse(stream, { headers: { "Content-Type": "text/event-stream", ... } });
```

---

## Types

**`ParsedFeature`** — exported from `lib/db/schema.ts`. Canonical feature type used across ingest, API, and UI.
```ts
interface ParsedFeature {
  id: string;       // e.g. "F-01"
  name: string;
  status: string;   // e.g. "done", "todo", "in progress"
}
```

**`AgentState`** — returned by `/api/data` per agent entry.
```ts
interface AgentState {
  sessionId: string;
  accountLabel: string;
  status: "working" | "stopped" | "needs_attention";
  lastSeen: string;
  features: ParsedFeature[];
  usage: UsageData | null;   // null until first stop event with transcript data
}
```

**`UsageData`** — usage snapshot from a completed session. Stored as `sessions.usage_json`.
```ts
interface UsageData {
  inputTokens: number;
  outputTokens: number;
  cacheReadTokens: number;
  cacheWriteTokens: number;
  costUsd: number;           // calculated at fixed rates: in $3/M, out $15/M, cache_read $0.30/M, cache_write $3.75/M
  durationSeconds: number;
  toolCallCount: number;
}
```

---

## Database Patterns

**Upsert pattern (sessions)**
```ts
await db.insert(sessions)
  .values({ sessionId, status, lastSeen: new Date() })
  .onConflictDoUpdate({
    target: sessions.sessionId,
    set: { status, lastSeen: new Date() },
  });
```

**`features_json` column** — `sessions.features_json TEXT` stores a serialised `ParsedFeature[]` array.

**`usage_json` column** — `sessions.usage_json TEXT` stores a serialised `UsageData` object. Written by `/api/ingest` on stop events that include transcript-parsed usage fields. Null until the agent's first stop event with a valid transcript. Written by `/api/ingest` on heartbeat; deserialised by `/api/data`. `null` if the agent's hook did not send feature data.

**Latest-row query**
```ts
const [row] = await db.select().from(table).orderBy(desc(table.createdAt)).limit(1);
```

**Staleness update**
```ts
await db.update(sessions)
  .set({ status: "needs_attention" })
  .where(and(eq(sessions.status, "working"), lt(sessions.lastSeen, cutoff)));
```

---

## UI Component Patterns

**Polling hook — dashboard page (3s interval, /api/data)**
> ⚠️ EventSource SSE was replaced in v04 due to unreliable delivery in Next.js App Router dev mode.
```ts
useEffect(() => {
  let cancelled = false;
  const poll = async () => {
    const res = await fetch("/api/data");
    const data = await res.json();
    if (!cancelled) setState(data);
  };
  poll();
  const interval = setInterval(poll, 3_000);
  return () => { cancelled = true; clearInterval(interval); };
}, []);
```

**Polling hook (GithubRow — 30s interval)**
```ts
useEffect(() => {
  const fetchData = async () => { ... };
  fetchData();
  const interval = setInterval(fetchData, 30_000);
  return () => clearInterval(interval);
}, []);
```

**`UsageBar`** — segmented horizontal bar inside `InstanceRow`, after `FeatureList`. Segments sized proportionally to total tokens; colour-coded: input (green), output (blue), cache read (amber), cache write (purple). Header shows total token count + formatted cost. Only renders when `agent.usage !== null`.

**`UsageTable`** — compact two-column label/value table below `UsageBar`. Rows: Input tokens, Output tokens, Cache read, Cache write, Estimated cost, Duration, Tool calls. Only renders when `agent.usage !== null`.

**Cost rate constants** (defined once, imported by UsageBar/UsageTable and ingest.sh):
```
input:       $3.00 / 1M tokens
output:      $15.00 / 1M tokens
cache_read:  $0.30 / 1M tokens
cache_write: $3.75 / 1M tokens
```

**Status colour maps** — defined as `Record<Status, string>` using Tailwind classes, not inline styles. Pattern: `"text-{colour}-400 border-{colour}-700"`.

---

## Hook Lifecycle

Three hooks wire Claude Code events to the dashboard. All call `hooks/ingest.sh`:

| Hook | Event | Payload | Effect |
|---|---|---|---|
| `UserPromptSubmit` | User submits a prompt | `heartbeat` | Status → `working` immediately (F-25) |
| `PostToolUse` | After each tool call | `heartbeat` | Status → `working`, feature sync |
| `Stop` | Claude stops / waits | `stop` + usage fields | Status → `stopped`; usage panel populated |

**settings.json pattern**
```json
"hooks": {
  "UserPromptSubmit": [{ "hooks": [{ "type": "command", "command": "/path/to/hooks/ingest.sh heartbeat" }] }],
  "PostToolUse":      [{ "matcher": "", "hooks": [{ "type": "command", "command": "/path/to/hooks/ingest.sh heartbeat" }] }],
  "Stop":             [{ "hooks": [{ "type": "command", "command": "/path/to/hooks/ingest.sh stop" }] }]
}
```

The `UserPromptSubmit` hook closes the status gap that existed when Claude was processing a prompt but had not yet made any tool call.

---

## Environment Variables

| Variable | Used by | Purpose |
|---|---|---|
| `DATABASE_URL` | Drizzle / Neon driver | Neon connection string |
| `CLAUDE_DASHBOARD_API_KEY` | `/api/ingest` | Bearer token auth for hook events |
| `CLAUDE_DASHBOARD_URL` | Claude Code hooks (local) | Dashboard base URL for curl POSTs |
| `SESSION_STALE_THRESHOLD_MINUTES` | `/api/stream`, `/api/stale` | Minutes before silent session becomes needs_attention (default: 5) |
| `GITHUB_TOKEN` | `/api/github` | Fine-grained PAT, read access to Actions + PRs |
| `GITHUB_OWNER` | `/api/github` | GitHub username or org |
| `GITHUB_REPO` | `/api/github` | Repository name |
| `CLAUDE_SESSION_ID` | Claude Code hooks (local) | Unique session identifier per project |
| `CLAUDE_ACCOUNT_LABEL` | Claude Code hooks (local) | Human-readable instance label shown in dashboard |
| `CLAUDE_FEATURE_MD_PATH` | `hooks/ingest.sh` | Explicit path to FEATURE.md; if unset, script auto-discovers by walking up 3 parent dirs |
