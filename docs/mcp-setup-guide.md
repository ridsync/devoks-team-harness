# MCP & 의존성 설치 가이드

DevOks 팀 하네스의 스킬·커맨드가 사용하는 MCP 서버와 외부 도구의 설치 방법을 정리합니다.

---

## 의존성 매트릭스

| 플러그인 / 스킬 | 필수 | 선택 |
|----------------|------|------|
| **devoks-core** | — | — |
| **devoks-git** | `gh` CLI | — |
| **devoks-feature** (commands) | `gh` CLI | Figma MCP (`devoks-new-ui-draft`) |
| **devoks-feature** (skills: frd/plan) | — | CodeGraph MCP, Serena MCP |
| **devoks-feature** (skills: workflow-runner) | Figma MCP, context-mode MCP | CodeGraph MCP, Serena MCP |
| **devoks-feature** (skills: data-verify) | Chrome DevTools MCP | Playwright MCP |
| **devoks-code** | CodeGraph MCP, Serena MCP | context-mode MCP |
| **devoks-browser** (chrome-devtools) | Chrome DevTools MCP + `~/.claude.json` | — |
| **devoks-browser** (visual-diff) | Figma MCP, Playwright MCP | Chrome DevTools MCP |

---

## 1. GitHub CLI (`gh`)

devoks-git 커맨드와 devoks-feature의 GitHub 이슈 기반 커맨드에 필요합니다.

```bash
# macOS
brew install gh

# 인증
gh auth login
# → 브라우저 또는 토큰으로 로그인

# 확인
gh api user --jq '.login'
```

---

## 2. Figma MCP

`devoks-new-ui-draft`, `devoks-feature-workflow-runner`, `devoks-visual-diff-verification` 에 필요합니다.

### 설치

Claude Code 내에서:
```
/plugin install @figma/figma-mcp
```

또는 수동 (`~/.claude.json`):
```json
{
  "mcpServers": {
    "figma": {
      "command": "npx",
      "args": ["@figma/figma-mcp@latest"],
      "type": "stdio"
    }
  }
}
```

### 인증

Figma 계정 연결은 최초 도구 호출 시 브라우저 OAuth 플로우로 진행됩니다.

---

## 3. Chrome DevTools MCP

`devoks-chrome-devtools-mcp-attach` 스킬과 `devoks-data-verification` (browser 환경)에 필요합니다.

### 3-1. 플러그인 설치 (스킬 파일 로딩)

```
/plugin install chrome-devtools-mcp@chrome-devtools-plugins
```

> 이 명령은 SKILL.md를 로드할 뿐입니다. 실제 MCP 연결 설정은 3-2가 필요합니다.

### 3-2. `~/.claude.json`에 MCP 서버 추가 (필수)

```json
{
  "mcpServers": {
    "chrome-devtools-attach": {
      "command": "npx",
      "args": ["chrome-devtools-mcp@latest", "--browserUrl", "http://127.0.0.1:9269"],
      "type": "stdio"
    }
  }
}
```

> ⚠ **주의**: `~/.claude.json`과 `~/.claude/settings.json`은 다른 파일입니다.
> MCP 서버 등록은 `~/.claude.json`에 해야 합니다.

### 3-3. Chrome 디버그 모드로 실행

```bash
# macOS
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --remote-debugging-port=9269 \
  --user-data-dir="$HOME/.claude/chrome-dev-mcp/" \
  http://localhost:5500

# 연결 확인
curl -s http://127.0.0.1:9269/json | python3 -m json.tool
```

### 사용하는 도구 prefix

```
mcp__chrome-devtools-attach__*
```

> `mcp__plugin_chrome-devtools-mcp_chrome-devtools__*` 와 혼용하지 마세요 (다른 prefix).

---

## 4. Playwright MCP

`devoks-visual-diff-verification`의 라이브 렌더 캡처 기본 도구입니다.

### 설치

```
/plugin install @playwright/playwright-mcp
```

