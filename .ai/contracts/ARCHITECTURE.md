# Contract: Architecture

Path: `.ai/lanes/<lane>/architecture.md` or a feature file referenced by state/task.

```markdown
---
id: ARCH-<LANE>-<NAME>
lane: <lane>
status: draft
version: 1
source_revision: <commit|working-tree>
approved_by: null
supersedes: null
---

# <Name>

## Goal

## Evidence and Constraints

## Scope
- in:
- out:

## Responsibilities
| Component | Owns | Must not own |
|---|---|---|

## Interfaces and Data Flow

## Lifecycle and Boundaries
Ownership, errors, concurrency, network, persistence, and compatibility only when relevant.

## Decisions
| Decision | Project evidence | Consequence | Reconsider when |
|---|---|---|---|

## Cross-Lane Contracts

## Verification Strategy

## Delivery Slices
For multi-Task work only: ordered observable outcomes and dependencies, without implementation-detail Task duplication.

## Open Risks
```

Rules:

- Use `draft | proposed | approved | rejected | superseded`.
- Builder uses only `approved` architecture.
- Increment version when structure changes; supersede affected tasks.
- Record drift instead of copying current source into the design.
- Keep implementation detail in source and rejected alternatives only when they affected the decision.
- Record only consequential decisions; include viable alternatives in the rationale when they materially differ.
- Materialize only the next Task; keep future delivery order compact here.
- Shared contracts require Integration approval.
