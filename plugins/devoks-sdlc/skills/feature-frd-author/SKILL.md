---
description: 거친 기능 아이디어나 FRD 초안을 받아, EARS Acceptance Criteria·Contract(파라미터/상태전이)·Resource 체크리스트·Edge Case·Testing Strategy를 갖춘 정련된 FRD.md로 완성한다. "FRD 초안 정리해줘", "기능 요구서 다듬기", "요구사항을 EARS로 정형화", "AC/Contract 정리", "스펙 문서 작성" 같은 요청에서 사용한다. 초안의 의도(누구·왜·성공 기준·하지 않을 것)가 비었거나 방향이 여러 갈래면 Phase 0에서 devoks-sdlc:feature-interview 로 먼저 정련한 뒤 이어서 진행한다. FRD→PLAN→실행 전체를 한 번에 돌리려면 devoks-sdlc:feature-workflow-runner, 작성 후 작업 분해는 devoks-sdlc:feature-plan-author 를 쓴다.
argument-hint: "[frd=<초안 경로|본문> (default: 대화 초안)] [out=<디렉터리> (default: 워크스페이스)]"
metadata:
  author: ridsync
  version: 1.4.0
---

# frd-author — FRD 정련 (Phase 1)

거친 초안을 검증 가능한 FRD로 만든다. `devoks-sdlc:feature-workflow-runner` 의 **Phase 1만** 단독 실행하는 얇은 스킬이다.
공유 자산/레퍼런스는 통합 스킬 디렉터리를 그대로 참조한다(중복 정의 금지, SSOT).

## 호출 방법

```
/devoks-sdlc:feature-frd-author [frd=<초안 경로|본문> (default: 대화 초안)] [out=<디렉터리> (default: 워크스페이스)]
```

> 표기: `key=값` 필수 · `[key=값]` 선택 · `(default: X)` 미지정 시 X로 진행.

- `out` 기본값 = `.claude/workspace/{feature-name}-{date}/`. 산출물 = `<out>/FRD.md`. → `../feature-workflow-runner/references/output-location.md`
- 워크스페이스에는 FRD 문서와 입력 초안·리소스 사본만 모은다. 코드는 두지 않는다(이 스킬은 코드 미생성).

## 절차

**Phase 0 — 의도·방향 게이트 (조건부, HITL)** — 초안을 읽고 §1의 대상 사용자·Success·Non-goals를 **추측해야만** 채울 수 있거나(의도 공백), 무엇을 만들지 **방향이 여러 갈래**로 열려 있으면, 슬롯 질문으로 메우지 않고 Skill 도구로 `devoks-sdlc:feature-interview`에 진입한다(그 스킬 절차를 이 흐름 안에서 수행). 사용자가 정련 요약을 승인하면 그 요약을 초안으로 아래 절차 0부터 이어간다. 초안이 이미 승인된 정련 요약이거나 의도·방향이 분명하면 게이트를 건너뛴다. 사용자가 인터뷰를 원치 않으면 아래 절차 7의 일괄 확인으로 진행한다. 비-HITL 경로에서는 게이트를 열지 않고 의도 공백을 blocked로 보고한다.

0. **워크스페이스 확정 · 초안 원문 보존** — `out` 경로 `.claude/workspace/{feature-name}-{date}/`(date=`yyyyMMdd`)를 정한다. 시안·시각 리소스 사본은 **`<out>/assets/`** 에 `RES-ASSET-NNN_<slug>` 네이밍으로 저장하고(시안 외 대용량·저장소 안 리소스는 경로만 기록), FRD §6.3 Assets 표 ID와 일치시킨다. **본문으로 받은 초안은 `<out>/FRD.draft.md` 로 원문 그대로 보존**한다: 짧은 출처 헤더 + 초안 원문 verbatim + 정련 중 사용자 확인으로 확정된 결정 누적(추측 금지). 정련 결과는 `FRD.md`. → 디렉토리·`assets/`·보존 형식 근거는 `../feature-workflow-runner/references/output-location.md`(SSOT).
   - 초안이 `feature-interview`의 **승인된 정련 요약**(`## 기능 정련 요약`)이면 그 값은 사용자가 승인한 것이므로 다시 묻지 않고 §1(Outcome·User·Why now·Success·Out of scope → 대상 사용자·Success·Non-goals), §2·§3(방향·논의 중 결정), §10(가정·남은 질문)의 근거로 쓴다. 요약도 다른 초안과 똑같이 `FRD.draft.md`로 보존한다(요약 첫 줄의 "원래 요청"이 인터뷰 전 원문이다). 요약의 "남은 질문"은 사용자가 보류한 것이라 절차 7 슬롯 확인에 한 번 더 넣어도 되고, 다시 보류되면 §10으로 넘긴다.
   - `FRD.draft.md`가 이미 있으면 덮어쓰지 않고 먼저 읽는다.
