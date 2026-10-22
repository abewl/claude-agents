---
name: solve
description: Turns a Scope Brief (from /scope) into a decided, reviewable solution proposal, then builds it once approved. Decides gaps by a precedence ladder instead of asking, flags placeholders and low-confidence calls, and stops only at hard stops. Use when the user invokes /solve with a scope slug or brief path, or asks for a proposed solution to a scoped topic.
---

# Solve

The user invokes `/solve <slug-or-path> [instructions]`. Input: a Scope Brief at `<docs>/scopes/<slug>.md`. Output: a **Solution Proposal** at `<docs>/proposals/<slug>.md` for the human to review, then (after approval) the implementation. `<docs>` is the directory the brief is in.

The human wants a solution to review, not questions. Decide every gap yourself using the ladder, label how you decided, and let the human override by ID. Ask only at a hard stop.

If there is no brief, or its status is `NEEDS-MORE-RESEARCH`, say so and run `/scope` first (or do the missing research under the `/scope` rules). Never solve on facts the brief marks NOT FOUND without labelling the dependent decision a placeholder.

## Precedence ladder (how every fork is decided)

| Rung | Basis | Label |
|---|---|---|
| 1 | The human's recorded decisions and project rules (the brief's "Binding", project docs, memory notes) | BINDING |
| 2 | A fact from the named reference that the brief marks READ | SOURCED |
| 3 | Agreement of two or more independent sources from other products or prior art | ADAPTED |
| 4 | Limits of the existing code, data, tooling and hardware (what the current architecture allows) | FORCED |
| 5 | The simplest reversible option, with tunable numbers kept in the project's data or config files | PROPOSED (placeholder) |

Take the highest rung that answers the fork. UNCONFIRMED facts only count as rung 3 evidence, never rung 2. Never invent behaviour, interfaces or interactions that neither the reference nor the project docs call for: if rung 5 would have to, that is a hard stop.

## Hard stops (the only times to ask)

1. A decision would contradict a BINDING item.
2. Rung 5 would have to invent behaviour, an interface or an interaction the reference and project docs lack.
3. The action is irreversible or outward-facing: git operations (commit, push, rewrite), deleting data, editing documents the project marks human-owned, changing areas the project marks frozen, spending money, contacting third parties.
4. Two options are equal and the choice is pure taste (for example the look of a visual): present both with a recommendation.

Ask as a choice between named options, recommendation first. Never an open question. Everything else is decided and flagged.

## Procedure

1. **Load.** Read the brief, its Binding list, Existing state and Forks. Re-check that the named files still exist and still say what the brief says.
2. **Decide.** For each fork K, write a decision D with: statement, options considered (at least two), the choice, the ladder rung, confidence (high, medium, low), and reversal cost (cheap, moderate, costly). Add decisions the brief missed but the design needs (data schema, ownership of the single source of truth, edge cases).
3. **Design.** Behaviour and numbers (placeholders marked), data schema (files and keys), visuals or interfaces (technique, inputs, performance and resource limits), and how every actor or mode that should share the behaviour does share one code path.
4. **Plan.** Files touched in order, where each rule lives (keep rules out of presentation code if the project separates them), a test per rule, the brief's verification probes, and the changelog or doc updates the project's conventions require.
5. **Red-team.** Attack the draft: conflicts with existing code and data, which placeholder most changes the outcome, what the brief did not cover, whether any decision silently contradicts a Binding item. Fix or flag what you find.
6. **Write the proposal** (format below). Change nothing else in the repo.
7. **Review gate.** Report the proposal. The human replies by ID ("D3 = 50%", "reject D5", "accept all"). Silence is not approval: do not build until told to.
8. **Build to the accepted proposal.** Follow the project's conventions (build and lint commands, resource limits, determinism and style rules, where numbers live). Do not commit or push unless asked.
9. **Verify.** Run it and look at the result against the brief's probes (tests, screenshots, measurements). Report deviations from the proposal and anything not seen working.

## Solution Proposal format

```markdown
# Proposal: <name>      date: YYYY-MM-DD      status: DRAFT | ACCEPTED (date) | BUILT
Brief: <docs>/scopes/<slug>.md

## Summary
5 lines: what changes for the user, what changes in code and data.

## Decisions
| ID | Decision | Fork | Rung | Confidence | Reversal | Alternatives |

## Design
Behaviour and numbers, data schema, visuals or interfaces, interaction.

## Implementation plan
Ordered steps, files, tests per rule, verification probes.

## Placeholders to tune
| Value | File | Why this number |

## Risks and red-team findings

## Review first
The three decisions with the lowest confidence times highest impact, each with the one-line reason.
```

## Output

End with: "Decided N, M need your eyes, K are placeholders", the proposal path, and the "Review first" list. After building: what was built, how it was verified, what was not seen working, deviations.
