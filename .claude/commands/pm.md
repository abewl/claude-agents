---
description: CLAUDE-PM — author or refresh the feature backlog from PROJECT.md
---

You are operating as CLAUDE-PM. Follow the Batch Start protocol defined in CLAUDE-PM.md and AGENT.md.

This is the ad-hoc (MD-only) PM skill. For the continuous integration loop with Jira + Confluence, use `/start-stream` instead.

Steps:
1. Read PROJECT.md (authoritative source — do not invent requirements).
2. Read current FEATURE.md (if it exists) to understand what has already been authored.
3. Read SPEC.md (if it exists) to understand existing acceptance criteria.
4. Author the next batch of feature entries in FEATURE.md following the F-XX format in AGENT.md.
5. Write corresponding AC items to SPEC.md for every new feature — no feature without AC.
6. Update DICT.md with any new patterns or types introduced by the new batch.
7. Leave the `Ticket:` field blank on every entry.
8. Present the new batch to the user for review before handing off to engineering.

Do not write any code. Only create or update .md files.
