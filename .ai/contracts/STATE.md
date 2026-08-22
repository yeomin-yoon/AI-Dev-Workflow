# Contract: Lane State

Paths: `.ai/lanes/<lane>/state.yaml` (current pointers, mutable) and `.ai/lanes/<lane>/ledger.jsonl` (closed-Task record, append-only). See `#run-ledger`.

```yaml
schema_version: 3
lane: <lane>
phase: uninitialized
status: idle
source_revision: null
artifacts:
  architecture: null
  task: null
  build_result: null
  review_result: null
  integration_requests: []
next:
  role: knowledge_maintainer
  action: initialize_lane
  inputs: []
blocked:
  type: null
  reason: null
  need: null
  owner: null
knowledge_sync:
  status: clean
  pending_reviews: []
updated_at: null
```

State is a pointer record, not a chat summary. Update evidence artifact and next role with every phase change. One writer edits a lane state at a time. Do not add progress prose, completed-task history, or model-specific phases; Review artifacts and Git carry history.

Schema `2` remains readable for preserved installations. Its legacy `active_feature`, `active_task`, and `open_risks` keys are non-authoritative and must not be updated: derive the Task from `artifacts.task`, and read risks from the referenced Architecture/Review artifact. New state and migrated state use schema `3` without those keys.

- `phase` is the preserved lifecycle position shown below; never set it to `blocked`.
- `status` is `idle | active | blocked | complete`.
- `complete` is reserved for a lane whose `lane.yaml.status` the user explicitly sets to `retired`; `synced + idle` means no active delivery and synchronized durable state. It supports a Feature-complete claim only after Architect's bounded Feature convergence finds every current-scope outcome implemented or approved-excluded. A Feature with a user-approved deferral may also rest there but remains visibly paused/incomplete in Architecture and chat.
- `next.role` is `knowledge_maintainer | architect | builder | reviewer` and always names the AI role responsible for consuming the next input and transition. Represent pending user input in `next.action` and, when blocked, `blocked.owner: user`; never store `user` or `integration` as a role.
- On a blocker, keep `phase`, set `status: blocked`, fill all `blocked` fields, and persist the responsible repair role/input. When a repair is performed by a different role, encode the interrupted role/action in `next.action` as `resolve_<type>_then_resume_<role>_<action>`; do not add a second hidden resume field.
- On resume, clear the `blocked` fields and set the appropriate non-blocked status.
- `knowledge_sync.status` is `clean | pending | required`. `clean` requires an empty list; `none` never clears older entries. Reviewer appends accepted deferred/required Review paths; Knowledge Maintainer clears only synchronized paths.
- When activating a new Task, point `artifacts.task` to it and clear the current Build/Review pointers. Build and Review attempts replace only their respective current pointers; history remains in artifacts and Git.
- Before leaving `accepted` for Knowledge sync or a next Task, revalidate the accepted Review identity. A committed candidate checks its tree; a Git-backed single-main working tree checks `reviewed_fingerprint`. On mismatch, do not continue from the stale PASS. When Git is usable, a single-main working-tree PASS must reach the `ACTION_CARDS.md` scoped logical checkpoint—including any required single-main revision-repin closure—before another Task is materialized. Review PASS plus exact-scope policy authorizes only that checkpoint, never unrelated paths or remote/history effects.

```text
uninitialized → discovery → synced/idle
new feature → design → ready_to_build → building
→ ready_to_review → reviewing → accepted
  ├─→ ready_to_build (next task; Knowledge pending/not needed)
  ├─→ synced (single-lane Knowledge checkpoint)
  └─→ Integration queue → main integration → accepted/synced
```

`.ai/integration/queue.yaml` and Integration Review artifacts own detailed Integration progress. The main Lane's `integration` phase is only a durable pointer that an exact queued range has been applied and awaits/undergoes independent main Review; it is invalid without that queue/range evidence. Normal phase/status pairs are:

| Phase | Normal status |
|---|---|
| `uninitialized` | `idle` |
| `discovery` | `active` |
| `synced` | `idle` or retired `complete` |
| `design` | `active` |
| `ready_to_build` | `active` |
| `building` | `active` |
| `ready_to_review` | `active` |
| `reviewing` | `active` |
| `accepted` | `active` |
| `integration` | `active` |

