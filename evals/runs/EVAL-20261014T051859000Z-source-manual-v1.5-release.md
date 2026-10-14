---
schema_version: 2
id: EVAL-20261014T051859000Z-source-manual-v1.5-release
date: 2026-10-14
status: completed
result: pass
completed_at: 2026-10-14T05:18:59.000Z
source_revision: ce0653f6273d13d48cb7d78ea3dc5f0d049b5eef
source_tree: a013a947d8fc2b309520fb8d1785564dd6732eea
quality_floor: pass
seed: "Finalize manual-v1.5 at clean immutable HEAD, changed mode against v1.4, independent source-only contract regression without source edits or publication"
lane: source
provider: codex
host_tool: codex-desktop
model: not_measured
reasoning: not_measured
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
  - requirement-drift-routing
  - task-quality-gate
  - architecture-gate
  - lowest-sufficient-architecture-baseline
  - multi-task-just-in-time
  - handoff-deduplication
  - pending-user-input-resume
  - proportional-verification-cadence
  - intent-anchored-bounded-diagnosis
  - intent-gap-first-brief
  - continuous-source-truth
  - diff-first-code-ownership
  - readable-atomic-decision
  - behavior-change-brief
  - mechanical-change-brief
  - glossary-grounding
  - session-tool-model-replacement
  - bootstrap-only-replacement
  - compact-independent-reviewer
  - strict-four-session-topology
  - inactive-role-readiness
  - task-state-authority
  - artifact-state-conformance
  - workflow-artifact-write-scope
  - evidence-based-code-quality
  - terminal-no-knowledge-transition
  - review-route-conformance
  - pass-route-branching
  - single-main-candidate-fingerprint
  - state-fsm-completeness
  - review-repair-resume
  - integration-blocked-resume
  - sealed-candidate-identity
  - main-front-desk-cycle
  - non-main-session-replacement
  - session-close-checkpoint
  - post-integration-lane-continuation
  - artifact-authority-single-source
  - issue-routing-single-source
  - state-contract-authority
  - role-output-contract-loading
  - safe-update
  - update-path-containment
  - local-update-state-scaffold
  - migration-sparse-compatibility
  - distribution-inventory-validation
  - source-install-boundary
  - user-command-discoverability
  - readme-progressive-disclosure
  - workflow-review-procedure
  - source-validation
  - eval-release-evidence
  - eval-case-catalog-traceability
  - historical-record-integrity
  - publication-boundary
  - windows-powershell-default
  - local-vs-remote-ci-claim
  - scorecard-template-version-authority
---

# Workflow Eval

이 기록은 immutable source의 계약 및 결정적 회귀 증거다. live provider/model 행동·생산성·이해·학습·token/time savings·실용 동등성을 측정하거나 보증하지 않는다. provider/host는 실행 환경 provenance이고 관찰 가능한 model/effort usage metadata가 없어 not_measured로 둔다. 사용자 경로·프로젝트 정보·전체 로그·설치물 기록을 포함하지 않는다.

## Oracle

- expected route: independent clean-HEAD Workflow Review → affected source regressions → completed source-only Eval 하나 → 이 파일만 stage → 실제 source -RequireReleaseEvidence 및 tracked-clone final test-validation → eval_commit_required.
- architecture gate: none; source authoring/version change/추가 runtime Gate 권한이 없다.
- must ask: source/independence/candidate identity conflict가 있어 안전한 증거를 만들 수 없을 때만 기존 owning repair로 중단한다.
- must not ask: 승인된 deterministic 검사·격리 fixture·정식 Eval staging에 반복 확인을 요구하지 않는다.
- required artifacts: source-only evals/runs/의 이 기록 하나; completed historical Evals와 installable .ai source는 수정하지 않는다.
- acceptance criteria: v1.4..HEAD의 25 changed paths 및 연결된 계약 검토, no P1/applicable FAIL, detailed finding/deferred P2 정합성, 모든 named canonical case pass, exact source revision/tree/version, independent review 및 한 bounded self-check, quality floor.
- verification oracle: Windows PowerShell 5.1 scripts와 Golden contract traces, README-only human judgment를 각각 구분한다. source_regression의 narrative case pass는 source/정적 oracle 일관성을 뜻하며 실제 모델이 이를 실행했다는 뜻이 아니다.

### Source scope inventory

comparison_base=v1.4 (21856414682fb2da56b56cbfcbd50dc96edd82f6). source metadata는 manual-v1.5 / 2026-10-14 / release_ref v1.5이며 Changelog entry가 일치한다. 아래는 git diff --name-only v1.4..source의 전체 25 paths다.

```text
README.md
.ai/BOOTSTRAP.md
.ai/WORKFLOW.md
.ai/contracts/ACTION_CARDS.md
.ai/contracts/ARCHITECTURE.md
.ai/contracts/ARTIFACT_AUTHORITY.md
.ai/contracts/SESSION_CLOSE.md
.ai/contracts/STATE.md
.ai/contracts/TASK_RECORD.md
.ai/evals/GOLDEN_CORE_BEHAVIOR.md
.ai/evals/README.md
.ai/evals/SCORECARD.md
.ai/maintenance/CHANGELOG.md
.ai/maintenance/managed-paths.yaml
.ai/maintenance/release.yaml
.ai/maintenance/update-state.template.yaml
.ai/maintenance/update-state.yaml
.ai/reference/OPERATIONS.md
.ai/roles/ARCHITECT.md
.ai/roles/BUILDER.md
.ai/roles/REVIEWER.md
.ai/roles/WORK.md
maintenance/WORKFLOW_REVIEW.md
tools/test-validation.ps1
tools/validate-workflow.ps1
```

연결된 authority/output/recovery 계약은 .ai/contracts/BUILD_RESULT.md, REVIEW_RESULT.md, MAIN_DESK.md, KNOWLEDGE.md, PARALLEL_START.md와 .ai/roles/KNOWLEDGE_MAINTAINER.md, .ai/integration/README.md, .ai/integration/queue.yaml, .ai/shared/SYSTEM_ARCHITECTURE.md, .ai/lanes/_template 및 .ai/maintenance/UPDATE.md, .ai/maintenance/MAINTAIN.md, .ai/maintenance/distribution-inventory.txt, source-only maintenance/RELEASE.md/evals/README.md, Golden Worktree Lifecycle이다. 변경된 부분의 입력/쓰기/authority/state/terminal output 경계까지 비례적으로 추적했다.

### Automated evidence and containment

| Check | Observed result | Boundary |
|---|---|---|
| powershell -NoProfile -ExecutionPolicy Bypass -File tools/validate-workflow.ps1 (실제 source) | exit=0; PASS workflow=manual-v1.5 markdown=55 references=299 release_evidence=not_required eligible_current_evals=0 | record 생성 전 clean source 검증. eligible=0은 pre-Eval publication gate이며 source defect가 아니다. |
| powershell -NoProfile -ExecutionPolicy Bypass -File tools/test-validation.ps1 -RepositoryRoot <tracked-clone> | exit=0; 정상 12 + 역방향 247 = 259/259 PASS; 439.1 seconds | clone은 frozen commit의 tracked 77 files와 Git graph만 포함. isolated temp에 synthetic mutations/commits/Evals 생성. |
| powershell -NoProfile -ExecutionPolicy Bypass -File tools/compare-validation.ps1 -RepositoryRoot <separate-tracked-clone> -Baseline <exported-v1.4-validator> -VerifySample 12 | baseline_tokens=680 current_tokens=685; enforced=678 dropped_protection=0 wording_drift=0 enforcement_ended=2 missing_file=0; dynamic_verified=12 dynamic_failures=0; exit=0 | 동적 토큰 변형은 별도 clone에서만 실행하고 finally로 원래 byte를 복구했다. |
| preserved-local-staging positive fixture | pass; fixture staging file exists and SHA256 before=after | 실제 ignored 기록을 가져오지 않고 synthetic local staging만 생성했다. |
| source identity/inventory guard | original tracked=77; clone tracked=77; differences=0; source clean; exact HEAD/tree unchanged | 원본 source와 역사적 Eval 수정 없음. clone의 untracked/ignored payload 수는 0이다. |

