# changelog_v01.md

## Features: F-01 (AC-02 close-out), F-02, F-03, F-04, F-05, F-06, F-07, F-08, F-09

### Changes

**DB Migration (F-01 AC-02 close-out)**
- Ran `db:generate` — produced `lib/db/migrations/0000_nervous_proemial_gods.sql`
- Ran `db:migrate` against Neon production — all three tables and enums created successfully

**F-02 — Ingest API (`app/api/ingest/route.ts`)**
- POST endpoint with bearer token auth
- `heartbeat` event: upserts session to `working`, inserts token_event row
- `stop` event: upserts session to `stopped`
- Returns 401 on invalid/missing token, 400 on bad payload, 200 on success

**F-03 — Claude Code Hook Config (`claude-hooks-setup.md`)**
- PostToolUse and Stop hook configuration documented
- Environment variable setup instructions included
- Neon validation SQL provided for AC-07/AC-08 confirmation
