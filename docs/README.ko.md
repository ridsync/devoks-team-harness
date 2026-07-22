# DevOks Team Harness

DevOks 팀 Claude Code 하네스 — 코드리뷰·기능개발·Git 워크플로우·React Native 디버깅 플러그인 모음.

> **MCP 및 의존성 설치 가이드**: [`mcp-setup-guide.md`](mcp-setup-guide.md)  
> **플러그인 관리 가이드** (생성·검증·배포): [`plugin-management.md`](plugin-management.md)

![DevOks Team Harness plugin map](../assets/devoks-harness-engineering-final.png)

---

> **English**: [README.md](../README.md)

## 플러그인 구성

| 플러그인 | 내용 | 필수 여부 |
|---------|------|----------|
| `devoks-core` | 기본 원칙, 컨벤션 preset, 명시적 setup 흐름 — MCP 점검 + 프로젝트 convention setup/management 제공 | **필수** |
| `devoks-git` | Git 커밋·이슈·PR 워크플로우 커맨드 | 권장 |
| `devoks-sdlc` | SDLC 워크플로우 통합 — 기능개발(FRD·PLAN·실행·UI), 테스트 작성·triage, 코드리뷰·리팩토링·모듈분석·보안검증, 요구사항·데이터흐름 검증 | 권장 |
| `devoks-browser` | Chrome DevTools MCP 연결 + Visual Diff 검증 | 선택 |
| `devoks-rn` | React Native 디버깅 — Metro DevTools CDP 연결, 에뮬레이터 스크린샷, JS 콘솔/상태 조회 | 선택 (RN 프로젝트) |

마켓플레이스 카탈로그에서 `devoks-core`를 제외한 모든 플러그인은 `devoks-core`에 의존합니다.

마켓플레이스 식별자: **`devoks-plugins`** (`@devoks-plugins`로 설치). 예전 `devoks` 마켓플레이스를 등록했다면 제거 후 재등록: `/plugin marketplace remove devoks` → `/plugin marketplace add ridsync/devoks-team-harness`.

---

## 빠른 시작

```bash
# 사전 준비: gh CLI
brew install gh && gh auth login

# 클로드 세션 시작
claude

# 1. 마켓플레이스 등록 (최초 1회)
/plugin marketplace add ridsync/devoks-team-harness

# 2. 플러그인 설치
/plugin install devoks-core@devoks-plugins      # 필수 — core rule, convention preset, setup/management 흐름
/plugin install devoks-git@devoks-plugins       # Git 워크플로우 (권장)
/plugin install devoks-sdlc@devoks-plugins      # SDLC: 기능·테스트·코드리뷰/보안·검증 (권장)
/plugin install devoks-browser@devoks-plugins   # 브라우저 도구 (선택)
/plugin install devoks-rn@devoks-plugins        # React Native 디버깅 (선택 — RN 프로젝트)

# 3. MCP 서버·의존성 초기화
/devoks-core:setup-mcp

# 4. base rules/refs 적용 + stack preset 선택
/devoks-core:setup-project-convention
```

> **플러그인 설치 직후에는 아래 2개 setup을 순서대로 실행하세요:**
> 1. `/devoks-core:setup-mcp`
> 2. `/devoks-core:setup-project-convention`
>
> 전체 의존성·MCP 설치 → [`mcp-setup-guide.md`](mcp-setup-guide.md)
>
> 이후 업데이트: `/plugin marketplace update devoks-plugins`

---

## 폴백 설치 (`setup.sh`)

플러그인 시스템을 쓸 수 없을 때 — 커맨드·스킬·rules·refs를 `.claude/`에 직접 복사합니다.

```bash
git clone https://github.com/ridsync/devoks-team-harness.git
cd /path/to/your-project
/path/to/devoks-team-harness/setup.sh

# 업데이트
/path/to/devoks-team-harness/setup.sh --update
```

> **참고:** `setup.sh`는 base rules/refs 와 commands/skills 를 부트스트랩하지만, stack-specific `project-convention.md`는 자동 주입하지 않습니다. 설치 후 프로젝트에서 `/setup-project-convention`으로 preset을 선택하세요.

---

## `devoks-core` Convention Setup 동작

`devoks-core`는 더 이상 SessionStart마다 `.claude/rules/`·`.claude/refs/`를 자동 overwrite 하지 않습니다.
대신 **명시적 setup/apply 모델**로 동작합니다.

1. `/devoks-core:setup-mcp`로 공유 MCP/의존성을 정리
2. `/devoks-core:setup-project-convention`으로 base rules/refs 와 stack preset 적용
3. 선택한 preset을 `.claude/rules/project-convention.md`에 주입
4. 이후 갱신은 setup/management 흐름으로만 수행 (자동 overwrite 금지)

