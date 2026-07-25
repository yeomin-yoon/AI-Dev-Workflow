# Workflow Evals

Measure whether the Workflow improves accepted-result quality and total cost, not project feature correctness.

Eval coordination is an explicit on-demand procedure, not a project role. Normal roles produce their usual lane artifacts; the evaluator may write only a copied scorecard under `.ai/evals/runs/` and must not alter their verdicts or lane state.

Files under `.ai/evals/runs/` are completed records, not drafts. A new record uses `schema_version: 2`, `status: completed`, `result: pass | fail`, a UTC `completed_at`, the exact committed Workflow `source_revision` and `source_tree`, and `quality_floor: pass | fail`. Failed Evals remain valid history but never satisfy release evidence.

Installed-project runs are local evidence only and are never copied into the canonical distribution. Canonical audit/release records live outside the installable `.ai` under source-only `evals/runs/` and follow `maintenance/RELEASE.md` in the distribution checkout.

Do not call a Workflow version optimal or model-parity proven without completed scorecards. Optimize in this order: quality floor → total tokens to accepted result → elapsed time and human actions. A cheap rejected result is not a saving.

Comparative baseline/A/B runs are optional and are required only for comparative quality, token, speed, or model-parity claims. Normal project use and a source-bound release regression Eval do not require a comparison run; without one, describe efficiency and learning as design goals rather than measured outcomes.

Compare the same seed and revision:

```text
baseline: no Workflow
A: Workflow + strong model/high effort
B: Workflow + low-cost model/low effort
```

Keep optional interventions equal: use the same repo-local pinned skill version and configuration in every worktree. A provider-global skill, hook, plugin, or silently updated bundle makes that run a different treatment and must be recorded rather than treated as model-only evidence.

Choose one of two eval types and do not mix their conclusions:

- `end_to_end`: same seed/revision, allowing each Architect to ask questions and choose structure. This measures the complete planning + implementation + review workflow, but different resulting scopes make raw task count and elapsed time non-comparable.
- `fixed_contract`: freeze the same approved Architecture, Task, ACs, human gates, and source revision before each Builder/Reviewer run. This is required for direct model/effort quality, token, and speed comparison.

Record every extra clarification or changed scope. A run that creates isolated skeleton code is not equivalent to one that migrates existing Blueprint-backed runtime behavior. UBT's `N actions` is compilation work, not `N gameplay actions` or functional tests.

Check quality floor/gap, route correctness, decision transparency without unnecessary interruption, risk-scaled Change Brief grounding/usefulness, questions, retries, human corrections, elapsed time, and total tokens to accepted result.

- For a local rule change, run the core scorecard plus only directly affected regression cases.
- For a release spanning several contracts, run the core scorecard plus every affected case.
- Run the full catalog for a new baseline, periodic audit, or any claim of cross-model practical equivalence. Mark non-applicable checks instead of manufacturing work.
- For a worktree/session/Integration contract change, also trace `.ai/evals/GOLDEN_WORKTREE_LIFECYCLE.md`. Record static contract and live provider/Git evidence separately.

## Regression catalog

Use the stable lowercase-hyphen `case_id` in Eval front matter. Do not invent a run-local label. Catalog enforcement applies from the first public release, `manual-v1.0`.

