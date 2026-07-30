# Contract: Review Result

Path: `.ai/lanes/<lane>/reviews/REVIEW-<TASK>-<ATTEMPT>.md`, or `.ai/integration/reviews/REVIEW-<IR>-<ATTEMPT>.md` for an activated Integration Gate under an approved order/contract.

```markdown
---
task: <TASK-id|IR-id>
lane: <lane|integration>
attempt: 1
verdict: pending
base_revision: <full-commit|no-git>
reviewed_revision: <commit|working-tree|no-git>
reviewed_tree: <git-tree-hash|unsealed>
reviewed_fingerprint: <sha256:hash|null|unsealed>
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

## Assurance
- mode: <independent_session|reduced_assurance>
- user_decision: <explicit post-disclosure acceptance evidence|none>
- limitation: <what independence is missing and what may remain unseen|none>

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

PASS requires all mandatory ACs passed, no unresolved requirement-ref drift, credible verification evidence whose oracle was not materially weakened, approved architecture/lane/scope compliance, no unresolved material maintainability finding, disclosed residual risks, an unchanged candidate identity from Review start through verdict, and independent-session Review unless the user explicitly accepted reduced assurance. Passing checks cannot offset disabled or weakened tests, an invariant/type/contract bypass, or compensating code that preserves a directionally wrong design; route the underlying finding to its owner. A PASS Review includes a risk-scaled Change Brief; use `none` for a purely mechanical change and do not duplicate the diff. Omit the Change Brief for `fail` or `blocked`; findings provide the needed failure context. The brief is revision-scoped orientation, not authority. Every FAIL finding needs type, severity, location, impact, evidence, reproduction, and route. Do not fail on preference alone or send architecture issues to Builder.

## Reduced-assurance exception

This exception is available only for an ordinary Task Review when a separate Reviewer session is unavailable. A generic request such as "review this" or a convenience-driven same-session role switch is not consent. Before proceeding, disclose in `user_language` that the same session authored or repaired the candidate, explain the resulting self-confirmation/blind-spot risk, and recommend later independent Review; proceed only after the user explicitly accepts that limitation after the disclosure.

Record `independence: reduced_assurance`, the post-disclosure user decision, and the limitation in `## Assurance`, and keep the unresolved independence risk in `## Residual Risks`. Reduced-assurance Review is never canonical release evidence, Integration Gate evidence, a sealed non-`main` candidate verdict, or a basis for claiming independent Review. When any of those is required, return `blocked type=verification need=independent_review`.

For a commit candidate, Reviewer inspects the exact `base_revision..reviewed_revision` range, records `reviewed_tree = reviewed_revision^{tree}`, and sets `reviewed_fingerprint: null`; the immutable Git tree already identifies the reviewed candidate. A non-`main` Integration candidate may PASS only against committed revisions. The later metadata-only handoff commit is not the reviewed production revision and must contain only the current Lane workflow artifacts allowed by `MAIN_DESK.md`. Historical committed Reviews that duplicated `git-tree:<reviewed_tree>` remain readable.

For a Git-backed single-main working tree, Reviewer first reconciles the Build Result `Changes` table with the Task scope, baseline, status/diff, and untracked Task files. It then independently recalculates the Build Result's canonical fingerprint from that exact authoritative path set before inspection and immediately before PASS, and records it as `reviewed_fingerprint`. Any missing path or mismatch means the candidate is unsealed and cannot inherit the verdict; route a new Build/Review attempt. A no-Git `unsealed` Review may PASS only with its reduced attribution assurance disclosed and can never become Integration evidence.

For a mandatory user-observed verification gate, complete all other review work, use verdict `blocked`, record the exact gate/procedure and available evidence, and show the User Action Card in chat. After evidence arrives, create/resume the appropriate Review attempt and issue the final verdict.

For `fail` or `blocked`, set `knowledge_sync: none`. For PASS, set it using the Reviewer role policy. `required` appends this Review and routes Knowledge Maintainer; an unmerged non-`main` candidate uses `PREPARE_DELTA` when the Lane needs that knowledge before Integration. Single-lane `defer` appends it and routes Architect/next Task; unmerged multi-lane `defer` routes Integration Gate. `none` routes Architect/next Task but never clears older pending Reviews. The Route section must match the verdict, finding owner, sync policy, and lane topology; it is never a fixed Knowledge handoff.
