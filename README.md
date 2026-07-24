# AI Dev Workflow

파일과 Git을 상태로 사용해 `설계 → 작은 구현 → 독립 검증 → 필요한 지식 갱신`을 반복하는 수동 AI 개발 워크플로우다. 기본 구성은 도구·모델과 무관한 `main` Lane 하나, 작업 세션 하나, 독립 Reviewer 세션 하나다.

## 사용법

### 처음 설치

다운로드한 AI Dev Workflow 저장소에서 **`.ai` 폴더만** 대상 프로젝트에 복사한다. 배포 저장소의 `.git`, `.github`, `tools`는 설치물이 아니다.

가능하면 대상 프로젝트에서 최초 실행 전에 Git 기준 커밋 하나를 만든다. Git이 없어도 기본 사용은 가능하지만 Review 근거가 약해지고 Worktree·후보 봉인·통합 기능은 사용할 수 없다.

1. 이 저장소의 `.ai` 폴더를 대상 프로젝트 루트에 복사한다. 기존 `.ai`가 있다면 먼저 백업한다.
2. 파일을 읽고 쓸 수 있는 AI 도구로 대상 프로젝트 루트를 연다.
3. 아래 순서로 세션 두 개를 직접 만든다.

처음 설치에서는 아래 Prompt를 수정하지 않고 그대로 복붙한다. 각 Prompt는 AI 도구에서 **새 세션을 만든 뒤 첫 번째 사용자 메시지**로 보낸다. System Prompt·Custom Instructions·터미널 명령으로 넣을 필요는 없다.

**Work** 세션을 먼저 만들고 초기화가 끝날 때까지 기다린다. 이 세션 안에서 파일 상태에 따라 Knowledge Maintainer → Architect → Builder 역할만 전환한다. Reviewer 역할은 하지 않는다.

```text
Read `.ai/BOOTSTRAP.md`. role=work, lane=main, session_mode=compact, user_language=ko. If lane `main` is missing, create it from `.ai/lanes/_template`. Initialize only if needed, restore durable state, and reply READY or BLOCKED.
```

초기화가 끝나면 별도의 **Reviewer** 세션을 만든다.

```text
Read `.ai/BOOTSTRAP.md`. role=reviewer, lane=main, session_mode=compact, user_language=ko. Restore durable state from files and reply READY or BLOCKED.
```

현재 차례가 아닌 세션도 `READY ... next=wait_for_...`로 대기하는 것이 정상이다. 아직 Task나 Build Result가 없다는 이유만으로 `BLOCKED`가 되지는 않는다.

엄격한 역할 분리나 워크플로우 평가가 목적이면 아래 네 세션을 대신 사용할 수 있다. 같은 Checkout에서 공용 Knowledge를 동시에 갱신하는 세션을 두 개 만들지는 않는다. 단, Worktree 모드를 시작하면 접수와 통합은 항상 별도의 `main` Work 세션이 담당한다.

<details>
<summary>엄격한 4세션 Prompt</summary>

Knowledge Maintainer:

```text
Read `.ai/BOOTSTRAP.md`. role=knowledge_maintainer, lane=main, session_mode=strict, user_language=ko. If lane `main` is missing, create it from `.ai/lanes/_template`. Then, if it is uninitialized, complete BUILD; otherwise restore durable state without a broad scan. Preserve existing work and report the result.
```

Architect:

```text
Read `.ai/BOOTSTRAP.md`. role=architect, lane=main, session_mode=strict, user_language=ko. Restore durable state from files and reply READY or BLOCKED.
```

Builder:

```text
Read `.ai/BOOTSTRAP.md`. role=builder, lane=main, session_mode=strict, user_language=ko. Restore durable state from files and reply READY or BLOCKED.
```

Reviewer:

```text
Read `.ai/BOOTSTRAP.md`. role=reviewer, lane=main, session_mode=strict, user_language=ko. Restore durable state from files and reply READY or BLOCKED.
```

</details>

### 평소 개발

1. **Work**에서 짧게 기능을 시작한다.

   ```text
   이 기능 짜야 해.
   ```

   구조에 실제로 중요한 선택이 있으면 Work가 프로젝트 근거와 함께 한국어 Decision Brief를 보여주고 질문한다. 내부 `architecture.md`를 열지 않아도 판단할 수 있어야 한다. 검토 후 승인하거나 수정 요청한다.

   ```text
   이 Architecture를 승인해.
   ```

   승인된 Architecture 안의 일반 Task는 다시 승인받지 않고 Work가 한 개씩 구현한다. 새 구조·사용자 의도·큰 비용·필수 수동 검증이 생길 때만 다시 묻는다.

