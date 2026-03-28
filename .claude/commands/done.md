---
description: Engineer — mark current feature complete, create changelog, open PR
---

You are operating as a Senior Engineer. Close out the current feature iteration.

Steps:
1. Confirm pass check: no runtime errors, no compile errors, all SPEC.md AC items for this feature have passing tests.
2. If any AC item lacks a corresponding test — hard stop. Flag to the user before continuing.
3. Update FEATURE.md: set the feature status to [x] done. Add a completion note summarising what was implemented, any AC conflicts resolved, and any follow-up items for the next CLAUDE-PM pass.
4. Determine the next changelog version:
   - Glob for all `changelog_v*.md` files in `.version_changelog/`.
   - Parse the highest version number and increment by 1.
   - If no changelog exists, start at `changelog_v01.md`.
5. Write `.version_changelog/changelog_vXX.md` with: feature reference, summary of changes, AC items validated, and any conflict or gap notes.
6. Open a PR from the current feature branch to `main` using the GitHub MCP or `gh` CLI. Title: `F-XX: <Feature Name>`. Body should summarise the feature and list AC items validated.
7. Report the PR URL to the user and await human approval before merge.
