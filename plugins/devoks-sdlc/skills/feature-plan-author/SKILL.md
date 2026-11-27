---
name: feature-plan-author
description: 정련된 FRD.md를 받아 실행 가능한 PLAN.md(작업 분해)로 만든다. 요구사항을 단일·검증가능·증분 Task로 쪼개고, TASK-ID·`[P]` 병렬 마커·`size` 크기 마커(실행 라우팅 신호)·`test` 테스트 필요 여부 마커·`file:`·`traces:`를 부여하며, PR 단위로 그룹핑하고 의존성 그래프와 Definition of Done을 작성한다. 모든 REQ/AC/CTR/EDGE가 traces로 커버되는지(누락 0) 검증한다. "FRD를 작업으로 분해해줘", "PLAN 짜줘", "태스크/PR 나눠줘", "스펙→태스크 분해", "작업 계획 세워줘" 같은 요청에서 사용한다. 분해 후 실행은 devoks-sdlc:feature-plan-executor, 전체 흐름은 devoks-sdlc:feature-workflow-runner.
argument-hint: "[frd=<FRD.md 경로> (default: 최근 FRD)] [out=<디렉터리> (default: FRD 워크스페이스)]"
metadata:
  author: ridsync
  version: 1.11.0
---

# plan-author — PLAN 작성 (Phase 2)

FRD를 추적 가능하고 PR 단위로 분리된 작업 분해로 변환한다. `devoks-sdlc:feature-workflow-runner` 의 **Phase 2만** 단독 실행한다.
공유 자산/레퍼런스는 통합 스킬 디렉터리를 참조한다(SSOT).

## 호출 방법

```
/devoks-sdlc:feature-plan-author [frd=<FRD.md 경로> (default: 최근 FRD)] [out=<디렉터리> (default: FRD 워크스페이스)]
```

> 표기: `key=값` 필수 · `[key=값]` 선택 · `(default: X)` 미지정 시 X로 진행.

- `frd` 없으면 가장 최근 `docs/workspace/*/FRD.md` 를 후보로 제시·확인한다. → `../feature-workflow-runner/references/output-location.md`
- `out` 기본값 = FRD.md가 있는 워크스페이스(`docs/workspace/{feature-name}-{date}/`). 산출물 = `<out>/PLAN.md`. → `../feature-workflow-runner/references/output-location.md`
- PLAN은 워크스페이스에 저장하되, 각 Task의 `file:`은 항상 **프로젝트 본래 코드 위치**를 가리킨다(워크스페이스 아님).

## 절차

0. **FRD 승인 처리** — `FRD.md` 로드 시 frontmatter `status`가 `review`이면 `approved`로 갱신(FRD 최종 상태)하고 PLAN §1에 "FRD AC 사용자 미검토" 한 줄을 남긴다(frd-author가 AC 승인을 받아 이미 `approved`면 해당 없음). → `../feature-workflow-runner/references/progress-tracking.md`
1. **골격 로드** — `../feature-workflow-runner/assets/PLAN.template.md` 형식을 따른다.
2. **Approach·Resource** — §1 구현 방식·PR 분리 방침, §2 Resource Check(FRD §6에서 가져옴).
3. **Task 분해** — 단일·검증가능·증분. 각 Task에 `TASK-ID`, (가능하면)`[P]`, `size`(S/M/L — 실행 라우팅 신호, 애매하면 M), `test`(required/skip/e2e — 테스트 필요 여부, 애매하면 required. 신규 E2E는 구현 Task에 넣지 않고 「E2E Task」 기준으로 별도 `e2e` Task를 만든다), `file:`, `traces:` 부여. `L`은 분해 재검토 신호 — 원칙적으로 더 쪼개고, 못 쪼개면 §1에 사유 1줄을 **스펙 닫힘 축/판단 축 중 어느 것인지 밝혀** 남긴다(실행 라우팅이 이 기록을 읽는다). `test`는 `code-implementer`가 실행 중 스스로 재판단하지 않고 그대로 따르는 값이므로 이 단계에서 확정한다. `file:`은 대상 프로젝트의 `.claude/rules/project-convention.md` Project Decisions 구조 슬롯(S1~S3)을 읽고 세그먼트 파일 단위로 정하며, 공용 자산 신설·승격은 별도 Task로 나눈다. 그 파일이 없는데 TRD(`docs/product/TRD.md`)에 `stack preset`이 있으면(그린필드에서 convention 적용 전) 분해 전에 `/devoks-core:setup-project-convention` 실행을 먼저 권한다 — 슬롯 없이 정한 `file:`은 골격 구조를 목표와 다르게 깔 수 있다. 사용자가 그대로 진행하길 원하거나 비-HITL이면 TRD §3.1과 `agent-principles` [Structure] 기준으로 정하고 §1에 "convention 미적용" 1줄을 남긴다. → `../feature-workflow-runner/references/task-pr-splitting.md`
   - **함께 두는 Task** — ⑴ FRD에 실측 전 지연 가정(외부 호출 p95 등 — §10 또는 데드라인 CTR)이 있으면 그 값에 기대는 Task보다 앞에 **측정 Task**를 둔다(측정 결과가 CTR 값을 바꿀 수 있다). ⑵ 요청 횟수 제한·쿼터·전역 카운터처럼 **클라이언트 식별 키(IP·세션·계정)로 상태를 공유하는 기능**이면 **E2E fixture 격리 Task**(컨텍스트마다 다른 키 — 예: 테스트 전용 `x-forwarded-for`, 계정 분리, 카운터 초기화)를 함께 둔다 — 없으면 병렬 E2E가 같은 키를 나눠 써서 한도에 걸린다. ⑶ WIREFRAMES W-n이 연결된 **화면 기능이고 디자인 파일이 있으면** §5 DoD에 "디자인 파일 프레임(W-0 셸·PC·모바일 변형 포함) ↔ 라이브 렌더 대조"를 넣고, 화면 Task 설명에 대상 프레임 이름을 적는다(위임 시 `design` 입력의 출처 — `../feature-workflow-runner/references/task-delegation.md`). 대조를 이번 PR에서 미루면 §1에 사유와 담당 Task를 남긴다.