2. `RESULT=ready_to_review`이면 **Reviewer**로 이동한다.

   ```text
   현재 Build Result를 검증해.
   ```

3. Reviewer 결과에 따라 진행한다.

   PASS 시 동작이나 구조가 달라진 작업은 Reviewer가 실제 Diff와 검증 근거로 짧은 `Change Brief`도 보여준다. 단순한 기계적 변경은 설명을 생략한다.

   | 결과 | 다음 단계 |
   |---|---|
   | `VERDICT=pass` | Work에 `계속 진행해.` |
   | `implementation` | Work에 `Reviewer 지적을 수정해.` |
   | `architecture / contract` | Work에 `Reviewer 지적을 처리해.` |
   | `BLOCKED owner=user` | Reviewer가 제시한 단계대로 확인 후 같은 Reviewer에 결과 전달 |

4. Work는 필요한 Knowledge 갱신을 수행하거나 작은 변경은 다음 체크포인트까지 묶어두고, 다음 Task를 준비한다.

   ```text
   계속 진행해.
   ```

다른 역할·세션으로 넘길 때는 `DO_NEXT session=... say="..."`가 붙는다. 병렬 작업에서는 대상 `lane`과 `worktree`도 함께 표시된다. 내부 `route` 값을 해석하지 말고 표시된 문장만 지정된 세션에 붙여넣으면 된다. 현재 세션에서 승인하거나 수동 확인 결과를 답하는 경우에는 중복 `DO_NEXT` 없이 질문 또는 복붙 답변 형식이 바로 나온다.

### Knowledge 바로 사용

기본 2세션 구성에서는 Work에, 엄격한 4세션 구성에서는 Knowledge Maintainer에 짧게 말하면 된다.

```text
Docs/WeaponGDD.md 추가했어. 반영해줘.
Git Pull 받았어. 변경분 반영해줘.
무기 시스템 진입점이 어디야? 근거 경로만 알려줘.
```

파일을 추가하는 것만으로 자동 실행되지는 않으므로 변경 사실은 알려야 한다. 새 세션이나 Bootstrap 재입력은 필요 없다.

### Worktree 병렬 시작

Worktree는 같은 Git 저장소의 다른 Branch를 별도 폴더에서 동시에 여는 기능이다. 평소에는 `main` Lane만 사용한다. 서로 겹치지 않는 기능을 실제로 동시에 개발할 때만 경계 설계를 요청하며, 기본 구성에서는 기존 `main` Work에, 엄격한 4세션 구성에서는 `main` Architect에 말한다.

Worktree 모드에서 `main` Work는 항상 **접수처**다. 새 작업을 받아 Lane별 시작 카드를 발급하고, Worktree에서 돌아온 상태를 인수해 통합하거나 다음 세션 카드를 발급한다. 엄격한 구성으로 경계를 설계했더라도 안내되는 고정 main Work Prompt로 접수처를 만들며, 실제 Lane 구현과 리뷰는 각 Worktree 세션에서 수행한다.

```text
main 접수처 → NEXT_SESSION → Worktree 작업 → RETURN_TO_MAIN → main 접수처
```

```text
캐릭터와 UI를 별도 Worktree에서 병렬 개발할 거야.
작업 경계를 설계하고 Lane별 시작 카드까지 만들어줘.
```

경계를 승인하고 안내된 기준 파일을 Git에 커밋한 뒤 요청을 시작한 같은 세션에 `병렬 기준 커밋했어.`라고 답한다. 기본적으로 각 Lane은 토큰과 세션 부담이 적은 Work+Reviewer 2세션으로 구성된다. 처음에는 main 접수처 Prompt와 Worktree 생성 명령까지 포함한 `PARALLEL_START`, 이후에는 필요한 새 세션만 담은 `NEXT_SESSION`이 나오므로 순서대로 복붙하며 `lane=main`을 직접 수정하지 않는다.

각 Lane은 안내된 Worktree 폴더를 AI 도구에서 따로 열고 **새 Work·Reviewer 세션**을 만든다. 기존 `main`이나 다른 Lane 세션에 새 초기화문을 넣어 Lane을 바꾸지 않는다. 별도 Lane도 엄격한 4세션으로 운영하려면 최초 요청 끝에 `각 Lane도 엄격한 4세션으로 만들어줘.`를 붙인다.

