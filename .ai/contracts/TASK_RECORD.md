# Contract: Task Record

Path: `.ai/lanes/<lane>/tasks/TASK-<LANE>-<NNN>.md`

```markdown
---
id: TASK-<LANE>-<NNN>
lane: <lane>
status: draft
source_revision: <commit|working-tree>
architecture_ref: <path>#<version|section>
depends_on: []
approved_by: null
approval_basis: null
---

# <Observable outcome>

## Goal
<one sentence>

## Scope
- in:
- out:
- allowed_write:

## Context Manifest
| Ref | Path | Symbol/section | Why |
|---|---|---|---|

## Constraints / Assumptions
Only constraints that affect implementation. Mark assumptions `verified | accepted | unverified` with evidence.

## Acceptance Criteria
- [ ] AC-1: <observable condition>

## Verification
| AC | Method/command | Required evidence |
|---|---|---|

## Failure Matrix
none

## Risks / Human Gates
none

## Expected Output
```

Use `draft | proposed | approved | rejected | superseded`. Task status records approval state only; execution progress belongs exclusively in lane state, Build Results, and Review Results.

The manifest starts with only required refs. Default soft budget comes from `BOOTSTRAP.md`; add optional refs or a budget override only when evidence justifies it.

## Task Quality Gate

This is the single canonical Task-splitting gate. Before a Task becomes `approved` or lane state reaches `ready_to_build`, Architect evaluates the completed Task Record against all seven checks. A file, class, or function boundary alone is not a Task boundary; required supporting edits may span several files when they produce one independently verifiable outcome.

| Check | Evidence required for `READY` |
|---|---|
| One outcome | Goal names one observable behavior or deliverable and one primary reason to change. |
| Independent delivery | Builder can implement it and Reviewer can PASS/FAIL it without a future Task or unapproved redesign. |
| Narrow, complete writes | `allowed_write` contains every required atomic edit, stays within the Lane boundary, and excludes unrelated cleanup. |
| Observable acceptance | Every mandatory result has an objective AC; labels such as `improve`, `refactor`, or `implement system` are insufficient by themselves. |
| Executable verification | Every mandatory AC maps to a feasible method and required evidence; any human gate has the complete procedure below. |
| Ready dependencies | Required source, contracts, decisions, and predecessor results exist and are approved or verified. |
| Worth the handoff | Split only when reduced context, risk, or review ambiguity repays another handoff; merge a fragment that has no standalone oracle or must land atomically with adjacent work. |

The gate returns exactly one internal planning outcome:

| Outcome | Meaning and action |
|---|---|
| `READY` | All checks pass. Architect may approve and hand the Task to Builder. |
| `SPLIT` | It contains multiple independently verifiable outcomes or separable risk/context. Architect reframes the delivery order and materializes/evaluates only the next smaller slice. |
| `MERGE` | It lacks a standalone outcome/oracle or must land atomically with adjacent work. Architect combines it and evaluates again. |
| `BLOCKED` | A required decision, dependency, boundary, or verification method is unresolved. Route the owning issue and do not hand off. |

`SPLIT` and `MERGE` are private Architect revisions, not new user gates. Ask the user only when the underlying change requires user-owned intent or an Architecture Gate. Do not add a separate Task-quality artifact, session, numeric score, or bare `task_quality=pass`; the Task Record fields are the evidence.

Builder must not start unless the Task satisfies this Gate. Unapproved Task/Architecture, non-observable ACs, incomplete or cross-Lane writes, a missing verification method or unresolved human-gate procedure, unapproved dependencies/contracts, and source drift are hard blockers.

`approval_basis` is `user:<decision>` for a separate Task gate or `architecture:<id>#<version>` when Architect confirms the Task is routine realization of already approved boundaries. A separate user approval is required only for new user-owned intent, a new Architecture Gate, irreversible/external effects, material cost/scope growth, or a mandatory human gate.

Use `Failure Matrix` only for risk-bearing state, lifecycle, callback, concurrency, network, persistence, or migration behavior. List the applicable normal, invalid, duplicate/idempotent, reentrant, shutdown, ordering, and rollback cases with their oracle; do not add empty ceremony to mechanical work.

Every mandatory human gate must use:

```markdown
| Gate | Why automation is insufficient | Who/when | Exact procedure | PASS evidence | FAIL route | Fallback/consequence |
|---|---|---|---|---|---|---|
```

Do not approve a mandatory gate described only as `manual test`, `Editor/PIE required`, or `user evidence needed`.
