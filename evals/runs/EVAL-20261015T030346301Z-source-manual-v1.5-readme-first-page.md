---
schema_version: 2
id: EVAL-20261015T030346301Z-source-manual-v1.5-readme-first-page
date: 2026-10-15
status: completed
result: pass
completed_at: 2026-10-15T03:16:15.169Z
source_revision: 92759c8e7a7c12fe9ba5df0571d059cc29c44543
source_tree: 3a385a461b78c9f18e50815e4e635a96ae8a2235
quality_floor: pass
seed: "Independently finalize the README-only first-page and general collaboration prompt revision at clean immutable HEAD; preserve manual-v1.5 runtime contracts and the existing v1.5 tag."
lane: source
provider: unknown
host_tool: codex-desktop
model: not_disclosed
reasoning: not_disclosed
optional_interventions: []
user_language: ko
workflow_version: manual-v1.5
eval_type: source_regression
workflow_review_result: pass
workflow_review_mode: changed
workflow_review_independence: independent_session
workflow_review_self_check: corrected
regression_cases:
  - variable-detail-request
  - architecture-gate
  - lowest-sufficient-architecture-baseline
  - continuous-source-truth
  - reference-role-and-fit
  - repository-trust-boundary
  - compact-independent-reviewer
  - first-user-message-install
  - source-install-boundary
  - readme-progressive-disclosure
  - user-command-discoverability
  - workflow-review-procedure
  - eval-release-evidence
---

# Workflow Eval

This is a source-only documentation regression, not a live provider experiment, project Task Review, or comparison. The reviewer did not author the candidate. Host identity is environment-observed; provider, exact model, and effort were not supplied by observed execution metadata, so they remain unknown/not_disclosed. No conversational model self-identification was used as provenance.

## Oracle

- expected route: README-only independent `changed` review against the clean source commit, affected canonical contract/scenario checks, one source-only Eval, stage only that Eval, then mandatory finalization validation; no source repair or remote action.
- architecture gate: no new runtime behavior, schema, role, artifact, Gate, or version is authorized. The README may improve presentation and the optional conversation prompt only.
- must ask: stop for source identity drift, unsafe/unusable onboarding, a P1/applicable FAIL, or an unjustified P2. A user's consequential outcome remains user-owned.
- must not ask: no repeated approval for this already authorized review or deterministic scoped checks; no comprehension quiz, model experiment, installation scan, or unrelated improvement.
- required artifacts: this single completed source-only record. No installed-project state or historical record changes.
- acceptance criteria: clear audience/problem and first action; formal Work/Reviewer usage preserved; general prompt usable for any task size, adaptive rather than format-bound, preserving outstanding intent and honest evidence; explicit limits on persistence, independent verification, learning, parity, and performance claims.
- verification oracle: source/base Git diff, README-alone cold-reader and copy/paste traces, directly connected contracts and Golden Core fixtures, development validation, and post-stage release-evidence plus full validation fixtures. Static checks are not evidence of live model compliance.

## Core Result

