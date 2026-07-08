# Roadmap — 추후 개선 사항 (TODO)

DevOks 하네스의 플러그인 구조·내용 개선 후보를 모아두는 단일 SSOT 문서.
양 언어 README는 이 문서를 링크만 한다(이중 관리 drift 방지).

> 최종 갱신: 2026-07-08

---

## 우선순위 한눈에

| 우선순위 | 항목 |
|---|---|
| **높음** | 컨벤션 문서 계층 분리 · 스킬 평가/검증 워크플로우 보강 · UI 작업 분리 검토 · 코드 리뷰 워크플로우 개선 · **`devoks-sdlc-orchestration` 신설(비-HITL SDLC)** |
| **중** | `devoks-release` 신설 · 구현자 세션 지속(continuation) · `browser-visual-diff` 이전 · 카탈로그 자동 생성 · evals 하니스 확대 · 심각도 분류 SSOT 통합 |
| **낮음** | 진입점 일관화 · Operate/Maintain 단계 · `code-security-review` references 보강 · plugin 버전 메타 정합 |

---

## 완료 / 최근 반영

- [x] **`code-implementer` model: `inherit` → `sonnet` 고정 재조정** (2026-07-08)
  - 근거: Anthropic 공식 Claude Code 가이드가 "plan with Opus, execute with Sonnet" 패턴을 명시 권장(`/model opusplan` 내장 지원)하며, Opus가 Sonnet 대비 Pro/Max 사용량 한도를 "meaningfully more" 소비한다고 밝힘. devoks-sdlc 구조상 FRD/PLAN 작성(plan, 메인 루프 유지)과 `code-implementer` 구현 실행(execute)이 이 패턴과 정확히 대응됨.
  - 기존(2026-07-06~07) quality-first 원칙("구현 품질=세션 추론 깊이") 자체는 유지하되, "실행 단계는 계획 단계와 다른 추론 형태를 요구한다"는 근거로 예외를 적용. 스코프 초과 시 blocked→메인 루프 인수 안전장치가 품질 리스크를 흡수.
  - 반영: `code-implementer.md` frontmatter, `docs/plugin-management.md` §12(모델 선택 기준·아키타입 매핑), `task-delegation.md`(위임 손익분기 — 세션이 opus/fable이면 위임이 시간·rate limit 절약도 제공하도록 갱신).

- [x] **devoks-sdlc 모델 티어링 + `code-implementer` 태스크 위임 도입** (2026-07-06~07, `1.1.1 → 1.2.0`)
  - `code-implementer` 에이전트 신설(최초 `model: inherit` — quality-first: 구현 품질은 세션 추론 깊이와 동일해야; 2026-07-08에 `sonnet` 고정으로 재조정, 위 항목 참고), `code-security-reviewer`는 `opus` + `effort: high`로 상향. 티어링 판단 3기준(스펙 완결성·인터랙션 필요성·격리 이득)과 역할 아키타입 매핑은 `docs/plugin-management.md` §12로 확장.
  - Phase 3 실행 구조: PLAN Task `size: S/M/L` 마커 기반 규칙 라우팅(S 직접 / M 위임 / L 분해 재검토) + done 리포트 인계 노트 누적(크로스 태스크 지식 유지). SSOT: `task-delegation.md`(실행 측)·`task-pr-splitting.md`(부여 측).

- [x] **`devoks-code`·`devoks-feature`·`devoks-test`·`devoks-verify` → `devoks-sdlc` 단일 플러그인 통합**
  - 4개 모두 MCP/permission/hook이 없는 순수 스킬/커맨드/에이전트 팩이라 분리 설치의 격리 이득이 없고, 스킬 description 간 cross-reference(test-author↔verify-requirements, feature-plan-executor↔code-security-review 등)가 분리 설치 시 끊김.
  - 컴포넌트 합산: commands 8 + skills 10 + agents 2, 이름 충돌 없음. prefix `devoks-{code,feature,test,verify}:` → `devoks-sdlc:` 일괄 변경.
  - 카탈로그/문서 동기화: marketplace.json, settings.json, README/README.ko, mcp-setup-guide, plugin-management, setup.sh. 부수로 README 스킬표의 `frd-author`→`feature-frd-author` drift 정정.
  - `devoks-core`·`devoks-git`·`devoks-browser`·`devoks-rn`은 분리 유지(core 의존 또는 MCP/permission 비용 실재).

