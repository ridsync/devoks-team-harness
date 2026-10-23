# Roadmap — 추후 개선 사항 (TODO)

DevOKs 하네스의 플러그인 구조·내용 개선 후보를 모아두는 단일 SSOT 문서.
양 언어 README는 이 문서를 링크만 한다(이중 관리 drift 방지).

> 최종 갱신: 2026-09-18

---

## 우선순위 한눈에


| 우선순위   | 항목                                                                                                                                          |
| ------ | ------------------------------------------------------------------------------------------------------------------------------------------- |
| **높음** | UI 작업 분리 검토 · `devoks-sdlc-orchestration` 신설(비-HITL SDLC)                                                                                   |
| **중**  | 컨벤션 preset 확장(신규 stack) · `browser-visual-diff` 이전 · `metro-devtools-attach` |
| **낮음** | `devoks-release` 신설 · Operate/Maintain 단계 · `code-security-review` 시크릿 패턴 카탈로그                                                              |


---

## 마이그레이션 / 구조

- [ ] **컨벤션 preset 확장 (신규 stack)**
  - management 고도화(provenance hash 기반 stale 감지, 플러그인 번들링 버그 수정)는 2026-07-14 완료 — 완료 섹션 참고.
  - `python-fastapi` preset 추가는 2026-09-15 완료 — 완료 섹션 참고.
  - 남은 범위: `react-web`·`react-native`·`android`·`ios`·`python-fastapi` 5개 외 `nextjs`, `node-backend`, `spring`, `swiftui-only`, `compose-only` 등 세분 preset 추가.
  - 우선순위: 낮음(management 인프라는 갖춰졌으니 실제 수요가 생길 때 진행 — blocking 이슈 없음).

- [ ] `**browser-visual-diff` → `devoks-sdlc:verify-visual-diff` 이전**
  - 시각 diff는 본질적으로 "검증"이므로 devoks-sdlc의 verify 계열로 모으는 것이 도메인상 자연스럽다.
  - 동반 이동 필요: `browser-visual-diff-capture` 에이전트, `references/` 일체.
  - 결합 비용(이번에 보류한 이유): Figma MCP·`browser-devtools` 형제 스킬과 묶여 있음 → 이전 시 cross-plugin 의존 정리가 선행되어야 함. (Chrome DevTools MCP 선언은 2026-10-23 `devoks-browser` 2.0.0에서 `plugin.json` 번들을 제거하고 user scope 등록으로 옮겨 이 결합은 해소됨 — 완료 섹션 참고.)
  - 영향 범위: README/README.ko 카탈로그, `docs/mcp-setup-guide.md`. (`check-setup-state.sh`의 chrome-devtools 감지는 2.3.0에서 `devoks-browser` 문자열 grep 폴백을 제거해 이전 시 점검할 항목이 없어짐.)
  - 우선순위: 중.

---

## SDLC 커버리지 확장

- [ ] **UI 작업 분리 검토 (기능 구현 전/후 집중 처리)**
  - 현재 기능 구현 흐름 안에서 UI까지 함께 처리하면 화면 충실도가 낮아지는 경향이 있음.
  - 검토 방향: 기능 구현 전 UI 요구사항/상태/빈 화면을 별도 정리하고, 기능 구현 후 시각 품질·반응형·접근성·visual diff를 별도 패스로 검증.
    - 피그마 리소스의 체계화 사전 작업이 필수, 태스크 요청시 피그마 UI시안의 링크정보의 정확도,구조등 UI작업시 필요한 리소스 정련 중요
  - 결정 필요: UI컴포넌트, 구조설계 및 기능구현작업 이후 UI CSS스타일링과 다듬기(polish)를 별도 단계로 추가할지, 아니면 기능구현시 병행 구현이 가능하도록 스킬을 고도화 할지. / 이외 추가적으로 `new-ui-draft`를 선행/후행 UI 패스로 분리할지, `feature-workflow-runner` Phase 안에 UI 다듬기(polish)를 명시할지.
  - 근거 보강(2026-07-22): `FRD.template.md` §4 Design Spec은 컴포넌트/아키텍처 구조 중심이라 i18n 키·색상 인디케이터·버튼 활성 조건 같은 UI 세부 사양을 ID로 강제 추적하지 않음(`verify-requirements`의 F/B/E/D 카테고리는 FRD §3/§5/§8에 대응되지만 U는 대응 섹션이 약함) — `post-implementation-checklist.md` 항목 1이 U를 범위 밖으로 명시하며 이 항목을 참조.
  - 우선순위: 높음(UI 품질 안정화).