| Metric | Value | Evidence |
|---|---|---|
| accepted | yes | contract_trace + human_judgment: the exact README-only candidate meets the bounded documentation oracle; no actionable finding in the ten-lens review. |
| quality floor passed | pass | contract_trace: no scope/authority/installation regression or unsupported measured-outcome claim; automated development validation and the complete 259-assertion post-stage fixture suite passed. Release-evidence validation is the separate record-eligibility gate below. |
| intent/scope convergence + contract equivalent | pass | contract_trace: base `7ea011ec1a6cdeac0caf446ca78cfbab14ddc06d` to source changes only README.md, 37 additions/53 deletions; formal `## 사용법` body is identical after newline normalization; seven prompt principles retain intent, pending work, scope, and completion boundaries. |
| lowest-sufficient Architecture baseline / executable backbone vs empty scaffold / local-change proportionality | pass | contract_trace: README basic loop and detailed Architecture explanation retain lowest-sufficient design and a real first vertical Task; Golden Core Fixture 25 and ARCHITECTURE contract agree. This local documentation change adds no design artifact or runtime phase. |
| integrated existing behavior vs isolated skeleton | pass | contract_trace: no implementation or installed payload changed; the existing install and normal development loop remain intact rather than being replaced by the general conversation prompt. |
| route + artifact/state contract compliance | pass | contract_trace: BOOTSTRAP/WORK, OPERATIONS normal/issue routes, STATE recovery rows, and README name Work, independent Reviewer, READY/BLOCKED, Build Result, and generated DO_NEXT consistently. |
| reviewer independence | pass | contract_trace: this finalizer session did not author the source and inspected clean HEAD/tree before writing the record; no same-session author PASS or earlier Eval was inherited. |
| intent-gap + decision clarity / current-design-altitude fit / unnecessary questions or gates / informed assent vs surrender | pass | contract_trace + human_judgment: prompt principles 1, 2, 4, and 6 preserve supplied goals and remaining requests, show material alternatives/tradeoffs, proceed with authorized work, and restrict short assent to a clear scope; confusion/surrender is not approval. Golden Core Fixtures 1 and 18 provide inverse scenarios. |
| user-language approval and blocker actionability | pass | contract_trace: Korean README identifies same-Work initialization recovery, same-Reviewer manual evidence replies, and exact Operations recovery prompt; ACTION_CARDS User Action and OPERATIONS retain steps, evidence, reply, and fallback. |
| scan-first result/source/evidence/next composition / bounded expert-note grounding and fatigue | pass | human_judgment: audience and two use routes precede the formal quick start; prompt principle 3 answers the current question with causal explanation and useful source anchors, while principle 7 rejects a compulsory recurring report. No fixed answer length, class, quiz, or learning claim is introduced. |
| continuous Architecture-to-Builder-to-Review source truth / direct Diff inspection / durable-pause usefulness | pass | contract_trace: the unchanged formal usage body retains Builder source orientation, exact reviewed Diff, Source Map pointer, and explicit opt-in pause; ACTION_CARDS Code walkthrough and Golden Core Fixture 26 agree. No actual user comprehension was measured. |
| reference role/scope/fit/non-copy/re-check discipline | pass | contract_trace: prompt principle 2 uses official material/precedent/principles proportionally and reuses still-applicable evidence; the formal detailed reference explanation remains unchanged and agrees with Architect Decision evidence ladder and Golden Core Fixture 27. |
| verification cadence / distinct evidence per repeated check | pass | contract_trace: one development validator checked source structure; focused read-only extraction checked formal-section preservation and prompt shape; qualitative scenarios checked meaning. One complete post-stage full fixture run passed; two environment-aborted attempts are disclosed below, not counted as complete runs or duplicated successful evidence. |
| verification-claim accuracy | pass | contract_trace: README explicitly distinguishes prompt-only conversation from file-backed state, sealed Git identity, and independent Review, and disclaims guaranteed model equality or omission prevention. This record claims static source regression only. |
| simplicity / reuse without safety loss | pass | human_judgment: the general prompt moves behind a top-level navigation link and uses seven adaptive principles, while the complete formal path remains available; no new runtime rule, file, gate, or fixture was added. |
| human corrections | not_measured | No live user/model interaction study was performed. The review required no source correction; this is not a zero-human-correction productivity claim. |
| attempts / review cycles | one independent source review | contract_trace: one frozen first-pass ten-lens report and one bounded self-check, with one disclosed canonical-enum serialization correction and no source or verdict correction; project Build/Review cycles were not exercised. |
| elapsed time | not_measured | No comparative timing instrument or accepted-result baseline was used. Command runtimes do not establish Workflow speed. |
| tokens: input / cached / output / total-to-accept | not_measured | No observed usage metadata or comparative run; no token-saving inference. |
| initial/expanded context + expansion reason | bounded changed-mode review | contract_trace: README/diff, release/review instructions, Scorecard/catalog, and directly connected bootstrap, role, authority, state, action-card, recovery, and Golden Core sections were read to establish onboarding, intent, permission, evidence, and continuation boundaries. No installation root or project ledger was read. |

## Targeted Regressions

All cases below are source contract/scenario results. They do not assert that any model followed the prompt in a live task.

