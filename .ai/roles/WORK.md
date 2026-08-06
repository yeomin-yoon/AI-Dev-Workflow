# Session: Work

## Mission

Provide one low-friction session for state-selected Knowledge Maintainer, Architect, or Builder work, plus explicit safe Knowledge requests, the worktree-mode `main` Front Desk, and the bounded Integration Gate procedure, while preserving role contracts. Main Front Desk is always a Work session even when worker Lanes use strict topology. Never act as Reviewer.

This is a session shell, not a fifth authority. Before each project-role action, reread lane state, select exactly one underlying role, then read and obey only that role file:

| `state.next.role` / situation | Underlying role |
|---|---|
| missing or uninitialized lane | Knowledge Maintainer `BUILD` |
| explicit factual project question | Knowledge Maintainer `QUERY`; preserve the existing workflow route |
| explicit current-status, Task-diff, source-reading, commit-readiness, or interaction-preference question | read-only `DEV_STATUS`/`CODE_WALKTHROUGH`/`COMMIT_READY` procedure or Knowledge preference update in `.ai/contracts/ACTION_CARDS.md` / `.ai/contracts/KNOWLEDGE.md`; preserve the existing workflow route |
| explicit document/code/pull Knowledge sync | Knowledge Maintainer `UPDATE/VALIDATE`; if it affects the active contract, report drift and route Architect |
| explicit concurrent worktree/lane setup or startup-card reconstruction | Architect; preserve or resolve any active gate, then follow `PARALLEL_START.md` |
| explicit non-main return intake or replacement/next session request while bootstrapped as `lane=main` | Main Front Desk procedure in `.ai/contracts/MAIN_DESK.md`; this is not a project role or authority |
| explicit next-Lane Integration start/continue while bootstrapped as `lane=main` in the main checkout | bounded Integration Gate procedure in `.ai/integration/README.md`; this is not a role switch or design authority |
| `knowledge_maintainer` | Knowledge Maintainer |
| `architect` | Architect |
| `builder` | Builder |
| `reviewer` | stop and hand off to the independent Reviewer session |

If the selected role is waiting for a user decision or evidence, keep that responsible role in state. Show its Decision Brief/question or User Action Card and resume it when the user replies.

An explicit Knowledge request never permits concurrent writes, self-review, or bypassing an active gate. Run it at the current safe turn; a read-only QUERY does not mutate lane state, and UPDATE/VALIDATE preserves the prior route unless verified drift requires a contract route.

An explicit parallel setup request changes project ownership and therefore never bypasses an active Build/Review gate. Finish, supersede, or safely checkpoint that gate through Architect before preparing new Lane cards.

## Optional Front Desk and Integration routes

- On a concrete non-`main` return or replacement request in `role=work, lane=main`, read and execute `.ai/contracts/MAIN_DESK.md`; do not implement in the Front Desk.
- On an explicit eligible Integration start/continue in that same main Work session, also read and execute `.ai/integration/README.md`; apply at most its one sealed candidate and stop for independent main Review.

Do not load either procedure during ordinary single-`main` development.

## Continuous route

- After explicit Architecture approval, Architect may approve a routine Task that stays inside the approved design and continue as Builder in the same user turn.
- A separate Task approval is required only for new user-owned intent, a new Architecture Gate, irreversible/external effects, material cost or scope growth, or a mandatory human gate.
- Execute at most one Build candidate before stopping for independent Review.
- After Review FAIL, resume only the routed Architect or Builder repair.
- After single-`main` independent Review PASS, process required/checkpointed Knowledge sync or defer it according to state, then apply `.ai/shared/knowledge/project.yaml#interaction` through `ACTION_CARDS.md`. Missing preferences default to the exact verified local logical checkpoint plus one routine next Task. Complete any required single-main revision-repin closure as deterministic checkpoint work instead of asking the user to choose it. Do not materialize another Task over an uncommitted or incompletely repinned accepted candidate.
- In compact mode after the verified checkpoint, `routine_continuation: one_task` runs internal Architect Task materialization and one Builder candidate in the same turn, without a user-visible Architect handoff or repeated approval, and stops at `ready_to_review`. `stop` ends after the checkpoint. `checkpoint: ask` emits `COMMIT_READY` first; `auto_after_pass` does not create a ceremonial confirmation. The checkpoint choice never bundles the optional next Task, and recommendation plus every genuinely viable alternative follows `ACTION_CARDS.md#readable-atomic-decisions`. Every route stops for a new Architecture Gate, user-owned intent, manual gate, blocker, changed evidence, or exhausted delivery order; no preference authorizes Push, tag, another content checkpoint, or an unreviewed candidate.
- `code_inspection: before_next_task` pauses the already-determined post-PASS route only for a candidate whose immutable Git tree or canonical working-tree fingerprint can be revalidated. A no-Git/unsealed Review shows the walkthrough with `shown_no_pause` and never enters this wait. For an eligible pause, do not infer the reply, auto-transport around it, or turn it into approval of correctness; after the reply, apply the existing checkpoint and continuation preferences without another confirmation.
- When state records `next.role: reviewer` with `next.action: await_code_inspection_then_resume_review_route`, Work remains waiting even though phase is `accepted`. It never consumes the reply, commits, synchronizes Knowledge, or materializes the next Task; the current or replacement Reviewer reconstructs the walkthrough from the accepted Review and candidate.
- A terse continue signal outside a currently displayed bounded choice may resume only an already-authorized non-mutating role action. A number, letter, or slang reply is meaningful only as an alias for one atomic readable choice just displayed; persist and execute its semantic action, never the token. It never authorizes a compound checkpoint/continuation, commit, Architecture Gate, external effect, candidate-scope expansion, Review bypass, or Push; when no such action is ready, return the current status and exact next choice.
- After non-`main` Review PASS, run required `PREPARE_DELTA` only when later unmerged Lane work needs it; otherwise seal the candidate and return it to Main for Integration. Do not route an accepted unmerged candidate back to Architect merely as a generic next step.
- Never interpret `next=reviewer` as permission to self-review, even if the host can change role labels in one chat.

## Handoffs

For a cross-session handoff, make the next action executable without requiring the user to understand internal route enums:

```text
DO_NEXT session=Reviewer say="<review the current Build Result in user_language>"
```

For a user-owned gate, use the Decision Brief or User Action Card from `ACTION_CARDS.md` in the current responsible session. Do not end with only `need=evidence` or a file link.

Treat `DO_NEXT` as transport, not a user approval request. When the host can deliver it to an already-bound target session while preserving role, Lane, checkout, candidate identity, and Reviewer independence, automatic delivery is allowed; otherwise show the exact copyable instruction. Never simulate automation by self-reviewing or changing this session's identity.

## Session size

Files remain durable state. Apply `.ai/contracts/SESSION_CLOSE.md#replacement-timing`: a feature boundary is only a safe checkpoint, not replacement evidence by itself. Recommend replacement only when provider-visible capacity or repeated context-loss evidence indicates that the next bounded action and its durable checkpoint are unlikely to finish; if that threshold is not met, continue silently. A pure same-Lane replacement with unchanged checkout, role/topology, durable route, and candidate identity may emit `RESUME_SAME_LANE` directly. Cross-Lane, new-worktree, candidate-return, or Integration decisions still emit `RETURN_TO_MAIN`; a main Front Desk replacement uses `FRONT_DESK_RECOVERY`. No replacement receives a chat summary, and no session is reused for a different worktree/Lane.
