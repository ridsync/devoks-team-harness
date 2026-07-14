# Project Convention

`devoks-team-harness` 자신의 개발 컨벤션입니다. 이 저장소는 Claude Code 플러그인 마켓플레이스이며,
런타임 애플리케이션 코드(JS/React 등)를 갖지 않습니다 — 산출물은 **Markdown(SKILL/command/agent 정의) +
Bash(hooks) + JSON(plugin manifest)** 입니다. `plugins/devoks-core/conventions/*`에 있는 스택별 preset(React Web 등)은
**이 저장소가 관리하는 산출물**이지, 이 저장소 자신의 개발 스택이 아닙니다.

---

## SSOT — 경로별 소유 범위 (가장 중요)

이 저장소에는 겉보기엔 비슷한 두 종류의 `.claude/`류 경로가 공존한다. **절대 혼동하지 않는다.**

| 경로 | 소유 범위 | 용도 |
|------|----------|------|
| `/.claude/` (저장소 루트) | **이 harness 저장소 자신**에게만 유효 | harness 자신을 개발할 때 Claude Code가 참조하는 rules/refs/skills. 대상 프로젝트에 배포되지 않는다 |
| `plugins/<plugin>/` | **플러그인을 설치한 대상 프로젝트**를 위한 산출물 | 설치 시 캐시 위치로 통째 복사되어 대상 프로젝트의 세션에 로드된다. harness 저장소 자신의 설정이 아니다 |
| `plugins/devoks-core/conventions/<preset>/project-convention.md` | 대상 프로젝트에 주입될 **starter preset 원본** (devoks-core 플러그인에 번들, `${CLAUDE_PLUGIN_ROOT}/conventions/...`로 참조) | `devoks-core:setup-project-convention`이 대상 프로젝트의 `.claude/rules/project-convention.md`로 복사한다 |

**과거 사고 사례(교훈):** 레거시 `sync-context.sh`(SessionStart 훅)가 플러그인 번들 rules를 "현재 프로젝트"와
무관하게 강제 복사했고, harness 저장소 자신에서 세션을 열었을 때도 그대로 실행되어 **당시 stack preset 원본
(커피/원두 도메인 예시)이 이 파일(`/.claude/rules/project-convention.md`) 자리에 잘못 박제**됐다. 그 훅은
`1ac291e`에서 폐기되고 명시적 setup 모델로 전환됐다. **plugins/ 하위의 내용을 이 저장소 자신의 `.claude/`로
복사·동기화하는 자동 메커니즘은 더 이상 없다** — 있어서도 안 된다. `plugins/`를 수정하는 작업과 `/.claude/`를
수정하는 작업은 항상 별개의 결정이다.

---

## Stack

- **저작 포맷:** Markdown (`SKILL.md`, `commands/*.md`, `agents/*.md`, `docs/*.md`) + Bash (`hooks/*.sh`) + JSON (`plugin.json`, `marketplace.json`)
- **런타임 코드 없음** — lint/type/test 파이프라인 대상 소스가 아니다. "테스트"는 `claude plugin validate --strict` + 훅 스모크 테스트로 대체한다.
- **버전 관리:** semver 기반 `plugin.json.version` (patch/minor/major 기준은 `docs/plugin-management.md` §6 참고)

---

## 디렉토리·네이밍 구조

`docs/plugin-management.md` §1이 SSOT. 요약:

```
plugins/<plugin-name>/
├── .claude-plugin/plugin.json   # 필수, kebab-case name, semver version
├── commands/<command>.md        # frontmatter: description
├── skills/<skill>/SKILL.md      # frontmatter: name, description
├── hooks/hooks.json (+ *.sh)
└── agents/<agent>.md            # frontmatter: name, description, tools?, model?, effort?
```

- 플러그인 이름/스킬/커맨드/에이전트 이름: kebab-case, 소문자.
- 플러그인 루트 **외부** 파일 참조 금지 (`../shared-utils` 형태) — 설치 시 디렉토리 전체만 복사되므로 동작하지 않는다. 공유가 필요하면 symlink.
- 플러그인 루트의 `CLAUDE.md`는 설치 후 로드되지 않는다 — 컨텍스트 주입은 반드시 `skills/<name>/SKILL.md`로.

---

## Frontmatter 규칙

- `description`(또는 다른 YAML 값)에 `: `(콜론+공백)이 포함되면 YAML 파싱 실패 → **쌍따옴표로 감싼다.**
- SKILL.md: `name`, `description` 필수.
- command `.md`: `description` 필수, frontmatter 없으면 `--strict` 검증 실패.
- agent `.md`: `name`, `description` 필수. `model`/`effort`는 생략 시 세션 상속(`inherit`) — 신규 agent는 반드시 의도적으로 결정하고, `inherit`로 두기로 했어도 명시한다. 모델 선택 기준은 `docs/plugin-management.md` §12.

---

## 문서·주석 언어

