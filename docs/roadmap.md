# Roadmap — 추후 개선 사항 (TODO)

DevOks 하네스의 플러그인 구조·내용 개선 후보를 모아두는 단일 SSOT 문서.
양 언어 README는 이 문서를 링크만 한다(이중 관리 drift 방지).

> 최종 갱신: 2026-07-14

---

## 우선순위 한눈에


| 우선순위   | 항목                                                                                                                                                   |
| ------ | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| **높음** | UI 작업 분리 검토 · `**devoks-sdlc-orchestration` 신설(비-HITL SDLC)** · 스킬 평가/검증 워크플로우 보강                              |
| **중**  | 컨벤션 preset 확장(신규 stack) · `browser-visual-diff` 이전 · `metro-devtools-attach` · 카탈로그 자동 생성 · evals 하니스 확대 · 심각도 분류 SSOT 통합 · MCP 버전 고정 검토 · MCP 가이드 이중 관리 정리 · MCP project-scope 표준화 검토                  |
| **낮음** | 구현자 세션 지속(continuation) · 진입점 일관화 · `devoks-release` 신설 · Operate/Maintain 단계 · `code-security-review` references 보강 · plugin 버전 메타 정합             |


---

## 마이그레이션 / 구조

- [ ] **컨벤션 preset 확장 (신규 stack)**
  - management 고도화(provenance hash 기반 stale 감지, 플러그인 번들링 버그 수정)는 2026-07-14 완료 — 완료 섹션 참고.
  - 남은 범위: `react-web`·`react-native`·`android`·`ios` 4개 외 `nextjs`, `node-backend`, `fastapi`, `spring`, `swiftui-only`, `compose-only` 등 세분 preset 추가.
  - 우선순위: 중(management 인프라는 갖춰졌으니 실제 수요가 생길 때 진행 — blocking 이슈 없음).

- [ ] `**browser-visual-diff` → `devoks-sdlc:verify-visual-diff` 이전**
  - 시각 diff는 본질적으로 "검증"이므로 devoks-sdlc의 verify 계열로 모으는 것이 도메인상 자연스럽다.
  - 동반 이동 필요: `browser-visual-diff-capture` 에이전트, `references/` 일체.
  - 결합 비용(이번에 보류한 이유): Chrome DevTools MCP 선언이 `devoks-browser/plugin.json`에 있고 Figma MCP·`browser-devtools` 형제 스킬과 묶여 있음 → 이전 시 MCP 의존 선언 이전 또는 cross-plugin 의존 정리가 선행되어야 함.
  - 영향 범위: README/README.ko 카탈로그, `docs/mcp-setup-guide.md`, `devoks-core/hooks/check-setup-state.sh`(chrome-devtools 감지가 "devoks-browser" 문자열도 grep함 — 이전 시 감지 로직 점검).
  - 우선순위: 중.

- [ ] **구현자 세션 지속 — 에이전트 continuation 기반 PR그룹 단위 위임**
  - 현재 태스크 단위 cold-start 위임은 인계 노트(요약 채널)로 지식 단절을 완화 중. subagent continuation(재호출 시 컨텍스트 유지)이 팀 배포 환경에서 공식 지원됨이 검증되면, **PR그룹(모듈) 단위로 `code-implementer` 1개를 유지하며 태스크를 순차 투입**하는 방식으로 전환 — 같은 모듈 재독 1회로 축소, 네이밍·패턴 일관성 확보. 인계 노트의 상위 호환.
  - 선행 조건: Claude Code subagent continuation 공식 문서 확인 + 팀 최소 버전 정책 합의.
  - 관련 SSOT: `plugins/devoks-sdlc/skills/feature-workflow-runner/references/task-delegation.md`.
  - 우선순위: 낮음(검증 선행).

- [ ] **진입점 일관화 검토 (command vs skill)**
  - 팀이 스킬 우선으로 이동 중(`new-feature-verify` 커맨드→스킬 전환). 그러나 `new-feature-draft`/`new-feature-github-issue`/`new-ui-draft`/`code-*` 등은 여전히 커맨드.
  - 트리거 기반(자연어) 호출로 통일할지, command는 진입 전용으로 남길지 정책을 한 번 확정.
  - 우선순위: 낮음(정책 결정 먼저).

---

## SDLC 커버리지 확장

