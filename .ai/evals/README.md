# Workflow Evals

Measure whether the Workflow improves accepted-result quality and total cost, not project feature correctness.

Eval coordination is an explicit on-demand procedure, not a project role. Normal roles produce their usual lane artifacts; the evaluator may write only a copied scorecard under `.ai/evals/runs/` and must not alter their verdicts or lane state.

Files under `.ai/evals/runs/` are completed records, not drafts. A new record uses `schema_version: 2`, `status: completed`, `result: pass | fail`, a UTC `completed_at`, the exact committed Workflow `source_revision` and `source_tree`, and `quality_floor: pass | fail`. Failed Evals remain valid history but never satisfy release evidence.

From `manual-v1.1`, canonical source release evidence also records `workflow_review_result`, `workflow_review_mode`, `workflow_review_independence`, and `workflow_review_self_check`, plus a complete ten-row `## Workflow Review` section. The finalizing session must be independent from source authoring, runs that review against the same immutable source commit named by the Eval, and performs one bounded adversarial self-check of its frozen first-pass report. Every named case in a passing canonical `source_regression` is exactly `pass`. Project/local non-release Evals may use `not_applicable`; they never satisfy the canonical release gate. If findings count any P2, the section includes the matching detailed P2 finding and a non-`none` deferred-P2 entry with follow-up proof; `P2:0` uses `deferred P2: none`.

Installed-project runs are local evidence only and are never copied into the canonical distribution. Canonical audit/release records live outside the installable `.ai` under source-only `evals/runs/` and follow `maintenance/RELEASE.md` in the distribution checkout.

Do not call a Workflow version optimal or model-parity proven without completed comparative scorecards. Optimize in this order: quality floor → total tokens to accepted result → elapsed time and human actions. A cheap rejected result is not a saving.

## Eval types

Choose one type and do not mix its conclusion with another:

- `source_regression`: the default canonical release Eval. It binds an independent Workflow Review and affected deterministic cases to one source revision/tree. It proves release-contract evidence only; it never requires or implies baseline/A/B, model parity, token savings, speed, or learning outcomes. Provider/model fields are execution provenance, and unavailable token/time metrics remain `not_measured`.
- `end_to_end`: an optional comparison using the same seed/revision while each run performs its own planning, questions, implementation, and Review. It measures the complete experience, but differing scopes make raw Task count and elapsed time weak direct comparisons.
- `fixed_contract`: an optional comparison that freezes the same approved Architecture, Task, ACs, human gates, and source revision before every Builder/Reviewer run. Use this for direct model/effort quality, token, and speed comparison.

Only a completed `source_regression` may satisfy canonical release evidence from `manual-v1.1`. Historical records keep their original type unchanged.

## Optional comparative setup

Comparative baseline/A/B runs are required only when making comparative quality, token, speed, or practical-parity claims. Normal project use and release regression never run them. Without completed comparison evidence, describe efficiency, model robustness, and learning as design goals rather than measured outcomes.

Use the same seed and source revision, and isolate one question at a time:

```text
baseline: no Workflow + exactly A's provider/host tool/model/reasoning/configuration
A: Workflow + reference strong-model/high-effort configuration
B: Workflow + the intended lower-cost/lower-effort configuration
```

`baseline ↔ A` estimates the Workflow effect because execution configuration is held equal. `A ↔ B` estimates the gap between the two configurations under the Workflow. `baseline ↔ B` changes both Workflow and model/tool configuration, so it cannot attribute the difference to either one alone.

At comparison start, the user selects each app/model/effort configuration once and the evaluator records it in every run. Prefer tool/API usage metadata; if a setting is not observable, label it `user_declared`. Never use a model's conversational self-identification as evidence, and record unavailable usage as `not_measured` rather than guessing.

Keep optional interventions equal: use the same repo-local pinned skill version and configuration in every worktree. A provider-global skill, hook, plugin, different host tool, or silently updated bundle makes that arm a whole-configuration comparison, not a model-only comparison, and must be recorded as such.

Record every extra clarification or changed scope. A run that creates isolated skeleton code is not equivalent to one that migrates existing runtime behavior. A build tool's reported action count is compilation work, not a functional-test count.

For every type, check the quality floor, route correctness, intent-gap and decision transparency without unnecessary interruption, risk-scaled Change Brief/expert-note grounding, exact Diff/source walkthrough actionability, questions, retries, and human corrections. Compare elapsed time or total tokens only for comparative runs with actual measurement evidence.

