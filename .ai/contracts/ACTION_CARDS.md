# Contract: Action Cards

Read only when return/orientation, a cross-role/session handoff, user-owned external/manual action, explicit developer-status request, or single-main commit checkpoint is actually needed.

## Working summary

When the user returns after unrelated work, asks what is happening, signals confusion, or several related clarification/choice turns have obscured the thread, reconstruct this compact view from lane state, current Architecture/Task/Build/Review pointers, and read-only Git evidence:

```text
WORKING_SUMMARY
goal=<plain user-visible outcome>
why=<problem or intent that started this work>
done=<only verified decisions/results>
current=<short user-language label (internal id) + phase>
open=<one unresolved decision/evidence|none>
terms=<only unfamiliar terms needed now as term: plain meaning|none>
next=<one bounded user-language action>
```

This is a chat-only projection, not a durable artifact, state field, handoff payload, or new approval Gate. Derive it again instead of copying an old chat summary. Keep it to one terminal screen, omit completed history that does not explain the current step, and never infer progress from a remembered conversation. A human-readable label precedes its internal ID; derive the label from the artifact heading/goal rather than adding a second durable name field. If a deeper explanation is useful, offer it after the one next action instead of expanding every prerequisite automatically.

## Developer Status

For an explicit request such as "show current development status", "show this Task's changes", or "is this ready to commit", read lane state, its current Task/Build/Review pointers, and read-only Git status/diff including untracked files. Return a compact terminal-safe projection in `user_language`; do not dump every path or raw hunk unless requested:

```text
DEV_STATUS
goal=<one current outcome>
phase=<phase> status=<status> task=<id|none>
changes=task:<count|unknown> workflow:<count|unknown> unrelated:<count|unknown> untracked:<count|unknown>
checks=<decisive pass/fail/pending evidence>
git=<clean|dirty|no-git> checkpoint=<not_ready|commit_ready|wip_only|not_applicable>
blocked=<short reason|none>
next=<one user-language action>
```

Derive classification from the Task, Build Result Changes/Baseline, Review identity, and Git. Never relabel an unattributed path merely to make the summary clean; report `unknown` and route attribution when needed. Summarize semantic effect before file order, group paths as production/tests/assets/workflow/unrelated, and use `git diff --stat` plus selected important hunks instead of an unbounded terminal dump.

## Single-main commit checkpoint

For a Git-backed ordinary single-`main` candidate, independent Review PASS is the default authorization for one exact local checkpoint when `.ai/shared/knowledge/project.yaml#interaction.checkpoint` is `auto_after_pass` or absent. This never authorizes Push, tag, history rewrite, merge/rebase, external effects, a different candidate, or unrelated/unknown paths.

After settling the required Knowledge route, reread status/diff, prove the accepted fingerprint and exact `include`/`exclude` attribution are unchanged, verify any commit hook/signing/credential behavior is already trusted and non-interactive, stage exactly `include`, inspect the staged diff and exclusions, create one local commit, and verify the commit contains no excluded path. Return `COMMIT_DONE task=<id> revision=<commit> next=<route>` with the semantic change summary and exclusions. If any proof fails, do not commit and return the owning blocker or actionable User Action Card.

Emit the following pre-commit choice only when `interaction.checkpoint: ask`, the user explicitly requests a pre-commit Diff, or safe automatic checkpoint preconditions cannot be established but a user choice can resolve them:

```text
COMMIT_READY
task=<task-id>
candidate=<review path + reviewed fingerprint>
include=<exact reviewed Task production/test paths, Task/Build/Review/state records, and required synchronized Knowledge paths>
exclude=<unrelated/pre-existing/unknown paths|none>
checks=<decisive evidence>
suggested_message=<project-style commit message>
reply=<two exact choices in user_language: commit_only | commit_and_one_next_routine_task>
next=<review the scoped diff, then choose one displayed reply or use the preferred Git UI>
```