- [ ] **UI 작업 분리 검토 (기능 구현 전/후 집중 처리)**
  - 현재 기능 구현 흐름 안에서 UI까지 함께 처리하면 화면 충실도가 낮아지는 경향이 있음.
  - 검토 방향: 기능 구현 전 UI 요구사항/상태/빈 화면을 별도 정리하고, 기능 구현 후 시각 품질·반응형·접근성·visual diff를 별도 패스로 검증.
    - 피그마 리소스의 체계화 사전 작업이 필수, 태스크 요청시 피그마 UI시안의 링크정보의 정확도,구조등 UI작업시 필요한 리소스 정련 중요
  - 결정 필요: `new-ui-draft`를 선행/후행 UI 패스로 분리할지, `feature-workflow-runner` Phase 안에 UI 체크포인트를 명시할지.
  - 우선순위: 높음(UI 품질 안정화).

- [ ] `**devoks-sdlc-orchestration` 신설 — 비-HITL(전체 위임) SDLC 오케스트레이션 플러그인**
  - **배경**: 현재 `devoks-sdlc`(`feature-workflow-runner` 중심)는 HITL(Human-in-the-Loop) 전제다. FRD 누락 슬롯·설계 스펙·브랜치/이슈 사전체크마다 사용자 확인이 필요하고, Phase 경계 중간 리포트·단계적 구현/리팩토링을 사람이 리뷰하며 진행한다. 커밋/PR도 사용자 명시 요청 시에만(`feature-workflow-runner` 범위 밖).
  - **목표**: 이슈 수신 → 작업 분해·실행 → 리뷰/평가/테스트 → PR·최종 리포트까지 **중간 승인 없이** 오케스트레이션하는 대규모 자동화 프레임워크. `devoks-sdlc`와 **공존**하되, 진입 조건·권한·에스컬레이션 정책을 분리한다.
  - **우선순위**: 높음(아키텍처·외부 연동 범위가 커서 **단계적 도입** — MVP부터 착수).
  #### 현재(HITL) vs 목표(비-HITL) 대비
  
  | 축         | `devoks-sdlc` (HITL)     | `devoks-sdlc-orchestration` (목표)      |
  | --------- | ------------------------ | ------------------------------------- |
  | **진입**    | FRD 초안·대화                | 이슈/티켓/웹훅/스케줄 트리거                      |
  | **스펙 확정** | 누락·설계 매 단계 사용자 확인        | 합리적 기본값·정책 SSOT로 자동 확정(불확실 시 에스컬레이션만) |
  | **실행**    | 태스크 단위 위임 + 메인 루프 판정     | 파이프라인 전 구간 에이전트 체인·병렬 실행              |
  | **중간 산출** | FRD/PLAN/태스크 리포트(사람 검토용) | 머신 가독 상태 파일 + 이벤트 로그(사람은 예외 시만)       |
  | **검증**    | DoD 수동 점검·사용자 재개         | 테스트·리뷰·보안·요구사항 검증 자동 게이트              |
  | **딜리버리**  | 커밋/PR 사용자 요청 시           | 브랜치·커밋·PR·CI 트리거까지 파이프라인 포함           |
  | **실패 처리** | `blocked` → 사용자 확인       | 재시도·롤백·이슈 코멘트·담당자 알림                  |
  
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
  
  | 단계            | 범위                                             | 산출                                  |
  | ------------- | ---------------------------------------------- | ----------------------------------- |
  | **0 — 정책**    | 자동화 허용 범위·금지 경로(시크릿·인프라·DB 마이그레이션)·에스컬레이션 연락처  | `orchestration-policy.md` SSOT      |
  | **1 — MVP**   | 수동 트리거 1건: 이슈 URL → 브랜치·구현·테스트·draft PR·요약 리포트 | `devoks-sdlc-orchestration` 플러그인 골격 |
  | **2 — 검증 강화** | 리뷰/보안/요구사항 게이트·재시도·`blocked` 자동 분류             | 게이트 실패 시 이슈 코멘트                     |
  | **3 — 트리거**   | Linear/GitHub 이슈 라벨·웹훅·(선택) Slack 명령           | 이벤트 기반 RUN 큐                        |
  | **4 — 운영**    | RUN 큐·동시성·비용 상한·감사 로그·evals                    | 팀 운영 가이드                            |
  
  #### 외부 솔루션 연동 키워드 (조사·선정 TODO)

  플러그인 **밖**에서 제공될 수 있는 영역 — 구현 시 어댑터(thin-wrapper 스킬/MCP/CLI)로 연결.
  
  | 영역                 | 키워드 / 후보                                                          |
  | ------------------ | ----------------------------------------------------------------- |
  | **이슈·프로젝트 관리**     | Linear, GitHub Issues, Jira, Asana, Shortcut                      |
  | **알림·HITL 에스컬레이션** | Slack, Microsoft Teams, Discord, PagerDuty                        |
  | **코드·PR**          | GitHub Actions, GitLab CI, CircleCI, `gh` CLI, Graphite, Mergify  |
  | **리뷰 에이전트**        | Cursor Bugbot, CodeRabbit, Greptile, SonarQube, Semgrep           |
  | **테스트**            | Jest, Vitest, Playwright, Cypress, pytest, `test-run-triage` 연동   |
  | **스펙·문서**          | Notion, Confluence, Figma(시안 링크), OpenAPI/Swagger                 |
  | **관측·품질**          | Datadog, Sentry, codecov, bundle-size CI                          |
  | **오케스트레이션**        | Temporal, Inngest, GitHub Actions workflow_dispatch, queue worker |
  | **정책·시크릿**         | OPA, vault, repository rulesets, branch protection                |
  
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

