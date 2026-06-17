# DevOks Team Harness

DevOks 팀 Claude Code 하네스 — 코드리뷰·기능개발·Git 워크플로우 플러그인 모음.

> **MCP 및 의존성 설치 가이드**: [`mcp-setup-guide.md`](mcp-setup-guide.md)  
> **플러그인 관리 가이드** (생성·검증·배포): [`plugin-management.md`](plugin-management.md)

![DevOks Team Harness plugin map](../assets/devoks-team-harness-hero.svg)

---

> **English**: [README.md](../README.md)

## 플러그인 구성

| 플러그인 | 내용 | 필수 여부 |
|---------|------|----------|
| `devoks-core` | 기본 원칙·참조 문서 — SessionStart 훅이 `rules/`·`refs/`를 프로젝트 `.claude/`에 동기화하여 네이티브 자동 로딩 | **필수** |
| `devoks-git` | Git 커밋·이슈·PR 워크플로우 커맨드 | 권장 |
| `devoks-feature` | 기능개발 워크플로우 (FRD·PLAN·실행 스킬, UI 구현, 검증) | 권장 |
| `devoks-code` | 코드리뷰·리팩토링·모듈분석 커맨드 | 권장 |
| `devoks-browser` | Chrome DevTools MCP 연결 + Visual Diff 검증 | 선택 |

마켓플레이스 카탈로그에서 `devoks-core`를 제외한 모든 플러그인은 `devoks-core`에 의존합니다.

---

## 빠른 시작 (최소 의존성)

```bash
# 필수: gh CLI 설치
brew install gh && gh auth login

# 1. 마켓플레이스 등록 (최초 1회)
/plugin marketplace add ridsync/devoks-team-harness

# 2. 설치
/plugin install devoks-core@devoks
/plugin install devoks-git@devoks
/plugin install devoks-feature@devoks
/plugin install devoks-code@devoks
```

전체 의존성 설치 → [`mcp-setup-guide.md`](mcp-setup-guide.md)

---

## 플러그인 설치 (Claude Code 플러그인 시스템)

### 1단계: 마켓플레이스 등록 (최초 1회)

```bash
/plugin marketplace add ridsync/devoks-team-harness
```

### 2단계: 플러그인 설치

```bash
/plugin install devoks-core@devoks           # 필수 — 세션 시작 시 rules·refs 자동 동기화
/plugin install devoks-git@devoks            # Git 워크플로우
/plugin install devoks-feature@devoks        # 기능개발
/plugin install devoks-code@devoks           # 코드 품질
/plugin install devoks-browser@devoks        # 브라우저 도구 (선택)
```

### 3단계: 업데이트

```bash
/plugin marketplace update devoks
```

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

> **참고:** `setup.sh`는 정적 파일만 복사하며 `devoks-core` SessionStart 훅은 실행하지 않습니다. 하네스 변경 후에는 `setup.sh --update`로 rules·refs를 다시 받으세요.

---

## `devoks-core` 컨텍스트 동기화

세션 시작(`startup`, `resume`, `clear`, `compact`) 시 `devoks-core` 훅이 `sync-context.sh`를 실행합니다.

1. 번들 `plugins/devoks-core/rules/*.md` → `.claude/rules/` 복사
2. 번들 `plugins/devoks-core/refs/*.md` → `.claude/refs/` 복사
3. `.gitignore`에 `.claude/rules/`, `.claude/refs/` 멱등 추가 (생성물; SSOT는 플러그인 번들)

| 유형 | 파일 | 역할 |
|------|------|------|
| **rules** | `agent-principles`, `project-convention`, `memory-policy` | 항상 적용되는 에이전트 행동 |
| **refs** | `code-review`, `engineering-principles`, `git-convention`, `workflow` | 필요 시 참조 문서 |

슬래시 커맨드 없이 Claude Code가 `.claude/rules/`를 네이티브로 로드합니다.

---

## 사용 가능한 스킬

| 스킬 | 호출 | 플러그인 |
|------|------|---------|
| `frd-author` | `/devoks-feature:frd-author` | devoks-feature |
| `plan-author` | `/devoks-feature:plan-author` | devoks-feature |
| `plan-executor` | `/devoks-feature:plan-executor` | devoks-feature |
| `feature-workflow-runner` | `/devoks-feature:feature-workflow-runner` | devoks-feature |
| `data-verification` | `/devoks-feature:data-verification` | devoks-feature |
| `code-review` | `/devoks-code:code-review` *(에이전트 내부 전용)* | devoks-code |
| `browser-devtools` | `/devoks-browser:browser-devtools` | devoks-browser |
| `browser-visual-diff` | `/devoks-browser:browser-visual-diff` | devoks-browser |

## 사용 가능한 에이전트

