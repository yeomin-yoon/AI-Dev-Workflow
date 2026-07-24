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
- metadata-only handoff commit: `H1`, with `C1` as ancestor
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
- Main verifies `B0`, `C1`, `T1`, ancestry, and the metadata-only range from Git.
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
- Reviewer PASS creates a metadata-only Integration Review/queue checkpoint commit.
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

## Acceptance

All seven cases must agree across:

- `.ai/BOOTSTRAP.md`
- `.ai/contracts/MAIN_DESK.md`
- `.ai/contracts/ACTION_CARDS.md`
- `.ai/contracts/SESSION_CLOSE.md`
- `.ai/contracts/BUILD_RESULT.md`
- `.ai/contracts/REVIEW_RESULT.md`
- `.ai/contracts/PARALLEL_START.md`
- `.ai/roles/WORK.md`
- `.ai/roles/BUILDER.md`
- `.ai/roles/REVIEWER.md`
- `.ai/roles/KNOWLEDGE_MAINTAINER.md`
- `.ai/integration/README.md`
- `.ai/integration/queue.yaml`
- `README.md`

Record static and live evidence separately. Passing this trace alone never claims provider, Git credential, engine, or desktop behavior.
