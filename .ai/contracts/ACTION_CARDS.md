# Contract: Action Cards

Read only when return/orientation, a cross-role/session handoff, user-owned external/manual action, explicit developer-status or source-inspection request, post-PASS code walkthrough, or single-main commit checkpoint is actually needed.

## Scan-first composition

This section owns the first visible user-facing composition for the cards below and for Architect/Builder/Reviewer result explanations. Compose rather than stack: when a result header, Change Brief, source walkthrough, expert note, risk, or handoff would repeat the same fact, say it once in the earliest useful field and omit the duplicate.

The first visible block must let a busy reader locate, without parsing internal history: `result/observable consequence`, `why it matters now`, `responsibility/runtime or data flow`, `exact current source anchor when known`, `decisive evidence or uncertainty`, and `one next action or real user decision`. Put full inventories, commands, logs, research trails, internal IDs, and secondary risks afterward or behind exact pointers. This is a comprehension criterion, not an arbitrary seconds, line, terminal-screen, or anchor-count limit.

When several technical upkeep findings appear, do not hand the user an undifferentiated "handle these?" list. Classify each as `current_blocker | after_current_work | optional` and `deterministic_ai_owned | user_owned`, lead with the current deliverable and its actual blocker, and place safe deterministic cleanup in the owning existing route. A user choice exists only when observable scope, compatibility, cost/risk, or another user-owned outcome genuinely differs. Name scope, rollback, and decisive proof for any upkeep action that is proposed; revision/index repinning follows reviewed content instead of competing with it as a choice.

Keep one semantic thread across roles: Architecture's observable intent and planned responsibility/flow become Builder's exact source symbols and then Reviewer's verified Diff/source path. Source corrects the plan when they disagree. The base fields never disappear because a user seems experienced; definitions, examples, alternatives, and theory expand only for first-use unfamiliar terms, a confusion signal, material risk, or a request. AI assistance and delivery pace do not taper, and no explanation creates a quiz, score, mandatory reply, or new Gate.

## Working summary

When the user returns after unrelated work, asks what is happening, signals confusion, or several related clarification/choice turns have obscured the thread, reconstruct this compact view from lane state, current Architecture/Task/Build/Review pointers, and read-only Git evidence:

```text
WORKING_SUMMARY
goal=<plain user-visible outcome>
why=<problem or intent that started this work>
done=<only verified decisions/results>
current=<short user-language label (internal id) + phase>
open=<one current blocker/decision/evidence|none>
terms=<only unfamiliar terms needed now as term: plain meaning|none>
next=<one bounded user-language action>
```

This is a chat-only projection, not a durable artifact, state field, handoff payload, or new approval Gate. Derive it again instead of copying an old chat summary. Apply `Scan-first composition`, omit completed history that does not explain the current step, and never infer progress from a remembered conversation. `open` contains only a current blocker or user-owned decision/evidence; non-blocking follow-up never displaces the active outcome. A human-readable label precedes its internal ID; derive the label from the artifact heading/goal rather than adding a second durable name field. If a deeper explanation is useful, offer it after the one next action instead of expanding every prerequisite automatically.

## Developer Status

For an explicit request such as "show current development status", "show this Task's changes", or "is this ready to commit", read lane state, its current Task/Build/Review pointers, and read-only Git status/diff including untracked files. Return a compact terminal-safe projection in `user_language`; do not dump every path or raw hunk unless requested:

```text
DEV_STATUS
goal=<one current outcome>
phase=<phase> status=<status> task=<id|none>
changes=task:<count|unknown> workflow:<count|unknown> unrelated:<count|unknown> untracked:<count|unknown>
checks=<decisive pass/fail/pending evidence>
git=<clean|dirty|no-git> checkpoint=<not_ready|commit_ready|content_committed_repin_pending|wip_only|not_applicable>
blocked=<short reason|none>
next=<one user-language action>
```

