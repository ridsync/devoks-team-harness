# Roadmap — 추후 개선 사항 (TODO)

DevOks 하네스의 플러그인 구조·내용 개선 후보를 모아두는 단일 SSOT 문서.
양 언어 README는 이 문서를 링크만 한다(이중 관리 drift 방지).

> 최종 갱신: 2026-07-30

---

## 우선순위 한눈에


| 우선순위   | 항목                                                                                                                                                                                     |
| ------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **높음** | UI 작업 분리 검토 · `**devoks-sdlc-orchestration` 신설(비-HITL SDLC)**                                                                                                                          |
| **중**  | 컨벤션 preset 확장(신규 stack) · `browser-visual-diff` 이전 · `metro-devtools-attach` · 카탈로그 자동 생성 · evals 하니스 확대 · 심각도 분류 SSOT 통합 · FRD §4 임계 신호 SSOT 수렴 · MCP 버전 고정 검토 · MCP 가이드 이중 관리 정리 · MCP project-scope 표준화 검토 · `git-commit-msg` 스킬+haiku 위임 전환 검토 |
| **낮음** | 구현자 세션 지속(continuation) · 진입점 일관화 · `devoks-release` 신설 · Operate/Maintain 단계 · `code-security-review` references 보강 · plugin 버전 메타 정합 · `git-create-issue`/`git-pull-request` 스킬 전환 검토                                                 |


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

- [ ] **`git-commit-msg` 커맨드 → 스킬 전환 + haiku 서브에이전트 위임**
  - 배경(2026-07-29): 커밋 메시지 작성은 SSOT(`.claude/refs/git-convention.md`) 기반 포맷팅 위주 작업이라 모델 지능보다 컨텍스트 처리 방식이 비용을 좌우함 — 메인 에이전트 모델을 토글하면 누적 대화의 prompt cache가 전부 깨지므로(스위치 왕복 2회 = cache miss 2회), 별도 서브에이전트(non-fork, `model: haiku`)에 diff+SSOT 요약만 작은 컨텍스트로 넘기는 쪽이 더 저렴할 것으로 판단.
  - 주의점:
    1. fork 타입은 `model` override가 무시되므로(부모 모델 강제 상속) 반드시 non-fork/`general-purpose` 계열로 구성.
    2. 커밋은 git-write 액션 — "사용자 명시 요청 시에만" 원칙과 SSOT의 "사용자 확인 후 커밋" 요건이 스킬 전환 후에도 그대로 지켜져야 한다. 스킬은 자연어 description 매칭으로 auto-trigger될 수 있어 커맨드보다 오발동 리스크가 크므로, description·본문에 explicit-invoke 전제(또는 최소 확인 게이트)를 baked-in할 것.
    3. 신규/변경 스킬 품질 체크리스트(축1 — `evals/evals.json` 동적 실행)로 haiku가 Conventional Commits 포맷·타입 매핑·footer 규칙(Agent 서명 등)을 안정적으로 지키는지 먼저 검증 — 실패율이 높으면 sonnet 유지로 되돌린다.
  - 관련: 아래 이슈/PR 스킬 전환 항목(짝 항목이나 리스크 수준이 달라 별도 판단), 위 "진입점 일관화 검토" 항목(상위 정책과 연결).
  - 우선순위: 중(비용 실측·eval 검증 선행 과제).

