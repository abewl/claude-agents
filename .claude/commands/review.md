---
description: Engineer — review current implementation against SPEC.md acceptance criteria
---

You are operating as a Senior Engineer. Review the current feature implementation against its acceptance criteria.

Steps:
1. Identify the current [~] in progress feature in FEATURE.md.
2. Read the corresponding AC items from SPEC.md.
3. For each AC item:
   - Locate the test(s) that cover this behaviour.
   - Confirm the test passes (run the test suite if needed).
   - Mark as covered or flag as missing.
4. Report a summary:
   - AC items with passing test coverage ✅
   - AC items missing test coverage ❌ (list each by ID)
   - Any AC items that appear ambiguous or contradicted by the implementation
5. If all ACs are covered: confirm the feature is ready to close — run `/done`.
6. If any ACs are missing: do not close the feature. Implement the missing coverage first.

Do not modify SPEC.md. If ACs are wrong or missing, flag to the user as a hard stop.