- [x] **`devoks-rn` 신설 (React Native 디버깅)**
  - `metro-devtools-attach` 스킬: 에뮬레이터 스크린샷, Metro CDP JS 콘솔/상태 조회.
  - `metro-devtools` MCP는 WebSocket URL 동적 변경으로 `~/.claude.json` 수동 등록 필요.
  - 마켓플레이스 식별자 `devoks` → `devoks-plugins` 로 변경.

---

## 마이그레이션 / 구조

- [ ] **컨벤션 문서 계층 분리 (`project-convention` 재정의)**
  - 현재 `project-convention.md`에 이전 프로젝트/도메인 전용 규칙(React + JavaScript/JSDoc, TypeScript 미사용, Ant Design 등)이 고정 예시로 섞여 있어, 다른 스택 프로젝트에 그대로 동기화(`sync-context.sh`)되면 범용 규칙 문서로서의 신뢰도가 떨어짐.
  - 분리 원칙: 프로젝트 범용 컨벤션(문서 구조, 규칙 계층, 공통 운영 원칙)과 프로젝트 전용 컨벤션(언어, 타입스크립트 여부, 팀 코딩 스타일)은 명시적으로 구분.
  - 금지 방향: 특정 프로젝트/도메인 전용 구현 규칙을 범용 컨벤션에 고정하지 않기.
  - 산출물 후보: 공통 컨벤션 문서 + 프로젝트/도메인 오버레이 문서 구조.
  - **실행 방향 후보(스킬화)**: 정적 오버레이 문서 구조 대신/더불어, 대상 프로젝트의 성격(언어·프레임워크·타입스크립트 여부·스타일 가이드 등)을 코드베이스 시그널로 감지하거나 사용자에게 질의해 `project-convention.md`를 해당 프로젝트에 맞게 생성·갱신하는 셋업 스킬을 제공한다. 범용 규칙 문서(`agent-principles.md`, `memory-policy.md`)는 건드리지 않고 프로젝트 전용 컨벤션 파일만 대상으로 하며, 신규 설치 온보딩과 기존 설치 스택 변경 재설정 양쪽에서 재사용 가능해야 한다.
  - 우선순위: 높음(규칙 drift 및 재사용성 저하 방지).

- [ ] **구현자 세션 지속 — 에이전트 continuation 기반 PR그룹 단위 위임**
  - 현재 태스크 단위 cold-start 위임은 인계 노트(요약 채널)로 지식 단절을 완화 중. subagent continuation(재호출 시 컨텍스트 유지)이 팀 배포 환경에서 공식 지원됨이 검증되면, **PR그룹(모듈) 단위로 `code-implementer` 1개를 유지하며 태스크를 순차 투입**하는 방식으로 전환 — 같은 모듈 재독 1회로 축소, 네이밍·패턴 일관성 확보. 인계 노트의 상위 호환.
  - 선행 조건: Claude Code subagent continuation 공식 문서 확인 + 팀 최소 버전 정책 합의.
  - 관련 SSOT: `plugins/devoks-sdlc/skills/feature-workflow-runner/references/task-delegation.md`.
  - 우선순위: 중(검증 선행).