Before another Task starts, the accepted single-main change must have a verified checkpoint commit when Git is usable. A failed or blocked Review may report `checkpoint=wip_only` in `DEV_STATUS` but never emits `COMMIT_READY` or becomes accepted evidence.

This is an operational Git checkpoint, not a second design approval Gate. The independent PASS and exact-scope proof authorize only the local checkpoint; the user controls the standing interaction preference and every remote or history-rewriting action. The include set never uses a broad directory, unrelated Workflow history, or `git add .`; omit synchronized Knowledge paths when the accepted route did not change them.

When `interaction.routine_continuation` is `one_task` or absent, a successful automatic or user-confirmed checkpoint continues through internal Architect to at most one next routine Task already covered by unchanged approved Architecture, then stops at independent Review. `stop` ends after the checkpoint. The canonical displayed replies for `ask` are descriptive: in Korean, render them as `커밋만` and `커밋 후 다음 Task 1개 진행`. A shorter natural-language alias is accepted only when it unambiguously selects one currently displayed choice; the displayed choice, never slang or an opaque token, defines the authorization boundary. Every route stops for a new Architecture Gate, unresolved user-owned intent, changed scope/evidence, manual gate, external effect, Push/tag, or another commit.

## Handoff

Tell the user exactly where to go and what to say:

```text
DO_NEXT session=<Work|Reviewer|Architect|Builder|Knowledge> say="<short copyable instruction>"
```

When more than one Lane is active or the target uses another checkout:

```text
DO_NEXT session=<session> lane=<lane> worktree=<absolute path> say="<short copyable instruction>"
```

In compact mode, Knowledge Maintainer/Architect/Builder routes target Work; Reviewer remains Reviewer. In strict mode, target the fixed role. Resolve the target path instead of asking the user to infer it from a Branch/Lane. Do not add `DO_NEXT` when the user can reply in the current session: a Decision Brief ends with its approval question and a User Action Card has its own reply.

## User Action

For a user-owned blocker or external/manual action, use `user_language`:

```text
USER_ACTION
why=<why available tools cannot complete this and why it matters>
steps=<short numbered procedure with exact app/path when relevant>
pass=<observable pass evidence>
reply=<copyable evidence template or decision options>
fallback=<safe alternative and consequence>
```

Do not return only `BLOCKED`, `owner=user`, `need=evidence`, or an artifact path. Answer follow-up questions in the same responsible session and resume when the requested evidence arrives.

## Editor/runtime check

When Reviewer needs an editor, runtime, device, visual, audio, accessibility, or other user-observed check, classify it before issuing the card:

- `observe_only`: the user performs and reports behavior without saving or otherwise changing candidate bytes.
- `candidate_mutating`: setup requires saving an asset/config/source or changing any Task-attributed candidate byte. Name every authorized path and expected mutation; if the path is outside Task scope/`allowed_write` or attribution is unknown, do not authorize it and route the owning `contract`/`context` issue.

Return an executable tutorial in `user_language`:

```text
EDITOR_CHECK
effect=<observe_only|candidate_mutating>
purpose=<what acceptance condition or risk this proves>
open=<exact app/project/map/asset/panel>
setup=<numbered preparation; include exact authorized save paths or none>
action=<numbered user actions>
observe=<where and what to watch>
pass=<concrete observable result>
fail=<concrete contrary result or anomaly>
reply=<copyable per-observation result template; include NOT_CHECKED and anomaly fields>
fallback=<safe alternative and consequence>
```

Never ask the user to infer controls, keys, asset locations, or the response format when project files can establish them. If a control cannot be established, explain the shortest way to find it. A generic "check it in the Editor" is incomplete.

When evidence returns, compare Git/candidate identity before consuming the observation. `observe_only` may resume the blocked Review only when candidate bytes are unchanged. Any `candidate_mutating` result invalidates the old Build/Review identity: preserve the user's observations as evidence, route a new Build attempt to reconcile every changed path and fingerprint, then perform a new Review. Do not promise that earlier AC evidence will be reused until the new attempt's impact check proves it remains applicable.