Any phase may temporarily use `status: blocked` while preserving that phase. Every active role writes the start transition before its substantive work so a replacement session can distinguish waiting from in-progress work.

Issue type and owner classification come only from `.ai/reference/OPERATIONS.md`. This table defines state effects and how the resolved responsible AI role is stored; it is not a second routing policy.

| From | Event | To | Next |
|---|---|---|---|
| `uninitialized/idle` | Knowledge Maintainer starts first `BUILD` | `discovery/active` | Knowledge Maintainer with `continue_initial_discovery` |
| `discovery/active` | initial discovery completes | `synced/idle`; clear Task/Build/Review pointers, retain Architecture | Architect with `await_feature_seed` |
| `synced/idle` or `accepted/active` | Architect accepts a Feature seed or starts approved redesign | `design/active` | Architect with `continue_design` |
| `design/active` | consequential user decision is pending | preserve `design/active` | Architect with `await_user_*` action |
| `design/active` | approved Task is materialized | `ready_to_build/active` | Builder with Task inputs |
| `ready_to_build/active` | Builder preflight rejects the Task or a required input | preserve `ready_to_build`, set `status: blocked`, and record the issue type, responsible repair role, and exact missing/invalid input | responsible role resolved by Operations; encode the Builder preflight resume target in `next.action` |
| `ready_to_build/blocked` with `architecture` | Architect starts the routed repair | `design/active`; supersede the affected Task when its approved outcome or boundary changed | Architect with `continue_architecture_repair` or the required approval action |
| `ready_to_build/blocked` with `contract`, `context`, `verification`, or a non-material `integration` repair | the responsible owner restores valid Task/input evidence without changing approved intent or boundary | `ready_to_build/active`; clear blocker fields | Builder repeats the complete preflight; never resume from a remembered partial preflight |
| `ready_to_build/blocked` with a material `contract`/`context`/`integration` repair | the repair changes approved intent, public boundary, or Task outcome | `design/active`; supersede the affected Task | Architect; a replacement approved Task and fresh preflight are required |
| `ready_to_build/active` | Builder preflight succeeds, before production writes | `building/active` | Builder with `continue_build` |
| `building/active` | approved implementation requires known user/editor authoring that will save only declared Task-attributed paths | preserve `building/active` | Builder with `await_user_build_authoring`; issue one batched candidate-mutating action card before final verification/fingerprint |
| `building/active` with `await_user_build_authoring` | user completes only the authorized saves and approved Task/boundary remain unchanged | preserve `building/active`; clear the wait | Builder reconciles the saved paths into the same Build attempt, runs only invalidated/final evidence, and continues `continue_build` |
| `building/active` with `await_user_build_authoring` | saved paths are unknown/unowned/outside authorization or change approved intent/boundary | set the owning blocker or route `design/active` | resolve attribution/contract first or Architect supersedes the Task; never absorb the bytes by assumption |
| `building/active` | an issue prevents a truthful Build completion | preserve `building`, set `status: blocked`, and record the issue type, owner, interrupted Build action, baseline, and attributable-path evidence | responsible role resolved by Operations |
| `building/blocked` with `architecture` or a material `contract`/`context`/`integration` repair | Architect starts the routed repair | `design/active`; supersede the affected Task and apply the interrupted-attempt disposition rule below | Architect with `continue_architecture_repair` or the required approval action |
| `building/blocked` with `contract`, `context`, `verification`, or a non-material `integration` repair | the responsible owner restores valid evidence without changing the approved Task/boundary or any Task-attributed bytes | `building/active`; clear blocker fields | Builder reconciles state, baseline, current diff, and attributed paths before resuming the exact attempt |
| `building/blocked` after a non-material repair | the approved Task/boundary is unchanged but the repair changed any Task-attributed byte | `ready_to_build/active`; clear stale Build/Review pointers and create a new Build attempt | Builder reconstructs the three-way Baseline attribution and repeats full preflight; never resume the old partial attempt or verdict |
| `building/active` | truthful Build Result is complete | `ready_to_review/active` | Reviewer with exact candidate inputs |
| `ready_to_review/active` | Reviewer preflight rejects the candidate or required input before substantive Review | preserve `ready_to_review`, set `status: blocked`, and record issue type, owner, exact candidate identity, and missing/invalid evidence | responsible role resolved by Operations; encode the complete Reviewer-preflight retry in `next.action` |
| `ready_to_review/blocked` after evidence/metadata repair | candidate bytes, approved intent, Task outcome, and public boundary are unchanged | `ready_to_review/active`; clear blocker fields and stale Review pointer | Reviewer repeats the complete preflight; never resume a remembered partial preflight |
| `ready_to_review/blocked` after repair | candidate bytes changed but approved intent, Task outcome, and public boundary are unchanged | `ready_to_build/active`; clear stale Build/Review pointers and create a new Build attempt | Builder with reconstructed Baseline attribution and full preflight |
| `ready_to_review/blocked` after material repair | approved intent, Task outcome, or public boundary changed | `design/active`; supersede the affected Task | Architect with the required approval action and replacement Task |
| `ready_to_review/active` | Reviewer accepts preflight, before substantive Review | `reviewing/active` | Reviewer with `continue_review` |
| `reviewing/active` | `implementation` finding | `ready_to_build/active`; create a new attempt and clear current Review pointer | Builder |
| `reviewing/active` | another routed finding (`architecture`, `contract`, `context`, `verification`, or `integration`) | preserve `reviewing`, set `status: blocked` | responsible AI role resolved by Operations/Integration Gate; encode the Review resume target in `next.action`; use `blocked.owner: user` only for required user input |
| `reviewing/blocked` with `architecture` | Architect starts the routed repair | `design/active`; supersede affected Task when its approved boundary changed | Architect with `continue_architecture_repair` or the required approval action |
| `design/active` after architecture repair | repaired approved Task is materialized | `ready_to_build/active`; clear current Build/Review pointers | Builder |
| `reviewing/blocked` with `contract` | owning role repairs only the malformed artifact/contract and candidate plus approved intent are unchanged | `ready_to_review/active`; clear current Review pointer and create a new Review attempt | Reviewer |
| `reviewing/blocked` with `contract` | repair changes approved intent, candidate bytes, or public boundary | route through `design/active` or `ready_to_build/active` as applicable | Architect or Builder; never reuse the old verdict |
| `reviewing/blocked` with `context` | authoritative context is restored without changing candidate/intent | `ready_to_review/active`; clear current Review pointer and resume the interrupted Reviewer action | Reviewer |
| `reviewing/blocked` with `verification` and `blocked.owner: user` | requested `observe_only` evidence arrives and candidate bytes/identity are unchanged | `reviewing/active`; clear blocker fields | Reviewer with `continue_review`; consume the exact observation and revalidate identity before verdict |
| `reviewing/blocked` with `verification` and `blocked.owner: user` | an authorized `candidate_mutating` Editor/runtime action changes Task-attributed bytes without changing approved intent, Task outcome, or public boundary | `ready_to_build/active`; clear stale Build/Review pointers and create a new Build attempt | Builder reconciles the changed paths/Baseline, reruns required checks, and emits a new candidate identity; the old verdict cannot resume |
| `reviewing/blocked` with `verification` and `blocked.owner: user` | the action changes an unowned/unknown path, exceeds the authorized mutation set, or changes approved intent, Task outcome, or public boundary | preserve blocked or route `design/active` as owned by the cause | resolve `context`/`contract` attribution first, or Architect supersedes the Task; never absorb the bytes into the old candidate |
| `reviewing/blocked` with `integration` | repair preserves candidate bytes, approved intent, Task outcome, public boundary, and applicable Integration contract | `ready_to_review/active`; clear blocker fields and current Review pointer | Reviewer starts a new Review attempt against the unchanged candidate |
| `reviewing/blocked` with `integration` | repair changes candidate bytes but preserves approved intent, Task outcome, and public boundary | `ready_to_build/active`; clear stale Build/Review pointers | Builder creates a new Build attempt; the old verdict is invalid |
| `reviewing/blocked` with `integration` | repair changes approved intent, Task outcome, public boundary, or cross-lane ownership | `design/active`; supersede the affected Task/boundary | Architect with the required user approval when consequential |
| `reviewing/active` | Review PASS includes non-trivial hand-written production source, project preference is `code_inspection: before_next_task`, and candidate identity is revalidatable through an immutable Git tree or canonical working-tree fingerprint | `accepted/active`; retain the accepted Review/candidate identity | Reviewer with `await_code_inspection_then_resume_review_route`; emit no `DO_NEXT` yet |
| `reviewing/active` | any other Review PASS | `accepted/active` | route by Knowledge-sync policy and Lane topology |
| `accepted/active` with `await_code_inspection_then_resume_review_route` | user asks a walkthrough question or has not supplied the descriptive inspected/continue reply | preserve `accepted/active` and the exact Review/candidate identity | Reviewer reconstructs or expands the same `CODE_WALKTHROUGH`; no `DO_NEXT` |
| `accepted/active` with `await_code_inspection_then_resume_review_route` | descriptive inspected/continue reply arrives and candidate identity is unchanged | preserve `accepted/active`; clear the inspection wait | Reviewer applies the already-recorded Review route by Knowledge-sync policy and Lane topology |
| `accepted/active` with `await_code_inspection_then_resume_review_route` | inspection changes Task-attributed candidate bytes while approved intent, Task outcome, and public boundary remain unchanged | `ready_to_build/active`; clear the stale Review pointer and create a new Build attempt | Builder reconciles paths/Baseline and emits a fresh candidate; old PASS cannot resume |
| `accepted/active` with `await_code_inspection_then_resume_review_route` | inspection changes an unowned/unknown path | `accepted/blocked`; retain the exact accepted Review/candidate identity and set `blocked.type: context` with the changed path/evidence | the role that can establish path/source ownership with `resolve_code_inspection_attribution_then_resume_reviewer_inspection_wait`; set `blocked.owner: user` only when authoritative user input is actually required |
| `accepted/blocked` with `resolve_code_inspection_attribution_then_resume_reviewer_inspection_wait` | attribution remains unresolved | preserve `accepted/blocked`, the exact accepted Review/candidate identity, and the attribution evidence | the same responsible owner; no checkpoint, Knowledge, next-Task, or Integration route may consume the stale PASS |
| `accepted/blocked` with `resolve_code_inspection_attribution_then_resume_reviewer_inspection_wait` | the changed path is proven unrelated/pre-existing and the accepted candidate identity is unchanged | `accepted/active`; clear blocker fields and restore `await_code_inspection_then_resume_review_route` | Reviewer revalidates the exact candidate and reconstructs the same inspection wait before any recorded Review route resumes |
| `accepted/blocked` with `resolve_code_inspection_attribution_then_resume_reviewer_inspection_wait` | attribution proves Task-attributed candidate bytes changed while approved intent, Task outcome, and public boundary remain unchanged | `ready_to_build/active`; clear blocker fields and the stale Review pointer | Builder reconciles paths/Baseline and emits a fresh candidate; the old PASS cannot resume |
| `accepted/blocked` with `resolve_code_inspection_attribution_then_resume_reviewer_inspection_wait` | attribution finds approved intent, Task outcome, public boundary, or cross-lane ownership changed | `design/active`; clear blocker fields and supersede the affected Task/boundary | Architect with the required user approval when consequential; never absorb the change into the stale PASS |
| `accepted/active` | Git-backed single-main PASS is still an uncommitted working-tree candidate or required metadata repin is incomplete before another Task | preserve `accepted/active` | Work creates and verifies the exact policy-authorized local logical checkpoint; `COMMIT_READY` is emitted only for `checkpoint: ask`, an explicit pre-commit request, or actionable uncertainty |
| `accepted/active` | accepted candidate is commit-backed, no-Git with disclosed assurance, or its scoped single-main logical checkpoint is fully verified; next approved Task is materialized | `ready_to_build/active` | Builder |
| `accepted/active` | final Task PASS has `knowledge_sync: none`, no older pending Review, and no next Task or active work | preserve `accepted/active` | Architect with `reconcile_feature_boundary`; Task PASS alone is not a Feature-completion claim |
| `accepted/active` | Knowledge checkpoint completes and more Feature design remains | `design/active` | Architect |
| `accepted/active` | Knowledge checkpoint completes with no next Task or active work | preserve `accepted/active` | Architect with `reconcile_feature_boundary` |
| `accepted/active` with `reconcile_feature_boundary` | bounded convergence finds a specified `open` outcome or a material `conflict` | `design/active` | Architect materializes the next already-approved slice or follows the existing intent/architecture/authority repair route |
| `accepted/active` with `reconcile_feature_boundary` | every current-scope outcome is exactly one of `{implemented, excluded, deferred}`, none is `open` or `conflict`, every `deferred` outcome has an explicit user-owned approval basis plus its consequence/trigger in the current Architecture, Knowledge is clean, and no active work remains | `synced/idle` | Architect with `await_feature_seed`; report complete only when every outcome is `implemented` or `excluded`, otherwise report paused/incomplete |
| `synced/idle` or `accepted/active` | main applies one sealed Integration candidate and records the exact queue/range | `integration/active` | independent main Reviewer using Integration inputs |
| `integration/active` | main Reviewer begins or resumes the exact Integration Review | preserve `integration/active` | Reviewer with `continue_review` |
| `integration/active` | Integration Review PASS; Task code-inspection pause is not applicable | `accepted/active` | Knowledge Maintainer when required; otherwise Architect with `reconcile_feature_boundary` when no next Task or active work remains; otherwise Main Front Desk/next approved queue action |
| `integration/active` | Integration Review fails or needs evidence | preserve `integration`, set `status: blocked`; retain the exact queue item, original `main_before`, current `main_after`, and interrupted Review action | responsible owner from Operations/Integration Gate |
| `integration/blocked` with `verification` or `context` | missing evidence/context is restored and candidate bytes, approved intent, and recorded Integration range are unchanged | `integration/active`; clear blocker fields and create/resume a new Integration Review attempt | independent main Reviewer with `continue_review` |
| `integration/blocked` with non-material `contract` | owning role repairs only malformed Integration/Review metadata and candidate bytes, approved intent, and recorded range are unchanged | `integration/active`; clear blocker fields, clear stale Review pointer, and create a new Integration Review attempt | independent main Reviewer |
| `integration/blocked` with `implementation` | responsible Builder starts a bounded repair; mark the old Integration attempt failed and persist its queue `repair.status`, `original_main_before`, and repair Task pointer before leaving Integration | `ready_to_build/active`; clear stale Integration Review pointer | Builder; a new Build/Review attempt is required |
| `integration/blocked` with `architecture` or material `contract`/`integration` change | mark the old Integration attempt failed, initialize its queue `repair` mapping with the original range, and supersede the affected Task/boundary | `design/active` | Architect with the required user approval when consequential |
| `reviewing/active` | a Build/Review repair referenced by the active Integration queue `repair` mapping PASSes, and Main Front Desk records the repaired committed `main_after` plus a new full `original main_before..repaired main_after` range | `integration/active`; clear blocker fields and never reuse the old Integration verdict | independent main Reviewer with a new Integration Review attempt |
| any | user evidence/input is required | preserve phase, set `status: blocked` | current responsible AI role with `blocked.owner: user` |

