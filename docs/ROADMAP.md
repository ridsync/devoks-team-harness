# Roadmap — 추후 개선 사항 (TODO)

DevOKs 하네스의 플러그인 구조·내용 개선 후보를 모아두는 단일 SSOT 문서.
양 언어 README는 이 문서를 링크만 한다(이중 관리 drift 방지). 완료 이력은 [`CHANGELOG.md`](CHANGELOG.md).

> 최종 갱신: 2026-10-29

---

## 우선순위 한눈에


| 우선순위   | 항목                                                                                                                                          |
| ------ | ------------------------------------------------------------------------------------------------------------------------------------------- |
| **높음** | UI 작업 분리 검토 · `devoks-sdlc-orchestration` 신설(비-HITL SDLC)                                                                                   |
| **중**  | 컨벤션 preset 확장(신규 stack) · Android·iOS 네이티브 확장(`devoks-android`·`devoks-ios`) · `metro-devtools-attach` |
| **낮음** | `devoks-release` 신설 · Operate/Maintain 단계 · `code-security-review` 시크릿 패턴 카탈로그                                                              |


---

## 마이그레이션 / 구조

- [ ] **컨벤션 preset 확장 (신규 stack)**
  - management 고도화(provenance hash 기반 stale 감지, 플러그인 번들링 버그 수정)는 2026-07-14 완료 — 완료 섹션 참고.
  - `python-fastapi` preset 추가는 2026-09-15 완료 — 완료 섹션 참고.
  - 남은 범위: `react-web`·`react-native`·`android`·`ios`·`python-fastapi` 5개 외 `nextjs`, `node-backend`, `spring`, `swiftui-only`, `compose-only` 등 세분 preset 추가.
  - 우선순위: 낮음(management 인프라는 갖춰졌으니 실제 수요가 생길 때 진행 — blocking 이슈 없음).

- [ ] **Android·iOS 네이티브 확장 — `devoks-android`·`devoks-ios` 신설 + 스택 중립 계층 보강**
  - 배경(2026-10-23 검토): preset(`conventions/android|ios`)과 감지 규칙은 이미 있으나, 실행·검증 계층이 웹(Chrome 9269)·RN(Metro)·`package.json`에 결합돼 있다. 방향은 **sdlc/git/core는 스택 중립 유지 + 네이티브 도구는 별도 플러그인**(`devoks-rn`·`devoks-browser`와 같은 모델) — sdlc 스킬을 네이티브용으로 fork하지 않는다.
  - **확정 결정**: ① 플러그인은 `devoks-android`/`devoks-ios` **분리**(툴체인·MCP가 서로 겹치지 않고 iOS는 macOS 전제) ② 모바일 acceptance runner는 **`devoks-sdlc`에 위치**(스킬 계약 SSOT가 sdlc) ③ 기기 UI 구동 드라이버는 **mobile-mcp(`@mobilenext/mobile-mcp`)를 우선 후보로 선정**하되 외부 도구 채택 게이트(실측 효용성)를 통과한 뒤 최종 결정 — XcodeBuildMCP·Xcode 내장 MCP(`xcrun mcpbridge`, 26.3+)·Maestro(`maestro mcp`)는 재검토 대상으로 보류. MCP는 번들하지 않고 `setup-mcp`에서 user scope 등록(`devoks-browser` 2.0.0과 동일 원칙).
  - **P0 — 스택 중립 보강(저비용)**:
    - `setup-project-convention` 감지: RN 프로젝트에도 `android/`·`ios/`가 있어 네이티브로 오추천될 수 있음 → `package.json`에 `react-native`가 있으면 RN 우선 규칙 추가.
    - refs `scope` 다중값 지원(현재 `scope: react-web` 단일) → `refs/mobile-security.md`(OWASP MASVS/MASTG 기반)를 `android`·`ios`·`react-native`가 공유. `check-setup-state.sh`·`setup-preset-manage` 판정 동반 수정.
    - `refs/code-review.md` 파일 패턴 표(`*.jsx`/`*.tsx`만 존재)에 `*.kt`·`*.swift`·`AndroidManifest.xml`·`Info.plist`/`*.entitlements` 행 추가. lint/type 선행검증에 Android Lint·detekt·ktlint·SwiftLint·컴파일 검사.
    - `test-author`/`test-run-triage`: Gradle(JUnit5, `test/` vs `androidTest/`)·`xcodebuild test`/`swift test` 감지, JUnit XML·`.xcresult` 파싱, 플래키 "기기·에뮬레이터" 범주.
    - `code-security-review`: Gradle·SwiftPM 의존성 audit(도구 실측 후 선정).
    - `new-smoke-test-draft` 휴리스틱: Compose Navigation(`NavHost`·`composable(`)·iOS `NavigationStack`/`navigationDestination` 누락분 추가. `verify-data-flow` 계측 예시에 `Log.d`/Timber·`os.Logger` + `adb logcat`/`simctl … log stream` 수집.
    - `new-ui-draft`: iOS는 Figma 플러그인의 `figma:figma-swiftui` 라우팅, `DESIGN.md` 토큰 → Material3 Theme/Asset Catalog 매핑.
    - `devoks-git`: 민감파일 점검에 `local.properties`·`*.keystore`/`*.jks`·`GoogleService-Info.plist`·`xcuserdata/`.
  - **P1 — 플러그인 신설**: `devoks-android`(`android-device-debug`·`android-build-triage`), `devoks-ios`(`ios-simulator-debug`·`ios-build-triage`). build-triage는 대용량 빌드 로그 격리를 위해 skill→agent 승격 구조. `setup-mcp`에 mobile-mcp 선택 단계, 공식 `kotlin-lsp`/`swift-lsp` 플러그인 안내.
  - **P2 — 실동작 검증**: `verify-acceptance-test` Phase 0에 **검증 드라이버 슬롯**(browser | mobile) 추가 + 모바일 runner agent 신설(agent `tools` frontmatter가 정적이라 `acceptance-test-runner`와 분리, `model: sonnet`). 영속 상태 대조는 `adb shell run-as … sqlite3`·`simctl get_app_container`. 현재 description의 `"실기기/에뮬레이터 확인"` 트리거는 Chrome 전용 동작과 어긋나는 오트리거였다 — 2026-10-23 `devoks-sdlc` 3.9.0에서 트리거를 제거하고 "웹앱 전용"을 명시해 정리함(아래 완료 항목 참고). `devoks-sdlc-orchestration` 실동작 allowlist(`localhost`+`9269`)에 기기 감지 프로브 추가.
  - **P3 — 출시·운영**: `android-release-check`(서명·R8·`exported`·target API), `ios-release-check`(Info.plist 사용 목적 문구·`PrivacyInfo.xcprivacy`·entitlements·ATS), Crashlytics MCP 연동(선택), Maestro 기반 스모크(재검토 결과에 따름).
  - 관련 항목: `metro-devtools-attach` iOS 시뮬레이터 검증(품질/유지보수) — adb/simctl 캡처 로직이 네이티브 플러그인과 중복되므로 P1 착수 시 경계 정리.
  - 우선순위: 중(P0는 스택 중립 개선이라 선행 가능, P1~ 는 mobile-mcp 실측 후).

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
  - **의존성 후보**: `devoks-core`, `devoks-git`, `devoks-sdlc`(스킬 참조 또는 soft dependency). `devoks-browser`는 더 이상 transitive 의존이 아니다(devoks-sdlc 3.8.0에서 `dependencies` 제거 — `verify-acceptance-test`가 필요한 것은 플러그인이 아니라 `chrome-devtools-attach` MCP이고 visual diff 호출은 조건부이기 때문). 필요한 MCP는 `/devoks-core:setup-mcp`가 설치한다.
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

## 완료 이력 · 결정 기록

완료된 항목과 폐기·기각 결정은 [`CHANGELOG.md`](CHANGELOG.md)로 옮겼다(2026-10-29). 이 문서에는 **열린 항목만** 둔다 — 항목을 끝내면 여기서 지우고 CHANGELOG에 배경·반영·검증·의도적 미반영과 함께 기록한다.

**재제안 전 확인할 결정** (상세는 CHANGELOG의 해당 날짜 항목):
- 2026-10-23 · `verify-visual-diff` 이전 폐기 — 시각 diff는 브라우저 관심사라 `devoks-browser`에 둔다
- 2026-09-18 · context-mode 도입 기각 + 기존 전제 전량 제거 — 「실행환경 계층 흡수」 항목
- 2026-08-21 · 4개 항목 폐기 — 카탈로그 자동 생성 · evals 하니스 확대 · `git-commit-msg` 스킬+haiku 위임 전환 · `git-create-issue`/`git-pull-request` 스킬 전환
- 2026-08-19 · `engineering-principles.md`에 Coalesced Effects 원칙 추가 기각 — 「반복·동시 트리거 정합성 커버리지 신설」 항목
