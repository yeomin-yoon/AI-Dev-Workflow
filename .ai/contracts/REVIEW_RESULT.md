# Contract: Review Result

Path: `.ai/lanes/<lane>/reviews/REVIEW-<TASK>-<ATTEMPT>.md`, or `.ai/integration/reviews/REVIEW-<IR>-<ATTEMPT>.md` for an activated Integration Gate under an approved order/contract.

```markdown
---
task: <TASK-id|IR-id>
lane: <lane|integration>
attempt: 1
verdict: pending
base_revision: <commit|working-tree>
reviewed_revision: <commit|working-tree>
reviewed_tree: <git-tree-hash|unsealed>
reviewer: <session-id|unknown>
independence: <independent_session|reduced_assurance>
knowledge_sync: <required|defer|none>
---

# Review <Task>

## AC Matrix
| AC | Verdict | Evidence |
|---|---|---|

## Findings
### [P1][implementation] <title>
- location:
- failed requirement/risk:
- violated invariant/contract:
- concrete consequence:
- evidence:
- reproduce/verify:
- route: Builder

## Scope/Architecture

## Checks Reproduced
| Check | Result | Evidence/log path |
|---|---|---|

## Residual Risks
none

## Change Brief
- level: <none|brief|deep>
- reason: <why this level; required for none>
- purpose: <why the accepted change exists|omit for none>
- before -> after: <conceptual behavior change|omit for none>
- runtime/data flow: <key flow in conceptual order|omit for none>
- invariants/tradeoffs: <what must remain true and material consequence|omit for none>
- inspect/try: <path + symbol/check|omit for none>

## Route
<Knowledge Maintainer | Architect | Builder | responsible role/user gate | Integration Gate>
```

Use verdict `pass | fail | blocked | pending`.

PASS requires mandatory ACs passed, credible evidence, architecture/lane compliance, no unapproved scope, disclosed residual risk, and independent-session Review unless the user explicitly accepted reduced assurance. A PASS Review includes a risk-scaled Change Brief; use `none` for a purely mechanical change and do not duplicate the diff. Omit the Change Brief for `fail` or `blocked`; findings provide the needed failure context. The brief is revision-scoped orientation, not authority. Every FAIL finding needs type, severity, location, impact, evidence, reproduction, and route. Do not fail on preference alone or send architecture issues to Builder.

For a commit candidate, Reviewer inspects the exact `base_revision..reviewed_revision` range and records `reviewed_tree = reviewed_revision^{tree}`. A non-`main` Integration candidate may PASS only against committed revisions; a `working-tree` Review may guide repair but must be repeated against the final commit before sealing. The later metadata-only handoff commit is not the reviewed production revision and must contain only the current Lane workflow artifacts allowed by `MAIN_DESK.md`.

For a mandatory user-observed verification gate, complete all other review work, use verdict `blocked`, record the exact gate/procedure and available evidence, and show the User Action Card in chat. After evidence arrives, create/resume the appropriate Review attempt and issue the final verdict.

For `fail` or `blocked`, set `knowledge_sync: none`. For PASS, set it using the Reviewer role policy. `required` appends this Review and routes Knowledge Maintainer; an unmerged non-`main` candidate uses `PREPARE_DELTA` when the Lane needs that knowledge before Integration. Single-lane `defer` appends it and routes Architect/next Task; unmerged multi-lane `defer` routes Integration Gate. `none` routes Architect/next Task but never clears older pending Reviews. The Route section must match the verdict, finding owner, sync policy, and lane topology; it is never a fixed Knowledge handoff.
