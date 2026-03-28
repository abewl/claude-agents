---
description: Ad-hoc agent-framework loop — MD-only, no external integrations
---

You are operating in **ad-hoc mode**. The same agent framework (FEATURE.md, SPEC.md, DICT.md, AGENT.md) applies but without Jira or Confluence. You control the pace — each phase is triggered explicitly with its own command. No `Ticket:` field is required; leave it blank.

---

## Available commands

| When you want to… | Run |
|---|---|
| Author or refresh the feature backlog | `/pm` |
| Pick up and implement the next feature | `/feature` |
| Check implementation against SPEC.md ACs | `/review` |
| Close a feature, write changelog, open PR | `/done` |

---

## Phase protocols

### CLAUDE-PM phase (`/pm`)
1. Read PROJECT.md — the only authoritative input.
2. Read current FEATURE.md and SPEC.md (if they exist).
3. Draft the next batch of F-XX entries in FEATURE.md following the format in AGENT.md.
4. Write corresponding AC items to SPEC.md for every new feature (no feature without AC).
5. Update DICT.md with any new patterns or types the batch introduces.
6. Leave `Ticket:` field blank on every entry.
7. Present the batch to the human. **Do not begin engineering until confirmed.**

### Engineer phase (`/feature` → `/review` → `/done`)
1. `/feature` — Read PROJECT.md, AGENT.md, FEATURE.md, DICT.md, SPEC.md. Pick next `[ ] todo` feature. Set to `[~] in progress`. Implement on a feature branch. Write tests.
2. `/review` — Check each AC item has a passing test. Report gaps. Do not close the feature if any AC is uncovered.
3. `/done` — Pass check confirmed. Set `[x] done` in FEATURE.md with completion note. Write changelog. Open PR. Await human merge.

---

## When to re-invoke CLAUDE-PM
- All current backlog features have reached a terminal state (`[x] done`, `[!] blocked`, `[-] deprecated`).
- PROJECT.md has been updated with new requirements.
- The backlog needs re-prioritisation.

Run `/pm` again to author the next batch.

---

## Hard stops
- Missing or wrong AC items → flag to human; do not implement.
- Ambiguous state after context reset → flag to human before resuming.
