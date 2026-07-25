# Contract: Lane State

Path: `.ai/lanes/<lane>/state.yaml`

```yaml
schema_version: 2
lane: <lane>
phase: uninitialized
status: idle
source_revision: null
active_feature: null
active_task: null
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
open_risks: []
updated_at: null
```

State is a pointer record, not a chat summary. Update evidence artifact and next role with every phase change. One writer edits a lane state at a time. Do not add progress prose, completed-task history, or model-specific phases; Review artifacts and Git carry history.

- `phase` is the preserved lifecycle position shown below; never set it to `blocked`.
- `status` is `idle | active | blocked | complete`.
- `complete` is reserved for a lane whose `lane.yaml.status` the user explicitly sets to `retired`; normal Task/Feature completion uses `synced + idle`.
- `next.role` is `knowledge_maintainer | architect | builder | reviewer` and always names the AI role responsible for consuming the next input and transition. Represent pending user input in `next.action` and, when blocked, `blocked.owner: user`; never store `user` or `integration` as a role.
- On a blocker, keep `phase`, set `status: blocked`, fill all `blocked` fields, and persist the responsible owner/next input.
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
| `discovery/active` | initial discovery completes | `synced/idle`; clear active Feature/Task and Task/Build/Review pointers, retain Architecture | Architect with `await_feature_seed` |
| `synced/idle` or `accepted/active` | Architect accepts a Feature seed or starts approved redesign | `design/active` | Architect with `continue_design` |
| `design/active` | consequential user decision is pending | preserve `design/active` | Architect with `await_user_*` action |
| `design/active` | approved Task is materialized | `ready_to_build/active` | Builder with Task inputs |
| `ready_to_build/active` | Builder preflight succeeds, before production writes | `building/active` | Builder with `continue_build` |
| `building/active` | truthful Build Result is complete | `ready_to_review/active` | Reviewer with exact candidate inputs |
| `ready_to_review/active` | Reviewer accepts preflight, before substantive Review | `reviewing/active` | Reviewer with `continue_review` |
| `reviewing/active` | `implementation` finding | `ready_to_build/active`; create a new attempt and clear current Review pointer | Builder |
| `reviewing/active` | another routed finding (`architecture`, `contract`, `context`, `verification`, or `integration`) | preserve `reviewing`, set `status: blocked` | responsible AI role resolved by Operations/Integration Gate; use `blocked.owner: user` only for required user input |
| `reviewing/active` | Review PASS | `accepted/active` | route by Knowledge-sync policy and Lane topology |
| `accepted/active` | next approved Task is materialized | `ready_to_build/active` | Builder |
| `accepted/active` | Knowledge checkpoint completes and more Feature design remains | `design/active` | Architect |
| `accepted/active` | Knowledge checkpoint completes with no active work | `synced/idle` | Architect with `await_feature_seed` |
| `synced/idle` or `accepted/active` | main applies one sealed Integration candidate and records the exact queue/range | `integration/active` | independent main Reviewer using Integration inputs |
| `integration/active` | main Reviewer begins or resumes the exact Integration Review | preserve `integration/active` | Reviewer with `continue_review` |
| `integration/active` | Integration Review PASS | `accepted/active` | Knowledge Maintainer when required; otherwise Main Front Desk/next approved queue action |
| `integration/active` | Integration Review fails or needs evidence | preserve `integration`, set `status: blocked` | responsible owner from Operations/Integration Gate |
| any | user evidence/input is required | preserve phase, set `status: blocked` | current responsible AI role with `blocked.owner: user` |

Create new build/review attempts for implementation fixes. Architecture changes supersede affected tasks.

Only the listed phase/status/blocker enums and transitions are valid. Task status records approval, not execution progress; state plus Build/Review Results record execution. On recovery, inspect state, its evidence artifact, and Git. Resume an in-progress phase only when those agree; otherwise route a context/attribution issue instead of silently replaying work.