### 병렬 작업 통합

`integration_order`는 병렬 경계를 승인할 때 의존성을 고려해 함께 정한 안전한 통합 순서다. 예를 들어 `character → ui`라면 Character의 계약을 먼저 `main`에 넣고 검증한 뒤 UI를 넣는다. 이미 승인한 순서이므로 충돌·공유 계약 변경·범위 추가·새 증거가 없으면 다시 선택하지 않는다.

비-`main` Lane의 각 Task는 Builder가 해당 Task 변경만 담은 후보 커밋을 만든 뒤 Reviewer가 그 정확한 revision을 검토한다. PASS 후에는 현재 Lane의 Task·Build·Review·state만 담은 메타데이터 커밋으로 후보를 봉인한다. 이는 승인된 Worktree 전달 절차라서 매번 묻지 않으며, 사용자 변경이나 다른 경로는 포함하지 않는다.

Lane의 마지막 세션을 마무리하면서 나온 `RETURN_TO_MAIN`의 `DO_NEXT` 한 줄을 **main Work 세션**에 붙여넣는다. main Work는 검토된 후보 커밋·트리와 Lane 메타데이터 커밋이 일치하는지 확인한다.

봉인된 후보라면 승인 순서의 한 Lane만 반영하고, 병합 전후 revision을 기록한 뒤 main Reviewer로 보낼 정확한 `DO_NEXT`를 준다. 직접 실행할 수 없거나 커밋·권한·충돌 문제가 있으면 사용자가 해야 할 단계와 PASS 기준을 `USER_ACTION`으로 준다.

main Reviewer의 통합 검증이 PASS하면 Review와 통합 Queue 정보만 담은 체크포인트 커밋을 남긴다. 필요한 공용 Knowledge 갱신도 별도 Knowledge 체크포인트로 정리한 뒤 `DO_NEXT`에 따라 main Work로 돌아가 다음 Lane을 같은 방식으로 처리한다. 사용자는 통합 순서를 외우거나 매번 승인할 필요 없이 표시된 복붙 문장만 따르면 된다.

### 세션 종료와 교체

```text
마무리하고 main으로 복귀해.
```

비-`main` 세션을 실제로 닫거나 교체할 때 사용하는 표준 명령이다. 기존 `세션 종료 프로토콜 수행해.`도 호환된다. 현재 Architecture·Task·Build·Review 경로, 승인된 결정, 단계와 상태, 검증 결과, 열린 위험·차단 사유, 다음 역할·행동과 최소 입력 경로를 파일에 체크포인트한다.

전체 대화·숨은 추론은 저장하지 않는다. 종료 명령 자체도 새 Git 커밋·병합이나 아직 선택하지 않은 Knowledge 갱신을 실행하지 않는다. 후보·메타데이터 커밋은 그보다 앞선 Builder/Reviewer/Knowledge 절차에서만 생성된다.

| 이동 상황 | 해야 할 일 |
|---|---|
| 같은 Worktree·같은 Lane에서 현재 세션 계속 사용 | 종료하지 않고 그대로 계속한다. |
| 같은 Lane의 이미 열린 Work↔Reviewer 이동 | 표시된 `DO_NEXT`를 해당 세션에 바로 붙인다. main을 거치지 않는다. |
| 비-main 세션 종료·교체·Lane 이탈 | `마무리하고 main으로 복귀해.` → 나온 `DO_NEXT`를 main Work에 붙인다. |
| main 접수처 세션 자체 교체 | `처음 설치`의 고정 main Prompt로 새 main 세션을 만든다. |

비-main 종료 결과에는 현재 Worktree·Lane·역할·세션 구성·Branch, 검토/봉인 revision, 변경 종류별 dirty 경로, Observation과 main 경로가 담긴 `RETURN_TO_MAIN`이 나온다.

main은 이 카드가 가리키는 파일과 Git을 직접 확인하고 다음 행동 하나를 선택한다. 새 세션이 필요하면 정확한 폴더·역할 Prompt·첫 요청까지 채운 `NEXT_SESSION`을 주므로 사용자는 과거 Prompt나 대화를 보관할 필요가 없다.