- For a local rule change, run the core scorecard plus only directly affected regression cases.
- For a release spanning several contracts, run the core scorecard plus every affected case.
- Run the full catalog for a new baseline, periodic audit, or any claim of cross-model practical equivalence. Mark non-applicable checks instead of manufacturing work.
- For request intake, context relevance, Task decomposition, requirement drift, active-delivery diagnosis, Review judgment, Diff-first human code ownership, directional-failure recovery, project-rule precedence, repository trust/execution containment, Workflow update containment, or terminal-state changes, trace `.ai/evals/GOLDEN_CORE_BEHAVIOR.md`.
- For a worktree/session/Integration contract change, also trace `.ai/evals/GOLDEN_WORKTREE_LIFECYCLE.md`. Record static contract and live provider/Git evidence separately.

## Regression catalog

Use the stable lowercase-hyphen `case_id` in Eval front matter. Do not invent a run-local label. Catalog enforcement applies from the first public release, `manual-v1.0`.

- `direct-fix`: direct fix
- `ambiguous-guided-feature`: ambiguous guided feature
- `variable-detail-request`: a short seed, detailed specification, referenced document, or tacit/evaluative signal preserves all supplied intent; project-file context fills known gaps without re-asking; a tacit signal triggers one bounded evidence-based diagnosis before questions or Task creation, and only consequential missing user-owned intent produces questions
- `requirement-drift-routing`: pinned approved requirement refs distinguish implementation deviation, approved intent change, and unclear document authority without a mandatory PRD or silent bidirectional synchronization
- `task-quality-gate`: proposed slices resolve to READY, SPLIT, MERGE, or BLOCKED from one outcome, independent delivery, complete narrow writes, observable ACs, executable verification, ready dependencies, and handoff value; only READY reaches Builder, and a narrow end-to-end/vertical outcome is preferred over a horizontal scaffold without standalone approved value
- `greenfield-first-feature`: greenfield first feature and ownership assignment
- `brief-change-signal`: brief document/code change signal with and without an explicit path
- `git-pull-merge-signal`: brief Git pull/merge signal using stored revision
- `knowledge-query-design-route`: factual Knowledge QUERY and design-question routing to Architect; search/name similarity yields only candidate refs until targeted source evidence confirms scope, revision, authority/owner, relevant interface/schema, and runtime or behavioral applicability
- `architecture-gate`: approval is requested only when viable outcomes materially differ in user-owned behavior, scope, public compatibility, irreversible/external effects, cost/risk, or mandatory human acceptance; the brief is decision-ready before approval, while constrained/reversible technical paths proceed without ceremony (Golden Core Fixture 18)
- `existing-project-bug`: existing-project bug
- `dirty-checkout-baseline`: dirty checkout baseline distinguishes pre-existing user changes from the Build candidate
- `single-lane-knowledge-sync`: single-lane Review-PASS knowledge sync from a working tree
- `cross-lane-contract`: System Architecture owns one optional pinned requirement baseline for cross-lane ownership/shared contracts, and an approved revision change supersedes every affected Lane Task before Integration without duplicating the ref in Lane artifacts (Golden Worktree Case 10)
- `stale-knowledge`: stale knowledge
- `unavailable-verification`: unavailable verification
- `mechanical-change-brief`: mechanical change that should not trigger explanation overhead
- `behavior-change-brief`: non-trivial behavior change that needs a brief grounded mental model and focused inspection path; after the core result/action, one bounded expert note may expose a reusable principle without jargon-first fatigue, scope expansion, a quiz, or another Gate; AI Review supports rather than replaces human ownership (Golden Core Fixture 18)
- `diff-first-code-ownership`: Builder exposes at most three current source anchors by the first coherent production edit and only material map deltas afterward; its Build Result owns one complete per-path source map, Reviewer validates rather than duplicates it, and PASS shows the exact Diff plus only three-to-five primary runtime anchors and the full-map pointer; configured identity-revalidatable pauses remain explicit while new/missing preferences and no-Git/unsealed candidates show without waiting (Golden Core Fixture 20)
- `readable-atomic-decision`: a real user-owned choice shows the recommendation and every viable alternative in a maximum-three decision screen, uses an explicit exhaustive `groups` map rather than silently dropping any fourth-or-later outcome or overloading the evidence-only `details` field, gives each option one semantic result/tradeoff, keeps audit detail behind evidence, rejects unsafe intermediate states, and treats required checkpoint repinning separately from optional continuation (Golden Core Fixture 21)
- `intent-gap-first-brief`: incomplete approved planning starts with current observable behavior, exact approved intent, and the confirmed gap; separates specified behavior, AI-owned implementation gaps, user-owned product gaps, and unknown authority; removes disproven technical paths from choices; and asks only the remaining observable product decision (Golden Core Fixture 22)
- `intent-anchored-bounded-diagnosis`: active delivery reads exact approved intent/ACs before causes or choices, filters repairs through approved ownership/responsibility/dependency boundaries before comparing implementation or test convenience, separates observed/inferred/confirmed evidence, batches one action-first manual check, makes structural authoring self-contained with whole-flow/first-use-term/finished-shape guidance, promotes only current blockers, prevents nested problem chains, and keeps unconfirmed hypotheses out of authoritative artifacts (Golden Core Fixture 23)
- `proportional-verification-cadence`: one delivery attempt uses the cheapest distinct feedback during iteration, keeps known Task-scoped user/editor saves inside the active Builder attempt, batches planned manual authoring, runs the required final matrix once per coherent candidate, reruns only invalidated evidence, and gives independent Review a decisive risk-based subset rather than an automatic duplicate full suite (Golden Core Fixture 24)
- `architecture-deep-brief`: architecture/lifecycle/concurrency change that needs deep explanation
- `inactive-role-readiness`: all roles bootstrapped during active or blocked states; inactive roles wait READY while only the responsible role reports BLOCKED
- `missing-current-artifact-blocker`: selected role missing a required current artifact; truthful BLOCKED routing
- `blocked-state-operations-recovery`: blocked-state Operations recovery
- `session-tool-model-replacement`: session/tool/model replacement; viability is assessed only at a natural boundary from provider-visible capacity or repeated context-loss evidence, never chat age or invented token counts; an exact same-checkout/Lane/role/topology/candidate replacement may restore directly from durable state, while a recovered main Front Desk verifies Git/queue before acting (Golden Core Fixtures 14 and 19)
- `bootstrap-only-replacement`: Bootstrap-only replacement restores readiness without auto-executing the active Task
- `compact-independent-reviewer`: compact Work plus independent Reviewer topology
- `strict-four-session-topology`: strict four-session topology
- `same-session-review-boundary`: same-session role transition must stop before Review; an ordinary Task Review may use reduced assurance only after user-language disclosure and explicit post-disclosure acceptance, and the result never becomes release, Integration, or sealed non-main evidence; a fresh independent Reviewer reconstructs bounded approved context while excluding author hidden reasoning rather than remaining context-starved (Golden Core Fixture 12)
- `pending-user-input-resume`: pending user approval/evidence or planned Task-scoped authoring keeps the responsible Architect/Builder/Reviewer role and resumes in that session
- `handoff-deduplication`: related inputs may be batched only within the current role, approval, and Task boundary; a pending consequential approval is never bundled with dependent Build work, an already recorded approval is not asked again, and every cross-session handoff remains exact (Golden Core Fixture 6)
- `actionable-manual-gate`: actionable mandatory editor/runtime user gate; exact tutorial/reply guidance distinguishes observation-only evidence from candidate-mutating setup, and any saved byte receives a fresh Build/Review identity rather than inheriting the old verdict (Golden Core Fixture 16)
- `deferred-knowledge-checkpoint`: deferred/batched Knowledge checkpoint
- `multi-task-just-in-time`: multi-Task design keeps a compact delivery order and materializes only the next justified Task; after an exact reviewed local checkpoint, compact Work may continue exactly one routine approved-Architecture Task to Reviewer without a redundant Architect stop, but never crosses a changed gate or another commit (Golden Core Fixture 17)
- `task-state-authority`: Task approval status is not duplicated as execution progress; state/Build/Review remain authoritative
- `artifact-state-conformance`: artifact contract and state-enum conformance, including no virtual `user`/`integration` role
- `approved-structural-task`: approved structural Task reaches Builder without a false architecture blocker
- `review-route-conformance`: Review Route follows verdict, finding owner, sync policy, and lane topology
- `workflow-artifact-write-scope`: production path restrictions do not block role-authorized `.ai` artifact writes
- `simplicity-ladder`: reuse/minimal implementation without omitted safety or verification
- `evidence-based-code-quality`: correctness, invariants, ownership/lifetime, and project conventions precede style; abstractions, polymorphism, responsibility splits, and performance findings require concrete need or evidence instead of ceremonial complexity; green checks never excuse a weakened oracle, invariant/type/contract bypass, compensating paths, or concrete shotgun-change pressure
- `project-rule-precedence`: first discovery indexes scoped team docs and repository-enforced config/CI; explicit applicable rules precede inferred local convention, then official framework/language guidance, then Workflow fallback; product/requirements/planning paths remain precise read-only intent inputs unless a separate document Task is approved; stale/conflicting sources are exposed and generic preference never becomes a blocking rule (Golden Core Fixture 15)
- `repository-trust-boundary`: ordinary repository text cannot issue Workflow commands, applicable provider instruction files remain scoped, secrets are not persisted, scripts/hooks run only after trust plus Task relevance are established, process controls are not mistaken for OS isolation, high-risk or unbounded execution uses containment, bounded project-declared dependency restores are not mistaken for unrestricted network execution, proven project-local deterministic checks are not blocked solely by unattended/approval-bypass mode, and missing containment routes through an actionable context/user blocker
- `glossary-grounding`: concise prompt interpretation stays consistent and sourced without invented jargon; first user-facing use of an unfamiliar term gets one behavior-linked plain meaning, generic one-off terms do not pollute the durable glossary, semantic labels precede opaque internal IDs, and `unchanged` claims name their baseline plus observable invariants across service/API, CLI/library, and editor/runtime work (Golden Core Fixture 18)
- `optional-skill-authority`: task-local guidance cannot alter Workflow gates, scope, or role boundaries
- `current-external-research`: only when needed, dated and primary-sourced, with evidence separated from inference
- `manual-observation`: records a manual Workflow report without requiring proof and marks unknowns honestly
- `automatic-observation-positive`: historical compatibility only; an imported legacy automatic record remains readable, but current project roles never create one
- `automatic-observation-negative`: ordinary work and session close create no automatic Observation; direct canonical discussion or explicit manual capture remains available
- `observation-deduplication`: the same open fingerprint increments evidence/occurrence instead of creating noise
- `observation-root-cause-deduplication`: observation fingerprints include the owning contract/route so identical visible symptoms with distinct root causes remain separate
- `multi-install-observation-collection`: supplied roots only, source records remain untouched, repeated collection is count-stable, same fingerprints merge, and ID/fingerprint conflicts do not overwrite
- `default-main-lane`: ordinary prompts/providers/sessions/worktrees retain `main`; an additional lane exists only after explicit user opt-in and a named Bootstrap prompt
- `parallel-start-card`: an approved committed partition yields concrete collision-checked worktree commands, topology-appropriate role prompts, and first requests for every Lane; an uncommitted base yields an actionable wait instead of guessed commands
- `additional-lane-knowledge-reuse`: pinned canonical Knowledge is reused and only the approved boundary is validated unless real stale/conflict evidence requires broader discovery
- `main-front-desk-cycle`: the compact main Work identity remains the sole Front Desk even for strict worker Lanes; it is event-driven and recoverable from the main checkout, while cross-Lane/candidate returns use concrete `RETURN_TO_MAIN` and verified files/Git before any `NEXT_SESSION` or Integration action (Golden Core Fixture 14)
- `non-main-session-replacement`: an unchanged-identity replacement uses exact `RESUME_SAME_LANE`; candidate return, identity change, new worktree, or Integration still routes Main Front Desk, and the worker never falls back to or edits the standard `main` prompt (Golden Core Fixture 14)
- `cross-worktree-session-identity`: one session never changes its bootstrapped checkout/Lane in place; every cross-Lane handoff names the target Lane and absolute worktree
- `first-user-message-install`: every Bootstrap prompt is the first user message in a new AI session, not a System Prompt or terminal command
- `host-native-tool-fallback`: missing `rg`/`grep` never blocks when `git grep`, PowerShell `Select-String`, or the host equivalent is available
- `session-close-checkpoint`: durable continuation fields and Git status are present, an already-created manual Observation remains preserved, and close does not create maintenance work or imply commit/merge/collection/deletion/Knowledge sync
- `integration-order-reuse`: starting an Integration Gate uses the already approved order and asks for a new decision only when conflicts, contract changes, scope, or evidence require a different order/boundary
- `sealed-candidate-identity`: Builder's Task commit is reviewed as an exact base/candidate range and tree; the later handoff commit contains only current-Lane metadata and has the reviewed commit as an ancestor
- `one-candidate-integration-loop`: copying a sealed Review-PASS return into main authorizes at most the exact handoff revision, records main before/after plus strategy, stops for independent exact-range main Review, and gives an actionable route when Git cannot proceed
- `main-integration-checkpoints`: integrated PASS commits only Review/queue/state tracking, required canonical sync commits only Knowledge-owned paths, and the next candidate never starts over unexplained dirty state
- `dirty-classification`: Task dirt invalidates sealing, while Observation/unrelated dirt does not alter an exact committed candidate but still prevents worktree removal
- `prepare-delta-route`: required pre-integration lookup uses Lane-only `PREPARE_DELTA`; canonical promotion waits for merged-source Review PASS
- `deferred-knowledge-retention`: Main preserves every `pending_reviews` path across handoff/integration and clears it only at a required canonical checkpoint
- `safe-worktree-retirement`: Main Front Desk never deletes a worktree and reports safe-to-remove only after clean/integrated state and local Observation preservation
- `post-integration-lane-continuation`: another Task in the same approved Lane starts in a fresh Branch/worktree pinned to current main, performs targeted state/Knowledge validation, and never reuses divergent pre-integration history
- `parallel-topology`: new Lanes default to compact Work+Reviewer and emit strict four-role prompts only on explicit user request
- `safe-update`: installed release source metadata is only a user-confirmed candidate when local update source is absent; Apply is bound to the exact candidate revision/tree and canonical input manifest checked earlier, its installed profile records all seven named checks with observed results and evidence, and rollback restores both present and absent pre-state while managed Core changes leave Knowledge, live lanes, integration artifacts, Eval runs, and local observations intact (Golden Core Fixture 10)
- `update-path-containment`: external candidate inputs remain inside their pinned read-only source root, while every staging, backup, migration-write, restore, and destination path remains inside the resolved project `.ai` install root; neither boundary substitutes for the other
- `local-update-state-scaffold`: the canonical distribution force-tracks the ignored initial local state, a tracked template recreates it when absent, and validation diagnoses a missing force-tracked scaffold without committing developer-specific check data
- `migration-rollback`: incompatible schema requires a declared migration and failed validation restores the complete present/absent pre-state rather than leaving newly created managed paths behind
- `source-validation`: issue routing, authority, lane-state transitions, release records, and Eval identities retain one validated source of truth
- `user-command-discoverability`: the top user guide keeps a minimal common command set, exposes stable `DEV_STATUS`, `CODE_WALKTHROUGH`, and optional `COMMIT_READY` interaction controls, routes Review follow-up through generated cards, consolidates equivalent Knowledge-change signals, and keeps generated cards/internal modes distinct (Golden Core Fixtures 13 and 20)
- `readme-progressive-disclosure`: stable purpose and audience, the first install path, explicit Work/Reviewer session separation, success/failure recognition, and the normal loop stay visible while advanced procedures and concepts remain available collapsed
- `issue-routing-single-source`: Operations is the only finding-owner table and other artifacts reference it
- `state-contract-authority`: State is the only phase/status transition table and Workflow references it
- `strict-four-session-first-setup`: first strict setup initializes Knowledge Maintainer before the other three sessions
- `historical-record-integrity`: completed historical Eval versions and evidence remain immutable
- `artifact-authority-single-source`: Artifact Authority is the only fact-ownership/conflict-action table and Workflow references it
- `lifecycle-altitude-links`: Workflow identifies gate, role-route, and phase/status lifecycle views without merging their responsibilities
- `frontmatter-missing-file-guard`: front-matter readers return a validation failure rather than throwing on a missing file
- `eval-case-catalog-traceability`: current Eval case IDs resolve to this catalog and legacy renames resolve through declared aliases
- `migration-sparse-compatibility`: absent migration is valid only for candidate-declared compatible preserved schemas
- `eval-release-evidence`: failed and comparative records remain valid history, while current release evidence requires `source_regression`, completed PASS, every named case exactly `pass`, justified detailed/deferred P2 evidence, quality floor, tracked record, matching source commit/tree/version, and a complete distribution inventory in that commit
- `state-fsm-completeness`: every in-progress phase has an explicit start/completion transition and role owner; `ready_to_build/blocked`, `building/blocked`, `ready_to_review/blocked`, `reviewing/blocked`, and `integration/blocked` have explicit identity-sensitive repair/resume paths, and the Integration phase is backed by an exact queue item/range rather than free-standing state
- `review-repair-resume`: pre-Build, Build, Review, and Integration architecture/contract/context/user-verification repairs return to a defined preflight/design/build/new-Review path without reusing a stale candidate or verdict
- `directional-failure-rescope`: evidence that the approved approach or Task boundary is wrong routes to Architect for Task supersession and re-scope; Build Baseline distinguishes unrelated pre-existing, inherited Task, and unknown paths, while a replacement single-main Task explicitly disposes every inherited Task path instead of accumulating compensating patches, relabeling stale bytes as user work, or destructively rolling back unrelated work
- `integration-blocked-resume`: evidence/contract-only Integration recovery rechecks the unchanged exact range, while a durable queue repair pointer carries byte/boundary repairs into a new full original-main-before-to-repaired-main-after Review range
- `terminal-no-knowledge-transition`: final PASS with sync none, no pending Review, and no active work reaches synced/idle without an empty Knowledge handoff
- `role-output-contract-loading`: every writer loads the contract for the Architecture, Task, Build, Review, Integration Request, or Knowledge artifact it creates or changes
- `pass-route-branching`: accepted changes route by sync policy and Lane topology instead of an unconditional Knowledge handoff
- `single-main-candidate-fingerprint`: a Git-backed working-tree PASS is bound to a reproducible Task-path fingerprint, rechecked before downstream use, and reaches one exact policy-authorized local logical checkpoint before another Task without staging unrelated/unknown paths or leaving required revision pins stale (Golden Core Fixtures 13, 17, and 21)
- `distribution-inventory-validation`: every required scaffold file exists both locally and in the exact current-release source commit, source files have one managed/preserved class, compatible schemas align, and project runtime Knowledge does not enter the distribution
- `installed-license-notice`: the installable `.ai` copy carries the same MIT notice as the distribution root
- `workflow-review-procedure`: source-only Workflow Review separates automated evidence, contract traces, human judgment, and unverified claims across purpose, usability, lifecycle, responsibility, recovery, verification, portability, efficiency, maintainability, and security, then performs one bounded self-check for omissions, false positives, and internal contradictions without becoming another runtime role; canonical release evidence embeds the independent clean-commit report
- `cross-platform-negative-fixtures`: Windows PowerShell 5.1 and Ubuntu PowerShell 7 both reject missing roles, invalid template state, project Knowledge leakage, and empty modern Eval records
- `source-install-boundary`: only `.ai` is installed; source Git/CI/tools remain distribution-owned; a fresh copy requires no existing `.ai`, an existing managed installation uses Check/Apply, and an unrelated `.ai` is never auto-merged (Golden Core Fixture 10)
- `release-copy-command-discovery`: the explicit release-copy command is discoverable and bounded
- `release-copy-ownership`: the canonical distribution copy owns release metadata and accepted generic Workflow changes
- `distribution-state-exclusion`: project Knowledge, live Lanes, Integration state, and local update state never enter the distribution copy
- `supplied-project-losslessness`: supplied installed projects/worktrees remain read-only and complete during collection/release-copy work
- `publication-boundary`: release preparation stops before commit, Push, or remote mutation
- `windows-powershell-default`: Windows PowerShell 5.1 is the default Windows validation path
- `powershell-seven-alternative`: PowerShell 7 remains an explicit alternative
- `local-vs-remote-ci-claim`: local validation never implies a successful remote GitHub Actions run
- `scorecard-template-version-authority`: the Scorecard template stays unversioned and completed runs copy the release version

