---
name: scope
description: Reference-first research on a named scope (a feature, system, component, format or design question). Gathers facts from authoritative references and the repo, never infers, triages every source as read or unconfirmed, and distils the result into a Scope Brief that /solve consumes. Use when the user invokes /scope with a scope and instructions. Does not design or build.
---

# Scope

The user invokes `/scope <scope> [instructions]` to say: this scope has a body of existing knowledge (specs, official docs, prior art, the repo's own docs). Gather it **from sources, not from memory or inference**, and shape it into a **Scope Brief**: the single input `/solve` takes to produce a decided solution.

`/scope` gathers and distils. It never designs the solution and never builds. Deciding is `/solve`'s job.

If the scope is unclear or too wide to research in one pass, ask one short question, or propose a split and start with the first slice.

## Reference

The reference is whatever the user names in the arguments or the project docs name as authoritative (a product, a standard, an API, a spec, a prior system). If none is named, pick the best public sources for the scope and say which you chose and why. Sources the user names as "other" or "non-reference" are candidates for adaptation, not the reference; label them that way.

## Procedure

1. **Fix the scope.** Restate it in one or two lines: what is in, what is out, which reference. Anything outside is not touched.
2. **Check what is recorded.** Find the project's own docs (agent or contributor docs such as `AGENTS.md`, `CLAUDE.md`, `README`, `docs/`, design docs, decision logs, changelogs, any "verified reference" or notes file) and read what bears on the scope. Grep the code and data for the scope. Note existing state: what exists, where, and what depends on it. Do not re-research what is already recorded with a source. Collect the user's **binding decisions** on this scope from the docs, any memory notes and this conversation, plus the project's stated conventions, constraints and frozen or human-owned areas.
3. **Walk the reference map.** For everything missing, web search and fetch the actual sources. Start from the reference's own structure (index pages, specs, manuals, lists, API docs) and cover the whole scope systematically, not the first hit. Use this angle checklist and mark any angle not covered: rules and numbers, data model, visuals (look at images and screenshots; do not describe from memory), UI and interaction, edge cases, performance and resource limits, consistency between actors or modes (for example user versus automated), compatibility with existing code. Official sources first, then community docs, then forums; say when a source is for a different product or version.
4. **Triage every source.** A claim is **READ** only if you fetched and read the page. A claim from a search snippet or an unreadable page (paywall, HTTP 402/403) is **UNCONFIRMED**. Try another source for an UNCONFIRMED claim before giving up.
5. **Never infer.** A fact you cannot source is **NOT FOUND**. Do not fill it from training data, analogy or likelihood.
6. **Record.** Append each finding, with its source URL, to the project's existing reference or notes document if it has one; otherwise to the brief itself. Keep sourced facts apart from design decisions.
7. **Write the Scope Brief** to `<docs>/scopes/<slug>.md` (format below) and report it. `<docs>` is the project's docs directory if it has one (for example `docs/` or `agent_docs/`), else `docs/`.

## Scope Brief format

The brief is the primitive handed to `/solve`: one statement, a fact ledger, and the open forks. No solution in it.

```markdown
# Scope Brief: <name>      date: YYYY-MM-DD      status: READY | NEEDS-MORE-RESEARCH

## Statement
One sentence: "<System> must <observable behaviour> for <who>, within <limits>." Plus in-scope / out-of-scope bullets.

## Binding (decisions and project rules that /solve may not override)
- B1 ... (source: doc / memory / conversation date)

## Existing state
- What already exists in code, data and assets, with file paths, and what depends on it.

## Fact ledger
| ID | Fact | Status | Source |
| F1 | ... | READ / UNCONFIRMED | URL (official / community / other product) |

## Not found
- N1 ... (what was searched, where)

## Forks (decisions /solve must make; each with the candidates seen in the sources)
- K1 <question>: candidates A (source), B (source). Constraint from existing state: ...

## Coverage
Angles covered / not covered (rules, data, visuals, interaction, edge cases, performance, consistency, compatibility).

## Verification probes
How a finished solution would be seen working (what to run, what to look at, what to measure).
```

`READY` means every fork has its candidates sourced and every NOT FOUND is listed. `NEEDS-MORE-RESEARCH` means a fork the solution depends on has no candidates yet; say which.

## Output

End with: scope, the brief's path, counts (READ facts, UNCONFIRMED, NOT FOUND, forks), sources used (links), and the top forks. Then say `/solve <slug>` is the next step. Do not ask the user to decide the forks here.
