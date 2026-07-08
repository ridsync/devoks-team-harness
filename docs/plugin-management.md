# 플러그인 관리 가이드

플러그인 추가·생성·검증·배포 전체 워크플로우를 정리합니다.

> **공식 레퍼런스**
> - 플러그인 만들기: https://code.claude.com/docs/ko/plugins
> - 마켓플레이스 생성·배포: https://code.claude.com/docs/ko/plugin-marketplaces
> - 검증 및 테스트: https://code.claude.com/docs/ko/plugin-marketplaces#validation-and-testing
> - 플러그인 레퍼런스(스키마 전체): https://code.claude.com/docs/ko/plugins-reference
> - 서브에이전트(agent) 정의: https://code.claude.com/docs/en/sub-agents

---

## 1. 디렉토리 구조

```
plugins/<plugin-name>/
├── .claude-plugin/
│   └── plugin.json          # 필수: 플러그인 매니페스트
├── commands/                # 슬래시 커맨드 (.md 파일)
│   └── my-command.md
├── skills/                  # 스킬 (SKILL.md 포함 디렉토리)
│   └── my-skill/
│       └── SKILL.md
├── hooks/                   # 훅 (선택)
│   └── hooks.json
└── agents/                  # 에이전트 정의 (선택)
    └── my-agent.md
```

> **중요**: 플러그인 설치 시 디렉토리 전체가 캐시 위치에 복사됩니다.  
> `../shared-utils` 처럼 플러그인 루트 **외부** 파일을 참조하면 설치 후 동작하지 않습니다.  
> 공유 파일이 필요한 경우 **symlink**를 사용하세요.

---

## 2. plugin.json 스키마

### 필수 필드

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "한 줄 설명",
  "author": { "name": "ridsync" }
}
```

### 전체 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `name` | string | **필수**. kebab-case 권장 (대문자·공백 포함 시 Claude.ai 마켓플레이스 동기화 거부) |
| `version` | string | semver 권장 (예: `"1.0.0"`). 없으면 git 커밋 SHA로 대체 |
| `description` | string | 플러그인 설명 |
| `author` | object | `{ "name": "...", "email": "..." }` |
| `homepage` | string | 문서/홈페이지 URL |
| `repository` | string | 소스 저장소 URL |
| `license` | string | SPDX 식별자 (예: `"MIT"`) |
| `keywords` | array | 검색·분류 태그 |
| `mcpServers` | object | **플랫 맵** — `{ "server-name": { command, args, type } }` |
| `skills` | string\|array | skill 디렉토리 경로 (기본값: `./skills`) |
| `commands` | string\|array | command 파일 경로 (기본값: `./commands`) |
| `hooks` | string\|object | hooks.json 경로 또는 인라인 설정 |
| `agents` | string\|array | 에이전트 파일 경로 |

### mcpServers — 올바른 구조

```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"],
      "type": "stdio"
    },
    "figma": {
      "command": "npx",
      "args": ["-y", "figma-mcp@latest"],
      "type": "stdio"
    }
  }
}
```

> **주의**: `required` / `optional` / `interactive` 중첩 키는 유효하지 않습니다.  
> 서버 이름을 최상위 키로 직접 사용해야 합니다.

---

## 3. command 파일 작성 (.md)

`commands/my-command.md` — 반드시 YAML frontmatter를 포함합니다.

```markdown
---
description: 이 커맨드가 수행하는 작업을 한 줄로 설명한다.
---

# 커맨드 제목

## Overview

커맨드 본문...
```

> frontmatter 없으면 `--strict` 검증 실패 (경고).  
> `description:` 값에 `: ` (콜론+공백)이 포함되면 YAML 파싱 오류 → **쌍따옴표로 감싸야** 합니다.

---

## 4. skill 파일 작성 (SKILL.md)

`skills/my-skill/SKILL.md`:

```markdown
---
name: my-skill
description: "스킬 설명 — 콜론이 포함되면 쌍따옴표 필수."
---

## 스킬 본문

