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
For a material reference, record its role (`approved_behavior_oracle | project_precedent | normative_standard | reference_implementation | analogous_case_or_principle`), exact scope and date/revision, supported claim, project fit/difference, adopted principle, deliberately un-copied parts, and re-check trigger. Omit when no reference materially shapes the design.

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

Keep this as a compact current-scope outcome map, not a pre-generated Task queue or implementation checklist. Use stable semantic slice labels within the Architecture version. Record an intentionally excluded outcome under `Scope: out`; record a consequential user-approved deferral with its approval basis and consequence under `Decisions` or `Open Risks`. Never make an approved in-scope behavior disappear merely because no Task has been materialized for it yet.

When this Architecture establishes or changes a foundation, the first slice is the executable backbone: the thinnest real path from an actual entry through its responsibility/decision or state boundary to an observable effect and decisive oracle. An empty interface set, horizontal layer, stub-only scaffold, or folder/class skeleton is not a backbone without standalone behavior and proof. If a valid backbone already exists, the first slice extends it vertically instead of rebuilding it.

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
- Select the lowest sufficient altitude (`project | system | feature | component/interaction | Task/program shape`). Escalate only for a crossed owner, state/data authority, public dependency direction, lifecycle/failure responsibility, compatibility boundary, or another expensive-to-reverse decision. A local change never requires a whole-project re-baseline merely because it is non-trivial.
- At that altitude, the existing sections collectively form the bounded baseline: purpose/non-goals, responsibility/non-responsibility and state/data owner, inputs/outputs and critical flow, invariants with applicable failure/recovery/finish behavior, decisive verification, and deliberately deferred reversible/tunable detail. Do not add empty ceremony when a field is not applicable.
- Stop Architecture expansion when the baseline is contradiction-free, the highest-cost uncertainty is resolved or assigned one bounded experiment, and the first executable backbone/vertical Task can proceed without inventing another owner, contract, or user-visible outcome. More detail being possible is not a reason to continue design.
- Record only consequential decisions; include viable alternatives in the rationale when they materially differ.
- Materialize only the next Task; keep future delivery order compact here.
- At a natural Feature boundary, the current approved `Scope` and `Delivery Slices` are the intent-coverage baseline. Architect reconciles them against Tasks, accepted Reviews, live implementation, and decisive evidence before claiming Feature completion or resting with user-approved deferred work; Task PASS alone is not whole-Feature coverage.
- A historical approved Architecture without `Delivery Slices` remains readable. At Feature convergence, reconstruct a candidate outcome map from its approved `Scope`, explicit intent/requirement refs, Tasks, and accepted Reviews. Backfill the living Architecture without a new Gate only when that map is lossless and introduces no intent, scope, or structural decision; otherwise keep the outcome `open` or route `context | contract` and never claim completion from the missing section.
- Shared contracts require Integration approval.