| 유형 | 소스 | 프로젝트 적용 방식 |
|------|------|--------------------|
| **base rules** | `plugins/devoks-core/rules/agent-principles.md`, `memory-policy.md` | explicit setup 시 복사 |
| **refs** | `plugins/devoks-core/refs/*.md` | explicit setup 시 복사 |
| **stack preset** | `plugins/devoks-core/conventions/<preset>/project-convention.md` | `.claude/rules/project-convention.md`로 주입 |
| **project active convention** | `.claude/rules/project-convention.md` | 프로젝트 소유, SessionStart overwrite 없음 |

SessionStart 훅은 이제 MCP/프로젝트 초기화 상태만 점검합니다.

---

## 사용 가능한 스킬

| 스킬 | 호출 | 플러그인 |
|------|------|---------|
| `feature-frd-author` | `/devoks-sdlc:feature-frd-author` | devoks-sdlc |
| `feature-plan-author` | `/devoks-sdlc:feature-plan-author` | devoks-sdlc |
| `feature-plan-executor` | `/devoks-sdlc:feature-plan-executor` | devoks-sdlc |
| `feature-workflow-runner` | `/devoks-sdlc:feature-workflow-runner` | devoks-sdlc |
| `verify-requirements` | `/devoks-sdlc:verify-requirements` | devoks-sdlc |
| `verify-data-flow` | `/devoks-sdlc:verify-data-flow` | devoks-sdlc |
| `code-review` | `/devoks-sdlc:code-review` *(에이전트 내부 전용)* | devoks-sdlc |
| `code-security-review` | `/devoks-sdlc:code-security-review` *(에이전트 내부 전용)* | devoks-sdlc |
| `test-author` | `/devoks-sdlc:test-author` *(에이전트 내부 전용)* | devoks-sdlc |
| `test-run-triage` | `/devoks-sdlc:test-run-triage` | devoks-sdlc |
| `browser-devtools` | `/devoks-browser:browser-devtools` | devoks-browser |
| `browser-visual-diff` | `/devoks-browser:browser-visual-diff` | devoks-browser |
| `project-convention-manage` | `/devoks-core:project-convention-manage` | devoks-core |
| `metro-devtools-attach` | `/devoks-rn:metro-devtools-attach` | devoks-rn |

## 사용 가능한 에이전트

| 에이전트 | 플러그인 | 위임 주체 |
|---------|---------|---------|
| `code-reviewer` | devoks-sdlc | `code-review-general`, `code-review-diff-branch` 커맨드 |
| `code-security-reviewer` | devoks-sdlc | `code-security-review` 커맨드 |
| `code-implementer` *(agent-internal only)* | devoks-sdlc | `feature-plan-executor` 스킬, `feature-workflow-runner` 스킬 (Phase 3) |
| `test-writer` | devoks-sdlc | `test-author` 커맨드 |
| `browser-visual-diff-capture` *(agent-internal only)* | devoks-browser | `browser-visual-diff` 스킬 (Phase 1~4) |

---

## 사용 가능한 커맨드

### devoks-core

| 커맨드 | 설명 |
|--------|------|
| `/devoks-core:setup-mcp` | 권장 MCP 서버·의존성 설치/점검 |
| `/devoks-core:setup-project-convention` | base rules/refs 적용 후 stack preset 기반 `project-convention.md` 구성 |

### devoks-git

| 커맨드 | 설명 |
|--------|------|
| `/devoks-git:git-commit-msg` | Conventional Commits 커밋 메시지 생성 |
| `/devoks-git:git-create-issue` | GitHub 이슈 생성 |
| `/devoks-git:git-pull-request` | PR 생성 (CODEOWNERS 기반 리뷰어 할당) |

### devoks-sdlc

| 커맨드 | 설명 |
|--------|------|
| `/devoks-sdlc:new-feature-draft` | 스펙 기반 기능 구현 |
| `/devoks-sdlc:new-feature-github-issue` | GitHub 이슈 기반 기능 구현 |
| `/devoks-sdlc:new-ui-draft` | Figma → 코드 UI 구현 |
| `/devoks-sdlc:code-review-general` | 범위 지정 코드리뷰 |
| `/devoks-sdlc:code-review-diff-branch` | 브랜치 diff 기반 코드리뷰 |
| `/devoks-sdlc:code-security-review` | repo·의존성·위협 수준 보안 검증 |
| `/devoks-sdlc:test-author` | 테스트 작성/확장 |
| `/devoks-sdlc:code-refactoring` | 구조·계약·품질 리팩토링 |
| `/devoks-sdlc:code-analyze-module` | 모듈/비즈니스 로직 분석 |