| Case | Result | Evidence |
|---|---|---|
| variable-detail-request | pass | contract_trace: Golden Core Fixture 1 traced against README introduction and prompt principles 1/4/6/7. Short and broad seeds need no form; partial satisfaction retains the other request; an informational question is answered without becoming a change; addressed intent changes do not erase unrelated work; transferred summaries include pending/follow-up/excluded items. |
| architecture-gate | pass | contract_trace: Golden Core Fixture 18 A-D against prompt principle 6 and unchanged formal Architecture/choice explanation. Authorized reversible work proceeds; a real user-owned outcome gets alternatives and prior approval; concise assent binds only a clear target; explicit confusion/surrender is rejected as approval. |
| lowest-sufficient-architecture-baseline | pass | contract_trace: Golden Core Fixture 25 and ARCHITECTURE baseline rules compared with README basic loop/detailed Architecture paragraph. Local/mechanical work avoids whole-project design; a new foundation starts with an executable vertical path, not empty scaffolding. |
| continuous-source-truth | pass | contract_trace + human_judgment: Golden Core Fixture 26 compared with unchanged formal code-orientation/Review steps and prompt principles 3/5/6. Explanation adapts to the question and preserves cause/evidence; source visibility is not replaced by a short summary; assent/length/tests do not prove learning. |
| reference-role-and-fit | pass | contract_trace: Golden Core Fixture 27 compared with Architect Decision evidence ladder and the unchanged formal reference paragraph. Approved behavior scope, precedent, official standards, and transferable principles remain distinct; the general prompt's research/reuse guidance does not override intent or create research ceremony. |
| repository-trust-boundary | pass | contract_trace: Golden Core Fixture 8 and ARTIFACT_AUTHORITY Repository trust boundary retain their safe/inverse execution routes; prompt principle 5 explicitly denies instructions in supplied material authority to change the user request, and principle 6 preserves prior approval for new external/irreversible effects. No prompt was executed as repository authority. |
| compact-independent-reviewer | pass | contract_trace: README quick-start windows and code fences match BOOTSTRAP Session topology and WORK Continuous route; Work excludes Reviewer and stops for the separate Reviewer. The optional general prompt explicitly does not create independent verification. |
| first-user-message-install | pass | contract_trace + human_judgment: README IMPORTANT says each Bootstrap is the unchanged first user message in a fresh session, not system/custom instructions or a shell command; Work initialization precedes Reviewer. The separate general prompt clearly belongs in a new conversation, not either formal role's Bootstrap. |
| source-install-boundary | pass | contract_trace: README NOTE/WARNING copy only .ai including MIT notice when absent; an existing release.yaml routes Check/Apply, and an unrelated .ai is not merged. Source tools/evals/maintenance/Git remain distribution-owned. |
| readme-progressive-disclosure | pass | human_judgment + automated: bounded cold-reader trace below answers all six questions without another document; formal/general anchor targets and links pass development validation. Optional procedures remain collapsed; formal usage extraction matches the base exactly after newline normalization. |
| user-command-discoverability | pass | contract_trace + human_judgment: visible quick start and common copy/paste tables still identify the receiving session, generated DO_NEXT, status, source inspection, Knowledge update, and recovery; generated cards are not user-authored commands. The two use routes are linked before detailed internals. |
| workflow-review-procedure | pass | contract_trace: current source-only procedure applied in changed mode with ten judgments, README gate, evidence labels, one bounded self-check, honest activation limits, and no source edits. This report is independent from source authoring and bound to the exact source commit/tree. |
| eval-release-evidence | pass | contract_trace: current SCORECARD/schema/catalog followed; all 13 named cases are pass, P2 count is zero, older records are untouched, and current source identity is independently recorded. The prior manual-v1.5 record points to another commit and is not evidence for this README. Post-stage tracked/current-source eligibility is checked by the mandatory validator. |

## Workflow Review

```text
WORKFLOW_REVIEW RESULT=pass
mode=changed workflow_version=manual-v1.5
source=92759c8e7a7c12fe9ba5df0571d059cc29c44543 reviewed=README.md plus directly connected contracts and source-only review/eval procedures
automated=pass regression=pass
findings=P1:0,P2:0,P3:0
independence=independent_session
self_check=corrected corrections=1
budget=pass slack=work+architect:180,work+builder:759,work+knowledge:1374,reviewer:1181 activation=not_available
release_recommendation=not_ready
```