...
```

> **주의**: 플러그인 루트의 `CLAUDE.md`는 설치 후 컨텍스트에 로드되지 않습니다.  
> 컨텍스트를 주입하려면 반드시 `skills/<name>/SKILL.md`를 사용하세요.

---

## 5. marketplace.json 등록

`.claude-plugin/marketplace.json`에 신규 플러그인 항목을 추가합니다. 현재 마켓플레이스 식별자는 **`devoks-plugins`** 입니다 (예전 `devoks`에서 변경됨 — 기존 등록이 있다면 `/plugin marketplace remove devoks` 후 재등록).

```json
{
  "name": "devoks-plugins",
  "owner": { "name": "ridsync" },
  "plugins": [
    {
      "name": "my-new-plugin",
      "source": "./plugins/my-new-plugin",
      "description": "플러그인 설명"
    }
  ]
}
```

| 필드 | 필수 | 설명 |
|------|------|------|
| `name` | ✅ | 플러그인 식별자 (kebab-case) |
| `source` | ✅ | 플러그인 디렉토리 상대 경로 (`..` 포함 불가) |
| `description` | 권장 | 사용자에게 표시되는 설명 |
| `dependencies` | 선택 | `["devoks-core@devoks-plugins"]` 형태 |
| `version` | 선택 | 명시 시 해당 값이 변경될 때만 업데이트 배포 |

---

## 6. 검증 (Validation)

### 기본 검증

```bash
claude plugin validate ./plugins/my-plugin
```

### Strict 검증 (CI 권장)

```bash
# 경고도 에러로 처리 — PR 머지 전 실행
claude plugin validate ./plugins/my-plugin --strict
```

### 전체 플러그인 일괄 검증

```bash
for plugin in devoks-core devoks-git devoks-sdlc devoks-browser devoks-rn; do
  echo "=== $plugin ==="
  claude plugin validate ./plugins/$plugin --strict
done
```

### 에러·경고 대응표

| 메시지 | 원인 | 해결 |
|--------|------|------|
| `mcpServers: Invalid input` | `required`/`optional` 중첩 구조 사용 | 플랫 맵으로 변경 |
| `YAML frontmatter failed to parse` | description 값에 `: ` 포함 | 값을 쌍따옴표로 감쌈 |
| `No frontmatter block found` | command/skill 파일에 frontmatter 없음 | `---` 블록 추가 |
| `version: No version specified` | plugin.json에 `version` 없음 | semver 추가 |
| `CLAUDE.md at the plugin root is not loaded` | 플러그인 루트 CLAUDE.md | `skills/<name>/SKILL.md`로 이전 |
| `File not found: .claude-plugin/plugin.json` | plugin.json 누락 | 파일 생성 |
| `Path contains ".."` | source 경로에 `..` 포함 | 플러그인 루트 기준 경로 사용 |

---

## 7. 로컬 테스트

배포 전 로컬에서 설치를 검증합니다.

```bash
# 로컬 마켓플레이스로 테스트 설치
/plugin marketplace add ./devoks-team-harness
/plugin install my-new-plugin@devoks-plugins

# 설치 확인
/plugin list

# 마켓플레이스 제거 (테스트 후)
/plugin marketplace remove devoks-plugins
```

---

### 저장소 maintainers용 로컬 skill

이 저장소에서 플러그인 변경 작업을 시작할 때는 배포용 플러그인 기능과 별개로, **로컬 유지보수 스킬**을 먼저 사용하는 것을 권장합니다.

- 위치: `.claude/skills/devoks-plugin-maintenance/SKILL.md`
- 목적: 플러그인 변경 시 **버전 bump → `validate --strict` → 문서/카탈로그 반영 → MCP prefix / permissions / cross-reference 점검** 순서를 누락 없이 강제
- 성격: `plugins/devoks-*`에 배포되는 기능이 아니라, **이 저장소 maintainers용 로컬 워크플로우**

이 스킬은 특히 아래 상황에서 먼저 사용하는 것을 권장합니다.

- 플러그인 기능 추가 / 버그 수정
- skill / command / agent 이름 또는 description 변경
- `plugin.json`의 `mcpServers` / `settings.permissions.allow` 변경
- `docs/mcp-setup-guide.md`, `plugins/devoks-core/commands/setup-mcp.md`, `plugins/devoks-core/hooks/check-mcp.sh` 와의 정합성 확인이 필요한 변경
- `devoks-core`의 `refs/`, `rules/`, `sync-context.sh` 영향 검토가 필요한 변경

상세 체크 항목은 로컬 skill의 reference 문서 `references/workflow-checklist.md`를 기준으로 유지합니다.

---

## 8. 배포 워크플로우

```
수정 → 검증 → 버전 bump → 커밋 → push → 팀원 업데이트
```

### 단계별 체크리스트

```bash
# 1. 플러그인 수정 후 검증
claude plugin validate ./plugins/<plugin> --strict

# 2. plugin.json 버전 bump (patch/minor/major)
#    예: "1.0.0" → "1.0.1"

# 3. 커밋 (devoks-git:git-commit-msg 커맨드 활용)
/devoks-git:git-commit-msg

# 4. GitHub push
git push origin main

