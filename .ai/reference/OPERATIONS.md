# Operations Reference

Read only for exceptions, integration, recovery, or session replacement.

## Normal route

```text
seed → Architect → approved architecture/task → Builder
→ build result → Reviewer
  ├─ FAIL/BLOCKED → resolved issue owner
  └─ PASS → accepted change
       ├─ Knowledge required/checkpoint → Knowledge Maintainer
       ├─ Git-backed single-main → Work policy checkpoint (`COMMIT_READY` only for `ask`) → Architect/next Task
       ├─ single-main no-Git → Architect/next Task with disclosed assurance
       └─ non-main → optional PREPARE_DELTA when required → Integration
            → main Reviewer → canonical Knowledge checkpoint when required
```

Knowledge is not an unconditional PASS handoff. Reviewer owns `required | defer | none`; Lane topology and pending checkpoints determine the concrete next role/procedure. `.ai/roles/REVIEWER.md` defines the classification criteria, while this route is the authoritative role/procedure outcome.

## Issue route

This is the single authoritative issue-routing table.

| Type | Owner |
|---|---|
| `implementation` | Builder |
| `architecture` | Architect |
| `contract` | owning artifact/contract role; Architect + user only for approved requirement or public-boundary changes |
| `context` | Knowledge Maintainer for stale discovery; otherwise the role/user owning the missing authoritative input |
| `verification` | Reviewer + user when needed; Builder supplies available evidence |
| `integration` | user-coordinated Integration Gate |

Repair only the responsible artifact; do not restart the whole workflow.

## Bounded diagnosis during active delivery

Use this before a cause, user choice, manual evidence request, new Task, or broader investigation can change an active delivery route:

1. Reconstruct the delivery anchor from the current Task's exact observable ACs, applicable approved Architecture/requirement sections, and latest explicit user intent. State the intended observable behavior before technical hypotheses. Do not ask the user to choose an outcome that this evidence already determines.
2. Label each claim `observed | inferred | confirmed`. `Observed` is direct source/runtime/diff evidence. `Inferred` is a plausible explanation with named uncertainty. `Confirmed` requires a discriminating check that rules out every materially viable competing cause. Use phrases such as `root cause confirmed` only for `confirmed` evidence, and correct an earlier inference explicitly when evidence disproves it.
3. Classify each discovery against that same delivery anchor:

| Promotion | Meaning and route |
|---|---|
| `current_blocker` | Direct evidence shows a mandatory AC fails, the candidate caused a regression, approved scope/boundary is invalid, candidate identity or required verification is untrustworthy, or a high-severity safety/loss/external-effect risk makes continuation unsafe. Route the owning repair now. |
| `follow_up` | The issue is evidenced but the active candidate can still be completed and truthfully accepted without hiding material risk. Keep it after the current result in an existing Residual Risk/owned artifact only when future work needs it; do not create a Task, Gate, handoff, or broader Review now. |
| `not_actionable` | Preference, speculation, duplicate evidence, or consequence-free cleanup. Do not persist or route it as work. |

4. Build one bounded evidence batch before requesting user help. Use source and deterministic tools first. When an editor, device, binary asset, or experiential behavior is unavailable, ask for the smallest user action that distinguishes the remaining hypotheses and batch observations available in the same app/surface. Do not drip-feed avoidable one-field questions or repeat evidence already supplied.
5. After each repair or observation, reclassify any new discovery against the same anchor and return to the bounded candidate unless it is a `current_blocker`. A discovery being real does not authorize recursive investigation, Task creation, or a changed product outcome.
6. Record durable truth at the right confidence. Architecture, Task, state, and Knowledge contain only confirmed/approved facts. Build/Review evidence may retain `observed` facts and explicitly `inferred` hypotheses while an attempt is open, but must correct disproved hypotheses and never present them as authoritative truth or PASS evidence.

Only `current_blocker` enters the Exception procedure below. Never downgrade a blocker for momentum; if the available evidence cannot safely distinguish blocker from follow-up, run one bounded probe or use the existing `context`/`verification` route.

## Cross-lane and integration