- [ ] **`browser-visual-diff` → `devoks-sdlc:verify-visual-diff` 이전**
  - 시각 diff는 본질적으로 "검증"이므로 devoks-sdlc의 verify 계열로 모으는 것이 도메인상 자연스럽다.
  - 동반 이동 필요: `browser-visual-diff-capture` 에이전트, `references/` 일체.
  - 결합 비용(이번에 보류한 이유): Chrome DevTools MCP 선언이 `devoks-browser/plugin.json`에 있고 Figma MCP·`browser-devtools` 형제 스킬과 묶여 있음 → 이전 시 MCP 의존 선언 이전 또는 cross-plugin 의존 정리가 선행되어야 함.
  - 영향 범위: README/README.ko 카탈로그, `docs/mcp-setup-guide.md`, `devoks-core/hooks/check-mcp.sh`(chrome-devtools 감지가 "devoks-browser" 문자열도 grep함 — 이전 시 감지 로직 점검).
  - 우선순위: 중.

- [ ] **진입점 일관화 검토 (command vs skill)**
  - 팀이 스킬 우선으로 이동 중(`new-feature-verify` 커맨드→스킬 전환). 그러나 `new-feature-draft`/`new-feature-github-issue`/`new-ui-draft`/`code-*` 등은 여전히 커맨드.
  - 트리거 기반(자연어) 호출로 통일할지, command는 진입 전용으로 남길지 정책을 한 번 확정.
  - 우선순위: 낮음(정책 결정 먼저).

---

## SDLC 커버리지 확장

- [ ] **`devoks-release` 신설 (Deploy/Release 단계 — 현재 0% 커버)**
  - Conventional Commits → CHANGELOG 생성 + semver bump + tag (devoks-git의 자연스러운 확장).
  - 릴리스 준비도 게이트: lint + type + test + review + verify 결과를 집계해 머지/릴리스 가능 여부 리포트.
  - CI 워크플로(예: GitHub Actions) 작성·유지 스킬.
  - 우선순위: 중(딜리버리 빈칸 — `devoks-sdlc-orchestration` Deliver 단계와 경계 협의 후 순서 조정 가능).

- [ ] **UI 작업 분리 검토 (기능 구현 전/후 집중 처리)**
  - 현재 기능 구현 흐름 안에서 UI까지 함께 처리하면 화면 충실도가 낮아지는 경향이 있음.
  - 검토 방향: 기능 구현 전 UI 요구사항/상태/빈 화면을 별도 정리하고, 기능 구현 후 시각 품질·반응형·접근성·visual diff를 별도 패스로 검증.
      - 피그마 리소스의 체계화 사전 작업이 필수, 태스크 요청시 피그마 UI시안의 링크정보의 정확도,구조등 UI작업시 필요한 리소스 정련 중요
  - 결정 필요: `new-ui-draft`를 선행/후행 UI 패스로 분리할지, `feature-workflow-runner` Phase 안에 UI 체크포인트를 명시할지.
  - 우선순위: 높음(UI 품질 안정화).

- [ ] **Operate/Monitor · Maintain 단계 (장기)**
  - 의존성 업그레이드 제안, 보안 패치/CVE 추적, 회귀 감지 등.
  - 환경 종속이 커서 대부분 thin-wrapper 또는 외부 도구 연동으로 설계 필요.
  - 우선순위: 낮음(장기).

