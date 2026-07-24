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

Builder must not start when the task/architecture is unapproved, ACs are not observable, allowed writes cross lane boundaries, dependencies/contracts are unapproved, or source drift invalidates assumptions.

`approval_basis` is `user:<decision>` for a separate Task gate or `architecture:<id>#<version>` when Architect confirms the Task is routine realization of already approved boundaries. A separate user approval is required only for new user-owned intent, a new Architecture Gate, irreversible/external effects, material cost/scope growth, or a mandatory human gate.

Use `Failure Matrix` only for risk-bearing state, lifecycle, callback, concurrency, network, persistence, or migration behavior. List the applicable normal, invalid, duplicate/idempotent, reentrant, shutdown, ordering, and rollback cases with their oracle; do not add empty ceremony to mechanical work.

Every mandatory human gate must use:

```markdown
| Gate | Why automation is insufficient | Who/when | Exact procedure | PASS evidence | FAIL route | Fallback/consequence |
|---|---|---|---|---|---|---|
```

Do not approve a mandatory gate described only as `manual test`, `Editor/PIE required`, or `user evidence needed`.