- `direct-fix`: direct fix
- `ambiguous-guided-feature`: ambiguous guided feature
- `greenfield-first-feature`: greenfield first feature and ownership assignment
- `brief-change-signal`: brief document/code change signal with and without an explicit path
- `git-pull-merge-signal`: brief Git pull/merge signal using stored revision
- `knowledge-query-design-route`: factual Knowledge QUERY and design-question routing to Architect
- `architecture-gate`: architecture gate
- `existing-project-bug`: existing-project bug
- `dirty-checkout-baseline`: dirty checkout baseline distinguishes pre-existing user changes from the Build candidate
- `single-lane-knowledge-sync`: single-lane Review-PASS knowledge sync from a working tree
- `cross-lane-contract`: cross-lane contract
- `stale-knowledge`: stale knowledge
- `unavailable-verification`: unavailable verification
- `mechanical-change-brief`: mechanical change that should not trigger explanation overhead
- `behavior-change-brief`: non-trivial behavior change that needs a brief grounded mental model
- `architecture-deep-brief`: architecture/lifecycle/concurrency change that needs deep explanation
- `inactive-role-readiness`: all roles bootstrapped during active or blocked states; inactive roles wait READY while only the responsible role reports BLOCKED
- `missing-current-artifact-blocker`: selected role missing a required current artifact; truthful BLOCKED routing
- `blocked-state-operations-recovery`: blocked-state Operations recovery
- `session-tool-model-replacement`: session/tool/model replacement
- `bootstrap-only-replacement`: Bootstrap-only replacement restores readiness without auto-executing the active Task
- `compact-independent-reviewer`: compact Work plus independent Reviewer topology
- `strict-four-session-topology`: strict four-session topology
- `same-session-review-boundary`: same-session role transition must stop before Review
- `pending-user-input-resume`: pending user approval/evidence keeps the responsible Architect/Reviewer role and resumes in that session
- `handoff-deduplication`: same-session user reply has no redundant `DO_NEXT`; every cross-session handoff remains exact
- `actionable-manual-gate`: actionable mandatory Editor/PIE user gate
- `deferred-knowledge-checkpoint`: deferred/batched Knowledge checkpoint
- `multi-task-just-in-time`: multi-Task design keeps a compact delivery order and materializes only the next justified Task
- `task-state-authority`: Task approval status is not duplicated as execution progress; state/Build/Review remain authoritative
- `artifact-state-conformance`: artifact contract and state-enum conformance, including no virtual `user`/`integration` role
- `approved-structural-task`: approved structural Task reaches Builder without a false architecture blocker
- `review-route-conformance`: Review Route follows verdict, finding owner, sync policy, and lane topology
- `workflow-artifact-write-scope`: production path restrictions do not block role-authorized `.ai` artifact writes
- `simplicity-ladder`: reuse/minimal implementation without omitted safety or verification
- `glossary-grounding`: concise prompt interpretation stays consistent and sourced without invented jargon
- `optional-skill-authority`: task-local guidance cannot alter Workflow gates, scope, or role boundaries
- `current-external-research`: only when needed, dated and primary-sourced, with evidence separated from inference
- `manual-observation`: records a manual Workflow report without requiring proof and marks unknowns honestly
- `automatic-observation-positive`: supported false blocker/route, missing actionability, redundant gate, avoidable context retry, provider incompatibility, or Eval failure is captured once
- `automatic-observation-negative`: ordinary code bug, Review finding, unavailable tool, or corrected one-off model slip creates no automatic record
- `observation-deduplication`: the same open fingerprint increments evidence/occurrence instead of creating noise
- `multi-install-observation-collection`: supplied roots only, source records remain untouched, repeated collection is count-stable, same fingerprints merge, and ID/fingerprint conflicts do not overwrite
- `default-main-lane`: ordinary prompts/providers/sessions/worktrees retain `main`; an additional lane exists only after explicit user opt-in and a named Bootstrap prompt
- `parallel-start-card`: an approved committed partition yields concrete collision-checked worktree commands, topology-appropriate role prompts, and first requests for every Lane; an uncommitted base yields an actionable wait instead of guessed commands
- `additional-lane-knowledge-reuse`: pinned canonical Knowledge is reused and only the approved boundary is validated unless real stale/conflict evidence requires broader discovery
- `main-front-desk-cycle`: the compact main Work session remains the sole Front Desk even for strict worker Lanes; every closed non-main session returns through a concrete `RETURN_TO_MAIN`; main verifies files/Git and emits any `NEXT_SESSION`
- `non-main-session-replacement`: Main Front Desk reissues the exact Lane/topology prompt and first request; the worker never falls back to or edits the standard `main` prompt
- `cross-worktree-session-identity`: one session never changes its bootstrapped checkout/Lane in place; every cross-Lane handoff names the target Lane and absolute worktree
- `first-user-message-install`: every Bootstrap prompt is the first user message in a new AI session, not a System Prompt or terminal command
- `host-native-tool-fallback`: missing `rg`/`grep` never blocks when `git grep`, PowerShell `Select-String`, or the host equivalent is available
- `session-close-checkpoint`: durable continuation fields and Git status are present, manual Observation capture persists, automatic capture remains evidence-gated, and close does not imply commit/merge/collection/deletion/Knowledge sync
- `integration-order-reuse`: starting an Integration Gate uses the already approved order and asks for a new decision only when conflicts, contract changes, scope, or evidence require a different order/boundary
- `sealed-candidate-identity`: Builder's Task commit is reviewed as an exact base/candidate range and tree; the later handoff commit contains only current-Lane metadata and has the reviewed commit as an ancestor
- `one-candidate-integration-loop`: copying a sealed Review-PASS return into main authorizes at most the exact handoff revision, records main before/after plus strategy, stops for independent exact-range main Review, and gives an actionable route when Git cannot proceed
- `main-integration-checkpoints`: integrated PASS commits only Review/queue/state tracking, required canonical sync commits only Knowledge-owned paths, and the next candidate never starts over unexplained dirty state
- `dirty-classification`: Task dirt invalidates sealing, while Observation/unrelated dirt does not alter an exact committed candidate but still prevents worktree removal
- `prepare-delta-route`: required pre-integration lookup uses Lane-only `PREPARE_DELTA`; canonical promotion waits for merged-source Review PASS
- `deferred-knowledge-retention`: Main preserves every `pending_reviews` path across handoff/integration and clears it only at a required canonical checkpoint
- `safe-worktree-retirement`: Main Front Desk never deletes a worktree and reports safe-to-remove only after clean/integrated state and local Observation preservation
- `parallel-topology`: new Lanes default to compact Work+Reviewer and emit strict four-role prompts only on explicit user request
- `safe-update`: managed Core changes while Knowledge, live lanes, integration artifacts, Eval runs, and local observations remain intact
- `migration-rollback`: incompatible schema requires a declared migration and failed validation restores the backup
- `source-validation`: issue routing, authority, lane-state transitions, release records, and Eval identities retain one validated source of truth
- `user-command-discoverability`: the top user guide maps common intents to target sessions and copyable phrases while generated cards/internal modes remain distinct
- `readme-progressive-disclosure`: first install, the command map, and the normal loop stay visible while advanced procedures and concepts remain available collapsed
- `issue-routing-single-source`: Operations is the only finding-owner table and other artifacts reference it
- `state-contract-authority`: State is the only phase/status transition table and Workflow references it
- `strict-four-session-first-setup`: first strict setup initializes Knowledge Maintainer before the other three sessions
- `historical-record-integrity`: completed historical Eval versions and evidence remain immutable
- `artifact-authority-single-source`: Artifact Authority is the only fact-ownership/conflict-action table and Workflow references it
- `lifecycle-altitude-links`: Workflow identifies gate, role-route, and phase/status lifecycle views without merging their responsibilities
- `frontmatter-missing-file-guard`: front-matter readers return a validation failure rather than throwing on a missing file
- `eval-case-catalog-traceability`: current Eval case IDs resolve to this catalog and legacy renames resolve through declared aliases
- `migration-sparse-compatibility`: absent migration is valid only for candidate-declared compatible preserved schemas
- `eval-release-evidence`: failed records remain valid history, while release evidence requires completed PASS, quality floor, non-empty cases, tracked record, and matching source commit/tree/version
- `state-fsm-completeness`: every in-progress phase has an explicit start/completion transition and role owner; the Integration phase is backed by an exact queue item/range rather than free-standing state
- `pass-route-branching`: accepted changes route by sync policy and Lane topology instead of an unconditional Knowledge handoff
- `single-main-candidate-fingerprint`: a Git-backed working-tree PASS is bound to a reproducible Task-path fingerprint and rechecked before downstream use
- `distribution-inventory-validation`: every required scaffold file exists, source files have one managed/preserved class, compatible schemas align, and project runtime Knowledge does not enter the distribution
- `cross-platform-negative-fixtures`: Windows PowerShell 5.1 and Ubuntu PowerShell 7 both reject missing roles, invalid template state, project Knowledge leakage, and empty modern Eval records
- `source-install-boundary`: only `.ai` is installed; source Git/CI/tools remain distribution-owned
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
- Knowledge QUERY answers factual questions with source refs and routes design choices
- durable state is sufficient for a fresh replacement session
- user-facing language follows `user_language`
- inactive roles report READY/wait while real persisted or active-input blockers remain BLOCKED
- PASS explanations match change risk, cite reviewed evidence, and do not replace authority or require a quiz
- consequential approval is possible from the user-language chat brief without opening an English artifact
- user-owned blockers include executable steps, observable evidence, reply template, and fallback
- Reviewer is independent or reduced assurance is explicitly disclosed
- compilation-action counts are not misreported as tests or gameplay actions
- smaller output or diff is not credited when it loses required explanation, safety, correctness, or verification
- optional skills and hooks are pinned/equal across model-only comparisons or explicitly recorded as different interventions
- observation precision is favored over recall: automatic candidates require evidence, while manual reports remain available for missed cases
- observation collection is source-scoped and idempotent, and never imports project state or silently starts triage/release
- no provider, session, or worktree label silently changes the standard `main` lane
- users never retain or derive a non-main Bootstrap prompt by editing `lane=main`; Main Front Desk reconstructs it from approved files and Git state
- every non-main close returns to the main Front Desk, while already-open Work/Reviewer sessions inside one Lane remain direct and the main Front Desk replaces itself only with the fixed main prompt
- a bootstrapped session never changes worktree/Lane identity in place, and multi-Lane handoffs identify the exact target checkout
- session close preserves the minimum durable continuation state and Git safety while keeping Observation capture, Git integration, worktree deletion, and Knowledge synchronization distinct
- integration order is reused without a redundant gate, and each copied sealed return integrates no more than one exact handoff revision before independent exact-range Review
- a Workflow update restarts every session using the affected checkout, including all active Lanes and strict fixed-role sessions
- update checks never silently apply a release, and update apply never overwrites preserved project state
- release-copy build: one explicit canonical-distribution command may collect and triage supplied installed evidence, but supplied projects remain unchanged and complete; it updates only the separate canonical distribution copy with accepted generic Core changes, release metadata, sanitized Eval evidence, and stops before commit/push

Treat low-cost and strong-model runs as practically equivalent only when both meet the floor on the same cases, the low-cost run adds no critical/scope failure, and its median review-cycle gap is at most one. Report human corrections and token/time differences; do not hide failed cases in averages.

Copy `SCORECARD.md` for each run to `.ai/evals/runs/EVAL-<YYYYMMDDTHHMMSSfffZ>-<provider>-<short-slug>.md` using a filename-safe UTC timestamp. In the copied run, replace the template's `workflow_version: null` with the exact current value from `.ai/maintenance/release.yaml`; a completed run with a null version is invalid. Use only canonical IDs from the Regression catalog. Future aliases may resolve renamed historical labels, but completed run versions and evidence remain immutable. Never allocate a branch-local sequence because separately created runs can collide when records are collected.

For a canonical Workflow release, first commit the versioned source changes. Run the affected Eval cases against that immutable commit, set `source_revision` to its full commit ID and `source_tree` to its Git tree, write the completed source record under `evals/runs/`, then stage it and run `tools/validate-workflow.ps1 -RequireReleaseEvidence`. Commit the Eval record only after that check passes. Never point an Eval at the previous release, use an untracked or unstaged-mutated Eval as release evidence, or inherit an earlier Eval after any non-Eval source drift.