- [ ] `**devoks-sdlc-orchestration` 신설 — 비-HITL(전체 위임) SDLC 오케스트레이션 플러그인**
  - **배경**: 현재 `devoks-sdlc`(`feature-workflow-runner` 중심)는 HITL(Human-in-the-Loop) 전제다. FRD 누락 슬롯·설계 스펙·브랜치/이슈 사전체크마다 사용자 확인이 필요하고, Phase 경계 중간 리포트·단계적 구현/리팩토링을 사람이 리뷰하며 진행한다. 커밋/PR도 사용자 명시 요청 시에만(`feature-workflow-runner` 범위 밖).
  - **목표**: 이슈 수신 → 작업 분해·실행 → 리뷰/평가/테스트 → PR·최종 리포트까지 **중간 승인 없이** 오케스트레이션하는 대규모 자동화 프레임워크. `devoks-sdlc`와 **공존**하되, 진입 조건·권한·에스컬레이션 정책을 분리한다.
  - **우선순위**: 높음(아키텍처·외부 연동 범위가 커서 **단계적 도입** — MVP부터 착수).
  - **확정 설계 결정(SSOT)**: 자율성 다이얼·대체 게이트·실행 모델·트리거·에스컬레이션·조건부 실동작 게이트(D1~D6)는 `docs/orchestration-design.md`가 SSOT. 아래 대비표·파이프라인·오픈 결정은 그 문서의 확정 내용으로 갱신됨(2026-07-23).
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
   Slack/webhook   스펙 자동보완    병렬 라우팅   size 라우팅       data-flow   security      merge?   최종 요약
  ```
  - **트리거(Intake)**: 외부 이슈·라벨·assignee·우선순위를 RUN(실행 단위)으로 매핑. 입력이 빈약하면 템플릿·과거 유사 이슈·코드베이스 스캔으로 스펙 보완(추측 상한·에스컬레이션 규칙 필수).
  - **Plan**: `devoks-sdlc`의 FRD/PLAN·`traces`·PR 분리 규칙을 **재사용**하되, 승인 게이트 제거·`status` 전환 자동화. RUN 메타(`run-id`, `issue-ref`, `policy-version`)를 frontmatter에 고정.
  - **Implement**: `code-implementer` + `size` 라우팅. 브랜치 생성·이슈 링크는 사전체크 확인 없이 **정책 기본값** 적용(`devoks-git` 연동).
  - **Verify**: 검증 체인 순서는 `post-implementation-checklist.md`가 SSOT(요구사항→코드리뷰→데이터흐름→UI 시각품질→브라우저 실동작 검증→테스트 회귀). `verify-acceptance-test`(실동작)는 dev server+Chrome(9269) 감지 시 커밋 직전 직렬 게이트, 미감지 시 draft PR 플래그로 위임(D6). 실패 시 자동 수정 루프 상한 N회 후 에스컬레이션.
  - **Review**: `code-review`, `code-security-review` — 심각도 임계 초과 시 PR draft 유지·머지 차단.
  - **Deliver**: Conventional Commits 커밋, PR 본문(추적성·테스트·리스크), CI 워크플로 트리거. `devoks-release`와 경계 협의(릴리스 vs 기능 PR).
  - **Report**: RUN 종료 리포트(성공/부분/실패), 이슈·Slack에 요약·아티팩트 링크. 중간 Phase 리포트는 생략·이벤트 스트림으로 대체.
  #### `devoks-sdlc`와의 관계
  - **공유**: 에이전트(`code-implementer`, `code-reviewer`, `code-security-reviewer`), 스킬 자산(PLAN/FRD 템플릿, `task-delegation`, `traceability`, 검증·리뷰 스킬), 심각도 SSOT.
  - **분리**: 오케스트레이터 스킬/커맨드(`orchestration-workflow-runner` 등), RUN 상태 스키마, 트리거·웹훅·권한(쓰기·PR·머지), 에스컬레이션·재시도 정책, 외부 MCP/CLI 어댑터.
  - **의존성 후보**: `devoks-core`, `devoks-git`, `devoks-sdlc`(스킬 참조 또는 soft dependency). `devoks-browser`는 `verify-acceptance-test`(1.10.0에서 devoks-sdlc가 `dependencies`로 선언) 및 visual diff를 통해 **transitive 의존**.
  #### 단계적 도입 (제안)
  
  | 단계            | 범위                                                                    | 산출                                                                                                                                                                     |
  | ------------- | --------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
  | **0 — 정책**    | 자동화 허용 범위·금지 경로(시크릿·인프라·DB 마이그레이션)·에스컬레이션 연락처                         | 정책 SSOT `plugins/devoks-sdlc-orchestration/references/orchestration-policy.md` (`policy-version 0.2.0`, 번들 단일본)                                                        |
  | **1 — MVP**   | 수동 트리거 1건: 이슈 URL → 브랜치·구현·테스트·draft PR·요약 리포트                        | `devoks-sdlc-orchestration` 저작 완료(2026-07-23 `0.2.0`, 현재 번들 `**0.2.1**`): `orchestration-run` 스킬 + `pipeline.md` + 정책 번들. validate ✔. 크로스-플러그인 호출은 post-publish 스모크 대기 |
  | **2 — 검증 강화** | 리뷰/보안/요구사항 게이트·재시도(2회)·`blocked` 자동 분류 **저작 완료**(pipeline.md Stage 4) | 이슈 코멘트/Slack 어댑터 배선은 단계 3(MVP 콘솔 fallback)                                                                                                                             |
  | **3 — 트리거**   | Linear/GitHub 이슈 라벨·웹훅·(선택) Slack 명령                                  | 이벤트 기반 RUN 큐                                                                                                                                                           |
  | **4 — 운영**    | RUN 큐·동시성·비용 상한·감사 로그·evals                                           | 팀 운영 가이드                                                                                                                                                               |
  
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
  - **품질**: HITL 제거만큼 게이트·샌드박스 실행이 필수 — 스킬 품질 검증은 `.claude/skills/devoks-plugin-maintenance/references/workflow-checklist.md` §7(8축)을 그대로 쓴다. 공용 evals 러너는 없다(구 "evals 하니스 확대" 항목은 2026-08-21 폐기 — 아래 폐기 ② 참고: `claude plugin eval`이 early-access 게이트로 실행 불가, `evals.json`과 포맷 비호환). 게이트가 열리면 이 항목의 전제도 함께 재검토할 것.
  - **비용·동시성**: RUN당 토큰·서브에이전트 상한, 큐 백프레셔 정책.
  - **법·컴플라이언스**: 고객 데이터·라이선스가 걸린 변경은 자동화 제외 목록에 명시.
  #### 네이밍 결정
  - **채택**: `devoks-sdlc-orchestration` — `devoks-agentic-sdlc` 대비 **역할(파이프라인 오케스트레이션)** 이 명확하고, `devoks-sdlc`와 형제 네이밍·prefix(`devoks-sdlc-orchestration:`)가 자연스럽다. `agentic`은 하네스 전반이 에이전트 기반이라 구분력이 약함.
  - **별도 플러그인** 유지(격리·권한 분리 유리) — `devoks-sdlc`에 모드 플래그로 합치지 않음.
  #### 확정된 결정 (구 오픈 결정, 2026-07-23 종결 — 상세 `docs/orchestration-design.md`)
  - 머지 자동화: **draft PR only**(auto-merge 제외, main 직접 푸시 금지) — D1.
  - 1차 트리거 SSOT: **Linear**. 단 MVP는 수동 트리거(이슈 URL/식별자 입력), 웹훅·스케줄은 단계 3 — D4.
  - 자율성 수준: **human-on-the-loop**(예외 시만 개입, draft PR 아티팩트 리뷰) — D1.
  - HITL 대체 게이트: EARS 실행가능 스펙 게이트 + 격리·복구(네트워크 차단 샌드박스+worktree+롤백) + 한도·안전(재시도상한·deny-list·에스컬레이션). LLM-judge 리뷰어는 MVP 제외 — D2.
  - 실행 모델: Workflow 툴 + worktree 병렬, 단 브라우저 실동작 검증은 Chrome 9269 싱글턴이라 병합 후 직렬 barrier — D3·D6.
  #### 남은 오픈 결정
  - dial 상향(out-of-the-loop/auto-merge) 시점·LLM-judge 도입, Linear↔RUN 메타 매핑·웹훅 설계, Slack/Linear 어댑터 형태, D6 환경 감지·Chrome 싱글턴 큐잉 정책.

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

- [ ] **외부 도구 의존성 상시 재점검 (CodeGraph · context-mode · ast-grep · Serena)**
  - **정책 (2026-09-18 확정)**: 하네스가 권하는 외부 도구는 **실측된 효용성**이 있을 때만 유지한다. 유명하거나
    기능이 그럴듯한 것은 근거가 아니다. 주기적으로 실제 프로젝트에서 재점검해 **유지/제거를 명시적으로 결정**하고,
    제거로 결정되면 설치 안내뿐 아니라 **그 도구를 전제하는 스킬·규칙·템플릿까지 함께** 걷어낸다.
  - **왜 전제까지 걷어내야 하나**: 안내만 지우면 "스킬이 전제하는데 하네스는 설치를 권하지 않는다"는 역방향
    불일치가 남는다. 2026-09-18 context-mode 기각에서 실제로 `test-run-triage` 실행 전략과 `memory-policy.md`
    계층 표가 여기에 걸렸다(완료 항목 참고).
  - **제거 시 체크 지점**: `setup-mcp.md` · `check-setup-state.sh` · 스택 preset · `shared/templates` 도구 라우팅 ·
    `rules/*` · 해당 스킬 `description`과 절차 · `docs/mcp-setup-guide.md`(절 번호 재정렬 포함) · README 양본
    카탈로그·의존성 표 · `docs/plugin-management.md`.
  - **판정은 원빈님이 직접 수행** — 하네스는 결정을 반영하는 쪽만 담당한다.
  - **측정 수단**: 트랜스크립트에서 도구별 tool_use/tool_result 바이트를 귀속시키고(Bash 명령 본문으로 CLI
    사용도 포함), 훅 주입 구간을 따로 집계하는 스크립트가 `aware-react-app`의
    `.claude/workspace/tool-usage-audit-20260918/`(`measure.py` + `baseline-20260918.md`)에 있다.
    **하네스 저장소 밖 + 그 프로젝트 `.claude/`가 gitignore**이므로 런타임 의존으로 삼지 않는다 —
    유지보수자용 재현 자산 포인터일 뿐이다. 하네스로 흡수할지는 별건.
  - **다음 재측정: 2026-09말** (협업 세션 보고 기준). 그때 codegraph·ast-grep·serena 판정도 함께 나온다.
  - **판정 시 볼 것**: 도구 출력 바이트만 보지 말고 **훅·지침 주입 고정비**를 함께 센다 — context-mode
    기각의 결정적 근거가 "도구를 거의 안 쓰는데 훅 오버헤드는 매 세션 나갔다"였다.
  - 우선순위: 중 (도구 추가·갱신 시점마다).

- [ ] `**metro-devtools-attach` — iOS 시뮬레이터 디버깅 환경 검증 및 테스트**
  - 대상: `plugins/devoks-rn/skills/metro-devtools-attach/SKILL.md`
  - 현재 `metro-devtools` MCP 검증 완료 기록은 Metro CDP 연결(`get_metro_status`·`evaluate_script`·`list_console_messages`) 동작 확인 위주이며, iOS 시뮬레이터(`xcrun simctl`) 경로는 스크린샷 캡처 외 실기 검증 근거가 명확하지 않음.
  - 검증 범위: iOS 시뮬레이터 부팅 상태에서 `xcrun simctl io booted screenshot` 스크린샷 캡처 + Metro CDP(`evaluate_script`, `list_console_messages`, `list_network_requests`) 정상 동작 확인, SKILL.md 트러블슈팅 표·전제 조건에 iOS 특이사항 반영.
  - 우선순위: 중.

- [ ] `**code-security-review` 시크릿 패턴 카탈로그 (선택)**
  - `**references/` 분리 자체는 2026-08-24 완료** — 스킬 진입 이전 과정에서 `references/security-scan-execution.md`(절차)·`references/report-template.md`(출력)로 분리됐다.
  - **남은 범위**: 시크릿 탐지 **패턴 카탈로그**(정규식·파일 확장자·엔트로피 기준 등)를 별도 `references/`로 추가. 현재는 "범용 패턴 전수 스캔"이라고만 서술돼 실제 패턴이 에이전트 판단에 맡겨져 있다.
  - 우선순위: 낮음.

---

## 완료 / 최근 반영

- [x] **`chrome-devtools-attach` 플러그인 번들 제거 → user scope 등록으로 통일** (2026-10-23, `devoks-browser` `1.2.6 → 2.0.0`, `devoks-core` `2.2.0 → 2.3.0`)
  - 배경: 같은 이름의 서버가 `devoks-browser/plugin.json`과 user scope에 이중 정의돼 있었다(동작 이슈는 없고 유지보수성 문제). 또 Node 20.19에서 `chrome-devtools-mcp`의 `get_css_styles`가 `Set.prototype.intersection` 부재로 실패해(`engines`는 `^20.19.0` 허용 — 2026-10-23 실측, Node 22.22.2에서는 통과) Node·PATH를 정할 자리가 필요했는데, 플러그인 캐시 `plugin.json`은 업데이트 때 덮어써져 로컬 설정이 유지되지 않는다. 로드맵 폐기 ④가 정한 "공유 MCP는 `setup-mcp`가 user scope에 1회 설치" 모델에서 chrome-devtools만 예외였다.
  - 반영(사용자 결정): `devoks-browser`에서 `mcpServers` 제거(`settings.permissions.allow`는 유지 — `devoks-rn`·`metro-devtools`와 같은 형태). `setup-mcp` Step 6을 `claude mcp add --scope user` 등록으로 전환하고 구버전 이중 등록 점검·Node 22 권장 안내 추가. `check-setup-state.sh`의 `have "devoks-browser"` 폴백 제거. `browser-devtools` SKILL 환경 셋업 절, `mcp-setup-guide.md` 설치 정책·3절, README/README.ko 정리.
  - 의도적 미반영: `assets/chrome-debug.sh` 주석의 "devoks-browser 번들" 표현(복사 산출물이라 주석만 고쳐도 `setup-preset-manage`가 갱신 대상으로 판정함). `devoks-sdlc`의 "devoks-browser 플러그인 설치 전제" 문구(`verify-acceptance-test` 등 — 정확한 전제는 이제 "chrome-devtools-attach 등록"이라 후속 정리 대상).
  - 영향: `devoks-browser` 번들에만 의존하던 설치자는 업데이트 후 서버가 사라져 `setup-mcp` Step 6(또는 `claude mcp add`)이 필요하다 — 그래서 major bump.

- [x] **Define 앞단 재구성 — 두 스킬을 `feature-interview`로 통합하고 frd-author Phase 0 게이트로 연결** (2026-10-21, `devoks-sdlc` `3.6.0 → 3.7.0`)
  - 배경: 바로 아래 항목(3.5.0)에서 만든 `feature-intent-interview`·`feature-idea-refine`이 실제로는 많이 겹쳤다. idea-refine의 첫 질문이 사실상 인터뷰였고, 둘 다 같은 `FRD.draft.md`를 거쳐 frd-author로 넘어갔다. 결과적으로 요구 정의 진입점이 3개가 되어, Build 단계에서 피하려던 "사용 시기가 혼동되는 분리"를 Define 단계에서 다시 만든 셈이었다(사용자 지적). 실제로 갈려야 할 차이는 **질문 단위** 하나였다 — 의도 공백은 1개씩, 슬롯·정책은 모아서.
  - 반영(사용자 결정): 두 스킬을 삭제하고 **`feature-interview`** 하나로 통합했다. 의도 공백은 질문 1개+예상 답, 방향이 여러 갈래면 넓혔다 좁히기로 처리하며, 한 대화 안에서 두 방식을 오간다. 결과물은 **파일이 아니라 정련 요약**(원래 요청·Outcome·User·Why now·Success·Constraint·Out of scope·방향·논의 중 결정·가정·남은 질문)이다. **명시 승인되면 다시 묻지 않고 바로 frd-author로 이어진다**(사용자 결정 (a)) — `frd`를 생략해 기본값 "대화 초안"으로 넘기고, 보존은 frd-author 절차 0이 `FRD.draft.md`로 한다. FRD 정련을 미루면 그때만 interview가 `FRD.draft.md`를 남긴다. frd-author와 runner Phase 1에는 **Phase 0 의도·방향 게이트**를 두었다(의도 공백·방향 갈래 → interview 진입 → 승인 요약을 초안으로 복귀). frd-author만 불러도 필요하면 인터뷰가 먼저 돈다. 절차 7은 "슬롯·정책만 모아 묻는다"는 질문 단위 규칙으로 정리했다. 3.5.0의 `FRD.draft.md` 누적 규칙은 제거했다. 두 스킬은 push 전이라 호환성 영향이 없다.
  - 검증: `feature-interview` evals 3케이스(의도 첫 턴·방향 탐색 첫 턴·승인 후 frd-author 연결)와 frd-author evals 2케이스(승인 요약 수용·게이트 진입)를 서브에이전트로 동적 실행해 전 assertion을 충족했다. 실행 중 드러난 모호점 4건(원래 요청 원문 보존, 남은 질문을 슬롯 확인에 재포함 가능, 근거 코드 없을 때 표기, 숨은 가정 시점)을 본문에 반영했다. `validate --strict`, frontmatter, argument-hint↔usage 일치, references 존재도 확인했다. 미반영 관찰(frd-author 기존 동작 — 빈 코드베이스의 §4 패턴 탐색, `interaction-integrity.md` 부재 시 폴백, 요구·설계 확인을 한 메시지에 묶는 방식)은 이번 범위 밖으로 남긴다.

- [x] **agent-skills 2차 비교 후속 — PLAN·구현·리뷰 소규모 흡수** (2026-10-21, `devoks-sdlc` `3.5.0 → 3.6.0`)
  - 배경: 2026-10-21 재비교(Define·Plan 신규 + Build·Review 재확인). Build 7개 스킬은 트리거가 전부 "구현할 때"라 별도 스킬로 들이면 사용 시점이 겹치므로 **필요한 규칙만 기존 파일에 흡수**(사용자 판단). 리뷰는 외부도 `/review`가 단일 스킬 1패스이고 보안·성능은 그 안의 축이라 로컬 `code-review → code-security-review` 구조와 같은 모양 — 새 리뷰 스킬 없이 **diff 신호로 켜지는 조건부 체크**만 추가. 2026-10-12에 채택하지 않은 항목(`NOTICED BUT NOT TOUCHING`·doubt-driven·mutation 리뷰·디버깅 스킬)은 그대로 제외.
  - 반영: `task-pr-splitting.md` Risk-first 예외(불확실한 통합 지점을 첫 Task로). `feature-plan-author` 절차 7·runner Phase 2에 **진행 중 PLAN 보호**(미체크 Task가 남은 PLAN.md 덮어쓰기 금지 — 재계획은 제자리 수정, 그 외 확인). `code-implementer` 2단계·`task-delegation.md` 리포트에 **버전 의존 API 근거 확인**(설치 버전 + 공식 문서/타입 정의, 못 하면 `UNVERIFIED API`) — 플러그인 안에 근거 0건이던 공백. `new-ui-draft` 계획에 화면 상태 목록, 마무리에 접근성·상태 셀프체크. `design-spec.md` §4.4 계약 변경 추가형 우선·breaking 명시. `review-execution.md` 조건부 체크 4종(manifest·lockfile / 측정 없는 성능 지적 `[추정]` / 1000줄·기능+리팩토링 혼재 분할 권고 / 민감 경로 → security-review 권장). `refactoring-execution.md` Chesterton's Fence·변경 하나 검증 하나·대량 변경 도구화.
  - 미채택: 파일 수 기반 태스크 크기(로컬은 정성 `size`를 의도적으로 채택), 태스크 2~3개마다 체크포인트(done 증거 계약이 더 촘촘), TDD 선-테스트 강제(`test-quality-bar.md` §7 기각 유지), 퍼포먼스 측정 스킬(수요 확인 시 devoks-browser에서 재검토).
  - 검증: `validate --strict`.

- [x] **Define 앞단 스킬 2종 신설 — `feature-intent-interview`·`feature-idea-refine` + FRD §1 확장·§10 신설** (2026-10-21, `devoks-sdlc` `3.4.0 → 3.5.0`)
  - 배경: addyosmani/agent-skills Define 단계(`interview-me`·`idea-refine`·`spec-driven-development`) 비교 결과, `feature-frd-author`는 **방향이 정해진 초안의 정형화**(EARS·CTR·EDGE·traces)에서는 앞서지만 그 앞 단계가 비어 있었다. 슬롯을 한 번에 모아 묻는 방식은 의도 자체가 불명확할 때 맞지 않고, FRD 템플릿에 대상 사용자·측정 가능한 성공 기준·Non-goals·가정·Open Questions 자리가 없었다.
  - 반영: **기능 정의 전용**(사용자 결정 — 범용 grill-me로 devoks-core에 두지 않음) 스킬 2개. `feature-intent-interview` — 가설+확신도, 질문 1개+예상 답, want vs should-want 탐침, Outcome/User/Why now/Success/Constraint/Out of scope 6줄 정리, 명시 승인 후 기록하고 턴 종료, HITL 전용. `feature-idea-refine` — HMW → 질문 3~5개 → 코드베이스 근거 변형안 5~8개 → 방향 2~3개·가치/실현성/차별성·숨은 가정 → 1-pager(Not Doing 필수). **둘 다 FRD를 직접 쓰지 않고 `FRD.draft.md`에 `## 확정 결정 — <스킬>` 섹션으로 누적**(사용자 결정 — FRD 작성 SSOT는 frd-author 유지), `output-location.md`에 누적·덮어쓰기 금지 규칙 추가. `FRD.template.md` §1에 대상 사용자·Why now·Success·Non-goals, §10 Assumptions & Open Questions(§4~§9 번호 참조 보존 위해 맨 뒤). `feature-frd-author`·runner Phase 1을 같이 수정(확정 결정 재질문 금지, 의도 수준 공백은 슬롯 질문에 섞지 않고 interview 제안, 완료 기준). 진입 라우팅은 입력 상태(의도 불명 → interview / 방향 미정 → idea-refine / 초안 있음 → frd-author)로 세 스킬 description·`workflow-map`(1a 행)·README 양본 다이어그램·스킬 표에 반영. `devoks-sdlc-orchestration`은 FRD 저작 스킬을 재사용하지 않아(자체 규약 적용) 영향 없음을 확인.
  - 검증: 신규 2종 evals 2케이스씩 + `feature-frd-author` evals 신규 2케이스를 서브에이전트로 동적 실행 — 전 assertion 충족(frd-author 케이스 1은 단일 턴에서 요구 슬롯·§4 확인이 먼저 발동하는 것이 정상이라 기대치를 조정). 실행 중 드러난 모호점 5건(비대화형 정의, 명시 승인 표현, `out` 지정 시 이름 확인 생략, 1-pager heading 강등, 코드 근거 미확인 시 가정으로 기록)을 본문에 반영. `validate --strict`, frontmatter·argument-hint↔usage 일치, references 존재 확인.

- [x] **web-security 가이드 복원·보강 + 스택 한정 refs 복사 체계 + 보안 심층 리뷰 신뢰 경계·조건부 카테고리** (2026-10-21, `devoks-core` `2.1.0 → 2.2.0`, `devoks-sdlc` `3.3.1 → 3.4.0`)
  - 배경: 2026-07-13에 작성한 React 웹 보안 가이드(`a0c0e98`·`1f342ac`)가 `docs/react-web-security-by-claude` 브랜치에만 있고 main에 머지되지 않아, 이후 48개 커밋 동안 `refs/web-security.md`와 연동 지점 전부가 빠져 있었다(메모리에는 "적용됨"으로 남아 있어 발견이 늦었다). agent-skills `security-and-hardening` 비교 중 발견했다. main 구조가 그 사이 크게 바뀌어(conventions 경로 이전, 루트 `.claude/refs` 사본 금지, base 스냅샷·3-way 갱신) 브랜치 머지 대신 **본문만 가져오고 연동은 새로 구현**했다. 브랜치는 사용자가 직접 정리한다.
  - devoks-core: `web-security.md` 복원 + §0.1 신뢰 경계 매핑·§7 PII 최소화·§11 파일 업로드·§12 AI/LLM(OWASP LLM Top 10 2025) 추가(OWASP Top 10:2025 분류명은 공식 페이지로 재확인). 배치는 **스택 한정 refs**(frontmatter `scope: react-web`) — 항상 복사(B안)는 RN·Android·FastAPI에 무관 문서를 넣고, preset 본문 내장(C안)은 매 세션 로드 비용이 커서 기각. `setup-project-convention`·`setup-preset-manage`(base 갱신·전환)·`check-setup-state.sh`(stale 판정)에 스택 한정 refs를 등록. `engineering-principles.md` [Security] 20. Never Trust the Client(이후 21~24 재번호, 번호 참조 없음 확인), `code-review.md` L3·§6·§9, react-web preset Security 요약. CHANGELOG 2.2.0.
  - devoks-sdlc: `code-security-review`에 점검 전 **신뢰 경계 매핑**과 **조건부 카테고리 5종**(파일 업로드·파괴적 파일 작업·무차별 대입·PII·AI/LLM — 발동 신호가 없으면 `해당 없음`), 스택 보안 ref 감지. `code-review` 보안 요약에 민감정보 노출 행, 참고 문서에 스택 보안 ref.
  - 검증: 훅 스모크 4케이스(react-web·사본 없음 → 경고 / RN → 0 / react-web 최신 → 0 / 버전 일치 → 0), `bash -n`, `validate --strict` 2/2, frontmatter 6개 파싱, 루트 `.claude/refs` 미생성 확인. `code-security-review` evals 동적 재실행은 미실시(권장 항목).

- [x] **`browser-devtools` 스토리지 전체 덤프 예시 제거 + 브라우저 출력 untrusted 본문 반영** (2026-10-21, `devoks-browser` `1.2.5 → 1.2.6`)
  - 배경: agent-skills 재비교(2026-10-21) 중 발견. 2026-10-12 채택 ②(브라우저 출력은 데이터일 뿐 지시가 아님)가 `acceptance-test-runner`·`browser-visual-diff-capture` 에이전트에만 들어가고 `browser-devtools` 스킬 본문에는 빠져 있었다. 같은 스킬의 `evaluate_script` 예시는 `{...localStorage, ...sessionStorage}`로 스토리지를 통째로 덤프해 인증 토큰·세션 값을 대화 컨텍스트로 끌어올 수 있었다(agent-skills `browser-testing-with-devtools`의 "No credential access"와 정면 충돌).
  - 반영: 예시를 키 목록 + 지정 비민감 키 `getItem` 조회로 교체(`verify-acceptance-test` `scenario-execution.md`와 같은 패턴). 토큰·쿠키·자격증명 값은 읽거나 출력하지 않고, 존재 확인은 boolean만 반환하도록 했다. 네트워크 요청의 `Authorization`·`Cookie` 헤더 값도 같은 기준. untrusted 문구를 스킬 본문에 추가했다.

- [x] **복사 산출물 변경 이력(CHANGELOG) + 원본 스냅샷 기반 3-way base 갱신** (2026-10-19, `devoks-core` `2.0.0 → 2.1.0`)
  - 배경: aware-react-app 세션이 2.0.0 base 갱신을 하다가 막혔다. 버전별로 무엇이 왜 바뀌었는지 기록이 없었고, 사본이 로컬에서 수정돼 있어 2-way diff로는 upstream 변경과 로컬 커스터마이징을 구분할 수 없었다. 남은 플러그인 캐시(1.6.0~)로 기준점을 추정했지만, 구버전 캐시는 업데이트 14일 뒤 삭제되므로 재현 가능한 방법이 아니다. 실제로 그 세션은 1.1.4에서 upstream이 삭제한 `workflow.md` APK 섹션과 `(auth, brew, sensor-ingest)` 예시를 로컬 커스터마이징으로 오판했다.
  - 반영: `plugins/devoks-core/CHANGELOG.md`를 신설했다. 플러그인 내부에 두어 설치 프로젝트에서도 읽을 수 있고, 1.1.4~2.1.0을 git 이력으로 소급 작성했다(복사 산출물은 파일 › 섹션 › 사유, 거부 가능 변경 표시). `setup-project-convention`은 적용 시 원본 스냅샷을 `.claude/.devoks-base/`에 기록한다. `setup-preset-manage` base 갱신은 상태 6분류 → CHANGELOG 사유 → `git merge-file` 3-way → 파일별 반영/거부/보류(거부도 스냅샷 전진) 순서로 바꿨고, 스냅샷 없는 프로젝트용 1회 이전 절차(캐시 기반 기준 추정 + CHANGELOG 대조)를 추가했다. preset 재적용도 스냅샷으로 upstream 변경 섹션만 식별한다. 훅은 스냅샷이 있으면 스냅샷 ↔ 번들로 판정한다. maintainer 절차에 CHANGELOG 기재를 필수로 넣었다.

- [x] **`project-convention-manage` → `setup-preset-manage` 개명 + setup 산출물 4종 통합 관리** (2026-10-19, `devoks-core` `1.8.0 → 2.0.0`, `devoks-sdlc` `3.3.0 → 3.3.1`)
  - 배경: 플러그인 스킬은 업데이트를 따라가지만, setup이 플러그인 밖으로 복사한 파일은 남는다. 조사 결과 base rules/refs 외에 `~/.devoks/bin/chrome-debug.sh`와 `~/.devoks/mcp/metro-mcp.js`도 업데이트 감지가 없었다. 자동 동기화(3-way 해시)는 구조 복잡도 때문에 **기각**하고(사용자 결정, `1ac291e`의 명시적 setup 원칙 유지), **수동 갱신 + 훅 감지**로 누락을 막는다. 근거: 공식 문서상 설치/업데이트 훅이 없고 SessionStart가 유일한 시점이다.
  - 반영: 스킬을 `setup-preset-manage`로 개명했다(호출명 변경 → major). Overview에 산출물 4종 표를 두고, "~/.devoks 스크립트 갱신" 절과 "업데이트 후 일괄 점검" 작업 유형을 추가했다. `chrome-debug.sh`는 `setup-mcp` 본문 인라인에서 `assets/chrome-debug.sh` 번들 파일로 분리했고, 기본 URL을 `~/.devoks/chrome-debug.url`로 빼서 사본이 원본과 바이트 동일하게 유지되게 했다(구버전 URL 이전은 스킬 절차에 포함). 훅은 두 스크립트의 원본 대비 차이를 감지한다. devoks-rn 원본은 공식 캐시 구조상 형제 디렉토리에서 찾고(`installed_plugins.json`은 비공개 포맷이라 미사용), 저장소 직접 실행 폴백도 지원한다. maintainer 체크리스트에 "setup 산출물 등록" 항목을 추가했다.
  - 검증: 훅 스모크 5케이스(사본 없음 → 0, 구버전 런처+stale metro → 2(`sort -V`로 1.10.0 선택), 갱신 후 → 0, 저장소 폴백 stale → 1, 폴백 동일 → 0), `bash -n`, `validate --strict` 2/2, frontmatter 파싱.

- [x] **base rules/refs 갱신 경로 신설 — `project-convention-manage` "base 갱신"** (2026-10-19, `devoks-core` `1.7.0 → 1.8.0`)
  - 배경: 1.7.0에서 `agent-principles.md`를 바꾼 뒤 대상 프로젝트에서 `project-convention-manage`를 돌렸지만 반영되지 않았다. 이 스킬은 `project-convention.md`(presetHash)만 관리했고, base 7종을 복사하는 경로는 `setup-project-convention` 재실행(preset 재선택·convention diff 질문 포함)뿐이었다.
  - 반영: `project-convention-manage`에 "base 갱신" 작업 유형을 추가했다. 7종을 파일 단위 `cmp`로 비교하고, diff 요약 → 확인 → `command cp -f` → `devoksCoreVersion` 갱신 순으로 진행한다. 로컬 수정 흔적은 덮어쓰기 경고와 함께 `project-convention.md`로 옮기도록 제안한다. "점검" 요청에도 base 최신 여부를 포함한다. SessionStart 훅의 stale 안내와 `setup-project-convention` 후속 안내도 이 경로를 가리키도록 바꿨다.
  - 검증: 훅 스모크 3케이스(버전 갭+파일 차이 → 경고 1건, 파일만 맞춤 → 0, 버전 갱신 후 → 0), `bash -n`, `validate --strict`. 스모크 중 `cp -i` 별칭이 덮어쓰기를 거부하는 함정을 발견해 절차에 `command cp -f`를 명시했다.

- [x] **ponytail 비교 검토 후속 — 안전 하한·재사용 사다리·미확인/리스크 보고·리뷰 Lean·테스트 필요 판정** (2026-10-19, `devoks-core` `1.6.0 → 1.7.0`, `devoks-sdlc` `3.2.0 → 3.3.0`)
  - 배경: `DietrichGebert/ponytail` v5.3.2(YAGNI·최소 코드 페르소나 플러그인)를 검토했다. 플러그인 자체는 병행 가능하지만 SubagentStart 주입이 devoks 에이전트의 리포트 스키마·테스트 설계 계약과 충돌하고, band·코드베이스 맵은 claude-hud·codegraph와 중복되어 채택하지 않았다. 규칙 문구만 흡수했다.
  - 채택: `agent-principles.md` — YAGNI 문장에서 "error handling"을 제거하고 **Safety Floor**를 신설(ponytail 자체 벤치마크에서 맨 YAGNI 프롬프트가 안전 가드를 빠뜨림), **Reuse-First Ladder** 신설, #6에 테스트 필요 신호, #8에 미확인·리스크 1~2줄. `code-implementer` 2단계에 재사용 사다리 inline. `task-delegation.md` done 스키마에 **미확인·리스크(필수)** 필드를 추가하고, runner/executor 마무리 보고에서 수집. `task-pr-splitting.md`의 `test: required` 신호(반복·파싱·금액/보안·버그 수정·신규 스크립트)와 하한(깨지면 실패하는 테스트 1개). `code-review` 로컬 체크리스트 6항목(Lean)·가정한 부하·통번호·먼저 고칠 항목(공유 SSOT `refs/code-review.md`는 2026-07-20 결정대로 불변).
  - 미채택: `shortcut:` 주석 규약·부채 장부(#8로 대부분 커버, #15와 예외 관계 비용), band/board/webhook, 코드베이스 맵, lite/full/ultra 레벨.

- [x] **addyosmani/agent-skills 비교 분석 후속 — 정합성 수정 + 테스트 무력화 점검 + 브라우저 출력 untrusted** (2026-10-12, `devoks-sdlc` `3.1.0 → 3.2.0`, `devoks-browser` `1.2.4 → 1.2.5`)
  - 배경: 구현·리뷰·검증 3축으로 비교한 결과, 파이프라인 골격(추적성·서브에이전트 격리·증거 계약)은 하네스가 앞서고 agent-skills는 "절차 우회·기준 약화 차단 장치"가 앞섰다. 후보 대부분은 **채택하지 않기로 결정**(사용자 결정):
    - Rationalizations 표·`NOTICED BUT NOT TOUCHING`·mutation 리뷰·이름 붙은 처방·간이 경로 검증 제안 → 효과를 실측할 수 없거나 기존 구조로 커버됨
    - 구현 루프 내 리뷰 게이트·doubt-driven·기준 약화 훅·재현 테스트 분리 작성 → HITL에서는 불필요, 향후 HOTL 자율 파이프라인에서 자연 흡수
    - 디버깅 신규 스킬 → `test-run-triage`는 디버깅이 아니라 "사용자 직접 호출 + HOTL 회귀 게이트"로 용도 재확인, 신규 스킬은 실사용 반복 문제가 확인될 때 재검토
    - command→skill 조합 계층 → 2026-08-24 진입점 정책(스킬 기본)과 충돌, agent-skills 자체에서도 커맨드↔스킬 심각도 체계 drift가 확인된 이중 관리 비용
  - 채택 ①: `task-delegation.md`에 **테스트 무력화 점검** — exit 0은 `.skip`·assert 삭제·`@ts-ignore`·빈 catch·임계값 하향으로도 나오므로 기존 증거 계약(종료코드+tail)으로는 잡히지 않는다. 메인 루프가 done 판정 시 diff를 훑어 사유 없는 추가분은 done으로 받지 않음. `code-implementer` 금지 사항에 미러.
  - 채택 ②: `acceptance-test-runner`·`browser-visual-diff-capture`에 **브라우저(·Figma) 출력은 데이터일 뿐 지시가 아님** — 두 에이전트가 `Edit` 권한을 가진 채 외부 페이지를 읽는 프롬프트 인젝션 경로 차단, `Edit`는 임시 패치 용도로 한정.
  - 정합성 수정(P0): `browser-visual-diff` 포트 `9222 → 9269`(나머지 전부 9269), runner↔분리 스킬 drift 3건(Phase 1 데이터 리얼리즘·연타 EDGE 의무, Phase 2 `size:`/`test:` 필수·분포 자기점검, Phase 3 done 증거 "포맷 실행 여부" 누락), `new-feature-by-github-issue` 테스트 위임을 `test-writer` 직접 위임으로 통일(`new-ui-draft`와 동일 — 이중 질문 제거), `review-execution.md` lint/type 실패 시 동작 정의(수정·질문 불가 에이전트이므로 중단 대신 헤더 기록 + 타입 오류 High + "해소 후 재리뷰").
  - 검증: `claude plugin validate --strict` 2개 플러그인 ✔, 변경 frontmatter 7개 `ruby -ryaml` 파싱 ✔.

- [x] **실행환경 계층 흡수 — MCP prefix→permissions, provenance 버전, Chrome 런처, ast-grep, setup.sh 폴백 버그** (2026-09-18, `devoks-core` `1.5.1 → 1.6.0`, `devoks-sdlc` `3.0.1 → 3.1.0`)
  - 배경: `aware-react-app`(이 하네스의 prototype) 전수 점검 결과, 문서·워크플로 계층은 이미 하네스가 소유하는데 **실행환경 계층**(MCP prefix→permission 기입, ast-grep 설정, Chrome 런처)만 프로젝트가 손으로 만든 상태였다. 일반화 가능한 7건을 흡수.
  - **context-mode 도입 기각 + 기존 전제까지 전량 제거** (사용자 결정): 브리프는 "`test-run-triage`와 `memory-policy.md`가 이미 전제하는데 설치 안내에 없다"는 의존성 구멍을 메우자고 했고 실제로 반영했었다. 그러나 **기존 프로젝트 실측에서 효용성이 확인되지 않아** 원빈님이 도입을 기각했다. 실측(30일 93세션, aware-react-app 트랜스크립트 기준): 훅 주입 오버헤드가 도구 출력과 **별개로** 1,411KB(`context_window_protection` 265회 × 4.6KB + `context_guidance` 398회 × 0.5KB) 나갔는데, 이를 정당화할 `ctx_execute` 계열 호출은 **19회**에 불과했다. 조회 계열도 절감 기전이 아니었다 — `ctx_search` 10KB/회, `ctx_batch_execute` 18.6KB/회로 `Read` 평균 19.1KB와 비슷하거나 더 비싸다. 설치 안내만 되돌리면 "스킬이 전제하는데 하네스는 설치를 권하지 않는다"는 **역방향 불일치**가 남으므로, 전제 지점까지 함께 걷어냈다:
    - `test-run-triage` Step 1 "실행은 context-mode로" → **"실행과 출력 격리"**(출력을 파일로 리다이렉트 → `tail`로 러너 요약 형식 파악 → 해당 줄만 추출, 전체 Read 금지). 종료코드를 따로 받아 실패 종료가 스크립트를 죽이지 않게 한다. 의존성 0으로 같은 목적을 달성한다. description도 함께 수정(트리거 문구에 박혀 있었음).
    - `memory-policy.md` 계층 표에서 "context-mode 세션 메모리" 행 제거(3계층 → 2계층). 규칙 4 "승격 패턴"은 출처 계층이 사라져 성립하지 않으므로 삭제. 규칙 2는 **일반화**해 보존했다 — "회상 ≠ 진실원천(context-mode 회상은…)" → "기록 ≠ 현재 사실(메모리에 적힌 내용은 기록 당시의 사실…)". 도구와 무관하게 Claude 파일 메모리에도 그대로 적용되는 규칙이라 이름만 걷어내고 남겼다.
    - `shared/templates` 도구 라우팅의 "대용량 출력 → context-mode" 항목도 같은 파일 리다이렉트 방식으로 교체 (`test-run-triage`와 동일 지침으로 통일).
    - `docs/mcp-setup-guide.md` §8 절 전체 삭제 + 절 번호 재정렬(ast-grep 9→8, Context7 10→9, 본문 절 참조 동반 수정), 의존성 매트릭스 4행·풀 구성 블록·README 양본 카탈로그에서 제거.
  - **permissions 베이스라인 산출 (`setup-mcp` Step 8 신설)** — setup-mcp가 "어떤 방식으로 설치했는지=prefix가 뭔지"를 아는 유일한 지점이라 그 자리에서 `.claude/settings.local.json`의 `permissions.allow`를 산출한다. **자동 기입 금지**(Step 2 패턴: 제시→확인→적용, 항목별 선택). stale prefix 제거 후보를 추가 항목과 **분리해** 제시 — 실측 사고 흔적 2건(`mcp__playwright__*`, `mcp__plugin_chrome-devtools-mcp_chrome-devtools__*`)이 근거.
  - **provenance `devoksCoreVersion` + 훅 stale 판정** — `presetHash`가 커버하지 않는 base rules/refs 7종의 stale 여부 판정 기준. **브리프의 "버전 문자열 1개 비교" 설계는 채택하지 않았다**: `patch` bump 8건 중 4건이 실제로 base를 변경(1.4.1→`code-review.md`, 1.2.1→`git-convention.md`, 1.1.4→4건)했고 나머지 4건은 무변경이라, 버전 단독 비교는 `devoks-mcp-servers`(1.5.0, 실측 drift 0/7)를 오탐하고 minor-only 비교는 위 4건을 놓친다. → **버전 갭이 있을 때만 `cmp`로 확증**하는 하이브리드. 침묵 경로는 순수 파라미터 확장으로 프로세스 0개, 확증은 갭이 있을 때만 실행. 구버전 provenance는 `source` 경로의 `/devoks-core/<version>/`에서 버전을 회수하므로 재설정 불필요.
  - **Chrome `:9269` 런처 승격** — 문서 안내 → `~/.devoks/bin/chrome-debug.sh` 생성(Step 5의 `metro-mcp.js`→`~/.devoks/mcp/` 패턴과 동일). 포트·`--user-data-dir` 고정, 시작 URL만 인자, 이미 떠 있으면 재실행 안 함(중복 attach 방지). macOS/Linux 바이너리 탐색 포함.
  - **ast-grep — opt-in 스캐폴드로 결정** (사용자 결정): 기본은 설정 없는 애드혹(`run -p --lang`), 영속 규칙은 **지금 넣을 규칙이 있을 때만** `sgconfig.yml` 생성. 하네스는 스택별 deprecated API 시드 규칙을 소유하지 않는다(버전 주장 노후화). 5개 preset에 언어 id·예시 패턴만 달리해 동일 절 추가. **실측 함정 표**: `키: $V`는 오브젝트 속성이 아니라 `labeled_statement`로 파싱돼 **조용히 0건**(→ `--debug-query=pattern`, `context`+`selector: pair`) / 규칙 YAML 1개만 깨져도 scan 전체 중단(→ `context`는 큰따옴표) / `--lang` 미지정 시 `.md` 오탐 / `scan`은 `severity: error`일 때만 exit 1. **`ast-grep test`를 스캐폴드 생존 판정으로 채택** — 소스 0개에서도 규칙 정확성을 판정(올바른 규칙 PASS, 틀린 규칙 fail)하므로, `scan`이 0건일 때 "규칙이 죽었는지 코드가 깨끗한지"를 가른다. `testConfigs`는 `ruleDirs`와 달리 `- testDir:` 구조체이고, `ast-grep new project -y`는 세 경로 전부 **절대경로**로 박으므로 상대경로 교정이 필수.
  - **CodeGraph/Serena 비용 기준** — 템플릿의 "도구→용도" 매핑에 "언제 순이득인가"를 추가. CodeGraph는 다중 파일·다중 홉일 때만(콜당 13~25KB), Serena는 심볼 편집 전용으로 좁힘(순수 조회는 내장 대비 이득 없고 세션당 활성화 고정비 추가). 기존 "과잉 라우팅 금지" 원칙 유지.
  - **`setup.sh` 설치 중단 버그** — `plugins/devoks-sdlc/commands/*.md` glob이 매치되지 않아(devoks-sdlc는 `skills/`+`agents/`만 보유) `set -e` 하에서 `cp` 실패로 폴백 설치가 중간에 죽었다(실행 재현 확인). 디렉토리 존재를 `compgen -G`로 먼저 확인하는 헬퍼(`copy_flat`/`copy_skill_dirs`)로 교체하고, 플러그인 목록을 단일 `ALL_PLUGINS` 배열로 통합. **함께 수정**: `agents/`를 아예 복사하지 않아 devoks-sdlc 6개 + devoks-browser 1개 에이전트가 폴백 경로에서 누락되던 문제, `devoks-rn` 스킬 미복사, 내용 없는 "추가 MCP 안내" 빈 배너(공백만 제거해 개행이 남던 가드). **`devoks-sdlc-orchestration`은 폴백 대상에서 제외**(리뷰에서 교정) — 헬퍼가 `commands/`·`agents/`·`skills/`만 복사해 플러그인 루트의 `references/`가 따라오지 않는데 `orchestration-run`은 그 자리의 `orchestration-policy.md`(deny-list·격리 allowlist·한도)를 실행 전제로 읽고, 폴백에는 `${CLAUDE_PLUGIN_ROOT}`가 없어 경로도 해석되지 않는다. 비-HITL 파이프라인을 안전 가드 없이 반쪽 설치하느니 플러그인 설치 경로로만 쓴다.
  - **브리프 범위 밖이나 함께 수정한 것**:
    - `refs_ready()`가 `interaction-integrity.md`를 체크하지 않아 base 7종 중 1개 누락을 통과시켰다(crema-service가 실제로 이 파일 MISSING인데 침묵). 새 stale 판정이 같은 파일을 보는데 `refs_ready()`만 안 보면 비일관이라 함께 보강.
    - **greenfield 오탐** — 하네스를 먼저 셋업하고 프로젝트를 나중에 만드는 순서에서는 설치 시점 소스가 0개인데, 훅이 serena/codegraph 인덱싱을 안내해 코드가 생길 때까지 매 세션 반복됐다("정상이면 침묵" 속성 위반). `has_source_files()` 가드 추가(`find -print -quit` 1회, 두 경고가 공유) — 소스가 생기면 다음 세션에 자동 복귀(자가치유). harness 저장소 자신(Markdown+Bash)은 `.sh` 포함으로 기존 동작 유지.
    - 템플릿에 "언제 채우나" 안내 — greenfield에서 Tech Stack/Architecture/Directory/Commands는 채울 사실이 아직 없으므로 추측 금지, 스택 확정·첫 구조 커밋 후 갱신.
    - 양 README의 `devoks-rn` 서술이 `~/.claude.json`에 `--wsEndpoint` **수동 등록**이라고 남아 있었으나, 실제로는 `setup-mcp` Step 5가 `metro-mcp.js`를 복사·등록하고 Metro URL을 자동 조회한다(재시작 수동 갱신 불필요) — 낡은 서술 정정.
  - **제외(브리프 명시)**: lefthook pre-commit 부트스트랩(하네스가 실행환경 아티팩트를 소유하게 되는 경계 문제 — 순서상 먼저 결정할 사안. greenfield엔 `package.json`이 없어 설치 시점 불가라는 점도 확인), Figma PAT(YAGNI — 댓글 QA 스킬 없음), gws/UDP 에뮬레이터/excalidraw/AGENTS.md(일반화 불가), `project-harness-manage` 스킬 신설(기각 — presence·version은 훅, diff·판단은 스킬이라는 기존 분업에서 스킬 칸이 빔), `aware-react-app` 정상화(첫 설치 이후 점진 개선은 정상 동작).
  - **`setup.sh`의 `~/.claude.json` 기입 — 스키마 정정 + 쉘 프롬프트 승인** (사용자 결정): `merge_mcp_required`/`print_mcp_optional`이 `mcpServers.required`/`optional`/`interactive` **중첩** 스키마를 읽는데 실제 `plugin.json`은 플랫 맵이라(중첩 키는 `Invalid input`으로 검증 실패 — 이 저장소 convention의 Pitfall 항목) **두 함수가 항상 no-op**이었고 `~/.claude.json`이 생성되지 않았다(샌드박스 실행으로 확인). 스키마 정정이 본 수정. 함수를 제거하지 않고 `collect_mcp_candidates`(계산만) + `apply_mcp_merge`(승인 후 기입)로 분리해, 작업 2의 "제시 → 승인 → 실행" 원칙을 폴백 경로에서도 지킨다 — 따라서 "자동 기입 금지"와 충돌하지 않는다.
    - 추가 후보를 **전 플러그인 합쳐 1회** 제시(플러그인별 반복 프롬프트 없음) → `y/N`, **기본 N**.
    - `[[ -t 0 ]]`로 tty를 확인해 비대화형(CI·파이프)에서는 기입을 건너뛰고 안내만 출력 — **무응답을 승인으로 해석하지 않는다.**
    - 병합만 하고 덮어쓰지 않으며, 임시파일 + `os.replace`로 원자적으로 쓴다. 기존 파일이 파싱 불가면 중단하고 원본을 보존한다.
    - 프로젝트 `.claude/settings.json` 권한 병합은 **항목 형태로 승인 여부를 가른다.** 무승인 병합은 "그 플러그인을 설치한 것 자체가 그 플러그인 도구에 대한 의사표시"라는 논리에 기대는데, 그 논리는 항목이 특정 MCP 서버 네임스페이스로 한정될 때만 성립한다. 현재 선언된 2건(`mcp__chrome-devtools-attach__*`, `mcp__metro-devtools__*`)이 narrow한 건 **플러그인 작성자의 자제일 뿐 구조가 강제하는 게 아니어서**, 나중에 어떤 플러그인이 `Bash(*)`를 선언하면 같은 무승인 경로로 통과한다 — 사후 출력은 이미 벌어진 일을 알리는 것뿐이다. 그래서 정규식 `^mcp__[A-Za-z0-9._-]+(__|$)`로 판정한다 — `mcp__` + 구체적 서버명 + (`__` 가 이어지거나 거기서 끝남):
      - 매치 → 무승인 병합 + 사후 출력 (현행 2건 해당, **동작 변화 없음**)
      - 비매치(`Bash(...)`/`Read(...)`/`Edit(...)`, 그리고 **서버명 없는 `mcp__*`·`mcp__**`·`mcp__<server>*`**) → `~/.claude.json`과 동일한 승인 게이트. 서버명 없는 와일드카드를 게이트에 넣은 건 그게 다른 서버의 도구까지 열기 때문이다.
      - `$` 종료를 허용하는 이유: `mcp__pencil`처럼 **서버명만 쓰는 표기**가 "그 서버 전체 허용"으로 실사용된다(원빈님 `~/.claude/settings.json`에 실재). 스코프가 `mcp__pencil__*`와 같은데 넓은 쪽만 통과시키고 좁아 보이는 쪽을 막으면 비일관이다 — `__` 종료만 강제했던 최초 구현의 오게이트를 교정했다.
  - **반영**: `plugins/devoks-core/hooks/check-setup-state.sh`, `plugins/devoks-core/commands/setup-mcp.md`(Step 6 런처, Step 7 ast-grep, Step 8 permissions 신설 → 결과보고 Step 9, Step 4에 serena 참조추적 전제 추가 — JS/TS 프로젝트는 `jsconfig.json`/`tsconfig.json`이 없으면 language server가 파일별 inferred project로 떨어져 `find_referencing_symbols`가 **에러 없이 빈 결과**를 돌려준다. 2026-09-18 실측: 추가 전 0건 → 추가 후 37개 파일로 grep 결과와 일치), `plugins/devoks-core/commands/setup-project-convention.md`(Step 6), `plugins/devoks-core/conventions/*/project-convention.md`(5개), `plugins/devoks-core/conventions/README.md`, `plugin.json`, `setup.sh`, `shared/templates/CLAUDE.md.project.template`, `README.md`, `docs/README.ko.md`, `docs/mcp-setup-guide.md`(매트릭스·§3-3·context-mode 절 삭제 후 재정렬 → ast-grep §8·Context7 §9, 풀 구성), `.claude/rules/project-convention.md`(base 7종 정정), `plugins/devoks-core/rules/memory-policy.md`·`plugins/devoks-sdlc/skills/test-run-triage/SKILL.md`(context-mode 전제 제거, 후자는 `metadata.version` `1.1.1 → 1.2.0`), `docs/plugin-management.md`(§12 표 셀), `plugins/devoks-sdlc/agents/code-security-reviewer.md`·`plugins/devoks-sdlc/skills/code-security-review/references/security-scan-execution.md`·`plugins/devoks-sdlc/skills/verify-data-flow/references/collection-by-environment.md`(`ctx_*` 도구 이름으로만 참조해 1차 검색에서 누락됐던 3곳 — 특히 `code-security-reviewer`는 frontmatter `tools:`에 MCP가 없어 그 지시가 **애초에 차단된 죽은 코드**였다), `.claude/skills/devoks-plugin-maintenance/references/workflow-checklist.md`(§3에 "에이전트 `tools:` 화이트리스트 대조" 신설 — 1차 사고(2026-07-29 `acceptance-test-runner`) 후 재발 방지를 "reference와 frontmatter 대조"로만 적어둬서 **본문에 직접 박힌 경우**가 빠져나갔다. 점검 대상을 references + 에이전트 본문 양쪽으로 확대하고 §6 최종 확인에 체크박스 추가).
  - **비대상**: `.claude-plugin/marketplace.json`(플러그인 버전을 핀하지 않고 소스 경로·description만 참조 — description 불변), 다른 4개 플러그인 `plugin.json`(번들 내용 불변 — `devoks-sdlc`는 `test-run-triage` 변경으로 bump 대상).
  - **검증**: `claude plugin validate --strict` 6개 플러그인 전량 PASS. `bash -n` (`setup.sh`, 훅, 문서에 박은 런처 스크립트 추출). 훅 실측 — `devoks-mcp-servers`(1.5.0, drift 0/7) 변경 전 대비 **추가 출력 0줄**, `crema-service`(1.2.0, drift 5/7) 변경 전 **완전 침묵 → 버전 경고 + setup 안내**(`refs_ready()` 보강으로 MISSING인 `interaction-integrity.md`까지 잡히므로 두 블록이 함께 뜨는 게 정확한 동작 — 브리프의 "1줄" 기대치는 이 누락을 모르고 쓴 것), 빈 디렉토리 → serena/codegraph 침묵 후 소스 1개 추가 시 복귀, harness 저장소 자신 회귀 없음. `setup.sh` — `HOME`·`TARGET_DIR` 격리 실행으로 exit 0 + commands 5·agents 7·skills 21·refs 5 복사 확인(orchestration 제외 후 재실행). MCP 기입 6경로 전량 검증(python `pty`로 실제 tty 구동): 비대화형 → 미기입 / tty+N → 미기입 / tty+y → 병합 기입(`_comment` 제거 확인) / 재실행 → "추가할 서버 없음"(멱등) / 기존 최상위 키·기존 서버 보존 / 파싱 불가 파일 → 중단·원본 보존·임시파일 잔재 0. 권한 형태 가드는 분류 규칙 12케이스 단위검증 + 스크래치 저장소 복사본에 `Bash(*)`/`Read(/**)`/`mcp__*`를 주입해 4경로 확인(현행 2건 동작 변화 없음 / 비대화형 → 범용만 건너뜀 / tty+N → 미기입 / tty+y → 기입). 실제 `plugin.json`은 미변경. ast-grep — 5개 preset 예시 패턴 각 1건 매치, `severity: error`→exit 1, 소스 0개에서 `test` PASS/fail 판별. frontmatter YAML 파싱(`ruby -ryaml`) 2개 커맨드 OK.

- [x] **컨벤션 preset 확장 — `python-fastapi` 신설** (2026-09-15, `devoks-core` `1.4.1 → 1.5.0`)
  - 배경: 사용자가 컨벤션 preset 확장 작업 중 Python/FastAPI(Starlette+Pydantic) preset을 추천·구성해 달라고 요청. 기존 4개 preset(`react-web`/`react-native`/`android`/`ios`)은 전부 프론트엔드·모바일 UI 스택이라, 백엔드 preset을 추가하며 공통 골격("플랫폼·언어·UI·테스트·보안·프로젝트 결정")의 "UI" 자리를 백엔드 스택에 맞게 어떻게 치환할지가 관건이었다.
  - **스택 확정(논의 후 결정, 근거)**: 패키지 매니저 `uv`(pyproject.toml+lock, FastAPI 커뮤니티에서 빠르게 표준화 중), ORM `SQLAlchemy 2.0(async)+Alembic`(Pydantic 스키마와 DB 모델을 분리해 보여주기 좋음 — `SQLModel`은 모델 중복은 적으나 복잡 쿼리 생태계 성숙도가 낮아 기각), 디렉토리 레이아웃 `Domain/module-first`(`app/<domain>/{router,schemas,models,service,dependencies}.py` — 커뮤니티에서 널리 인용되는 "fastapi-best-practices" 컨벤션과 일치하고, `android` preset의 feature-first 패키지 구조와도 결이 맞음. `react-web`의 layer-first와는 다른 결이나 스택별로 이미 갈려 있던 기존 상태를 그대로 반영), 타입체크 `mypy`(Pydantic mypy plugin 생태계 성숙도 우선, `pyright`는 기각).
  - **기존 골격과의 매핑**: "UI and Styling" 자리에 "Data & Platform Integration"(DB/설정/백그라운드 작업)을 배치, "Component Pattern" 자리에 Schema/Model/DI/Validation을 담은 "Design Pattern"으로 통합(Android preset과 동일 구조). Comment Rules 3종(기본 주석/Rationale/Provider Header)·Pitfalls·Project Decisions 골격은 그대로 유지.
  - **`interaction-integrity.md` 인용**: 단발 API(결제·주문 생성 등)의 중복 실행 방지는 서버 계약(Idempotency-Key)이 핵심이라 Android와 동일하게 Pitfalls 표 1행으로 결함 ID(C4)만 인용(메커니즘 설명 복사 금지 규칙 준수).
  - **반영**: `plugins/devoks-core/conventions/python-fastapi/project-convention.md`(신설), `plugins/devoks-core/conventions/README.md`(Presets 목록에 추가, 공통 골격 문구를 "UI" 고정 표현에서 "핵심 계층(UI 또는 API/데이터 등)"으로 일반화), `plugins/devoks-core/commands/setup-project-convention.md`(Step 1 감지 시그널·Step 2 추천 목록에 Python FastAPI 추가), `plugin.json` 버전.
  - **비대상**: `README.md`/`docs/README.ko.md`(preset 이름을 나열하지 않고 `plugins/devoks-core/conventions/*` 패턴으로만 서술 — 변경 불필요), `docs/plugin-management.md`(preset을 아예 참조하지 않음), `.claude-plugin/marketplace.json`(플러그인 버전을 핀하지 않고 소스 경로만 참조).
  - **검증**: `claude plugin validate ./plugins/devoks-core --strict` ✔.

- [x] **`devoks-plugin-maintenance` 축1 방법론에 `claude plugin eval` 온디맨드 옵션 추가** (2026-09-14, 로컬 skill `metadata.version` `0.3.0 → 0.3.1`)
  - 배경: 사용자가 `code.claude.com/docs/ko/plugin-evals` 문서를 보고 도입 필요성·ROI 검토를 요청. 조사 결과 2026-08-21 폐기 ②(「evals 하니스 확대」)의 근거 ①("`claude plugin eval`이 early-access 게이트로 실행 불가")이 무효화된 사실을 발견 — 2026-09-11 GA(v2.1.269+), 이 세션에서 v2.1.270으로 `--help`/`init --bare` 정상 동작 실측 확인.
  - **폐기 근거 재검토 — 부분 갱신, 전면 재개 아님**: 근거 ①(게이트)만 무효화됐다. 근거 ②(포맷이 `evals/evals.json`과 완전 무관 — 실측: `prompt.md`+`graders/*.md` 구조, 자동 변환 불가)와 근거 ③(커버리지 확대는 YAGNI)은 여전히 유효하다고 판단해 "모든 플러그인에 상시 evals 스위트 저작"으로는 재개하지 않는다.
  - **채택한 좁은 용도**: `claude plugin eval <plugin 경로>`의 target 해석이 "installed and skills-dir plugins both resolve"라, `enabledPlugins` 활성화 여부와 무관하게 `plugins/<plugin>` 소스 경로를 직접 가리켜 독립 child 세션에서 검증할 수 있다. 이 도구는 발동 여부(`tool_used` grader) 확인에 그치지 않는다 — 기본 동작(`--ablation with-without`)이 플러그인 있음/없음 두 arm을 비교해 **효용성(Δ)을 자동 측정**하고, `llm`/`regex`/`baseline` grader로 **출력 품질**까지 판정한다. 이는 2026-09-02 항목("6축→8축 확장")에서 *"효용성을 축1에서 분리한 별도 축 후보 — 자동화된 판정 방법이 없어 보류"*로 기록해둔 공백을 부분적으로 메운다(사용자 지적으로 이 세션 내에서 1차 초안의 "발동 여부"로 좁힌 서술을 정정). 축 1이 지금까지 써온 "서브에이전트에 프롬프트를 그대로 전달해 roleplay로 대조"하는 방법보다 강한 증거이므로, 그 방법을 대체하지 않고 **발동·효용성·출력품질까지 의심스러울 때 단일 플러그인 대상으로 즉석 실행하는 선택적 심화 옵션**으로만 추가했다(필수 축 신설은 아님). 케이스는 상시 저작·커밋 대상이 아니며 1회성으로 만들고 지워도 된다.
  - **명시적으로 하지 않은 것**: 여러 플러그인을 한 번에 스캔하는 배치 실행은 도입하지 않는다 — target이 단수(플러그인 1개)만 받고, 전체 스윕은 실행마다 실비용이 플러그인 수만큼 선형으로 늘어 "필요할 때 하나만" 원칙과 맞지 않는다(사용자 확인).
  - **반영**: `.claude/skills/devoks-plugin-maintenance/references/workflow-checklist.md`(§"동적 검증(축 1·6) 실행 방법"에 "보조 옵션" 절 신설), `.claude/skills/devoks-plugin-maintenance/SKILL.md`(Step 4 축1 설명에 참고 문장 추가, `metadata.version`).
  - **검증**: 두 파일 모두 이 저장소 전용 로컬 skill이라 `claude plugin validate`/`enabledPlugins` 제약 대상이 아님. frontmatter YAML 파싱(`ruby -ryaml`) 확인.

- [x] **`devoks-plugin-maintenance` 스킬 품질 체크리스트 6축 → 8축 확장** (2026-09-02, 로컬 skill `metadata.version` `0.2.0 → 0.3.0`)
  - 배경: 사용자가 "6축 외에 빠진 게 없는지, 특히 효용성·중복 관점에서 찾아보자"고 요청. `workflow-checklist.md §7`을 다시 훑은 결과 두 종류의 문제를 발견.
  - **발견 1 (표기 결함, 재논의 없이 정정)**: `argument-hint 정합성` 절(§7 하위, "항상 필수·정적"로 명시)이 이미 존재하는데 "6축" 표(§7 상단)에 집계되지 않았다 — Step 8 리포트에서 "6축 다 확인" 체크가 이 항목 누락을 가려줄 수 있는 구조였다. **축 8로 표에 편입.**
  - **발견 2 (신규 축 채택)**: "인접 스킬 경계 명확성(중복 방지)"이 6축 어디에도 없었다. 근거 — 이 저장소는 스킬을 만든 **뒤에** 경계를 다시 그은 이력이 실제로 여러 번 있다(`code-review`↔`code-security-review` 2026-07-20 보안 에스컬레이션+상호참조, `verify-acceptance-test`↔`verify-data-flow`, `browser-visual-diff`↔`verify-data-flow` 중복 구현 금지 명시). 전부 사후 재작업이었고 사전 체크리스트가 있었다면 줄일 수 있었던 패턴. **축 7로 신설**(트리거 문구 grep 겹침 확인 → 범위 섹션의 양방향 라우팅 확인 → 갭이면 보고).
  - **검토했으나 채택하지 않은 후보**: "효용성"을 축 1에서 분리한 별도 축(2026-07-20에 이미 축1 흡수로 결정된 사안 — 재확인 결과 축1의 실제 메커니즘(evals `expected_output` 대조)은 "description이 사실을 기술하는가"만 검증하고 "존재할 가치가 있는가(ROI/YAGNI)"는 검증 못 해 흡수가 이름뿐이라는 지적은 타당했으나, 자동화된 판정 방법이 없어 이번엔 보류), Step 1의 사전 중복 검색 게이트, eval assertion의 판별력(discriminating power, 공식 `skill-creator` 플러그인의 `grader` 에이전트 설계 참고) 검증 — 셋 다 정성적 판단 의존도가 높아 정적/동적 검증으로 조작화하기 어렵고, 축을 늘릴수록 매 스킬 변경마다 체크 비용이 커지는 트레이드오프가 있어 사용자가 직접 보류 결정.
  - **반영**: `.claude/skills/devoks-plugin-maintenance/references/workflow-checklist.md`(§7 표에 축 7·8 추가, "인접 스킬 경계 검사" 절 신설, §6 완료 전 최종 확인 문구 갱신), `.claude/skills/devoks-plugin-maintenance/SKILL.md`(Step 4 8축 목록·Step 8 리포트 템플릿·`metadata.version`), `docs/plugin-management.md`(로컬 skill 설명 8축 갱신), `.claude/skills/devoks-plugin-maintenance/evals/evals.json`(id 6 expected_output 8축 갱신).
  - **의도적으로 갱신하지 않음**: `docs/roadmap.md`의 과거 "6축" 서술(2026-07-20/08-07 등 날짜 있는 완료 이력)은 그 시점엔 정확했던 기록이므로 그대로 둔다 — 히스토리를 현재 기준으로 소급 수정하지 않는다는 이 저장소의 기존 원칙을 따름.
  - **검증**: `.claude/skills/devoks-plugin-maintenance/evals/evals.json` JSON 유효성 ✔, `.claude/skills/devoks-plugin-maintenance/SKILL.md` frontmatter YAML 파싱 ✔. 이 스킬은 배포되는 플러그인이 아니라 로컬 maintainers 전용이라 `claude plugin validate`/`enabledPlugins` 제약 대상이 아님 — 동적 검증(축1)은 다음 실제 유지보수 요청 때 자연 발생적으로 스모크됨.

- [x] **`devoks-sdlc` 커맨드·스킬 통합 2차 — `code-analyze-module`·`code-refactoring`·`new-feature-by-github-issue`** (2026-09-02, `devoks-sdlc` `2.1.0 → 3.0.0`)
  - 1차(2026-08-24)에서 남겨둔 마지막 커맨드 3개를 전부 스킬로 이전 — **`devoks-sdlc`의 `commands/` 디렉터리가 완전히 사라졌다**(커맨드 0개, 진입점 전부 스킬).
  - **`code-analyze-module`**: 대량 파일 읽기·거대 리포트 작성의 컨텍스트 격리 이득이 커 신규 `code-analyzer` 에이전트(`model: sonnet`, researcher archetype)로 위임하는 구조로 전환. 거대 인라인 템플릿(Mermaid 규칙·DoD·산출 마크다운 템플릿·체크리스트)은 `skills/code-analyze-module/references/analysis-execution.md`로 분리. `docs/plugin-management.md` §12의 "researcher → 에이전트화는 향후 후보" 매핑을 실제 에이전트 매핑으로 갱신.
  - **`code-refactoring`**: 계획→승인→실행 상호작용이 절차 본질이라(기존 `feature-frd-author` 등과 동일 근거) 에이전트로 위임하지 않고 **메인 루프 유지** — 스킬 전환 + `references/refactoring-execution.md` 분리만 수행. 기존 검증 체인 연계(`test-run-triage`/`test-author`)는 그대로 보존.
  - **`new-feature-by-github-issue`**: **단순 전환**(`new-ui-draft`/`new-smoke-test-draft`와 동급의 형제 스킬로, `feature-plan-executor`/`code-implementer` 엔진과는 병합하지 않음)으로 확정. 이슈 파싱·갭 분석 알고리즘은 `references/issue-parsing-and-gap-analysis.md`로 분리.
  - **부수적으로 발견·정정한 사실**: 로드맵과 `workflow-checklist.md` §4가 이 커맨드를 "조건 1(이슈 생성) 때문에 커맨드 유지(잠정)"로 서술해왔으나, 실제 커맨드 본문(Step 4)은 "이슈는 이미 SSOT로 주어짐 — 이슈 생성·연결 확인 단계는 스킵한다"고 명시하고 `git commit`/`push`도 하지 않는다 — 즉 저장소 밖 write 부작용이 애초에 없었다(이슈를 읽기만 하고 생성하지 않음). 이 낡은 근거 문구를 정정했다.
  - **이름 정정(사용자 피드백)**: 위 정정 직후 사용자가 "오인이 스킬명 자체에서 온다"고 지적 — `new-feature-github-issue`가 "새 GitHub 이슈를 만든다"로 읽혀 위 오해와 같은 뿌리다. `new-feature-by-github-issue`로 리네임(디렉터리 이동 + 참조 8개 파일 문자열 치환). 이미 이슈를 "by"(수단)로 구현한다는 의미가 분명해짐. 커밋 전 상태에서 진행해 별도 버전 bump 없이 이번 `3.0.0`에 흡수.
  - **major bump 근거**: 슬래시 커맨드 3개가 사라지는 파괴적 변경(1차와 동일 근거, deprecation shim 없음).
  - **신규 산출물**: agent 1개(`code-analyzer`), skill 3개(`code-analyze-module`·`code-refactoring`·`new-feature-by-github-issue`, 각 `references/` 1개 + `evals/evals.json` 1개), `feature-workflow-runner/references/branch-issue-precheck.md` 문구 정정("해당 커맨드는" → "해당 스킬은", step 번호 갱신).
  - **반영**: `workflow-map/SKILL.md`(표 B "(legacy)" 라벨 제거, "커맨드로 남아 있는 것" 문단 정정, `version` `1.1.0 → 1.1.1`), `README.md`/`docs/README.ko.md`(스킬·에이전트 표 갱신, devoks-sdlc 커맨드 섹션 제거), `docs/plugin-management.md` §12, `.claude/skills/devoks-plugin-maintenance/references/workflow-checklist.md` §4 판정표·devoks-sdlc agent-internal 경계, `plugin.json` 버전.
  - **검증**: `claude plugin validate ./plugins/devoks-sdlc --strict` ✔ / 신규 skill 3개 frontmatter YAML 파싱(`ruby -ryaml`) ✔ / `references/` 참조 경로 실존·플러그인 루트 밖 상대경로(`../..`) 0건 ✔ / evals.json 3개 JSON 유효성 ✔. **축 1(동적 트리거 실행)은 1차와 동일한 구조적 제약**으로 이 세션에서 실행 불가 — push 이후 별도 세션 스모크로 이월(작성해 둔 `evals/evals.json` 각 2개 케이스를 그대로 입력으로 사용).

- [x] `**devoks-sdlc` 커맨드·스킬 통합 1차 + 진입점 정책 확정** (2026-08-24, `devoks-sdlc` `1.17.1 → 2.0.0`)
  - **확정된 진입점 정책(SSOT는 `.claude/skills/devoks-plugin-maintenance/references/workflow-checklist.md` §4)**: 진입점은 **스킬을 기본**으로 하고, 커맨드는 ① 저장소 밖으로 나가는 write 부작용이 있거나 ② 승인 게이트가 절차의 본질일 때만 남긴다. 이 정의는 2026-08-21에 확정된 `devoks-git` 커맨드-only 정책의 근거를 판정축으로 뒤집어 쓴 것이라 **기존 상태와 충돌하지 않는다**(로드맵이 요구한 "정책 한 번 확정"을 이 형태로 종결).
  - **정책을 뒷받침한 조사 사실**: (1) 이 저장소 커맨드 8개 중 `argument-hint`/`allowed-tools`/`disable-model-invocation`을 쓰는 것이 **0개** — 커맨드가 스킬 대비 갖는 고유 기능이 전혀 없었다. (2) 이미 11개 스킬이 `## 호출 방법` + `$ARGUMENTS`로 슬래시 진입을 담당하고, `verify-acceptance-test`·`browser-visual-diff`는 **스킬(Phase 0 합의) → 에이전트(실행) → `references/`(엔진 SSOT)** 구조로 커맨드 없이 완결돼 있었다.
  - **부수적으로 실제 결함 1건 수정**: `code-reviewer`/`code-security-reviewer`/`test-writer` 에이전트의 `description`이 자연어 트리거를 직접 물고 있어서, "코드리뷰 해줘" 같은 요청이 **커맨드의 Phase 0(범위 확정)을 건너뛰고** 에이전트로 직행할 수 있었다(에이전트는 사용자 질문이 금지돼 범위가 모호해도 받은 대로 진행). 트리거 문구를 진입 스킬 `description`으로 이관하면서 이 우회가 막혔다.
  - **구조 전환** — 계층 수는 3단 그대로이나 역할이 바뀌었다: `command`(진입+Phase 0) → `agent`(Skill 도구 껍데기) → `skill`(agent-internal 엔진)  ⇒  `skill`(진입+Phase 0+위임+pass-through+후속조치) → `agent`(엔진 실행 주체, `Skill` 도구 제거) → `skill/references/*.md`(엔진 SSOT). 엔진을 `references/`로 내린 이유는 진입 SKILL.md가 **자연어 트리거마다 메인 루프에 로드**되므로 대용량 리포트 템플릿을 본문에 두면 에이전트 격리 이득이 상쇄되기 때문이다.
  - **이전 완료(커맨드 → 스킬)**: `code-review-general` + `code-review-diff-branch` → `**code-review` 하나로 통합**(`mode=general|diff-branch` 인자 + Phase 0 추론·1줄 확인 — 인자로 확정되면 되묻지 않음), `code-security-review`, `test-author`. 신규 `references/` 5개(`review-execution.md`·`report-template.md`·`security-scan-execution.md`·`report-template.md`·`test-authoring-execution.md`)와 신규 `evals/evals.json` 3개 작성.
  - **폐기**: `new-feature-draft`(미사용). 연쇄 정리 — `branch-issue-precheck.md`의 공유 대상 목록·`full` 모드 행, `new-feature-github-issue.md` Overview의 참조 문장(자기완결형으로 재작성), `workflow-map` 표 B·"진입점이 둘이다" 문단, maintenance 체크리스트 §8 적용 스킬 목록.
  - `**commands/` 8개 → 3개**(`code-analyze-module`·`code-refactoring`·`new-feature-github-issue`). 스킬 14개·에이전트 5개는 개수 불변(역할만 전환).
  - `**major` bump 근거**: 슬래시 진입점 5개가 사라지는 파괴적 변경. deprecation shim은 두지 않기로 결정(내부 팀 마켓플레이스 + 재설치 흐름이 명시돼 있음).
  - `**devoks-sdlc-orchestration`은 무영향** — 에이전트 **이름·입력 계약이 불변**이고, `docs/orchestration-design.md`가 이미 "`직접 호출 금지` 마킹은 사용자용 소프트 가드일 뿐 스킬/오케스트레이터 위임은 허용"을 명시한다. 대신 각 에이전트의 입력 파라미터 표를 자기완결 상태로 유지하는 것이 제약으로 남는다(체크리스트에 기록).
  - **미완 잔여** → 2차 항목 2개(`code-analyze-module`/`code-refactoring` 고도화 후 이전, `new-feature-by-github-issue` 흡수)는 2026-09-02에 완료(아래 완료 섹션 최신 항목 참고).
  - **검증**: `claude plugin validate --strict` ✔ / 구 이름 잔존 0건 / 스킬 품질 정적 축(2 references 실존·3 evals 보유·5 경로 안전성·6 토큰효율성 105~112줄) ✔. **축 1(동적 트리거 실행)은 이 저장소에서 구조적으로 불가** — `.claude/settings.json`이 `enabledPlugins: {}`라 어떤 플러그인도 활성화되지 않고, 로컬 소스 수정은 push + `/plugin marketplace update` + 재설치 전까지 실행 세션에 반영되지 않는다. **push 이후 별도 세션 스모크로 이월**(작성해 둔 `evals/evals.json` 8개 케이스를 그대로 입력으로 사용).

- [x] **4개 항목 폐기 — 「카탈로그 자동 생성」·「evals 하니스 확대」·「`git-commit-msg` 스킬+haiku 위임 전환」·「`git-create-issue`/`git-pull-request` 스킬 전환」** (2026-08-21, `plugins/` 미변경 — 저장소 루트 문서만)
  - ①~③은 착수 전 사실 조사를 먼저 수행했고, 그 결과 **투자 대비 효용이 낮거나 외부 요인으로 실행 불가**로 판정돼 추적을 중단했다. ④는 ③의 폐기 근거가 그대로 적용돼 같은 라운드에서 함께 정리했다. 아래는 같은 조사를 반복하지 않기 위한 근거 보존이다.
  - **폐기 ①「카탈로그 자동 생성 (drift 방지)」**
    - **생성 가능한 표가 5개 중 1개뿐**이다. `Available Skills`(Skill/Invoke/Plugin)만 전부 파생 가능하고, `Available Agents`의 "Delegated by", `Available Commands`·`Plugin Overview`·`Dependency Summary`의 설명 컬럼은 **영·한 각각 손으로 쓴 큐레이션 문구**다. frontmatter `description`은 트리거 매칭용 장문 한국어라 카탈로그 표에 그대로 넣을 수 없다(예: README `Scoped code review` / README.ko `범위 지정 코드리뷰` ↔ frontmatter `사용자가 지정한 파일/폴더/모듈 범위의 코드를 리뷰한다.`).
    - **이 저장소에 CI가 없다**(`.github/` 부재). 생성기 대신 `--check` 드리프트 검증기를 두더라도 **사람이 호출해야만 동작**하므로, README 갱신을 빠뜨린 것과 정확히 같은 실패 모드가 남는다. 자동화로 해결되는 문제가 아니라 절차 이행 문제였다.
    - **절차는 이미 있다** — `.claude/skills/devoks-plugin-maintenance/references/workflow-checklist.md` §2가 "플러그인/skill/command 설명이 바뀔 때 README·README.ko 검토"를 규정한다.
    - **결정적 반례(2026-08-21 발견)**: 조사 시점에 `devoks-sdlc-orchestration`(플러그인)과 `orchestration-run`(스킬)이 `marketplace.json`에는 있으나 양 README 카탈로그에는 없어 drift로 보였으나, **이는 drift가 아니라 의도된 상태**다 — 해당 플러그인이 아직 작업 중(미완성)이라 사용자-facing 카탈로그에 일부러 넣지 않았다. **자동 생성기를 도입했다면 미완성 플러그인을 카탈로그에 강제 주입했을 것이다.** 카탈로그는 "존재하는 것의 기계적 목록"이 아니라 "팀에 공개할 준비가 된 것의 큐레이션"이므로 자동 생성과 성격이 맞지 않는다.
    - 구 항목이 담고 있던 `workflow-map` 관련 판단(단계 순서는 어떤 메타데이터에도 없어 생성 불가, 도입 시 이름 유효성 검증 대상으로만 편입)도 함께 종결.
  - **폐기 ②「evals 하니스 확대」**
    - **러너 질문은 외부 요인으로 종결**: `claude plugin eval` / `claude plugin eval init`은 CLI에 실재하지만(v2.1.238 확인) 실행하면 ``plugin eval` is currently in early access` 를 출력하고 종료한다 — **조직 early-access 게이트 미개방**. 우리 쪽에서 할 수 있는 작업이 없다.
    - **포맷 흡수 불가**: CLI 포맷은 `evals/[[ORCA_RICH_MD:cebdf985fb4e1f8d51781f7c96ec2366:inline-html:%3Ccase%3E]]/prompt.md` + `graders/*.md`(또는 `case.yaml`, `schema_version "1.1"`; grader 타입 `regex|tool_order|tool_used|file_exists|llm|baseline`; 옵션으로 `.claude-plugin/plugin.json`의 `experimental.evals`로 디렉토리 이전 가능)다. CLI 내장 문서가 *"it is unrelated to the `evals/evals.json` format some skill-authoring tools use"* 라고 명시 — 자동 변환 경로가 없고 전량 수기 재작성이다. 게이트가 열리면 그때 이관 비용을 다시 산정할 것.
    - **커버리지 확대는 YAGNI**: 미보유 9개(`test-author`·`test-run-triage`·`code-security-review`·`verify-requirements`·`verify-data-flow`·`code-review`·`feature-frd-author`·`feature-plan-author`·`feature-plan-executor`)는 모두 안정화된 기존 스킬이다. evals의 실사용 시점은 유지보수 스킬 §7 축1(**스킬이 변경될 때**)인데 그 시점에 "기존 skill 변경 시 evals 작성 권장" 규칙이 다시 걸린다 → 지금 쓰면 비용은 즉시, 효용은 불확실한 미래다. 신규 스킬은 축3이 blocking으로 작동해 구멍이 생기지 않는다(최근 신설 스킬 전부 보유).
  - **폐기 ③「`git-commit-msg` 커맨드 → 스킬 전환 + haiku 서브에이전트 위임」**
    - **저장소 자신의 SSOT가 반대 방향이다(결정적)**: `docs/plugin-management.md` §12 "서브에이전트 분리·티어링 판단 3기준" 중 **기준 2(인터랙션 필요성)** 는 *"승인 게이트·사용자 질문이 절차의 본질인 작업은 의도적으로 메인 루프·세션 모델에서 실행한다"* 고 규정한다. 커밋은 SSOT가 "반드시 사용자에게 커밋 메시지를 확인받은 후 커밋한다"로 정한 **승인 게이트가 본질인 작업**이고, 서브에이전트는 `workflow-checklist.md` §8에 따라 **질문 금지**라 게이트를 보유할 수 없다. 3기준 중 2개(기준 2 인터랙션, 기준 3 격리 이득)가 위임에 반대하고 1개(기준 1 스펙 완결성)만 찬성.
    - **비용 절감이 작다(실측)**: 이 저장소 최근 12커밋 diff 중앙값 24,572 chars(≈12k tok), SSOT+커맨드 8,227 chars(≈4k tok). Opus 5 `$5/$25` per MTok · Haiku 4.5 `$1/$5` · 캐시 read `0.1×`/write `2×`(1h TTL) 기준으로 **커밋당 메인 루프 ≈ **$0.19 vs 서브에이전트 ≈$**0.05 → 절감 ≈ $0.14(70%)**. 절감률은 크나 절대액이 작고(주 20커밋 → 월 ~~$11), 무엇보다 **커밋은 검증 체인의 마지막 액션이라 잔여 턴 수가 거의 0** → 서브에이전트 격리의 본래 이득(누적 캐시 재전송 회피)이 이 워크로드에서는 거의 발생하지 않는다. 이득이 커지는 경우는 **한 세션에서 PR 그룹 단위로 3~~4회 커밋하며 계속 작업하는 패턴**뿐이다(4커밋·각 30턴 잔존 시 $1.60 →$0.20).
    - **품질 리스크가 요구사항과 정면 충돌**: 커맨드 본문이 *"변경에 따른 결과·효과를 기재"* 를 요구하는데, 이는 **의도(why) 정보**라 cold diff만 본 haiku가 쓸 수 없다. 보정하려면 메인 루프가 의도 요약을 작성해 넘겨야 하는데 — 그러면 메시지 가치의 대부분을 메인이 만들고 haiku는 포맷팅만 하게 되어 위임의 근거 자체가 사라진다.
    - **스킬 전환은 순이익이 없다**: 커맨드를 우회한 즉흥 `git commit` 문제는 이미 `plugins/devoks-git/hooks/remind-commit-convention.sh`(PreToolUse, 2026-08-21 `bd9ce53`)가 커버한다. 스킬 전환으로 남는 건 git-write 액션의 자연어 auto-trigger 오발동 리스크뿐이다.
    - **재검토 트리거(추적은 하지 않음)**: 한 세션에서 3회 이상 커밋하는 PR-그룹 단위 워크플로가 일상화되면 누적 컨텍스트 비용이 위 계산과 달라지므로 그때 다시 판단한다.
    - 짝 항목 `git-create-issue`/`git-pull-request` 스킬 전환도 같은 라운드에서 함께 폐기 — 아래 폐기 ④.
  - **폐기 ④「`git-create-issue`/`git-pull-request` 커맨드 → 스킬 전환」**
    - 구 배경(2026-07-29): 위 ③과 함께 나온 짝 항목으로, "커맨드→스킬 전환"(진입점 변경)과 "haiku 위임 여부"(모델 변경)를 분리 검토하기로 돼 있었다.
    - **진입점 전환 근거가 ③과 동일하게 무효**: 스킬은 자연어 description 매칭으로 auto-trigger되므로 **gh-write 액션(이슈 생성·PR 생성)의 오발동 리스크**를 커맨드보다 키운다. 반면 스킬 전환으로 얻으려던 "커맨드를 우회한 즉흥 실행 보정"은 커밋의 경우 이미 `remind-commit-convention.sh` PreToolUse 훅이 담당하고 있고, 이슈·PR은 애초에 즉흥 실행 빈도가 낮다(둘 다 명시적 산출물 생성 액션). 즉 **얻는 것 없이 리스크만 늘어난다.**
    - **haiku 위임은 커밋보다 근거가 더 약하다**: 이슈 생성은 label/assignee/issue-type MCP 검증 순서, `### Additional Context` 단일 블록 blockquote 연속 규칙 등 지침이 촘촘해 작은 모델의 실패(재시도) 비용이 커밋보다 크다. PR 본문은 추적성·테스트·리스크 요약이라 ③에서 지적한 **"why 정보는 cold diff에서 나오지 않는다"** 문제가 커밋보다 심하다(PR 본문은 커밋 메시지보다 의도 서술 비중이 더 높다).
    - **§12 기준 2도 동일 적용**: 이슈·PR 생성 역시 사용자 확인 게이트가 절차의 본질이라 `docs/plugin-management.md` §12 "승인 게이트형 작업은 의도적으로 메인 루프에서 실행" 기준에 걸린다.
    - 결론: `devoks-git`의 3개 커맨드(`git-commit-msg`·`git-create-issue`·`git-pull-request`)는 **모두 커맨드·메인 루프 실행을 유지**한다. 진입점 정책 자체를 다시 다룰 일이 생기면 위 "`devoks-sdlc` 커맨드·스킬 통합" 항목의 진입점 정책 절에서 일괄 판단할 것.

- [x] **로드맵 항목 정리 — 완료 항목 제거 + 4개 항목 폐기** (2026-08-21, `devoks-sdlc` `1.17.0 → 1.17.1`)
  - **제거(완료됨)**: "`aware-react-app` 스모크테스트 스킬·에이전트 생성" — 이미 `[x]`로 종결돼 있었고 후속 과제도 아래 `new-smoke-test-draft` 항목에서 처리 완료. 실질 내용(프로젝트 소유 스모크 테스트가 왜 devoks-sdlc 밖에 있는지)은 `workflow-map` 표 A-1 "옵션" 행과 양 README §검증 체인에 이미 서술돼 있어 로드맵에서 빼도 유실 없음.
  - **폐기 ①「구현자 세션 지속 — continuation 기반 PR그룹 단위 위임」**: 실효성이 낮다고 판단해 추적 중단. 현행 태스크 단위 cold-start + 인계 노트 방식을 유지한다. 이 항목을 가리키던 잔여 참조도 함께 제거 — `task-delegation.md` §윈도잉의 "roadmap의 continuation 도입 시 이 윈도잉은 상위 호환으로 완화된다" 1줄 삭제(윈도잉 규칙 자체는 불변, 폐기된 계획을 가리키는 forward-looking 주석만 제거 → `devoks-sdlc` patch bump). 로드맵 orchestration 항목의 Implement 절·파이프라인 다이어그램에 있던 continuation 언급도 `size` 라우팅으로 정리.
  - **폐기 ②「진입점 일관화 검토(command vs skill)」**: 위 "`devoks-sdlc` 커맨드·스킬 통합" 항목과 정리 대상이 동일해 중복 → 그 항목의 "진입점 정책" 절로 흡수했다.
  - **폐기 ③「plugin 버전 메타 정합」**: 플러그인별 개별 semver가 갈라지는 것을 문제로 보지 않기로 결정 — 플러그인마다 변경 빈도가 다른 것이 자연스럽고, 하네스 일괄 버전으로 묶으면 무변경 플러그인까지 재설치를 유발한다.
  - **폐기 ④「MCP 서버 버전 고정 검토」·「MCP project-scope 표준화 검토」**: 공유 MCP는 `/devoks-core:setup-mcp`가 **user scope에 1회 설치**하는 현행 모델을 유지한다. 팀원 간 설치 시점 차이(`@latest` 드리프트)는 감수 가능한 수준으로 판단. 삭제해도 근거는 유실되지 않음 — 번들 방식을 쓰지 않는 이유(번들 MCP와 user-scope MCP는 병합되지 않고 별도 프로세스·다른 prefix로 공존해 중복·충돌)는 `plugins/devoks-core/commands/setup-mcp.md`(15~17행)와 `docs/mcp-setup-guide.md`(9·12행)에 이미 운영 문서로 남아 있다.

- [x] **프로젝트 전용 검증 스킬 Draft 생성 스킬 신설 — `new-smoke-test-draft`(devoks-sdlc)** (2026-08-19, `devoks-sdlc` `1.16.1 → 1.17.0`)
  - 배경: 프로젝트마다 라우트·화면 구조가 달라 devoks-sdlc가 범용 실행 스킬로 제공할 수 없다(`aware-react-app`이 프로젝트 자신의 `verify-app-smoke-test` 스킬을 직접 저작·관리하는 사례에서 확인 — 구 로드맵 항목은 2026-08-21 정리 시 제거). 그렇다고 매 프로젝트가 완전 백지에서 SKILL.md·체크리스트·리포트 템플릿 구조를 설계하게 두는 것도 비효율이라, 시작점만 생성해 주는 별도 스킬을 신설했다.
  - **소유 플러그인 결정**: devoks-core(`setup-project-convention`의 preset 복사 인프라 재사용) 대신 **devoks-sdlc**로 결정 — preset 복사는 고정 템플릿을 그대로 옮기는 반면, 이 스킬은 검증 도메인 지식(스모크 테스트 모드·리포트 판정 체계)을 담은 산출물을 생성하므로 검증 스킬 계열(`verify-acceptance-test` 등)과 같은 플러그인에 있는 것이 SSOT 근접성이 높다고 판단.
  - **이름 결정**: `new-ui-draft`/`new-feature-draft`와 같은 `new-<도메인>-draft` 계열로 `new-smoke-test-draft` 채택 — 이 저장소에서 "draft"는 "미완성 산출물"이 아니라 "한 번에 새 산출물을 직접 만든다"는 의미로 이미 쓰이고 있어 의미가 정확히 들어맞는다(`verify-*`는 검증을 실제로 수행한다는 뜻이라 이 스킬의 "생성만 하고 검증은 안 한다"는 성격과 어긋나 기각).
  - **v1 스코프를 의도적으로 최소화**: (1) 코어(모드 1) 체크리스트는 실제 스캔 데이터로 채워 생성하고, 딥다이브(모드 2) 체크리스트도 **구조**(화면 목록·섹션 골격)는 함께 생성하되 실제 UX 시나리오 **본문**은 화면 이름·라우트만으로 지어낼 수 없어 TODO로 비워 둔다(2026-08-20 보강 — 최초엔 "표에 행을 추가하라"는 문장 하나로만 언급했으나, `aware-react-app`의 `verify-app-smoke-test`가 코어+딥다이브+리포트 3개 reference 파일로 구성된 실제 사례를 근거로 사용자가 "큰 구조를 갖추는 지시가 있어야 한다"고 지적해 딥다이브 체크리스트 파일 자체를 생성하도록 확장). (2) 전담 서브에이전트(`acceptance-test-runner`/`browser-visual-diff-capture`류 스크린샷·콘솔 바이트 격리 패턴)는 파일로 생성하지 않고, 대신 제안 경로·필수 frontmatter·**"tools: 화이트리스트에 실제 devoks-browser MCP 도구 이름을 빠뜨리면 에이전트가 조용히 차단된다"는 구체적 함정 경고**를 포함한 구조화된 지시로 대체한다(2026-08-20 보강 — 이 함정은 바로 위 "반복·동시 트리거 정합성 커버리지 신설" 항목에서 `acceptance-test-runner` 자신이 실제로 겪은 버그를 일반화한 것이라, 생성기가 대상 프로젝트의 실제 MCP tool 이름을 모른 채 frontmatter를 추측해 쓰면 같은 결함을 재현할 위험이 있어 파일 생성 대신 경고로 대체). (3) `project-convention-manage`류 provenance hash·drift 감지·재적용 관리 스킬은 만들지 않음 — 1회 생성 후 프로젝트가 전적으로 소유·유지보수하는 모델이라 동기화 의무 자체가 없다. 대신 생성된 SKILL.md의 `metadata.generatedBy`/`metadata.generatedFrom`에 생성기·소스 라우트 파일을 1회성 참고 정보로만 남긴다.
  - **감지 원칙 재사용**: `setup-project-convention` Step 1의 "감지 결과는 추천 근거에만 사용, SSOT로 단정하지 않는다" 원칙을 그대로 적용 — React Router/Next.js/Expo Router·React Navigation 등 스택별 라우트 파일 후보를 스캔하되, 화면 목록은 반드시 사용자 확인을 거쳐 확정하고, 감지가 애매하면(후보 0개 또는 충돌하는 후보 2개 이상) 추측 대신 라우트 파일을 직접 지목하도록 요청한다.
  - **템플릿 파일 배치**: 대상 프로젝트에 그대로 쓰이는 4개 템플릿(SKILL.md·코어 체크리스트·딥다이브 체크리스트·리포트)은 `feature-workflow-runner/assets/FRD.template.md`와 동일하게 `assets/`에 두고(`references/`는 생성기 자신의 절차 문서만), 플레이스홀더 표기도 FRD.template.md가 쓰는 꺾쇠괄호(`[[ORCA_RICH_MD:cebdf985fb4e1f8d51781f7c96ec2366:inline-html:%3Cfeature-slug%3E]]`류) 스타일을 그대로 따라 이 저장소에 없던 `{{...}}` 문법을 새로 들이지 않았다.
  - **🟡 부수 발견·수정(2026-08-20, 실제 `aware-react-app`의 `verify-app-smoke-test` reference 4개 파일 전문 대조 감사에서 발견)**: 실제 파일은 화면마다 도메인 접두 ID(`WK-1`/`ST-1`/`PT-1`류)를 부여해 코어 체크리스트·딥다이브 체크리스트("기본 체크리스트 대응 ID" 컬럼)·리포트(화면별 결과 행) 3곳에서 동일 ID로 교차 참조하고, 리포트에는 도메인별 PASS/FAIL/BLOCKED 집계 표도 있었다 — 이 v1 생성기의 템플릿 3개(코어·딥다이브·리포트)에는 **ID 컬럼 자체가 없어** 교차 참조가 불가능했고 도메인 집계 표도 없었다. 이는 도메인 지식이 필요한 "내용 깊이" 문제(위 (1)번, 의도된 경계)와 달리 **라우트 경로 문자열만으로 기계적으로 채울 수 있는 정보**를 빠뜨린 생성기 자체 결함이라 수정 대상으로 판단. `references/screen-detection-heuristics.md`에 §4 "화면 ID 부여" 규칙을 신설(라우트의 첫 세그먼트를 도메인 키로 삼아 도메인이 2개 이상이면 `[[ORCA_RICH_MD:cebdf985fb4e1f8d51781f7c96ec2366:inline-html:%3CDOMAIN%3E]]-[[ORCA_RICH_MD:cebdf985fb4e1f8d51781f7c96ec2366:inline-html:%3CN%3E]]`, 1개면 `S-[[ORCA_RICH_MD:cebdf985fb4e1f8d51781f7c96ec2366:inline-html:%3CN%3E]]` — 업무 의미는 절대 추측하지 않는다)하고, 3개 템플릿 전부에 ID 컬럼과 도메인 집계 표를 추가했다.
  - 반영: `plugins/devoks-sdlc/skills/new-smoke-test-draft/`(SKILL.md·`references/screen-detection-heuristics.md`(§4 ID 부여 규칙 신설로 §4~5 재배치)·`assets/`템플릿 4개(2026-08-20 `deep-dive-checklist.template.md` 추가 + 전체에 ID/도메인 집계 컬럼 보강)·`evals/evals.json` 신설/갱신), `plugins/devoks-sdlc/skills/workflow-map/SKILL.md`(표 A-1 "옵션" 행·표 B 재작성, `1.0.1 → 1.0.2`), `plugins/devoks-sdlc/.claude-plugin/plugin.json`(`1.16.1 → 1.17.0`), README.md·docs/README.ko.md(검증 체인 문단 재작성 + 스킬 카탈로그 표·단발 작업 목록에 행 추가).
  - 후속 여지: 실제 설치 대상 프로젝트에서 1회 실행해 생성 결과가 `aware-react-app`의 `verify-app-smoke-test`와 실사용 관점에서 부합하는지 확인 필요(현재는 `evals/evals.json` 프롬프트 기반 동적 검증만 수행) — 6축 체크 동적 축(1·6)의 근본 한계(`enabledPlugins: {}`)는 `workflow-map` 신설 때와 동일.

- [x] **반복·동시 트리거 정합성 커버리지 신설 — 심화 SSOT + SDLC 5단계 전개** (2026-08-19, `devoks-core` `1.2.3 → 1.3.0`, `devoks-sdlc` `1.15.1 → 1.16.0`, `devoks-git` `1.1.0 → 1.1.1`)
  - 배경: 연타 시 수치 유실 버그의 근본원인 분석 결과, 전체 플러그인에서 관련 키워드 grep이 1건뿐이라 리뷰·테스트·검증 어디에서도 이 결함군을 잡지 못했다. 사건에서 관측된 3종(코얼레싱 부재·응답 역류·stale closure 갱신유실)에 더해, 같은 "연타" 행동에서 나오는 **중복 확정(C4)·응답 순서 뒤바뀜(C5)** 이 누락돼 있어 결함 클래스를 7종으로 확장했다.
  - **아키텍처(4레이어)**: 심화 SSOT `refs/interaction-integrity.md` 신설(결함 7종·조작 의미 3분류 판별표·대응 패턴별 함정·검증 축 4개) → 소비처는 **판정 질문 + 결함 ID(C1~C7) 참조만**. 메커니즘 설명·패턴은 소비처에 복사 금지(§6에 인용 규칙 명문화) → 패턴이 바뀌어도 **고칠 파일은 L1 하나**.
  - **과적용 방지**: §1을 AND 게이트(반복이 실제 사용 패턴인가 ∧ 상태 확정·I/O를 유발하는가) + **명시적 제외 예시**(표시만 바꾸는 조작·I/O 없는 단발 조작)로 설계. 대상이어도 §2 의미 분류로 해당 결함만 적용한다. 과다/과소 적용 비용이 대칭이라 정량 임계 대신 정성 판별 질문을 택했다.
  - **전개 위치(SDLC 5단계)**: 스펙 `feature-frd-author`+`FRD.template.md` / 구현 `conventions/react-web`·`react-native`(+`android`·`ios`는 C4 1행) / 테스트 `test-quality-bar.md` §6 + `code-implementer` §6 인용 / 리뷰 `refs/code-review.md` 6곳 / 실동작검증 `verify-acceptance-test` 2곳 + `verify-data-flow`.
  - **🔴 부수 발견·수정: `acceptance-test-runner` 에이전트의 MCP 도구 차단** — frontmatter `tools:`가 화이트리스트로 동작하는데 `Read, Bash, Edit, ToolSearch`만 있어, `scenario-execution.md`가 지시하는 `mcp__chrome-devtools-attach__*` 호출이 **에이전트 내부에서 전부 차단**돼 있었다(= verify-acceptance-test의 Phase 1~4 전체가 동작 불가). 형제 에이전트 `browser-visual-diff-capture`에서 **동일 결함을 `62a7d0a`(2026-07-29)로 이미 고쳤으나**, 그보다 먼저 추가돼 있던(`dcdb81e`, 2026-07-23) 이 에이전트에는 적용되지 않았다. `mcp__chrome-devtools-attach__*` 추가로 해소. permission은 `devoks-browser`의 `settings.permissions.allow`가 이미 커버(devoks-sdlc가 dependency로 보유). **재발 방지: 에이전트를 추가·수정할 때 그 에이전트가 읽는 스킬/reference의 `mcp__` 호출 지시와 frontmatter `tools:`를 항상 대조한다**(유지보수 스킬 Step 6에 해당하나, 에이전트-스킬 쌍 단위 대조는 명시돼 있지 않았다).
  - 부수 수정 3건: (1) `code-implementer`가 `test-quality-bar.md`를 §7·§9만 인용해 **PLAN 인라인 테스트 경로로 케이스 설계 규칙이 전파되지 않던** 갭 — §6 인용 추가. (2) `verify-acceptance-test`가 최종값만 대조해 **코얼레싱 부재를 원리상 검출 못하던** 갭 — I/O 횟수 관측·대기 중 이탈 절차 추가(`list_network_requests` 도구 로드 포함). (3) react-web preset의 기존 pitfall "파생 가능한 값을 state로 중복 보관"과 신규 ref 원천 규칙의 표면적 충돌 — "단방향(ref → state)일 때만 허용" 경계 명시.
  - **기각: `engineering-principles.md`에 원칙 추가(Coalesced Effects)** — 작업 중 추가했다가 철회했다. 사유 3가지: (1) 나머지 23개가 스택·도메인 무관 설계 원칙인데 이 항목만 "state에 즉시 반영하고 I/O는 코얼레싱하라"는 **구체 처방**이라 추상화 수준이 다르다(문장 길이도 2배). (2) 10번 `Idempotent Actions`와 부분 중복 — C4(중복 확정)는 사실상 그 원칙의 위반이다. (3) 이 문서는 frontmatter가 `alwaysApply: false` + "참조용 보관"이고 실제 소비도 `code-refactoring.md`가 이름으로 4개 인용하는 정도라, 한 줄 추가로 바뀌는 에이전트 동작이 없다. 반면 번호 삽입은 이후 전 항목 재번호를 강제한다 — **이득 0에 비용만 남는 변경**. 커버리지 손실은 없다(L1 SSOT + 5단계가 이미 담당). 재제안 시 위 3가지를 먼저 반박할 것.
  - 상세 설계·근거: `~/.claude/plans/devoks-interaction-integrity-design.md`.

- [x] **MCP 설치 명령 정합성 감사 — serena/playwright/codegraph 실제 동작과 불일치 3건 발견·수정** (2026-08-10, `devoks-core` `1.2.2 → 1.2.3`, `devoks-browser` `1.2.0 → 1.2.1`)
  - 배경: 사용자가 "`setup-mcp.md`는 자체적으로 정상 동작하는 상태인가?"라고 물어 실제 `claude mcp list`/`claude plugin list` 등록 상태와 문서의 명령을 대조 검증했다. 이어서 사용자가 "이전엔 문제없던 가이드인데 변경한 기억이 없다"며 git 히스토리로 회귀 여부를 확인해 달라고 요청.
  - **🔴 serena — 확정 버그(day 1부터)**: `claude mcp add serena --scope user -- uvx serena@latest --project ...`가 참조하는 PyPI `serena` 패키지는 이 도구(`oraios/serena` 코드 심볼탐색 에이전트)와 **무관한 별개 프로젝트**(AMQP 0-9-1 클라이언트, 작성자 Lura Skye)였다 — PyPI API로 직접 확인. 최초 커밋(`d194b65`, 2026-06-18)부터 한 번도 고쳐지지 않았다. 실제 동작 중인 serena는 공식 플러그인(`serena@claude-plugins-official`, 내부적으로 `uvx --from git+https://github.com/oraios/serena`)이었다.
  - **🟠 playwright — 확정 버그(day 1부터)**: `/plugin install @playwright/playwright-mcp`는 존재하지 않는 참조 형식. `claude plugin list` 확인 결과 실제 등록은 `playwright@claude-plugins-official`(`<플러그인>@<마켓플레이스>` 형식, figma와 동일). 흥미롭게도 커밋 `58a1ad1`(2026-07-12)이 figma의 동일한 옛 형식(`@figma/figma-mcp`)을 `figma@claude-plugins-official`로 고치면서 **바로 옆 줄의 playwright는 그대로 두고 지나갔다** — 같은 파일 같은 라운드에서 형제 항목 하나만 놓친 사례.
  - **🟡 codegraph — 부분 수정 후 전파 누락**: `setup-mcp.md`는 `58a1ad1`에서 `npm install -g colbymchenry/codegraph` + `codegraph serve --mcp`로 정정됐고 이는 실제 동작과 일치(로컬 확인: `@colbymchenry/codegraph@1.4.1`). 그러나 같은 플러그인의 `check-setup-state.sh`(SessionStart 훅 인라인 안내)와 `docs/mcp-setup-guide.md` §5는 갱신되지 않아, 각각 `npx -y codegraph-mcp@latest`·`npm install -g @codegraph/mcp-server`(플레이스홀더 주석 포함)라는 다른 명령을 안내하고 있었다.
  - **파생 발견 — devoks-browser 자체에 동일 계열 버그**: `plugins/devoks-browser/skills/browser-devtools/SKILL.md`의 "환경 셋업" 절이 `/plugin install chrome-devtools-mcp@chrome-devtools-plugins`(존재하지 않는 마켓플레이스)로 수동 설치를 안내하고 있었는데, 이 안내는 커밋 `6d13a7a`(2026-06-16)에서 작성됐고 **바로 다음 날** `c026652`(2026-06-17)에서 `devoks-browser`가 `chrome-devtools-attach`를 `plugin.json`에 직접 번들하도록 바뀌면서 통째로 불필요해졌다 — 이후 약 2개월간 갱신 없이 방치. harness 문서가 아니라 **실제 설치되는 플러그인 산출물**이라 mcp-setup-guide.md 쪽 문제보다 영향이 크다.
  - **결론(사용자 우려에 대한 답)**: 최근에 누가 실수로 고친 게 아니라, 이 4곳 모두 **애초에 검증 없이 작성됐거나(serena·playwright) 부분 수정이 다른 파일로 전파되지 않은(codegraph) 오래된 잠재 결함**이다 — git blame으로 각 라인의 최초/최종 수정 커밋을 확인해 회귀가 아님을 확정했다.
  - 반영: `plugins/devoks-core/commands/setup-mcp.md`(serena를 Step 3→Step 4 플러그인 설치로 이동 + 사유 명시, playwright 참조 수정, `--project` 대신 런타임 `activate_project` 안내), `plugins/devoks-core/hooks/check-setup-state.sh`(serena·codegraph 인라인 안내 정정), `plugins/devoks-browser/skills/browser-devtools/SKILL.md`(수동 설치 절 전체 삭제 → "자동 번들, 별도 설치 불필요"로 교체), `docs/mcp-setup-guide.md`(§3-1 마켓플레이스명·§4 playwright·§5 codegraph·§6 serena·§8 context-mode 마켓플레이스명·하단 조합 예시 2곳 정정, 각 절에 SSOT 포인터 추가), `shared/setup/claude.json.template`(serena 블록 제거 → `_serena_note` 경고로 교체). `claude plugin validate --strict` 양 플러그인 통과, 전량 재검색으로 실제 안내문 중 잔존 오류 패턴 0건 확인(경고성 예시 텍스트만 남음).
  - 의도적으로 변경하지 않음: context7 관련 명령(검증 결과 정확), figma 관련 명령(이미 정확), README/README.ko/marketplace.json/plugin-management.md(이 구체적 명령을 인용하지 않아 비대상 — grep 확인).

- [x] **MCP 설치 가이드 이중 관리 재정의 — "SSOT-미러"가 아니라 "목적이 다른 별개 문서"로 재구성** (2026-08-10, `plugins/` 미변경 — 저장소 루트 문서만)
  - 배경: `setup-mcp.md`(대상 프로젝트에 설치되는 실행형 지침) ↔ `mcp-setup-guide.md`(harness 저장소 자체의 유지보수자용 배경 설명)가 Chrome 디버그 명령을 inline 중복 보유하면서, "한쪽을 고치면 반드시 다른 쪽도 갱신한다"는 SSOT-미러 동기화 의무 주석을 달고 있었다.
  - 사용자 지적으로 전제 자체를 재검토: 두 문서는 **목적이 다르다** — `plugins/*`는 설치·실행 대상 산출물(플러그인 루트 밖 참조 금지로 자기완결적이어야 함), `docs/*`는 harness 저장소 자신을 위한 유지보수자 참고 문서다. 우연히 같은 실행 명령을 담을 뿐, 하나가 다른 하나의 미러여서 동기화 의무를 지는 관계가 아니다 — 이 원칙은 `doc/*` ↔ `plugins/*` 전반에 적용된다.
  - 실제로 이 원칙이 이미 지켜지던 곳도 확인: `setup-mcp.md` 11행은 이미 "`docs/mcp-setup-guide.md`는 harness 저장소 자체 전용, 대상 프로젝트엔 미설치 — 이 커맨드 실행에 필요한 내용을 그 문서에 미루지 않는다"고 명시하고 있었다. 위반은 `mcp-setup-guide.md` 쪽의 "동기화 의무" 주석 하나뿐이었다(`code-analyze-module.md`의 `docs/` 언급은 대상 프로젝트 자신의 문서를 가리키는 다른 맥락, `orchestration-run/SKILL.md`의 `docs/orchestration-design.md` 인용은 "(유지보수자용)" 라벨이 이미 붙어 있어 문제 없음 — grep으로 전량 확인).
  - 반영: `docs/mcp-setup-guide.md` §3-3의 "한쪽을 고치면 반드시 다른 쪽도 갱신한다" 문구를 "목적이 달라 SSOT-미러 관계가 아니다 — 동기화 의무 없이 각자 독립적으로 고친다"로 교체. `setup-mcp.md`는 변경 없음(이미 정확한 서술 보유). `plugins/` 미변경이므로 버전 bump 비대상.
  - 후속 여지: "`doc/*`와 `plugins/*`는 목적이 다르다"는 원칙을 이번엔 이 한 쌍에만 적용했다 — 다른 `doc/*` ↔ `plugins/*` 쌍에 유사한 오류가 있는지의 전면 감사는 이번 스코프 밖(요청 시 별도 진행).

- [x] **FRD §4 복잡도 임계 신호 목록 SSOT 수렴** (2026-08-10, `devoks-sdlc` `1.15.0 → 1.15.1`)
  - 미러 3곳(`feature-workflow-runner/SKILL.md` 핵심 원칙 절 · `feature-frd-author/SKILL.md` 절차 6 · `assets/FRD.template.md` §4 안내 주석)의 신호 인라인 나열을 제거하고 "복잡도 임계 초과 시(신호 목록·기준: `design-spec.md`)" 포인터로 축약 — 로드맵이 제시한 두 방향("전면 제거" vs "축약 표기 유지") 중 전면 제거를 채택했다. 3곳 모두 SSOT 링크가 이미 인접해 있어 정보 손실이 미미한 반면, 2026-07-30에 실제로 4곳 수동 동기화가 필요했던 drift 표면이 이번 개정으로 사라진다.
  - SSOT(`design-spec.md`)는 무변경. `claude plugin validate --strict` 통과, grep으로 SSOT 외 잔존 나열 0건 확인.
  - 반영: `skills/feature-workflow-runner/SKILL.md`(`1.6.0 → 1.6.1`), `skills/feature-frd-author/SKILL.md`(`1.2.0 → 1.2.1`), `skills/feature-workflow-runner/assets/FRD.template.md`, `plugin.json`. README/README.ko/marketplace.json은 스킬 이름·description 불변이라 비대상.

- [x] **심각도 분류 SSOT 통합** (2026-08-10, `devoks-sdlc` `1.15.0 → 1.15.1`, 위 FRD §4 항목과 같은 라운드)
  - 재조사 결과 `code-review`·`code-security-review`는 2026-07-20에 이미 `.claude/refs/code-review.md §8`을 SSOT로 참조 중이었음을 확인(로드맵 기록이 낡아 있었다) — 실제 미반영은 `verify-requirements`·`test-run-triage` 2곳.
  - `verify-requirements`의 "V3. 심각도 판정 기준" 표는 일반 SSOT의 **도메인 특수화**(요구사항 커버리지 갭 맥락)라 내용 삭제는 부적절 — 표 삭제 대신 "SSOT는 §8, 아래는 그 맥락 특수화"임을 명시하는 1줄만 추가해 정의가 갈라진 게 아니라 좁혀진 것임을 밝혔다. `test-run-triage`는 정의 자체가 없이 이모지만 표에 있었으므로 참고 기준 문서 절에 SSOT 포인터 1줄만 추가.
  - 반영: `skills/verify-requirements/SKILL.md`(`1.0.1 → 1.0.2`), `skills/test-run-triage/SKILL.md`(`1.1.0 → 1.1.1`), `plugin.json`.

- [x] `**workflow-map` 스킬 신설 — SDLC 흐름·진입점 조회 맵 + README 파이프라인 차트** (2026-08-07, `devoks-sdlc` `1.13.0 → 1.14.0`)
  - 배경: HITL 작업 중 "지금 어디쯤이고 다음에 뭘 부르나"를 즉시 답하는 진입점이 없었다. 흐름 정보가 세 곳에 흩어져 있었고 어느 것도 그 질문에 답하지 못했다 — README 카탈로그는 **평면 나열**이라 순서가 없고 harness 저장소 문서라 설치 대상 프로젝트에서 접근 불가, `post-implementation-checklist.md`는 **검증→커밋→PR 꼬리 부분만** 담으며 `feature-workflow-runner` 실행 중에만 로드, 각 SKILL.md의 "관련 스킬" 문구는 인접 1~2개만 가리킨다.
  - 문서가 아니라 **스킬**로 만든 이유: 설치된 대상 프로젝트에서 동작하려면 플러그인 루트 안에 있어야 하고(루트 밖 참조 금지), 커맨드와 달리 스킬은 에이전트가 "다음 단계 제안" 근거로 스스로 참조할 수 있다. 팀의 스킬 우선 방향과도 일치.
  - 설계 결정: (1) **정적 표만** — 진행 상태 판정은 `PLAN.md` 체크박스가 이미 SSOT라 중복 로직을 만들지 않는다. (2) **얕게 담고 링크** — 단계 순서·진입점만 SSOT로 갖고 조건·절차는 `post-implementation-checklist.md`에 위임(그 문서가 이긴다고 본문에 명시). 심각도 분류·FRD §4 임계 신호에서 겪은 인라인 복제 drift를 반복하지 않기 위함. (3) **실제 흐름 전체 범위** — devoks-core(0단계)·devoks-git(5단계)·devoks-browser(4-4)를 포함하되 prefix로 출처 표기, 미설치 시 생략 안내.
  - 파생 발견: `new-feature-draft`/`new-feature-github-issue` 커맨드가 `feature-workflow-runner`를 **호출하지 않고**(`branch-issue-precheck.md` 참조만 공유) 기능 구현 진입 경로가 사실상 둘로 병존한다. workflow-map 표 B에 "산출물 없는 간이 구현"으로 성격을 명시해 당장의 혼란은 덮었으나, 통합/정리 여부는 위 "`devoks-sdlc` 커맨드·스킬 통합" 항목에서 결정해야 한다.
  - 반영: README.md·docs/README.ko.md에 mermaid 파이프라인 차트 섹션 신설(스킬 카탈로그 **앞**에 배치 — 평면 나열을 읽기 전에 순서를 먼저 보게), 양 README 스킬 표에 `workflow-map` 추가, 위 "카탈로그 자동 생성" 항목에 표면 추가 기록.
  - 미완: 6축 스킬 품질 체크의 **동적 축(1·6)** — 이 저장소는 `enabledPlugins: {}`라 어떤 플러그인도 활성화하지 않아 신규 스킬을 세션에서 트리거할 수 없다. publish + 재설치 후 `evals/evals.json` 2케이스로 스모크 필요.

- [x] **harness 유지보수 체크표(`workflow-checklist.md`) §4 devoks-sdlc 절 사실 정정** (2026-07-30, 플러그인 번들 외부 — 버전 bump 비대상)
  - 위 `size` 개정의 커밋 전 자체 재감사 중 발견. 이 문서는 devoks-sdlc 변경 시 "영향 범위가 가장 넓다"고 경고하는 근거인데 두 곳이 틀려 있었다.
  - ⑴ **수치 drift**: "skill 10 + command 8 + agent 2"로 기재됐으나 실제는 skill 11 + command 9 + agent 5. 숫자를 갱신하는 대신 **하드코딩을 제거**하고 확인 명령(`ls skills/*/ commands/*.md agents/*.md`)을 남겼다 — 손으로 유지하는 개수는 반드시 다시 drift한다(당시엔 같은 이유로 "카탈로그 자동 생성(drift 방지)" 항목을 두고 있었으나, 그 항목은 2026-08-21 폐기됐다 — 위 폐기 ① 참고. 하드코딩 제거라는 이 조치 자체는 유효하다).
  - ⑵ **사실 오류**: "`code-reviewer`/`code-security-reviewer` **agent**가 agent-internal only"라고 서술했으나 반대다 — 그 둘은 커맨드·사용자 요청의 **진입점**(직접 트리거 가능)이고, agent-internal인 agent는 `code-implementer`·`acceptance-test-runner`다. agent-internal인 것은 동명의 **skill**(`code-review`/`code-security-review`)이다. skill/agent 층을 혼동한 서술이라 감사자가 잘못된 기준으로 README를 점검하게 된다 → 세 갈래(agent-internal skill / agent-internal agent / 직접 트리거 가능 agent)로 분리 기재하고 확인 grep을 붙였다.
  - 반영: `.claude/skills/devoks-plugin-maintenance/references/workflow-checklist.md`. `plugins/` 미변경이므로 어떤 플러그인도 버전 bump 비대상.

- [x] `**size` 마커 부여 기준·위임 라우팅 개정 — 경계선을 `S`(직접) 대신 `M`(위임)으로 기울임 + `L` 라우팅 비단조성 해소** (2026-07-30, `devoks-sdlc` `1.12.0 → 1.13.0`)
  - 배경(실사례): Aware 저장소 "추출 보정 3회화"(이슈 #43, PR #44)에서 구현 Task 5개가 전부 `size: S`로 부여돼 세션 모델(Fable 5, $10/$50 per MTok)이 직접 구현. TASK-002/003은 "구현 1파일 + colocated 테스트 1파일, FRD에 수식 단위로 스펙 확정"으로 `M` 기본값("파일 1~3개, 스펙 확정")에 해당했으나, `task-delegation.md` 손익분기의 **"잔여 Task ≤3개이거나 단일 모듈·단일 PR이면 `S`를 넉넉히 부여"** 조항이 `S` 판정 근거로 확대 적용된 것이 직접 원인.
  - 확정 원칙: **스펙이 닫혀 있으면 위임(`M`), 판단·설계가 필요하면 직접** — 기존 공통 예외 ③("스펙 미완결 → 직접")과 대칭을 이루는 축. `code-implementer`는 `model: sonnet` 고정이라 스펙이 닫힌 기계적 구현을 상위 모델로 직접 해도 충실도 이득이 없는 반면 단가·rate limit 소모는 큼 — 상위 모델은 판단 레이어(분석·FRD 정련·설계 결정·리포트 판정)에 남긴다.
  - `S` 정의를 **닫힌 열거**로 축소(순수 타입/상수 정의·설정값 변경·문구/주석 수정·단순 re-export, `test: skip`). "목록에 없으면 `M`" 구조가 경계선을 기본값으로 강제한다. 새 규칙 `**test: required` ⇒ 최소 `M`**(단방향 필요조건 — `skip`이어도 규모가 있으면 `M`).
  - **열린 결정 4건의 판단**: ⑴ colocated 테스트 파일 수 산정은 논쟁 자체를 폐기 — 파일 수는 프록시일 뿐이고 위임 순이득의 실제 원천("검증 출력이 메인 컨텍스트에 적재되는가")은 `test` 마커가 직접 표현하므로 4번 규칙으로 흡수. ⑵ 정량 임계(diff ≤30줄 등) **미도입** — PLAN 작성 시점엔 추정치라 이번 오배정과 동일한 실패 모드(자의적 근거의 확대 적용)를 재생산하고, 대신 닫힌 열거 + "새 분기·상태·런타임 동작을 만들지 않는다"는 구조적 판별식을 채택. ⑶ 세션 모델 조건부 규칙 **미도입** — `size`는 PLAN 작성 시점에 고정되는데 실행 세션 모델은 그때 미확정이고 재개 시 바뀔 수 있어, 조건부화하면 마커 안정성(즉흥 판단 제거라는 존재 이유)이 깨짐. 모델 이득은 규범이 아닌 손익분기 서술로만 유지. ⑷ `test: required` ⇒ 최소 `M` **채택** — 새 `S` 정의가 기존 `test: skip` 기준 목록의 진부분집합이라 명문화 비용 0.
  - **손익분기 조항의 우회로 2곳을 함께 축소**(제안 단계에서 발견, 사용자 승인): ⒜ `task-pr-splitting.md`·`task-delegation.md`의 ≤3개 조항을 "이미 `S` 요건을 충족한 Task끼리의 tie-breaker"로 격하하고 "`M` 기본값 Task를 `S`로 끌어내리는 근거로 쓰지 않는다"를 명시. ⒝ `progress-tracking.md` 재개 절차 5항의 **런타임 판본**("잔여 3개 이하면 남은 `M`도 직접 구현 우선 검토") — 마커를 고치지 않고 라우팅만 뒤집어 ⒜의 취지가 그대로 새는 지점이라, "잔여량은 `M`을 직접으로 뒤집는 근거가 아니다"로 반전. ⒞ `task-delegation.md` 손익분기 표의 모델 조건부 행("세션이 opus/fable이면 `S` 임계를 보수적으로")은 결정 ⑶과 충돌하고 구 `S` 정의(함수 1~2개)를 인용하고 있어 제거 — 유효 내용(cold-start 재독 오버헤드는 모델 무관 존재)은 서술 문단에 이미 있음.
  - 안티패턴 노트 2개("애매하면 `M` 남용"/"귀찮아서 skip")는 **유지**(방향만 바꾸는 개정이지 균형 장치 제거가 아님). 단 노트 ①의 `S` 후보 예시는 구 정의("조건부 렌더링·단순 토글류")를 인용해 새 규칙과 충돌하므로 새 열거로 교체. 반영 중 `순수 타입/상수 정의`가 `S` 열거에서 빠지면 예시·템플릿에 유효한 `S`가 하나도 남지 않아 노트 ①이 무근거가 되는 문제를 발견해 명시적으로 포함(`test: skip` 기준 목록과의 정합).
  - 예시·템플릿의 `S` + `test: required` 조합(새 규칙 위반) 정정: `example-walkthrough.md` TASK-005(조건부 토스트)·TASK-012(재시도 폴백), `PLAN.template.md` TASK-004(조건부 렌더링)·TASK-011(에러/재시도) → 모두 `M`. 각 예시에 `S`는 타입/상수 Task 1개만 남는다.
  - **후속 발견 — `L` 라우팅 비단조성(같은 라운드에서 함께 개정)**: 라우팅이 규모에 대해 비단조였다(`S`→직접, `M`→위임, `L`→직접). 규모가 커질수록 위임 이득이 커지는데(cold-start 고정비 대비 본작업 비례 이득) 못 쪼개는 `L`은 정의상 본작업이 가장 크고 위임 이득이 최대인 지점인데도 가장 비싼 모델(세션 모델)로 갔다.
    - **진단(층 1)**: 원인은 "L이 크니까 직접"이 아니라 `**L` 부여 기준이 이질적인 두 축을 OR로 묶은 것** — ⑴ 규모 축(파일 3개 초과, 양적) ⑵ **판단 축**(설계 변경·인터페이스 파급, 질적). 두 축은 위 확정 원칙에서 정반대 결론을 요구한다(스펙이 닫혔으면 위임 / 판단이 필요하면 직접). 판단 축 `L`은 실은 공통 예외 ③과 같은 축이라 이미 커버되고 있었고 **다른 축만 잘못된 출구로 나가고 있었다.** 따라서 필요한 것은 새 규칙이 아니라 **기존 원칙의 누락된 적용**이었다.
    - **개정(A안)**: 라우팅 표 `L` 행을 사유별 2분기로 — 판단 축 → 메인 루프 직접 / 스펙 닫힘 축 → 위임(스코프 초과 시 런타임 보정의 blocked가 안전장치). 부여 측은 "쪼갤 수 없으면 §1에 사유 1줄"이라는 **기존 의무에 어느 축인지 밝히도록** 한 구절만 추가 — 라우팅은 그 기록을 읽을 뿐 새 판단을 하지 않으므로 `test: required ⇒ 최소 M`과 동일한 **"판단 비용 0 게이트"** 패턴이 된다. `PLAN.template.md` §1에 해당 슬롯이 없어 A안이 실제로 동작하지 않으므로 선택 bullet(`size: L` 잔존 사유)을 신설했다.
    - **기각**: ⒝ 못 쪼개는 `L`을 AskUserQuestion으로 확인 — "쪼갤 수 없는 `L`"은 정의상 사용자가 결정할 것이 없고(§1에 사유 기록됨) HITL 마찰만 늘어 실익 낮음. ⒞ `L` 마커 폐기 후 `M`+분해 플래그로 통합 — 비단조성 원천은 제거되나 템플릿·예시·각 SKILL.md 요약까지 파급되어 "문서 구조·SSOT 분담 유지" 제약 초과.
  - **후속 발견 2 — `L` 부여 기준의 파일 수 지표 폐기(같은 라운드, 사용자 지적으로 발견)**: 층 1을 고친 뒤에도 규모 축의 **측정 지표**가 "파일 3개 초과"로 남아 있었다. 사용자 지적 — "수정될 파일 개수는 중요하지 않다. 실제로 중요한 것은 구현 시 판단이 필요한지, 로직·테스트·인터페이스 중 무엇이 변경되는지다. 파일 1개라도 그것들이 바뀌면 크다. 사이즈가 파일 수량에 비례하지 않는다."
    - **진단(층 2)**: 파일 수는 **신뢰성은 있고 타당성이 없는** 대리지표 — "세기 쉬워서" 쓰였을 뿐 `size`가 예측해야 하는 값(재독 범위·검증 출력 크기)과 상관이 약하다. 양방향 반례: ⑴ 파일 1개인데 공용 시그니처·상태 머신·데이터 계약 변경 → 전 호출부 재독/테스트 폭발/마이그레이션 판단 ⑵ 파일 5개인데 rename·import 경로 일괄 수정 → 판단 0·재독 얕음·위임 최적. 결정 ⑵가 diff 라인 수를 기각한 이유("작성 시점 추정치")가 파일 수에는 적용되지 않아 살아남았던 것이며, 신뢰성마저 완전하지 않다(`file:`은 디렉터리 표기를 허용하고 colocated 테스트는 보통 미기재 → **라우팅이 `file:` 기재 정확도에 종속**). 또한 결정 ⑴("colocated 테스트 파일 수 산정 논쟁 폐기")은 `S` 판정에서만 해소됐고 M/L 경계에서는 그대로 재발했다(컴포넌트+훅+스타일 3개 + 테스트 1개 = 4개 → `L`로 튐).
    - **핵심 관찰**: 정성적 의도는 **이미 산문에 있었다** — 표 바로 아래에 "`L`이 남아 있는 PLAN은 분해 3원칙 위반 가능성이 높다"고 적혀 있었고 표만 틀린 자로 재고 있었다. 따라서 개정은 새 기준 도입이 아니라 **표를 산문에 맞추는 일**이다. 그리고 사용자가 지목한 세 성질 중 테스트는 `test` 마커, 인터페이스는 `L` 판단 축에 이미 인코딩돼 있고 **빈 칸은 "로직" 하나뿐**이었는데 그 자리를 파일 수가 차지하고 있었다 — 산문이 말한 "관심사가 둘 이상 섞였는가"로 채웠다.
    - **개정**: `L` 부여 기준을 "**관심사가 둘 이상 섞였거나**(분해 3원칙 ①단일 위반) **설계 변경·인터페이스 파급**이 있는 Task"로 교체하고, 파일 수는 "판정 기준이 아니라 위반을 의심하게 하는 **참고 신호**"로 격하(권장 크기 문구에도 "`size` 판정 기준이 아니다" 명시). A안의 축 이름을 **규모 축 → 스펙 닫힘 축**(관심사가 얽혔지만 각각의 스펙은 확정됨)으로 정렬 — A안은 무효화되지 않고 **전제가 정확해졌다**("파일이 많다"는 위임 근거로 빈약했으나 "관심사가 얽혔지만 스펙은 닫혔다"는 정확한 근거).
    - **부수 효과**: 이 개정으로 **파일 수가 `size` 체계 전체에서 사라졌다**(`S`는 같은 라운드에 이미 정성화). 결정 ⑵의 논리가 S/M/L 세 마커에 일관 적용된 상태가 됐다 — 앞서 "남은 리스크: 정량 기준의 비대칭"으로 기록했던 항목이 이로써 해소됨.
    - **트레이드오프**: 파일 수는 기계적으로 셀 수 있어 `feature-plan-author` 완료 기준의 자동 점검이 쉬웠고, 정성 기준은 그것이 안 된다. 다만 애초에 잘못 재던 값이라 자동 점검의 정확도 자체가 낮았고, 실제 안전장치는 런타임 보정(blocked)이며, 파일 수를 "참고 신호"로 남겨 의심 트리거는 유지된다 — 순손실은 작다고 판단.
  - **후속 발견 3 — FRD §4 복잡도 임계 보강(같은 라운드, "파일 3개도 같은 대리지표 문제 아닌가" 질문에서 R&amp;D)**: `size`에서 파일 수를 폐기한 논리를 §4 임계에 그대로 옮기면 **틀린다**는 결론. 반사적 적용을 기각한 근거를 남긴다.
    - **출처 확인**: `design-spec.md`의 임계 신호는 이 문서 고유값이 아니라 `**plugins/devoks-core/rules/agent-principles.md:21` "Ask Before Expanding Scope"의 미러**임을 문서가 스스로 선언하고 있었다(그 rule은 대상 프로젝트에 실제 복사되는 base rule 2개 중 하나). 임계를 건드리면 크로스 플러그인 변경이거나 선언된 미러 관계를 깨는 drift가 된다.
    - **진단**: 원본 게이트는 **"사용자에게 스코프 확인을 받아라"**(blast radius)용이고 §4는 **"설계를 문서로 고정하라"**(구조 결정 유무)용이다 — **다른 목적의 기준을 차용**한 것이며, 이번 세션에서 세 번째로 반복된 같은 패턴(손익분기 조항 확대 적용 → `L` 두 축 OR → 이번). 파일 수가 어긋나는 것도 맞다(파일 5개 rename = 구조 결정 0인데 초과 판정 / 훅 1개 안에서 상태 소유 위치 변경 = §4.2의 핵심인데 단순 판정).
    - **그런데 `size`와 결론이 다른 이유 — 오류 비용의 비대칭이 반대다**: `size`는 과다·과소 위임 모두 실비가 발생해 **대칭**이므로 정확도가 필요했고 정성 전환이 정당했다. §4 임계는 과다 트리거가 토큰+HITL 1회로 끝나는 반면 과소 트리거는 PLAN이 임의 구조로 분해되는 비용을 내므로 **비대칭** — **과다 트리거가 안전한 방향**이다. 게다가 §4는 사용자와 대화하는 FRD 저작 단계에서 작동해 오판을 즉시 교정할 수 있고, `size`처럼 실행 라우팅에 자동 집행되지 않는다. 따라서 느슨한 정량 임계는 해악이 아니라 **안전판**으로 작동한다. 남는 실질 문제는 false negative 하나뿐이었다.
    - **개정(안 A — 제거 대신 보강)**: ⑴ 임계 신호에 **"상태·데이터의 소유 위치가 새로 정해지거나 바뀜"** 추가 — §4.2가 스스로 핵심이라 밝힌 질문을 신호로 승격(`L` 개정과 같은 "문서 안에 이미 있는 것을 신호화" 패턴), 파일 1개짜리 false negative를 잡는다. ⑵ `파일 3개 초과`에 **"기계적 일괄 변경(rename·import 경로·동일 패턴 반복 추가)은 해당 없음"** 한정구 — false positive만 깎고 임계는 유지해 미러 선언을 깨지 않는다. ⑶ `단순` 행에 "위 신호가 하나라도 있으면 단순이 아니다"를 명시(기존 AND 조건이 암묵적이었음). ⑷ 원본과의 차이가 **의도된 것**임을 design-spec에 1줄로 박아 미래 유지보수자가 "동일하게" 되돌리지 못하게 했다.
    - **기각(안 B)**: `파일 3개 초과`를 참고 신호로 격하하고 미러 선언을 끊는 정성 전환 — 과다 트리거가 안전한 게이트에서 안전판을 제거하고 base rule과의 선언된 관계를 끊어 drift 관리 부담을 만든다. 비용 &gt; 이득.
    - `**devoks-core` 미변경**: `agent-principles.md`의 "more than 3 files"는 원래 목적(blast radius → 스코프 확인)에서 정량이 오히려 적합하고, base rule로 전 대상 프로젝트에 배포되는 SSOT라 파급이 크다 — 유지.
  - **남은 리스크**: 위임한 스펙 닫힘 축 `L`이 blocked로 돌아오면 cold-start 1회 헛지불. `L`은 설계상 드물고 blocked 리포트가 부분 변경 파일 목록을 은폐 금지로 요구하므로 인수 비용은 낮다.
  - 반영: `skills/feature-workflow-runner/references/task-pr-splitting.md`(부여 기준 SSOT — `size` 표·`S` 필요조건·손익분기 tie-breaker·`L` 정성 기준 전환·권장 크기 문구의 판정 기준 부인·`L` 사유 축 명시)·`references/task-delegation.md`(라우팅 SSOT — 원칙·단가 다운시프트·손익분기 표·`L` 행 2분기)·`references/progress-tracking.md`·`references/example-walkthrough.md`·`assets/PLAN.template.md`(`size` 설명·예시 마커·§1 `L` 잔존 사유 슬롯), `skills/feature-workflow-runner/SKILL.md`(Phase 3 요약의 `L` 문구, `metadata.version` `1.5.0 → 1.5.1`), `skills/feature-plan-author/SKILL.md`(`size` 분포 자기점검 양방향화 + `L` 축 명시 확인, `1.2.0 → 1.2.1`), `skills/feature-plan-executor/SKILL.md`(라우팅 절의 `L` 문구, `1.5.0 → 1.5.1`), `skills/feature-workflow-runner/references/design-spec.md`·`assets/FRD.template.md`·`skills/feature-frd-author/SKILL.md`(§4 복잡도 임계 보강 — 소유 위치 신호 추가·기계적 일괄 변경 한정구·단순 행 AND 조건 명시, `1.1.0 → 1.1.1`), `plugin.json`.
  - 의도적으로 변경하지 않음: `feature-plan-author`/`feature-plan-executor`의 `references/` 사본 — 존재하지 않고 `../feature-workflow-runner/references/`를 상대 참조하므로 SSOT 1곳 수정으로 전파됨. 두 스킬의 `description`에 있는 size 요약("S 직접·M 위임·L 분해 재검토")은 개괄 표현이라 그대로 유효(트리거 조건 불변 — 동적 eval 생략 근거). `README.md`/`docs/README.ko.md`/`marketplace.json`은 스킬 목록·description 불변이라 비대상.
  - 6축 스킬 품질 체크리스트: 정적 축만 적용 — 축2(참조 실존) 변경 4개 스킬의 `references/*.md` 언급 27건 전량 실존 확인, 축3(`evals/evals.json`)은 변경 4개 중 `feature-workflow-runner`만 보유하고 `feature-plan-author`/`feature-plan-executor`/`feature-frd-author` **3개가 기존 공백**(이번 변경으로 생긴 것 아님 — "evals 하니스 확대" 항목 범위), 축4(MCP 의존 없음), 축5(`../../` 플러그인 루트 탈출 0건 — 스킬 간 `../feature-workflow-runner/` 공유 참조는 루트 내부라 안전). 동적 축(1·6)은 description·트리거 조건 불변이라 생략.
  - **커밋 전 자체 재감사에서 발견·수정(같은 라운드)**: ⑴ `feature-plan-author/SKILL.md` 완료 기준이 `S` 열거를 SSOT(`task-pr-splitting.md`) 밖에 **복제**하고 있어 참조로 축약(열거를 여기 복제하지 않는다는 문구를 함께 박음) — 이 저장소가 "심각도 분류 SSOT 통합"을 별도 항목으로 둘 만큼 경계하는 패턴과 충돌했다. ⑵ `task-pr-splitting.md`의 `S` 필요조건 bullet이 "`skip`이어도 **규모가 있으면** `M`"이라고 써서, 같은 파일에서 방금 폐기한 양적 지표를 되살리는 자기모순이었다 → "위 `S` 열거에 해당하지 않으면 `M`"으로 정정. ⑶ 첫 보고에서 `patch`로 판정했으나 **라우팅 결과가 실제로 뒤집히는 변경**이라 소비자에게 신호가 필요하다고 판단해 `minor`로 승격(`1.12.1 → 1.13.0`, 스킬 metadata도 minor). ⑷ 재감사 자체가 스킬이 지정한 상세 체크표(`references/workflow-checklist.md`)를 첫 라운드에 읽지 않고 진행했던 절차 누락을 드러냈다 — 축 2/3/5의 명시된 grep 절차와 §4 devoks-sdlc 특수 케이스는 재감사에서야 실행됐다.

- [x] **실동작 인수 검증 스킬 신설 — `verify-acceptance-test`(+ `acceptance-test-runner` 에이전트), `devoks-browser` 의존성 추가** (2026-07-23, `devoks-sdlc` `1.9.0 → 1.10.0`)
  - 배경: aware-react-app 세션에서 "추출설정 기계보정 완료 마크" 기능이 계획→구현→유닛테스트 39건→코드리뷰까지 전부 통과했는데도, 브라우저 실동작 검증 단계에서만 (a) 의존 DB 필드가 실환경에서 `null`이라 기능이 발동 자체를 안 하는 데이터 리얼리즘 문제와 (b) 에뮬레이터가 목표 상태를 재현 못해 임시 패치가 필요했던 인프라 갭이 드러남. lint/유닛테스트/코드리뷰가 잡지 못하는 "실데이터 정합"·"UI 조작→영속의 종단 동작" 갭을 메우는 스킬로 신설.
  - 조사 결과 제안된 5개 항목(P1~P5) 중 상당수가 이미 커버돼 있었음: TEMP 패치 회수 규약(`verify-data-flow`의 `[[ORCA_RICH_MD:cebdf985fb4e1f8d51781f7c96ec2366:inline-html:%3CAuditMarker%3E]]`+grep 전량 회수)은 이미 완비돼 참조만 걸었고, "실행 단계 마지막 자동 게이트"화는 이 저장소가 이미 확정한 "제안이지 오케스트레이션이 아니다" 원칙(`post-implementation-checklist.md`, 자동 게이트는 `devoks-sdlc-orchestration` 로드맵 항목 소관)과 충돌해 게이트가 아니라 체크리스트 항목으로 편입. 데이터 리얼리즘 체크는 `verify-requirements`가 이미 "데이터 정합성 실측은 verify-data-flow 소관"이라 자기 범위를 그어둬 그 대신 `feature-frd-author`의 Edge Case 작성 단계에 배치.
  - 신규 스킬 위치를 devoks-sdlc로 결정(사용자 확인) — 실제 앱을 구동해 검증하는 것은 SDLC 검증 영역이고 devoks-browser는 Chrome DevTools MCP 연동·디버깅 전용 역할로 분리 유지. `browser-visual-diff → devoks-sdlc:verify-visual-diff` 이전이 보류된 사유("기존 스킬+캡처 에이전트+references 통째 이전 비용")와는 다른 케이스임을 확인 — 새 스킬이 `dependencies`로 devoks-browser를 선언하는 것은 devoks-browser가 devoks-core에 의존하는 것과 동일한 이미 검증된 패턴이라 새 결합 문제를 만들지 않음(공식 문서 `plugin-dependencies`의 `deploy-kit`↔`secrets-vault` 예시로 MCP 도구가 의존성만으로 그대로 호출 가능함을 확인, 별도 permission 중복 선언 불필요).
  - `verify-data-flow`(레이어별 계측·3중 대조)와 경계 분리: 이 스킬은 UI 조작 주도·1회성 최종 상태 확인 중심이며, 다층 계측이 필요하면 리포트에서 `verify-data-flow` 호출을 제안하고 중복 구현하지 않음. `browser-visual-diff`↔`browser-visual-diff-capture` 패턴(슬롯 합의는 메인 루프, 실행은 스크린샷/콘솔 바이트 격리용 서브에이전트)을 그대로 재사용.
  - 6축 스킬 품질 체크리스트 전체 적용(신규 skill, blocking) — 정적 축(2·3·4·5·6) 확인 완료, 동적 축(1·6)은 서브에이전트 2건(AC 선별 케이스, devoks-browser 미설치 케이스)을 실제 실행해 description↔동작 일치 확인(둘 다 전 항목 PASS). 로컬 플러그인 소스 수정이 실행 세션에 반영되려면 push→marketplace update→재설치가 필요한 기존 갭(2026-07-20 기록) 때문에, 동적 검증은 설치된 스킬 트리거 대신 SKILL.md를 직접 따르게 하는 방식으로 수행.
  - **체크리스트 내 순서 재검토(같은 날 후속)**: 처음엔 표 맨 끝(8번, PR 이후)에 붙였다가, 커밋 전 검증이어야 한다는 지적으로 "요구사항→데이터 흐름→UI→코드리뷰" 뒤(항목 2)로 옮김 → "코드 리뷰는 정적·저비용이라 구조적 문제를 먼저 걸러야 라이브 검증(데이터 흐름·UI·실동작) 낭비가 없다"는 지적으로 코드 리뷰를 항목 2로 앞당김 → "`browser-visual-diff`는 Phase 5에서 레이아웃 상수·토큰 코드를 실제로 고치므로, 그 변경까지 반영된 최종 코드를 실동작 검증이 봐야 한다"는 지적으로 최종 순서를 **요구사항→코드리뷰→데이터 흐름→UI 시각 품질→브라우저 실동작 검증(커밋 직전 최종 게이트)→테스트 회귀→커밋→PR**로 확정. 원칙: 코드 변경을 유발할 수 있는 정적/라이브 검증은 앞에, "지금 커밋될 코드가 실제로 동작하는가"를 묻는 최종 확인은 그 모든 변경이 반영된 뒤 가장 마지막(커밋 직전)에 둔다.
  - 순서 재배치 과정에서 `feature-workflow-runner/SKILL.md`·`feature-plan-executor/SKILL.md`의 마무리 절 요약 문구("표준 메뉴" 나열)가 신규 항목을 빠뜨린 채 구 순서로 남아있던 실제 불일치를 발견해 수정. `verify-requirements`의 범위 선언("안 한다")에도 `verify-acceptance-test` 위임 문구를 대칭으로 추가(`1.0.0 → 1.0.1`) — `verify-data-flow`/`code-review-diff-branch`는 이미 있었는데 신규 항목만 빠져 있었음.
  - 반영: `skills/verify-acceptance-test/SKILL.md`(신규)·`references/scenario-execution.md`·`references/report-template.md`·`evals/evals.json`(신규), `agents/acceptance-test-runner.md`(신규), `plugin.json`(`dependencies`에 `devoks-browser` 추가), `skills/feature-workflow-runner/references/post-implementation-checklist.md`(항목 신설 후 순서 재배치·비고 갱신, 최종 위치는 항목 5), `skills/feature-frd-author/SKILL.md`(데이터 리얼리즘 EDGE case 가이드, `1.0.0 → 1.1.0`), `skills/feature-workflow-runner/SKILL.md`·`skills/feature-plan-executor/SKILL.md`(참조 문서 갱신 반영 + 마무리 절 요약 문구 정합, patch `1.4.0 → 1.4.1`), `skills/verify-requirements/SKILL.md`(범위 선언 대칭 추가, `1.0.0 → 1.0.1`), `README.md`/`docs/README.ko.md`/`.claude-plugin/marketplace.json`(스킬·에이전트·dependencies 카탈로그 반영, marketplace.json 플러그인 배열 순서도 devoks-browser가 devoks-sdlc보다 먼저 오도록 정렬).
  - 의도적으로 변경하지 않음: `verify-data-flow`(TEMP 규약·`env=browser` 이미 완비), `code-implementer.md`("dev server 실행 금지"와 정면 충돌 소지라 브라우저 검증을 그 안에 넣지 않고 별도 후속 단계로 유지).

- [x] **테스트 품질 기준(FIRST·결정성·안티패턴 등) ROI 선별 도입 — `test-author/references/test-quality-bar.md` 신설** (2026-07-22, `devoks-sdlc` `1.8.1 → 1.9.0`)
  - 배경: 사용자가 개인 테스트 규칙 문서(`docs/testing-rules.md`, 276줄 — FIRST/행위검증/결정성/AAA·GWT/테스트레벨/테스트더블/경계값분석/안티패턴/커버리지철학/사전체크리스트/JS·TS 도구부록)를 제공하고, "토큰비효율적이거나 실익 없는 룰은 배제, 전체 도입 금지"를 명시적으로 요구. Explore 조사 결과 `verify-requirements`/`code-review`/`code-security-review` 등 devoks-sdlc 어디에도 테스트 품질 관련 내용이 없어 클린 슬레이트였음.
  - **채택**: FIRST 원칙, 행위(behavior) vs 구현(implementation) 검증, 결정성(flaky 원인 5가지 — 시간/난수/동시성/네트워크·FS·DB/순서), AAA/네이밍, 테스트 레벨 결정 휴리스틱(Unit/Integration/E2E·Trophy·"자명한 코드는 테스트 안 함"), 케이스 설계(3종+경계값분석), 테스트 더블 규칙(상태검증 우선·3rd-party 직접mock금지·과도한mock금지), 금지 안티패턴(assertion없음·over-mocking·허수 테스트 등), 커버리지 철학(floor·branch&gt;line). **제외**: Red-Green-Refactor를 기본 워크플로로 도입 — 직전 `test:` 마커 신설 라운드에서 이미 결정한 "TDD 순서 강제는 토큰비용 대비 품질개선 근거 약함"과 모순되므로 유지. **채택(유일한 순서 예외)**: 버그 수정 시 재현 실패 테스트 우선(Anthropic 공식 권장과 일치, 이미 승인된 예외). Property-based/Contract/Mutation testing은 "프로젝트에 이미 해당 도구가 있을 때만" MAY로 1줄 압축, JS/TS 도구 부록은 "참고용·비강제"로 대폭 압축, 사전 제출 체크리스트(§10)는 `test-author`의 기존 완료 기준과 중복이라 독립 섹션으로는 도입하지 않고 병합.
  - SSOT는 신규 `skills/test-author/references/test-quality-bar.md`(116줄, 표·불릿 중심) 하나 — `code-implementer.md`·`test-run-triage/SKILL.md`·`PLAN.template.md`는 본문 복제 없이 포인터만 추가.
  - 버그 수정 예외를 실제로 트리거하려면 `test-author` 경로에 신호 전달 채널이 필요했음 — `test-author/SKILL.md`에 이미 선언돼 있었지만 `commands/test-author.md`·`agents/test-writer.md`가 전달하지 않던(죽어있던) `context` 파라미터를 엔드투엔드로 배선. `code-implementer`는 PLAN Task 원문(이미 읽는 텍스트)에서 버그 수정 키워드를 직접 스캔 — 별도 마커 신설 없이 오버엔지니어링 방지.
  - `test-run-triage`의 플래키 근본원인 추정 절에 결정성 원인표를 1차 체크리스트로 연결(포인터만, 중복 없음). `PLAN.template.md` §5 DoD의 "핵심 비즈니스 로직 테스트 통과"에 품질 기준 참조를 추가.
  - 반영: `skills/test-author/references/test-quality-bar.md`(신규), `skills/test-author/SKILL.md`(`metadata.version` `2.0.1 → 2.1.0`), `commands/test-author.md`, `agents/test-writer.md`, `agents/code-implementer.md`, `skills/test-run-triage/SKILL.md`(`metadata.version` `1.0.0 → 1.1.0`), `skills/feature-workflow-runner/assets/PLAN.template.md`, `plugin.json`.
  - 6축 스킬 품질 체크리스트: 정적 축 적용 — 축2(참조 실존) 확인 완료, 축3(`evals/evals.json`)은 `test-author`/`test-run-triage` 둘 다 기존 공백(이번 변경으로 새로 생긴 것 아님, 별도 로드맵 항목 "evals 하니스 확대" 범위), 축4(MCP 의존 없음), 축5(플러그인 루트 밖 참조 없음) 확인 완료. 동적 축(1·6)은 트리거 조건(description) 불변이라 권장 단계로 생략.

- [x] **PLAN Task에 `test`(required/skip) 마커 신설 — `code-implementer`의 "로직 Task는 테스트 동반" 암묵 판단을 PLAN 저작 단계 명시 마커로 이관** (2026-07-22, `devoks-sdlc` `1.7.0 → 1.8.1`)
  - 배경: 위 "경량 구현/리팩토링 커맨드 테스트 연동" 작업 직후, `code-implementer`(FRD/PLAN 정식 경로)가 테스트를 작성하는 조건이 "로직 Task"라는 미정의 개념 하나뿐이고 스킵 경로가 없다는 점을 재점검함. `new-feature-draft`에는 "규모가 작거나 순수 UI/설정 변경이면 사용자 확인 후 생략"이라는 명시적 조건을 넣었는데, PLAN 경로엔 `size`(S/M/L)처럼 PLAN 저작 시점에 고정되는 마커가 없어 `code-implementer`가 실행 중 매번 암묵적으로 재판단해야 했음 — `task-pr-splitting.md`엔 "테스트는 로직 Task에 동반 가능"이라는 느슨한 문장뿐, 판정 기준 자체가 문서화돼 있지 않았음.
  - `code-implementer`는 금지 사항상 실행 중 사용자에게 질문할 수 없으므로, `new-feature-draft`와 동일한 "사용자 확인 후 스킵" 패턴은 이식 불가 — 대신 `size`와 같은 논리로, 사용자 승인이 있는 PLAN 저작 단계(`feature-plan-author`)에서 결정을 확정하고 `code-implementer`는 마커를 그대로 따르기만 하도록 결정.
  - `size`와 나란히 `test`(required 기본값 / skip) 마커 신설 — 부여 기준 SSOT는 `task-pr-splitting.md`(비즈니스 로직·상태 전이·데이터 흐름·계약 검증·조건부 분기 포함 시 `required`, 순수 타입/상수·마크업/스타일링·설정값·문서만이면 `skip`). 애매하면 `size`(기본값 `M`)와 반대 방향으로 `required`를 기본값으로 둠 — 여기서는 테스트 과다 작성이 누락보다 안전.
  - 반영 범위: `feature-plan-author/SKILL.md`(Task 필드·완료기준·`test` 분포 자기점검, `metadata.version` `1.1.0 → 1.2.0`), `task-pr-splitting.md`(Task 필드 형식·`test` 마커 부여 기준 절 신설), `task-delegation.md`(리포트 스키마의 "로직 Task 추가" → "`test: required` Task 추가"), `PLAN.template.md`·`example-walkthrough.md`(Task 예시에 `test:` 필드 반영), `code-implementer.md`(Step 4 — 마커 기계적 준수로 문구 교체), `feature-plan-executor/SKILL.md`·`feature-workflow-runner/SKILL.md`(리포트 처리 문구의 "로직 Task" → "`test: required` Task", `metadata.version` 각각 `1.3.0 → 1.4.0`).
  - `devoks-sdlc` 전체에서 "로직 Task" 문구가 남아 있지 않은지 grep으로 교차 확인 완료(cross-reference 많은 플러그인이라 하나만 고치면 어긋나기 쉬워 — `workflow-checklist.md` devoks-sdlc 특수 케이스 참고).
  - **재검증(같은 날 후속, `1.8.0 → 1.8.1`, patch)**: `/devoks-plugin-maintenance`로 재점검한 결과 두 가지 실제 갭을 발견해 수정.
    1. `test:` 마커 관련 지시가 `code-implementer.md`(위임 경로)에만 있고, `size: S`로 메인 루프가 **직접 구현**하는 경로에는 마커 준수 지시가 없었음(`size`의 "직접 구현 시에도 절차 동일" 문구를 test에도 확장하지 않은 채 남겨둠). → `task-delegation.md` "직접 구현 시에도 절차..." 문구에 `test:` 마커 준수를 포함해 해소.
    2. `size`의 "마커 없음(구버전 PLAN) → M으로 간주"와 대칭되는 `test` 쪽 fallback("마커 없음 → ?")이 누락돼 있었고, `test: skip`인데 구현 중 실제 로직이 드러나는 런타임 불일치 처리도 없었음 → `task-delegation.md`에 "런타임 보정(test)" 항목 신설(마커 없으면 `required` 간주, `skip`인데 로직 발견 시 차단 대신 최소 테스트 작성 + 인계 노트 flag), `code-implementer.md` Step 4에도 동일 지시 반영.
    3. `task-pr-splitting.md`의 `test` 마커 절에 "완료 후 코드 리뷰·`test-run-triage`에서 재확인 대상"이라는 문장이 있었으나, 실제로 `code-review`/`test-run-triage` 어느 스킬도 `test:` 마커를 참조하지 않아 **존재하지 않는 검증 안전망을 주장하는 과장**이었음(grep으로 확인) → 실제 안전망(`code-implementer` 자체의 런타임 보정)을 가리키도록 문구 수정, 외부 재검증은 "범위 밖"으로 명시.
      - field-position 의존 파싱 충돌 여부도 점검 — `traceability.md`의 커버리지 스크립트는 정규식으로 ID만 추출해 필드 순서 무관하므로 `test:` 필드 삽입과 충돌 없음 확인.
      - 반영: `task-delegation.md`, `code-implementer.md`, `task-pr-splitting.md`, `plugin.json`. `feature-plan-author`/`feature-plan-executor`/`feature-workflow-runner`의 `SKILL.md` 본문 자체는 이번 라운드에서 안 건드려 `metadata.version` 변경 없음.

- [x] **경량 구현/리팩토링 커맨드에 테스트 작성·회귀검증 연동 — `new-feature-draft`·`code-refactoring`** (2026-07-22, `devoks-sdlc` `1.6.0 → 1.7.0`)
  - 배경: `test-run-triage`(실행+triage 전용, 새 테스트 작성 안 함) 논의 중, 구현 계열 커맨드가 실제로 테스트를 어떻게 다루는지 점검한 결과 셋으로 갈렸음 — `code-implementer`(FRD/PLAN 정식 경로)는 이미 Step 4에서 인라인으로 테스트를 동반 작성하지만, `new-feature-draft`(경량 기능 구현)는 테스트를 "추후 작업" 안내 문구로만 흘려보내고 실제로 작성하지도 `test-author`로 위임하지도 않았고, `code-refactoring`은 "동작 불변"을 원칙으로 내세우면서 이를 검증할 테스트 실행/보강 연결이 없었음.
  - `code-implementer`는 의도적으로 변경하지 않음 — `tools:` 프론트매터에 Agent/Task 도구 자체가 없어 `test-writer` 서브에이전트 위임이 구조적으로 불가능하고, 이미 subagent 내부라 컨텍스트 격리 이득도 없어 인라인 작성 유지가 더 저렴하다고 판단.
  - `new-feature-draft.md`: Step 4(구현)와 Step 6(마무리, 기존 5) 사이에 Step 5 "테스트 작성(조건부)" 신설 — 로직 포함 시 `devoks-sdlc:test-author`(`test-writer` 에이전트)로 위임, 규모가 작거나 순수 UI/설정 변경이면 사용자 확인 후 생략 가능. 마무리 안내 문구도 "테스트 생략 시 사실·사유 명시"로 갱신(No Silent TODO 원칙).
  - `code-refactoring.md`: Step 5(검증 및 마무리)에 "동작 불변 검증" 서브섹션 추가 — 기존 테스트 있으면 `devoks-sdlc:test-run-triage`로 회귀 확인, 커버리지 없으면 `devoks-sdlc:test-author` 보강을 제안(적용은 사용자 결정).
  - 두 커맨드 모두 대상이 `commands/*.md`이지 `SKILL.md`가 아니라 `devoks-plugin-maintenance`의 6축 스킬 품질 체크리스트(§7) 적용 대상 아님 — 정적/동적 검증 생략은 공백이 아니라 적용 대상 자체가 아니기 때문.
  - 반영: `commands/new-feature-draft.md`, `commands/code-refactoring.md`, `plugin.json` 버전. README/README.ko/marketplace.json은 두 커맨드의 이름·한 줄 설명이 불변이라 비대상.

- [x] **구현 완료 후 다음 단계 체크리스트 신설 — `feature-workflow-runner`/`feature-plan-executor` 마무리 절에 표준 후속 메뉴 추가** (2026-07-21, `devoks-sdlc` `1.5.0 → 1.6.0`)
  - 배경: 구현(Phase 3/태스크 실행) 이후 `verify-requirements`·`verify-data-flow`·`code-review-diff-branch`·`test-run-triage`·커밋·PR로 이어지는 표준 후속 흐름을 능동적으로 제시하는 장치가 없어, 에이전트가 그때그때 기억에 의존해 제안하거나 누락하는 문제가 있었음. `code-review`가 이미 갖춘 "Critical/High 보안 이슈 시 `code-security-review` 권장" 에스컬레이션 패턴(2026-07-20 반영)을 구현 완료 시점으로 확장.
  - `feature-workflow-runner`/`feature-plan-executor` 공유 SSOT로 `feature-workflow-runner/references/post-implementation-checklist.md` 신설 — 요구사항 구현 충실도 재확인(항상)/데이터 흐름 검증(조건부)/UI 시각 품질 확인(조건부)/코드 리뷰(항상)/테스트 스위트 회귀(조건부)/커밋/PR 7항목 표준 메뉴 + `🚀 다음 단계 제안` 출력 형식.
  - 요구사항 검증 항목은 `verify-requirements mode=verify spec=[[ORCA_RICH_MD:cebdf985fb4e1f8d51781f7c96ec2366:inline-html:%3Cout%3E]]/FRD.md`로 한정하고 `mode=checklist`(별도 체크리스트 파일 생성)는 생략 — FRD §3/§5/§8이 이미 F(기능)/B(비즈니스로직)/E(엣지케이스)/D(데이터계약) 카테고리에 ID로 대응돼 중복이기 때문. 단, U(UI/UX 세부)는 FRD §4가 아키텍처 구조 중심이라 대응이 약해 이 항목의 범위 밖으로 명시하고 위 "UI 작업 분리 검토" 항목으로 연결(근거 보강 참고).
  - 두 스킬 모두 Phase 4 / "마무리" 절 끝에 이 체크리스트를 **출력만** 하도록 절차 문구 추가 — 실행은 여전히 사용자 확인 후(HITL 유지, 자동 실행은 `devoks-sdlc-orchestration` 로드맵 항목의 책임 범위와 역할 분리).
  - 반영: `skills/feature-workflow-runner/SKILL.md`(references 표·Phase 4·`metadata.version` `1.2.0 → 1.3.0`), `skills/feature-plan-executor/SKILL.md`(마무리 절·`metadata.version` `1.2.0 → 1.3.0`), `plugin.json` 버전.
  - 6축 스킬 품질 체크리스트는 "기존 skill 변경"(워크플로 단계 추가) 기준으로 적용 — 정적 축(2/3/4/5)만 확인, 동적 축(1/6)은 권장 단계라 이번 변경(마무리 절 안내 문구 추가, 트리거 조건 불변)에서는 생략. `feature-plan-executor`는 `evals/evals.json` 미보유 상태 유지(기존 공백, 이번 변경으로 새로 생긴 문제 아님 — "evals 하니스 확대" 항목 범위).

- [x] **스킬 평가/검증 워크플로우 보강 — `devoks-plugin-maintenance`에 6축 스킬 품질 체크리스트 추가** (2026-07-20, 로컬 skill `metadata.version` `0.1.0 → 0.2.0`)
  - 기존 유지보수 스킬(독립 스킬 신설 대신)에 신규/변경 스킬 한정 게이트로 통합 — Step 1에 신규 skill 생성·description/핵심 동작 변경 신호 추가, Step 4에 6축 체크리스트 서브섹션 신설, Step 8 리포트 항목 추가.
  - 6축: ① description↔실제 동작 일치(효용성 포함, 신규 skill은 evals 프롬프트 서브에이전트 실행 기반 동적 검증 필수) ② `references/` 존재 ③ `evals/evals.json` 보유(신규 skill blocking) ④ 의존 MCP/도구 명시(기존 Step 6 재사용) ⑤ 설치 후 경로 참조 안전성 ⑥ 토큰효율성(정적 휴리스틱 + 동적 실행 시 토큰/턴수 관찰, 신규 축으로 신설).
  - 설계 논의로 확정된 사항: "효용성"은 별도 축이 아니라 축 1(description-동작 일치)에 흡수(SSOT/DRY 위반 방지), "토큰효율성"은 axis 1과 판정 대상이 달라(정확성 vs 비용) 별도 6번 축으로 분리, 신규 스킬은 동적 검증(실제 서브에이전트 실행)을 생략 불가로 강제.
  - 반영: `.claude/skills/devoks-plugin-maintenance/SKILL.md`(Step 1/4/8, `metadata.version`), `references/workflow-checklist.md`(§7 신설), `evals/evals.json`(id 6 케이스 추가), `docs/plugin-management.md`(maintainers 로컬 skill 설명 갱신).
  - 적용 범위는 신규/변경 스킬로 한정 — 기존 12개 스킬의 `evals`/`references` 공백 소급 채우기는 별도 백로그("evals 하니스 확대" 항목)로 유지, 이번 스코프 밖.

- [x] **code-review ↔ code-security-review 역할 경계 강화 — 보안 에스컬레이션 규칙 + 상호 참조 + finding 필드 정합** (2026-07-20, `devoks-sdlc` `1.4.0 → 1.5.0`)
  - `code-review` 스킬에 "🔒 보안 점검 요약에서 Critical/High 발견 시 `🚀 다음 액션 제안`에 `/devoks-sdlc:code-security-review` 실행을 권장 문구로 명시" 에스컬레이션 규칙 추가 — 경량 스크리닝에서 걸린 문제를 심층 검증으로 안내하는 연결고리 신설.
  - `code-review/SKILL.md` "참고 기준 문서"에 `code-security-review` 역참조 추가 — 기존엔 `code-security-review → code-review` 단방향 참조만 존재했음.
  - `code-security-review`의 finding 템플릿(Critical~Low)에 `재현/검증 방법`·`후속 테스트 필요` 필드 추가 — 앞선 `code-review` 필드 확장과 정합.
  - 반영 전 `code-reviewer`/`code-security-reviewer` 에이전트를 실제 대상(`plugins/devoks-core/hooks/check-setup-state.sh`, `plugins/devoks-core`)에 스모크 테스트해 두 스킬의 내부 로직 자체는 문제없이 동작함을 확인. 그 과정에서 **로컬 플러그인 소스 수정이 실행 중인 세션에 반영되려면 push → `claude plugin marketplace update` → 재설치가 필요**하다는 배포 구조를 발견함(플러그인 캐시는 `~/.claude/plugins/cache/devoks-plugins/devoks-sdlc/[[ORCA_RICH_MD:8472e27ef20562008f339ef2780b47db:inline-html:%3Cversion%3E]]/`에 버전 스냅샷으로 존재하고, marketplace clone(`~/.claude/plugins/marketplaces/devoks-plugins`)은 GitHub remote(`ridsync/devoks-team-harness`)를 추종할 뿐 로컬 워킹디렉토리를 직접 참조하지 않음) — 향후 플러그인 변경 후 "실제 실행으로 검증"을 계획할 때 이 갭을 먼저 감안할 것.
  - 반영: `skills/code-review/SKILL.md`(`metadata.version` `1.1.0 → 1.2.0`), `skills/code-security-review/SKILL.md`(`metadata.version` `1.0.1 → 1.1.0`), `plugin.json` 버전.

- [x] **코드 리뷰 워크플로우 개선 — 5항목 필수 체크리스트 + 체크리스트 커버리지 섹션 + finding 필드 확장** (2026-07-20, `devoks-sdlc` `1.3.2 → 1.4.0`)
  - `code-review` 스킬(Step 3)에 "잠재적 버그 / 예외 처리 / 성능 / 보안 / 가독성" 5개 필수 체크리스트를 로컬로 추가 — 공유 SSOT(`devoks-core/refs/code-review.md`의 Layered Examination)는 변경하지 않고, 그 5단계를 빠뜨리지 않고 확인했는지 확정짓는 실행 게이트로 별도 배치(`code-security-review` 등 다른 SSOT 소비자에 영향 없음, core-sync 점검 불필요 — 논의 후 결정).
  - 출력 템플릿에 `✅ 체크리스트 커버리지` 섹션을 신설(5축 확인 결과를 리포트 상단에 가시화), Critical/High/Medium/Low 4개 등급 finding 템플릿 전체에 `재현/검증 방법`·`후속 테스트 필요` 필드 추가.
  - 반영: `skills/code-review/SKILL.md`(체크리스트·출력 템플릿·`metadata.version` `1.0.1 → 1.1.0`), `commands/code-review-general.md`·`code-review-diff-branch.md`(pass-through 금지 목록 필드 갱신), `plugin.json` 버전.
  - 심각도 분류 SSOT를 4개 스킬(`code-review`·`code-security-review`·`verify-requirements`·`test-run-triage`)에 걸쳐 통합하는 일은 별도 "중" 우선순위 항목("심각도 분류 SSOT 통합")으로 분리 유지 — 이번 작업 범위 밖.

- [x] **컨벤션 preset management 고도화 — hash 기반 stale 감지 + 플러그인 루트 번들링 버그 수정** (2026-07-14, `devoks-core` `1.1.4 → 1.2.0`)
  - 선행 발견·수정: `shared/conventions/`가 `plugins/devoks-core/` **바깥**(저장소 루트)에 있어 이 저장소 자신의 "플러그인 루트 외부 참조 금지" 규칙을 위반 — 실제 설치된 대상 프로젝트에서는 `/devoks-core:setup-project-convention`이 참조하는 preset 원본에 접근할 방법이 전혀 없었다(harness 저장소 자신의 워킹디렉토리에서만 우연히 동작). `shared/conventions/*` → `plugins/devoks-core/conventions/`로 이전하고 `${CLAUDE_PLUGIN_ROOT}/conventions/[[ORCA_RICH_MD:8472e27ef20562008f339ef2780b47db:inline-html:%3Cpreset%3E]]/...`로 참조하도록 전환(공식 문서 확인: `${CLAUDE_PLUGIN_ROOT}`는 skill/command 본문·Bash 실행 컨텍스트에도 inline 치환됨). `shared/setup/`·`shared/templates/`는 `setup.sh`에서만 참조되어 같은 문제가 없어 이동 대상에서 제외.
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

