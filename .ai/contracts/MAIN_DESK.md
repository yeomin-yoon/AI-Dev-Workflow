# Contract: Main Front Desk

Read this only when a non-`main` session is closing/returning, or when the `main` Work session receives that return and must issue the next session. Ordinary Work-to-Reviewer handoffs inside one active Lane do not use the Front Desk.

## Purpose and authority

In worktree mode, a `role=work, lane=main` session is always the Front Desk. Strict topology may separate roles inside worker Lanes, but it never turns the main Architect into the Front Desk or Integration executor. If ordinary `main` development uses four strict sessions, open the standard compact main Work session before starting worktree mode.

The Front Desk is a user-operated control point, not another project role, daemon, or autonomous orchestrator. It does not create chats, message sessions, invent Lane boundaries, or replace Architecture, state, Review, Git, or Knowledge authority.

The user carries one short return instruction. Durable files and Git carry project state; the return card may carry only non-authoritative presentation preferences such as topology, language, and suggested tool.

```text
main Work Front Desk -> NEXT_SESSION -> Lane worktree sessions
Lane session close -> RETURN_TO_MAIN -> main Work Front Desk
```

Keep already-open Work and Reviewer sessions inside the same Lane on their direct handoff path. Use the Front Desk only when a session is actually being closed/replaced, the user leaves a Lane/worktree, a Review-PASS candidate returns for Integration, or a new Lane/session card is needed.

## Sealed candidate

A non-`main` candidate is eligible for Integration only when:

1. Builder produced a Task-scoped `result_revision` commit from the recorded `base_revision`.
2. Reviewer inspected that same commit as `reviewed_revision`, using the exact `base_revision..reviewed_revision` range, and recorded `reviewed_tree = reviewed_revision^{tree}` in a PASS Review.
3. Any required pre-integration `knowledge-delta` is complete.
4. A later `handoff_revision` contains the current Lane Task, Build, PASS Review, state, and delta artifacts; `reviewed_revision` is its ancestor.
5. `reviewed_revision..handoff_revision` changes only current-Lane workflow artifacts under `.ai/lanes/<lane>/**`.
6. No Task-attributed production/test change remains outside `reviewed_revision`.

The last required Lane role creates the Lane handoff commit as part of its selected PASS or `PREPARE_DELTA` route, before session close. Reviewer does it when Knowledge sync is `defer` or `none`; Knowledge Maintainer does it after required `PREPARE_DELTA`. This commit stages only `.ai/lanes/<lane>/**`. It never includes production files, shared/canonical Knowledge, the Integration queue, or Workflow maintenance files.

Candidate and handoff commits are normal, explicitly defined worktree-mode delivery steps. A bare close request never creates either commit. If a commit cannot be created safely because attribution, credentials, hooks, signing, or permissions are unresolved, keep the candidate `unsealed` and emit an actionable route or User Action Card.

Historical or single-`main` Reviews may still reference `working-tree`, but an uncommitted or working-tree Review is never Integration-eligible. Commit it and perform a new exact-revision Review before sealing.

## Worker delivery procedure

Load this section only inside an explicitly approved non-`main` worktree Lane.

Builder creates the immutable Task candidate:

1. verify the recorded full-commit `base_revision` and pre-existing dirty baseline;
2. stage only Task-attributed production/config/asset/test paths;
3. inspect the staged diff and prove every path maps to the Task/AC;
4. commit with the Task ID, then record the commit as `result_revision` and its tree as `result_tree`;
5. leave Build Result, state, and other current-Lane `.ai` artifacts for the later Lane handoff commit.

The approved worktree flow authorizes this isolated commit without another confirmation. Never include unrelated user changes, canonical/shared Knowledge, Integration state, Observations, or Workflow maintenance files. If attribution, hooks, signing, credentials, or permissions prevent a truthful commit, keep it unsealed and provide one actionable prerequisite.

After exact-revision independent PASS:

- With `knowledge_sync: defer | none`, Reviewer stages only current-Lane artifacts under `.ai/lanes/<lane>/**`, verifies the reviewed commit/tree and ancestry, confirms no Task production dirt remains, and creates the Lane `handoff_revision`.
- With `knowledge_sync: required`, Reviewer does not seal. Knowledge Maintainer performs `PREPARE_DELTA`, stages only `.ai/lanes/<lane>/**`, repeats the same ancestry/dirty checks, and creates the handoff commit.
- A failed seal does not erase a valid diagnostic PASS, but it leaves `candidate_status=unsealed` and requires an actionable Integration prerequisite.

