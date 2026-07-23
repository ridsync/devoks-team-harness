---
description: FRD의 AC(Acceptance Criteria) 중 UI 조작과 상태 영속이 걸린 항목을, 이미 실행 중인 앱에서 실제로 조작해 검증한다. 단위/통합/E2E 자동화 테스트 스위트와 달리 테스트 코드를 남기지 않는 1회성 실동작 확인이다 — 진입 경로(라우트) → 사전 상태 세팅 → 조작(클릭/입력) → 기대 UI 상태 → 기대 영속 상태(DB 필드 대조) 순으로 실행하고 시나리오별 PASS/FAIL 리포트를 낸다. devoks-browser 플러그인(Chrome DevTools MCP, 9269 attach)이 설치돼 있어야 한다. "실동작 검증", "브라우저로 실제 확인", "AC가 실제로 동작하는지", "기능이 실제 앱에서 되는지", "acceptance test", "실기기/에뮬레이터 확인" 키워드에서 호출한다. 레이어별 계측·3중 대조가 필요한 데이터 정합성 심층 검증은 devoks-sdlc:verify-data-flow를 쓴다.
metadata:
  author: ridsync
  version: 1.0.0
---
# verify-acceptance-test — 실동작 인수 검증

FRD의 AC를 **실행 중인 앱에서 실제로 조작해** 검증하는 워크플로우. 단위/통합/E2E 자동화 스위트(코드로  
남아 회귀 때마다 재실행)와는 목적이 다르다 — 이 스킬은 **구현 직후 1회, 사람이 손으로 하던 수동 테스트를**  
**에이전트가 대신 수행**하고 리포트만 남긴다. lint/유닛테스트/코드리뷰가 잡지 못하는 두 가지 갭을 메운다:

1. 목(mock) 데이터로는 드러나지 않는 **실데이터 형태 불일치**(예: 의존하는 필드가 실환경에서 `null`).
2. 유닛테스트로는 확인할 수 없는 **UI 조작 → 상태 전이 → 영속화의 종단 동작**.

## devoks-browser 의존성

이 스킬은 `devoks-browser` 플러그인(Chrome DevTools MCP, `mcp__chrome-devtools-attach__*`, 9269 attach)이
설치돼 있어야 동작한다 — `plugin.json`의 `dependencies`에 선언돼 있어 devoks-sdlc 설치 시 함께 설치된다.
미설치 시 리포트에 "devoks-browser 미설치"를 기록하고 설치를 안내한다(추측으로 진행하지 않는다).

## 호출 방법

```
/devoks-sdlc:verify-acceptance-test [ac=<검증 대상 AC ID 목록>] [frd=<FRD.md 경로>] [route=<진입 라우트>] [persistence=<영속 조회 방법>]
```

**예시:**

```
/devoks-sdlc:verify-acceptance-test ac="AC-003-1,AC-003-2" frd=.claude/workspace/mark-calibration-20260722/FRD.md route=/settings/extraction persistence="IndexedDB(PouchDB) evaluate_script 조회"
```

인자가 없어도 동작한다. Phase 0에서 1회 확인한다.

## 추상 슬롯 (프로젝트별 사용자가 채움)


| 슬롯                         | 의미                                            | 입력 방법                          |
| -------------------------- | --------------------------------------------- | ------------------------------ |
| `<TargetAC>`               | 검증 대상 AC ID 목록(UI 조작+상태 영속이 걸린 것만 선별)         | `ac` 인자 또는 FRD에서 Phase 0 확인    |
| `<FRDSource>`              | AC 원문·traces 확인용 FRD 경로                       | `frd` 인자 또는 Phase 0 확인         |
| `<EntryRoute>`             | 시나리오 진입 라우트/화면                                | `route` 인자 또는 Phase 0 확인       |
| `<PreconditionSetup>`      | 조작 전 필요한 사전 상태(설정값/시드 데이터)                    | Phase 0에서 AC·Contract 근거로 도출   |
| `<Interactions>`           | 수행할 조작 순서(클릭/입력/대기)                           | Phase 0에서 AC 근거로 도출            |
| `<ExpectedUIState>`        | 조작 후 기대하는 화면 상태(문구/단계/표시)                     | Phase 0에서 AC 근거로 도출            |
| `<ExpectedPersistence>`    | 조작 후 기대하는 영속 상태(필드/값)                         | Phase 0에서 AC·Contract 근거로 도출   |
| `<PersistenceCheckMethod>` | 영속 상태를 실제로 조회하는 프로젝트별 방법(DB API, 동적 import 등) | `persistence` 인자 또는 Phase 0 확인 |
| `<DevServerURL>`           | 이미 실행 중인 dev server URL                       | Phase 0 확인                     |
| `<AuditMarker>`            | 임시 패치가 필요할 때 식별 마커                            | 기본 `ACCEPT-TEMP`               |
| `<VerifyCommands>`         | 임시 패치 회수 후 검증 명령                              | Phase 0 확인                     |


> 슬롯 값은 실행 시점에만 사용하며 SKILL.md에 저장하지 않는다.

---

## `verify-data-flow`와의 경계


