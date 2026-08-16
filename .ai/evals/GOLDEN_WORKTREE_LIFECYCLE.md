# Golden Worktree Lifecycle

Use this deterministic scenario before accepting a Workflow release that changes worktree, session, Review, Knowledge, or Integration contracts. It is a contract trace, not a claim that any provider UI or model run was exercised.

## Fixture

- primary checkout/Lane: `main`
- main session: compact Work Front Desk
- worker Lane: `character`
- worker topology: compact unless a case says strict
- committed common base: `B0`
- Task candidate commit: `C1`
- `tree(C1)`: `T1`
- Lane handoff commit: `H1`, with `C1` as ancestor
- main before Integration: `M0`
- main after Integration: `M1`
- independent Lane and main Reviewer sessions

## Case 1 — Front Desk identity

Given a strict worker Lane returns, Main Front Desk remains `role=work, lane=main`.

Expected:

- `RETURN_TO_MAIN.DO_NEXT` targets main Work, never main Architect.
- Strict topology affects only the replacement worker session.
- Main Architect is used only for a newly changed Architecture boundary.

## Case 2 — Exact candidate sealing

Given Builder records `base_revision=B0`, `result_revision=C1`, and `result_tree=T1`, Reviewer must inspect `B0..C1`.

Expected:

- PASS Review records `base_revision=B0`, `reviewed_revision=C1`, `reviewed_tree=T1`.
- `H1` contains the current Lane Task/Build/Review/state/delta artifacts.
- `C1..H1` contains only `.ai/lanes/character/**`.
- `RETURN_TO_MAIN` reports `candidate_status=sealed`, `reviewed_revision=C1`, `reviewed_tree=T1`, and `handoff_revision=H1`.

Reject sealing when the Review says `working-tree`, `tree(C1) != T1`, `C1` is not an ancestor of `H1`, a production path appears in `C1..H1`, or Task production dirt remains.

## Case 3 — Dirty classification

Given `H1` is sealed and an uncommitted local Observation exists:

Expected:

- `task_dirty=none`.
- `observation=<path>`.
- Main may integrate exact `H1`.
- `safe_to_remove=no` until the Observation is collected/preserved and the worktree is clean.

Given a Task production file changed after `C1`:

- `task_dirty=<path>`.
- candidate becomes `unsealed`.
- Main routes the exact Lane role needed to rebuild/commit/re-review; it does not merge.

## Case 4 — Inaccessible source checkout

Given Main cannot read the sibling worktree but can resolve its Branch and `H1` in the shared Git repository:

Expected:

- Main reads the committed Review/state from `H1`.
- Main verifies `B0`, `C1`, `T1`, ancestry, and the Lane-handoff-only range from Git.
- No chat summary is treated as authority.

If neither the source path nor `H1` is available, Main emits one User Action Card with exact evidence/steps/reply/fallback.

## Case 5 — Knowledge route

Given Review PASS changes a durable public entry point needed by later unmerged Lane work:

Expected:

- Reviewer sets `knowledge_sync=required` and routes Knowledge Maintainer `PREPARE_DELTA`.
- Knowledge writes only `.ai/lanes/character/knowledge-delta/**`, preserves the Review in pending sync, then creates `H1`.
- Canonical Knowledge is untouched until merged-source main Review PASS.
- Main Front Desk verifies source/main `pending_reviews`, preserves every deferred path in committed handoff/main state, and reaches zero at the required final/new-Feature/dependent-candidate checkpoint.

If no later unmerged Lane work needs the index, defer canonical sync and seal without an unnecessary delta.

## Case 6 — One-candidate Integration

Given `character` is the next approved dependency candidate and main is clean:

Expected:

- Main verifies sealed `H1`.
- Queue records `main_before=M0`.
- Main applies at most one candidate ending at `H1`; merge/fast-forward targets `H1`, while cherry-pick/squash applies the complete `B0..H1` range. It then records `main_after=M1`, actual `merge_strategy`, and `review_range=M0..M1`.
- Main stops and routes independent main Reviewer.
- Reviewer checks the exact range and candidate identity before PASS.
- An eligible non-`main` ordinary Task Review may use the configured `CODE_WALKTHROUGH` pause before its Lane handoff route; the later main Integration Review never creates that pause and records `code_inspection=not_applicable`.
- Reviewer PASS creates an Integration Review checkpoint commit containing only its Review, queue update, and required main state pointers.
- Only after integrated PASS may canonical Knowledge synchronize; an activated sync creates a separate role-owned Knowledge checkpoint commit.
- The next candidate never starts over uncommitted Integration tracking, canonical Knowledge, production, or unexplained paths.

Conflict, changed shared contract, added scope, or changed dependency evidence stops the loop and routes the responsible Builder or Architect. It never triggers unattended conflict resolution or all-Lane merging.

## Case 7 — Close and replacement

Expected:

- Normal close emits the complete `SESSION_CLOSED` form from on-demand `SESSION_CLOSE.md`.
- Every non-main close adds a full diagnostic `RETURN_TO_MAIN` with role/topology/language/tool preference and exact Git fields.
- Its single pasted `DO_NEXT` carries only source Lane/worktree, topology/language, Branch, head, and handoff locators. Main reconstructs role/candidate/Review/dirty state from files and Git.
- A missing locator is derived only when worktree/Branch/Lane state yields one unique value; ambiguity produces a User Action Card.
- A replacement prompt uses the returned topology; missing/invalid preference defaults to compact.
- A bare close never commits, merges, collects Observations, deletes a worktree, or changes Lane identity.
- Already-open Work and Reviewer sessions in the same Lane still hand off directly.

## Case 8 — Post-integration Lane continuation

Given the `character` candidate is integrated and independently accepted, and another Task remains inside the same approved Lane boundary:

Expected:

- Main Front Desk chooses `continue` only after required source-Lane/canonical Knowledge checkpoints are satisfied.
- The old worker worktree/Branch is never used as the next baseline, regardless of merge, cherry-pick, or squash strategy.
- A fresh collision-free Branch/worktree is pinned to current clean main while retaining `lane=character`; no second active worktree uses that Lane identity.
- The new Work session performs targeted Knowledge/state validation, updates Lane `source_revision`, and resumes Architect without replaying the completed Task or broad-scanning the repository.
- A changed purpose, ownership, shared contract, or dependency order routes Architect through a new boundary decision.
- No remaining work leaves the Lane at `synced/idle`; `retired` and worktree removal remain separate explicit decisions.
- In the terminal variant, the last Integration PASS and required Knowledge checkpoint still route Architect through `reconcile_feature_boundary` before any `synced/idle` disposition. An open-only or mixed open plus user-approved-deferred outcome returns `design/active`; only all-implemented/excluded coverage, or explicitly approved deferred work reported as paused/incomplete, may rest at `synced/idle`.

## Case 9 — Integration blocker repair and resume

Given main records `main_before=M0`, applies one sealed candidate to `M1`, and Integration Review becomes blocked:

- If only missing verification/context arrives or the owning role fixes malformed metadata, while `M0..M1`, candidate bytes, and approved intent remain unchanged, state returns from `integration/blocked` to `integration/active` and a new independent Integration Review attempt checks the same range.
- If an implementation repair changes bytes, the old queue attempt becomes `failed`; its optional `repair` mapping preserves `original_main_before=M0` plus the current repair Task/Build/Review pointers while state routes normal Builder/Reviewer attempts, and the old verdict is invalidated.
- After that repair PASS, Main Front Desk records a committed repaired revision `M2` and the new full Integration Review range `M0..M2`; only a new independent Review over that range may accept it.
- If architecture, a material contract, ownership, scope, or dependency order changes, the same repair mapping retains `M0`; Architect supersedes the affected boundary/Task and obtains any consequential approval before another candidate is built.
- A conflict/partial checkout never becomes a baseline. If it cannot be recovered with a project-safe non-lossy action, the user receives an actionable Git recovery card and Integration remains blocked.

## Case 10 — Cross-lane requirement revision

Given approved requirement `Docs/SharedPRD.md#REQ-SHARED-1@R1` governs one shared contract consumed by `character` and `ui`, System Architecture pins that exact ref, and newly approved revision `R2` changes the contract:

- Architect versions `.ai/shared/SYSTEM_ARCHITECTURE.md`, pins `Docs/SharedPRD.md#REQ-SHARED-1@R2` once in its canonical `requirement_refs`, and updates the affected ownership/contract before another Integration attempt.
- Every approved or active Task in each affected Lane is superseded and regenerated against the new System Architecture before Build/Integration. An unaffected Lane is not interrupted merely because the requirement document changed.
- Lane Architecture may explain its local consequence but never duplicates ownership of the cross-lane requirement ref. A missing historical System Architecture field reads as an empty optional baseline until the next applicable cross-lane decision.
- Main rejects Integration when the shared requirement revision, System Architecture version, or any affected Task still points to `R1`; chat summaries cannot bridge the mismatch.

## Acceptance

All ten cases must agree across:

- `.ai/BOOTSTRAP.md`
- `.ai/contracts/MAIN_DESK.md`
- `.ai/contracts/ACTION_CARDS.md`
- `.ai/contracts/SESSION_CLOSE.md`
- `.ai/contracts/BUILD_RESULT.md`
- `.ai/contracts/REVIEW_RESULT.md`
- `.ai/contracts/PARALLEL_START.md`
- `.ai/shared/SYSTEM_ARCHITECTURE.md`
- `.ai/roles/WORK.md`
- `.ai/roles/BUILDER.md`
- `.ai/roles/REVIEWER.md`
- `.ai/roles/KNOWLEDGE_MAINTAINER.md`
- `.ai/integration/README.md`
- `.ai/integration/queue.yaml`
- `README.md`

Record static and live evidence separately. Passing this trace alone never claims provider, Git credential, engine, or desktop behavior.
