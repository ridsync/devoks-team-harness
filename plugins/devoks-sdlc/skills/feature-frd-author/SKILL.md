---
description: 거친 기능 아이디어나 FRD 초안을 받아, EARS Acceptance Criteria·Contract(파라미터/상태전이)·Resource 체크리스트·Edge Case·Testing Strategy를 갖춘 정련된 FRD.md로 완성한다. "FRD 초안 정리해줘", "FRD 입력 양식 줘", "기능 요청 양식", "기능 요구서 다듬기", "요구사항을 EARS로 정형화", "AC/Contract 정리", "스펙 문서 작성" 같은 요청에서 사용한다. 초안의 의도(무엇이 달라지는지·누구를 위한 것인지)가 비었거나 방향이 여러 갈래면 Phase 0에서 devoks-sdlc:feature-interview 로 먼저 정련한 뒤 이어서 진행한다. FRD→PLAN→실행 전체를 한 번에 돌리려면 devoks-sdlc:feature-workflow-runner, 작성 후 작업 분해는 devoks-sdlc:feature-plan-author 를 쓴다. 입력은 FRD 입력 양식(FRD.intake.md)이 SSOT이며 양식만 요청하면 빈 양식을 준다.
argument-hint: "[frd=<초안 경로|본문> (default: 대화 초안)] [out=<디렉터리> (default: 워크스페이스)]"
metadata:
  author: ridsync
  version: 1.7.1
---

# frd-author — FRD 정련 (Phase 1)

거친 초안을 검증 가능한 FRD로 만든다. `devoks-sdlc:feature-workflow-runner` 의 **Phase 1만** 단독 실행하는 얇은 스킬이다.
공유 자산/레퍼런스는 통합 스킬 디렉터리를 그대로 참조한다(중복 정의 금지, SSOT).

> 범위: 기능 하나의 요구서다. 제품·장기 프로젝트 전체의 문제·목표·범위·기능 백로그는 `devoks-sdlc:product-prd-author`가 소유한다 — 그 백로그(`FEATURES.md`)의 **FRD 시드** 블록을 `frd` 초안으로 받으면 §1 의도 슬롯이 채워진 상태라 Phase 0 게이트를 건너뛸 수 있고, PRD의 공통 NFR(`NFR-n`)·제약은 §7에서 재정의하지 않고 참조한다.

## 호출 방법

```
/devoks-sdlc:feature-frd-author [frd=<초안 경로|본문> (default: 대화 초안)] [out=<디렉터리> (default: 워크스페이스)]
```

> 표기: `key=값` 필수 · `[key=값]` 선택 · `(default: X)` 미지정 시 X로 진행.

- `out` 기본값 = `.claude/workspace/{feature-name}-{date}/`. 산출물 = `<out>/FRD.md`. → `../feature-workflow-runner/references/output-location.md`
- 워크스페이스에는 FRD 문서와 입력 초안·리소스 사본만 모은다. 코드는 두지 않는다(이 스킬은 코드 미생성).
- **입력 형식 SSOT** — `assets/FRD.intake.md`(★ Outcome·User·Success·Out of scope). 사용자가 채운 양식, `feature-interview`의 정련 요약, `product-prd-author` FEATURES.md의 FRD 시드가 모두 이 형식이다. 자유 형식 초안·유지보수 요청도 받는다 — 그때는 ★ 칸을 초안에서 추출한다.

### 양식만 요청받은 경우

"FRD 양식 줘"처럼 입력 양식만 원하면 `assets/FRD.intake.md`를 `out`이 있으면 `<out>/FRD.intake.md`로 복사하고, 없으면 양식을 대화에 그대로 보여 준다. "채운 뒤 `/devoks-sdlc:feature-frd-author frd=<파일>`" 한 줄을 안내하고 멈춘다(FRD는 쓰지 않는다).

## 절차