- Production writes stay inside lane `owned_paths`; role-owned workflow artifacts stay in their declared `.ai` paths.
- Request shared/other-lane changes through `.ai/integration/requests/`.
- Run parallel Builders only in isolated worktrees.
- The user approved the dependency-safe order with the parallel boundary; do not ask again unless conflicts, shared contracts, scope, or evidence change it.
- After a non-main Lane closes, the user pastes its `RETURN_TO_MAIN` instruction into main Work Front Desk. A sealed return authorizes at most the exact next `handoff_revision` and stops for a designated independent `main` Reviewer.
- Main records the exact before/after range and merge strategy. Reviewer verifies that range, the reviewed candidate identity/tree, post-review Lane-handoff-only paths, and affected contracts; Knowledge Maintainer syncs only after that verification.
- Run relevant checks after each merge, then full integration checks.
- Validate architecture drift and promote verified knowledge deltas last.

Integration Gate is this procedure, not another role/session. A non-`main` session never rebinds itself to the main checkout. No session merges without explicit user instruction, starts another session, or messages another session automatically.

## Exception procedure

1. Read only current lane state, active artifacts, relevant diff, and minimum evidence.
2. Classify the issue as `implementation | architecture | contract | context | verification | integration`.
3. Resolve only when the active role owns the repair. Otherwise persist a route to the responsible AI role; record the user only as blocker owner when its decision/evidence is required.
4. After repair, use the explicit pre-Build/Build, architecture/contract/context/user-verification, or Integration resume transition in `.ai/contracts/STATE.md`; never reuse a stale Review/range verdict or leave `ready_to_build/blocked`, `building/blocked`, `reviewing/blocked`, or `integration/blocked` without a return path.
5. Record cause, evidence, changed artifacts, verification, residual risk, next role/action, and minimum input paths only in an artifact the active role may write and in state. Never edit another role's artifact.
6. Return exactly one outcome: `resolved`, `routed`, or `blocked`. Do not restart the whole workflow or cross role boundaries.

```text
OUTCOME=<resolved|routed|blocked> type=<type> owner=<role|user>
evidence=<minimum paths> changed=<paths|none>
next=<role/action> inputs=<minimum paths|none>
```

If `owner=user`, immediately follow the outcome with the `ACTION_CARDS.md` User Action Card. State why tools cannot obtain the evidence, give exact app/path/steps and observable PASS/FAIL, provide a copyable reply, and name the safe fallback/consequence. A route such as `provide manual runtime evidence` is incomplete by itself.

Keep `state.next.role` as the AI role that will consume the reply. Do not store `user` or `integration` as a role, and do not add a redundant cross-session handoff when the user replies in the current responsible session.

Known Task-scoped user/editor authoring that saves candidate bytes is implementation: Builder batches it before final verification and Review, keeps the same active Build attempt, and reconciles every authorized save. For unavailable observation-only verification after implementation is complete, route the Build candidate to Reviewer. Reviewer evaluates available evidence and owns that observation gate; do not repeatedly send the user back to Builder merely to explain the check. A newly discovered candidate-mutating action after handoff invalidates candidate identity and routes a fresh Build/Review attempt, while unowned/unknown mutation remains blocked for attribution.

## Direct edits or external merges

```text
diff → Knowledge UPDATE → architecture-drift check
→ affected lane source_revision/state update
```

If structure changed, Architect resolves intended architecture before Knowledge becomes canonical.

## Session replacement

Before closing, persist decisions, artifact paths, verification, risks/blockers, next role/action, and minimum next inputs; inspect read-only Git status. Do not treat close as a Git commit, merge, observation capture/collection, worktree deletion, or unselected Knowledge update. Never pass a chat summary.

A pure same-Lane replacement with unchanged absolute checkout, Lane, role/topology, durable route, and candidate identity emits `RESUME_SAME_LANE` directly from `.ai/contracts/SESSION_CLOSE.md`. Every cross-Lane, new-worktree, candidate-return, or Integration-sensitive non-`main` close emits `RETURN_TO_MAIN`; the user pastes its single instruction into main Work Front Desk, which verifies the referenced files/Git and issues any `NEXT_SESSION`. Do not make the user retain or edit old Lane prompts. A main Front Desk replacement uses `FRONT_DESK_RECOVERY` and verifies main Git/queue state before acting.

If durable state is missing, report:

```text
BLOCKED type=context reason=missing_durable_state need=<artifact> owner=<role|user>
```

Changing the tool or model does not change durable state. Main Front Desk may carry the prior card's non-authoritative topology/language/tool preference into a new session; if absent, it defaults to compact topology and the current user language. Changing to a different worktree or Lane changes session identity: use the concrete `NEXT_SESSION` instead of rebinding the old session.