세션은 Bootstrap 뒤 하나의 Worktree·Lane에 고정된다. main이 `NEXT_SESSION`을 주면 대상 폴더를 열어 **새 세션**을 만들고 Prompt를 붙인다. 기존 세션에 다른 Lane Prompt를 넣어 재사용하지 않는다.

종료 시 Workflow 불편사항의 자동 기록 조건도 한 번 확인하지만, 근거가 분명한 문제만 `OBS-*.yaml`로 저장한다. 반드시 남기고 싶은 불편은 다음처럼 명시한다.

```text
방금 불편도 Workflow 개선 후보로 기록하고 main으로 복귀해.
```

결과의 `RETURN_TO_MAIN`에서 `observation=<path>`이면 현재 Worktree에 저장된 것이다. `none`이면 자동 기록 조건에 해당하지 않은 것이다. Observation만 남아 있는 `dirty` 상태는 봉인된 커밋의 병합을 막지는 않지만 Worktree 삭제는 막는다. AI Dev Workflow 배포 저장소로 자동 전송되지 않으므로 main은 삭제 가능 여부를 안내하기 전에 개선 기록의 보존 여부도 확인한다.

### 문제가 생겼을 때

정상 흐름에서는 사용하지 않는다. `BLOCKED`의 담당이 불명확하거나 상태 불일치·충돌·복구가 필요할 때만 사용한다.

```text
Read `.ai/reference/OPERATIONS.md` and handle this issue:
<현재 문제를 한 줄로 작성>
```

- `OUTCOME=resolved` → 정상 흐름으로 복귀
- `OUTCOME=routed` → 지정된 역할 세션으로 이동
- `OUTCOME=blocked owner=user` → 요청된 정보나 결정 제공

`owner=user`이면 왜 필요한지, 정확한 앱·경로·순서, PASS 기준, 복붙할 답변 형식과 대안이 함께 나와야 정상이다. 안내대로 확인한 뒤 그 요청을 만든 같은 세션에 결과를 답한다. `Editor/PIE 근거 제공`처럼 한 줄만 나오면 같은 세션에 `내가 정확히 무엇을 어떻게 확인해야 해?`라고 물어도 된다. Workflow는 사용자의 조치를 요구하기 전에 이 안내를 제공해야 한다.

### Workflow 개선과 업데이트

사용 중 놓치고 싶지 않은 문제가 있으면 어느 세션에서든 말한다.

```text
방금 문제를 Workflow 개선 후보로 기록해줘.
```

명백한 오경로·가짜 BLOCKED·필수 안내 누락·반복 복구 실패처럼 증거가 있는 Workflow 문제는 역할이 작업을 멈추는 시점에 자동으로 중복 없이 기록한다. 일반 코드 버그나 한 번의 실수는 자동 기록하지 않는다. 기록될 때만 `WORKFLOW_OBSERVATION=<path>` 한 줄이 나온다.

<details>
<summary>여러 프로젝트·Worktree의 개선 기록 취합</summary>

기록은 서로 자동 공유되지 않는다. 별도 **AI Dev Workflow 배포 저장소**를 열고 설치본 경로만 전달한다.

```text
다음 설치본들의 Workflow 개선 기록만 이 배포 저장소에 취합해줘.
sources:
- <프로젝트 또는 Worktree 경로>
- <프로젝트 또는 Worktree 경로>
```

`OBS-*.yaml`만 가져오며 재수집해도 중복 집계하지 않는다. 코드·Knowledge·Lane·Task·Eval과 Workflow Core는 변경하지 않는다. 취합 후 실제 개선 여부를 판단할 때만 말한다.

```text
취합된 Workflow 개선 기록을 검토하고 업데이트 후보를 정리해줘.
```

</details>

### GitHub용 `.ai` 복사본 갱신

개발 프로젝트의 `.ai`를 정리하거나 지우지 않는다. 상태가 모두 남아 있는 개발 프로젝트와, 프로젝트 내용이 없는 GitHub 배포용 복사본을 별도로 유지한다.

```text
개발 프로젝트/.ai       → Knowledge·Lane·Task·Review를 그대로 보존
AI-Dev-Workflow/.ai     → 공통 Workflow만 담은 별도 배포용 복사본
```

공통 개선을 배포용 복사본에 반영하려면 별도 **AI Dev Workflow 배포 저장소**를 새 AI 세션으로 열고 다음 한 번만 보낸다.

```text
Read `.ai/maintenance/MAINTAIN.md` and run BUILD_RELEASE_COPY.
sources:
- <개발 프로젝트 또는 Worktree 경로>
user_language=ko
```

이 명령은 지정한 개발 프로젝트를 읽기 전용으로 비교하고, Observation과 공통 Workflow 파일의 차이를 개선 후보로 사용한다. 개발 프로젝트의 파일은 삭제·정리·수정하지 않는다. 프로젝트 Knowledge·실제 Lane·Architecture·Task·Build·Review·Integration·업데이트 상태도 배포용 복사본에 넣지 않는다.

승인 가능한 공통 변경만 별도 `AI-Dev-Workflow/.ai`에 일반화해 반영하고 버전·Changelog·Eval·검증까지 마친다. 중요한 정책 충돌은 적용하지 않고 먼저 묻는다.

성공 결과가 `BUILD_RELEASE_COPY RESULT=ready_to_publish`이면 `AI-Dev-Workflow/.ai`가 GitHub에 올릴 최신 복사본이다. 커밋과 Push는 실행하지 않으므로 변경 내용을 확인한 뒤 GitHub Desktop에서 올리면 된다. `no_change`이면 올릴 새 공통 변경이 없고, `blocked`이면 함께 나온 충돌이나 사용자 결정을 먼저 해결한다.

<details>
<summary>무엇이 보존되고 무엇이 반영되는가</summary>

| 구분 | 처리 |
|---|---|
| 개발 프로젝트의 코드·문서 | 읽거나 복사하지 않음 |
| Project Knowledge·Architecture·실제 Lane·Task·Build·Review | 개발 프로젝트에 그대로 보존 |
| Observation과 공통 파일 Diff | 개선 여부를 판단하는 후보로만 사용 |
| `BOOTSTRAP`, `WORKFLOW`, 역할·계약·공통 템플릿 | 승인된 일반 개선만 배포용 복사본에 재적용 |
| 버전·Changelog·Eval | 배포용 복사본에서 갱신·검증 |
| 커밋·Push | 사용자가 Diff를 확인한 뒤 수행 |

배포본을 다시 프로젝트에 적용할 때도 관리 대상 공통 파일만 갱신하고 기존 Knowledge·Lane·작업 기록은 보존하므로, 제외된 프로젝트 상태를 다시 만들 필요가 없다.

</details>

각 개발 프로젝트에서는 배포 출처를 처음 한 번 지정한 뒤 업데이트 확인과 적용을 나눠 실행한다.

```text
Workflow 업데이트 확인해줘. source=<GitHub URL 또는 로컬 경로>
확인된 Workflow 업데이트 적용해줘.
```

업데이트 후에는 업데이트가 적용된 Checkout을 사용하는 모든 기존 세션을 종료하고 같은 Lane·역할의 Bootstrap Prompt로 다시 만든다. 여기에는 모든 병렬 Lane과, 엄격한 구성이라면 네 역할 세션 전부가 포함된다.

---

## 설명

### 역할과 Gate

| 역할 | 담당 | 하지 않는 일 |
|---|---|---|
| Work 세션 | 현재 상태에 따라 Knowledge·Architect·Builder 계약 중 하나를 수행 | Reviewer 역할, 자기 결과 승인 |
| Knowledge Maintainer | 현재 프로젝트의 사실·위치·출처와 변경분 색인 | 설계 결정, 코드 구현 |
| Architect | 요구사항, 구조, 책임, 인터페이스, 작은 Task | 프로덕션 코드 구현 |
| Builder | 승인된 Task 구현과 검증 | 구조 변경, 자기 승인 |
| Reviewer | 실제 Diff와 증거를 독립 검증 | 코드 수정, 취향에 따른 재설계 |

중요한 Architecture와 사용자 소유 결정은 사용자가 승인하고, 그 안의 일반 Task는 Architect가 승인할 수 있다. Builder 결과는 별도 Reviewer가 PASS해야 수용된다. 구현 문제는 Builder, 구조·공개 계약은 Architect, 결과물 형식 문제는 해당 작성 역할이 수정한다. Knowledge는 매 Task마다 강제 실행하지 않고 필요한 변경을 즉시 반영하거나 같은 Feature 안에서 묶어 갱신한다.

모든 세션에서 자유롭게 질문할 수 있다. Work/Architect에게 설계 근거와 영향을, Reviewer에게 문제의 근거·재현 방법·수동 검증 방법과 위험을 물어볼 수 있다.

### 변경을 이해하는 흐름