The first-pass report was frozen before creating this record. `not_ready` is the expected publication-evidence gate at that point: a current-source completed staged Eval and its post-stage commands did not yet exist. It is not a Workflow defect. One later serialization correction removed explanatory prose from the canonical recommendation enum line and retained that explanation here; all lens judgments, findings, and source identity remained unchanged. The finalization checks below report later gate outcomes separately. Automated PASS in the frozen review refers to the executed development validator; regression PASS refers to the affected static contract/scenario traces, not live model behavior.

| Lens | Result | Evidence |
|---|---|---|
| 1 | PASS | human_judgment: README first visible prose identifies developers who want to inspect changed code and judgment evidence, the Work/Reviewer split, durable files/Git, small verified changes, and consequential human control. The repository is a workflow, not a model-performance guide. |
| 2 | PASS | human_judgment + contract_trace: README-alone cold-reader trace answers install payload, first message, session order, READY/initialization/BLOCKED, Review transport/recovery, and advanced navigation. Intro/routing are shorter without removing first-success information. |
| 3 | PASS | contract_trace: the entire formal usage section is preserved; README loop/detailed flow connects request, bounded design/approval, vertical Build, independent Review, repair/PASS, Knowledge/checkpoint, continuation, and Feature convergence. Optional Integration remains separate; OPERATIONS/STATE give the owners and resume paths. |
| 4 | PASS | contract_trace: BOOTSTRAP/WORK and README keep Work and independent Reviewer separate. Prompt principles 2/6 distinguish useful AI judgment from a necessary user-owned choice, require explicit bounded approval, reject confusion/surrender, and introduce no ceremonial repeat approval. |
| 5 | PASS | contract_trace: initialization failure returns to the same Work; implementation findings return to Builder/Work; structural/public-boundary findings to Architect/Work; malformed artifacts to their author; unavailable observation to the same Reviewer/user gate; ambiguous routing to the exact Operations prompt. STATE preserves phase/owner and distinguishes evidence-only from changed-byte resume, including Integration. |
| 6 | PASS | automated + contract_trace: development validation passed; exact source commit/tree and README-only diff were checked. Prompt/README claims distinguish facts, inference, proposal, recency, source access, and unavailable evidence. No live parity, speed, token, productivity, learning, or omission-proof result is asserted. |
| 7 | PASS | contract_trace: ARTIFACT_AUTHORITY and ARCHITECTURE Request continuity own facts/lifetimes and outstanding intent; prompt principles 4/5 align with them without inventing durable state. Formal file-backed restore and general prompt/summary transfer are visibly different. Supplied material cannot change authority. |
| 8 | PASS | human_judgment + automated: ordinary single-main one-Task route is unchanged; no added always-read file, user stop, role handoff, durable output stack, or runtime suite. General prompt adapts to task size and current explanation need, reuses still-applicable evidence, and stops at the requested outcome. Always-read totals/slack are measured below; no activation or productivity inference is available. |
| 9 | PASS | human_judgment + contract_trace: top use-route links lead to formal quick start or the relocated general prompt; detailed Worktree/strict/update/concept content remains on demand. Paths, role names, readiness states, generated cards, licensing, and canonical links remain consistent; the README is an action summary rather than a second runtime authority. |
| 10 | PASS | contract_trace: fresh/managed/unrelated installation boundaries and source-only maintenance stay intact. Prompt fact/permission principles preserve user intent and prior approval for new external/irreversible effects; repository trust, secrets, update containment, rollback, and immutable evidence remain with their unchanged canonical contracts. No supplied installation was read or changed. |

### README quality gate and cold-reader trace

All twelve README checks pass at the reviewed source: identity, differentiation, first action, session separation, success recognition, normal loop, failure recovery, progressive disclosure, contract accuracy, single source, terminology, and claims. This is a bounded readability/copy-paste judgment, not a usability study or proof of model behavior.