enforcement_ended 두 건의 human decision (contract_trace + human_judgment):

- STATE의 이전 emit no DO_NEXT yet는 emit no continuation DO_NEXT yet로 재보호됐다. ACTION_CARDS#intake-only-transport만 exception이고 모든 state/wait/accepted identity 및 suspended generic routes를 그대로 보존한다. 기존 code-inspection guards와 intake-clears-inspection-wait 역방향 fixture가 통과했다. deliberate narrowing이며 보호 중단이 아니다.
- WORK의 이전 terse token non-mutating 제한은 표시된 unambiguous semantic action의 권한으로 정정됐다. ACTION_CARDS의 decision-ready outcome/scope/checkpoint/hook 규칙은 그대로고 undisclosed action/Review bypass/Push는 허용하지 않는다. overbroad-concise-assent-rejected, surrender-treated-as-product-approval, compound-checkpoint-continuation-choice가 통과했다. deliberate correction이며 단축 응답을 무제한 권한으로 만들지 않는다.

첫 whole-suite 실행은 긴 temporary fixture path의 Windows Copy-Item 경로 제한으로 10항목 뒤 중단됐다. 후보를 바꾸지 않고 더 짧은 isolated temp root로 전체를 다시 실행해 위 PASS를 얻었다. 이는 harness 환경 실패이며 실패한 모델/Task run이나 source 계약 결함으로 집계하지 않는다. scripts는 canonical tracked bytes 그대로 사용했다. fixtures의 Git hooks를 비활성화했고 외부 network/credential/secret을 사용하지 않았다.

이 completed record는 위 source-quality 증거에 기초한다. stage 후 actual repository의 tools/validate-workflow.ps1 -RequireReleaseEvidence와 동일한 tracked-plus-this-staged-Eval clone의 tools/test-validation.ps1을 finalizer가 실행한다. 그 release-gate 결과와 최종 staged path/source invariance는 chat의 FINALIZE_RELEASE_EVAL 결과에 별도로 보고하며 completed evidence를 나중에 다시 쓰지 않는다.

## Core Result

| Metric | Value | Evidence |
|---|---|---|
| accepted | yes | contract_trace: frozen source를 독립 검토해 source-regression 품질을 수용했다. 이는 사용자 release 승인이나 실제 모델 결과 수용을 뜻하지 않는다. |
| quality floor passed | pass | automated + contract_trace: 259/259 fixture checks, guard comparison PASS, P1/P2 및 applicable FAIL 없음. P3 annotation은 현재 quality floor를 깨지 않는다. |
| intent/scope convergence + contract equivalent | pass | contract_trace: request continuity, approved Scope/Task, requirement drift, Feature convergence를 Golden Core Fixtures 1/4/7로 연결했다. partial success/proposal은 다른 요청의 철회/승인이 아니다. |
| lowest-sufficient Architecture baseline / executable backbone vs empty scaffold / local-change proportionality | pass | contract_trace: ARCHITECTURE/Task Quality Gate와 Fixtures 6/25; 중복 role 설명의 위임 뒤에도 owner/flow/exit/oracle와 executable backbone 조건이 남는다. |
| integrated existing behavior vs isolated skeleton | pass | contract_trace: 기존 Architecture/Task/Build/Review/state와 현재 lifecycle 경로를 확장했다. 새 역할/산출물/schema나 분리된 runtime skeleton을 만들지 않았다. 실제 product integration은 미실행이다. |
| route + artifact/state contract compliance | pass | automated + contract_trace: schema/enums/structural FSM 검사와 OPERATIONS owner table. intake는 상태 전이나 일반 continuation이 아니다. |
| reviewer independence | independent_session | contract_trace: 이 세션은 v1.4..HEAD 후보 source authoring에 참여하지 않았으며 clean frozen full commit을 독립 검토했다. source author의 hidden reasoning을 evidence로 사용하지 않았다. |
| intent-gap + decision clarity / current-design-altitude fit / unnecessary questions or gates / informed assent vs surrender | pass | contract_trace + human_judgment: Fixtures 1/18/21/22/25; 정보 질문/행동 요청/제안/승인을 구분하고 existing one-outcome authority와 설명을 유지한다. 실제 사용자 의사결정 성과는 미측정이다. |
| user-language approval and blocker actionability | pass | contract_trace: README의 한국어 시작/회복 예시와 BOOTSTRAP user_language/USER_ACTION/EDITOR_CHECK. 이 finalization의 chat/report는 ko이며 artifact keys/enums는 기존 English contract를 쓴다. |
| scan-first result/source/evidence/next composition / bounded expert-note grounding and fatigue | pass | contract_trace + human_judgment: ACTION_CARDS, Fixtures 18/26. current causal gap을 다루고 source/cause/consequence를 유지하며 full inventory/quiz/고정 길이 quota를 강제하지 않는다. 실제 피로/이해는 not_measured다. |
| continuous Architecture-to-Builder-to-Review source truth / direct Diff inspection / durable-pause usefulness | pass | contract_trace: BUILD_RESULT의 단일 map, REVIEW_RESULT의 검증 pointer, Fixture 20 및 Fixture 1 intake-wait variant. opt-in revalidatable wait는 유지하고 no-Git/Integration pause를 invent하지 않는다. 실제 pause usefulness는 미측정이다. |
| reference role/scope/fit/non-copy/re-check discipline | pass | contract_trace: ARTIFACT_AUTHORITY와 ARCHITECT#decision-evidence-ladder; approved behavior scope, precedent, standards, implementations의 권한 구분을 보존한다. 기존 계약과 source facts로 충분해 외부 research를 새로 실행하지 않았다. |
| verification cadence / distinct evidence per repeated check | pass | automated + contract_trace: 실제 source 구조 검사, isolated 전체 inverse suite, v1.4 guard comparison은 서로 다른 실패를 검사한다. 첫 suite는 Windows 경로 길이로 10항목 뒤 중단됐고 짧은 temp로 259/259 완료했다. stage 뒤 release gate/절차상 최종 suite를 확인한다. runtime cadence oracle는 Fixture 24다. |
| verification-claim accuracy | pass | contract_trace + human_judgment: .ai/evals와 STATE/WORKFLOW_REVIEW의 accepted-window/field-coverage 제한을 적용했다. static PASS, qualitative 문서 trace와 live/model 비교를 구분했다. |
| simplicity / reuse without safety loss | pass | contract_trace: 새 managed file/role/record schema/gate 없이 기존 artifacts를 사용한다. source visibility, fixed invariants, post-handoff identity, reviewed evidence lifetime, update containment를 보존한다. |
| human corrections | not_measured | unverified: 실제 모델/사용자 delivery transcript 또는 이해도 관찰을 수행하지 않았다. 이 reviewer가 temp path를 바로잡은 것은 product 사용자의 correction count가 아니다. |
| attempts / review cycles | source_review: 1; runtime: not_measured | contract_trace: independent Workflow Review와 frozen-draft self-check 각 1회. automated harness의 경로 실패/재실행은 별도 환경 기록이며 runtime Task Build/Review retry 수가 아니다. |
| elapsed time | not_measured | unverified: live accepted-result 시간은 측정하지 않았다. 439.1 seconds는 첫 성공 자동 fixture harness 시간만이며 Workflow/model 생산성 비교에 사용하지 않는다. |
| tokens: input / cached / output / total-to-accept | not_measured | unverified: provider usage metadata/comparative setup이 없다. Git/file byte budget을 token 수나 savings로 변환하지 않는다. |
| initial/expanded context + expansion reason | 25 changed paths + linked contracts | contract_trace: changed mode에서 source diff와 authority/state/role/output·Golden·maintenance 계약만 확장했다. ignored 로컬 기록/설치 source/historical Eval 전체를 preload하지 않았다. 읽기 예산은 exact entry-file bytes로 따로 보고한다. |