# 5. 팀원은 다음 명령으로 업데이트
/plugin marketplace update devoks-plugins
```

### 버전 전략

| 방식 | 동작 | 권장 상황 |
|------|------|----------|
| `version` 명시 | 값이 변경될 때만 업데이트 배포 | 안정적 릴리스 관리 |
| `version` 생략 | 모든 git 커밋이 새 버전으로 인식 | 빠른 이터레이션 |

---

## 9. 팀 자동 적용 (settings.json)

프로젝트 `.claude/settings.json`에 추가하면 팀원이 저장소를 신뢰할 때 마켓플레이스가 자동 설치됩니다.

```json
{
  "extraKnownMarketplaces": {
    "devoks-plugins": {
      "source": {
        "source": "github",
        "repo": "ridsync/devoks-team-harness"
      }
    }
  },
  "enabledPlugins": {
    "devoks-core@devoks-plugins": true,
    "devoks-git@devoks-plugins": true
  }
}
```

---

## 10. 마켓플레이스 관리 명령어

```bash
# 마켓플레이스 추가
/plugin marketplace add ridsync/devoks-team-harness    # GitHub
/plugin marketplace add ./my-local-dir                 # 로컬 경로

# 목록 확인
/plugin marketplace list

# 업데이트 (최신 커밋 반영)
/plugin marketplace update devoks-plugins
/plugin marketplace update           # 전체 업데이트

# 제거
/plugin marketplace remove devoks-plugins
```

```bash
# 플러그인 설치·관리
/plugin install devoks-core@devoks-plugins
/plugin list
/plugin uninstall devoks-core@devoks-plugins
```

---

## 11. 인증 (Private 저장소)

```bash
# ~/.bashrc 또는 ~/.zshrc에 추가
export GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx
```

CI/CD 환경에서는 시크릿 환경 변수로 구성합니다. GitHub Actions는 같은 조직 저장소에 `GITHUB_TOKEN`을 자동 제공합니다.

---

## 12. Agent 파일 작성과 모델 선택 가이드

`agents/my-agent.md` — YAML frontmatter를 포함한 Markdown 파일입니다.

```markdown
---
name: my-agent
description: 이 에이전트가 언제 호출되어야 하는지 설명한다.
tools: Read, Grep, Glob
model: sonnet
---

