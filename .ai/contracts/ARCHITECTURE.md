# Contract: Architecture

Path: `.ai/lanes/<lane>/architecture.md` or a feature file referenced by state/task.

```markdown
---
id: ARCH-<LANE>-<NAME>
lane: <lane>
status: draft
version: 1
source_revision: <commit|working-tree>
requirement_refs: []
approved_by: null
supersedes: null
---

# <Name>

## Goal

## Requirement Baseline
Optional. Explain only why the front-matter refs apply and what durable approval basis they use; do not copy requirement prose here.

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
For multi-Task work only:

| Slice | Approved observable outcome | Intent/requirement ref | Depends on |
|---|---|---|---|

Keep this as a compact current-scope outcome map, not a pre-generated Task queue or implementation checklist. Use stable semantic slice labels within the Architecture version. Record an intentionally excluded outcome under `Scope: out`; record a consequential deferral with its basis and consequence under `Decisions` or `Open Risks`. Never make an approved in-scope behavior disappear merely because no Task has been materialized for it yet.

## Open Risks
```

Rules:

- Use `draft | proposed | approved | rejected | superseded`.
- Front-matter `requirement_refs` is the canonical machine-readable list and is backward-compatible and optional. When present, reference only the applicable approved requirement IDs/sections as `<path>#<id-or-section>@<revision>`; a newer unreviewed document revision is drift, not automatic approval. Leave `requirement_refs: []` when no durable requirement document exists; a short explicit user request remains valid input.
- The `Requirement Baseline` body may explain applicability or approval basis but must not duplicate or redefine the front-matter list. A mismatch is a `contract` blocker until both agree; Builder and Reviewer never choose between them.
- Builder uses only `approved` architecture.
- Increment version when structure changes; supersede affected tasks.
- When approved product intent changes, increment the Architecture version as needed and supersede every affected approved Task before further Build. Implementation discovery may propose a requirement change but never rewrites the requirement baseline silently.
- Record drift instead of copying current source into the design.
- Keep implementation detail in source and rejected alternatives only when they affected the decision.
- Record only consequential decisions; include viable alternatives in the rationale when they materially differ.
- Materialize only the next Task; keep future delivery order compact here.
- At a natural Feature boundary, the current approved `Scope` and `Delivery Slices` are the intent-coverage baseline. Architect reconciles them against Tasks, accepted Reviews, live implementation, and decisive evidence before claiming Feature completion or resting with explicitly deferred work; Task PASS alone is not whole-Feature coverage.
- Shared contracts require Integration approval.
