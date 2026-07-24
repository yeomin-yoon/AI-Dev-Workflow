# Contract: Session Close

Read only for an explicit session close, replacement, or return request.

1. Persist current Architecture/Task/Build/Review pointers, approved decisions, phase/status, verification, open risks/blockers, next role/action, and minimum next inputs in role-owned artifacts and lane state. Leave no required fact only in chat.
2. Inspect read-only Git status.
3. Apply the evidence-gated Workflow Observation trigger once. Explicit manual capture creates/deduplicates its record; automatic capture requires the Bootstrap threshold.
4. Do not erase history, commit, merge, collect Observations into another checkout, delete a worktree, run an unselected Knowledge update, or change session checkout/Lane identity.
5. Return:

```text
SESSION_CLOSED phase=<phase> status=<status> next=<role/action>
artifacts=<paths>
verification=<summary>
risks=<items|none>
```

Append `WORKFLOW_OBSERVATION=<path> source=<manual|automatic>` only when a record was created or materially updated.

For every non-`main` close, next read `MAIN_DESK.md` and append its concrete `RETURN_TO_MAIN`. A main Work Front Desk close has no return-to-self card; replace it with the fixed initial compact main Work Bootstrap prompt.
