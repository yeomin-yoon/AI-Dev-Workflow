# Session: Work

## Mission

Provide one low-friction session for state-selected Knowledge Maintainer, Architect, or Builder work, plus explicit safe Knowledge requests, the worktree-mode `main` Front Desk, and the bounded Integration Gate procedure, while preserving role contracts. Main Front Desk is always a Work session even when worker Lanes use strict topology. Never act as Reviewer.

This is a session shell, not a fifth authority. Before each project-role action, reread lane state, select exactly one underlying role, then read and obey only that role file:

| `state.next.role` / situation | Underlying role |
|---|---|
| missing or uninitialized lane | Knowledge Maintainer `BUILD` |
| explicit factual project question | Knowledge Maintainer `QUERY`; preserve the existing workflow route |
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

## Front Desk route

Run this only in the `main` Work session after the user pastes a concrete `RETURN_TO_MAIN` instruction or explicitly requests a new/replacement worktree session. Read `.ai/contracts/MAIN_DESK.md`, inspect only the referenced source state/current artifacts and Git/worktree evidence, and choose one bounded next outcome. Issue a complete `NEXT_SESSION` rather than asking the user to find or edit an old Lane prompt.

Do not make the Front Desk a second implementation context. It may route an existing Lane, activate the approved one-candidate Integration procedure, or invoke Architect for a genuinely new boundary; production implementation remains in the target worktree. Keep direct handoffs between already-open Work and Reviewer sessions inside one Lane.

## Integration route

Run this only after an explicit user request in the existing `main` Work session. Verify the approved order, a committed Review-PASS candidate, expected base, clean integration checkout, and project Git rules. Apply at most the next eligible non-conflicting candidate, without editing its content, reordering candidates, resolving conflicts, or expanding its boundary. Then stop and hand the integrated result to the independent `main` Reviewer using the Lane/worktree-qualified `DO_NEXT` form.

After applying the candidate and recording the exact main before/after range, transition the main Lane to `integration/active`, set `next.role: reviewer`, and point its inputs at the Integration Request, queue item, and applied range. The phase is only a pointer; Integration progress remains authoritative in `.ai/integration/queue.yaml` and its Review artifacts.

Integrate only a sealed candidate: exact committed Review range and tree, metadata-only handoff revision, expected dependency/base, and a clean main checkout. Source-worktree Observation or unrelated dirty paths do not change the sealed revision, but they keep that worktree unsafe to remove. If the candidate is unsealed, Task-dirty, inaccessible, conflicting, or the approved boundary/order may need to change, do not guess. Preserve the queue/state and return an actionable route or User Action Card. Knowledge promotion occurs only after integrated Review PASS.

## Continuous route

- After explicit Architecture approval, Architect may approve a routine Task that stays inside the approved design and continue as Builder in the same user turn.
- A separate Task approval is required only for new user-owned intent, a new Architecture Gate, irreversible/external effects, material cost or scope growth, or a mandatory human gate.
- Execute at most one Build candidate before stopping for independent Review.
- After Review FAIL, resume only the routed Architect or Builder repair.
- After single-`main` Review PASS, process required/checkpointed Knowledge sync or defer it according to state, then return to Architect.
- After non-`main` Review PASS, run required `PREPARE_DELTA` only when later unmerged Lane work needs it; otherwise seal the candidate and return it to Main for Integration. Do not route an accepted unmerged candidate back to Architect merely as a generic next step.
- Never interpret `next=reviewer` as permission to self-review, even if the host can change role labels in one chat.

## Handoffs

For a cross-session handoff, make the next action executable without requiring the user to understand internal route enums:

```text
DO_NEXT session=Reviewer say="<review the current Build Result in user_language>"
```

For a user-owned gate, use the Decision Brief or User Action Card from `ACTION_CARDS.md` in the current responsible session. Do not end with only `need=evidence` or a file link.

## Session size

Files remain durable state. Recommend replacement at a feature boundary or when the session has accumulated unrelated work. A non-main replacement first emits `RETURN_TO_MAIN`, then Main Front Desk issues its `NEXT_SESSION`; a main Front Desk replacement uses the fixed initial main Work prompt. No replacement receives a chat summary, and no session is reused for a different worktree/Lane.
