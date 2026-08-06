---
schema_version: 2
id: EVAL-<YYYYMMDDTHHMMSSfffZ>-<provider>-<short-slug>
date: null
status: draft
result: pending
completed_at: null
source_revision: null
source_tree: null
quality_floor: pending
seed: ""
lane: null
provider: null
host_tool: null
model: null
reasoning: null
optional_interventions: []
user_language: ko
workflow_version: null
eval_type: <source_regression|end_to_end|fixed_contract>
workflow_review_result: <pass|not_applicable>
workflow_review_mode: <changed|full|not_applicable>
workflow_review_independence: <independent_session|reduced_assurance|not_applicable>
workflow_review_self_check: <pass|corrected|blocked|not_applicable>
regression_cases: []
---

# Workflow Eval

Use `source_regression` for canonical release evidence. For that type, provider/model fields record execution provenance and unavailable token/time metrics are `not_measured`; they are not comparative claims. Use `end_to_end` or `fixed_contract` only for an explicitly planned comparison under `.ai/evals/README.md`.

## Oracle

- expected route:
- architecture gate:
- must ask:
- must not ask:
- required artifacts:
- acceptance criteria:
- verification oracle:

## Core Result

| Metric | Value | Evidence |
|---|---|---|
| accepted | | |
| quality floor passed | | |
| scope/contract equivalent | | |
| integrated existing behavior vs isolated skeleton | | |
| route + artifact/state contract compliance | | |
| reviewer independence | | |
| intent-gap + decision clarity / unnecessary questions or gates | | |
| user-language approval and blocker actionability | | |
| Change Brief / bounded expert-note grounding and fatigue | | |
| Direct Diff/source walkthrough / durable-pause usefulness | | |
| verification-claim accuracy | | |
| simplicity / reuse without safety loss | | |
| human corrections | | |
| attempts / review cycles | | |
| elapsed time | | |
| tokens: input / cached / output / total-to-accept | | |
| initial/expanded context + expansion reason | | |

## Targeted Regressions

List only the regression cases named in front matter; use `not_applicable` rather than inventing evidence.

| Case | Result | Evidence |
|---|---|---|

## Workflow Review

Required for canonical release evidence from `manual-v1.1` onward. For non-release/project Evals, record `not_applicable` and explain why.

| Lens | Result | Evidence |
|---|---|---|
| 1 | | |
| 2 | | |
| 3 | | |
| 4 | | |
| 5 | | |
| 6 | | |
| 7 | | |
| 8 | | |
| 9 | | |
| 10 | | |

- findings: P1:<n>, P2:<n>, P3:<n>
- deferred P2: <finding + consequence + follow-up evidence|none>
- self-check: <pass|corrected|blocked>
- corrections: <frozen-draft correction + reason|none>
- release recommendation: <ready|not_ready|not_assessed>

## Failure

- stage:
- cause:
- evidence:

## Decision

- keep/change:
- regression cases:
