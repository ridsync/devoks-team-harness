---
description: FRD(기능 요구서) 초안을 받아 정련된 FRD를 완성하고, 이를 추적 가능한 PLAN(작업 분해)으로 만든 뒤, 각 태스크를 의존성 순서대로 단계 실행하는 통합 워크플로. EARS Acceptance Criteria, REQ/AC/CTR/EDGE↔TASK 추적성, `[P]` 병렬 마커, PR 단위 분리, PLAN 체크박스 기반 진행 추적을 한 흐름으로 묶는다. "FRD 초안 줄게 PLAN 짜고 진행해줘", "기능 요구서를 작업으로 분해", "스펙→태스크 분해 후 단계 실행", "PLAN 만들고 태스크 추적하며 구현", "FRD/PLAN 워크플로" 같은 요청에서 사용한다. 단계별로 따로 돌리고 싶으면 devoks-sdlc:feature-frd-author / devoks-sdlc:feature-plan-author / devoks-sdlc:feature-plan-executor 를 쓴다.
metadata:
  author: ridsync
  version: 1.5.0
---

# feature-workflow-runner

FRD 초안 → **정련 FRD → PLAN(작업 분해) → 태스크 단계 실행 → 마무리** 를 끊김 없이 잇는 4 Phase 통합 워크플로.
요구사항이 빠짐없이 작업으로 변환되고(추적성), 작업이 합리적 PR 단위로 쪼개지며(분리), 진행 상태가
세션을 넘어 유지되도록(PLAN.md SSOT) 한다.

## 왜 이 워크플로우인가

거친 아이디어에서 바로 코딩에 들어가면 (1) 빠진 요구사항이 구현 끝에 드러나고, (2) 거대한 단일 PR이
되어 리뷰·롤백이 어렵고, (3) 어디까지 했는지 추적이 안 된다. 이 스킬은 **EARS로 요구를 검증 가능하게
고정 → 각 작업에 `traces`를 달아 커버리지를 보장 → PR 경계로 분해 → PLAN 체크박스로 진행을 영속**시켜
이 세 실패를 막는다. FRD/PLAN은 사람이 읽는 산출물이자 에이전트가 재개 가능한 상태 저장소다.

## 호출 방법

```
/devoks-sdlc:feature-workflow-runner [frd=<FRD 초안 경로 또는 본문>] [out=<산출물 디렉터리>]
```

- `frd` 없으면 현재 대화에서 초안을 받는다.
- `out` 없으면 기본 워크스페이스 **`.claude/workspace/{feature-name}-{date}/`**. → `references/output-location.md`
- 워크스페이스에는 `FRD.md`·`PLAN.md`와 입력 초안·리소스 사본을 모은다. **생성/수정 코드는 워크스페이스가 아니라 프로젝트 본래 위치**에 둔다.

## 핵심 원칙

- **추적성 우선** — 모든 `AC/CTR/EDGE`는 최소 한 Task의 `traces`에 등장한다(누락 0). 근거 없는 Task도 두지 않는다.
- **검증 가능한 요구** — AC는 EARS로 써서 그대로 테스트가 된다. 통과/실패를 판정 못 하는 문장은 요구가 아니다.
- **설계는 제안 후 확인** — 요구 누락은 묻고(추측 금지), 설계 공백은 합리적 안을 먼저 제안한 뒤 확인한다. 복잡도 임계(파일 3개 초과·신규 모듈/계층·아키텍처 변경·새 패턴) 초과 시 FRD §4에 컴포넌트 구조·패턴(`DSN`)·모듈 배치를 채운다. → `references/design-spec.md`
- **증분 분해·PR 분리** — 머지해도 안 깨지는 크기로 쪼개고, 필요할 때만(기본은 PR 1개) 독립 가치/위험 단위로 PR을 나눈다.
- **PLAN이 진행 SSOT** — 완료는 검증 통과 후에만 `[x]`. 세션 도구는 미러일 뿐 PLAN을 이긴다.
- **실행은 태스크까지** — 구현 착수 전 브랜치·이슈 사전체크(제안→확인→적용) 후, 태스크 구현·검증은 `size` 라우팅(S 직접/M 위임/L 분해 재검토)에 따라 `code-implementer` 위임(기본 경로)·직접 실행으로 처리하고, 리포트 판정·인계 노트 윈도잉·진행 갱신은 메인 루프가 수행. → `references/branch-issue-precheck.md`, `references/task-delegation.md`. 태스크 실행 중엔 자동 커밋/PR·타 커맨드 오케스트레이션을 하지 않는다. **단 Phase 4 마무리에서 사용자가 AskUserQuestion으로 명시 선택한 항목**(검증·리뷰·테스트·커밋·PR)은 메뉴 순서대로 위임 실행한다(HITL 선택 실행 — `references/post-implementation-checklist.md`).
- **읽기 전 변경 금지 + 재사용 우선** — 손대기 전 관련 코드를 읽고, 기존 유틸/훅/패턴을 먼저 찾아 재사용한다.

## 자산 · 레퍼런스

| 파일 | 언제 읽나 |
|------|-----------|
| `assets/FRD.template.md` | Phase 1 — 정련 FRD 골격 |
| `assets/PLAN.template.md` | Phase 2 — PLAN 골격 |
| `references/ears-acceptance-criteria.md` | Phase 1 — AC를 EARS로 쓸 때 |
| `references/design-spec.md` | Phase 1 — §4 설계 스펙(컴포넌트/패턴/배치)·`DSN`·능동 제안 절차 |
| `references/traceability.md` | Phase 2·4 — `traces` 커버리지 검증(누락 0) |
| `references/task-pr-splitting.md` | Phase 2 — Task 분해·`[P]`·`size`/`test` 부여 기준·PR 분리·의존성 그래프 |
| `references/progress-tracking.md` | Phase 1·2·3 — FRD/PLAN 승인 전환, PLAN 체크박스/status 갱신, 재개 절차 |
| `references/branch-issue-precheck.md` | Phase 3 — 구현 착수 전 브랜치·이슈 사전체크(제안→확인→적용) |
| `references/task-delegation.md` | Phase 3 — `code-implementer` 위임 프로토콜(`size` 라우팅·공통 예외 ③·손익분기·입력 계약·done/blocked 리포트·인계 노트 윈도잉·에스컬레이션) |
| `references/output-location.md` | 시작 시 — 산출물 워크스페이스 경로 규칙(문서/코드 분리) |
| `references/post-implementation-checklist.md` | Phase 4 — 구현 완료 후 다음 단계(검증/리뷰/보안/테스트/커밋/PR) 표준 체크리스트 |
| `references/example-walkthrough.md` | 막힐 때 — 도메인 중립 FRD→PLAN 완성 예시 |

---

## Phase 1 — FRD 정련

거친 초안을 `assets/FRD.template.md` 형식으로 완성한다.

0. **워크스페이스 확정 · 초안 원문 보존** — feature-name·date(`yyyyMMdd`)로 `out` 기본 경로 `.claude/workspace/{feature-name}-{date}/` 를 정한다(디렉토리명·날짜·`assets/` 레이아웃 SSOT는 `references/output-location.md`). 시안·시각 리소스 사본은 **`<out>/assets/`** 에 `RES-ASSET-NNN_<slug>` 네이밍으로 저장하고(시안 외 대용량·저장소 안 리소스는 경로만 기록), FRD §6.3 Assets 표 ID와 일치시킨다. **본문으로 받은 거친 초안은 `<out>/FRD.draft.md` 로 원문 그대로 보존**한다: 짧은 출처 헤더(어떤 스킬·호출에서 받았는지) + 초안 원문 verbatim, 정련 중 사용자 확인으로 확정된 결정은 같은 파일 하단에 누적(추측 금지). 정련 결과는 `FRD.md`. → 형식 근거는 `references/output-location.md`(SSOT).
1. 초안에서 Goal·Context·요구사항 후보를 추출한다.
2. 각 요구사항을 `REQ-xxx` + EARS `AC-xxx-y` 로 정형화한다(정상 경로 + 예외 경로 최소 1쌍). → `references/ears-acceptance-criteria.md`
3. 수치·세팅·상태전이를 §5 Contract(`CTR-xxx`)로 빼고, Edge Case를 §8(`EDGE-xxx`)로 정리한다.
4. §6 Resources(참고 코드·외부 문서·시안·API)와 §7 Constraints(위험/의존 제약·기술 제약)를 채운다. PR 분리 여부·개수는 이 단계에서 정하지 않는다(PLAN 단계 — `references/task-pr-splitting.md`).
5. **§4 설계 스펙** — 복잡도 임계 초과 시 코드 패턴을 먼저 탐색(기존 상태관리·훅·유틸·모델)하고 **설계안을 제안·확인**한 뒤 컴포넌트 구조·패턴(`DSN`)·모듈 배치를 채운다. 단순 기능은 §4.1만 간결히. → `references/design-spec.md`
6. **누락 슬롯은 한 번에 모아 사용자에게 확인**한다(추측 금지 — 요구는 묻고, 설계는 제안 후 확인). 확정되면 `<out>/FRD.md` 작성.

완료 기준: 모든 REQ가 검증 가능한 AC를 갖고, 측정값은 CTR로, 예외는 EDGE로 분리됨. 복잡도 임계 초과 기능은 §4 설계 스펙(컴포넌트/패턴/배치)이 채워지고 확인됨. ID 체계(`REQ`/`AC`/`CTR`/`EDGE`/`DSN`)가 일관되어 다음 단계(PLAN)의 `traces`로 바로 인용 가능. `FRD.md` 작성 시 frontmatter `status: draft → review`. → `references/progress-tracking.md`

## Phase 2 — PLAN 작성

`<out>/FRD.md` 를 `assets/PLAN.template.md` 형식의 작업 분해로 변환한다.

0. **FRD 승인 처리** — `FRD.md` 로드 시 frontmatter `status`가 `review`이면 `approved`로 갱신(FRD 최종 상태). → `references/progress-tracking.md`
1. Approach·PR 분리 방침을 1~2문장으로 적는다(§1). Resource Check(§2)는 FRD §6에서 가져온다.
2. 요구사항을 Task로 쪼갠다: 단일·검증가능·증분. 각 Task에 `TASK-ID`, (가능하면) `[P]`, `size`(S/M/L — 실행 라우팅 신호, 애매하면 M, `L`은 분해 재검토), `test`(required/skip — 테스트 필요 여부, 애매하면 required), `file:`, `traces:` 부여. → `references/task-pr-splitting.md`
3. Task를 **PR 그룹**으로 묶는다 — 기본값 PR 1개. FRD의 메모는 참고일 뿐, `task-pr-splitting.md` 기준으로 이 단계에서 직접 재판단한다. 기본값이 명확하면 묻지 말고 진행하고, **애매할 때만 AskUserQuestion 단일선택**(`[PR 1개 (권장)]` / `[독립 가치·위험 단위로 분리]`; HITL 전용 — 비-HITL 경로에선 기본값 PR 1개). 분리 시 §1에 근거 1줄. → `references/task-pr-splitting.md`
4. §4 의존성 그래프(mermaid, **사이클 금지**)와 §5 DoD를 작성한다.
5. **커버리지 검증**: FRD의 모든 `AC/CTR/EDGE`가 어떤 Task `traces`에 등장하는지 점검(누락 0). → `references/traceability.md` 의 comm 스크립트.
6. 확정되면 `<out>/PLAN.md` 작성. 누락이 있으면 담당 Task를 추가한 뒤에만 다음 단계로.

완료 기준: 모든 Task가 `file:`·`traces:`를 가지고 ID 규칙(`TASK-\d+`)을 지킴, `[P]`가 의존성 그래프와 모순 없음(병렬 Task는 서로를 가리키지 않음), 1개 이상 PR(기본 1개, 2개 이상이면 §1에 분리 근거 명시·PR 간 의존 단방향), 커버리지 점검 출력 공백(누락 0) + DoD 섹션 존재. `PLAN.md` 작성 시 frontmatter `status: draft → approved`. → `references/progress-tracking.md`

## Phase 3 — 태스크 단계 실행

`<out>/PLAN.md` 를 SSOT로 의존성 순서대로 실행한다. → `references/progress-tracking.md`

1. PLAN을 읽어 미완 Task와 의존성 그래프를 파악, 세션 Task/Todo 목록을 PLAN에 맞춰 구성한다. PLAN `status`가 아직 `draft`이면 `approved`로 보정. → `references/progress-tracking.md`
2. **선행이 모두 `[x]`인 Task**를 골라 착수(세션 도구 in_progress). `[P]` Task는 함께 진행 가능.
3. **브랜치·이슈 사전체크(최초 1회)** — 첫 구현 착수 직전, 현재 브랜치·연결 이슈를 확인하고 브랜치명·이슈 초안을 제안한 뒤 사용자 확인 후 적용한다(모드 `full`; 선택지는 AskUserQuestion 단일선택 — `branch-issue-precheck.md` §4). → `references/branch-issue-precheck.md`
4. 각 Task: **`size` 마커로 라우팅 후 구현·검증** — `S`는 메인 루프 직접, `M`(및 마커 없음)은 `code-implementer` 위임(기본 경로), `L`은 분해 재검토(못 쪼개면 직접), 공통 예외(③ 스펙 미완결·① tools 밖 도구·② 사용자 직접 요청)는 직접. 위임 전 공통 예외 ③을 점검한다. 위임 시 Task 블록 원문·`plan`·`frd` 경로·`context`(인계 노트 윈도잉 적용)를 주입하면, 에이전트가 코드 읽기→기존 패턴 재사용 구현→테스트/린트 검증(`test: required` Task는 AC ID를 테스트 설명에 박아 양방향 추적, `test: skip`은 테스트 작성 생략)까지 수행하고 done|blocked 리포트를 리턴한다. 한 번에 한 태스크만. → `references/task-delegation.md`
5. **리포트 판정 후 진행 갱신(메인 루프 수행)** — `done`은 검증 근거(실행 명령·**종료코드**·출력 **tail 1줄 원문**·`test: required` Task 시 테스트 파일·케이스명) 확인 후에만 PLAN 체크박스 `- [ ]` → `- [x]`, frontmatter `status`를 `approved` → `in-progress`로(첫 착수 시), **인계 노트는 윈도잉 규칙에 맞게 수집해 다음 위임의 `context`에 주입**한다. `blocked`이면 `[x]`로 바꾸지 않고 에스컬레이션(스펙 문제→사용자 확인 후 재위임, 기계적 문제→직접 해소 후 재위임, 스코프 초과→인수·재분해), 막힌 이유를 명시한다.
6. PR 경계는 **기록만** 한다(어떤 Task가 어느 PR인지). 커밋·푸시·PR 생성은 하지 않는다.

## Phase 4 — 마무리 / 검증

1. PLAN §5 DoD 각 항목 점검 후 `[x]`:
   - 커버리지 재점검(누락 0) — `references/traceability.md` comm 스크립트 재실행.
   - 핵심 로직 테스트 통과를 실제 실행 출력으로 확인.
   - Edge case 처리 확인.
2. 모든 Task `[x]` + DoD 충족 시 frontmatter `status: done`.
3. 미완 Task·임시 코드·추후 작업(예: 커밋/PR, 추가 테스트)을 명시적으로 보고한다(은폐 금지).
4. **다음 단계 (AskUserQuestion 다중선택 → 선택 항목 위임 실행)** — `references/post-implementation-checklist.md`의 표준 메뉴에서 해당 항목만 골라 검증/마무리 2개 질문의 `multiSelect`로 제시하고, **고른 항목을 메뉴 순서대로 위임 실행**한다(HITL 선택 실행). 읽기전용 검증/리뷰/테스트는 즉시 실행, 커밋·PR은 각 git 커맨드 자체 확인 플로를 최종 게이트로 위임한다. **앞선 검증에서 Critical/High가 나오면 커밋·PR 전에 멈추고 확인**한다. → `references/post-implementation-checklist.md`

## 재진입 / 분기

- 이미 정련된 FRD가 있으면 Phase 1을 건너뛰고 Phase 2부터.
- 이미 PLAN이 있으면 Phase 3(실행)부터 — PLAN 체크박스 상태로 재개 지점을 정한다.
- 단계만 따로 돌리려면 분리 스킬: `devoks-sdlc:feature-frd-author`(1) / `devoks-sdlc:feature-plan-author`(2) / `devoks-sdlc:feature-plan-executor`(3).

## 프로젝트 규칙 정합

산출·구현 시 해당 저장소의 규칙 파일(`.claude/rules/`, `.claude/refs/`, `CLAUDE.md` 등)이 있으면 직접 읽어 따른다.
특히 **커밋/푸시/PR은 사용자가 명시 요청(태스크 착수 요청 또는 Phase 4 마무리 선택)할 때만** 위임 실행하고, 그 외 자동 커밋·푸시는 하지 않는다.
