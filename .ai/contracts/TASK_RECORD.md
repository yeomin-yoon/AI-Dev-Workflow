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

When a mandatory AC derives from a referenced product/requirements/specification document, include only its exact requirement ID/section and pinned revision in the Context Manifest, or rely on the exact Architecture requirement ref when it is already sufficient. Do not copy the full document or repeat unrelated requirements.

When existing source and approved Architecture do not determine a consequential implementation shape, use `Constraints / Assumptions` or `Expected Output` to pin only the key types/signatures, call or control flow, file placement, and dependency boundaries needed for this Task. Do not prescribe full code, copy source, or create a separate Program Design artifact.

## Task Quality Gate

This is the single canonical Task-splitting gate. Before a Task becomes `approved` or lane state reaches `ready_to_build`, Architect evaluates the completed Task Record against all seven checks. A file, class, or function boundary alone is not a Task boundary; required supporting edits may span several files when they produce one independently verifiable outcome.

Prefer a narrow end-to-end/vertical slice that can be exercised at its approved boundary. A horizontal layer or scaffold is a separate Task only when it has a standalone approved outcome/oracle or must land atomically; otherwise merge it with the first observable behavior.

| Check | Evidence required for `READY` |
|---|---|
| One outcome | Goal names one observable behavior or deliverable and one primary reason to change. |
| Independent delivery | Builder can implement it and Reviewer can PASS/FAIL it without a future Task or unapproved redesign. |
| Narrow, complete writes | `allowed_write` contains every required atomic edit, stays within the Lane boundary, and excludes unrelated cleanup. A replacement Task after an interrupted/superseded single-main attempt classifies every inherited Task path as `retain | adapt | remove` in Scope or Constraints and keeps each retained/adapted/removed path inside `allowed_write`. |
| Observable acceptance | Every mandatory result has an objective AC; labels such as `improve`, `refactor`, or `implement system` are insufficient by themselves. |
| Executable verification | Every mandatory AC maps to a feasible method and required evidence; any human gate has the complete procedure below. |
| Ready dependencies | Required source, contracts, decisions, predecessor results, and applicable requirement refs exist at their approved or verified revisions. |
| Worth the handoff | Split only when reduced context, risk, or review ambiguity repays another handoff; merge a fragment that has no standalone oracle or must land atomically with adjacent work. |

The gate returns exactly one internal planning outcome:

| Outcome | Meaning and action |
|---|---|
| `READY` | All checks pass. Architect may approve and hand the Task to Builder. |
| `SPLIT` | It contains multiple independently verifiable outcomes or separable risk/context. Architect reframes the delivery order and materializes/evaluates only the next smaller slice. |
| `MERGE` | It lacks a standalone outcome/oracle or must land atomically with adjacent work. Architect combines it and evaluates again. |
| `BLOCKED` | A required decision, dependency, boundary, or verification method is unresolved. Route the owning issue and do not hand off. |

`SPLIT` and `MERGE` are private Architect revisions, not new user gates. Ask the user only when the underlying change requires user-owned intent or an Architecture Gate. Do not add a separate Task-quality artifact, session, numeric score, or bare `task_quality=pass`; the Task Record fields are the evidence.

Task creation also requires a current delivery reason: an explicit user-requested outcome, the approved Architecture delivery order, a dependency of the next observable outcome, or repair of an `OPERATIONS.md#bounded-diagnosis-during-active-delivery` `current_blocker`. A discovered `follow_up` is not independently READY merely because it is real or convenient to fix, and `not_actionable` evidence never becomes a Task.

When the complete procedure includes known user/editor saves to Task-attributed paths, label that step as candidate-mutating implementation to be batched during Builder's active attempt before final verification. Reserve post-handoff Reviewer gates for observation-only evidence or newly discovered setup that could not be known from the approved Task; do not knowingly design a Build -> Review -> save -> Build loop.

The interrupted-attempt disposition is required only when the replacement Task inherits Workflow-attributed dirty bytes. It never authorizes deleting unrelated pre-existing or `unknown` work; unresolved attribution remains a `context` blocker. Builder and Reviewer verify the disposition against the prior Build Baseline and current diff.

Builder must not start unless the Task satisfies this Gate. Unapproved Task/Architecture, non-observable ACs, incomplete or cross-Lane writes, a missing verification method or unresolved human-gate procedure, unapproved dependencies/contracts, changed or unresolved requirement refs, and source drift are hard blockers.

`approval_basis` is `user:<decision>` for a separate Task gate or `architecture:<id>#<version>` when Architect confirms the Task is routine realization of already approved boundaries. A separate user approval is required only for new user-owned intent, a new Architecture Gate, irreversible/external effects, material cost/scope growth, or a mandatory human gate.

Use `Failure Matrix` only for risk-bearing state, lifecycle, callback, concurrency, network, persistence, or migration behavior. List the applicable normal, invalid, duplicate/idempotent, reentrant, shutdown, ordering, and rollback cases with their oracle; do not add empty ceremony to mechanical work.

Every mandatory human gate must use:

```markdown
| Gate | Why automation is insufficient | Who/when | Exact procedure | PASS evidence | FAIL route | Fallback/consequence |
|---|---|---|---|---|---|---|
```

Do not approve a mandatory gate described only as `manual test`, `editor/runtime required`, or `user evidence needed`.