- [ ] `**devoks-release` 신설 (Deploy/Release 단계 — 현재 0% 커버)**
  - Conventional Commits → CHANGELOG 생성 + semver bump + tag (devoks-git의 자연스러운 확장).
  - 릴리스 준비도 게이트: lint + type + test + review + verify 결과를 집계해 머지/릴리스 가능 여부 리포트.
  - CI 워크플로(예: GitHub Actions) 작성·유지 스킬.
  - 우선순위: 낮음(딜리버리 빈칸 — `devoks-sdlc-orchestration` Deliver 단계와 경계 협의 후 순서 조정 가능).

- [ ] **Operate/Monitor · Maintain 단계 (장기)**
  - 의존성 업그레이드 제안, 보안 패치/CVE 추적, 회귀 감지 등.
  - 환경 종속이 커서 대부분 thin-wrapper 또는 외부 도구 연동으로 설계 필요.
  - 우선순위: 낮음(장기).

---

## 품질 / 유지보수

- [ ] **스킬 평가/검증 워크플로우 보강**
  - `devoks-team-harness` management 흐름에 신규/기존 스킬의 효용성·정합성·설치 가능성·레퍼런스 충실도를 검증하는 체크를 추가.
  - 구현 후보: 기존 유지보수 스킬에 평가 절차를 붙이거나, `verify-skill-quality` 같은 독립 검증 스킬을 신설.
  - 필수 검증 축: 스킬 description과 실제 동작 일치, 필요한 `references/` 존재, 예시/evals 보유 여부, 의존 MCP/도구 명시, 플러그인 설치 후 경로 참조 안전성.
  - 레퍼런스 후보: `docs/plugin-management.md` 검증 섹션, Claude Code plugin validation 문서, 기존 `evals/evals.json` 패턴.
  - 우선순위: 높음(스킬 품질과 배포 안정성 직결).

- [ ] `**metro-devtools-attach` — iOS 시뮬레이터 디버깅 환경 검증 및 테스트**
  - 대상: `plugins/devoks-rn/skills/metro-devtools-attach/SKILL.md`
  - 현재 `metro-devtools` MCP 검증 완료 기록은 Metro CDP 연결(`get_metro_status`·`evaluate_script`·`list_console_messages`) 동작 확인 위주이며, iOS 시뮬레이터(`xcrun simctl`) 경로는 스크린샷 캡처 외 실기 검증 근거가 명확하지 않음.
  - 검증 범위: iOS 시뮬레이터 부팅 상태에서 `xcrun simctl io booted screenshot` 스크린샷 캡처 + Metro CDP(`evaluate_script`, `list_console_messages`, `list_network_requests`) 정상 동작 확인, SKILL.md 트러블슈팅 표·전제 조건에 iOS 특이사항 반영.
  - 우선순위: 중.

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

- [ ] `**code-security-review` references/ 보강 (선택)**
  - 단일 SKILL.md → 시크릿 패턴 카탈로그·카테고리별 체크리스트를 `references/`로 분리(feature-data-verification 패턴 참고).
  - 우선순위: 낮음.