**Phase 0 — 의도·방향 게이트 (조건부, HITL)** — 초안을 읽고 **무엇이 달라지는지(Outcome)·누구를 위한 것인지(User)**를 추측해야만 채울 수 있거나(의도 공백), 무엇을 만들지 **방향이 여러 갈래**로 열려 있으면, 슬롯 질문으로 메우지 않고 Skill 도구로 `devoks-sdlc:feature-interview`에 진입한다(그 스킬 절차를 이 흐름 안에서 수행). 사용자가 정련 요약을 승인하면 그 요약을 초안으로 아래 절차 0부터 이어간다. 초안이 이미 승인된 정련 요약이거나 의도·방향이 분명하면 게이트를 건너뛴다. 사용자가 인터뷰를 원치 않으면 아래 절차 7의 일괄 확인으로 진행한다. 비-HITL 경로에서는 게이트를 열지 않고 의도 공백을 blocked로 보고한다.

> **판단 칸만 비었으면 인터뷰하지 않는다** — Outcome·User가 분명하고 Success·Non-goals만 비어 있는 경우(작은 기능 추가·수정에서 흔하다)는 의도 공백이 아니다. 요청에서 추론한 값을 `제안: …`으로 채워 절차 7의 일괄 확인에 함께 올린다(예: Success "토글 1회로 표시/숨김 전환", Non-goals "다른 입력 필드에는 적용하지 않음"). 사용자 입력은 대개 불완전하므로, 인터뷰는 무엇을 왜 만드는지 모를 때만 연다. 확인된 제안은 확정값, 보류되면 §10.

0. **워크스페이스 확정 · 초안 원문 보존** — `out` 경로 `.claude/workspace/{feature-name}-{date}/`(date=`yyyyMMdd`)를 정한다. 시안·시각 리소스 사본은 **`<out>/assets/`** 에 `RES-ASSET-NNN_<slug>` 네이밍으로 저장하고(시안 외 대용량·저장소 안 리소스는 경로만 기록), FRD §6.3 Assets 표 ID와 일치시킨다. **본문으로 받은 초안은 `<out>/FRD.draft.md` 로 원문 그대로 보존**한다: 짧은 출처 헤더 + 초안 원문 verbatim + 정련 중 사용자 확인으로 확정된 결정 누적(추측 금지). 정련 결과는 `FRD.md`. → 디렉토리·`assets/`·보존 형식 근거는 `../feature-workflow-runner/references/output-location.md`(SSOT).
   - 초안이 `## 기능 정련 요약` 형식(`feature-interview`의 **승인된 정련 요약**, 사용자가 채운 `FRD.intake.md`, FEATURES.md의 FRD 시드)이면 확정된 값은 다시 묻지 않고 §1(Outcome·User·Why now·Success·Out of scope → 대상 사용자·Success·Non-goals), §2·§3(방향·논의 중 결정), §7(Constraint), §6(관련 문서), §10(가정·남은 질문)의 근거로 쓴다. 단 값이 `미확정`이거나 `제안: …`이면 확정값이 아니다 — 특히 FEATURES 시드는 prd/trd-author가 쓴 것이라 비-HITL로 만들어졌을 수 있다. 이런 값은 절차 7 일괄 확인에 올리고(비-HITL이면 §10에 남긴다) 확정값처럼 §1에 옮기지 않는다. 요약도 다른 초안과 똑같이 `FRD.draft.md`로 보존한다(요약 첫 줄의 "원래 요청"이 인터뷰 전 원문이다). 요약의 "남은 질문"은 사용자가 보류한 것이라 절차 7 슬롯 확인에 한 번 더 넣어도 되고, 다시 보류되면 §10으로 넘긴다.
   - `FRD.draft.md`가 이미 있으면 덮어쓰지 않고 먼저 읽는다.