Derive classification from the Task, Build Result Changes/Baseline, Review identity, and Git. `blocked` reports only an `OPERATIONS.md#bounded-diagnosis-during-active-delivery` `current_blocker`; `follow_up` and `not_actionable` never make status look blocked. Use `content_committed_repin_pending` only when the reviewed content commit exists but the required single-main revision-repin closure has not yet updated and committed its role-owned state/Knowledge pins; name that deterministic next action instead of calling the content uncommitted. Never relabel an unattributed path merely to make the summary clean; report `unknown` and route attribution when needed. Summarize semantic effect before file order, group paths as production/tests/assets/workflow/unrelated, and use `git diff --stat` plus selected important hunks instead of an unbounded terminal dump.

## Readable atomic decisions

Use this rendering rule for every user-owned Decision Brief, checkpoint choice, or non-evidence User Action choice. If only one materially safe path remains, do not emit a choice: execute it when authorized or report the predetermined action and consequence. If two or three genuinely viable outcomes remain, apply `Scan-first composition` and show the recommendation and every viable alternative together. If four or more genuinely viable user-owned outcomes remain, never omit one or break the three-choice cap: first ask one bounded discriminator using at most three mutually exclusive, collectively exhaustive groups, list every included semantic outcome under its group in `groups`, then show every viable outcome in the selected group; repeat only when that group still exceeds three. Group only when no semantic outcome is lost, and exclude an outcome only with evidence that it is not currently viable. A general decision begins directly with `DECISION`; it does not receive the intent-gap preface unless an applicable request or approved planning source is incomplete.

```text
DECISION
question=<one user-owned outcome in plain language>
recommend=<semantic choice> — <why it best fits current evidence>
choices=
- <semantic choice> — <observable result>; tradeoff=<actual cost or limitation>
- <semantic choice> — <observable result>; tradeoff=<actual cost or limitation>
groups=<none|up to three discriminator groups, each followed by every included semantic outcome>
remote_effect=<none|exact external/history effect>
details=<artifact path or scoped inspection command|none>
reply=<repeat the semantic choices in user_language; free-form questions remain valid>
```

Each choice authorizes one atomic user-owned action. Do not use an opaque `1`, `A`, Task ID, or internal enum as the durable meaning of a reply; a short alias is accepted only after an atomic readable choice is displayed, and record the semantic choice. Do not combine required checkpoint closure with optional next-Task continuation, or combine commit, Push, merge, cleanup, and new work into one option. Required deterministic bookkeeping, exact metadata repinning, and role-owned repair are not choices and proceed without another confirmation when their existing authority and scope are proven. An unsafe, unverifiable, or never-tested intermediate state is a blocker or a `reverify` action, not a selectable commit strategy. Put exact path inventories, long check lists, internal IDs, and historical narrative in `details`; the first screen leads with outcome, reason, tradeoff, and one reply. Prefer short bullets over a wide CLI table.

A concise assent to one decision-ready semantic outcome remains valid; being short or repeated does not by itself make the reply uninformed. An explicit surrender signal never becomes product authority: confusion, inability to compare, disengagement, or "I do not know, just decide" is not durable approval of a user-owned outcome. Re-run the owning role's `gate necessity`, `needed now`, and `decision readiness`: decide and explain an AI-owned reversible implementation detail, defer a choice that the current bounded deliverable does not need, simplify or investigate a necessary product choice, and block only for materially unresolved user-owned intent. Explicit delegation applies only to AI-owned reversible implementation detail and never transfers product authority.

### Intent-gap preface

When a request or approved planning source is incomplete, open its Decision Brief with these five user-language lines before the `DECISION` block, technical options, or internal history:

```text
current_behavior=<what the user/system does now + strongest evidence>
intended_behavior=<what the exact approved request/spec section actually requires>
confirmed_gap=<the missing or conflicting observable behavior>
ai_direction=<the internal implementation direction project evidence already determines>
user_decision=<the remaining user-visible/product behavior the user can truly choose|none>
```

