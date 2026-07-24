# Integration Control

Integration Gate is a user-started procedure, not a fifth role/session. `integration_order` is the dependency-safe merge order already approved with the parallel ownership boundary in System Architecture/Integration Requests. The user does not choose or reapprove it at every merge. Ask for a new decision only when conflicts, shared-contract changes, added scope, or new evidence require the approved order/boundary to change.

`PARALLEL_START` is the earlier Architect-owned setup handoff, not Integration Gate and not another session. It freezes non-overlapping ownership/shared contracts in one committed base and gives the user exact per-Lane creation and Bootstrap copy blocks. Integration begins only after a Lane has a sealed Review-PASS candidate.

Durable `next.role` remains the designated Architect or Reviewer while a user decision/merge/evidence is pending. Store Integration Gate in `next.action` and the queue/request artifacts; never invent an `integration` or `user` role.

Integration Review Results live in `.ai/integration/reviews/` and follow `.ai/contracts/REVIEW_RESULT.md`.
The designated Reviewer updates queue item status and `integration_review`; Knowledge Maintainer updates only final knowledge-sync fields.

- Lanes do not edit another lane's internals.
- Shared changes start as Integration Requests.
- Use one writer for shared files and canonical knowledge.
- Queue only Review-PASS changes.
- Merge one lane at a time and run decisive checks after each merge.
- After all merges, run integration checks and architecture-drift review.

`queue.yaml` stores candidate identity/order, exact main before/after revisions, merge strategy, and verification status only—never chat summaries or full logs.

After merge, Knowledge Maintainer validates lane deltas against integrated source before canonical promotion.

## User loop

1. A non-`main` Lane reaches independent commit-scoped Review PASS, completes any required `PREPARE_DELTA`, creates its metadata-only handoff commit, and closes through `.ai/contracts/MAIN_DESK.md` without rebinding itself to `main`.
2. `RETURN_TO_MAIN` records the source Branch, exact reviewed commit/tree, handoff revision, classified dirty paths, Review, and main target. If the candidate is not sealed, Main Front Desk routes an actionable prerequisite instead of pretending it is mergeable.
3. The user pastes the card's `DO_NEXT` into the existing main Work session. That copy explicitly authorizes Main Front Desk to accept the return and, when eligible, apply only the next clean candidate in the approved order. It does not authorize conflict resolution, boundary change, deletion, or an unattended all-Lane merge.
4. Main Work verifies the approved order, PASS Review, `base_revision..reviewed_revision` identity, recorded tree, metadata-only `reviewed_revision..handoff_revision` range, expected base, clean main checkout, and project Git rules. Source-worktree Observation or unrelated dirty paths do not alter the sealed commit, but they keep that worktree unsafe to remove.
5. Main Work records `main_before` and applies one sealed candidate ending at `handoff_revision`. A merge/fast-forward targets that revision; cherry-pick or squash must apply the complete `base_revision..handoff_revision` range rather than the metadata commit alone. It then records `main_after`, actual merge strategy, and `review_range=main_before..main_after`, and emits an exact `DO_NEXT` to the independent `main` Reviewer.
6. Main Reviewer verifies that exact integration range, the Lane production diff against its PASS Review, post-review metadata-only paths, affected contracts, and decisive checks. On PASS, it commits only its Integration Review, queue update, and required main state pointers as a metadata checkpoint.
7. If canonical Knowledge is required before continuing or all candidates are complete, Knowledge Maintainer synchronizes from integrated source and creates its role-owned Knowledge checkpoint commit. Otherwise Reviewer routes back to main Work for the next candidate.

If Main Work cannot access the source worktree, it may verify a sealed candidate from Branch/object data because the handoff revision contains the authoritative Lane artifacts. If neither source files nor the committed handoff are available, emit a `USER_ACTION` with the exact Branch/revisions, app or command steps, observable PASS/FAIL state, reply template, and safe fallback.

If the candidate is working-tree-only, lacks a PASS Review in its handoff revision, has a tree mismatch, or has Task production changes after the reviewed commit, route to the exact Lane session needed to commit/review/seal it. If a merge conflicts, stop before conflict resolution; route an implementation-only conflict to the responsible Builder and a changed shared contract/boundary/order to Architect. Never turn an explicit start into an unattended all-Lane merge.

Before starting the next candidate, require no uncommitted production, Integration tracking, Knowledge, or unexplained path in main. An Observation may remain local because it is not part of the candidate, but it must be reported and preserved before later worktree removal. If a required checkpoint commit fails, stop with an actionable prerequisite rather than stacking another merge on dirty tracking state.