1. Repository/audience: first prose says developers can inspect changed code and decision evidence, using Work plus a separate Reviewer and file/Git state. The next four-row problem/experience table exposes the distinct mechanisms.
2. First file operation/message: quick start says copy only .ai (with MIT notice) to a project lacking .ai, open the project root, and paste the Work text fence. The existing-install/unrelated-directory warning precedes this operation.
3. Prompt/session: numbered steps and bold window labels assign Work first, Reviewer only after initialization, each in a separate new session with its Bootstrap as first user message. The general collaboration section is a separate navigation destination and explicitly lacks formal execution mechanisms.
4. Success/failure: the visible quick start says check READY; the expandable installation check shows `initialization=complete`, expected main lane/state files, and BLOCKED/missing-file recovery in the same Work before creating Reviewer. Inactive READY/wait is explicitly normal.
5. Work to Reviewer and return: the basic example gives `DO_NEXT session=reviewer` and the exact verification message; PASS provides verified source/Diff orientation and generated Work continuation. The detailed Review paragraph owns implementation/structure/artifact routes and same-Reviewer manual evidence. Operations recovery supplies a concrete prompt when owner/routing is unclear.
6. Optional/unusual paths: strict four-session prompts, situation-specific Worktree/Integration/close/recovery/update, conceptual detail, and maintainer links are collapsed under named summaries. The top two-route table reaches the general collaboration prompt directly without reading those sections.

The general copy block stands alone: opening intent plus seven bullets and a closing apply instruction, with no path placeholders, internal role command, mandatory reporting template, or hidden install dependency. Scenario interpretation preserves task-size freedom, questions versus action requests, partial satisfaction versus withdrawal, bounded assent versus surrender, references versus authority, and completion versus unrelated follow-ups. The factual limits outside the block do not promise the prompt can preserve unprovided chat history or independently verify its own work.

### Findings and retained mechanisms

No actionable findings. No source fix order is required. Keep the formal install/update warning, separate Reviewer, explicit generated handoffs, exact-source orientation, conditional consequential gates, request continuity, and honest prompt-only limits. They prevent concrete authority, loss, self-review, and false-evidence failures while the README presentation remains optional/on demand.

### Efficiency and observed activation

The base-to-source diff contains no Core or validator change. The ordinary single-main path therefore adds zero required files, user stops, handoffs, broad-suite runs, or runtime artifacts. The one broad suite in this finalization is an explicit source-publication gate, not a new per-Task rule.

Measured file-byte totals use the validator's exact entry sets: work+architect 62,284/62,464 (slack 180); work+builder 50,441/51,200 (759); work+knowledge 43,682/45,056 (1,374); reviewer 50,019/51,200 (1,181). All pass. These bound entry loading only, not total run context, and the README-only change leaves them unchanged.

Observed activation: `activation=not_available`. No installation roots or accepted-Task ledger window were supplied/read. Window size and field coverage are unavailable; no measured zero-activation rule is reported and no deletion is proposed on missing evidence. Main/lane/no-Git closure distributions, optional-card use, blockers, unsuccessful/unfinished work, retry cost, whole-project productivity, learning, and Integration execution remain not_measured/not_observed as applicable, not zero. Rare safety/recovery mechanisms are retained for their named authority/loss/candidate risks.

### Bounded self-check

One first-pass report was frozen, then checked once. Its only recorded correction is canonical-enum serialization, caught by the later record validator; there was no second source-review/self-check cycle:

- coverage: all ten lenses judged; initialization, preflight, Build/Review, inspection, and Integration blocker owners and resume boundaries traced through README/OPERATIONS/STATE.
- evidence: no P1/P2/applicable FAIL requires an unsupported finding; static, automated, human-judgment, and unverified claims remain labeled.
- inverse: intentional progressive disclosure, the expected pre-Eval release gate, safe BLOCKED recovery, and unmeasured prompt outcomes were tested as non-defect explanations; none became a finding.
- miss: normal versus Integration recovery, runtime versus source-only maintenance, installation versus distribution, and unchanged evidence versus changed candidate bytes retain distinct authority and resume paths.
- consistency: ten PASS rows, zero findings, PASS quality, independent source identity, and temporary not_ready publication status agree. The canonical footer now contains only the valid recommendation enum; its explanation remains in prose instead of sharing that parsed field.
- scope: the review changed no file; only the subsequent authorized finalizer creates this record. No source repair, installed-project access, comparison, model parity, or learning proof is invented.

Unverified: live model compliance, cross-model equivalence, learning, omissions, productivity, token/time improvements, rendered-host behavior, and remote CI. Matching text/links and qualitative cold-reading do not establish these outcomes. No external research was needed to review this local documentation/contract delta, and no new self-check criteria were adopted.