Classify each relevant gap as `specified`, `implementation_open`, `product_open`, or `authority_unknown`. `specified` behavior is preserved as intent; `implementation_open` is an AI-owned reversible technical choice and is explained without a Gate; `product_open` is the only planning absence that becomes a user decision; `authority_unknown` uses the existing `context`/`contract` blocker. Never treat silence in a planning document as approval for new user-visible behavior. Put exact requirement path/section/revision and runtime/source evidence in `details`, but state their plain meaning in the first screen. A rejected or previously failed approach belongs under evidence/rejected direction, not under `choices`.

## Bounded expert note

This is optional depth integrated into an existing Architect or Reviewer scan-first view, not another stacked chat section, durable artifact, role, session, Gate, quiz, or correctness condition. The core problem, direction/accepted result, and next action always remain easy to locate. Add a note only when it provides a non-obvious reusable engineering principle, names a material failure mode, or helps the user find and maintain the relevant code. Prefer one useful idea; add more only when the current high-risk explanation genuinely needs them. Omit mechanical, repeated, speculative, and unrelated knowledge.

Render in `user_language` with short labels equivalent to:

```text
Expert note - one useful idea for this change
plain=<behavior-linked meaning without prerequisite jargon>
term=<precise professional term|none>
code=<exact current path/symbol/evidence anchor>
reuse=<one criterion the user can apply next time>
deeper=<available on request|none>
```

Define the meaning before the term. Do not turn the note into a history lecture, option dump, external-study prerequisite, scope addition, Review finding, or mandatory reply. When the user says the explanation is unclear or tiring, remove detail and restate the core before offering further expertise.

## Code walkthrough

After every PASS, keep the exact reviewed Diff directly inspectable. A purely mechanical or non-code change may use one compact scoped Diff reference. A non-trivial change to hand-written production source must also produce this chat-only walkthrough from the approved intent, the Builder-owned Source Map after Reviewer validation, the exact reviewed candidate/range, and source/tests—not from remembered chat:

```text
CODE_WALKTHROUGH
result=<PASS + observable accepted result>
change=<plain outcome + semantic label before internal Task id>
snapshot=<base..reviewed revision | base revision + reviewed fingerprint | no-git/unsealed + reviewed changed-file manifest>
diff=<exact per-file git diff/show command or preferred Git UI range | no-git direct R# path+symbol open sequence>
new_files=<primary-read paths that must be opened as whole files|none>
primary_read=
R1. <path>#<symbol> — <what this code owns> — <what to follow here>
full_map=<Build Result#changes + #source-map, validated by Review Result>
flow=<entry -> important decision/state -> observable effect>
invariants=<what must remain true and where it is enforced>
tests=<test path/case -> what it proves and does not prove>
next=<one existing route/action; inspection reply only when the configured pause applies>
reply=<descriptive user_language choices meaning "I inspected the primary reviewed source path; continue the existing route" or "explain R#/path/symbol", plus free-form questions>
```

The Build Result `Changes` and `Source Map` are the one cumulative revision-scoped inventory: every Task-touched hand-written production source path has a key symbol, plain-language role, and Task reason there; generated/vendor/mechanical paths are grouped, and new source files are marked for whole-file reading. Reviewer independently validates that map against the exact candidate and records its pointer plus corrections instead of copying it. The chat walkthrough selects the smallest connected source path that explains entry, responsibility/decision or state, and observable effect, then points to the complete map. It may be short or longer according to the actual flow, never an arbitrary anchor quota. Mark unchanged context as `context`, never as part of the Diff.