- [ ] **plugin 버전 메타 정합**
  - 플러그인별 버전이 활동량에 따라 갈라지는 중(예: `devoks-sdlc` 1.2.0, `devoks-browser` 1.1.0, 나머지 1.0.x). 릴리스 정책 확정 시 버전 규칙(개별 semver 유지 vs 하네스 일괄 버전)을 통일.
  - 우선순위: 낮음.

- [ ] **MCP 서버 버전 고정 검토 (`setup-mcp`)**
  - 현재 `claude mcp add`로 설치하는 context7·codegraph·serena가 `@latest`를 사용해, 설치 시점에 따라 팀원 간 버전이 달라질 수 있음(번들·user-scope 선택과 무관하게 존재하는 드리프트).
  - 검토 방향: 특정 버전 핀 vs `@latest` 유지의 트레이드오프(보안 패치 지연 vs 팀 일관성) 판단 후 `plugins/devoks-core/commands/setup-mcp.md`·`docs/mcp-setup-guide.md` 갱신.
  - 우선순위: 중(당장 깨지는 이슈 아님 — 팀 규모 커질 때 재검토).

- [ ] **MCP 설치 가이드 이중 관리 정리 (`setup-mcp.md` ↔ `mcp-setup-guide.md`)**
  - Chrome 디버그 실행 커맨드가 두 문서에 inline 중복(플러그인 루트 외부 참조 금지 제약 때문에 불가피하게 선택한 트레이드오프)돼 있고, 현재는 문서 내 주석("한쪽 고치면 반드시 다른 쪽도 갱신")으로 수동 동기화 중.
  - 검토 방향: 위 "카탈로그 자동 생성" 항목과 유사하게 단일 원본에서 생성하는 방식 검토, 혹은 현재 수동 동기화가 실제로 더 간단한지 재확인.
  - 우선순위: 중.

- [ ] **MCP project-scope 표준화 검토 (`.mcp.json` 팀 공유)**
  - 현재 공유 MCP(context7·codegraph·serena 등)는 user-scope 개별 설치 방식 — 팀원마다 설치 시점·옵션이 달라질 수 있음.
  - 검토 방향: 리포에 커밋되는 project-scope `.mcp.json` 전환 시 이점(팀 일관성) vs 리스크(동일 서버가 user-scope에도 있을 때 병합/중복 동작이 실제로 어떻게 되는지 미검증)를 먼저 실험으로 확인한 뒤 판단.
  - 관련 배경: 플러그인 번들(plugin.json `mcpServers`) 방식은 2026-07-14 논의에서 기각 — 공유 MCP 인스턴스가 플러그인 수만큼 중복되고 stateful 서버(Playwright·Serena) 리소스/락 충돌 위험이 커짐. `setup-mcp.md`/`docs/mcp-setup-guide.md`의 현재 근거는 유효하다고 판단.
  - 우선순위: 중.

---

## 완료 / 최근 반영

- [x] **코드 리뷰 워크플로우 개선 — 5항목 필수 체크리스트 + 체크리스트 커버리지 섹션 + finding 필드 확장** (2026-07-20, `devoks-sdlc` `1.3.2 → 1.4.0`)
  - `code-review` 스킬(Step 3)에 "잠재적 버그 / 예외 처리 / 성능 / 보안 / 가독성" 5개 필수 체크리스트를 로컬로 추가 — 공유 SSOT(`devoks-core/refs/code-review.md`의 Layered Examination)는 변경하지 않고, 그 5단계를 빠뜨리지 않고 확인했는지 확정짓는 실행 게이트로 별도 배치(`code-security-review` 등 다른 SSOT 소비자에 영향 없음, core-sync 점검 불필요 — 논의 후 결정).
  - 출력 템플릿에 `✅ 체크리스트 커버리지` 섹션을 신설(5축 확인 결과를 리포트 상단에 가시화), Critical/High/Medium/Low 4개 등급 finding 템플릿 전체에 `재현/검증 방법`·`후속 테스트 필요` 필드 추가.
  - 반영: `skills/code-review/SKILL.md`(체크리스트·출력 템플릿·`metadata.version` `1.0.1 → 1.1.0`), `commands/code-review-general.md`·`code-review-diff-branch.md`(pass-through 금지 목록 필드 갱신), `plugin.json` 버전.
  - 심각도 분류 SSOT를 4개 스킬(`code-review`·`code-security-review`·`verify-requirements`·`test-run-triage`)에 걸쳐 통합하는 일은 별도 "중" 우선순위 항목("심각도 분류 SSOT 통합")으로 분리 유지 — 이번 작업 범위 밖.