- self-check: corrected
- corrections: one serialization correction; the first record validator rejected extra prose after the recommendation enum, so the line was normalized to exact `not_ready` and the explanation retained separately. No source finding, lens result, recommendation meaning, or authority changed.
- release recommendation: not_ready
- findings: P1:0, P2:0, P3:0
- deferred P2: none

## Finalization checks

- automated development check: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/validate-workflow.ps1` exited 0 with `PASS workflow=manual-v1.5 markdown=56 references=335 release_evidence=not_required eligible_current_evals=0`. Zero current Evals was expected before this record existed.
- automated focused checks: compared base/current complete formal usage sections after newline normalization (equal); extracted the general prompt's single text fence (seven principles); measured every always-read set from current validator path/ceiling definitions (all pass).
- source identity: clean status before record creation, HEAD `92759c8e7a7c12fe9ba5df0571d059cc29c44543`, tree `3a385a461b78c9f18e50815e4e635a96ae8a2235`, branch `docs/readme-first-page`; only source delta from base is README.md. Existing v1.5 annotated tag object `7f1a99ce8d4bc592f9c13dd7c708880e078d02e3` peels to `7ea011ec1a6cdeac0caf446ca78cfbab14ddc06d` and is not modified.
- mandatory post-stage fixture check: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/test-validation.ps1` completed with exit 0 and all 259 declared assertions passing, from `fixture-baseline` through `always-read-budget-exceeded`. This is one complete successful suite, not 259 functional product tests or live model trials.
- resolved test-environment setup: two earlier attempts ended with `Copy-Item` DirectoryNotFoundException while constructing temporary fixtures, first under the sandbox-expanded temp prefix and then under normal per-user Temp at a longer fixture name. Neither was a complete suite or fixture PASS. The unchanged script then passed using a unique short process-scoped temp root; read-only preflight bounded the longest constructed copy path at 250 characters (maximum fixture name 60 and copied relative path 106). Original TEMP/TMP were restored, and exact-root-validated cleanup removed only that disposable fixture tree. No registry, Git configuration, script, or source change was made.
- initial post-stage release-evidence check: exited 1 because the recommendation footer included explanatory prose instead of the exact parsed enum; the secondary no-eligible-Eval message followed that record-shape error. The one serialization correction above addresses it; this was not a source-quality finding.
- final staged release-evidence check: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/validate-workflow.ps1 -RequireReleaseEvidence` exited 0 with `PASS workflow=manual-v1.5 markdown=57 references=335 release_evidence=required eligible_current_evals=1` after the corrected record was staged. The finalizer rechecks that staged eligibility after appending this observed outcome; the full fixture suite is not repeated because its source/oracles are unchanged and its fixture loader excludes source Eval records.
- local finalization disposition: required source-review, affected static regressions, full fixtures, and staged release-evidence eligibility pass. Commit, remote CI, merge, and publication remain outside this record's authority; the frozen pre-record `not_ready` recommendation is not silently rewritten into remote success.
- environment: Windows local checkout; required validation uses Windows PowerShell 5.1.26100.9711, while read-only orchestration commands used available PowerShell 7.6.5. Existing fsmonitor IPC diagnostics were observed; configuration was preserved and command exit/result was checked rather than suppressing the warning.

## Failure

- stage: no source-review or affected static-regression failure; two resolved fixture-copy environment failures and one resolved new-record serialization rejection.
- cause: long temporary copy paths in the environment-aborted attempts; extra explanatory prose in a canonical enum field for the record rejection. Neither required a source change.
- evidence: initial command errors, successful unchanged short-temp full suite, and the disclosed footer normalization above. Final release eligibility is checked only against the staged corrected record; an earlier failure is not relabeled as PASS.

## Decision

- keep/change: keep the README candidate unchanged. Leave one sanitized source-only Eval for human review and a separate evidence commit; no version/Changelog/tag/runtime-rule changes. No commit, Push, merge, PR, or other remote mutation is authorized to this finalizer.
- regression cases: exactly the 13 canonical IDs in front matter and Targeted Regressions; all pass as bounded source-contract/scenario checks, not live performance or learning evidence.
