# Workflow checklist

`devoks-plugin-maintenance`가 상세 점검 시 참고하는 매트릭스다.

## 1. 변경 유형별 기본 확인

| 변경 유형 | 기본 확인 | 추가 확인 |
|---|---|---|
| runtime behavior only | 대상 플러그인 식별, `plugin.json` version bump 여부, `validate --strict` | 사용자-facing 설명 변경이 있으면 README/README.ko 검토 |
| public workflow change | version bump, `validate --strict`, 관련 skill/command 문서 | `docs/plugin-management.md`, README/README.ko |
| docs-only | 실제 코드/동작 불변인지 확인 | plugin version bump 비대상 사유 기록 |
| MCP/prefix/policy change | `mcpServers`, `permissions.allow`, prefix, setup 문서 | `docs/mcp-setup-guide.md`, `setup-mcp.md`, `check-setup-state.sh` |
| naming/catalog change | 이름/description/dependency 변경 반영 | README, README.ko, marketplace, 다른 SKILL 참조 |
| core refs/rules change | 루트 `.claude/` 사본과 explicit setup/sync 정책 확인 | `docs/fix-plan-sync-context-ssot.md`, 관련 운영 문서 |

## 2. 문서 대상 판단표

| 파일 | 언제 검토하나 |
|---|---|
| `README.md` | 플러그인/skill/command 설명, 설치/업데이트 흐름, 사용자-facing 요약이 바뀔 때 |
| `docs/README.ko.md` | README와 동일한 정보의 한국어 카탈로그가 영향을 받을 때 |
| `docs/plugin-management.md` | 플러그인 생성/검증/배포/유지보수 절차 자체가 바뀔 때 |
| `docs/mcp-setup-guide.md` | MCP 서버 설치 방식, prefix, 정책 설명이 바뀔 때 |
| `plugins/devoks-core/commands/setup-mcp.md` | setup 절차, 예시 명령, 서버별 설치 안내가 바뀔 때 |
| `.claude-plugin/marketplace.json` | 신규 플러그인 추가, description/dependencies/source 관련 정보가 바뀔 때 |
| `docs/roadmap.md` | 반복 drift 문제를 후속 개선 과제로 명시해야 할 때 |

## 3. MCP / prefix / permission 점검 포인트

### plugin 설치형 prefix
- `mcp__plugin_<plugin>_<server>__*`
- 플러그인 번들에 의해 제공되는 tool 명칭

### 일반 MCP 등록형 prefix
- `mcp__<server>__*`
- `claude mcp add` 또는 별도 설치로 제공되는 tool 명칭

### 대조 지점
- `plugins/<plugin>/.claude-plugin/plugin.json`
- 관련 SKILL.md / agent 문서
- `docs/mcp-setup-guide.md`
- `plugins/devoks-core/commands/setup-mcp.md`
- `plugins/devoks-core/hooks/check-setup-state.sh`

## 4. 특수 케이스

### devoks-browser
- `chrome-devtools-attach` 명칭 유지 여부
- `settings.permissions.allow` prefix
- browser visual diff / browser devtools 관련 설명

### devoks-rn
- `metro-devtools` 관련 allow prefix
- Metro URL / setup 흐름 설명
- RN 전용 optional 성격 설명

### devoks-core
- `rules/`, `refs/`, hook 변경 시 루트 `.claude/` 사본과 관계
- `check-setup-state.sh`, explicit setup/sync 정책 문서와 설명 일치 여부

### devoks-sdlc
- 구 devoks-code/devoks-feature/devoks-test/devoks-verify 통합체 — skill 10 + command 8 + agent 2, 변경 영향 범위가 5개 플러그인 중 가장 넓음
- `code-reviewer`/`code-security-reviewer` agent와 `code-review`/`code-security-review` skill은 agent-internal only — 메인 루프 직접 트리거 금지 설명이 README/문서에 유지되는지 확인
- `gh` CLI, CodeGraph MCP, Serena MCP 의존 — 플러그인 자체 번들 MCP 아님(일반 MCP 등록형), README dependency summary와 실제 의존 일치 여부 확인
- skill 간 cross-reference(예: `feature-workflow-runner` ↔ `feature-plan-executor` ↔ `branch-issue-precheck.md`)가 많아 하나만 고치면 다른 곳의 참조·완료 기준 문구가 어긋나기 쉬움 — 관련 SKILL.md 전체를 grep으로 교차 확인