- [x] **컨벤션 preset management 고도화 — hash 기반 stale 감지 + 플러그인 루트 번들링 버그 수정** (2026-07-14, `devoks-core` `1.1.4 → 1.2.0`)
  - 선행 발견·수정: `shared/conventions/`가 `plugins/devoks-core/` **바깥**(저장소 루트)에 있어 이 저장소 자신의 "플러그인 루트 외부 참조 금지" 규칙을 위반 — 실제 설치된 대상 프로젝트에서는 `/devoks-core:setup-project-convention`이 참조하는 preset 원본에 접근할 방법이 전혀 없었다(harness 저장소 자신의 워킹디렉토리에서만 우연히 동작). `shared/conventions/*` → `plugins/devoks-core/conventions/`로 이전하고 `${CLAUDE_PLUGIN_ROOT}/conventions/<preset>/...`로 참조하도록 전환(공식 문서 확인: `${CLAUDE_PLUGIN_ROOT}`는 skill/command 본문·Bash 실행 컨텍스트에도 inline 치환됨). `shared/setup/`·`shared/templates/`는 `setup.sh`에서만 참조되어 같은 문제가 없어 이동 대상에서 제외.
  - `.claude/project-convention.json` provenance에 `presetHash`(sha256) 필드 추가. `project-convention-manage` Step 1에 hash 사전 체크를 추가해, 매번 전체 diff·유사도 추론을 도는 대신 "업스트림 preset이 그 사이 바뀌었는지"를 값싸고 정확하게 먼저 판별한다 — 동일하면 즉시 "변경 없음" 보고(전체 diff 생략), 다르면 기존 diff/selective-apply 흐름을 그대로 진행 후 해시 갱신. `presetHash`가 없는 레거시 provenance는 기존 유사도 추론 체인으로 폴백(에러 없음).
  - 반영: `setup-project-convention.md`(Step 6 해시 계산·저장), `project-convention-manage/SKILL.md`(SSOT·Step 1/5/6), `README.md`·`docs/README.ko.md`(디렉토리 구조·경로 표), `.claude/rules/project-convention.md`(SSOT 경로 갱신·Pitfall 항목 추가), `plugin.json` 버전.
  - preset 확장(신규 stack 추가)은 별도 오픈 항목으로 분리 유지 — 위 "마이그레이션 / 구조" 참고.

- [x] **컨벤션 preset 구조 + explicit setup 모델 도입** (2026-07-09, `devoks-core` `1.0.3 → 1.1.0`)
  - `shared/conventions/` 아래에 `react-web`·`react-native`·`android`·`ios` starter preset SSOT를 분리하고, 프로젝트 active convention은 `.claude/rules/project-convention.md`로 선택 주입하는 구조로 재정의.
  - legacy `sync-context.sh` 기반 SessionStart overwrite 모델을 종료하고, `setup-project-convention` 커맨드 + `project-convention-manage` 스킬 기반 explicit setup/apply 흐름으로 전환. SessionStart 훅은 `check-setup-state.sh` 상태 점검만 유지.
  - 반영: README.md·docs/README.ko.md Quick Start/카탈로그/디렉토리 구조, `setup.sh` 폴백 부트스트랩 흐름, 관련 command/skill의 `project-convention.md` 해석 문구 정리.

- [x] `**test-author` 승격 — 메인 루프 실행 skill → `test-writer`(`sonnet`) 위임형 에이전트** (2026-07-08, `devoks-sdlc` `1.2.2 → 1.3.0`)
  - 근거: `code-implementer`와 동일한 3기준 재검증(스펙 완결성·인터랙션 필요성·컨텍스트 격리 이득) — target 명시 시 스펙 완결적, 승인 게이트 불필요, 소스·기존 테스트 다독+자기검증 로그로 격리 이득 큼. Opus급 추론 불필요(대상 코드에 이미 정의된 동작을 검증하는 실행형).
  - 구조: `commands/test-author.md`(신규, target 모호성 확인 후 위임) → `agents/test-writer.md`(신규, `model: sonnet`, `Skill` 도구로 엔진 호출) → `skills/test-author/SKILL.md`(기존 skill을 agent-internal 엔진으로 재프레이밍, done/blocked 리포트 스키마 추가) — `code-security-review`(커맨드·에이전트·엔진 skill 3단 분리)와 동일 패턴.
  - 반영: README.md·docs/README.ko.md 카탈로그(스킬/에이전트/커맨드 3개 표), `docs/plugin-management.md` §12 아키타입 매핑, `plugin.json` 버전.

