# Contract: Session Close

Read only for an explicit session close, replacement, or return request, or when the Bootstrap viability check has evidence that the session should stop before its next substantial action.

## Replacement timing

Assess viability only at a natural boundary: after a durable handoff/checkpoint or before starting a new Architecture decision, Task/Build attempt, Review attempt, or Integration candidate. The question is whether this session can likely complete the next bounded action **and** persist its checkpoint, not how old the chat is.

- Treat a provider/tool capacity warning or visible remaining context/quota as the strongest timing evidence. Quote an exact amount only when the provider exposes it; never infer or fabricate one.
- Without a meter, require repeated observable degradation after targeted restoration, such as losing facts already reread from durable state, confusing the persisted route or candidate identity, or repeatedly reopening broad context that the current pointers should bound. One corrected mistake, a long transcript, or turn count alone is not enough.
- If the next action and checkpoint remain likely achievable, continue silently. Do not ask a ceremonial replacement question or report session health every turn.
- If they are likely not achievable, do not start the next substantial action. Persist the current safe boundary using this contract and emit the applicable `RESUME_SAME_LANE`, `RETURN_TO_MAIN`, or `FRONT_DESK_RECOVERY` route.
- If risk becomes clear during an action, stop at the nearest safe durable boundary without claiming completion, preserve the in-progress phase/evidence honestly, and replace before further substantive work. Never trade candidate identity or verification integrity for squeezing in one more step.

1. Persist current Architecture/Task/Build/Review pointers, phase/status, blocker, next role/action, and minimum next inputs in lane state. Persist approved decisions, verification, and open risks only in their owning Architecture/Task/Build/Review artifacts; state points to those artifacts instead of copying their prose. Leave no required fact only in chat.
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

For a pure replacement in the same absolute checkout and Lane, emit the following only when the requested session role/topology, durable route, and active candidate identity are unchanged, no candidate is being returned, and no Front Desk/Integration decision is pending:

```text
RESULT=same_lane_resume
RESUME_SAME_LANE
lane=<lane>
worktree=<absolute path>
session=<Work|Reviewer|Architect|Builder|Knowledge>
topology=<compact|strict>
prompt=<exact Bootstrap prompt for the same identity>
first_request=<restore the current route from state/artifacts/Git and report READY or the persisted blocker>
```

The replacement receives no chat summary and revalidates state, current artifact pointers, and Git before acting. A role, topology, candidate, Lane, checkout, new-worktree, Integration, or return-intent change is not a same-Lane replacement.

For every other non-`main` close, next read `MAIN_DESK.md` and append its concrete `RETURN_TO_MAIN`. A main Work Front Desk close reads `MAIN_DESK.md#front-desk-recovery` and emits its recovery card instead of returning to itself.