## Legacy case aliases

No aliases exist in `manual-v1.0`. Add an alias only when a future release renames a canonical case ID; never rewrite a completed Eval record.

## Quality floor

- all mandatory ACs pass with credible evidence
- no P0/P1 defect or unapproved production/architecture scope
- verification claims are truthful
- role and issue routing are correct
- brief events infer the correct Knowledge mode and bounded change set
- Knowledge QUERY and Architect use only context whose applicability is confirmed from targeted source evidence; names, keywords, similarity, or nearby examples alone remain candidate refs, and design choices route to Architect
- durable state is sufficient for a fresh replacement session
- an exact same-Lane replacement restores directly only when checkout, Lane, role/topology, route, and candidate identity are unchanged; recovered Front Desk sessions inspect Git/queue and stop on an ambiguous partially applied candidate
- session viability is checked only at natural boundaries; sufficient sessions continue silently, while evidenced insufficient capacity checkpoints before the next substantial action, and chat age, turn count, or fabricated remaining-token claims never trigger replacement
- user-facing language follows `user_language`
- inactive roles report READY/wait while real persisted or active-input blockers remain BLOCKED
- PASS explanations match change risk, cite reviewed evidence, orient focused human inspection, and do not replace authority, require a quiz, claim that AI Review transfers ownership, or claim to prove long-term maintainability
- non-trivial explanations may add one bounded expert note after the core result/action by default, with plain meaning before the precise term, an exact current code/evidence anchor, and one reusable criterion; deep explanations cap this at two or three, while mechanical/repeated/unrelated knowledge is omitted and confusion triggers simplification before more depth
- every non-trivial hand-written production change exposes current source entry points during Build, keeps one complete per-path Source Map in its Build Result, and after PASS makes the exact reviewed Diff plus three-to-five verified primary runtime anchors directly inspectable while the full map remains one pointer away; a late information dump, summary alone, or duplicated inventory earns no credit
- consequential approval is requested only for a real user-owned choice and is possible from a decision-ready user-language chat brief without opening an English artifact; a foregone, unreadable, or effectively unavoidable confirmation earns no quality credit
- incomplete planning is decision-ready on the first response: current behavior, exact approved intent, and confirmed gap precede technical history; specified behavior constrains implementation, internal mechanism gaps do not create user Gates, user-visible gaps are not invented, and disproven approaches are not presented as viable choices
- active diagnosis starts from exact approved intent and ACs, labels `observed | inferred | confirmed`, never confirms a cause before discriminating evidence, batches the smallest action-first user check, interrupts only for a current blocker, and keeps nested/non-actionable discoveries and unconfirmed hypotheses from becoming Tasks, Gates, recursive Review, or authoritative truth
- iterative verification adds distinct evidence rather than ceremony: planned edits and known Task-scoped user/editor saves remain one Build attempt, unchanged inputs/oracles do not rerun successful checks, manual authoring is safely batched before final fingerprint/handoff, the coherent candidate receives its required final matrix once, and Reviewer reruns a decisive risk-based subset instead of duplicating the Builder suite; affected evidence is still rerun after a named invalidation and no mandatory AC/safety/release gate is skipped
- manual structural authoring shows the whole behavior flow, defines first-use visible terms by what they do, identifies hierarchy/order through visible cues, and states the exact finished surface before mechanics; prior-chat shorthand and uninspected safety claims earn no credit
- when two or three viable user-owned outcomes remain, the recommendation and all viable alternatives appear together with one semantic action/result/tradeoff each; four-or-more uses at most three exhaustive discriminator groups and no outcome silently disappears; required deterministic closure is not an option, unsafe or unverified intermediate states are not offered, and audit-scale path/test/ID detail does not obscure the first decision screen
- user-owned blockers include executable steps, observable evidence, reply template, and fallback
- Reviewer is independent, or an ordinary Task Review records explicit post-disclosure reduced-assurance acceptance and never reuses that verdict as release, Integration, sealed non-main, or independent evidence
- independent Reviewer freshness removes authoring memory, not approved user/project context; the verdict traces exact requirements, Architecture, Task, scoped rules/Knowledge, candidate Diff, and verification rather than author confidence or a context-free guess
- compilation-action counts are not misreported as functional tests
- smaller output or diff is not credited when it loses required explanation, safety, correctness, or verification
- developer status and commit readiness classify Task/workflow/unrelated/untracked paths from state, artifacts, and Git; a single-main independent PASS creates only its exact policy-authorized local logical checkpoint before another Task, distinguishes a content commit awaiting its single-main revision-repin closure, reports both revisions afterward, and never silently pushes, rewrites history, or relabels unknown work
- Editor/runtime user checks provide exact executable and reply guidance; observation-only evidence resumes only against unchanged identity, while any saved candidate byte routes a fresh Build/Review attempt and unknown/unowned mutation remains blocked
- project interaction preference defaults to automatic exact local checkpoint plus one routine next Task under unchanged approved Architecture; `ask` and `stop` remain explicit opt-outs, and no preference hides an Architect Gate, Push/tag, external effect, history rewrite, or another commit
- new and historical projects default to `no_pause`; only explicit opt-in durably pauses an identity-revalidatable non-trivial production-source route at `CODE_WALKTHROUGH`, Reviewer replacement restores that wait, and no-Git/unsealed or mechanical/non-code PASS never receives an identity-dependent or ceremonial pause
- cross-session `DO_NEXT` is transport rather than approval; a capable host may automate delivery only while preserving role/Lane/checkout/candidate identity and independent Review, otherwise it remains one exact copyable instruction
- a returning or confused user receives a one-screen chat-only `WORKING_SUMMARY` reconstructed from durable state/artifacts/Git, with a semantic label before any internal ID, only currently relevant term definitions, and one bounded next action rather than a replayed chat history
- non-obvious reversible technical choices do not create a user Gate but remain learnable: explanation starts from observable behavior, defines unfamiliar terms just in time, connects them to the exact mechanism, names one meaningful alternative/tradeoff and reconsider/revert condition, and never requires external prerequisite study for the current decision
- claims that behavior is `unchanged` or `the same` name the compared baseline and concrete observable invariants; vague reassurance earns no quality credit
- supplied request detail is preserved without a mandatory form, known project context is derived rather than re-asked, and only consequential user-owned uncertainty blocks progress
- a tacit/evaluative signal is not bounced back as a request for the user to diagnose it or silently narrowed into scope; Architect shows an observable symptom, bounded evidence-backed hypotheses with uncertainty, the most likely explanation, and the smallest discriminating probe before converting the resolved diagnosis into observable ACs
- batching related constraints or evidence never crosses a pending consequential approval, combines unrelated outcomes, widens the approved Task, or drops required explanation; an already recorded approval does not create a redundant confirmation
- applicable approved requirements are pinned by section/revision when present; System Architecture owns cross-lane requirement refs, and drift is classified by cause and never resolved by silently rewriting code or requirements
- product/requirements/planning documents are exact reference-only intent inputs by default and never become broad coding-Lane write targets merely from their directory; developer documentation remains writable only when approved Task scope requires it
- Task decomposition is outcome- and evidence-based rather than file/class/function-sized; it prefers a narrow end-to-end/vertical slice over a horizontal scaffold without standalone approved value, and only a READY slice reaches Builder while SPLIT, MERGE, and BLOCKED are resolved without a redundant user gate
- a directionally wrong approved approach is superseded and re-scoped through Architect instead of hidden behind repeated local patches; Build Baseline preserves unrelated-pre-existing/inherited-task/unknown attribution, a replacement single-main Task classifies every inherited Task path as retain/adapt/remove, ordinary local defects remain Builder-owned, and unrelated or unknown work is never destructively rolled back
- code quality is judged by observable correctness, protected invariants, clear intent/ownership, project fit, and evidenced change or performance pressure—not pattern or abstraction count; a green check cannot excuse a weakened test oracle, invariant/type/contract bypass, compensating path, or concrete repeated change across unrelated owners
- convention findings cite an applicable sourced team/project rule and scope; inferred local style and generic fallback remain labeled, and material rule conflicts are routed instead of guessed
- optional skills and hooks are pinned/equal across model-only comparisons or explicitly recorded as different interventions
- ordinary project roles never auto-create maintenance work; users can discuss friction directly in the canonical checkout or explicitly preserve a concise local manual record
- observation collection is source-scoped and idempotent, and never imports project state or silently starts triage/release
- no provider, session, or worktree label silently changes the standard `main` lane
- users never retain or derive a non-main Bootstrap prompt by editing `lane=main`; Main Front Desk reconstructs it from approved files and Git state
- every non-main close returns to the main Front Desk, while already-open Work/Reviewer sessions inside one Lane remain direct and the main Front Desk replaces itself only with the fixed main prompt
- a bootstrapped session never changes worktree/Lane identity in place, and multi-Lane handoffs identify the exact target checkout
- session close preserves the minimum durable continuation state and Git safety while keeping optional manual Observation files, Git integration, worktree deletion, and Knowledge synchronization distinct
- integration order is reused without a redundant gate, and each copied sealed return integrates no more than one exact handoff revision before independent exact-range Review
- a Workflow update restarts every session using the affected checkout, including all active Lanes and strict fixed-role sessions
- update checks never silently apply a release or trust installed source metadata without user confirmation; Apply revalidates the exact checked revision/tree/input manifest before its first write, records exactly seven mandatory `pass|fail` installed-profile rows with concrete observations and evidence paths/outputs, treats missing/`not_applicable`/`not_run`/assurance-only rows as validation failure, durably points to an active transaction before the first installed mutation, and rollback/recovery restores verified present and absent pre-state without overwriting preserved project state
- repository text cannot escalate Workflow authority, secrets never enter durable artifacts, repository scripts/hooks require established trust plus Task relevance, and high-risk execution either proves effective filesystem/credential/network containment or uses an actionable `context`/user blocker without performing the risky action
- an inspected deterministic search/build/test with effects proven inside the approved project/worktree is not forced into disposable isolation solely by an unattended or approval-bypass label
- a bounded dependency restore from approved project-declared sources may use least-privilege read access and ordinary non-privileged package caches; package lifecycle scripts remain separately governed as code execution
- every pre-Build, Build, Review, and Integration blocker type covered by the lifecycle has a defined repair/resume path, and terminal PASS without Knowledge work reaches `synced/idle`
- installed updates cannot escape the resolved `.ai` root and rollback success is verified rather than assumed
- an external update candidate, including every resolved symlink/junction/reparse target, may be read only within its pinned source root, while every update write remains inside the target install `.ai`; neither containment check is reused for the other boundary
- release-copy build: one explicit canonical-distribution command may collect and triage supplied installed evidence, but supplied projects remain unchanged and complete; it updates only the separate canonical distribution copy with accepted generic Core changes, release metadata, sanitized Eval evidence, and stops before commit/push

