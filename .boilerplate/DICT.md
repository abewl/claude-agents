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

**`/api/features` — feature list endpoint**
- GET returns raw features for a session; used by FeatureList when not bundled with agent state

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
  tokensUsed: number;
  tokensLimit: number;
  features: ParsedFeature[];
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

**`features_json` column** — `sessions.features_json TEXT` stores a serialised `ParsedFeature[]` array. Written by `/api/ingest` on heartbeat; deserialised by `/api/data`. `null` if the agent's hook did not send feature data.

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

**Status colour maps** — defined as `Record<Status, string>` using Tailwind classes, not inline styles. Pattern: `"text-{colour}-400 border-{colour}-700"`.

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
