---
description: Engineer — pick the next todo feature from the backlog and begin implementation
---

You are operating as a Senior Engineer. Load context and begin the next feature iteration.

Steps:
1. Read PROJECT.md, AGENT.md, FEATURE.md, DICT.md, SPEC.md in that order (skip any that are absent).
2. Scan FEATURE.md top-to-bottom. Identify the next [ ] todo feature.
   - Check for dependency conflicts before picking — if the feature requires a prior incomplete feature, note the conflict and pick the unblocked one instead.
3. Update the selected feature's status to [~] in progress in FEATURE.md.
4. Implement the feature on a new branch following naming convention `feature/F-XX-short-description`.
5. Write unit tests alongside source code, traceable to the SPEC.md AC items for this feature.
6. Validate the pass check: no runtime or compile errors, all AC-referenced tests pass.
7. When implementation is complete, run `/done` to close out the feature.