- [ ] **`devoks-sdlc-orchestration` 신설 — 비-HITL(전체 위임) SDLC 오케스트레이션 플러그인**
  - **배경**: 현재 `devoks-sdlc`(`feature-workflow-runner` 중심)는 HITL(Human-in-the-Loop) 전제다. FRD 누락 슬롯·설계 스펙·브랜치/이슈 사전체크마다 사용자 확인이 필요하고, Phase 경계 중간 리포트·단계적 구현/리팩토링을 사람이 리뷰하며 진행한다. 커밋/PR도 사용자 명시 요청 시에만(`feature-workflow-runner` 범위 밖).
  - **목표**: 이슈 수신 → 작업 분해·실행 → 리뷰/평가/테스트 → PR·최종 리포트까지 **중간 승인 없이** 오케스트레이션하는 대규모 자동화 프레임워크. `devoks-sdlc`와 **공존**하되, 진입 조건·권한·에스컬레이션 정책을 분리한다.
  - **우선순위**: 높음(아키텍처·외부 연동 범위가 커서 **단계적 도입** — MVP부터 착수).

  #### 현재(HITL) vs 목표(비-HITL) 대비

  | 축 | `devoks-sdlc` (HITL) | `devoks-sdlc-orchestration` (목표) |
  |---|---|---|
  | **진입** | FRD 초안·대화 | 이슈/티켓/웹훅/스케줄 트리거 |
  | **스펙 확정** | 누락·설계 매 단계 사용자 확인 | 합리적 기본값·정책 SSOT로 자동 확정(불확실 시 에스컬레이션만) |
  | **실행** | 태스크 단위 위임 + 메인 루프 판정 | 파이프라인 전 구간 에이전트 체인·병렬 실행 |
  | **중간 산출** | FRD/PLAN/태스크 리포트(사람 검토용) | 머신 가독 상태 파일 + 이벤트 로그(사람은 예외 시만) |
  | **검증** | DoD 수동 점검·사용자 재개 | 테스트·리뷰·보안·요구사항 검증 자동 게이트 |
  | **딜리버리** | 커밋/PR 사용자 요청 시 | 브랜치·커밋·PR·CI 트리거까지 파이프라인 포함 |
  | **실패 처리** | `blocked` → 사용자 확인 | 재시도·롤백·이슈 코멘트·담당자 알림 |

  #### 파이프라인 개요 (목표 아키텍처)

  ```
  [트리거] → [Intake/정규화] → [Plan/분해] → [Implement] → [Verify] → [Review] → [Deliver] → [Report]
       ↑            │                │              │            │           │            │
   Linear/GitHub   이슈→RUN         PLAN SSOT    code-implementer  test/req/   code-review/  PR+CI    Slack/이슈
   Slack/webhook   스펙 자동보완    병렬 라우팅   (continuation)    data-flow   security      merge?   최종 요약
  ```

  - **트리거(Intake)**: 외부 이슈·라벨·assignee·우선순위를 RUN(실행 단위)으로 매핑. 입력이 빈약하면 템플릿·과거 유사 이슈·코드베이스 스캔으로 스펙 보완(추측 상한·에스컬레이션 규칙 필수).
  - **Plan**: `devoks-sdlc`의 FRD/PLAN·`traces`·PR 분리 규칙을 **재사용**하되, 승인 게이트 제거·`status` 전환 자동화. RUN 메타(`run-id`, `issue-ref`, `policy-version`)를 frontmatter에 고정.
  - **Implement**: `code-implementer` + continuation(도입 후) + `size` 라우팅. 브랜치 생성·이슈 링크는 사전체크 확인 없이 **정책 기본값** 적용(`devoks-git` 연동).
  - **Verify**: `test-run-triage`, `verify-requirements`, `verify-data-flow`, (선택) visual diff — 실패 시 자동 수정 루프 상한 N회 후 에스컬레이션.
  - **Review**: `code-review`, `code-security-review` — 심각도 임계 초과 시 PR draft 유지·머지 차단.
  - **Deliver**: Conventional Commits 커밋, PR 본문(추적성·테스트·리스크), CI 워크플로 트리거. `devoks-release`와 경계 협의(릴리스 vs 기능 PR).
  - **Report**: RUN 종료 리포트(성공/부분/실패), 이슈·Slack에 요약·아티팩트 링크. 중간 Phase 리포트는 생략·이벤트 스트림으로 대체.

  #### `devoks-sdlc`와의 관계

  - **공유**: 에이전트(`code-implementer`, `code-reviewer`, `code-security-reviewer`), 스킬 자산(PLAN/FRD 템플릿, `task-delegation`, `traceability`, 검증·리뷰 스킬), 심각도 SSOT.
  - **분리**: 오케스트레이터 스킬/커맨드(`orchestration-workflow-runner` 등), RUN 상태 스키마, 트리거·웹훅·권한(쓰기·PR·머지), 에스컬레이션·재시도 정책, 외부 MCP/CLI 어댑터.
  - **의존성 후보**: `devoks-core`, `devoks-git`, `devoks-sdlc`(스킬 참조 또는 soft dependency), (선택) `devoks-browser`(visual diff).

  #### 단계적 도입 (제안)

  | 단계 | 범위 | 산출 |
  |---|---|---|
  | **0 — 정책** | 자동화 허용 범위·금지 경로(시크릿·인프라·DB 마이그레이션)·에스컬레이션 연락처 | `orchestration-policy.md` SSOT |
  | **1 — MVP** | 수동 트리거 1건: 이슈 URL → 브랜치·구현·테스트·draft PR·요약 리포트 | `devoks-sdlc-orchestration` 플러그인 골격 |
  | **2 — 검증 강화** | 리뷰/보안/요구사항 게이트·재시도·`blocked` 자동 분류 | 게이트 실패 시 이슈 코멘트 |
  | **3 — 트리거** | Linear/GitHub 이슈 라벨·웹훅·(선택) Slack 명령 | 이벤트 기반 RUN 큐 |
  | **4 — 운영** | RUN 큐·동시성·비용 상한·감사 로그·evals | 팀 운영 가이드 |

  #### 외부 솔루션 연동 키워드 (조사·선정 TODO)

  플러그인 **밖**에서 제공될 수 있는 영역 — 구현 시 어댑터(thin-wrapper 스킬/MCP/CLI)로 연결.

  | 영역 | 키워드 / 후보 |
  |---|---|
  | **이슈·프로젝트 관리** | Linear, GitHub Issues, Jira, Asana, Shortcut |
  | **알림·HITL 에스컬레이션** | Slack, Microsoft Teams, Discord, PagerDuty |
  | **코드·PR** | GitHub Actions, GitLab CI, CircleCI, `gh` CLI, Graphite, Mergify |
  | **리뷰 에이전트** | Cursor Bugbot, CodeRabbit, Greptile, SonarQube, Semgrep |
  | **테스트** | Jest, Vitest, Playwright, Cypress, pytest, `test-run-triage` 연동 |
  | **스펙·문서** | Notion, Confluence, Figma(시안 링크), OpenAPI/Swagger |
  | **관측·품질** | Datadog, Sentry, codecov, bundle-size CI |
  | **오케스트레이션** | Temporal, Inngest, GitHub Actions workflow_dispatch, queue worker |
  | **정책·시크릿** | OPA, vault, repository rulesets, branch protection |

  #### 리스크·전제

  - **권한**: 자동 커밋/PR은 repo write·토큰 범위 최소화, draft PR 기본, main 직접 푸시 금지.
  - **품질**: HITL 제거만큼 게이트·evals·샌드박스 실행이 필수 — `evals` 하니스·스킬 품질 검증(본 문서 §품질) 선행 권장.
  - **비용·동시성**: RUN당 토큰·서브에이전트 상한, 큐 백프레셔 정책.
  - **법·컴플라이언스**: 고객 데이터·라이선스가 걸린 변경은 자동화 제외 목록에 명시.

  #### 네이밍 결정

  - **채택**: `devoks-sdlc-orchestration` — `devoks-agentic-sdlc` 대비 **역할(파이프라인 오케스트레이션)** 이 명확하고, `devoks-sdlc`와 형제 네이밍·prefix(`devoks-sdlc-orchestration:`)가 자연스럽다. `agentic`은 하네스 전반이 에이전트 기반이라 구분력이 약함.
  - **별도 플러그인** 유지(격리·권한 분리 유리) — `devoks-sdlc`에 모드 플래그로 합치지 않음.

  #### 오픈 결정
  - 머지 자동화 여부(draft PR만 vs CI green 시 auto-merge).
  - Linear vs GitHub Issues를 1차 트리거 SSOT로 할지.

---

## 품질 / 유지보수

- [ ] **스킬 평가/검증 워크플로우 보강**
  - `devoks-team-harness` management 흐름에 신규/기존 스킬의 효용성·정합성·설치 가능성·레퍼런스 충실도를 검증하는 체크를 추가.
  - 구현 후보: 기존 유지보수 스킬에 평가 절차를 붙이거나, `verify-skill-quality` 같은 독립 검증 스킬을 신설.
  - 필수 검증 축: 스킬 description과 실제 동작 일치, 필요한 `references/` 존재, 예시/evals 보유 여부, 의존 MCP/도구 명시, 플러그인 설치 후 경로 참조 안전성.
  - 레퍼런스 후보: `docs/plugin-management.md` 검증 섹션, Claude Code plugin validation 문서, 기존 `evals/evals.json` 패턴.
  - 우선순위: 높음(스킬 품질과 배포 안정성 직결).

- [ ] **코드 리뷰 워크플로우 개선**
  - `code-review`/`code-reviewer`가 리뷰 시 필수 체크 항목을 빠뜨리지 않도록 체크리스트와 결과 포맷을 보강.
  - 필수 체크 항목:
    1. 잠재적 버그는 없는가?
    2. 예외 처리가 빠진 곳은 없는가?
    3. 성능상 문제는 없는가?
    4. 보안상 위험은 없는가?
    5. 더 읽기 좋은 코드가 있는가?
  - 결과에는 발견 근거(파일/라인), 심각도, 재현/검증 방법, 후속 테스트 필요 여부를 함께 남기도록 정리.
  - 우선순위: 높음(리뷰 품질 균질화 — `devoks-sdlc-orchestration` Review 게이트의 선행 기반).

