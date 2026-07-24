# Contract: Action Cards

Read only when a cross-role/session handoff or user-owned external/manual action is actually needed.

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
