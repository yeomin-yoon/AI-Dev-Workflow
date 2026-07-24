# Migration: manual-v1.11 → manual-v1.12

This declarative migration is inspected and applied by the update worker; it is not an executable script.

## Scope

- from: `manual-v1.11`
- to: `manual-v1.12`
- writable preserved paths:
  - `.ai/lanes/<runtime-lane>/lane.yaml` (every lane except `_template`)
  - `.ai/lanes/<runtime-lane>/state.yaml` (every lane except `_template`)
  - `.ai/lanes/<runtime-lane>/tasks/TASK-*.md` (every lane except `_template`)
  - `.ai/integration/requests/IR-*.md`
  - `.ai/shared/knowledge/**/*.yaml`
- additional read-only paths:
  - the current Review Result referenced by each runtime `state.yaml`

## Preconditions

- The exact paths above were backed up by `UPDATE.md`.
- No lane/Knowledge writer is active.
- Local managed-file conflicts were resolved before migration.
- Each lane is `synced/idle`, or its current Task/Review pointers and route are unambiguous under the v1.12 contracts. Otherwise defer until `synced/idle`.
- Any ambiguous state or conflicting old/new key stops the update and triggers rollback.

## Transform

1. For each runtime `lane.yaml`, remove only the exact default `.ai/shared/**` item from `shared_read_only`, preserve every production-path item, and set `schema_version: 2`. Preserve `uninitialized | active | retired`; map `ready | initialized` to `active`, and stop on any other lane status. Never add `owned_paths`.
2. For each runtime `state.yaml`, set `schema_version: 2`. If `next.role` is `user` or `integration`, replace it with the responsible `knowledge_maintainer | architect | builder | reviewer` only when the active artifact, phase, and `next.action` make that consumer unambiguous; preserve/refine `next.action` as `await_user_*` when applicable. Otherwise stop for an explicit owner decision.
3. In Task front matter, keep `draft | proposed | approved | rejected | superseded`. Map `building | ready_to_review | accepted | blocked` to `approved` only when `approved_by` or `approval_basis` proves prior approval; otherwise stop. Execution evidence remains in state, Build Results, and Review Results.
4. In Integration Request front matter, keep `proposed | approved | rejected | superseded`. Map `implemented | verified` to `approved` only when its Decision/owner proves approval; merge and verification evidence remains in the queue and Integration Review Results. Otherwise stop.
5. Under canonical Knowledge YAML, rename every `source_commit` key to `source_revision`. When both exist, remove the old key only if values match; otherwise stop. Set the root `manifest.yaml`, `project.yaml`, and `glossary.yaml` to `schema_version: 2`.

## Validate

- Runtime lane/state schemas are `2`.
- Lane status is `uninitialized | active | retired`, and production path sets do not overlap.
- `state.next.role` is only `knowledge_maintainer | architect | builder | reviewer`.
- No Task uses an execution-progress status.
- No Integration Request uses merge/verification progress as approval status.
- No canonical Knowledge YAML contains `source_commit`.
- Existing production ownership, artifact paths, pending Reviews, decisions, and evidence are otherwise unchanged.
- Any current Review Result's verdict/sync/Route agrees with migrated state; historical Reviews are not rewritten.
- Bootstrap readiness succeeds on every migrated lane and on a disposable lane made from `_template`.

## Rollback

On any failed transform or validation, restore every scoped path and managed target from the update backup and keep `installed_version: manual-v1.11`.