시스템 프롬프트 본문...
```

### Frontmatter 필드

| 필드 | 필수 | 설명 |
|------|------|------|
| `name` | ✅ | 소문자·하이픈 식별자 |
| `description` | ✅ | Claude가 언제 이 에이전트에 위임할지 판단하는 기준 |
| `tools` | 선택 | 생략 시 전체 tool 상속 |
| `model` | 선택 | `sonnet` \| `opus` \| `haiku` \| `fable` \| 전체 모델 ID(예: `claude-opus-4-8`) \| `inherit`. **생략 시 기본값은 `inherit`**(메인 세션 모델을 그대로 상속) |
| `effort` | 선택 | `low` \| `medium` \| `high` \| `xhigh` \| `max` (모델별 일부 레벨만 가용). 생략 시 세션 effort 상속. 플러그인 배포 에이전트에서의 지원은 공식 문서에 명시돼 있지 않음(미지원 환경에서는 무시됨) |

> 모델 결정 우선순위: `CLAUDE_CODE_SUBAGENT_MODEL` 환경변수 > 호출 시 `model` 파라미터 > agent frontmatter > 메인 세션(`inherit`).

### `effort` 미지원 환경에서의 기대 동작

`effort` frontmatter는 **있으면 보너스, 없으면 `model` 단독으로도 목표를 달성**하는 전제로 설계한다. 미지원 환경에서는 필드가 조용히 무시되고, 해당 에이전트는 `model`(예: `opus`) + 세션 기본 effort로만 동작한다.

| 에이전트 | `effort: high` 미지원 시 |
|---|---|
| `code-security-reviewer` | `opus` 단독으로 보안 감사 수행 — 품질 기준은 유지하되, 추론 깊이 상한은 세션 기본 effort에 따름. **필수 전제가 아님** |
| 향후 `effort: low` 후보(lint-formatter 등) | `haiku` + 기본 effort — 저난도 작업이라 영향 미미 |

팀 배포 전 `claude plugin validate ./plugins/<plugin> --strict`로 frontmatter 유효성을 확인하고, 보안 검증 품질이 critical path이면 메인 세션 모델·effort도 함께 점검한다.

### 모델 선택 기준 (quality-first)

| 작업 성격 | 권장 `model` | 근거 |
|---|---|---|
| 단순 조회/검색/포맷 정리 (저난도·고빈도) | `haiku` | 판단 난이도 낮고 결과 검증이 쉬움 — 지연·rate limit 절약 |
| 설계 판단이 포함된 조사·문서 종합 | `sonnet` | 단순 검색 이상의 판단은 Sonnet |
| 일반 품질/버그 리뷰형 (코드리뷰, 비주얼 diff) | `sonnet` 고정 | 세션 모델과 무관하게 판단 품질을 일관 유지 — `code-reviewer`, `browser-visual-diff-capture` 적용 사례 |
| 스펙 확정 구현 실행 (태스크 위임형) | `sonnet` 고정 | plan(메인 루프)·execute(위임) 역할 분리 — Anthropic 공식 권장 패턴("plan with Opus, execute with Sonnet", [Claude Code 사용량 가이드](https://support.claude.com/en/articles/14552983-models-usage-and-limits-in-claude-code)) 적용. 스코프 초과 시 blocked→메인 루프 인수가 안전장치 — `code-implementer` 적용 사례 |
| 실패 비용이 최대인 감사형 (auth·입력검증·동시성·정합성 보안검증) | `opus` + `effort: high`(가능 시) | 품질 최우선 — `code-security-reviewer`. `effort` 미지원 시 `opus` 단독(위 표 참고) |
| 크로스파일·설계 변경 구현, 장기 체인 추론 | `opus` + `effort: high` 검토 | 첫 시도 정확도가 중요 — 비용/지연 트레이드오프 선검토 |

> **Fable은 subagent 상시 배치에서 제외**한다. Fable 5는 장시간 자율성·비전 워크플로에서 Opus 4.8 대비 개선됐지만(공식 Fable 5 프롬프팅 가이드 참고), 초고난도 1회성 작업은 메인 세션에서 `/model fable` 수동 전환으로 처리한다.

### 서브에이전트 분리·티어링 판단 3기준

작업 카테고리("버그수정 → Sonnet")가 아니라 **작업의 형태**로 판단한다 — 난이도 높은 디버깅은 오히려 추론 집약적이다.

1. **스펙 완결성** — 입력이 자기완결적인가(예: PLAN Task 블록의 TASK-ID·`file:`·`traces:`). 완결적일수록 위임 적합.
2. **인터랙션 필요성** — 승인 게이트·사용자 질문이 절차의 본질인가. 서브에이전트는 사용자 질문이 불가하므로, 승인 게이트형 작업(FRD/PLAN 정련·리팩토링 설계 등 추론형 스킬)은 **의도적으로 메인 루프·세션 모델에서 실행**한다.
3. **컨텍스트 격리 이득** — 대량 파일 읽기·테스트/린트/audit 출력이 메인 대화 컨텍스트를 오염시키는가. 클수록 위임 이득이 크다.

### 역할 아키타입 → devoks 매핑

| 아키타입 | 권장 모델 | devoks 대응 |
|---|---|---|
| explorer (경로·심볼 검색, 요약 반환) | `haiku` | 빌트인 `Explore` 에이전트 사용 — 자체 신설 안 함 |
| researcher (설계 판단 포함 조사) | `sonnet` | `code-analyze-module` (메인 루프) — 에이전트화는 향후 후보 |
| code-reviewer (일반 품질/버그) | `sonnet` | `code-reviewer` (기존) |
| security-reviewer (auth·입력검증·동시성·정합성) | `opus` + `effort: high` | `code-security-reviewer` |
| implementer (스코프 확정 구현) | `sonnet` | `code-implementer`, `test-writer`(테스트 작성 — 동일 근거: 대상 코드에 이미 정의된 동작을 검증하는 실행형) |
| implementer-hard (크로스파일·설계 변경) | `opus` + `effort: high` | 별도 에이전트 없음 — blocked 에스컬레이션으로 메인 루프(세션 모델)가 담당 |
| architect (설계·ADR·장기 계획) | `opus` + `effort: high` | 메인 루프 유지 — 승인 게이트가 본질 (`feature-frd-author` 등) |
| test-runner (실행·실패 원인 해석) | `sonnet` | `test-run-triage` (메인 루프 + context-mode 격리) — 에이전트화는 향후 후보 |
| docs-writer (문서 작성·갱신) | `sonnet` | 향후 후보 |
| lint-formatter (단순 lint·format) | `haiku` + `effort: low` | 향후 후보 (현재 빈도 낮음 — YAGNI) |

> **작성 체크리스트**: 신규 agent를 만들 때는 `model`(필요 시 `effort`) 필드를 반드시 의도적으로 결정한다. `inherit`으로 두기로 했어도 명시적으로 `model: inherit`을 적어 의도를 남긴다(공식 `code-reviewer` 예시가 이 패턴을 따른다).

---

## 참고 링크

| 주제 | URL |
|------|-----|
| 플러그인 만들기 | https://code.claude.com/docs/ko/plugins |
| 마켓플레이스 생성·배포 | https://code.claude.com/docs/ko/plugin-marketplaces |
| 검증 및 테스트 | https://code.claude.com/docs/ko/plugin-marketplaces#validation-and-testing |
| 플러그인 레퍼런스 (전체 스키마) | https://code.claude.com/docs/ko/plugins-reference |
| 플러그인 의존성 | https://code.claude.com/docs/ko/plugin-dependencies |
| 플러그인 설정 | https://code.claude.com/docs/ko/settings#plugin-settings |
