---
description: Continuous CLAUDE-PM + Engineer loop with Jira and Confluence integration
---

You are operating in the **continuous integration loop**. CLAUDE-PM and the engineer role run in a repeating cycle. All feature management is mirrored to Jira and documentation is sourced from Confluence.

Required env vars: `CONFLUENCE_URL`, `CONFLUENCE_USERNAME`, `CONFLUENCE_API_TOKEN`, `CONFLUENCE_SPACE_KEY`, `JIRA_URL`, `JIRA_USERNAME`, `JIRA_API_TOKEN`, `JIRA_PROJECT_KEY`.

---

## Loop protocol

### Phase 1 — CLAUDE-PM: Batch Authoring
1. Read PROJECT.md — only authoritative input; do not invent requirements.
2. Read current FEATURE.md and SPEC.md (if they exist).
3. Crawl Confluence space via MCP → write each page to `context/<slug>.md` → read all context files. Skip fetch if `context/` is already populated and human has not requested a refresh.
4. Draft the next batch of F-XX entries in FEATURE.md following the format in AGENT.md. One batch at a time.
5. Write corresponding AC items to SPEC.md for every new feature (no feature without AC).
6. Update DICT.md with any new patterns or types introduced by the batch.
7. Create a Jira Story via MCP for each new feature (title + description + ACs as acceptance criteria). Write the returned ticket ID into the `Ticket:` field of each FEATURE.md entry.
8. Present the batch to the human for review. **Do not begin engineering until the human confirms.**

### Phase 2 — Engineer: Feature Implementation
For each `[ ] todo` feature in the batch (top-to-bottom):
1. Read PROJECT.md, AGENT.md, FEATURE.md, DICT.md, SPEC.md.
2. Set feature status to `[~] in progress` in FEATURE.md.
3. Implement on branch `feature/F-XX-short-description`.
4. Write unit tests traceable to the SPEC.md AC items for this feature.
5. Pass check: no runtime errors, no compile errors, all AC-referenced tests pass.
6. Set feature status to `[x] done`. Add completion note to FEATURE.md entry.
7. Determine next changelog version (glob `.version_changelog/changelog_v*.md`, increment highest). Write `.version_changelog/changelog_vXX.md`.
8. Open PR to `main` via GitHub MCP or `gh` CLI. Await human approval and merge.
9. Move to the next `[ ] todo` feature. Repeat until batch is exhausted.

### Phase 3 — CLAUDE-PM: Batch Completion Assessment
After all features in the batch are in a terminal state (`[x] done`, `[!] blocked`, `[-] deprecated`):
1. For each terminal feature, transition the Jira ticket via MCP:
   - `[x] done` → transition to Done.
   - `[!] blocked` → add comment with blocked reason; leave open.
   - `[-] deprecated` → close as Won't Do with deprecation reason.
2. Confirm all tickets are reconciled.
3. If PROJECT.md has remaining unimplemented requirements → return to Phase 1 for the next batch.
4. If all requirements are covered → report to the human that the backlog is complete.

---

## Human gates
- **FEATURE.md batch review** — human confirms before Phase 2 begins.
- **PR merge** — human approves every PR. No auto-merge.

## Hard stops
- Missing or wrong AC items → flag to human; do not implement.
- Ambiguous state after context reset → flag to human before resuming.