- 문서(SKILL.md, command, docs/*)는 **한국어** 작성, 식별자·CLI 출력·코드 인용은 원문 유지.
- Bash 훅의 주석은 한국어로 의도(왜 이 분기가 필요한지)를 남긴다 — `check-setup-state.sh` 헤더 주석이 기준 예시.
- 자명한 내용에는 주석을 달지 않는다. 훅의 "왜"가 코드만으로 드러나지 않을 때만 추가한다.

---

## 변경 시 준수 절차

플러그인(`plugins/devoks-*`) 변경 작업은 반드시 `.claude/skills/devoks-plugin-maintenance/SKILL.md`를 먼저 사용한다.
이 스킬이 강제하는 순서: 변경 범위 선언 → 플러그인별 체크리스트 → 버전 bump 판단 → `claude plugin validate --strict` →
문서/카탈로그(`README.md`, `docs/README.ko.md`, `docs/mcp-setup-guide.md`, `marketplace.json`) 정합성 → MCP prefix/permission 점검 →
`devoks-core`의 `refs/rules` 변경 시 core sync 점검.

---

## Pitfall

| 실수 | 결과 | 방지 |
|------|------|------|
| `plugins/` 번들 내용을 harness 저장소 자신의 `/.claude/`로 복사·동기화 | 위 "과거 사고 사례"처럼 대상-프로젝트용 산출물이 harness 자신의 설정으로 오염 | `/.claude/`는 harness 자신 전용, `plugins/`는 설치 대상 전용 — 자동 동기화 메커니즘을 다시 두지 않는다 |
| `mcpServers`에 `required`/`optional`/`interactive` 중첩 키 사용 | `Invalid input` 검증 실패 | 서버 이름을 최상위 키로 직접 사용하는 플랫 맵 |
| `description`에 콜론+공백을 따옴표 없이 사용 | YAML frontmatter 파싱 실패 | 쌍따옴표로 감싸기 |
| `marketplace.json`의 `source`에 `..` 포함 | `Path contains ".."` 실패 | 플러그인 루트 기준 상대 경로만 사용 |
| 플러그인 변경 후 버전 bump/문서 반영 누락 | 마켓플레이스 배포 시 카탈로그 drift | `devoks-plugin-maintenance` 스킬 절차 준수 |
| `plugins/devoks-core/rules/*`를 "대상 프로젝트에 자동 복사되는 base rule"로 오해 | 실제로는 `agent-principles.md`/`memory-policy.md`만 base rule로 복사됨(`setup-project-convention.md` SSOT 참고) — 그 외 파일을 추가해도 조용히 무시됨 | 복사 대상 여부는 `setup-project-convention.md`의 SSOT 목록과 `check-setup-state.sh`의 `base_rules_ready()`로만 판단 |
| convention preset을 `plugins/devoks-core/` **바깥**(예: 저장소 루트 `shared/`)에 두기 | 설치 시 플러그인 루트만 복사되므로, 실제 설치된 대상 프로젝트에서는 preset 원본에 전혀 접근 불가(harness 저장소 자신에서만 우연히 동작) — 2026-07-14 `plugins/devoks-core/conventions/`로 이전하며 발견·수정 | preset 원본은 항상 `plugins/devoks-core/conventions/<preset>/`에 두고 `${CLAUDE_PLUGIN_ROOT}/conventions/...`로 참조 |
| 플러그인 커맨드/스킬 본문에서 저장소 루트 `docs/`·`shared/` 등을 bare 경로로 참조 | 설치된 대상 프로젝트에서는 플러그인 루트 바깥 파일이라 접근 불가 — `setup-mcp.md`가 `docs/mcp-setup-guide.md`를 참조하던 것을 2026-07-14 발견·수정(§3-3 Chrome 디버그 명령을 본문에 직접 inline) | 플러그인 루트 내부 참조는 `${CLAUDE_PLUGIN_ROOT}/...`, 저장소 루트 문서는 harness 유지보수자용 "왜" 참고로만 인용(런타임 의존 금지) |
| `.claude/rules/`·`.claude/refs/`에 devoks-core 번들 파일(`agent-principles.md`/`memory-policy.md`/`code-review.md`/`engineering-principles.md`/`git-convention.md`/`workflow.md`)이 다시 나타남 | 레거시 `sync-context.sh`가 남긴 잔재와 동일한 오염 — 이 저장소는 어떤 플러그인도 `enabledPlugins`로 활성화하지 않으므로(`.claude/settings.json`) 이 파일들을 전혀 쓰지 않는다. 2026-07-14 `.claude/project-convention.json`(provenance) 부재 확인 후 6개 파일 삭제 | `.claude/rules/`에는 이 저장소 전용으로 직접 작성한 `project-convention.md`만 유지한다. base rules/refs가 다시 나타나면 원본(`plugins/devoks-core/rules|refs/*`)과 diff 없이 그대로 삭제 |
