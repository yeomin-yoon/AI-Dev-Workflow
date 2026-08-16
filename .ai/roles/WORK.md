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

Keep the selected responsible role in state while it awaits a user decision/evidence and reconstruct its `ACTION_CARDS.md` projection on reply. For unexpected behavior or a corrected claim, select the owner and apply `OPERATIONS.md#bounded-diagnosis-during-active-delivery`; preserve the approved outcome and do not let a non-blocking discovery replace the route.

User-facing status distinguishes the Work shell from the active project role in plain language. Explicit Knowledge work preserves the prior route unless verified drift requires repair, and parallel setup never bypasses an active Build/Review gate.

## Optional Front Desk and Integration routes

- On a concrete non-`main` return or replacement request in `role=work, lane=main`, read and execute `.ai/contracts/MAIN_DESK.md`; do not implement in the Front Desk.
- On an explicit eligible Integration start/continue in that same main Work session, also read and execute `.ai/integration/README.md`; apply at most its one sealed candidate and stop for independent main Review.

Do not load either procedure during ordinary single-`main` development.

## Continuous route

- After explicit Architecture approval, Architect may approve a routine Task that stays inside the approved design and continue as Builder in the same user turn.
- A separate Task approval is required only for new user-owned intent, a new Architecture Gate, irreversible/external effects, material cost or scope growth, or a mandatory human gate.
- Execute at most one Build candidate before stopping for independent Review.
- After Review FAIL, resume only the routed Architect or Builder repair.
- After single-`main` PASS, follow the state-selected Knowledge route and `.ai/shared/knowledge/project.yaml#interaction` through `ACTION_CARDS.md`. Missing preferences mean one exact logical checkpoint plus one routine Task; deterministic revision repinning is closure, not another choice. Never start a Task over an uncommitted/incompletely repinned accepted candidate.
- Compact `one_task` continuation may materialize and build one already-approved routine Task without a user-visible Architect handoff or repeated approval, then stops at `ready_to_review`. Every new Gate, user-owned intent, manual gate, blocker, changed evidence, or exhausted delivery order stops it; preferences never authorize Push/tag, another content checkpoint, or an unreviewed candidate.
- When no next Task is materialized after the accepted candidate and required Knowledge/checkpoint closure, run Architect's bounded Feature convergence in the same compact Work session when possible. Do not declare completion from the last Task PASS, invent another user confirmation, or skip a specified open slice; strict topology may hand off to Architect with `reconcile_feature_boundary`.
- `before_next_task` uses the durable Reviewer-owned code-inspection wait only for revalidatable identity; no-Git/unsealed shows without pausing. Work never consumes that reply or routes around the wait.
- A terse token resumes only the semantic non-mutating action just displayed. It never authorizes a compound choice, commit, Gate, external effect, scope expansion, Review bypass, or Push.
- After non-`main` Review PASS, run required `PREPARE_DELTA` only when later unmerged Lane work needs it; otherwise seal the candidate and return it to Main for Integration. Do not route an accepted unmerged candidate back to Architect merely as a generic next step.
- Never interpret `next=reviewer` as permission to self-review, even if the host can change role labels in one chat.

## Handoffs

Use the exact executable `DO_NEXT` from `ACTION_CARDS.md` for cross-session transport and its Decision/User Action Card for a current-session user Gate; never end with only an enum or link. A host may deliver `DO_NEXT` automatically only while preserving role, Lane, checkout, candidate identity, and Reviewer independence. Never simulate transport by self-reviewing or changing identity.

## Session size

Files remain durable state. Apply `.ai/contracts/SESSION_CLOSE.md#replacement-timing`: a feature boundary is only a safe checkpoint, not replacement evidence by itself. Recommend replacement only when provider-visible capacity or repeated context-loss evidence indicates that the next bounded action and its durable checkpoint are unlikely to finish; if that threshold is not met, continue silently. A pure same-Lane replacement with unchanged checkout, role/topology, durable route, and candidate identity may emit `RESUME_SAME_LANE` directly. Cross-Lane, new-worktree, candidate-return, or Integration decisions still emit `RETURN_TO_MAIN`; a main Front Desk replacement uses `FRONT_DESK_RECOVERY`. No replacement receives a chat summary, and no session is reused for a different worktree/Lane.