While `next.action: await_code_inspection_then_resume_review_route` is present, only the four code-inspection rows above may leave `accepted/active`; all generic accepted, checkpoint, Knowledge, next-Task, and Integration routes are suspended until that wait is cleared or invalidated.

While `next.action: resolve_code_inspection_attribution_then_resume_reviewer_inspection_wait` is present, only its four attribution-recovery rows above may leave `accepted/blocked`; unresolved attribution remains blocked, and no generic recovery may reuse the accepted PASS.

Create new build/review attempts for implementation fixes. Architecture changes supersede affected tasks. Contract/context repair may resume the same immutable candidate only through a new Review attempt; any candidate or approved-intent change requires the corresponding Build or Architecture path. Integration repair follows the same rule at range level: evidence-only recovery may reuse unchanged bytes/range through a new Review attempt, while any changed byte, intent, or public boundary invalidates the old verdict and requires a repaired committed `main_after` plus a new full range from the retained original `main_before`. While state temporarily enters design/build/review, the active queue item's optional `repair` mapping is the sole durable Integration-resume pointer; normal `next.action` changes must not clear it. Missing `repair` is backward-compatible and means no repair is active.

For a superseded single-main working-tree Build, apply the canonical interrupted-attempt disposition in `.ai/contracts/TASK_RECORD.md#task-quality-gate` and the three-way Baseline attribution in `.ai/contracts/BUILD_RESULT.md`. State stores only pointers to those artifacts; it does not redefine their fields. Preserve unrelated user work, and never perform destructive rollback automatically.

