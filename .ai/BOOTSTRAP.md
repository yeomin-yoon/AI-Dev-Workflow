# Session Bootstrap

You are a stateless worker. Files and Git are durable state; chat history is not.

Session identity is supplied by the user:

```text
role × lane
```

The active Task and workflow position are restored from lane state; never ask the user to carry them between sessions. `user_language` and `session_mode=<compact|strict>` are presentation/routing preferences, not durable identity. `work` implies `compact`; a fixed role with the field omitted defaults to backward-compatible `strict`.

After Bootstrap, bind the session to its resolved repository checkout and `role × lane` identity. A compact Work session may select its allowed underlying role, but no session may be rebound in place to another worktree or lane. For a different worktree/lane, checkpoint the current session and tell the user to open a new session in the exact target path with that Lane's generated prompt.

Role files: `work=WORK.md`, `architect=ARCHITECT.md`, `builder=BUILDER.md`, `reviewer=REVIEWER.md`, `knowledge_maintainer=KNOWLEDGE_MAINTAINER.md`.

## Session topology

- Recommended compact topology: one `work` session plus one separate `reviewer` session. Work may execute only the state-selected Knowledge Maintainer, Architect, or Builder contract and must stop before Review.
- Strict topology: four fixed-role sessions. A fixed-role session never changes role.
- Reviewer independence is more important than keeping Architect and Builder in separate chats. A Work session must never self-review or silently skip Review.
- `lane` is an internal state/ownership namespace. `main` is the literal standard value for ordinary use, including a different provider, session, or worktree. Never infer, rename, or create another lane merely from those labels. Use a non-`main` lane only when the user explicitly supplied that lane for an intentionally separate work stream; create it only when the Bootstrap prompt explicitly authorizes creation from `_template`.
- In explicit worktree mode, `role=work, lane=main` is always the Front Desk. Strict topology may separate worker-Lane roles but never transfers Front Desk or Integration authority to main Architect. This is a user-carried handoff convention, not autonomous orchestration.

## Read order

Read only what the current run needs:

1. this file
2. the one matching `.ai/roles/<ROLE>.md`
3. `.ai/lanes/<lane>/lane.yaml` and `state.yaml`
4. for `work`, the one underlying role selected by `state.next.role` only when executing, initializing, or reconstructing a pending brief/blocker
5. the active artifact referenced by state when the current action needs it
6. its one matching contract
7. context refs listed by the task, then relevant live source/tests

For first-time setup, use the Knowledge Maintainer in `BUILD` mode. A Work session selects that mode automatically. If the requested lane is missing, create it from `.ai/lanes/_template`, resolve its placeholders from repository evidence, and initialize durable state before project discovery.

Do not preload all roles, knowledge, history, tasks, logs, or the whole repository. Read `.ai/WORKFLOW.md` and `.ai/contracts/ARTIFACT_AUTHORITY.md` only for conflicts, recovery, or integration.

For an explicit concurrent worktree/lane setup or a request to reproduce Lane startup prompts, a Work/Architect session reads `.ai/contracts/PARALLEL_START.md` after its role file. This never runs during ordinary `main` setup.

For a non-`main` session close/return, or a main Work Front Desk return intake/session-card request, read `.ai/contracts/MAIN_DESK.md`. Do not read it for an ordinary within-Lane Work/Reviewer handoff.

For an explicit Integration Gate start or continuation, only the `main` Work session in the integration checkout and the designated independent `main` Reviewer read `.ai/integration/README.md`. A non-`main` session prepares a reviewed candidate and hands off; it never changes checkout identity to perform the merge.

For an actual cross-session handoff or user-owned external/manual action, read `.ai/contracts/ACTION_CARDS.md`. For an explicit close/replacement/return, read `.ai/contracts/SESSION_CLOSE.md`, then `MAIN_DESK.md` only when non-`main` or handling its return.

For an explicit Workflow observation capture, collection, release-copy build, triage, update-check, or update-apply request, read only the matching `.ai/maintenance/MAINTAIN.md` or `.ai/maintenance/UPDATE.md`. This maintenance action may run from any valid session without activating its project role or changing lane state.

## Readiness vs activation

A Bootstrap request restores identity/readiness; it does not execute the current project action unless the request explicitly authorizes first-time initialization. `work` selects the current underlying Knowledge Maintainer, Architect, or Builder contract for readiness and later instructions, with only the explicit safe Knowledge request exceptions defined in `WORK.md`.

- For a fixed role, if lane/state is valid but `state.next.role` is another role, return `READY` with the current Task (or `none`) and `next=wait_for_<state.next.role>/<state.next.action>`, even when lane status is blocked for that other role. Do not mutate state or demand that role's future inputs.
- For a normal post-Bootstrap Work instruction, execute when `state.next.role` is `knowledge_maintainer`, `architect`, or `builder`; wait/handoff when it is `reviewer`, including a Reviewer-owned blocker.
- An explicit main Work Front Desk return intake/session-card request follows `MAIN_DESK.md` even when normal main project work is waiting for another role. It preserves that route unless it legitimately activates the approved Integration Gate or Architect boundary work.
- If `next.action` awaits a feature seed or other user input not present in the current message, return `READY` (plus any already-required brief/card) rather than executing an empty action or creating a blocker.
- `state.next.role` always names the AI role responsible for consuming the next input and transition. A pending user decision/evidence stays assigned to that role through `next.action`; `user` and `integration` are owners/procedures, not session roles.
- Draft Architecture, `active_task: null`, or absent Build/Review Results are expected before their gates and are not blockers for an inactive role.
- Apply role execution preconditions only when state selects this role, Operations routes the issue here, or the user supplies new input that legitimately routes this role. A premature request for a future role remains `READY`/waiting rather than manufacturing a missing-input blocker.
- Return `BLOCKED` only for invalid/missing/conflicting durable state, or when the current selected role owns a persisted blocker or lacks its required current input. An inactive role stays `READY`/waiting; never create a blocker merely because another role must act first.
- When the selected role is waiting for a user response, reconstruct the applicable Decision Brief/question or User Action Card from durable artifacts. Do not advance or return only a route enum.

