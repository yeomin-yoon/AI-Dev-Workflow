# Contract: Parallel Start Card

Read only when the user explicitly asks to split one project into concurrent worktree/lane streams or asks to reproduce their startup instructions. Ordinary single-lane work never reads or emits this contract.

## Authority and owner

Architect owns the partition decision. Approved `.ai/shared/SYSTEM_ARCHITECTURE.md`, lane Architecture/ownership, and Git are the durable sources; the card is a user-facing executable projection, not a new authority or session. After card issuance, `role=work, lane=main` is the Front Desk defined by `MAIN_DESK.md`. A strict main Architect may prepare the partition but never becomes the Front Desk or Integration executor.

The main session never messages, creates, or commands another chat. Unless the user explicitly asks for execution, it only prepares files and prints commands/prompts for the user to copy.

## Preconditions

Before a start card:

1. Confirm the requested streams are independently buildable/reviewable and their production `owned_paths` do not overlap.
2. Identify shared read-only paths, shared-contract owner, dependencies, integration order, expected session/checkpoint load, and whether an available main Front Desk can be recovered for returns and Integration. Treat tool/account availability and Front Desk handoff cost as real partition costs. If those costs or the shared surface are larger than the independent work, recommend sequential `main` work instead.
3. Present the normal Architecture Decision Brief and obtain approval.
4. Persist the approved partition in System Architecture and any already-existing affected lane Architecture/ownership. New Lane scaffolds are created later inside their own worktrees from this shared boundary.
5. Require one Git commit that contains `.ai`, canonical Knowledge needed by the lanes, and the approved partition. A worktree cannot inherit uncommitted chat/files.
6. Resolve the actual repository root, committed base revision, proposed branch names, and target paths. Read-only check that target branches/paths do not already conflict.
7. Use compact `Work + Reviewer` topology for new Lanes by default, even if the coordinating main session is strict. Use strict four-role topology only when the user explicitly requests it for those Lanes.
8. State that each non-`main` Builder creates one Task-scoped candidate commit before Review and the final Lane role creates one metadata-only handoff commit after PASS. These isolated commits are part of the approved worktree delivery flow; they never include unrelated changes.

Lane IDs use lower-case domain slugs such as `character` or `ui`, never provider/model/session names. Suggested branches use `feature/<lane>` unless project Git rules say otherwise. Suggested worktree directories are siblings named `<repo>-<lane>` unless the user supplied paths.

## Baseline not ready

If the approved partition is not in a commit, keep `state.next.role: architect` with `next.action: await_parallel_baseline_commit`. Do not call it an implementation blocker and do not emit commands that falsely claim a frozen base. Return:

```text
RESULT=parallel_baseline_needed
artifacts=<approved partition paths>
next=commit approved baseline, then reply in this Work/Architect session
```

Follow with a `USER_ACTION` in `user_language` containing:

- why every worktree must start from the same committed boundary;
- exact files/status the user should commit using their preferred Git UI or CLI;
- the observable clean/committed PASS condition;
- one copyable `user_language` reply meaning `parallel baseline committed`; and
- a fallback to remain on sequential `main` without losing work.

Do not require a particular commit command when the project may have unrelated user changes. Never stage or commit them implicitly.

## Parallel Start output

After verifying the committed base, return `RESULT=parallel_ready` and one self-contained card in `user_language`. Every value must be concrete and copyable; do not leave `<placeholders>`.

If the current coordinating session is not main Work, precede the Lane sections with:

```text
MAIN_FRONT_DESK
action=create_or_reuse
worktree=<absolute main worktree>
prompt=Read `.ai/BOOTSTRAP.md`. role=work, lane=main, session_mode=compact, user_language=<language>. Restore durable state from files and reply READY or BLOCKED.
first_request=<accept the approved parallel baseline and act as Main Front Desk>
```

The user keeps this main Work session available while worker sessions run.

```text
PARALLEL_START
base_revision=<full-or-unambiguous-commit>
run_from=<absolute repository root>
integration_order=<approved lane order>
rule=<one sentence: each lane edits only its approved ownership; main avoids overlapping writes>
git_delivery=<one Task candidate commit before Review; one Lane-metadata handoff commit after PASS>

LANE 1/<count>
lane=<domain slug>
topology=compact
purpose=<one sentence>
owned_paths=<project-relative paths>
shared_read_only=<paths|none>
branch=<branch>
worktree=<absolute target path>

WORKTREE_COMMAND
<host-appropriate, quoted git worktree add command pinned to base_revision>

WORK_PROMPT
Read `.ai/BOOTSTRAP.md`. role=work, lane=<lane>, session_mode=compact, user_language=<language>. If lane `<lane>` is missing, create it from `.ai/lanes/_template`. Initialize only if needed, restore durable state, and reply READY or BLOCKED.

REVIEWER_PROMPT
Read `.ai/BOOTSTRAP.md`. role=reviewer, lane=<lane>, session_mode=compact, user_language=<language>. Restore durable state from files and reply READY or BLOCKED.

FIRST_REQUEST
<exact short seed for this approved lane purpose>
FIRST_REQUEST_TARGET=Work

RETURN_COMMAND
<exact user_language instruction meaning: close this session and return it to main Front Desk>
```