|          | `verify-acceptance-test` (본 스킬) | `verify-data-flow`            |
| -------- | ------------------------------- | ----------------------------- |
| 주도 방식    | UI 조작 주도, 1회성 최종 상태 확인          | 레이어별 계측, 3중 대조(의도↔저장↔재로드)     |
| 목적       | AC가 실제 앱에서 사용자 관점으로 동작하는가       | 데이터가 각 레이어를 거치며 정확히 흐르고 저장되는가 |
| 영속 대조 깊이 | 최종 값 1회 조회로 충분한 경우 직접 수행        | 다층 계측이 필요할 때                  |


영속 대조가 얕은 1회 조회로 부족하다고 판단되면(다층 계측 필요), 이 스킬의 리포트에서
`devoks-sdlc:verify-data-flow` 호출을 제안하고 중복 구현하지 않는다.

---

## Phase 0 — 시나리오 합의 (입력)

목적: **어떤 AC를, 어떤 시나리오로, 무엇을 기대하며 확인할지**를 1회 합의한다.

1. `$ARGUMENTS`에서 슬롯 파싱.
2. `<FRDSource>`가 있으면 Read해 AC(EARS)·Contract(CTR)·Edge(EDGE) 중 **UI 조작 + 상태 영속이 걸린 항목만** 선별한다. 순수 로직/타입/설정값만 다루는 AC는 대상에서 제외한다(유닛테스트가 이미 충분히 커버).
3. 미충족 슬롯을 1회 확인:
  - "검증할 AC ID, 진입 라우트, 사전 상태 세팅 방법, 영속 상태 조회 방법(예: DB API, 콘솔 evaluate_script)을 알려주세요."
4. AC별 **시나리오 표**를 작성한다 — 이 표가 Phase 1~4 실행 계획이자 Phase 5 리포트의 뼈대가 된다:
  
  | AC ID    | 진입 경로                  | 사전 상태    | 조작          | 기대 UI 상태   | 기대 영속 상태                       |
  | -------- | ---------------------- | -------- | ----------- | ---------- | ------------------------------ |
  | AC-003-1 | `/settings/extraction` | 기계보정 미완료 | 보정 완료 버튼 클릭 | "완료" 배지 표시 | `calibration.completedAt` 값 존재 |
  
5. devoks-browser 설치 여부를 1회 확인한다(미설치면 Phase 1로 진행하지 않고 안내).

---

## Phase 1~4 — 실행·대조 (에이전트 위임)

> ⚠️ **실행 주체는 `acceptance-test-runner` 에이전트이다.** 스크린샷·콘솔 바이트는 에이전트 컨텍스트에
> 격리되고, 메인 루프에는 시나리오별 PASS/FAIL **리포트만** 리턴된다.

Phase 0에서 확정된 시나리오 표로 `acceptance-test-runner` 에이전트를 호출한다:

- **전달 슬롯**: 시나리오 표 전체, `<DevServerURL>`, `<PersistenceCheckMethod>`, `<AuditMarker>`
- **에이전트 수행 내용**: 시나리오별로 `사전 상태 세팅 확인 → 조작 실행 → UI 상태 대조 → 영속 상태 대조`를 반복(상세 절차는 `references/scenario-execution.md`)
- **리턴값**: 시나리오별 PASS/FAIL 표 + 불일치 증거 + 임시 패치 회수 여부를 담은 **검증 리포트**

**예외 처리**: 에이전트 리포트에 "Chrome DevTools MCP 연결 실패"가 포함되면, 사용자에게 1줄로 요청한다:
`"Chrome 브라우저를 --remote-debugging-port=9269 옵션으로 실행해 주세요."` → 확인 후 재시도.

---

## Phase 5 — 검증 리포트

`references/report-template.md` 템플릿으로 리포트를 작성한다(에이전트가 Phase 1~4 결과로 초안을 만들고,
메인 루프가 그대로 수령·출력한다). 저장은 선택 — 대상 프로젝트 문서 디렉토리에 남기고 싶으면 파일명은
`<대상>-verify-acceptance-test-result.md`.

---

## Phase 6 — 회수 + 검증

1. 임시 패치가 있었다면 전량 식별:
  ```bash
   grep -rn "[[ORCA_RICH_MD:31eece837df50ada5b81f733779eb865:inline-html:%3CAuditMarker%3E]]" <소스 루트>
  ```

   마커 규약은 `../verify-data-flow/SKILL.md`(핵심 원칙 "계측은 임시, 반드시 회수")와 동일한 메커니즘이다 — 새로 만들지 않고 그대로 재사용한다.
2. 식별된 패치를 모두 제거(원복)한다.
3. 회수 후 검증:
  ```bash
   <VerifyCommands>
   git diff --stat   # → 의도한 변경만 남고 임시 패치 흔적은 0이어야 함
  ```
4. **검증 환경 갭**(에뮬레이터/환경이 특정 상태를 재현하지 못해 임시 패치가 불가피했던 경우): 리포트에
 "검증 환경 갭"으로 명시하고, 사용자에게 대상 프로젝트의 이슈 트래커/백로그 등록을 제안한다(새 인프라를
 만들지 않고 안내만).

---

## Reference 파일 목록


| 파일                                 | 내용                                                 | 참조 주체                       |
| ---------------------------------- | -------------------------------------------------- | --------------------------- |
| `references/scenario-execution.md` | 시나리오 실행 절차(사전상태 확인·조작·UI/영속 대조), 프로젝트별 영속 조회 패턴 예시 | acceptance-test-runner 에이전트 |
| `references/report-template.md`    | 검증 리포트 템플릿                                         | Phase 5                     |