- [x] `**code-implementer` model: `inherit` → `sonnet` 고정 재조정** (2026-07-08)
  - 근거: Anthropic 공식 Claude Code 가이드가 "plan with Opus, execute with Sonnet" 패턴을 명시 권장(`/model opusplan` 내장 지원)하며, Opus가 Sonnet 대비 Pro/Max 사용량 한도를 "meaningfully more" 소비한다고 밝힘. devoks-sdlc 구조상 FRD/PLAN 작성(plan, 메인 루프 유지)과 `code-implementer` 구현 실행(execute)이 이 패턴과 정확히 대응됨.
  - 기존(2026-07-06~07) quality-first 원칙("구현 품질=세션 추론 깊이") 자체는 유지하되, "실행 단계는 계획 단계와 다른 추론 형태를 요구한다"는 근거로 예외를 적용. 스코프 초과 시 blocked→메인 루프 인수 안전장치가 품질 리스크를 흡수.
  - 반영: `code-implementer.md` frontmatter, `docs/plugin-management.md` §12(모델 선택 기준·아키타입 매핑), `task-delegation.md`(위임 손익분기 — 세션이 opus/fable이면 위임이 시간·rate limit 절약도 제공하도록 갱신).

- [x] **devoks-sdlc 모델 티어링 + `code-implementer` 태스크 위임 도입** (2026-07-06~07, `1.1.1 → 1.2.0`)
  - `code-implementer` 에이전트 신설(최초 `model: inherit` — quality-first: 구현 품질은 세션 추론 깊이와 동일해야; 2026-07-08에 `sonnet` 고정으로 재조정, 위 항목 참고), `code-security-reviewer`는 `opus` + `effort: high`로 상향. 티어링 판단 3기준(스펙 완결성·인터랙션 필요성·격리 이득)과 역할 아키타입 매핑은 `docs/plugin-management.md` §12로 확장.
  - Phase 3 실행 구조: PLAN Task `size: S/M/L` 마커 기반 규칙 라우팅(S 직접 / M 위임 / L 분해 재검토) + done 리포트 인계 노트 누적(크로스 태스크 지식 유지). SSOT: `task-delegation.md`(실행 측)·`task-pr-splitting.md`(부여 측).

- [x] `**devoks-code`·`devoks-feature`·`devoks-test`·`devoks-verify` → `devoks-sdlc` 단일 플러그인 통합**
  - 4개 모두 MCP/permission/hook이 없는 순수 스킬/커맨드/에이전트 팩이라 분리 설치의 격리 이득이 없고, 스킬 description 간 cross-reference(test-author↔verify-requirements, feature-plan-executor↔code-security-review 등)가 분리 설치 시 끊김.
  - 컴포넌트 합산: commands 8 + skills 10 + agents 2, 이름 충돌 없음. prefix `devoks-{code,feature,test,verify}:` → `devoks-sdlc:` 일괄 변경.
  - 카탈로그/문서 동기화: marketplace.json, settings.json, README/README.ko, mcp-setup-guide, plugin-management, setup.sh. 부수로 README 스킬표의 `frd-author`→`feature-frd-author` drift 정정.
  - `devoks-core`·`devoks-git`·`devoks-browser`·`devoks-rn`은 분리 유지(core 의존 또는 MCP/permission 비용 실재).

- [x] `**devoks-rn` 신설 (React Native 디버깅)**
  - `metro-devtools-attach` 스킬: 에뮬레이터 스크린샷, Metro CDP JS 콘솔/상태 조회.
  - `metro-devtools` MCP는 WebSocket URL 동적 변경으로 `~/.claude.json` 수동 등록 필요.
  - 마켓플레이스 식별자 `devoks` → `devoks-plugins` 로 변경.