Make direct inspection practical rather than dumping code: for Git-backed work, start with `--stat`, then provide the connected primary file/symbol path in runtime order and the corresponding scoped `git diff`/`git show` command or Git UI range. For a supported no-Git Review, write `snapshot=no-git/unsealed`, use the reconciled Build/Review changed-file manifest as the bounded reviewed set, and provide the exact `R#` path+symbol open sequence instead of inventing a revision, Diff command, or sealed identity. Keep its reduced attribution assurance visible. A summary, raw directory list, Review link, or selected hunk alone never substitutes for opening the actual changed source. Keep the first pass to the primary path; answer numbered or free-form follow-ups from the same reviewed snapshot and expand only the requested file, symbol, flow, complete-map entry, or prerequisite term.

This is not a quiz, correctness approval, or claim that the user permanently understands the code. Read-only inspection does not change the candidate. If the user edits or saves any candidate byte while inspecting, apply the candidate-mutation Build/Review rule before reusing PASS.

Use `R#` only for the visible primary read; a follow-up such as `explain 2` without that namespace is not a deterministic reference. Complete-map follow-ups use an exact path/symbol. Render reply choices as descriptive sentences in `user_language`, for example `핵심 검토 소스를 확인했어. 기존 경로로 계속해.` or `R2 파일을 더 설명해줘.` Internal enums may be stored in state/result fields but never replace the displayed meaning.

This pause applies only to an ordinary Task Review whose Git tree or canonical working-tree fingerprint can be revalidated, whether the Task is on `main` or a non-`main` Lane. A no-Git/unsealed Task Review always sets `code_inspection=shown_no_pause` after showing the walkthrough, even when the project preference says `before_next_task`; without a durable identity it must not enter or repeat an inspection wait. Integration Review always sets `code_inspection=not_applicable` and follows the exact Integration range/queue route without creating this user wait; its already reviewed Lane source is not presented as a new Task walkthrough.

When an identity-revalidatable ordinary Task PASS includes a non-trivial hand-written production source change and `interaction.code_inspection` is `before_next_task`, set `code_inspection=awaiting_user`, transition through the durable `STATE.md` code-inspection wait, show the walkthrough, and wait in the current Reviewer session before delivering `DO_NEXT` or automatically starting Knowledge/Work continuation. Questions keep that same wait. After the descriptive inspected/continue reply, revalidate candidate identity and apply the already-recorded Review route without asking for approval again. `no_pause` or no-Git/unsealed sets `shown_no_pause`, still shows the walkthrough, and permits the normal route. A `fail`/`blocked` verdict or a purely mechanical/non-code PASS sets `not_applicable`; it may show one compact scoped Diff reference but never creates a code-inspection wait. Missing historical preferences read as `no_pause` for backward compatibility.

## Single-main commit checkpoint

For a Git-backed ordinary single-`main` candidate, independent Review PASS is the default authorization for one exact local logical checkpoint when `.ai/shared/knowledge/project.yaml#interaction.checkpoint` is `auto_after_pass` or absent. This never authorizes Push, tag, history rewrite, merge/rebase, external effects, a different candidate, or unrelated/unknown paths.

After settling the required Knowledge route, reread status/diff, prove the accepted fingerprint and exact `include`/`exclude` attribution are unchanged, verify any commit hook/signing/credential behavior is already trusted and non-interactive, append the single accepted-Task line defined in `.ai/contracts/STATE.md#run-ledger` with `closure: main_checkpoint` and add that one path to `include` as role-owned Task-closure evidence, stage exactly `include`, inspect the staged diff and exclusions, create the reviewed content commit, and verify it contains no excluded path. If commit-backed state or Knowledge cannot name that new revision until it exists, immediately repin only the role-owned state/Knowledge metadata to the content revision, verify the revision-repin-only diff, and create at most one single-main revision-repin closure commit. This deterministic repin is part of the same logical checkpoint, not a second choice or permission to change source/tests/assets. Return `COMMIT_DONE task=<id> content_revision=<commit> metadata_revision=<commit|none> next=<route>` with the semantic change summary and exclusions. If any proof fails, do not guess, widen scope, or start the next Task; remove the ledger line this attempt appended so a retry appends exactly one, then return the owning blocker or actionable User Action Card.