별도 학습 세션이나 의무 질문은 없다. Architect는 중요한 구조를 승인받기 전에 현재 동작, 바뀔 흐름, 실제 영향, 제외 범위와 재검토 조건을 한국어로 보여준다. 영어 Architecture 링크는 근거일 뿐 설명을 대신하지 않는다. Reviewer는 PASS 후 실제 구현 기준으로 목적, 전후 동작, 핵심 흐름, 지켜야 할 조건과 직접 확인할 위치를 `Change Brief`로 보여준다.

설명 깊이는 변경에 맞춘다. 이름·서식 같은 기계적 변경은 생략하고, 일반 동작 변경은 짧게, 구조·수명주기·동시성·네트워크·저장 방식처럼 사고 모델이 중요한 변경만 자세히 설명한다. 설명은 새로운 Source of Truth가 아니라 해당 Review revision을 이해하기 위한 안내다.

더 깊이 이해해야 할 때는 같은 Reviewer 세션에 다음처럼 말한다.

```text
이 변경을 내가 다음 수정까지 직접 판단할 수 있게 설명해줘.
```

직접 조작해야 이해하기 쉬운 복잡한 시스템이라면 Reviewer가 디버거·시각화 같은 작은 도구를 선택 사항으로 제안할 수 있다. 이는 자동 생성하거나 PASS 조건으로 삼지 않고, 필요할 때 Architect에서 별도 Task로 승인한다.

### Knowledge

Knowledge는 프로젝트 전체의 요약본이나 복사본이 아니다. 다시 찾을 가치가 있는 사실만 `경로 + 심볼/섹션 + revision + 상태`로 저장하는 출처 기반 색인이다.

반복해서 쓰는 프로젝트 고유 용어와 별칭은 `.ai/shared/knowledge/glossary.yaml`에 출처와 함께 저장한다. 일반 용어 사전이나 한 번 쓸 줄임말은 만들지 않는다. 짧은 요청도 프로젝트와 같은 의미로 해석하기 위한 색인이다.

최초 BUILD에서는 저장소 구조, 빌드 명령, 주요 진입점, 공개 경계와 문서 위치를 단계적으로 찾는다. 모든 파일이나 클래스 목록을 읽어 저장하지 않는다.

GDD, TDD, API, 코딩 규칙, 설정과 데이터 스키마도 대상이다. PDF·DOCX·이미지는 도구마다 지원이 다르므로 가능하면 Markdown 또는 텍스트 버전을 함께 둔다. 채팅에만 첨부한 중요한 자료는 다음 세션이 검증할 수 없으므로 프로젝트의 `Docs/` 같은 폴더에 저장한다.

- 파일 경로가 있으면 해당 파일과 직접 관련된 항목만 `UPDATE`한다.
- 경로가 없으면 Git Status/Diff로 변경 범위를 찾는다.
- Git Pull/Merge는 저장된 revision과 현재 `HEAD`를 비교한다.
- 프로젝트의 사실·위치 질문은 읽기 전용 `QUERY`로 답한다.
- 설계·추천 질문은 근거를 제공하고 Architect로 보낸다.

Knowledge가 오래됐거나 구조와 충돌하면 자동으로 전체 갱신하거나 Architecture를 수정하지 않고 `UPDATE`, `VALIDATE` 또는 Architect가 필요하다고 알린다.

### 상태, Context, 언어

채팅은 교체 가능한 작업자이고 파일과 Git이 상태를 보존한다. 각 세션은 `lane.yaml`, `state.yaml`과 현재 Architecture·Task·결과물만 읽어 작업을 복원한다.

정상 작업에서는 `BOOTSTRAP + 현재 역할 + 현재 Lane/Task + 필요한 근거 파일`만 읽는다. 경로·심볼·섹션·Diff를 우선 사용하고, 증거가 부족할 때만 Context를 확장한다. Operations, Integration, Eval 문서는 필요한 상황에서만 읽는다.

`.ai` 내부 문서는 토큰 효율과 모델 간 일관성을 위해 영어로 유지한다. 사용자가 영어 파일을 읽어야 승인할 수 있게 만들지는 않는다. 채팅의 Decision Brief, 질문, 실패 영향, Change Brief, 수동 검증 안내는 `user_language=ko`에 따라 한국어로 나오며, `RESULT`, `PASS` 같은 기계 판독 값만 영어로 유지된다. 코드와 게임 문구는 프로젝트 규칙을 따른다.