1. **골격 로드** — `../feature-workflow-runner/assets/FRD.template.md` 를 읽어 형식을 따른다.
2. **요구 추출** — 초안에서 Goal(대상 사용자·Why now·Success·Non-goals 포함)·Context·요구사항 후보를 뽑는다.
3. **EARS 정형화** — 각 요구를 `REQ-xxx` + `AC-xxx-y`(정상 WHEN/WHILE + 예외 IF 최소 1쌍)로. → `../feature-workflow-runner/references/ears-acceptance-criteria.md`
4. **분리 기재** — 수치/세팅/상태전이 → §5 Contract(`CTR-xxx`), 예외 상황 → §8 Edge(`EDGE-xxx`). 요구가 **기존 데이터의 특정 필드/형태**(비교 키, 마이그레이션 폴백, 다른 기능이 이미 채워놓은 값 등)에 의존하면, 그 필드가 실환경에 실제로 그 형태로 존재하는지 확인하는 항목을 `EDGE-xxx`로 반드시 추가한다 — 유닛테스트는 mock 데이터로 통과해도 실데이터 형태가 다르면 기능이 아예 발동하지 않을 수 있다. 같은 방식으로, 요구가 **사용자가 의도적으로 반복 트리거하는 조작**(증감 스테퍼, 연속 제출, 검색어 입력, 스크롤 페이징 등)을 포함하고 그 조작이 **상태를 확정하거나 I/O를 유발**하면(`.claude/refs/interaction-integrity.md` §1 적용 대상 판정), 연타 시의 기대 동작을 `EDGE-xxx`로 반드시 추가한다 — 조작의 의미(누적 → 입력 횟수만큼 반영 / 최종값 → 마지막 값만 / 단발 → 1회만 확정)와 I/O 코얼레싱 기대치를 함께 적는다. 단발 조작만 명세하면 저사양 기기에서만 드러나는 유실·중복을 스펙 단계에서 놓친다. 표시만 바꾸는 조작은 대상이 아니다.
5. **착수 리소스** — §6(참고 코드·외부 문서·시안·API), §7 Constraints(위험/의존 제약·기술 제약)를 채운다. PR 분리 여부·개수는 이 단계에서 정하지 않는다(PLAN 단계 — `../feature-workflow-runner/references/task-pr-splitting.md`).
6. **§4 설계 스펙** — 복잡도 임계 초과 시(신호 목록·기준: `../feature-workflow-runner/references/design-spec.md`) 코드 패턴을 먼저 탐색하고 **설계안을 제안·확인**한 뒤 컴포넌트 구조·패턴(`DSN`)·모듈 배치를 채운다. 단순 기능은 §4.1만 간결히.
7. **확인 후 작성** — 누락 슬롯은 한 번에 모아 사용자에게 확인(추측 금지 — 요구는 묻고, 설계는 제안 후 확인) → `<out>/FRD.md` 작성. 검증되지 않은 가정과 답이 보류된 질문은 §10에 남긴다.
   - **질문 단위 규칙** — 여기서 한 번에 모아 묻는 것은 **슬롯·정책**(필드 구성, 상태값, 편집 범위, 이관, 인증 방식 등)이다. 의도 수준 공백은 여기 섞지 않는다 — Phase 0 게이트(`feature-interview`, 한 번에 하나씩)가 맡는다.

## 완료 기준

- §1에 대상 사용자·Success(가능하면 측정값)·Non-goals(최소 1개)가 있음.
- §10 Assumptions & Open Questions가 채워짐(없으면 "없음").
- 모든 REQ가 검증 가능한 AC를 가짐(통과/실패 판정 가능).
- 측정값은 CTR로, 예외는 EDGE로 분리됨.
- 기존 데이터 의존 로직이 있는 요구는 그 데이터 리얼리즘(실환경 필드/형태 존재 여부)을 확인하는 EDGE case가 최소 1개 있음.
- 반복 트리거 조작이 상태 확정·I/O를 유발하는 요구는 연타 시 기대 동작을 규정한 EDGE case가 최소 1개 있음.
- 복잡도 임계 초과 기능은 §4 설계 스펙(컴포넌트/패턴/배치)이 채워지고 확인됨.
- ID 체계(`REQ`/`AC`/`CTR`/`EDGE`/`DSN`)가 일관되어 다음 단계(PLAN)의 `traces`로 바로 인용 가능.
- `FRD.md` 작성 완료 시 frontmatter `status: draft → review`. → `../feature-workflow-runner/references/progress-tracking.md`

> 막히면 `../feature-workflow-runner/references/example-walkthrough.md` 의 완성 예시를 참고한다.
