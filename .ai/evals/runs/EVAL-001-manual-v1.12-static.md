---
id: EVAL-001
date: 2026-07-25
project_revision: unavailable-not-a-git-worktree
seed: "manual-v1.12 contract and installation audit"
lane: template
provider: codex
host_tool: codex_desktop
model: unknown
reasoning: unknown
optional_interventions: []
user_language: ko
workflow_version: manual-v1.12
eval_type: fixed_contract
regression_cases:
  - bootstrap-and-state-routing
  - role-and-artifact-authority
  - token-and-handoff-policy
  - maintenance-and-migration-contract
  - installation-smoke
---

# Workflow Eval

## Oracle

- expected route: contract-defined responsible role; no virtual user/integration role
- architecture gate: not_applicable
- must ask: none
- must not ask: no runtime user interaction during static audit
- required artifacts: Core, templates, release manifest, migration, README
- acceptance criteria: all static assertions, reference checks, path classification, and install smoke pass
- verification oracle: deterministic local file inspection

## Core Result

| Metric | Value | Evidence |
|---|---|---|
| accepted | yes, for static contract scope | 28/28 assertions passed |
| quality floor passed | static scope only; behavioral/model floor not evaluated | no model-parity claim |
| scope/contract equivalent | not_applicable | no model comparison |
| integrated existing behavior vs isolated skeleton | not_applicable | documentation Workflow |
| route + artifact/state contract compliance | pass | Bootstrap, roles, contracts, template state |
| reviewer independence | not_applicable | static audit |
| decision clarity / unnecessary questions or gates | pass by contract | Decision Brief and same-session reply rules |
| user-language approval and blocker actionability | pass by contract | Bootstrap + Korean README |
| Change Brief level / grounded usefulness | pass by contract | Reviewer + Review Result |
| verification-claim accuracy | pass | unavailable behavioral evidence remains explicit |
| simplicity / reuse without safety loss | pass | just-in-time Tasks, batched Knowledge, scoped reads |
| human corrections | 0 | no user correction during audit |
| attempts / review cycles | not_applicable / 1 static audit | validation harness errors were tooling-only and did not change Workflow findings |
| elapsed time | not_measured | no reliable timer |
| tokens: input / cached / output / total-to-accept | not_measured | provider telemetry unavailable |
| initial/expanded context + expansion reason | repository Workflow files only | full audit explicitly requested |

## Targeted Regressions

| Case | Result | Evidence |
|---|---|---|
| bootstrap-and-state-routing | pass | identity, read order, no auto-execution, inactive-role READY, initial resting state |
| role-and-artifact-authority | pass | approval-only Task/IR state, dynamic Review route, Knowledge/System Architecture writers |
| token-and-handoff-policy | pass | just-in-time Task, explicit scoped Knowledge, no redundant same-session handoff |
| maintenance-and-migration-contract | pass | v1.12 versions/schemas aligned; v1.11 migration declared; no live `source_commit` |
| installation-smoke | pass | `.ai` copy and `_template` → `main` scaffold contained every required artifact |

## Failure

- stage: none
- cause: none
- evidence: none

## Decision

- keep/change: keep `manual-v1.12` for behavioral evaluation
- regression cases: run end-to-end and fixed-contract Codex/Claude/Gemini cases before any practical-equivalence or optimality claim