1. **골격 로드** — `../feature-workflow-runner/assets/FRD.template.md` 를 읽어 형식을 따른다.
2. **요구 추출** — 초안에서 Goal(대상 사용자·Why now·Success·Non-goals 포함)·Context·요구사항 후보를 뽑는다.
3. **EARS 정형화** — 각 요구를 `REQ-xxx` + `AC-xxx-y`(정상 WHEN/WHILE + 예외 IF 최소 1쌍)로. → `../feature-workflow-runner/references/ears-acceptance-criteria.md`
4. **분리 기재** — 수치/세팅/상태전이 → §5 Contract(`CTR-xxx`), 예외 상황 → §8 Edge(`EDGE-xxx`). 요구가 **기존 데이터의 특정 필드/형태**(비교 키, 마이그레이션 폴백, 다른 기능이 이미 채워놓은 값 등)에 의존하면, 그 필드가 실환경에 실제로 그 형태로 존재하는지 확인하는 항목을 `EDGE-xxx`로 반드시 추가한다 — 유닛테스트는 mock 데이터로 통과해도 실데이터 형태가 다르면 기능이 아예 발동하지 않을 수 있다. 같은 방식으로, 요구가 **사용자가 의도적으로 반복 트리거하는 조작**(증감 스테퍼, 연속 제출, 검색어 입력, 스크롤 페이징 등)을 포함하고 그 조작이 **상태를 확정하거나 I/O를 유발**하면(`.claude/refs/interaction-integrity.md` §1 적용 대상 판정), 연타 시의 기대 동작을 `EDGE-xxx`로 반드시 추가한다 — 조작의 의미(누적 → 입력 횟수만큼 반영 / 최종값 → 마지막 값만 / 단발 → 1회만 확정)와 I/O 코얼레싱 기대치를 함께 적는다. 단발 조작만 명세하면 저사양 기기에서만 드러나는 유실·중복을 스펙 단계에서 놓친다. 표시만 바꾸는 조작은 대상이 아니다.
5. **착수 리소스** — §6(참고 코드·외부 문서·시안·API), §7 Constraints(위험/의존 제약·기술 제약)를 채운다. 제품 TRD(`product-trd-author` 산출물, 기본 `docs/product/TRD.md`)가 있으면 스택·인터페이스 규약·NFR 보장 설계는 재정의하지 않고 TRD 섹션·`NFR-n`을 참조한다. PR 분리 여부·개수는 이 단계에서 정하지 않는다(PLAN 단계 — `../feature-workflow-runner/references/task-pr-splitting.md`).
6. **§4 설계 스펙** — TRD가 있으면 그 시스템 구성·공유 도메인 모델·규약 안에서 설계하고, 벗어나야 하면 이유를 §4에 명시하고 완료 보고에 "TRD 갱신 검토"를 남긴다. 복잡도 임계 초과 시(신호 목록·기준: `../feature-workflow-runner/references/design-spec.md`) 코드 패턴을 먼저 탐색하고 **설계안을 제안·확인**한 뒤 컴포넌트 구조·패턴(`DSN`)·모듈 배치를 채운다. 단순 기능은 §4.1만 간결히.
7. **확인 후 작성** — 누락 슬롯은 한 번에 모아 사용자에게 확인(추측 금지 — 요구는 묻고, 설계는 제안 후 확인) → `<out>/FRD.md` 작성. 검증되지 않은 가정과 답이 보류된 질문은 §10에 남긴다.
   - **질문 단위 규칙** — 여기서 한 번에 모아 묻는 것은 **슬롯·정책**(필드 구성, 상태값, 편집 범위, 이관, 인증 방식 등)이다. 의도 수준 공백(Outcome·User·방향)은 여기 섞지 않는다 — Phase 0 게이트(`feature-interview`, 한 번에 하나씩)가 맡는다. Success·Non-goals 제안값 확인은 여기 함께 넣는다.

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
- 저장소에 제품 PRD(`product-prd-author` 산출물, 기본 `docs/product/PRD.md`)가 있는데 이 기능이 그 `FEATURES.md`에 없는 **새 능력**이면, 완료 보고에 "`product-prd-author` 갱신 모드로 FEATURES 등재 필요"를 안내한다(직접 고치지 않는다) — 유지보수로 추가된 기능이 제품 백로그에서 빠지면 PRD가 실제 제품과 어긋난다.

> 막히면 `../feature-workflow-runner/references/example-walkthrough.md` 의 완성 예시를 참고한다.