That ledger line is a silent projection of artifacts that already exist: it never appears in `COMMIT_DONE`, never becomes a choice, blocker, or Review finding, and a failed append never blocks the route or the next Task.

Emit the following pre-commit choice only when `interaction.checkpoint: ask`, the user explicitly requests a pre-commit Diff, or safe automatic checkpoint preconditions cannot be established but a user choice can resolve them:

```text
COMMIT_READY
decision=<plain semantic checkpoint outcome; internal Task id is secondary>
recommend=<semantic choice + one-sentence reason>
choices=<all currently viable atomic choices, including stop/defer when real; at most three>
scope=<plain production/test/asset/workflow summary>
after_checkpoint=<current standing continuation preference; informational, not bundled authorization>
remote_effect=none
details=<Review/Build evidence path + exact scoped diff command + exact include/exclude inventory>
reply=<descriptive semantic choices in user_language>
```

Before another Task starts, the accepted single-main change must have a verified logical checkpoint when Git is usable, including any required single-main revision-repin closure. A failed or blocked Review may report `checkpoint=wip_only` in `DEV_STATUS` but never emits `COMMIT_READY` or becomes accepted evidence.

This is an operational Git checkpoint, not a second design approval Gate. The independent PASS and exact-scope proof authorize only the local logical checkpoint; the user controls the standing interaction preference and every remote or history-rewriting action. The include set never uses a broad directory, unrelated Workflow history, or `git add .`; omit synchronized Knowledge paths when the accepted route did not change them. A content commit plus its required single-main revision-repin closure is reported as one checkpoint with two revision fields, not disguised as a promised single Git commit.

When `interaction.routine_continuation` is `one_task` or absent, a successful automatic or user-confirmed checkpoint continues through internal Architect to at most one next routine Task already covered by unchanged approved Architecture, then stops at independent Review. `stop` ends after the checkpoint. `COMMIT_READY` asks only about the checkpoint; it displays the already-recorded continuation preference but never offers compound `commit and continue` choices. If the user explicitly wants to change continuation, settle that as a separate standing preference before or after checkpoint closure. Canonical replies are descriptive semantic actions such as `검토된 변경을 로컬 체크포인트로 남겨줘` or `지금은 커밋하지 말고 멈춰줘`; the displayed semantic choice, never slang or an opaque token, defines the authorization boundary. Every route stops for a new Architecture Gate, unresolved user-owned intent, changed scope/evidence, manual gate, external effect, Push/tag, or another content checkpoint.

## Handoff

Tell the user exactly where to go and what to say:

```text
DO_NEXT session=<Work|Reviewer|Architect|Builder|Knowledge> say="<short copyable instruction>"
```

When more than one Lane is active or the target uses another checkout:

```text
DO_NEXT session=<session> lane=<lane> worktree=<absolute path> say="<short copyable instruction>"
```

In compact mode, Knowledge Maintainer/Architect/Builder routes target Work; Reviewer remains Reviewer. In strict mode, target the fixed role. Resolve the target path instead of asking the user to infer it from a Branch/Lane. Do not add `DO_NEXT` when the user can reply in the current session: a Decision Brief ends with its approval question, a User Action Card has its own reply, and a `CODE_WALKTHROUGH` with `code_inspection=awaiting_user` stays in Reviewer until the descriptive inspected/continue reply.

## User Action

For a user-owned blocker or external/manual action, use `user_language`:

```text
USER_ACTION
do_now=<one plain action sentence; include save/do-not-save when relevant>
why=<why available tools cannot complete this and why it matters>
flow=<for graph/state/lifecycle/data-flow authoring: plain before -> this step -> resulting behavior|none>
terms=<only first-use visible labels needed in the steps: label = plain behavioral meaning|none>
steps=<short numbered procedure with exact app/path when relevant>
pass=<observable pass evidence; for authoring include the exact finished surface/shape before save or report>
reply=<copyable evidence template or decision options>
fallback=<safe alternative and consequence>
```