---

## 의존성 요약

> DevOks 플러그인은 범용 MCP 서버(Figma·Playwright·Serena·CodeGraph·context7)를 **번들하지 않습니다.** 중복 인스턴스와 로컬 MCP 충돌을 막기 위해 **user/project scope에 1회만** 설치하세요. `devoks-core`의 SessionStart 훅(`hooks/check-setup-state.sh`)이 세션마다 미설치 항목을 감지해 설치를 안내합니다. **예외:** `devoks-browser`는 `chrome-devtools-attach`(`:9269` 연결 전용 설정)만 번들합니다. `devoks-rn`은 Metro WebSocket URL이 동적으로 바뀌므로 `~/.claude.json`에 `metro-devtools`(`--wsEndpoint`)를 수동 등록해야 합니다. 자세한 내용 → [`mcp-setup-guide.md`](mcp-setup-guide.md) → "설치 정책".

| 플러그인 | 필수 | 선택 |
|---------|------|------|
| devoks-core | — | — |
| devoks-git | `gh` CLI | — |
| devoks-sdlc | `gh` CLI, CodeGraph MCP, Serena MCP | Figma MCP, context-mode MCP |
| devoks-browser | Chrome DevTools MCP + `~/.claude.json` | Playwright MCP, Figma MCP |
| devoks-rn | `devoks-rn` 플러그인 + Metro 실행; `~/.claude.json`의 `metro-devtools` (동적 `--wsEndpoint`) | `adb` / `xcrun simctl` (스크린샷) |

전체 설치 가이드 → [`mcp-setup-guide.md`](mcp-setup-guide.md)

---

## 디렉토리 구조

```
devoks-team-harness/
├── .claude-plugin/marketplace.json    # 마켓플레이스 카탈로그
├── plugins/
│   ├── devoks-core/
│   │   ├── hooks/                     # SessionStart → MCP/프로젝트 상태 점검 (자동 overwrite 없음)
│   │   ├── commands/                  # setup-mcp, setup-project-convention
│   │   ├── skills/                    # project convention 관리
│   │   ├── rules/                     # base rules: agent-principles, memory-policy (+ 운영 계약)
│   │   ├── refs/                      # setup 시 주입하는 reference docs
│   │   └── conventions/               # 기술스택별 project convention preset (번들, ${CLAUDE_PLUGIN_ROOT}로 참조)
│   ├── devoks-git/commands/           # Git 커맨드 (3개)
│   ├── devoks-sdlc/                    # SDLC: 기능·테스트·코드·검증 (커맨드 8개 + 스킬 10개 + 에이전트 3개)
│   ├── devoks-browser/               # 브라우저 도구 (스킬 2개 + 에이전트 1개)
│   └── devoks-rn/                    # React Native 디버깅 (스킬 1개)
├── shared/
│   ├── setup/claude.json.template     # ~/.claude.json MCP 설정 템플릿
│   └── templates/CLAUDE.md.project.template
├── docs/
│   ├── README.ko.md                   # 한국어 README (이 문서)
│   ├── mcp-setup-guide.md             # MCP 의존성 설치 가이드
│   ├── plugin-management.md           # 플러그인 생성·검증·배포 워크플로우
│   └── roadmap.md                     # 추후 개선 사항 (TODO)
├── setup.sh                           # 폴백 설치 스크립트
└── README.md                          # English README
```

> `plugins/devoks-core/rules/agent-principles.md`, `memory-policy.md` 와 `plugins/devoks-core/refs/*` 는 explicit setup으로 프로젝트에 seed 됩니다. stack-specific `project-convention.md`는 `plugins/devoks-core/conventions/*` preset에서 선택 주입되며, 이후에는 프로젝트가 소유합니다.

---

## 로드맵

플러그인 구조·내용 개선 후보는 [`roadmap.md`](roadmap.md)에 TODO 형식으로 추적합니다. 주요 항목: `browser-visual-diff` → `devoks-sdlc:verify-visual-diff` 이전, Deploy/Release 단계용 `devoks-release` 신설, 카탈로그 표 자동 생성(README drift 방지), 심각도 분류 SSOT 통합.

---

## 기여 방법

1. 이 저장소를 fork 합니다.
2. `plugins/devoks-core/rules/`, `plugins/devoks-core/refs/`, 또는 플러그인 파일을 수정합니다.
3. PR을 올립니다.
4. 머지 후 팀원은 `/plugin marketplace update devoks-plugins` 로 갱신합니다.