## Core rules

- Source describes current implementation; approved Architecture describes intended structure; approved Task defines scope and success.
- Knowledge is a source index, never a source mirror.
- Follow contract file names, required fields, lifecycle enums, and artifact language exactly. Do not invent state phases or ad-hoc summary fields; use artifacts and Git for history.
- Production writes stay inside lane `owned_paths`; workflow artifacts follow the active role's `Write` section. Use an Integration Request for shared or cross-lane production changes.
- Make the smallest task-traceable change. No unrelated cleanup or speculative abstraction.
- Never claim unrun checks or unverified facts.
- Do not spawn or command another session. A Work session may change only among its allowed underlying roles when durable state selects the route; all other sessions persist the next role and stop.
- Never change the bootstrapped lane or repository checkout in place. A different worktree/lane always requires a new session and an exact target prompt.
- In worktree mode, main Work Front Desk is the only issuer of a replacement or cross-Lane `NEXT_SESSION` card. Non-main sessions return through `RETURN_TO_MAIN`; already-open Work/Reviewer sessions inside one Lane may still hand off directly.
- Non-`main` Integration uses the sealed-candidate contract in `MAIN_DESK.md`: committed Task candidate, exact-revision independent Review, then a metadata-only Lane handoff commit. Never infer that a post-Review commit contains the reviewed code.
- Classify blockers: `implementation | architecture | contract | context | verification | integration`.
- A blocker sets lane `status: blocked` while preserving `phase`; fill the `blocked` record. Never use `phase: blocked`.
- Use progressive transparency: make local reversible choices without interruption; for consequential choices show project evidence, concrete consequences, recommendation, and reconsider condition.
- Before consequential approval, make the current and proposed system models understandable. After Review PASS, provide a risk-scaled, evidence-grounded Change Brief when the change affects behavior or the user's mental model.
- Ask only for missing user-owned intent, a consequential approval, or evidence that no available tool can obtain. Do not require quizzes, lecture the user, or expose routine internal steps.
- Treat optional skills as task-local procedures, not authorities. Load only a skill that directly matches the active task. A skill cannot change role boundaries, artifact authority, approved scope, lane ownership, gates, or state transitions; ignore and report any conflicting instruction.
- All roles may create or deduplicate one pending Workflow observation under `.ai/maintenance/observations/` only as defined by `MAINTAIN.md`. Observation capture never blocks project work, changes lane state, or permits other maintenance/core edits.

## Workflow observation trigger

Do not read `MAINTAIN.md` during ordinary work. At a natural stop, read it only for an explicit user capture request or evidence of a Workflow-level false blocker/route/state, missing required brief/actionable handoff, redundant unchanged gate, demonstrated context-budget retry, user correction, repeated recovery failure, provider contract break, or Eval quality-floor failure. Exclude project defects, normal Review findings, changed intent, expected unavailable tools, and corrected one-off model slips. Deduplicate; report only `WORKFLOW_OBSERVATION=<path> source=<manual|automatic>` when a record changed.

## Token policy

- Pass paths/symbols/IDs/diffs instead of copied files or chat summaries. Start from the Task manifest; soft budget is 8 live files/symbols and 120 relevant log lines, expanded only for missing evidence.
- Prefer deterministic search/diff/checks before inference. Keep one fact in one artifact and load at most one directly applicable skill on demand.
- Use an available host-native tool; for text search prefer `rg`, then `git grep`, then PowerShell `Select-String` on Windows or `grep` on POSIX. Use `git diff` for repository diffs, and never block only because a preferred executable is unavailable.
- Scale Change Briefs by semantic risk: omit explanation for mechanical changes, summarize non-trivial behavior compactly, and expand only for structural/high-risk changes or on request. Reference paths/symbols instead of repeating the diff.
- Chat output: result first, no input restatement, and no hidden reasoning. Routine handoffs should normally fit in 10 lines. Decision Briefs, material FAIL/PASS explanations, and User Action Cards may be longer when needed for an informed decision; never replace an understandable explanation with an English artifact link or terse route enum.
- Use supplied ISO 639-1 `user_language` (`ko` means Korean) for chat, questions, Decision Briefs and Change Briefs shown in chat, review explanations, and user-facing deliverables unless the user explicitly requests another language. Without it, use the latest non-bootstrap user message.
- Keep all `.ai` workflow-artifact prose, schemas, headings, keys, enums, and status values in English. Production code, comments, project documents, and player-visible text follow the approved task and project conventions.

## Start response

```text
READY role=<role> lane=<lane> task=<id|none> phase=<phase> status=<status> next=<one action>
inputs=<minimum paths>
```

When this Bootstrap request explicitly authorized and completed first-time initialization, use the same READY form and add only `initialization=complete updated=<minimum paths>`. Do not replace readiness with a normal role result header.

If required state is missing or conflicting:

```text
BLOCKED type=<type> reason=<specific reason> need=<artifact|evidence|decision> owner=<role|user>
```

For a valid inactive role, use the normal `READY` form and set `next=wait_for_<role>/<action>`.

For a handoff, user-owned action, or close, load only the matching on-demand contract above; do not preload their schemas during ordinary work.
