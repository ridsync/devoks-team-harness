# 플러그인 관리 가이드

플러그인 추가·생성·검증·배포 전체 워크플로우를 정리합니다.

> **공식 레퍼런스**
> - 플러그인 만들기: https://code.claude.com/docs/ko/plugins
> - 마켓플레이스 생성·배포: https://code.claude.com/docs/ko/plugin-marketplaces
> - 검증 및 테스트: https://code.claude.com/docs/ko/plugin-marketplaces#validation-and-testing
> - 플러그인 레퍼런스(스키마 전체): https://code.claude.com/docs/ko/plugins-reference

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
for plugin in devoks-core devoks-git devoks-feature devoks-verify devoks-code devoks-test devoks-browser devoks-rn; do
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

## 참고 링크

| 주제 | URL |
|------|-----|
| 플러그인 만들기 | https://code.claude.com/docs/ko/plugins |
| 마켓플레이스 생성·배포 | https://code.claude.com/docs/ko/plugin-marketplaces |
| 검증 및 테스트 | https://code.claude.com/docs/ko/plugin-marketplaces#validation-and-testing |
| 플러그인 레퍼런스 (전체 스키마) | https://code.claude.com/docs/ko/plugins-reference |
| 플러그인 의존성 | https://code.claude.com/docs/ko/plugin-dependencies |
| 플러그인 설정 | https://code.claude.com/docs/ko/settings#plugin-settings |