- [ ] **카탈로그 자동 생성 (drift 방지)**
  - 현재 `README.md`와 `docs/README.ko.md`의 플러그인·스킬·커맨드 표를 **수기로 이중 관리** → 실제 drift 발생(devoks-test가 한동안 README에 누락됨).
  - `marketplace.json` + 각 plugin.json/SKILL.md frontmatter에서 카탈로그 표를 생성하는 스크립트를 두고, README는 생성 결과를 포함하도록 전환.
  - 우선순위: 중(반복 비용·정확성 직결).

- [ ] **evals 하니스 확대**
  - 현재 `feature-workflow-runner`만 `evals/evals.json` 보유. `test-author`·`test-run-triage`·`code-security-review`·`verify-requirements`·`verify-data-flow`에도 추가.
  - eval 러너 스크립트가 없음(데이터만 존재) → 공용 러너 도입 검토.
  - 우선순위: 중.

- [ ] **심각도 분류 SSOT 통합**
  - `code-review`·`code-security-review`·`verify-requirements`·`test-run-triage`가 각자 🔴🟠🟡🔵 표/기준을 본문에 둠 → 정의가 갈라질 위험.
  - `.claude/refs/code-review.md §8` 단일 참조로 수렴하고 각 스킬은 링크만.
  - 우선순위: 중(DRY/SSOT 위반 소지).

- [ ] **`code-security-review` references/ 보강 (선택)**
  - 단일 SKILL.md → 시크릿 패턴 카탈로그·카테고리별 체크리스트를 `references/`로 분리(feature-data-verification 패턴 참고).
  - 우선순위: 낮음.

- [ ] **plugin 버전 메타 정합**
  - 플러그인별 버전이 활동량에 따라 갈라지는 중(예: `devoks-sdlc` 1.2.0, `devoks-browser` 1.1.0, 나머지 1.0.x). 릴리스 정책 확정 시 버전 규칙(개별 semver 유지 vs 하네스 일괄 버전)을 통일.
  - 우선순위: 낮음.
