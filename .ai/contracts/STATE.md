# Contract: Lane State

Path: `.ai/lanes/<lane>/state.yaml`

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
- `complete` is reserved for a lane whose `lane.yaml.status` the user explicitly sets to `retired`; normal Task/Feature completion uses `synced + idle`.
- `next.role` is `knowledge_maintainer | architect | builder | reviewer` and always names the AI role responsible for consuming the next input and transition. Represent pending user input in `next.action` and, when blocked, `blocked.owner: user`; never store `user` or `integration` as a role.
- On a blocker, keep `phase`, set `status: blocked`, fill all `blocked` fields, and persist the responsible repair role/input. When a repair is performed by a different role, encode the interrupted role/action in `next.action` as `resolve_<type>_then_resume_<role>_<action>`; do not add a second hidden resume field.
- On resume, clear the `blocked` fields and set the appropriate non-blocked status.
- `knowledge_sync.status` is `clean | pending | required`. `clean` requires an empty list; `none` never clears older entries. Reviewer appends accepted deferred/required Review paths; Knowledge Maintainer clears only synchronized paths.
- When activating a new Task, point `artifacts.task` to it and clear the current Build/Review pointers. Build and Review attempts replace only their respective current pointers; history remains in artifacts and Git.
- Before leaving `accepted` for Knowledge sync or a next Task, revalidate the accepted Review identity. A committed candidate checks its tree; a Git-backed single-main working tree checks `reviewed_fingerprint`. On mismatch, do not continue from the stale PASS.

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
| `reviewing/blocked` with `verification` and `blocked.owner: user` | requested user evidence arrives | `reviewing/active`; clear blocker fields | Reviewer with `continue_review` |
| `reviewing/blocked` with `integration` | repair preserves candidate bytes, approved intent, Task outcome, public boundary, and applicable Integration contract | `ready_to_review/active`; clear blocker fields and current Review pointer | Reviewer starts a new Review attempt against the unchanged candidate |
| `reviewing/blocked` with `integration` | repair changes candidate bytes but preserves approved intent, Task outcome, and public boundary | `ready_to_build/active`; clear stale Build/Review pointers | Builder creates a new Build attempt; the old verdict is invalid |
| `reviewing/blocked` with `integration` | repair changes approved intent, Task outcome, public boundary, or cross-lane ownership | `design/active`; supersede the affected Task/boundary | Architect with the required user approval when consequential |
| `reviewing/active` | Review PASS | `accepted/active` | route by Knowledge-sync policy and Lane topology |
| `accepted/active` | next approved Task is materialized | `ready_to_build/active` | Builder |
| `accepted/active` | final Task PASS has `knowledge_sync: none`, no older pending Review, and no active work | `synced/idle` | Architect with `await_feature_seed` |
| `accepted/active` | Knowledge checkpoint completes and more Feature design remains | `design/active` | Architect |
| `accepted/active` | Knowledge checkpoint completes with no active work | `synced/idle` | Architect with `await_feature_seed` |
| `synced/idle` or `accepted/active` | main applies one sealed Integration candidate and records the exact queue/range | `integration/active` | independent main Reviewer using Integration inputs |
| `integration/active` | main Reviewer begins or resumes the exact Integration Review | preserve `integration/active` | Reviewer with `continue_review` |
| `integration/active` | Integration Review PASS | `accepted/active` | Knowledge Maintainer when required; otherwise Main Front Desk/next approved queue action |
| `integration/active` | Integration Review fails or needs evidence | preserve `integration`, set `status: blocked`; retain the exact queue item, original `main_before`, current `main_after`, and interrupted Review action | responsible owner from Operations/Integration Gate |
| `integration/blocked` with `verification` or `context` | missing evidence/context is restored and candidate bytes, approved intent, and recorded Integration range are unchanged | `integration/active`; clear blocker fields and create/resume a new Integration Review attempt | independent main Reviewer with `continue_review` |
| `integration/blocked` with non-material `contract` | owning role repairs only malformed Integration/Review metadata and candidate bytes, approved intent, and recorded range are unchanged | `integration/active`; clear blocker fields, clear stale Review pointer, and create a new Integration Review attempt | independent main Reviewer |
| `integration/blocked` with `implementation` | responsible Builder starts a bounded repair; mark the old Integration attempt failed and persist its queue `repair.status`, `original_main_before`, and repair Task pointer before leaving Integration | `ready_to_build/active`; clear stale Integration Review pointer | Builder; a new Build/Review attempt is required |
| `integration/blocked` with `architecture` or material `contract`/`integration` change | mark the old Integration attempt failed, initialize its queue `repair` mapping with the original range, and supersede the affected Task/boundary | `design/active` | Architect with the required user approval when consequential |
| `reviewing/active` | a Build/Review repair referenced by the active Integration queue `repair` mapping PASSes, and Main Front Desk records the repaired committed `main_after` plus a new full `original main_before..repaired main_after` range | `integration/active`; clear blocker fields and never reuse the old Integration verdict | independent main Reviewer with a new Integration Review attempt |
| any | user evidence/input is required | preserve phase, set `status: blocked` | current responsible AI role with `blocked.owner: user` |

Create new build/review attempts for implementation fixes. Architecture changes supersede affected tasks. Contract/context repair may resume the same immutable candidate only through a new Review attempt; any candidate or approved-intent change requires the corresponding Build or Architecture path. Integration repair follows the same rule at range level: evidence-only recovery may reuse unchanged bytes/range through a new Review attempt, while any changed byte, intent, or public boundary invalidates the old verdict and requires a repaired committed `main_after` plus a new full range from the retained original `main_before`. While state temporarily enters design/build/review, the active queue item's optional `repair` mapping is the sole durable Integration-resume pointer; normal `next.action` changes must not clear it. Missing `repair` is backward-compatible and means no repair is active.

For a superseded single-main working-tree Build, apply the canonical interrupted-attempt disposition in `.ai/contracts/TASK_RECORD.md#task-quality-gate` and the three-way Baseline attribution in `.ai/contracts/BUILD_RESULT.md`. State stores only pointers to those artifacts; it does not redefine their fields. Preserve unrelated user work, and never perform destructive rollback automatically.

A deferred Knowledge entry is not `none`: when the Feature ends, synchronize it before using `synced/idle`.

Only the listed phase/status/blocker enums and transitions are valid. Task status records approval, not execution progress; state plus Build/Review Results record execution. On recovery, inspect state, its evidence artifact, and Git. Resume an in-progress phase only when those agree; otherwise route a context/attribution issue instead of silently replaying work.