### devoks-git
- skill 없이 command만 존재(`git-commit-msg`, `git-create-issue`, `git-pull-request`) — 변경 시 command frontmatter/문서만 대상
- `gh` CLI 의존, 별도 MCP 서버·prefix 없음
- devoks-sdlc의 여러 커맨드/스킬이 `/devoks-git:git-commit-msg`, `/devoks-git:git-create-issue`를 텍스트로 참조함(plugin.json `dependencies`엔 미기재) — devoks-git 쪽 커맨드명·규칙을 바꾸면 devoks-sdlc 참조도 함께 확인

## 5. 비대상 사유 작성 규칙

업데이트하지 않는 파일은 아래 형식으로 남긴다.

- `<file>`: `<왜 비대상인지>`

예시:
- `README.md`: 내부 hook 주석 정정만 포함, 사용자-facing 설명 불변
- `.claude-plugin/marketplace.json`: 플러그인 추가/삭제/description/dependency 변경 없음

## 6. 완료 전 최종 확인

- [ ] 변경 플러그인별 체크리스트가 분리되어 있는가
- [ ] 각 플러그인의 version bump 필요 여부가 설명되어 있는가
- [ ] `claude plugin validate ./plugins/<plugin> --strict` 실행 여부가 기록되었는가
- [ ] 문서 대상/비대상 판단이 파일별로 남아 있는가
- [ ] MCP/prefix/permission 대조 지점이 확인되었는가
- [ ] core sync 영향이 있으면 `.claude/` 사본과 문서까지 함께 봤는가
- [ ] 신규/변경 skill이면 §7 스킬 품질 체크리스트(6축)를 적용했는가

## 7. 스킬 품질 체크리스트 (신규/변경 스킬 한정)

적용 조건: 신규 skill 생성 또는 기존 skill의 `description`/핵심 동작(트리거 조건·워크플로 단계) 변경.

| # | 축 | 검증 방식 | 적용 강도 |
|---|---|---|---|
| 1 | description ↔ 실제 동작 일치(효용성 포함) | 동적 — `evals/evals.json` 프롬프트를 서브에이전트로 실행해 `expected_output`과 대조 | 신규 skill: 필수 / 기존 skill 변경: 권장(트리거 조건 대폭 변경 시 필수) |
| 2 | `references/` 존재 | 정적 — SKILL.md 내 `references/*.md` 언급을 grep, 실제 파일과 대조 | 필수 |
| 3 | `evals/evals.json` 보유 | 정적 — 파일 존재 확인 | 신규 skill: blocking(없으면 최소 1~2개 작성) / 기존 skill 변경: 권장 |
| 4 | 의존 MCP/도구 명시 | 정적 — 위 "3. MCP / prefix / permission 점검 포인트" 대조 지점 재사용 | 필수 |
| 5 | 설치 후 경로 참조 안전성 | 정적 — 플러그인 루트 밖 상대경로(`../`) grep, `${CLAUDE_PLUGIN_ROOT}` 사용 확인 | 필수 |
| 6 | 토큰효율성 | 정적(SKILL.md 라인수·인라인 대용량 예시·`references/` 분리 여부) + 동적(축 1 실행 시 토큰/턴수 관찰) | 신규 skill: 필수 / 기존 skill 변경: 권장 |

### 동적 검증(축 1·6) 실행 방법

1. 대상 skill의 `evals/evals.json`에서 프롬프트를 가져온다(없으면 최소 1~2개 신규 작성).
2. 서브에이전트(`Agent` 도구, 신선한 컨텍스트)에 프롬프트를 그대로 전달해 skill을 실제로 트리거시킨다.
3. 결과를 `expected_output`과 대조해 description-동작 일치·효용성을 판정한다.
4. 실행 과정에서 관찰된 토큰/턴 소모가 skill의 목적·워크플로 복잡도 대비 과도한지 판단한다(예: 단순 조회성 skill이 references를 불필요하게 여러 개 순차 로드하는지).
5. 신규 skill은 이 실행을 생략할 수 없다.

### 정적 체크(축 2~6) 실행 방법

- 축 2: `grep -o 'references/[a-zA-Z0-9_.-]*\.md' SKILL.md` 결과와 `references/` 디렉토리 실제 파일 목록 대조
- 축 3: `evals/evals.json` 파일 존재 확인
- 축 4: 위 §3 "MCP / prefix / permission 점검 포인트" 절차 재사용
- 축 5: `grep -n '\.\./' skills/<name>/SKILL.md` 등으로 플러그인 루트 밖 상대경로 참조 여부 확인
- 축 6: SKILL.md 라인 수(`wc -l`), 본문 내 대용량 코드블록/예시 유무, `references/` 분리 여부 확인