Lead with `do_now`, then the plain consequence, and put test counts, internal IDs, logs, and technical history after the action. Do not return only `BLOCKED`, `owner=user`, `need=evidence`, or an artifact path. Answer follow-up questions in the same responsible session and resume when the requested evidence arrives.

`fallback` defaults to stopping without changing candidate bytes. Never describe a new save, configuration edit, or source/asset mutation as a safe way to stop. If the only meaningful fallback changes the candidate, label it `candidate_mutating` and name the exact authorized paths/consequence. During active Build disclose same-attempt reconciliation and final verification; after handoff disclose that a fresh Build/Review identity will be required.

## Editor/runtime check

When Builder needs approved user-authored candidate bytes, or Reviewer needs an editor, runtime, device, visual, audio, accessibility, or other user-observed check, classify it before issuing the card:

- `observe_only`: the user performs and reports behavior without saving or otherwise changing candidate bytes.
- `candidate_mutating`: setup requires saving an asset/config/source or changing any Task-attributed candidate byte. Name every authorized path and expected mutation; if the path is outside Task scope/`allowed_write` or attribution is unknown, do not authorize it and route the owning `contract`/`context` issue. When this is known implementation work before a final Build candidate, Builder batches it under `building/active + await_user_build_authoring` and resumes the same attempt. Once a Build candidate is handed off or Review has started, the mutation invalidates that candidate identity and requires the fresh Build/Review route below.

Return an executable tutorial in `user_language`:

```text
EDITOR_CHECK
effect=<observe_only|candidate_mutating>
do_now=<one plain action sentence + explicit save/do-not-save instruction>
purpose=<what acceptance condition or risk this proves>
flow=<for graph/state/lifecycle/data-flow authoring: plain before -> this step -> resulting behavior|none>
terms=<only first-use visible labels needed in the steps: label = plain behavioral meaning|none>
open=<exact app/project/map/asset/panel>
setup=<numbered preparation; include exact authorized save paths or none>
action=<numbered user actions>
observe=<where and what to watch>
pass=<concrete observable result; for authoring include the exact finished surface/shape before save or report>
fail=<concrete contrary result or anomaly>
reply=<copyable per-observation result template; include NOT_CHECKED and anomaly fields>
fallback=<safe alternative and consequence>
```

Never ask the user to infer controls, keys, asset locations, or the response format when project files can establish them. If a control cannot be established, explain the shortest way to find it. A generic "check it in the Editor" is incomplete. When several observations in the same app/surface distinguish the current bounded hypotheses, batch them into this one card in inspection order instead of issuing avoidable one-field follow-ups. Do not request a user observation that source or deterministic tools can settle.

For manual graph, state-machine, lifecycle, wiring, or other structural authoring, show the whole behavior flow and the expected finished shape before numbered mechanics. Define every unfamiliar visible label at its first use by connecting it to what the system will do; do not rely on "same as last time", prior chat memory, or an unexplained engine/tool term. Separate hierarchy from order with an observable cue such as indentation, parent, or connector. Mention a historical pitfall only when it changes the current action. Never claim an insertion or wiring position is safe from surrounding references that were not inspected: label the claim `inferred`/`unknown` and request one bounded view that can confirm it. When the user reports completion, lead with acknowledgement and the next verification step rather than reopening background theory unless the reported shape conflicts with the card.

When evidence returns, compare Git/candidate identity before consuming the observation. `observe_only` may resume the blocked Review only when candidate bytes are unchanged. A planned pre-candidate `candidate_mutating` action returns to the same active Builder attempt after path reconciliation; any later `candidate_mutating` result invalidates the handed-off Build/Review identity, routes a new Build attempt to reconcile every changed path and fingerprint, and then receives a new Review. Do not promise that earlier AC evidence will be reused until the impact check proves it remains applicable.