비-main 세션 종료 시 재개에 필요한 상태를 파일에 남기고 `RETURN_TO_MAIN`으로 접수처에 복귀한다. main은 파일과 Git을 근거로 `NEXT_SESSION`, Integration, 사용자 조치 또는 종료 중 하나를 선택한다. 조건을 만족한 Workflow 불편은 별도 Observation 파일에 남고, 전체 대화는 전달하지 않는다.

### Lane과 Worktree

이 Workflow의 표준 사용법은 `main` Lane 하나다. Lane은 모델명·세션명·Worktree명이 아니며, Worktree를 만들거나 AI 도구를 바꿔도 자동으로 달라지지 않는다. 위의 모든 복붙 Prompt가 `lane=main`만 사용하는 것은 의도된 구성이다.

평소에는 Lane을 만들거나 관리할 필요가 없다. 서로 겹치지 않고 독립적으로 빌드·검증할 수 있는 작업을 실제로 동시에 진행할 때만 Architect가 수정 경로, 공유 계약과 통합 순서를 나누고, main 접수처가 각 Lane의 `PARALLEL_START`를 생성한다. 이후 세션 교체와 Lane 이동도 main의 `NEXT_SESSION`으로만 시작하므로 사용자는 Lane Prompt를 직접 조립하지 않는다.

같은 Lane의 Work·Reviewer는 같은 Worktree를 사용하고 다른 Lane의 소유 경로는 수정하지 않는다. 하나의 세션도 Bootstrap 뒤에는 해당 Worktree·Lane에 고정한다. 새 Lane은 기준 커밋의 Knowledge를 재사용한다. 병합 전 다음 Lane 작업이 새 색인을 꼭 필요로 할 때만 `knowledge-delta`를 만들고, 공용 Knowledge 반영은 main 통합 검증 뒤에 한다.

Reviewer PASS 후 사용자는 `RETURN_TO_MAIN`의 복붙 문장만 main Work에 전달한다. main Work는 이미 승인된 순서대로 정확히 봉인된 후보 하나만 병합하고, main Reviewer가 기록된 병합 전후 범위와 실제 통합 결과를 검증한다. 모든 후보가 검증된 뒤 Knowledge Maintainer가 최종 `main` 코드 기준으로 Knowledge를 동기화한다.

`.ai` 내부의 나머지 문서는 AI용이므로 사용자가 읽을 필요가 없다.

### 배포 저장소와 프로젝트 설치본

AI Dev Workflow 저장소는 공통 Workflow를 보관하고 배포한다. 저장소 자체의 Git 이력, `tools/`, `.github/`는 배포본 유지보수와 게시 전 검증에만 사용한다. 실제 프로젝트는 복사된 `.ai`와 그 프로젝트 자신의 Git을 사용하며, 배포 저장소의 `.git`을 복사하거나 공유하지 않는다.

현재 Workflow 버전의 유일한 기준은 `.ai/maintenance/release.yaml`이다. Scorecard 템플릿은 버전을 고정하지 않고, 실제 Eval 기록을 만들 때 해당 값을 복사한다. 이미 완료된 과거 Eval의 버전은 변경하지 않는다. 설치본의 공통 개선을 별도 배포용 복사본에 반영할 때는 위의 `BUILD_RELEASE_COPY`를 사용하며 `.ai` 전체를 역복사하거나 개발 프로젝트를 정리하지 않는다.

배포 저장소를 수정하거나 GitHub에 올리기 전에는 저장소 루트에서 다음 읽기 전용 검사를 실행한다.

**Windows 기본 환경 — Windows PowerShell 5.1 (`powershell.exe`)**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\validate-workflow.ps1
```

**PowerShell 7 설치 환경 — `pwsh`**

```powershell
pwsh -NoProfile -File ./tools/validate-workflow.ps1
```

검사는 현재 버전 정보의 일치, 필수 파일, 내부 파일 참조, Markdown 링크와 코드 펜스 균형을 확인한다.

GitHub에 Push하거나 Pull Request를 만들면 `.github/workflows/validate.yml`이 같은 검사를 실행하도록 구성되어 있다. 최초 게시 후에는 GitHub Actions 결과까지 PASS인지 확인해야 하며, 로컬 PASS만으로 원격 CI 성공을 주장하지 않는다.

이 도구는 프로젝트 작업이나 AI 세션을 자동화하지 않으며 설치 대상에 복사할 필요가 없다.