또는 `~/.claude.json`:
```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["@playwright/playwright-mcp@latest"],
      "type": "stdio"
    }
  }
}
```

---

## 5. CodeGraph MCP

`devoks-code` 커맨드와 FRD/PLAN 스킬의 코드 탐색에 필요합니다.

### 설치 및 초기화

CodeGraph는 먼저 프로젝트를 인덱싱해야 합니다:

```bash
# CodeGraph CLI 설치 (npx 또는 전역 설치)
npm install -g @codegraph/mcp-server  # 실제 패키지명은 팀 내 설정 확인

# 프로젝트 인덱싱 (프로젝트 루트에서)
codegraph index .

# Claude Code에 MCP 서버 등록
/mcp add codegraph
```

또는 `~/.claude.json`:
```json
{
  "mcpServers": {
    "codegraph": {
      "command": "codegraph",
      "args": ["serve"],
      "type": "stdio"
    }
  }
}
```

> ⚠ CodeGraph의 정확한 설치 명령은 팀 내 설정을 확인하세요. 프로젝트마다 다를 수 있습니다.

---

## 6. Serena MCP

심볼 단위 정밀 코드 편집(`devoks-code`, FRD/PLAN 스킬)에 필요합니다.

### 설치

Serena는 Python 기반 LSP MCP 서버입니다:

```bash
# uv 설치 (없는 경우)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Serena 설치
uvx install serena
```

`~/.claude.json`에 추가:
```json
{
  "mcpServers": {
    "serena": {
      "command": "uvx",
      "args": ["serena@latest", "--project", "/path/to/your/project"],
      "type": "stdio"
    }
  }
}
```

> Serena는 프로젝트 경로를 `--project`로 지정해야 합니다. 프로젝트마다 설정이 다릅니다.

---

## 7. context-mode MCP

`devoks-feature-workflow-runner`의 대용량 출력 처리와 세션 지식베이스에 필요합니다.

### 설치

```
/plugin install context-mode
```

또는 `~/.claude.json`:
```json
{
  "mcpServers": {
    "context-mode": {
      "command": "npx",
      "args": ["context-mode-mcp@latest"],
      "type": "stdio"
    }
  }
}
```

---

## 8. Context7 MCP (선택)

라이브러리 문서 조회에 사용됩니다 (devoks-feature, devoks-code의 웹 검색 대안).

```bash
# ~/.claude.json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"],
      "type": "stdio"
    }
  }
}
```

---

## `~/.claude.json` 전체 템플릿

`shared/setup/claude.json.template` 파일을 복사해 사용하세요:

```bash
cp devoks-team-harness/shared/setup/claude.json.template ~/.claude.json
# 이후 필요 없는 항목 제거 및 경로 수정
```

---

## Claude Code `/mcp` 명령어 참고

```
/mcp list              # 등록된 MCP 서버 목록 및 상태
/mcp add <name>        # MCP 서버 추가 (대화형)
/mcp remove <name>     # MCP 서버 제거
```

---

## 플러그인 조합별 최소 설치

### 최소 구성 (Git 워크플로우만)
```bash
brew install gh && gh auth login
/plugin install devoks-core@devoks
/plugin install devoks-git@devoks
```

### 기능개발 구성
```bash
# 위 최소 구성 +
/plugin install devoks-feature@devoks
/plugin install @figma/figma-mcp    # new-ui-draft 사용 시
```

### 코드 품질 구성
```bash
# 최소 구성 +
/plugin install devoks-code@devoks
# ~/.claude.json에 codegraph, serena 추가
```

### 풀 구성
```bash
# 전체 설치
/plugin install devoks-core@devoks
/plugin install devoks-git@devoks
/plugin install devoks-feature@devoks
/plugin install devoks-code@devoks
/plugin install devoks-browser@devoks

# MCP 설치
/plugin install @figma/figma-mcp
/plugin install @playwright/playwright-mcp
# ~/.claude.json에 chrome-devtools-attach, codegraph, serena 추가
```