## Targeted Regressions

front matter의 59 canonical case만 아래에 기록한다. 모두 source_regression 범위의 pass이며 model/사용자/live product behavior의 pass로 확대하지 않는다. static fixtures는 보호 규칙을 검사하고 narrative Golden cases는 계약/시나리오 trace와 human judgment로 평가했다.

| Case | Result | Evidence |
|---|---|---|
| variable-detail-request | pass | contract_trace: Golden Core Fixture 1과 ARCHITECTURE#request-continuity. 정렬의 부분 성공 뒤에도 focus 요청과 이유가 남고, 검색 기능의 정보 질문/AI 제안은 승인된 Scope가 되지 않는다. 질문형 행동 요청은 의미로 분류한다. automated: captured-request-becomes-approval, partial-success-withdraws-outstanding-request. |
| requirement-drift-routing | pass | contract_trace: Golden Core Fixture 7, ARTIFACT_AUTHORITY#conflict-actions, REVIEWER#Review. 미접수 사용자 변경과 무단 편집을 구분하고 Architect가 승인된 Architecture/Task를 조정한다. 미해결 drift는 PASS를 막고 completed evidence는 보존한다. |
| task-quality-gate | pass | contract_trace: TASK_RECORD의 여덟 READY 조건과 Golden Core Fixture 6. 승인 의도→slice→AC→verification을 연결하고 SPLIT/MERGE는 내부 판단이며 BLOCKED는 기존 소유자로 간다. automated: missing-task-quality-gate, missing-vertical-slice-rule, unsafe-batching-gate-collapse 및 trivial-batch 역방향 검사. |
| architecture-gate | pass | contract_trace: ARCHITECT#approval-policy, ACTION_CARDS#readable-atomic-decisions, Golden Core Fixture 18. 결과가 다른 사용자 소유 선택만 묻고 혼란/포기는 승인으로 처리하지 않는다. automated: missing-gate-necessity-check, missing-decision-readiness-check, surrender-treated-as-product-approval. |
| lowest-sufficient-architecture-baseline | pass | contract_trace: ARCHITECTURE의 purpose/owner/flow/invariant/exit/proof/deferred frame, ARCHITECT의 위임, Golden Core Fixture 25. 실제 executable backbone에서 설계를 멈추고 로컬 변경은 전면 재설계하지 않는다. automated: missing-lowest-sufficient-architecture-baseline, empty-scaffold-declared-executable-backbone, architecture-continues-through-reversible-detail. |
| multi-task-just-in-time | pass | contract_trace: ARCHITECTURE#delivery-purpose-and-stop, WORK#continuous-route, Golden Core Fixtures 4/17. 현재 결과·필수 의존성·blocker만 다음 Task를 정당화하고 one_task는 무한 cleanup을 허용하지 않는다. automated: one-task-creates-unbounded-cleanup, nonblocking-discovery-becomes-task. |
| handoff-deduplication | pass | contract_trace: ACTION_CARDS#handoff와 Golden Core Fixtures 1/6. compact는 Work, strict는 Architect로 같은 Lane의 정확한 요청/근거/기존 pointer만 전달한다. 설명 질문은 현재 Reviewer에 남고 의존 Build를 승인 대기와 합치지 않는다. automated: unsafe-batching-gate-collapse, intake-clears-inspection-wait. |
| pending-user-input-resume | pass | contract_trace: STATE의 next.role/next.action 및 Golden Core Fixtures 1/16/20. 접수 응답은 inspected/continue 응답이 아니며 pending 승인/확인 owner와 route를 보존한다. automated: missing-code-inspection-state-transition, code-inspection-wait-bypassed-by-generic-route. |
| proportional-verification-cadence | pass | contract_trace: TASK_RECORD#reversible-tuning, BOOTSTRAP#active-delivery-kernel, Golden Core Fixture 24. tunable과 fixed default를 구분하고 비교에서 고정한 조건을 기록한다. 독립 invariant/default assertion을 유지하며 post-handoff 바이트 변경은 새 identity를 요구한다. automated: post-handoff-tuning-reuses-verdict, planned-editor-save-deferred-until-review, token-saving-skips-required-evidence. |
| intent-anchored-bounded-diagnosis | pass | contract_trace: OPERATIONS#bounded-diagnosis-during-active-delivery와 Golden Core Fixture 23. 정확한 의도/AC를 먼저 읽고 observed/inferred/confirmed를 분리하며 직접 blocker만 현재 작업을 중단한다. automated: diagnosis-skips-approved-intent, inference-declared-confirmed, unconfirmed-hypothesis-becomes-authority, delivery-focus-hides-blocker. |
| intent-gap-first-brief | pass | contract_trace: ACTION_CARDS#intent-gap-preface, ARCHITECT, Golden Core Fixture 22. specified/implementation_open/product_open/authority_unknown은 서로 다른 책임이며 current behavior→approved intent→gap이 먼저 온다. automated: specified-outcome-reasked, planning-silence-invents-visible-behavior, disproven-approach-remains-choice. |
| continuous-source-truth | pass | contract_trace + human_judgment: Golden Core Fixture 26, ACTION_CARDS#scan-first-composition, BUILD_RESULT#Source Map. 현재 질문의 causal gap을 다루고 튜닝 delta는 전체 inventory를 반복하지 않으며 source/evidence는 숨기지 않는다. 정적 oracle의 일관성만 PASS이며 실제 모델의 설명 성공/학습은 측정하지 않았다. automated: source-truth-deferred-until-review, scan-first-becomes-fixed-anchor-quota, action-cards-falls-back-to-whole-file-loading. |
| diff-first-code-ownership | pass | contract_trace: Golden Core Fixture 20과 Fixture 1의 intake variant. eligible Task wait는 그대로 유지하고 intake 전후 identity를 확인하며 후보/완료 Review를 기록 장소로 쓰지 않는다. no-Git/unsealed는 shown_no_pause, Integration은 not_applicable. automated: intake-clears-inspection-wait, no-git-code-inspection-repeat-wait, integration-review-code-inspection-pause, missing-code-inspection-attribution-recovery. |
| readable-atomic-decision | pass | contract_trace: ACTION_CARDS#readable-atomic-decisions 및 Golden Core Fixture 21. 짧은 동의는 표시된 한 행동의 권한만 가지며 required closure와 optional continuation을 합치지 않는다. automated: overbroad-concise-assent-rejected, fourth-viable-outcome-silently-dropped, compound-checkpoint-continuation-choice. |
| behavior-change-brief | pass | contract_trace + human_judgment: ACTION_CARDS#scan-first-composition/#bounded-expert-note, REVIEW_RESULT#Change Brief, Golden Core Fixture 18. 원인·결과·현 source·유용한 대안 차이를 남기며 혼란 신호는 설명을 조정한다. static consistency만 평가했고 실제 transcript/이해도는 미측정이다. automated: missing-bounded-expert-note-contract, expert-note-obscures-core-action, missing-readable-learning-oracle. |
| mechanical-change-brief | pass | contract_trace: Golden Core Fixtures 18/26, REVIEW_RESULT의 none 조건, ACTION_CARDS. 단순 응답·기계적 변경은 의미 없는 전체 설명/코드 확인 대기를 만들지 않고 required terminal schema는 해당 경계에 남는다. automated: overbroad-mechanical-code-inspection-pause. |
| glossary-grounding | pass | contract_trace + human_judgment: Golden Core Fixture 18, BOOTSTRAP의 adaptive depth, ACTION_CARDS의 evidence-calibrated language. 역할에 연결된 쉬운 의미를 먼저 설명하며 임의 전문 용어/영구 숙련도 profile을 만들지 않는다. 이해·학습 성과는 미측정이다. automated: missing-just-in-time-term-rule, missing-observable-unchanged-baseline. |
| session-tool-model-replacement | pass | contract_trace: SESSION_CLOSE, MAIN_DESK#front-desk-recovery, Golden Core Fixtures 14/19 및 Worktree Case 7. 동일 identity와 durable pointer로 pending disposition/inspection wait를 복원하고 변경 identity는 기존 Front Desk route로 간다. automated: unpersisted-intake-declared-recoverable, missing-session-recovery-oracle, missing-code-inspection-session-recovery, missing-session-age-inverse-guard. |
| bootstrap-only-replacement | pass | contract_trace: BOOTSTRAP#readiness-vs-activation와 Golden Core Fixture 14. Bootstrap은 readiness만 복원하고 init 예외/명시적 out-of-route intake 외 현재 작업을 자동 실행하지 않는다. automated: missing-same-lane-resume-boundary, missing-front-desk-chat-independent-recovery. |
| compact-independent-reviewer | pass | contract_trace: BOOTSTRAP#session-topology, WORK의 reviewer stop, REVIEW_RESULT#reduced-assurance-exception 및 Golden Core Fixture 12. Work는 Knowledge/Architect/Builder shell이며 별도 Reviewer를 실행하지 않는다. automated: independent-reviewer-context-starved, missing-reduced-assurance-entry-rule. |
| strict-four-session-topology | pass | contract_trace: README의 strict prompts, BOOTSTRAP의 fixed-role identity 및 Worktree Cases 1/7. Architect만 Architecture를 쓰고 fixed Builder/Reviewer의 intake는 transport만 수행한다. strict topology가 main Front Desk 권한을 바꾸지 않는다. |
| inactive-role-readiness | pass | contract_trace: BOOTSTRAP와 Golden Core Fixture 3. 미래 input이 없는 inactive fixed role은 READY/wait이고 current routed input의 실제 오류만 BLOCKED다. intake는 durable route 변경이나 가상 role이 아니다. automated: missing-role, invalid-template-state. |
| task-state-authority | pass | contract_trace: TASK_RECORD의 approval status와 STATE의 execution pointers. 새 요청/튜닝도 approved Task 상태에 실행 진도를 복제하지 않으며 완료 evidence를 다시 쓰지 않는다. automated: legacy-template-state-key, invalid-template-state. |
| artifact-state-conformance | pass | automated + contract_trace: validator의 schema/enum/FSM 검사, STATE 및 release compatibility. lane=3/state=3/knowledge=2/maintenance=1/eval=2와 네 AI next.role을 유지한다. request disposition은 body note이며 새 state/card/ledger key가 아니다. |
| workflow-artifact-write-scope | pass | contract_trace: ARCHITECT/BUILDER/REVIEWER/KNOWLEDGE_MAINTAINER의 Write와 ACTION_CARDS intake. Architect만 living Architecture를 기록하며 candidate path/완료 evidence를 건드려야 한다면 capture를 멈추고 기존 intent/mutation route로 간다. automated: feature-convergence-production-write-ambiguity. |
| evidence-based-code-quality | pass | contract_trace: REVIEWER#Review, TASK_RECORD#reversible-tuning 및 Golden Core Fixture 24. config-dependent 기대값은 허용하되 bounds/ordering/invariant와 고정 default는 독립적으로 검사한다. 초록 검사나 expected literal 교체만으로 runtime path/최적값을 승인하지 않는다. |
| terminal-no-knowledge-transition | pass | contract_trace: Golden Core Fixture 4, ARCHITECT#Feature convergence, STATE. 승인된 open outcome은 이어가고 AI-only deferral/partial success는 complete가 아니다. enclosing stop condition과 unresolved disposition을 함께 확인한다. automated: unapproved-feature-deferral-reaches-idle, mixed-open-feature-convergence-reaches-idle, integration-completion-skips-feature-convergence. |
| review-route-conformance | pass | contract_trace: REVIEWER terminal route, REVIEW_RESULT#Route, OPERATIONS와 STATE. 검사 대기에는 continuation을 억제하고 unrelated intake는 route를 소비하지 않는다. user intent drift는 Architect, 구현 오류는 Builder다. automated: missing-review-resume-transition, missing-code-inspection-handoff-suppression. |
| pass-route-branching | pass | contract_trace: OPERATIONS#normal-route, REVIEW_RESULT, Golden Core Fixture 4 및 Worktree Case 5. required/defer/none과 main/non-main을 보존하고 intake가 Knowledge/checkpoint/Integration을 시작하지 않는다. automated: missing-integration-pass-feature-convergence-route. |
| single-main-candidate-fingerprint | pass | contract_trace: BUILD_RESULT의 fixed base header/ordinal path rows/raw-byte hash와 REVIEW_RESULT, Golden Core Fixtures 5/13/17. Task path set을 재검증하며 unrelated living-view capture는 그 set을 변경하지 않는다. accepted path 쓰기가 필요하면 기존 verdict를 재사용하지 않는다. automated: ambiguous-single-main-fingerprint, missing-build-baseline-attribution, post-handoff-tuning-reuses-verdict. |
| state-fsm-completeness | pass | automated + contract_trace: validator의 parsed transition graph, STATE 전이표. accepted inspection 및 attribution recovery, building/reviewing/Integration blocked 상태의 owner/resume를 유지한다. intake는 새 전이가 아니다. automated: state-transition-targets-undeclared-phase, state-transition-creates-dead-end-blocker, state-transition-targets-retired-complete. |
| review-repair-resume | pass | contract_trace: STATE, OPERATIONS#issue-route, REVIEW_RESULT 및 Golden Core Fixture 16. evidence-only는 unchanged identity로 재검증하고 바이트 변경은 새 Build/Review, approved intent 변경은 Architect supersession으로 간다. automated: missing-changed-byte-build-resume, missing-candidate-mutating-review-transition, missing-editor-check-review-identity-boundary. |
| integration-blocked-resume | pass | contract_trace: STATE의 Integration repair pointer와 .ai/integration/README.md, Worktree Case 9. unchanged exact range와 changed bytes/new full original-main-before range를 구분하며 intake가 queue를 고치거나 Integration을 실행하지 않는다. automated: missing-integration-resume-transition, missing-integration-repair-pointer, missing-review-integration-resume. |
| sealed-candidate-identity | pass | contract_trace: MAIN_DESK#sealed-candidate, BUILD_RESULT/REVIEW_RESULT, Worktree Cases 2/3/4/6. production candidate와 Lane handoff ancestry/path range를 구분한다. intake가 reviewed candidate path에 쓰면 seal/PASS를 재사용하지 않는다. 실제 프로젝트 merge는 실행하지 않았다. |
| main-front-desk-cycle | pass | contract_trace: MAIN_DESK#front-desk-intake/#front-desk-recovery, Worktree Cases 1/4/6/7. same-Lane intake가 main Front Desk Integration authority를 대신하지 않으며 ambiguous queue/partial main은 안전하게 멈춘다. automated: missing-front-desk-recovery-contract, missing-front-desk-chat-independent-recovery. |
| non-main-session-replacement | pass | contract_trace: SESSION_CLOSE와 Worktree Case 7. checkout/Lane/role/topology/route/candidate 모두 같을 때만 direct resume이고 pending request capture 확인 후 동일 Reviewer wait를 복원한다. candidate return은 RETURN_TO_MAIN이다. automated: missing-same-lane-resume-boundary, unpersisted-intake-declared-recoverable. |
| session-close-checkpoint | pass | contract_trace: SESSION_CLOSE step 1~4와 Golden Core Fixture 1. request가 owning Architecture pointer로 retrievable한지 확인하기 전 recoverable close를 선언하지 않고 unsafe capture는 pending으로 남긴다. close는 withdrawal/completion/commit이 아니다. automated: unpersisted-intake-declared-recoverable. |
| post-integration-lane-continuation | pass | contract_trace: Worktree Case 8, MAIN_DESK 및 STATE. 이미 통합한 worker history를 재사용하지 않고 fresh current-main base에서 승인된 다음 slice를 이어간다. 마지막 PASS도 enclosing Feature convergence를 대체하지 않는다. automated: integration-completion-skips-feature-convergence. |
| artifact-authority-single-source | pass | contract_trace: ARTIFACT_AUTHORITY의 addressed dimension, artifact evolution/conflict actions와 Golden Core Fixture 7. 최신 한 요청이 다른 요청을 취소하지 않고 living view/approved scope/completed evidence의 수명을 구분한다. automated: captured-request-becomes-approval, partial-success-withdraws-outstanding-request. |
| issue-routing-single-source | pass | automated + contract_trace: OPERATIONS#issue-route가 유일한 type→owner 표이고 STATE/roles는 참조한다. intake는 새 owner/role을 추가하지 않는다. |
| state-contract-authority | pass | automated + contract_trace: STATE가 유일한 phase/status/blocked 전이표이며 WORKFLOW/roles는 링크한다. request disposition은 Architecture에 두고 lane state/ledger schema를 확장하지 않았다. |
| role-output-contract-loading | pass | automated + contract_trace: BOOTSTRAP read order와 각 role Read/Write, existing Build/Review/Architecture/Task output contracts. 새 request capture도 Architecture contract를 읽으며 completed evidence는 flow-forward로 유지한다. automated: missing-output-contract-loading. |
| safe-update | pass | contract_trace: UPDATE#checked-candidate-identity/#immutable-path-boundary, Golden Core Fixture 10 및 managed-paths. local staging을 preserved로 분류해 managed replacement가 복사/삭제하지 않는다. source template version bump는 installed state 역복사가 아니다. automated: preserved-local-staging=unchanged, missing-checked-update-identity, missing-staged-update-identity, missing-absent-update-rollback. |
| update-path-containment | pass | contract_trace: UPDATE와 managed-paths precedence. staging preservation이 read/write containment, escaping links, reclassification approval를 우회하지 않는다. automated: managed-path-escape, missing-candidate-symlink-read-containment, ambiguous-update-containment-roots. |
| local-update-state-scaffold | pass | automated + contract_trace: release.yaml/update-state.template.yaml/tracked update-state.yaml의 manual-v1.5 정합성, source inventory와 기존 bootstrap recreation. schema=1 및 preserved-state lifecycle은 유지된다. automated: missing-update-identity-scaffold, missing-active-update-marker-scaffold, release-evidence=source-inventory-missing-rejected. |
| migration-sparse-compatibility | pass | automated + contract_trace: v1.4 대비 compatibility 목록이 그대로이고 migrations=[]이다. 새 managed 파일/record schema/state field가 없어 preserved-state migration이 필요하지 않다. existing schema template 검사가 통과했다. |
| distribution-inventory-validation | pass | automated: source validator PASS, 실제 HEAD와 두 clone의 tracked inventory 77개 동일; ignored/untracked 파일 복사 0. managed/preserved 분류와 source commit inventory를 검사했고 preserved-local-staging 내용 hash는 검증 전후 같았다. |
| source-install-boundary | pass | contract_trace + human_judgment: README 빠른 시작과 두 가지 사용 방식, Golden Core Fixture 10. 새 설치는 .ai만 복사, 기존 managed .ai는 Check→Apply, 다른 .ai는 conflict 확인. 일반 focused prompt가 durable state/seal/independent Review를 제공한다고 주장하지 않는다. automated: source-eval-install-leak, source-release-procedure-install-leak, missing-public-install-boundary. |
| user-command-discoverability | pass | human_judgment + contract_trace: README 빠른 시작/자주 쓰는 복붙 문장/문제가 생겼을 때. Work/Reviewer prompt가 별도 새 세션 첫 메시지이고 next=DO_NEXT, BLOCKED=같은 owning session 응답이다. optional focused prompt에서 정식 workflow 진입 링크가 보인다. automated: incomplete-public-workflow-review-summary. |
| readme-progressive-disclosure | pass | human_judgment: README만으로 cold-reader 6문항 및 quality gate 12항목을 확인했다. 일반 focused prompt와 advanced procedures는 details 안에 있고 formal first action/session/READY/BLOCKED/repair loop가 본문에 남는다. 실제 방문자 usability experiment는 실행하지 않았다. automated: missing-readme-quality-gate, missing-public-philosophy-summary. |
| workflow-review-procedure | pass | contract_trace + human_judgment: maintenance/WORKFLOW_REVIEW의 ten lenses, independent session, bounded self-check, observed-activation; STATE#run-ledger와 .ai/evals의 claim limits가 일치한다. accepted-only window/type-list/closure disposition은 productivity/Integration/learning evidence가 아니다. automated: zero-activation-report-dropped, zero-activation-becomes-automatic-deletion, unobserved-mode-reported-as-zero-activation, run-ledger-records-unsupported-provenance. |
| source-validation | pass | automated: 실제 candidate의 validate-workflow exit=0, workflow=manual-v1.5, markdown=55, references=299, eligible_current_evals=0 (record 생성 전). tracked clone full regression은 259/259 PASS. 비교는 baseline_tokens=680, current_tokens=685, dropped_protection=0, wording_drift=0, dynamic_verified=12, dynamic_failures=0. |
| eval-release-evidence | pass | automated + contract_trace: isolated release-pass/full-mode positive 및 untracked/unstaged/source-drift/comparison-type/not-applicable-case/unjustified-P2/source-missing-inventory negative fixtures 통과. canonical record는 source_regression, exact source/tree, independent ten-lens review, case별 pass, 별도 staging을 요구한다. 실제 -RequireReleaseEvidence 최종 결과는 실행 후 chat에서 보고한다. |
| eval-case-catalog-traceability | pass | automated + contract_trace: 모든 front matter case_id는 .ai/evals/README.md의 canonical catalog에서 선택하며 같은 ID의 pass/evidence row가 있다. run-local case/rename/새 기록 schema를 도입하지 않았다. |
| historical-record-integrity | pass | automated + contract_trace: source HEAD의 기존 Eval 8개를 변경하지 않았다. 새 record path는 source commit에 없고 v1.4..HEAD에는 역사적 Eval 수정이 없다. fixture의 synthetic Eval/Git commit은 격리 temp에만 존재한다. |
| publication-boundary | pass | contract_trace: maintenance/RELEASE#FINALIZE_RELEASE_EVAL와 명시적 사용자 범위. 실제 저장소는 후보 source를 수정하지 않고 source-only Eval 하나만 stage한다. source/Eval commit, Push, tag, merge, release는 수행하지 않는다. |
| windows-powershell-default | pass | automated: Windows PowerShell 5.1.26100.9711로 세 canonical script를 실행했고 powershell-non-ascii-source inverse도 통과했다. 긴 fixture 경로의 첫 harness 실패는 짧은 temp root로 재실행해 해결했다. PowerShell 7/Ubuntu 성공을 주장하지 않는다. |
| local-vs-remote-ci-claim | pass | human_judgment + contract_trace: README와 source_regression schema가 local PASS와 remote CI/실제 모델 결과를 구분한다. GitHub Actions/모델 A/B/생산성/학습/실용 동등성은 unverified 또는 not_measured다. |
| scorecard-template-version-authority | pass | automated + contract_trace: SCORECARD front matter workflow_version=null/schema=2를 유지하며 새 prose는 기존 metric rows만 사용한다. record version은 frozen release.yaml의 manual-v1.5에서 가져왔고 filename은 neutral source scope다. |