## Return from a non-main session

Before emitting a return:

1. Complete the Bootstrap Close checkpoint. Preserve any already-created manual Observation, but never create one merely because the session is closing.
2. Resolve the source repository root/worktree, Lane, current role, Branch, `HEAD`, and read-only Git status.
3. Read only current lane state and its active artifact pointers.
4. Resolve the primary/main worktree from approved Parallel Start data when available, otherwise verified Git worktree state. Never guess from a folder name.
5. Classify remaining changes without mutating Git:
   - `task_dirty`: Task-attributed production/test paths outside the reviewed commit.
   - `workflow_dirty`: uncommitted `.ai` workflow paths other than the reported Observation.
   - `unrelated_dirty`: all other modified/untracked paths.
6. Do not commit, merge, collect Observations, delete a worktree, or change Lane identity during close.

After the normal `SESSION_CLOSED` result, emit this concrete card in `user_language`; omit no value and use `none` or `unknown` when applicable:

```text
RETURN_TO_MAIN
source_lane=<lane>
source_worktree=<absolute path>
source_role=<Work|Reviewer|Architect|Builder|Knowledge>
topology=<compact|strict>
user_language=<ISO 639-1 code>
suggested_tool=<user-supplied tool|unknown>
branch=<branch>
head_revision=<HEAD commit>
state=<lane state path>
candidate_status=<sealed|unsealed|none>
review=<current unintegrated PASS Review path|none>
base_revision=<commit|none>
reviewed_revision=<commit|none>
reviewed_tree=<tree hash|none>
handoff_revision=<commit|none>
task_dirty=<paths|none|unknown>
workflow_dirty=<paths|none|unknown>
unrelated_dirty=<paths|none|unknown>
observation=<path|none>
main_worktree=<absolute primary/main path>
DO_NEXT session=Work lane=main worktree=<main_worktree> say="<accept return source_lane=... source_worktree=... topology=... user_language=... branch=... head_revision=... handoff_revision=...; restore from files/Git, perform at most the next approved action, and stop on ambiguity, conflict, or boundary change>"
```

The emitted `say` instruction replaces every placeholder above with the card's concrete value. The copied line carries only the minimum checkout/Lane/revision locators plus topology/language preference. Main reconstructs role, candidate status, Review, and dirty state from verified files/Git rather than chat. Copying it authorizes only the bounded next step, not conflict resolution, scope change, deletion, or an unattended all-Lane merge. It must not contain a chat summary or ask the user to interpret state enums.

`candidate_status=sealed` is valid only when every sealed-candidate condition above is verified. Never advertise a stale, failed, blocked, superseded, working-tree-only, or already integrated Review merely because its file still exists.

Remaining dirty paths do not automatically invalidate a sealed revision: Main integrates the exact committed `handoff_revision`, not the source working tree. However, `task_dirty` makes the candidate unsealed, and any dirty path keeps the worktree unsafe to remove. A created Observation remains local until collected or otherwise preserved.

The `main` session does not return to itself. Replacing the Front Desk uses the recovery procedure below; it is reconstructible and need not remain open while worker Lanes run.

## Front Desk recovery

A main Front Desk replacement may use another available session/tool in the same main checkout without claiming model parity. Recovery does not depend on the exhausted chat: the user or any available source session can reconstruct this card from the checked-in contract. Emit:

```text
RESULT=front_desk_recovery
FRONT_DESK_RECOVERY
worktree=<absolute main checkout>
prompt=Read .ai/BOOTSTRAP.md. role=work, lane=main, session_mode=compact, user_language=<ISO 639-1>
first_request=Read .ai/contracts/MAIN_DESK.md#front-desk-recovery and restore Front Desk from files/Git. Inspect main status, Integration queue, active item/repair, pending Reviews/Knowledge, and report the next bounded action without integrating on ambiguity.
```

The recovered Front Desk first verifies main `HEAD`/dirty state, `.ai/integration/queue.yaml` status and active item, recorded `main_before`/`main_after`, repair pointer, source Branch/handoff identities, and pending canonical Knowledge. If queue state says `merging`/`integrating`, or Git indicates a candidate may have been applied while `main_after` is absent, recover only when Git plus the queue identify one exact candidate and range; otherwise issue a User Action Card and perform no merge, reset, conflict resolution, or new candidate. A Front Desk is event-driven: open or recover it for cards, Integration, and routing rather than keeping one long-lived chat alive or batching candidates by count.