- [ ] **`git-create-issue`/`git-pull-request` 커맨드 → 스킬 전환**
  - 배경(2026-07-29): 위 `git-commit-msg` 스킬 전환 논의와 함께 나온 짝 항목.
  - 커밋과 달리 haiku 서브에이전트 위임은 별도 판단 필요 — 이슈 생성은 label/assignee/issue-type MCP 검증 순서, `### Additional Context` 단일 블록 blockquote 연속 규칙 등 지침이 촘촘해 작은 모델의 실패(재시도) 비용이 커밋보다 클 수 있다. "커맨드→스킬 전환"(진입점 변경)과 "haiku 위임 여부"(모델 변경)를 분리해서 검토할 것.
  - 우선순위: 낮음(`git-commit-msg` 스킬 전환·eval 검증 결과를 먼저 보고 착수).

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
   Slack/webhook   스펙 자동보완    병렬 라우팅   (continuation)    data-flow   security      merge?   최종 요약
  ```
  - **트리거(Intake)**: 외부 이슈·라벨·assignee·우선순위를 RUN(실행 단위)으로 매핑. 입력이 빈약하면 템플릿·과거 유사 이슈·코드베이스 스캔으로 스펙 보완(추측 상한·에스컬레이션 규칙 필수).
  - **Plan**: `devoks-sdlc`의 FRD/PLAN·`traces`·PR 분리 규칙을 **재사용**하되, 승인 게이트 제거·`status` 전환 자동화. RUN 메타(`run-id`, `issue-ref`, `policy-version`)를 frontmatter에 고정.
  - **Implement**: `code-implementer` + continuation(도입 후) + `size` 라우팅. 브랜치 생성·이슈 링크는 사전체크 확인 없이 **정책 기본값** 적용(`devoks-git` 연동).
  - **Verify**: 검증 체인 순서는 `post-implementation-checklist.md`가 SSOT(요구사항→코드리뷰→데이터흐름→UI 시각품질→브라우저 실동작 검증→테스트 회귀). `verify-acceptance-test`(실동작)는 dev server+Chrome(9269) 감지 시 커밋 직전 직렬 게이트, 미감지 시 draft PR 플래그로 위임(D6). 실패 시 자동 수정 루프 상한 N회 후 에스컬레이션.
  - **Review**: `code-review`, `code-security-review` — 심각도 임계 초과 시 PR draft 유지·머지 차단.
  - **Deliver**: Conventional Commits 커밋, PR 본문(추적성·테스트·리스크), CI 워크플로 트리거. `devoks-release`와 경계 협의(릴리스 vs 기능 PR).
  - **Report**: RUN 종료 리포트(성공/부분/실패), 이슈·Slack에 요약·아티팩트 링크. 중간 Phase 리포트는 생략·이벤트 스트림으로 대체.
  #### `devoks-sdlc`와의 관계
  - **공유**: 에이전트(`code-implementer`, `code-reviewer`, `code-security-reviewer`), 스킬 자산(PLAN/FRD 템플릿, `task-delegation`, `traceability`, 검증·리뷰 스킬), 심각도 SSOT.
  - **분리**: 오케스트레이터 스킬/커맨드(`orchestration-workflow-runner` 등), RUN 상태 스키마, 트리거·웹훅·권한(쓰기·PR·머지), 에스컬레이션·재시도 정책, 외부 MCP/CLI 어댑터.
  - **의존성 후보**: `devoks-core`, `devoks-git`, `devoks-sdlc`(스킬 참조 또는 soft dependency). `devoks-browser`는 `verify-acceptance-test`(1.10.0에서 devoks-sdlc가 `dependencies`로 선언) 및 visual diff를 통해 **transitive 의존**.
  #### 단계적 도입 (제안)
  
  | 단계            | 범위                                             | 산출                                  |
  | ------------- | ---------------------------------------------- | ----------------------------------- |
  | **0 — 정책**    | 자동화 허용 범위·금지 경로(시크릿·인프라·DB 마이그레이션)·에스컬레이션 연락처  | 정책 SSOT `plugins/devoks-sdlc-orchestration/references/orchestration-policy.md` (`policy-version 0.2.0`, 번들 단일본) |
  | **1 — MVP**   | 수동 트리거 1건: 이슈 URL → 브랜치·구현·테스트·draft PR·요약 리포트 | `devoks-sdlc-orchestration` **0.2.0 저작 완료**(2026-07-23): `orchestration-run` 스킬 + `pipeline.md` + 정책 번들. validate ✔. 크로스-플러그인 호출은 post-publish 스모크 대기 |
  | **2 — 검증 강화** | 리뷰/보안/요구사항 게이트·재시도(2회)·`blocked` 자동 분류 **저작 완료**(pipeline.md Stage 4) | 이슈 코멘트/Slack 어댑터 배선은 단계 3(MVP 콘솔 fallback) |
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

- [ ] **FRD §4 복잡도 임계 신호 목록 SSOT 수렴**
  - 임계 신호 목록이 **4곳에 인라인 복제** 중: `feature-workflow-runner/references/design-spec.md`(SSOT) · 같은 스킬 `SKILL.md`(핵심 원칙 절) · `feature-frd-author/SKILL.md`(절차 6) · `assets/FRD.template.md`(§4 안내 주석).
  - 2026-07-30 임계 보강(신호 1개 추가 + 한정구 1개)에서 4곳을 모두 손으로 동기화해야 했다 — 성공했지만 drift 표면이 그만큼 넓다는 것이 확인됐다. `심각도 분류 SSOT 통합`과 동일 성격의 문제.
  - 검토 방향: 미러 3곳의 나열을 제거하고 "복잡도 임계 초과 시(신호 목록: `design-spec.md`)" 수준의 포인터만 남긴다. 단, 미러가 존재하는 이유(각 문서를 단독으로 읽는 사람이 임계를 즉시 알 수 있게)를 잃지 않는 선인지 판단이 필요하다 — 전면 제거 vs 축약 표기 유지 중 선택.
  - 우선순위: 중(당장 깨지지 않았으나 다음 임계 변경에서 누락 위험이 반복됨).

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

- [x] **harness 유지보수 체크표(`workflow-checklist.md`) §4 devoks-sdlc 절 사실 정정** (2026-07-30, 플러그인 번들 외부 — 버전 bump 비대상)
  - 위 `size` 개정의 커밋 전 자체 재감사 중 발견. 이 문서는 devoks-sdlc 변경 시 "영향 범위가 가장 넓다"고 경고하는 근거인데 두 곳이 틀려 있었다.
  - ⑴ **수치 drift**: "skill 10 + command 8 + agent 2"로 기재됐으나 실제는 skill 11 + command 9 + agent 5. 숫자를 갱신하는 대신 **하드코딩을 제거**하고 확인 명령(`ls skills/*/ commands/*.md agents/*.md`)을 남겼다 — 손으로 유지하는 개수는 반드시 다시 drift하며, 이 저장소는 같은 이유로 "카탈로그 자동 생성(drift 방지)" 항목을 이미 두고 있다.
  - ⑵ **사실 오류**: "`code-reviewer`/`code-security-reviewer` **agent**가 agent-internal only"라고 서술했으나 반대다 — 그 둘은 커맨드·사용자 요청의 **진입점**(직접 트리거 가능)이고, agent-internal인 agent는 `code-implementer`·`acceptance-test-runner`다. agent-internal인 것은 동명의 **skill**(`code-review`/`code-security-review`)이다. skill/agent 층을 혼동한 서술이라 감사자가 잘못된 기준으로 README를 점검하게 된다 → 세 갈래(agent-internal skill / agent-internal agent / 직접 트리거 가능 agent)로 분리 기재하고 확인 grep을 붙였다.
  - 반영: `.claude/skills/devoks-plugin-maintenance/references/workflow-checklist.md`. `plugins/` 미변경이므로 어떤 플러그인도 버전 bump 비대상.

- [x] **`size` 마커 부여 기준·위임 라우팅 개정 — 경계선을 `S`(직접) 대신 `M`(위임)으로 기울임 + `L` 라우팅 비단조성 해소** (2026-07-30, `devoks-sdlc` `1.12.0 → 1.13.0`)
  - 배경(실사례): Aware 저장소 "추출 보정 3회화"(이슈 #43, PR #44)에서 구현 Task 5개가 전부 `size: S`로 부여돼 세션 모델(Fable 5, $10/$50 per MTok)이 직접 구현. TASK-002/003은 "구현 1파일 + colocated 테스트 1파일, FRD에 수식 단위로 스펙 확정"으로 `M` 기본값("파일 1~3개, 스펙 확정")에 해당했으나, `task-delegation.md` 손익분기의 **"잔여 Task ≤3개이거나 단일 모듈·단일 PR이면 `S`를 넉넉히 부여"** 조항이 `S` 판정 근거로 확대 적용된 것이 직접 원인.
  - 확정 원칙: **스펙이 닫혀 있으면 위임(`M`), 판단·설계가 필요하면 직접** — 기존 공통 예외 ③("스펙 미완결 → 직접")과 대칭을 이루는 축. `code-implementer`는 `model: sonnet` 고정이라 스펙이 닫힌 기계적 구현을 상위 모델로 직접 해도 충실도 이득이 없는 반면 단가·rate limit 소모는 큼 — 상위 모델은 판단 레이어(분석·FRD 정련·설계 결정·리포트 판정)에 남긴다.
  - `S` 정의를 **닫힌 열거**로 축소(순수 타입/상수 정의·설정값 변경·문구/주석 수정·단순 re-export, `test: skip`). "목록에 없으면 `M`" 구조가 경계선을 기본값으로 강제한다. 새 규칙 **`test: required` ⇒ 최소 `M`**(단방향 필요조건 — `skip`이어도 규모가 있으면 `M`).
  - **열린 결정 4건의 판단**: ⑴ colocated 테스트 파일 수 산정은 논쟁 자체를 폐기 — 파일 수는 프록시일 뿐이고 위임 순이득의 실제 원천("검증 출력이 메인 컨텍스트에 적재되는가")은 `test` 마커가 직접 표현하므로 4번 규칙으로 흡수. ⑵ 정량 임계(diff ≤30줄 등) **미도입** — PLAN 작성 시점엔 추정치라 이번 오배정과 동일한 실패 모드(자의적 근거의 확대 적용)를 재생산하고, 대신 닫힌 열거 + "새 분기·상태·런타임 동작을 만들지 않는다"는 구조적 판별식을 채택. ⑶ 세션 모델 조건부 규칙 **미도입** — `size`는 PLAN 작성 시점에 고정되는데 실행 세션 모델은 그때 미확정이고 재개 시 바뀔 수 있어, 조건부화하면 마커 안정성(즉흥 판단 제거라는 존재 이유)이 깨짐. 모델 이득은 규범이 아닌 손익분기 서술로만 유지. ⑷ `test: required` ⇒ 최소 `M` **채택** — 새 `S` 정의가 기존 `test: skip` 기준 목록의 진부분집합이라 명문화 비용 0.
  - **손익분기 조항의 우회로 2곳을 함께 축소**(제안 단계에서 발견, 사용자 승인): ⒜ `task-pr-splitting.md`·`task-delegation.md`의 ≤3개 조항을 "이미 `S` 요건을 충족한 Task끼리의 tie-breaker"로 격하하고 "`M` 기본값 Task를 `S`로 끌어내리는 근거로 쓰지 않는다"를 명시. ⒝ `progress-tracking.md` 재개 절차 5항의 **런타임 판본**("잔여 3개 이하면 남은 `M`도 직접 구현 우선 검토") — 마커를 고치지 않고 라우팅만 뒤집어 ⒜의 취지가 그대로 새는 지점이라, "잔여량은 `M`을 직접으로 뒤집는 근거가 아니다"로 반전. ⒞ `task-delegation.md` 손익분기 표의 모델 조건부 행("세션이 opus/fable이면 `S` 임계를 보수적으로")은 결정 ⑶과 충돌하고 구 `S` 정의(함수 1~2개)를 인용하고 있어 제거 — 유효 내용(cold-start 재독 오버헤드는 모델 무관 존재)은 서술 문단에 이미 있음.
  - 안티패턴 노트 2개("애매하면 `M` 남용"/"귀찮아서 skip")는 **유지**(방향만 바꾸는 개정이지 균형 장치 제거가 아님). 단 노트 ①의 `S` 후보 예시는 구 정의("조건부 렌더링·단순 토글류")를 인용해 새 규칙과 충돌하므로 새 열거로 교체. 반영 중 `순수 타입/상수 정의`가 `S` 열거에서 빠지면 예시·템플릿에 유효한 `S`가 하나도 남지 않아 노트 ①이 무근거가 되는 문제를 발견해 명시적으로 포함(`test: skip` 기준 목록과의 정합).
  - 예시·템플릿의 `S` + `test: required` 조합(새 규칙 위반) 정정: `example-walkthrough.md` TASK-005(조건부 토스트)·TASK-012(재시도 폴백), `PLAN.template.md` TASK-004(조건부 렌더링)·TASK-011(에러/재시도) → 모두 `M`. 각 예시에 `S`는 타입/상수 Task 1개만 남는다.
  - **후속 발견 — `L` 라우팅 비단조성(같은 라운드에서 함께 개정)**: 라우팅이 규모에 대해 비단조였다(`S`→직접, `M`→위임, `L`→직접). 규모가 커질수록 위임 이득이 커지는데(cold-start 고정비 대비 본작업 비례 이득) 못 쪼개는 `L`은 정의상 본작업이 가장 크고 위임 이득이 최대인 지점인데도 가장 비싼 모델(세션 모델)로 갔다.
    - **진단(층 1)**: 원인은 "L이 크니까 직접"이 아니라 **`L` 부여 기준이 이질적인 두 축을 OR로 묶은 것** — ⑴ 규모 축(파일 3개 초과, 양적) ⑵ **판단 축**(설계 변경·인터페이스 파급, 질적). 두 축은 위 확정 원칙에서 정반대 결론을 요구한다(스펙이 닫혔으면 위임 / 판단이 필요하면 직접). 판단 축 `L`은 실은 공통 예외 ③과 같은 축이라 이미 커버되고 있었고 **다른 축만 잘못된 출구로 나가고 있었다.** 따라서 필요한 것은 새 규칙이 아니라 **기존 원칙의 누락된 적용**이었다.
    - **개정(A안)**: 라우팅 표 `L` 행을 사유별 2분기로 — 판단 축 → 메인 루프 직접 / 스펙 닫힘 축 → 위임(스코프 초과 시 런타임 보정의 blocked가 안전장치). 부여 측은 "쪼갤 수 없으면 §1에 사유 1줄"이라는 **기존 의무에 어느 축인지 밝히도록** 한 구절만 추가 — 라우팅은 그 기록을 읽을 뿐 새 판단을 하지 않으므로 `test: required ⇒ 최소 M`과 동일한 **"판단 비용 0 게이트"** 패턴이 된다. `PLAN.template.md` §1에 해당 슬롯이 없어 A안이 실제로 동작하지 않으므로 선택 bullet(`size: L` 잔존 사유)을 신설했다.
    - **기각**: ⒝ 못 쪼개는 `L`을 AskUserQuestion으로 확인 — "쪼갤 수 없는 `L`"은 정의상 사용자가 결정할 것이 없고(§1에 사유 기록됨) HITL 마찰만 늘어 실익 낮음. ⒞ `L` 마커 폐기 후 `M`+분해 플래그로 통합 — 비단조성 원천은 제거되나 템플릿·예시·각 SKILL.md 요약까지 파급되어 "문서 구조·SSOT 분담 유지" 제약 초과.
  - **후속 발견 2 — `L` 부여 기준의 파일 수 지표 폐기(같은 라운드, 사용자 지적으로 발견)**: 층 1을 고친 뒤에도 규모 축의 **측정 지표**가 "파일 3개 초과"로 남아 있었다. 사용자 지적 — "수정될 파일 개수는 중요하지 않다. 실제로 중요한 것은 구현 시 판단이 필요한지, 로직·테스트·인터페이스 중 무엇이 변경되는지다. 파일 1개라도 그것들이 바뀌면 크다. 사이즈가 파일 수량에 비례하지 않는다."
    - **진단(층 2)**: 파일 수는 **신뢰성은 있고 타당성이 없는** 대리지표 — "세기 쉬워서" 쓰였을 뿐 `size`가 예측해야 하는 값(재독 범위·검증 출력 크기)과 상관이 약하다. 양방향 반례: ⑴ 파일 1개인데 공용 시그니처·상태 머신·데이터 계약 변경 → 전 호출부 재독/테스트 폭발/마이그레이션 판단 ⑵ 파일 5개인데 rename·import 경로 일괄 수정 → 판단 0·재독 얕음·위임 최적. 결정 ⑵가 diff 라인 수를 기각한 이유("작성 시점 추정치")가 파일 수에는 적용되지 않아 살아남았던 것이며, 신뢰성마저 완전하지 않다(`file:`은 디렉터리 표기를 허용하고 colocated 테스트는 보통 미기재 → **라우팅이 `file:` 기재 정확도에 종속**). 또한 결정 ⑴("colocated 테스트 파일 수 산정 논쟁 폐기")은 `S` 판정에서만 해소됐고 M/L 경계에서는 그대로 재발했다(컴포넌트+훅+스타일 3개 + 테스트 1개 = 4개 → `L`로 튐).
    - **핵심 관찰**: 정성적 의도는 **이미 산문에 있었다** — 표 바로 아래에 "`L`이 남아 있는 PLAN은 분해 3원칙 위반 가능성이 높다"고 적혀 있었고 표만 틀린 자로 재고 있었다. 따라서 개정은 새 기준 도입이 아니라 **표를 산문에 맞추는 일**이다. 그리고 사용자가 지목한 세 성질 중 테스트는 `test` 마커, 인터페이스는 `L` 판단 축에 이미 인코딩돼 있고 **빈 칸은 "로직" 하나뿐**이었는데 그 자리를 파일 수가 차지하고 있었다 — 산문이 말한 "관심사가 둘 이상 섞였는가"로 채웠다.
    - **개정**: `L` 부여 기준을 "**관심사가 둘 이상 섞였거나**(분해 3원칙 ①단일 위반) **설계 변경·인터페이스 파급**이 있는 Task"로 교체하고, 파일 수는 "판정 기준이 아니라 위반을 의심하게 하는 **참고 신호**"로 격하(권장 크기 문구에도 "`size` 판정 기준이 아니다" 명시). A안의 축 이름을 **규모 축 → 스펙 닫힘 축**(관심사가 얽혔지만 각각의 스펙은 확정됨)으로 정렬 — A안은 무효화되지 않고 **전제가 정확해졌다**("파일이 많다"는 위임 근거로 빈약했으나 "관심사가 얽혔지만 스펙은 닫혔다"는 정확한 근거).
    - **부수 효과**: 이 개정으로 **파일 수가 `size` 체계 전체에서 사라졌다**(`S`는 같은 라운드에 이미 정성화). 결정 ⑵의 논리가 S/M/L 세 마커에 일관 적용된 상태가 됐다 — 앞서 "남은 리스크: 정량 기준의 비대칭"으로 기록했던 항목이 이로써 해소됨.
    - **트레이드오프**: 파일 수는 기계적으로 셀 수 있어 `feature-plan-author` 완료 기준의 자동 점검이 쉬웠고, 정성 기준은 그것이 안 된다. 다만 애초에 잘못 재던 값이라 자동 점검의 정확도 자체가 낮았고, 실제 안전장치는 런타임 보정(blocked)이며, 파일 수를 "참고 신호"로 남겨 의심 트리거는 유지된다 — 순손실은 작다고 판단.
  - **후속 발견 3 — FRD §4 복잡도 임계 보강(같은 라운드, "파일 3개도 같은 대리지표 문제 아닌가" 질문에서 R&D)**: `size`에서 파일 수를 폐기한 논리를 §4 임계에 그대로 옮기면 **틀린다**는 결론. 반사적 적용을 기각한 근거를 남긴다.
    - **출처 확인**: `design-spec.md`의 임계 신호는 이 문서 고유값이 아니라 **`plugins/devoks-core/rules/agent-principles.md:21` "Ask Before Expanding Scope"의 미러**임을 문서가 스스로 선언하고 있었다(그 rule은 대상 프로젝트에 실제 복사되는 base rule 2개 중 하나). 임계를 건드리면 크로스 플러그인 변경이거나 선언된 미러 관계를 깨는 drift가 된다.
    - **진단**: 원본 게이트는 **"사용자에게 스코프 확인을 받아라"**(blast radius)용이고 §4는 **"설계를 문서로 고정하라"**(구조 결정 유무)용이다 — **다른 목적의 기준을 차용**한 것이며, 이번 세션에서 세 번째로 반복된 같은 패턴(손익분기 조항 확대 적용 → `L` 두 축 OR → 이번). 파일 수가 어긋나는 것도 맞다(파일 5개 rename = 구조 결정 0인데 초과 판정 / 훅 1개 안에서 상태 소유 위치 변경 = §4.2의 핵심인데 단순 판정).
    - **그런데 `size`와 결론이 다른 이유 — 오류 비용의 비대칭이 반대다**: `size`는 과다·과소 위임 모두 실비가 발생해 **대칭**이므로 정확도가 필요했고 정성 전환이 정당했다. §4 임계는 과다 트리거가 토큰+HITL 1회로 끝나는 반면 과소 트리거는 PLAN이 임의 구조로 분해되는 비용을 내므로 **비대칭** — **과다 트리거가 안전한 방향**이다. 게다가 §4는 사용자와 대화하는 FRD 저작 단계에서 작동해 오판을 즉시 교정할 수 있고, `size`처럼 실행 라우팅에 자동 집행되지 않는다. 따라서 느슨한 정량 임계는 해악이 아니라 **안전판**으로 작동한다. 남는 실질 문제는 false negative 하나뿐이었다.
    - **개정(안 A — 제거 대신 보강)**: ⑴ 임계 신호에 **"상태·데이터의 소유 위치가 새로 정해지거나 바뀜"** 추가 — §4.2가 스스로 핵심이라 밝힌 질문을 신호로 승격(`L` 개정과 같은 "문서 안에 이미 있는 것을 신호화" 패턴), 파일 1개짜리 false negative를 잡는다. ⑵ `파일 3개 초과`에 **"기계적 일괄 변경(rename·import 경로·동일 패턴 반복 추가)은 해당 없음"** 한정구 — false positive만 깎고 임계는 유지해 미러 선언을 깨지 않는다. ⑶ `단순` 행에 "위 신호가 하나라도 있으면 단순이 아니다"를 명시(기존 AND 조건이 암묵적이었음). ⑷ 원본과의 차이가 **의도된 것**임을 design-spec에 1줄로 박아 미래 유지보수자가 "동일하게" 되돌리지 못하게 했다.
    - **기각(안 B)**: `파일 3개 초과`를 참고 신호로 격하하고 미러 선언을 끊는 정성 전환 — 과다 트리거가 안전한 게이트에서 안전판을 제거하고 base rule과의 선언된 관계를 끊어 drift 관리 부담을 만든다. 비용 > 이득.
    - **`devoks-core` 미변경**: `agent-principles.md`의 "more than 3 files"는 원래 목적(blast radius → 스코프 확인)에서 정량이 오히려 적합하고, base rule로 전 대상 프로젝트에 배포되는 SSOT라 파급이 크다 — 유지.
  - **남은 리스크**: 위임한 스펙 닫힘 축 `L`이 blocked로 돌아오면 cold-start 1회 헛지불. `L`은 설계상 드물고 blocked 리포트가 부분 변경 파일 목록을 은폐 금지로 요구하므로 인수 비용은 낮다.
  - 반영: `skills/feature-workflow-runner/references/task-pr-splitting.md`(부여 기준 SSOT — `size` 표·`S` 필요조건·손익분기 tie-breaker·`L` 정성 기준 전환·권장 크기 문구의 판정 기준 부인·`L` 사유 축 명시)·`references/task-delegation.md`(라우팅 SSOT — 원칙·단가 다운시프트·손익분기 표·`L` 행 2분기)·`references/progress-tracking.md`·`references/example-walkthrough.md`·`assets/PLAN.template.md`(`size` 설명·예시 마커·§1 `L` 잔존 사유 슬롯), `skills/feature-workflow-runner/SKILL.md`(Phase 3 요약의 `L` 문구, `metadata.version` `1.5.0 → 1.5.1`), `skills/feature-plan-author/SKILL.md`(`size` 분포 자기점검 양방향화 + `L` 축 명시 확인, `1.2.0 → 1.2.1`), `skills/feature-plan-executor/SKILL.md`(라우팅 절의 `L` 문구, `1.5.0 → 1.5.1`), `skills/feature-workflow-runner/references/design-spec.md`·`assets/FRD.template.md`·`skills/feature-frd-author/SKILL.md`(§4 복잡도 임계 보강 — 소유 위치 신호 추가·기계적 일괄 변경 한정구·단순 행 AND 조건 명시, `1.1.0 → 1.1.1`), `plugin.json`.
  - 의도적으로 변경하지 않음: `feature-plan-author`/`feature-plan-executor`의 `references/` 사본 — 존재하지 않고 `../feature-workflow-runner/references/`를 상대 참조하므로 SSOT 1곳 수정으로 전파됨. 두 스킬의 `description`에 있는 size 요약("S 직접·M 위임·L 분해 재검토")은 개괄 표현이라 그대로 유효(트리거 조건 불변 — 동적 eval 생략 근거). `README.md`/`docs/README.ko.md`/`marketplace.json`은 스킬 목록·description 불변이라 비대상.
  - 6축 스킬 품질 체크리스트: 정적 축만 적용 — 축2(참조 실존) 변경 4개 스킬의 `references/*.md` 언급 27건 전량 실존 확인, 축3(`evals/evals.json`)은 변경 4개 중 `feature-workflow-runner`만 보유하고 `feature-plan-author`/`feature-plan-executor`/`feature-frd-author` **3개가 기존 공백**(이번 변경으로 생긴 것 아님 — "evals 하니스 확대" 항목 범위), 축4(MCP 의존 없음), 축5(`../../` 플러그인 루트 탈출 0건 — 스킬 간 `../feature-workflow-runner/` 공유 참조는 루트 내부라 안전). 동적 축(1·6)은 description·트리거 조건 불변이라 생략.
  - **커밋 전 자체 재감사에서 발견·수정(같은 라운드)**: ⑴ `feature-plan-author/SKILL.md` 완료 기준이 `S` 열거를 SSOT(`task-pr-splitting.md`) 밖에 **복제**하고 있어 참조로 축약(열거를 여기 복제하지 않는다는 문구를 함께 박음) — 이 저장소가 "심각도 분류 SSOT 통합"을 별도 항목으로 둘 만큼 경계하는 패턴과 충돌했다. ⑵ `task-pr-splitting.md`의 `S` 필요조건 bullet이 "`skip`이어도 **규모가 있으면** `M`"이라고 써서, 같은 파일에서 방금 폐기한 양적 지표를 되살리는 자기모순이었다 → "위 `S` 열거에 해당하지 않으면 `M`"으로 정정. ⑶ 첫 보고에서 `patch`로 판정했으나 **라우팅 결과가 실제로 뒤집히는 변경**이라 소비자에게 신호가 필요하다고 판단해 `minor`로 승격(`1.12.1 → 1.13.0`, 스킬 metadata도 minor). ⑷ 재감사 자체가 스킬이 지정한 상세 체크표(`references/workflow-checklist.md`)를 첫 라운드에 읽지 않고 진행했던 절차 누락을 드러냈다 — 축 2/3/5의 명시된 grep 절차와 §4 devoks-sdlc 특수 케이스는 재감사에서야 실행됐다.

- [x] **실동작 인수 검증 스킬 신설 — `verify-acceptance-test`(+ `acceptance-test-runner` 에이전트), `devoks-browser` 의존성 추가** (2026-07-23, `devoks-sdlc` `1.9.0 → 1.10.0`)
  - 배경: aware-react-app 세션에서 "추출설정 기계보정 완료 마크" 기능이 계획→구현→유닛테스트 39건→코드리뷰까지 전부 통과했는데도, 브라우저 실동작 검증 단계에서만 (a) 의존 DB 필드가 실환경에서 `null`이라 기능이 발동 자체를 안 하는 데이터 리얼리즘 문제와 (b) 에뮬레이터가 목표 상태를 재현 못해 임시 패치가 필요했던 인프라 갭이 드러남. lint/유닛테스트/코드리뷰가 잡지 못하는 "실데이터 정합"·"UI 조작→영속의 종단 동작" 갭을 메우는 스킬로 신설.
  - 조사 결과 제안된 5개 항목(P1~P5) 중 상당수가 이미 커버돼 있었음: TEMP 패치 회수 규약(`verify-data-flow`의 `<AuditMarker>`+grep 전량 회수)은 이미 완비돼 참조만 걸었고, "실행 단계 마지막 자동 게이트"화는 이 저장소가 이미 확정한 "제안이지 오케스트레이션이 아니다" 원칙(`post-implementation-checklist.md`, 자동 게이트는 `devoks-sdlc-orchestration` 로드맵 항목 소관)과 충돌해 게이트가 아니라 체크리스트 항목으로 편입. 데이터 리얼리즘 체크는 `verify-requirements`가 이미 "데이터 정합성 실측은 verify-data-flow 소관"이라 자기 범위를 그어둬 그 대신 `feature-frd-author`의 Edge Case 작성 단계에 배치.
  - 신규 스킬 위치를 devoks-sdlc로 결정(사용자 확인) — 실제 앱을 구동해 검증하는 것은 SDLC 검증 영역이고 devoks-browser는 Chrome DevTools MCP 연동·디버깅 전용 역할로 분리 유지. `browser-visual-diff → devoks-sdlc:verify-visual-diff` 이전이 보류된 사유("기존 스킬+캡처 에이전트+references 통째 이전 비용")와는 다른 케이스임을 확인 — 새 스킬이 `dependencies`로 devoks-browser를 선언하는 것은 devoks-browser가 devoks-core에 의존하는 것과 동일한 이미 검증된 패턴이라 새 결합 문제를 만들지 않음(공식 문서 `plugin-dependencies`의 `deploy-kit`↔`secrets-vault` 예시로 MCP 도구가 의존성만으로 그대로 호출 가능함을 확인, 별도 permission 중복 선언 불필요).
  - `verify-data-flow`(레이어별 계측·3중 대조)와 경계 분리: 이 스킬은 UI 조작 주도·1회성 최종 상태 확인 중심이며, 다층 계측이 필요하면 리포트에서 `verify-data-flow` 호출을 제안하고 중복 구현하지 않음. `browser-visual-diff`↔`browser-visual-diff-capture` 패턴(슬롯 합의는 메인 루프, 실행은 스크린샷/콘솔 바이트 격리용 서브에이전트)을 그대로 재사용.
  - 6축 스킬 품질 체크리스트 전체 적용(신규 skill, blocking) — 정적 축(2·3·4·5·6) 확인 완료, 동적 축(1·6)은 서브에이전트 2건(AC 선별 케이스, devoks-browser 미설치 케이스)을 실제 실행해 description↔동작 일치 확인(둘 다 전 항목 PASS). 로컬 플러그인 소스 수정이 실행 세션에 반영되려면 push→marketplace update→재설치가 필요한 기존 갭(2026-07-20 기록) 때문에, 동적 검증은 설치된 스킬 트리거 대신 SKILL.md를 직접 따르게 하는 방식으로 수행.
  - **체크리스트 내 순서 재검토(같은 날 후속)**: 처음엔 표 맨 끝(8번, PR 이후)에 붙였다가, 커밋 전 검증이어야 한다는 지적으로 "요구사항→데이터 흐름→UI→코드리뷰" 뒤(항목 2)로 옮김 → "코드 리뷰는 정적·저비용이라 구조적 문제를 먼저 걸러야 라이브 검증(데이터 흐름·UI·실동작) 낭비가 없다"는 지적으로 코드 리뷰를 항목 2로 앞당김 → "`browser-visual-diff`는 Phase 5에서 레이아웃 상수·토큰 코드를 실제로 고치므로, 그 변경까지 반영된 최종 코드를 실동작 검증이 봐야 한다"는 지적으로 최종 순서를 **요구사항→코드리뷰→데이터 흐름→UI 시각 품질→브라우저 실동작 검증(커밋 직전 최종 게이트)→테스트 회귀→커밋→PR**로 확정. 원칙: 코드 변경을 유발할 수 있는 정적/라이브 검증은 앞에, "지금 커밋될 코드가 실제로 동작하는가"를 묻는 최종 확인은 그 모든 변경이 반영된 뒤 가장 마지막(커밋 직전)에 둔다.
  - 순서 재배치 과정에서 `feature-workflow-runner/SKILL.md`·`feature-plan-executor/SKILL.md`의 마무리 절 요약 문구("표준 메뉴" 나열)가 신규 항목을 빠뜨린 채 구 순서로 남아있던 실제 불일치를 발견해 수정. `verify-requirements`의 범위 선언("안 한다")에도 `verify-acceptance-test` 위임 문구를 대칭으로 추가(`1.0.0 → 1.0.1`) — `verify-data-flow`/`code-review-diff-branch`는 이미 있었는데 신규 항목만 빠져 있었음.
  - 반영: `skills/verify-acceptance-test/SKILL.md`(신규)·`references/scenario-execution.md`·`references/report-template.md`·`evals/evals.json`(신규), `agents/acceptance-test-runner.md`(신규), `plugin.json`(`dependencies`에 `devoks-browser` 추가), `skills/feature-workflow-runner/references/post-implementation-checklist.md`(항목 신설 후 순서 재배치·비고 갱신, 최종 위치는 항목 5), `skills/feature-frd-author/SKILL.md`(데이터 리얼리즘 EDGE case 가이드, `1.0.0 → 1.1.0`), `skills/feature-workflow-runner/SKILL.md`·`skills/feature-plan-executor/SKILL.md`(참조 문서 갱신 반영 + 마무리 절 요약 문구 정합, patch `1.4.0 → 1.4.1`), `skills/verify-requirements/SKILL.md`(범위 선언 대칭 추가, `1.0.0 → 1.0.1`), `README.md`/`docs/README.ko.md`/`.claude-plugin/marketplace.json`(스킬·에이전트·dependencies 카탈로그 반영, marketplace.json 플러그인 배열 순서도 devoks-browser가 devoks-sdlc보다 먼저 오도록 정렬).
  - 의도적으로 변경하지 않음: `verify-data-flow`(TEMP 규약·`env=browser` 이미 완비), `code-implementer.md`("dev server 실행 금지"와 정면 충돌 소지라 브라우저 검증을 그 안에 넣지 않고 별도 후속 단계로 유지).

- [x] **테스트 품질 기준(FIRST·결정성·안티패턴 등) ROI 선별 도입 — `test-author/references/test-quality-bar.md` 신설** (2026-07-22, `devoks-sdlc` `1.8.1 → 1.9.0`)
  - 배경: 사용자가 개인 테스트 규칙 문서(`docs/testing-rules.md`, 276줄 — FIRST/행위검증/결정성/AAA·GWT/테스트레벨/테스트더블/경계값분석/안티패턴/커버리지철학/사전체크리스트/JS·TS 도구부록)를 제공하고, "토큰비효율적이거나 실익 없는 룰은 배제, 전체 도입 금지"를 명시적으로 요구. Explore 조사 결과 `verify-requirements`/`code-review`/`code-security-review` 등 devoks-sdlc 어디에도 테스트 품질 관련 내용이 없어 클린 슬레이트였음.
  - **채택**: FIRST 원칙, 행위(behavior) vs 구현(implementation) 검증, 결정성(flaky 원인 5가지 — 시간/난수/동시성/네트워크·FS·DB/순서), AAA/네이밍, 테스트 레벨 결정 휴리스틱(Unit/Integration/E2E·Trophy·"자명한 코드는 테스트 안 함"), 케이스 설계(3종+경계값분석), 테스트 더블 규칙(상태검증 우선·3rd-party 직접mock금지·과도한mock금지), 금지 안티패턴(assertion없음·over-mocking·허수 테스트 등), 커버리지 철학(floor·branch>line). **제외**: Red-Green-Refactor를 기본 워크플로로 도입 — 직전 `test:` 마커 신설 라운드에서 이미 결정한 "TDD 순서 강제는 토큰비용 대비 품질개선 근거 약함"과 모순되므로 유지. **채택(유일한 순서 예외)**: 버그 수정 시 재현 실패 테스트 우선(Anthropic 공식 권장과 일치, 이미 승인된 예외). Property-based/Contract/Mutation testing은 "프로젝트에 이미 해당 도구가 있을 때만" MAY로 1줄 압축, JS/TS 도구 부록은 "참고용·비강제"로 대폭 압축, 사전 제출 체크리스트(§10)는 `test-author`의 기존 완료 기준과 중복이라 독립 섹션으로는 도입하지 않고 병합.
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
  - 요구사항 검증 항목은 `verify-requirements mode=verify spec=<out>/FRD.md`로 한정하고 `mode=checklist`(별도 체크리스트 파일 생성)는 생략 — FRD §3/§5/§8이 이미 F(기능)/B(비즈니스로직)/E(엣지케이스)/D(데이터계약) 카테고리에 ID로 대응돼 중복이기 때문. 단, U(UI/UX 세부)는 FRD §4가 아키텍처 구조 중심이라 대응이 약해 이 항목의 범위 밖으로 명시하고 위 "UI 작업 분리 검토" 항목으로 연결(근거 보강 참고).
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

