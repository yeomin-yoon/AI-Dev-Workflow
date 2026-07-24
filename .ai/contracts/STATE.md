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

```text
uninitialized → discovery → synced/idle
new feature → design → ready_to_build → building
→ ready_to_review → reviewing → accepted
  ├─→ ready_to_build (next task; Knowledge pending/not needed)
  ├─→ synced (single-lane Knowledge checkpoint)
  └─→ integration → synced (multiple lanes)
```

Any lifecycle phase may have `status: blocked`. Typical routes:

| Event | State action | Next |
|---|---|---|
| initial discovery complete / no active feature | `phase: synced`, `status: idle`; clear active Feature/Task and Task/Build/Review pointers, retain Architecture | Architect with `await_feature_seed` |
| architecture/user decision pending | `phase: design`, `status: active` | responsible Architect with `await_user_*` action |
| approved task | `phase: ready_to_build`, `status: active` | Builder |
| build result | `phase: ready_to_review`, `status: active` | Reviewer |
| user evidence/input pending | preserve phase, `status: blocked` | responsible AI role with `blocked.owner: user` |
| implementation finding | `phase: ready_to_build`, `status: active` | Builder |
| architecture/public-boundary finding | preserve phase, `status: blocked` | Architect/user when approval is needed |
| artifact-contract finding | preserve phase, `status: blocked` | owning artifact role |
| context finding | preserve phase, `status: blocked` | Knowledge Maintainer or owner of missing authoritative input |
| verification finding | preserve phase, `status: blocked` | Reviewer/user |
| integration finding | preserve phase, `status: blocked` | designated Architect/Reviewer awaiting user-coordinated Integration Gate |
| review PASS, sync required/checkpoint | `phase: accepted`, `status: active` | Knowledge Maintainer (`INTEGRATE` on main; `PREPARE_DELTA` only when later unmerged Lane work needs it), otherwise sealed Integration return |
| review PASS, sync deferred/not needed | `phase: accepted`, `status: active` | Architect/next task |
| integrated and synced | `phase: synced`, `status: idle` | Architect/next task |

Create new build/review attempts for implementation fixes. Architecture changes supersede affected tasks.

Only the listed phase/status/blocker enums are valid. For example, use `building`, not `build`. Task status records approval, not execution progress; state plus Build/Review Results record execution.