## Front Desk intake

On the copyable return instruction, Main Front Desk:

1. Prefers the supplied source worktree and reads its lane state/current pointers plus read-only Git status.
2. If that path is inaccessible, resolves the supplied Branch and exact `head_revision`/`handoff_revision` in the shared repository and reads committed state/Review from there.
3. If a copied locator is missing, derives it only when verified `git worktree` state, Branch, and `.ai/lanes/<lane>/state.yaml` identify one unique value. Otherwise emits a User Action Card; never guesses or treats chat as authority.
4. Treats topology and language as presentation preferences only. If missing or invalid, defaults replacement sessions to compact topology and the current user language; tool choice defaults to `any`.
5. Verifies sealed-candidate ancestry, tree hash, PASS Review, post-review Lane-handoff-only diff, pending user evidence, dependencies, local Observations, and the approved integration order.
6. Checks both source and main `knowledge_sync.status` plus `pending_reviews`. Preserve every deferred Review path in the committed handoff/main state; `none` never clears older entries. Run the required canonical checkpoint before a new Feature, final Integration completion, or any next candidate that needs the updated index.
7. Chooses exactly one outcome: issue a replacement/next session, start the next eligible Integration candidate, request one actionable prerequisite, or accept the return with no next session.
8. Never deletes a worktree. Report `safe_to_remove=yes` only when it is clean, has no unintegrated or uniquely needed state, local Observations are preserved, and any pending Review evidence also exists in the committed handoff or main checkout. Deferred canonical sync may remain batched when its evidence is safely preserved outside the source worktree.

For an existing approved Lane/session, return one self-contained card in `user_language`:

```text
RESULT=next_session
NEXT_SESSION
lane=<lane>
worktree=<absolute path>
topology=<compact|strict>
session=<Work|Reviewer|Architect|Builder|Knowledge>
suggested_tool=<tool|any>
purpose=<one sentence>
prompt=<exact Bootstrap prompt>
first_request=<exact short instruction>
```

The user opens a new session in `worktree`, pastes `prompt`, waits for `READY`, then pastes `first_request`. Never ask the user to edit `lane=main`, recover an old chat, or assemble a prompt. Use `Work` for Knowledge/Architect/Builder routes in compact topology and the fixed role in strict topology.

If a new worktree/Lane is required, Main Front Desk routes Architect through `PARALLEL_START.md`; it does not fabricate a `NEXT_SESSION` before the boundary and committed base are approved. If the next candidate is sealed and dependency-eligible, follow `.ai/integration/README.md` and integrate one candidate ending at its exact `handoff_revision` before independent main Review; non-merge strategies must apply the complete sealed range, not the Lane handoff commit alone.

## Post-integration Lane disposition

After a Lane candidate is integrated, independently reviewed, and any required canonical Knowledge checkpoint is complete, Main Front Desk chooses one explicit disposition:

- `complete`: leave the Lane `active` and resting at `synced/idle`; `retired` requires a separate explicit user decision. Report whether the old worktree is safe to remove, but never delete it.
- `continue`: reuse the same Lane ID and approved ownership only sequentially from the current clean main baseline. Do not continue in the old worker worktree/Branch: merge, cherry-pick, and squash can leave its history or Knowledge behind main even when its candidate was accepted.
- `redesign`: route Architect before another worktree when ownership, shared contracts, dependency order, or purpose changes.

For `continue`, verify that main contains the accepted Lane artifacts, no source-Lane `pending_reviews` needed by the next work remain unsynchronized, the prior candidate is integrated, and no second active worktree is bound to the same Lane. Then read `PARALLEL_START.md#post-integration-continuation` and emit its fresh worktree/Branch card pinned to current main. The new Work session performs targeted Knowledge/state validation, updates the Lane `source_revision`, and resumes Architect; it does not broad-scan or replay the integrated Task.

If the user wants another Task but the old worktree is still dirty or holds an unpreserved Observation, that affects removal only. It never makes the old divergent checkout the baseline for continuation.

When no session is required, return:

```text
RESULT=return_accepted next=none safe_to_remove=<yes|no>
reason=<short user-language reason>
```

Cards are executable projections, not project authority. If a card conflicts with files or Git, files/Git win and the Front Desk reports the mismatch.