| 에이전트 | 플러그인 | 위임 주체 |
|---------|---------|---------|
| `code-reviewer` | devoks-code | `code-review-general`, `code-review-diff-branch` 커맨드 |
| `browser-visual-diff-capture` | devoks-browser | `browser-visual-diff` 스킬 (Phase 1~4) |

---

## 사용 가능한 커맨드

### devoks-git

| 커맨드 | 설명 |
|--------|------|
| `/devoks-git:git-commit-msg` | Conventional Commits 커밋 메시지 생성 |
| `/devoks-git:git-create-issue` | GitHub 이슈 생성 |
| `/devoks-git:git-pull-request` | PR 생성 (CODEOWNERS 기반 리뷰어 할당) |

### devoks-feature

| 커맨드 | 설명 |
|--------|------|
| `/devoks-feature:new-feature-draft` | 스펙 기반 기능 구현 |
| `/devoks-feature:new-feature-github-issue` | GitHub 이슈 기반 기능 구현 |
| `/devoks-feature:new-feature-verify` | 구현 전후 체크리스트 + 커버리지 검증 |
| `/devoks-feature:new-ui-draft` | Figma → 코드 UI 구현 |

### devoks-code

| 커맨드 | 설명 |
|--------|------|
| `/devoks-code:code-review-general` | 범위 지정 코드리뷰 |
| `/devoks-code:code-review-diff-branch` | 브랜치 diff 기반 코드리뷰 |
| `/devoks-code:code-refactoring` | 구조·계약·품질 리팩토링 |
| `/devoks-code:code-analyze-module` | 모듈/비즈니스 로직 분석 |

---

## 의존성 요약

> DevOks 플러그인은 범용 MCP 서버(Figma·Playwright·Serena·CodeGraph·context7)를 **번들하지 않습니다.** 중복 인스턴스와 로컬 MCP 충돌을 막기 위해 **user/project scope에 1회만** 설치하세요. `devoks-core`의 SessionStart 훅(`hooks/check-mcp.sh`)이 세션마다 미설치 항목을 감지해 설치를 안내합니다. **예외:** `devoks-browser`는 `chrome-devtools-attach`(`:9269` 연결 전용 설정)만 번들합니다. 자세한 내용 → [`mcp-setup-guide.md`](mcp-setup-guide.md) → "설치 정책".

| 플러그인 | 필수 | 선택 |
|---------|------|------|
| devoks-core | — | — |
| devoks-git | `gh` CLI | — |
| devoks-feature | `gh` CLI | Figma MCP, context-mode MCP |
| devoks-code | CodeGraph MCP, Serena MCP | context-mode MCP |
| devoks-browser | Chrome DevTools MCP + `~/.claude.json` | Playwright MCP, Figma MCP |

전체 설치 가이드 → [`mcp-setup-guide.md`](mcp-setup-guide.md)

---

## 디렉토리 구조

```
devoks-team-harness/
├── .claude-plugin/marketplace.json    # 마켓플레이스 카탈로그
├── plugins/
│   ├── devoks-core/
│   │   ├── hooks/                     # SessionStart → sync-context.sh
│   │   ├── rules/                     # SSOT: agent-principles, project-convention, memory-policy
│   │   └── refs/                      # SSOT: code-review, engineering-principles, git-convention, workflow
│   ├── devoks-git/commands/           # Git 커맨드 (3개)
│   ├── devoks-feature/                # 기능개발 (커맨드 4개 + 스킬 5개)
│   ├── devoks-code/                   # 코드 품질 (커맨드 4개 + 스킬 1개 + 에이전트 1개)
│   └── devoks-browser/               # 브라우저 도구 (스킬 2개 + 에이전트 1개)
├── shared/
│   ├── setup/claude.json.template     # ~/.claude.json MCP 설정 템플릿
│   └── templates/CLAUDE.md.project.template
├── docs/
│   ├── README.ko.md                   # 한국어 README (이 문서)
│   ├── mcp-setup-guide.md             # MCP 의존성 설치 가이드
│   └── plugin-management.md           # 플러그인 생성·검증·배포 워크플로우
├── setup.sh                           # 폴백 설치 스크립트
└── README.md                          # English README
```

> `plugins/devoks-core/rules/` 와 `plugins/devoks-core/refs/` 가 SSOT입니다. 해당 파일을 수정·커밋하면 SessionStart 훅(또는 `setup.sh`)이 각 프로젝트 `.claude/`에 반영합니다.

---

## 기여 방법

1. 이 저장소를 fork 합니다.
2. `plugins/devoks-core/rules/`, `plugins/devoks-core/refs/`, 또는 플러그인 파일을 수정합니다.
3. PR을 올립니다.
4. 머지 후 팀원은 `/plugin marketplace update devoks` 로 갱신합니다.
