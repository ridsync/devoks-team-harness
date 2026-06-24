# Roadmap — 추후 개선 사항 (TODO)

DevOks 하네스의 플러그인 구조·내용 개선 후보를 모아두는 단일 SSOT 문서.
양 언어 README는 이 문서를 링크만 한다(이중 관리 drift 방지).

> 최종 갱신: 2026-06-24

---

## 완료 / 최근 반영

- [x] **`devoks-rn` 신설 (React Native 디버깅)**
  - `metro-devtools-attach` 스킬: 에뮬레이터 스크린샷, Metro CDP JS 콘솔/상태 조회.
  - `metro-devtools` MCP는 WebSocket URL 동적 변경으로 `~/.claude.json` 수동 등록 필요.
  - 마켓플레이스 식별자 `devoks` → `devoks-plugins` 로 변경.

---

## 마이그레이션 / 구조

- [ ] **컨벤션 문서 계층 분리 (`project-convention` 재정의)**
  - 현재 `project-convention.md`에 이전 프로젝트/도메인 전용 규칙이 섞여 있어 범용 규칙 문서로서의 신뢰도가 떨어짐.
  - 분리 원칙: 프로젝트 범용 컨벤션(문서 구조, 규칙 계층, 공통 운영 원칙)과 프로젝트 전용 컨벤션(언어, 타입스크립트 여부, 팀 코딩 스타일)은 명시적으로 구분.
  - 금지 방향: 특정 프로젝트/도메인 전용 구현 규칙을 범용 컨벤션에 고정하지 않기.
  - 산출물 후보: 공통 컨벤션 문서 + 프로젝트/도메인 오버레이 문서 구조.
  - 우선순위: 높음(규칙 drift 및 재사용성 저하 방지).

- [ ] **`browser-visual-diff` → `devoks-verify:verify-visual-diff` 이전**
  - 시각 diff는 본질적으로 "검증"이므로 devoks-verify로 모으는 것이 도메인상 자연스럽다.
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
  - 우선순위: 높음(딜리버리 빈칸).

- [ ] **Operate/Monitor · Maintain 단계 (장기)**
  - 의존성 업그레이드 제안, 보안 패치/CVE 추적, 회귀 감지 등.
  - 환경 종속이 커서 대부분 thin-wrapper 또는 외부 도구 연동으로 설계 필요.
  - 우선순위: 낮음(장기).

---

## 품질 / 유지보수

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
  - `devoks-core`만 1.0.1, 나머지 1.0.0. 릴리스 정책 확정 시 버전 규칙 통일.
  - 우선순위: 낮음.