4. **PR 그룹핑** — 기본값 PR 1개. FRD의 메모는 참고일 뿐, `task-pr-splitting.md` 기준으로 이 단계에서 직접 재판단한다(애매하면 AskUserQuestion). 분리 시 §1에 근거 1줄. → `../feature-workflow-runner/references/task-pr-splitting.md`
5. **그래프·DoD** — §4 mermaid 의존성 그래프(사이클 금지), §5 Definition of Done.
6. **커버리지 검증(누락 0)** — FRD의 모든 `AC/CTR/EDGE`가 어떤 Task `traces`에 등장하는지 점검. → `../feature-workflow-runner/references/traceability.md` 의 comm 스크립트.
7. **작성** — 누락이 없을 때만 `<out>/PLAN.md` 작성. 있으면 담당 Task 추가 후 재검증.
   - **진행 중 PLAN 보호** — `<out>/PLAN.md`가 이미 있고 frontmatter `status`가 `in-progress`이거나 미체크(`- [ ]`) Task가 남아 있으면 **덮어쓰지 않는다**. 같은 기능의 재계획(사용자가 수정·확장을 요청)이면 기존 파일을 제자리에서 고치되 `[x]` 체크와 완료 Task는 보존하고, 그 외에는 멈추고 확인한다(AskUserQuestion 단일선택: `[기존 PLAN 이어서 실행]` / `[기존 PLAN을 PLAN.<날짜>.bak.md로 보존 후 새로 작성]` / `[취소]` — HITL 직접 호출 전용, 비-HITL 경로에선 덮어쓰지 않고 blocked로 보고). 미체크 Task는 다른 세션에서 실행 중일 수 있고, 그 진행 상태는 PLAN.md 밖에 없다.

## 완료 기준

- 모든 Task가 `size:`·`test:`·`file:`·`traces:`를 가짐, ID 규칙(`TASK-\d+`) 준수.
- `[P]` 가 의존성 그래프와 모순 없음(병렬 Task는 서로를 가리키지 않음).
- `size: L` Task가 남아 있으면 §1에 분해 불가 사유 명시 — **스펙 닫힘 축인지 판단 축(설계 변경·인터페이스 파급)인지 밝혔는지** 확인(실행 라우팅의 위임/직접 판정 근거).
- `size` 분포 자기점검 — 양방향으로 확인한다. ⑴ `S`가 부여 기준의 **`S` 열거를 벗어나지 않았고** `test: required`·`test: e2e` Task에 `S`가 붙지 않았는지(**`required`·`e2e` ⇒ 최소 `M`**), ⑵ 그 열거에 해당하는 후보가 있는데도 전부 `M`으로만 부여되지 않았는지 — 열거 원문은 `../feature-workflow-runner/references/task-pr-splitting.md`(부여 기준 SSOT)에서 확인하고 여기에 복제하지 않는다.
- E2E Task 자기점검 — 프로젝트가 E2E 도구를 쓰는데(`Test/E2E` 슬롯·설정 감지) §9 `테스트 코드` 흐름 AC에 `test: e2e` Task가 없으면 누락이다. 반대로 E2E 도구가 없으면 `e2e` Task를 만들지 않고 §1에 미사용 1줄이 있는지 확인한다 — 기준: `../feature-workflow-runner/references/task-pr-splitting.md` 「E2E Task」.
- `test` 분포 자기점검 — `skip`을 부여한 Task에 실제로 로직(비즈니스 로직·상태 전이·데이터 흐름·계약 검증·조건부 분기·반복·파싱·금액/보안·버그 수정)이 없는지 재확인. 애매해서 `skip`으로 몰아넣지 않았는지 확인 — 부여 기준: `../feature-workflow-runner/references/task-pr-splitting.md`.
- 1개 이상 PR 생성(기본 1개). 2개 이상이면 §1에 분리 근거(기능/위험/리뷰 부담 중 하나) 명시 + PR 간 의존 단방향 준수.
- 커버리지 점검 출력 공백(누락 0), DoD 섹션 존재.
- 담당 ID 없는 `후속`·`추후` 표기 0건 — PLAN에서 미룬 일(디자인 대조·측정·QA 등)마다 `TASK-n`·`F-n`·`B-n` 또는 "FEATURES 등재 필요"가 있다(`../feature-workflow-runner/references/traceability.md` "미룬 일의 담당 ID"). FRD §4.1 "하이파이 구성"에서 온 AC도 위 커버리지 점검에 그대로 포함된다.
- `PLAN.md` 작성 완료 시 frontmatter `status: draft → approved`. → `../feature-workflow-runner/references/progress-tracking.md`
- FRD frontmatter에 `feature:`가 있으면 그 FEATURES.md 행을 `🗂️ plan`으로 바꾼다(앞으로만 — 이미 `in-progress` 이후면 유지). 규칙: `progress-tracking.md` "제품 백로그 상태 동기화".

> 형식이 헷갈리면 `../feature-workflow-runner/references/example-walkthrough.md` 참고.