A deferred Knowledge entry is not `none`: before Feature-boundary convergence can rest at `synced/idle`, synchronize it. A deferred product/delivery outcome is different: require its explicit user-owned approval basis, consequence, and trigger in current Architecture and never call the Feature complete. Without that authority it remains `open` or follows the existing blocker route rather than resting at `synced/idle`.

Only the listed phase/status/blocker enums and transitions are valid. Task status records approval, not execution progress; state plus Build/Review Results record execution. On recovery, inspect state, its evidence artifact, and Git. Resume an in-progress phase only when those agree; otherwise route a context/attribution issue instead of silently replaying work.

## Run ledger

Path: `.ai/lanes/<lane>/ledger.jsonl`. One JSON object per line, appended once when an accepted Task reaches its closure, never rewritten. It exists so Workflow maintenance can decide from observed runs which rules, gates, and roles actually earn their cost.

```json
{"schema_version":1,"task":"<task-id>","closed_at":"<ISO-8601>","closure":"<main_checkpoint|lane_handoff|accepted_no_git>","build_attempts":<n>,"review_attempts":<n>,"findings_total":<n>,"finding_types":["<review finding type>"],"code_inspection":"<shown_no_pause|awaiting_user|inspected|not_applicable>","checkpoint":"<auto|ask|none>"}
```