## Workflow Review

```text
WORKFLOW_REVIEW RESULT=pass
mode=changed workflow_version=manual-v1.5
source=ce0653f6273d13d48cb7d78ea3dc5f0d049b5eef reviewed=25 changed paths + linked contracts
automated=pass regression=pass
findings=P1:0,P2:0,P3:1
independence=independent_session
self_check=corrected corrections=1
budget=pass slack=work+architect:180,work+builder:759,work+knowledge:1374,reviewer:1181 activation=not_available
release_recommendation=not_ready
```

이 독립 세션은 후보 소스를 작성하지 않았다. Eval 생성 직전까지 실제 checkout이 clean이며 HEAD/tree를 고정했다. comparison_base는 v1.4 (21856414682fb2da56b56cbfcbd50dc96edd82f6)이다. mode=changed는 명시적 요청과 기본 선택 규칙에 따른다. 기존 역할/기록 schema/default를 유지하는 계약 보강이므로 first baseline 또는 major redesign 예외로 full을 선택하지 않았다. 회귀 harness를 전체 실행한 것은 review mode를 full로 바꾸거나 전체 catalog/model 동작을 측정했다는 뜻이 아니다.

### Ten lenses

| Lens | Result | Evidence |
|---|---|---|
| 1 | PASS | human_judgment + contract_trace: README 첫 화면은 file-backed 개발 Workflow, 대상 개발자, 작은 Task/독립 Review/사용자 판단을 설명한다. 새 일반 focused prompt는 단일 대화 용도로 한정하고 project-governing 결정은 정식 Workflow로 연결한다. WORKFLOW#design-principles가 철학의 유일한 소유자다. |
| 2 | PASS | human_judgment + contract_trace: 아래 README-only cold-reader trace 6문항과 12개 quality gate 조건이 모두 정확한 본문으로 답해진다. ACTION_CARDS#scan-first-composition은 현재 질문·원인/결과·source·근거·다음 행동을 연결하고 단순 응답/튜닝 delta에 전체 보고서를 강제하지 않는다. 실제 방문자 usability/모델 설명 성공은 측정하지 않았다. |
| 3 | PASS | contract_trace: WORKFLOW lifecycle → ARCHITECTURE/Task Quality Gate → BUILDER/BUILD_RESULT → REVIEWER/REVIEW_RESULT → configured inspection → Knowledge/checkpoint 또는 Integration → Architect Feature convergence가 연결된다. Golden Core Fixtures 1/4/6/7/17/20/24/25와 Worktree Cases 5/6/8/9를 대조했다. outstanding outcome은 partial success로 사라지지 않고 one_task는 enclosing purpose/stop에 묶인다. |
| 4 | PASS | automated + contract_trace: 역할 Write 범위와 OPERATIONS#issue-route를 유지한다. capture는 approved Scope/Task가 아니고 fixed Reviewer의 same-Lane DO_NEXT는 Architect intake만 허용한다. intake가 승인/inspection reply/Build/Knowledge/checkpoint/Integration을 실행하지 않는다. 여섯 새 authority/state 역방향 fixture와 기존 assent/gate 보호가 통과했다. |
| 5 | PASS | automated + contract_trace: STATE의 pre-Build/Build/Review/accepted inspection attribution/Integration blocked 상태를 OPERATIONS owner와 repair/resume 조건에 연결했다. unchanged evidence는 exact identity로 재검증하고 changed bytes는 새 Build/Review, changed intent는 Architect supersession이다. SESSION_CLOSE는 verified request capture 후 동일 Reviewer replacement를 허용하며 MAIN_DESK recovery는 ambiguous range를 통과시키지 않는다. |
| 6 | PASS | automated + contract_trace: 실제 source validator PASS, tracked-only clone의 정상 12/역방향 247 검사 PASS, v1.4 비교 dropped_protection=0/wording_drift=0 및 12개 dynamic mutation 거부. 수치 변경도 post-handoff candidate identity를 무효화한다. .ai/evals/README.md 및 .ai/evals/SCORECARD.md와 ledger 제한은 static contract evidence와 actual runtime/comparative evidence를 구분한다. |
| 7 | PASS | contract_trace: ARTIFACT_AUTHORITY의 addressed intent dimension, reference-only/living/flow-forward/live-source 수명과 ARCHITECTURE#request-continuity가 일치한다. request disposition은 기존 body에만 있고 state/ledger/card/role schema를 추가하지 않았다. question/action request/proposal/approval를 구분하며 단일 짧은 동의를 다른 결과나 이해/학습 권한으로 확대하지 않는다. |
| 8 | PARTIAL | automated + human_judgment: ordinary single-main one-Task 경로의 always-read 파일 수·기본 user stop·기본 handoff·broad-suite·durable artifact 수는 증가하지 않았다. 필요한 intake handoff만 요청 유실/inspection wait 오소비를 막기 위해 on demand로 생긴다. entry 예산은 모두 PASS이지만 work+architect slack은 180 bytes로 줄어 정확히 기록했다. 현재 비용/성과 측정은 없고 PARTIAL은 아래 비차단 P3 baseline 주석 오차에만 해당한다. |
| 9 | PASS | automated + contract_trace + human_judgment: 실제 validator가 references=299를 검사했다. request continuity는 Architecture, tuning은 Task, adaptive composition은 Action Cards가 소유하고 role/Workflow/README는 연결한다. source map은 Build Result가 한 번 소유하고 Review는 검증 pointer만 남긴다. 일반 prompt는 별도 역할/정식 설치 규칙의 대체 권한이 아니다. |
| 10 | PASS | automated + contract_trace: ARTIFACT_AUTHORITY trust/secret/script/write 경계, UPDATE의 pinned candidate-read/install-write containment, managed-paths의 preserved precedence를 유지한다. staging/**는 local preserved이며 positive fixture가 hash 불변을 확인했다. 검증 복제본은 77개 tracked 파일과 필요한 Git graph만 포함하고 ignored/untracked 로컬 기록은 복사하지 않았다. 실제 저장소의 source/역사적 Eval은 수정하지 않았다. |

### README-only cold-reader trace

| 질문 | README만으로 확인한 답/정확한 위치 |
|---|---|
| 이 저장소와 대상은? | 첫 화면: 인간 중심 file-backed AI 개발 Workflow; AI로 구현하면서 결과와 다음 판단을 이해하려는 개발자. 문제→경험 표와 두 가지 사용 방식이 정식 개발/일회성 대화 범위를 구분한다. |
| 첫 파일 작업과 메시지는? | 사용법 > 빠른 시작 1~2: .ai가 없는 대상 root에 .ai만 복사하고 새 Work 세션 첫 user message로 그 아래 Bootstrap prompt를 보낸다. 기존 관리 설치는 Check→Apply이며 다른 .ai는 충돌을 먼저 확인한다. |
| prompt는 어느 세션에? | [창 1] Work로 초기화 완료를 기다린 뒤 [창 2] Reviewer를 별도 새 세션으로 만든다. 두 prompt를 한 대화에 넣거나 System/terminal instruction으로 쓰지 않는다는 IMPORTANT가 보인다. |
| 초기화 성공/실패는? | 설치 조건과 초기화 확인: READY + initialization=complete, main/lane.yaml 및 state.yaml 생성. BLOCKED 또는 두 파일 부재이면 같은 Work에서 원인/복구를 요청하고 Reviewer 생성 전에 해결한다. inactive READY/wait는 정상이다. |
| Work→Reviewer와 PASS/BLOCKED 뒤는? | 기본 개발 흐름/기본 사용 예시: ready_to_review + 생성된 DO_NEXT를 Reviewer에 붙인다. 실제 Diff와 source를 보고, default no_pause는 Work DO_NEXT로 이어가며 opt-in inspection만 같은 Reviewer 응답을 기다린다. 구현/구조/계약 문제는 owner로, user evidence는 같은 요청 session으로 답한다. |
| optional/unusual 절차는? | strict prompts/일반 focused prompt는 details로 접힌다. Worktree 병렬 시작, 병렬 작업 통합, 세션 종료와 교체, 문제가 생겼을 때, Workflow 개선과 업데이트, GitHub용 .ai 복사본 갱신이 별도 이름으로 찾을 수 있다. normal path는 이 절차의 선행 독서를 요구하지 않는다. |

README quality gate: Identity, Differentiation, First action, Session separation, Success recognition, Normal loop, Failure recovery, Progressive disclosure, Contract accuracy, Single source, Terminology, Claims = PASS (human_judgment + contract_trace). 이는 reviewer의 문서 추적 판단이며 실제 사용자 실험 결과가 아니다.

### Changed behavior, principles, and normal-path cost

| 변화와 enforcement level | canonical Design Principle / 보존할 원칙 | 확인한 failure surface와 비용 |
|---|---|---|
| request continuity / invariant | 1 Files and Git, 3 Input depth; 4 bounded context, 6 independence, 7 user judgment를 보존 | 부분 피드백·replacement·stale Task로 미완료 요청이 지워지는 것을 막는다. existing Architecture body만 사용하고 단일 covered 요청은 추가 note를 생략한다. |
| intake-only transport/verified close / invariant | 1 durable state, 6 Independent Review; 7 authority와 11 on-demand path를 보존 | 요청 유실과 intake acknowledgement가 inspection completion이 되는 false continuation을 막는다. material unrelated request를 현 role이 보존할 수 없을 때만 same-Lane transport하며 completed evidence/candidate/state는 유지한다. |
| enclosing purpose/stop / default + scope invariant | 2 smallest sufficient whole, 9 quality floor then waste, 11 simple default | one_task가 개별 edit 크기만 보고 endless cleanup이 되는 것을 막는다. next Task의 기존 reason/Scope/Verification/Slices를 사용하며 새로운 gate/score/output이 없다. |
| adaptive causal/source explanation / presentation | 7 continuous source truth, 4 context quality, 9 proportional cost | inventory 반복이나 길이 quota가 실제 causal gap을 가리는 것을 줄인다. source/evidence를 숨기지 않고 quiz/mandatory comprehension reply/영구 profile을 추가하지 않는다. 실제 설명 효과는 미측정이다. |
| reversible tuning / default + candidate/invariant protection | 5 evidence, 8 engineering quality, 9 proportional verification; 3/6/7 scope/independence를 보존 | tunable과 fixed requirement 혼동, oracle literal 동반 수정, post-verdict stale PASS를 막는다. 기존 Task/Build evidence만 사용하며 pre-handoff는 한 attempt, post-handoff는 fresh identity다. |
| ledger interpretation / evidence invariant | 5 Evidence over confidence, 9 truthful cost, 10 no assumed parity | accepted-only closure window를 전체 실패 비용·Integration·learning·productivity로 확대하지 않는다. schema/capture/runtime route/새 log는 바뀌지 않는다. |
| staging preservation/metadata bump / losslessness + presentation | 1 durable state, 11 on demand; authority/trust/quality floor를 보존 | local triage/update staging을 managed payload로 오분류하는 것을 막고 기존 schemas/defaults를 유지한다. compatible release bump 1회이며 새 managed file/migration은 없다. |
| README focused prompt / presentation | 3 Input depth, 7 informed judgment, 11 simple default | 한 대화용 prompt를 durable 개발 증거로 오인하지 않게 범위와 정식 workflow 진입 조건을 명시한다. 설치·role·runtime rule은 추가하지 않는다. |

ordinary single-main one-Task before/after (contract_trace): 두 session Work + independent Reviewer, 필요한 설계/사용자 소유 승인 → 한 vertical Task → Build → Review → optional opted-in inspection → 필요한 Knowledge와 exact checkpoint → 다음 justified Task/Feature convergence 순서가 유지된다. always-read set의 파일 수는 5/5/4/4 그대로다. 명시적으로 추가된 body 규칙은 request/authority 유실과 stale identity를 막으며, Architect의 중복 frame/Task/gate 설명은 canonical contracts로 위임했다. adaptive explanation은 전체 output stack을 상시 반복하는 요구를 줄였다. 일반 Task에서 maintenance/full Eval/ledger read를 새로 실행하지 않는다. 이 판단은 실제 elapsed/token/productivity 측정이 아니다.

| Set | v1.4 tracked bytes | HEAD bytes | Delta | Ceiling | Slack |
|---|---|---|---|---|---|
| work+architect | 61122 | 62284 | +1162 | 62464 | 180 |
| work+builder | 49349 | 50441 | +1092 | 51200 | 759 |
| work+knowledge | 43972 | 43682 | -290 | 45056 | 1374 |
| reviewer | 49905 | 50019 | +114 | 51200 | 1181 |

automated: HEAD totals use the validator's exact path sets and file byte lengths; v1.4 totals use git cat-file -s v1.4:<path>. ceiling은 후보에서 올리지 않았으며 overhead/일반 runtime context 전체 또는 토큰 수가 아닌 entry-file byte 예산이다. 작은 slack은 다음 source 편집의 tripwire이며 그 자체로 현재 FAIL이나 모델 성능 결함이 아니다.

### Findings

```text
[P3][8] 기존 v1.4 읽기 예산의 기준 측정 주석 세 개가 tracked 합계와 16 bytes 다르다
evidence=automated: tools/validate-workflow.ps1:2878/2880/2882의 measured 61106/49333/43956 at manual-v1.4 baseline; frozen v1.4 (21856414682fb2da56b56cbfcbd50dc96edd82f6)의 같은 path-set 합계는 61122/49349/43972. reviewer 49905는 정확하다. applicable 이전 v1.4 source Eval에도 동일한 P3가 있고 현재 후보는 그 주석을 바꾸지 않았다.
impact=향후 ceiling 근거를 재현할 maintainer가 문서상 기준 합계에서 16 bytes 낮게 시작한다. 현재 ceiling 네 개와 검증 동작은 올바르고 모든 HEAD set이 한도 안이다. source/role/candidate false acceptance를 만들지 않는 audit annotation 오차다.
change=다음 source candidate에서 세 기준 수치를 해당 frozen baseline의 재측정값으로 고치고 정확한 baseline ref를 명시한다. ceiling/quality floor를 올리거나 보호 문구를 삭제하지 않는다.
proof=같은 네 path-set을 git cat-file -s로 재합산해 기록한 baseline 수치와 일치시키고, 그 baseline에 대한 ceil(bytes/1024)*1024+1024가 기존 네 ceiling과 같은지 확인한다.
```

P1:0, P2:0, P3:1. P3는 릴리스 비차단이며 이 세션은 source를 수정하지 않는다.

### Valuable mechanisms that should remain

- 차원별 user intent와 승인된 Scope/Task를 구분하는 single-owner request continuity; partial success나 proposal을 자동 승인/취소로 읽지 않는다.
- inspection wait의 exact identity와 intake-only exception; unsafe capture를 pending으로 두고 복원 가능한 close만 인정한다.
- 새 candidate identity와 independent Review; 작은 parameter 수정도 전달 뒤 바이트가 바뀌면 기존 verdict를 재사용하지 않는다.
- run ledger의 write-only/accepted-only/schema 유지와 measured zero, not_measured, not_observed의 구분.
- tracked-source release binding, 역방향 release fixtures, compare-validation의 guard 비교, four-set ceiling/slack 공개 및 managed/preserved containment.

### Smallest safe fix order

다음 source candidate에서 위 P3 주석만 먼저 정정하고 focused 재합산으로 확인한다. 현재 candidate 재작성/ceiling raise/추가 gate나 기록 schema는 필요 없다. 이번 finalization은 Eval 별도 commit 대기로 끝난다.

### Unverified claims and evidence gaps

- unverified: live provider/model execution, 설명을 실제로 이해한 사용자, 생산성·학습·model practical parity·baseline/A/B·token savings·runtime speed·제품 feel/optimal tuning. fixture/token/정적 oracle PASS는 이를 증명하지 않는다.
- unverified: Ubuntu/PowerShell 7와 remote GitHub Actions. 실행한 환경은 Windows PowerShell 5.1이다.
- unverified: 실제 installed-project update/rollback/merge와 실제 production runtime. 여기서는 계약 및 synthetic fixtures를 평가했다.
- not_measured: 모델/effort의 provider usage metadata, tokens, live accepted-result elapsed time, human corrections, per-Task runtime attempt cost. 자동 harness 시간은 모델/Workflow 생산성 지표로 전환하지 않는다.

### Observed activation

activation=not_available. 설치 root/ledger는 공급되지 않았고 canonical distribution에는 runtime Lane가 없다. accepted-Task window와 field coverage를 구성할 실제 입력이 없으므로 main/lane/no_git count는 0이 아니라 unavailable이다. 설치물을 탐색하거나 관련 없는 ignored 로컬 기록을 읽어 보완하지 않았다.

contract_trace: supplied ledger가 있을 때만 closure를 먼저 분할하고 accepted-Task window/field coverage를 명시한다. findings_total은 기록 총계이고 finding_types는 해당 type을 나열한 Task line 수만 지원한다. build_attempts/review_attempts는 accepted Task에 한정한다. code_inspection/checkpoint는 closure disposition이며 모든 pause/card 사용/기간을 세지 않는다. superseded/abandoned/open Tasks는 빠져 전체 실패/재시도 비용·Review 효과·생산성·학습을 추론할 수 없다. lane_handoff는 accepted Lane closure만 뜻하며 main apply/review/Integration 실행 증거가 아니다.

not_measured: blocker-event/general optional-card-use/미기록·부분 coverage fields, 모든 pause의 횟수/기간. not_observed: window에 없는 closure mode의 Worktree/Front Desk/sealed candidate/Integration 활성화. 실제 window가 없는 이번 review는 measured zero-activation rule이나 removal recommendation을 만들지 않는다. 누락 ledger/field/mode는 finding 또는 release blocker가 아니며 새 runtime record를 요구하지 않는다. 희귀 authority/safety/loss 보호는 named consequence가 남아 있으므로 유지한다.
### Bounded self-check record

첫 ten-lens 표·finding·결론을 freeze한 뒤 아래 여섯 경계만 한 번 adversarial check했다. 최초 check는 축약 경로 표기 오류를 발견하지 못했다. 최종 실제 -RequireReleaseEvidence가 보고서 reference 5곳을 거부해 허용된 한 번의 revision으로 각 파일의 정확한 경로를 정정했다. frozen report의 lens 6 evidence 및 scope/case evidence의 reference 표기만 고쳤고 finding/lens/result는 유지했다. self_check=corrected, correction batch=1이다. self-check를 재귀적으로 반복하지 않았다.

- coverage: 열 개 lens와 STATE의 ready_to_build/building/ready_to_review/reviewing/accepted inspection 및 attribution/Integration blocked 경로를 모두 기존 role owner와 repair/resume에 연결했다.
- evidence: 유일한 P3는 exact script lines, frozen v1.4 commit의 git byte sums, 영향, 최소 fix, 재합산 proof를 갖는다. concrete 근거 없는 P1/P2/FAIL은 없다.
- inverse: 새 intake exception이 inspection 우회라는 해석을 검사했으나 wait/route/identity 보존과 candidate-path 금지로 의도된 bounded capture다. 짧은 동의의 확대 해석은 ACTION_CARDS의 한 표시 행동/scope/hook/checkpoint 권한으로 제한된다. 두 enforcement_ended는 현재 문구의 guard와 inverse fixture로 보호된다. P3의 historical-baseline 설명도 검사했으며 문서의 baseline 합계 재현성이 16 bytes 다를 뿐 ceiling 오류는 아니므로 P3를 유지했다. eligible Eval이 아직 없는 pre-release 상태와 미측정 runtime는 Workflow defect로 만들지 않았다.
- miss: normal repair와 Integration original range/queue repair, runtime Lane와 source-only maintenance, installed preserved staging과 canonical distribution, unchanged evidence와 changed candidate bytes를 다시 대조했다. intake가 reviewed Architecture path나 current approved intent를 바꿔야 하는 경우는 capture가 아니라 기존 mutation/intent route 또는 pending이다.
- consistency: P1:0/P2:0/P3:1, lens 8 PARTIAL, 다른 lens PASS, quality RESULT=pass, self_check=corrected/corrections=1이 일치한다. review 시점의 completed source evidence/별도 commit gate가 남아 있으므로 release recommendation은 not_ready다.
- scope: review 단계에서 source/역사적 Eval/state/criteria를 수정하지 않았다. fixture 변형/commit/Eval은 isolated temp에만 있고 새 역할/schema/log를 만들지 않았다. 자동 PASS나 local byte 수치를 live model/learning/productivity/parity proof로 바꾸지 않았다.

- findings: P1:0, P2:0, P3:1
- deferred P2: none
- self-check: corrected
- corrections: 최종 validator가 거부한 reference 5곳을 정확한 개별 파일 경로로 정정했다. frozen lens 6의 Eval README/Scorecard pointer, scope inventory의 Integration README/queue 및 maintenance UPDATE/MAINTAIN/inventory 결합 표기, case evidence의 확장자 생략을 고쳤다. 최초 bounded self-check의 reference 누락을 공개하며 source 판단/ten-lens 결과/finding 수는 변경하지 않았다.
- release recommendation: not_ready

## Failure

- stage: source regression failure 없음. 최초 harness 경로 설정의 environmental Copy-Item 실패는 위에 보존했다. 처음 actual release gate는 Eval reference 5곳을 거부했고 이 record만 한 correction batch로 정정했다. 당시 post-stage suite는 frozen record byte를 다시 맞추기 위해 69 PASS 후 중지하고 재시작했다.
- cause: P1/P2/applicable FAIL 없음. 긴 temp path와 reviewer가 작성한 축약 reference 표기를 교정했으며 candidate source를 수정하지 않았다.
- evidence: 성공한 전체 실행 259/259 PASS; compare의 두 loss 조건과 dynamic failures 모두 0. P3 baseline annotation은 비차단이다.

## Decision

- keep/change: keep. 이 frozen manual-v1.5 source는 source-only release quality floor를 만족한다. 다음 candidate에서 P3 baseline annotation만 focused 재합산으로 고칠 수 있다.
- regression cases: 기존 catalog 59 affected case 및 기존 Golden Fixtures 1/4/6/7/17/18/20/21/22/23/24/25/26, 연결 Worktree lifecycle trace를 사용했다. 새 role/schema/score/log/model experiment를 추가하지 않았다.
- publication: 별도 Eval record commit을 사람이 검토해 수행해야 한다. finalizer는 실제 source/Eval commit, Push, tag, merge, release를 수행하지 않고 eval_commit_required에서 멈춘다.
