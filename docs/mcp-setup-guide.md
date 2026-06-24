# MCP & 의존성 설치 가이드

DevOks 팀 하네스의 스킬·커맨드가 사용하는 MCP 서버와 외부 도구의 설치 방법을 정리합니다.

---

## 설치 정책 (중요)

DevOks 플러그인은 범용·공유 MCP 서버(Figma·Playwright·Serena·CodeGraph·context7 등)를 **번들하지 않는다**. 플러그인마다 같은 서버를 중복 선언하면 user/project scope에 이미 설치된 서버와 충돌하고(서로 다른 인스턴스·포트·파일락), 사용 가능한 도구 수가 환경마다 달라지기 때문이다.

- **원칙**: 공유 MCP는 **user 또는 project scope에 1회만** 설치한다. 플러그인은 그 단일 서버를 참조만 한다.
- **예외**: `devoks-browser`의 `chrome-devtools-attach`(`:9269` 연결 전용 고유 설정)만 플러그인이 번들한다. `devoks-rn`의 `metro-devtools`는 `/devoks-setup-mcp` Step 5로 user scope에 설치한다 (Metro URL 자동 조회, 재시작 자동 적응).
- **자동 안내**: `devoks-core`의 SessionStart 훅(`hooks/check-mcp.sh`)이 매 세션 시작 시 권장 MCP의 설치 여부를 점검하고, **누락 항목만** 설치 명령과 함께 안내한다. 모두 설치돼 있으면 아무것도 출력하지 않는다(멱등·non-blocking).
- **도구 네임스페이스 주의**: 설치 방식에 따라 도구 prefix가 다르다 — 플러그인 설치 → `mcp__plugin_<plugin>_<server>__*`, `claude mcp add` → `mcp__<server>__*`. 스킬이 하드코딩한 prefix(Figma=`mcp__plugin_figma_figma__*`, Playwright=`mcp__plugin_playwright_playwright__*`)와 맞추려면 해당 서버는 **플러그인으로 설치**한다.

---

## 빠른 설치 (`/devoks-setup-mcp`)

`devoks-core`의 `/devoks-setup-mcp` 커맨드를 실행하면 누락된 권장 MCP를 현재 상태에 맞춰 한 번에 설치한다.

- **자동(shell)**: context7·codegraph·serena 를 `claude mcp add --scope user`로 설치(serena는 현재 프로젝트 경로 자동 적용).
- **안내(플러그인)**: figma·playwright 는 prefix 일치를 위해 `/plugin install` 경로를 안내한다(자동 설치하지 않음).
- 이미 설정된 항목은 건너뛰고, 전역 설정 변경 전 실행 명령을 보여주고 확인받는다.

수동 설치가 필요하거나 각 서버의 세부 옵션·인증·초기화가 궁금하면 아래 절을 참고한다.

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
| **devoks-browser** (visual-diff) | Figma MCP, Chrome DevTools MCP (attach) | Playwright MCP (폴백) |
| **devoks-rn** (`metro-devtools-attach`) | `devoks-rn` 플러그인, Metro 실행 중 | `metro-devtools` (user scope — `/devoks-setup-mcp` Step 5); `adb` / `xcrun simctl` (스크린샷) |

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

`devoks-feature:new-ui-draft`, `devoks-feature:feature-workflow-runner`, `devoks-browser:browser-visual-diff` 에 필요합니다.

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

`devoks-browser:browser-devtools` 스킬, `devoks-browser:browser-visual-diff`의 라이브 렌더 캡처(**기본 도구**), `devoks-verify:verify-data-flow`(browser 환경)에 필요합니다.

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

`devoks-browser:browser-visual-diff`의 라이브 렌더 캡처 **폴백 도구**입니다(기본 도구는 Chrome DevTools MCP).

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

## 7. Metro DevTools MCP (React Native)

`devoks-rn:metro-devtools-attach` 스킬 — JS 콘솔 확인, Zustand·TanStack Query 상태 조회, 네트워크 모니터링에 필요합니다. 에뮬레이터 스크린샷은 MCP 없이 `adb`/`xcrun simctl`로 즉시 사용 가능합니다.

### 7-1. 플러그인 설치

```
/plugin install devoks-rn@devoks-plugins
/reload-plugins
```

### 7-2. metro-devtools MCP 설치 (`/devoks-setup-mcp` Step 5)

`devoks-rn` 플러그인에 번들된 `metro-mcp.js`를 `~/.devoks/mcp/`에 복사한 뒤 user scope에 등록합니다.  
Metro `/json` 엔드포인트로 WebSocket URL을 **자동 조회**하므로, Metro 재시작 후 별도 갱신 없이 자동 적응합니다.

```bash
# 1. 스크립트를 devoks 관리 경로에 복사
mkdir -p ~/.devoks/mcp
SCRIPT=$(find ~/.claude/plugins/cache/devoks-plugins/devoks-rn -name "metro-mcp.js" \
          -path "*/scripts/*" 2>/dev/null | sort -V | tail -1)
cp "$SCRIPT" ~/.devoks/mcp/metro-mcp.js

# 2. user scope에 등록
claude mcp add metro-devtools --scope user \
  -- node --experimental-websocket ~/.devoks/mcp/metro-mcp.js
```

Claude Code 재시작 후 `mcp__metro-devtools__*` 도구가 활성화됩니다.

> ⚠ `devoks-rn` 플러그인 업데이트 후에는 위 1·2단계를 재실행해 스크립트를 갱신하세요.

### 사용하는 도구 prefix

```
mcp__metro-devtools__*
```

> `mcp__plugin_devoks-rn_metro-devtools__*` 및 `mcp__chrome-devtools-attach__*` 와 혼용하지 마세요.

자세한 디버깅 패턴·트러블슈팅 → `devoks-rn:metro-devtools-attach` 스킬 또는 `/devoks-setup-mcp` 커맨드.

---

## 8. context-mode MCP

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

## 9. Context7 MCP (선택)

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
/plugin install devoks-core@devoks-plugins
/plugin install devoks-git@devoks-plugins
```

### 기능개발 구성
```bash
# 위 최소 구성 +
/plugin install devoks-feature@devoks-plugins
/plugin install @figma/figma-mcp    # new-ui-draft 사용 시
```

### 코드 품질 구성
```bash
# 최소 구성 +
/plugin install devoks-code@devoks-plugins
# ~/.claude.json에 codegraph, serena 추가
```

### React Native 구성
```bash
# 최소 구성 +
/plugin install devoks-rn@devoks-plugins
# Metro 실행 후 /devoks-setup-mcp Step 5 실행 — metro-devtools user scope 등록 (7절 참조)
```

### 풀 구성
```bash
# 전체 설치
/plugin install devoks-core@devoks-plugins
/plugin install devoks-git@devoks-plugins
/plugin install devoks-feature@devoks-plugins
/plugin install devoks-verify@devoks-plugins
/plugin install devoks-code@devoks-plugins
/plugin install devoks-test@devoks-plugins
/plugin install devoks-browser@devoks-plugins
# /plugin install devoks-rn@devoks-plugins   # RN 프로젝트 시

# MCP 설치
/plugin install @figma/figma-mcp
/plugin install @playwright/playwright-mcp
# ~/.claude.json에 chrome-devtools-attach, codegraph, serena 추가
# RN 프로젝트: /devoks-setup-mcp Step 5 실행 — metro-devtools user scope 등록 (7절 참조)
```