Repeat the `LANE` section for every new worktree. For compact topology, tell the user to keep main Work Front Desk available, run `WORKTREE_COMMAND`, open that exact directory in the chosen AI tool, create a new Work session with `WORK_PROMPT`, wait for initialization/READY, create a new Reviewer session with `REVIEWER_PROMPT`, and send `FIRST_REQUEST` to Work. Never tell the user to paste a different Lane prompt into an existing `main` or other-Lane session. Tool/provider assignment is included only when the user supplied it; it never changes Lane identity.

For explicitly requested strict topology, set `topology=strict`, omit `WORK_PROMPT`, and provide all four concrete prompts instead:

```text
KNOWLEDGE_PROMPT
Read `.ai/BOOTSTRAP.md`. role=knowledge_maintainer, lane=<lane>, session_mode=strict, user_language=<language>. If lane `<lane>` is missing, create it from `.ai/lanes/_template`. Then, if it is uninitialized, complete BUILD; otherwise restore durable state without a broad scan. Preserve existing work and report the result.

ARCHITECT_PROMPT
Read `.ai/BOOTSTRAP.md`. role=architect, lane=<lane>, session_mode=strict, user_language=<language>. Restore durable state from files and reply READY or BLOCKED.

BUILDER_PROMPT
Read `.ai/BOOTSTRAP.md`. role=builder, lane=<lane>, session_mode=strict, user_language=<language>. Restore durable state from files and reply READY or BLOCKED.

REVIEWER_PROMPT
Read `.ai/BOOTSTRAP.md`. role=reviewer, lane=<lane>, session_mode=strict, user_language=<language>. Restore durable state from files and reply READY or BLOCKED.

FIRST_REQUEST
<exact short seed for this approved lane purpose>
FIRST_REQUEST_TARGET=Architect

RETURN_COMMAND
<exact user_language instruction meaning: close this session and return it to main Front Desk>
```

Tell the user to initialize Knowledge first, wait for completion, create the other three fixed-role sessions, and send `FIRST_REQUEST` to Architect.

If a branch/path already exists, do not print a knowingly failing command. Reuse it only after proving it is the intended clean worktree/branch; otherwise ask one narrow naming/path question or propose a non-conflicting concrete name.

## Reconstruction and safety

- On a request to show the Lane startup prompts again, regenerate the card from approved files plus current Git/worktree state; do not rely on old chat text.
- If a worktree already exists, report its actual path/branch and omit a duplicate creation command.
- A generated Lane prompt is bound to its exact Lane and worktree. Initial startup uses this card. Later non-main closure/replacement returns through `MAIN_DESK.md`, and the main Front Desk reissues an exact `NEXT_SESSION`; moving to another Lane/worktree always creates a new session.
- Initializing an additional lane reuses valid canonical Knowledge from the committed base and validates only its approved boundary. It does not rebuild or rewrite the entire shared index merely because the Lane is new.
- New lanes keep accepted but unmerged facts in lane `knowledge-delta`; canonical promotion happens only after integration.
- Integration reuses `integration_order`; request a new decision only if conflicts, shared-contract changes, added scope, or new evidence require it to change.
- When a non-`main` session closes or a sealed candidate reaches Review PASS, use the concrete `RETURN_TO_MAIN` card from `MAIN_DESK.md`. Its main-targeted instruction authorizes only the bounded next approved step; the user never interprets the order or targets a virtual Integration session.
- Card emission does not start implementation, create sessions, merge branches, or grant writes outside `owned_paths`.

## Post-integration continuation

This is the only exception to the new-boundary approval steps above. Use it when `MAIN_DESK.md` proves that one existing Lane will continue sequentially with unchanged purpose, ownership, shared contracts, and dependency order after its prior candidate was integrated and reviewed.

1. Pin `base_revision` to the current clean main `HEAD`, never the old worker Branch.
2. Keep the same Lane ID, but choose a new collision-free Branch and sibling worktree path. Never bind two active worktrees to the same Lane.
3. Emit the normal topology-appropriate `WORKTREE_COMMAND`, Work/Reviewer prompts, and first request. The Work first request is to perform targeted Knowledge/state validation against the new base, update `source_revision`, and then resume Architect for the next seed/approved slice.
4. Do not recreate the Lane scaffold, replay the completed Task, reuse the old Build/Review as a new candidate, or run broad Knowledge `BUILD`.
5. If purpose, ownership, shared contracts, or dependency order changed, stop this shortcut and use the normal Architect-owned parallel boundary flow.

Fresh continuation avoids duplicate diffs after merge/cherry-pick/squash and ensures the next candidate starts from integrated Knowledge and source.
