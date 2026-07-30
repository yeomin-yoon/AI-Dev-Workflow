---
status: uninitialized
version: 0
source_revision: null
requirement_refs: []
approved_by: null
---

# System Architecture

Store only cross-lane ownership, dependency direction, and shared contracts. Lane internals belong in lane architecture.
Use status `uninitialized | draft | proposed | approved | superseded`.

Front-matter `requirement_refs` is the canonical optional list for approved requirements that govern cross-lane ownership, dependency direction, or shared contracts. Use `<path>#<id-or-section>@<revision>`. A historical System Architecture without this field remains readable as `requirement_refs: []`; absence alone never blocks installation, update, or unrelated single-Lane work. Architect populates it at the next applicable cross-lane decision. A changed approved ref requires a new System Architecture version and supersession of every affected Lane Task before Integration; Lane artifacts must not duplicate ownership of the same cross-lane requirement.

## Goals

## Requirement Baseline

Optional. Explain only why the front-matter refs govern cross-lane ownership or a shared contract; do not copy requirement prose here.

## Lane Boundaries

| Lane | Owns | Must not own | Public surface |
|---|---|---|---|

## Dependencies and Data Flow

## Shared Contracts

| Contract | Owner | Consumers | Version | Source |
|---|---|---|---|---|

## Lifecycle/Compatibility

## Global Constraints

## ADR Refs

## Open Integration Risks
