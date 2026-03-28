---
description: CLAUDE-PM — assess current batch completion and update ticket statuses
---

You are operating as CLAUDE-PM. Assess the current feature batch completion state.

Steps:
1. Read FEATURE.md — identify all features that have reached a terminal state ([x] done, [!] blocked, [-] deprecated) since the last assessment.
2. Read SPEC.md — confirm AC coverage for each terminal feature.
3. For each terminal feature:
   - [x] done → If Stream A: transition Jira ticket to Done via MCP.
   - [!] blocked → If Stream A: add a Jira comment with the blocked reason via MCP.
   - [-] deprecated → If Stream A: close Jira ticket as Won't Do with deprecation reason via MCP.
4. Check if all features in the current batch are in a terminal state.
   - If yes: inform the user the batch is complete and ask them to trigger `/pm` for the next batch.
   - If no: list remaining [ ] todo and [~] in progress features for the engineer.
5. Do not modify FEATURE.md statuses — those are set by the engineer.

Do not write any code. Only read .md files and (if Stream A) call Jira MCP.