Every field is a projection of artifacts that already exist at closure: the Task record, its Build Results, its Review Results, the recorded code-inspection disposition, and the checkpoint outcome. Derive each value by counting or reading those artifacts.

- Append exactly one line when an accepted Task closes, and record which path closed it. Every delivery mode has exactly one such point, so no mode is silently unmeasured:
  - `main_checkpoint`: the single-`main` logical checkpoint. Work appends the line before staging and includes that one path in the checkpoint, so the line is committed with the Task it describes.
  - `lane_handoff`: a non-`main` Lane candidate sealed. The role that creates the Lane handoff commit appends it — Reviewer for `knowledge_sync: defer|none`, Knowledge Maintainer after a required `PREPARE_DELTA`. The ledger already lies inside the `.ai/lanes/<lane>/**` that commit stages.
  - `accepted_no_git`: Git is unusable. Append at the accepted transition with `checkpoint: none`.
- A Task that is superseded, abandoned, or still open produces no line. Integration reviews a merged range rather than a Task and appends nothing; its activation is read from the `lane_handoff` lines that fed it.
- Append only after the verdict and its owning artifacts are final, so a line can never influence a verdict, route, or Review. That ordering, not the identity of the writing role, is what preserves independence.
- Every Git-backed closure commits the line with the change it describes, so the ledger is never left as permanent untracked drift and never falls into an unrelated Task's commit. No entry records the revision it landed in: Git already answers that, and a field that can only be filled after the commit would force the append out of the commit it belongs to.
- Never infer a field from chat memory, and never write a value an artifact does not support. Omit an unsupported optional field rather than guessing.
- Do not record provider, model, effort, token counts, elapsed time, file counts, or any other value that is not durably recorded at closure. Comparative provenance belongs to `.ai/evals/README.md`, which pins configuration explicitly; a model's self-identification is never evidence.
- Never record source, chat text, logs, secrets, user data, or free-form prose.

This file is write-only during ordinary work. Bootstrap, roles, recovery, status projections, and handoffs never read it, never report it, and never gate on it. A missing, empty, or partial ledger is always valid and never a blocker, a Review finding, or a reason to pause: it is evidence for Workflow maintenance, not project state. Reading it is a maintenance action performed in the canonical distribution checkout under `maintenance/WORKFLOW_REVIEW.md`.