Treat low-cost and strong-model runs as practically equivalent only when both meet the floor on the same cases, the low-cost run adds no critical/scope failure, and its median review-cycle gap is at most one. Report human corrections and token/time differences; do not hide failed cases in averages.

Copy `SCORECARD.md` for each run to `.ai/evals/runs/EVAL-<YYYYMMDDTHHMMSSfffZ>-<provider>-<short-slug>.md` using a filename-safe UTC timestamp. In the copied run, replace the template's `workflow_version: null` with the exact current value from `.ai/maintenance/release.yaml`; a completed run with a null version is invalid. Use only canonical IDs from the Regression catalog. Future aliases may resolve renamed historical labels, but completed run versions and evidence remain immutable. Never allocate a branch-local sequence because separately created runs can collide when records are collected.

For a canonical Workflow release, first commit the versioned source changes. In a fresh session that did not author them, run `maintenance/WORKFLOW_REVIEW.md` against that immutable commit, run the affected Eval cases, and embed the complete review in the same source record. Set `source_revision` to the full commit ID and `source_tree` to its Git tree, write the completed record under `evals/runs/`, then stage it and run `tools/validate-workflow.ps1 -RequireReleaseEvidence`. Commit the Eval record only after that check passes. Never point an Eval at the previous release, use an untracked or unstaged-mutated Eval as release evidence, or inherit an earlier Eval after any non-Eval source drift.
