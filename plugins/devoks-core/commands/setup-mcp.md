---
description: DevOks 권장 MCP 서버를 현재 상태에 맞춰 user scope에 1회 설치·초기화한다.
---

# DevOks MCP Setup (`/devoks-setup-mcp`)

## SSOT

- 설치 정책·방식·prefix 규칙: [`docs/mcp-setup-guide.md`](../../../docs/mcp-setup-guide.md)를 따른다.
- 감지 로직 참고: `devoks-core` SessionStart 훅 [`hooks/check-mcp.sh`](../hooks/check-mcp.sh).

## Overview

DevOks 플러그인은 공유 MCP(context7·figma·serena·codegraph·playwright)를 번들하지 않는다.
번들 MCP와 user-scope MCP는 병합되지 않고 별도 프로세스 + 다른 도구 prefix로 공존해
중복·충돌을 일으키기 때문이다. 이 커맨드는 누락된 권장 MCP만 골라 **user scope에 1회 설치**한다.

**핵심 제약 — 설치 방식이 도구 prefix를 결정한다:**
- `claude mcp add` → `mcp__<server>__*`
- 플러그인 설치 → `mcp__plugin_<plugin>_<server>__*`

스킬이 하드코딩한 prefix와 맞추기 위해 **figma·playwright는 반드시 플러그인으로** 설치하고
(`claude mcp add`로 깔면 prefix 불일치로 스킬이 깨진다), context7·codegraph·serena는 `claude mcp add`로 설치한다.

## Steps

1. **현재 상태 감지 (멱등)**
   - `claude mcp list`를 실행해 등록된 MCP 서버를 확인한다. 보조로 `~/.claude.json`을 확인한다.
   - 이미 설정된 항목은 **건너뛴다**. 아래 액션은 누락된 항목에만 적용한다.

2. **설치 계획 제시 및 확인**
   - `~/.claude.json`은 전역 설정이므로, 실제로 실행할 `claude mcp add` 명령 목록을 먼저 사용자에게 보여주고
     **확인을 받은 뒤** 실행한다.
   - 사용자가 특정 항목만 선택할 수 있게 한다(예: context7만, serena 제외 등).

3. **user scope 설치 (shell — 직접 실행)**
   - **context7** (문서조회, 선택):
     ```bash
     claude mcp add context7 --scope user -- npx -y @upstash/context7-mcp@latest
     ```
   - **codegraph** (코드그래프, 선택):
     ```bash
     claude mcp add codegraph --scope user -- npx -y codegraph-mcp@latest
     ```
     설치 후 현재 프로젝트에 `.codegraph/`가 없으면 인덱싱을 제안한다:
     `codegraph init "$CLAUDE_PROJECT_DIR"` (CLI 설치돼 있을 때).
   - **serena** (심볼 탐색·리팩토링, 권장):
     - 먼저 `uvx` 존재를 확인한다(`command -v uvx`). 없으면 설치를 안내한다:
       `curl -LsSf https://astral.sh/uv/install.sh | sh`.
     - 프로젝트 경로는 **현재 프로젝트 절대경로**(`$CLAUDE_PROJECT_DIR`)로 채운다:
       ```bash
       claude mcp add serena --scope user -- uvx serena@latest --project "$CLAUDE_PROJECT_DIR"
       ```
     - ⚠ user scope에 `--project`를 고정하므로 **다른 프로젝트로 전환하면 재설정이 필요**함을 사용자에게 알린다.

4. **플러그인 설치 (figma·playwright — prefix 일치를 위해 플러그인 경로 유지)**
   - 이들은 `claude mcp add`로 깔지 **않는다**(prefix가 달라져 스킬이 깨짐). 다음 슬래시 명령을 안내한다:
     - figma (UI 구현·visual-diff 필수): `/plugin install @figma/figma-mcp`
     - playwright (visual-diff 폴백, 선택): `/plugin install @playwright/playwright-mcp`
   - `/plugin install`은 대화형 Claude Code 명령이므로 shell로 자동 실행하지 말고, 위 명령을 그대로 안내한다.
   - figma는 최초 도구 호출 시 브라우저 OAuth로 인증된다.

5. **metro-devtools (React Native 전용 — devoks-rn 플러그인 필요)**
   - RN 프로젝트에서 `devoks-rn:metro-devtools-attach` 스킬 사용 시 필요하다 (JS 콘솔·Zustand·TanStack Query 조회).
   - Metro WebSocket device ID가 재시작마다 바뀌어 `claude mcp add`나 플러그인 번들로 정적 등록이 불가능하다.
     대신 **현재 WebSocket URL을 직접 추출해 `~/.claude.json`의 `mcpServers`에 수동 추가**한다.

   **설치 단계:**
   - Metro가 실행 중인지 확인한다:
     ```bash
     curl -s http://localhost:8081/status   # → packager-status:running
     ```
   - 현재 WebSocket URL을 추출한다:
     ```bash
     python3 -c "import urllib.request,json; print(json.loads(urllib.request.urlopen('http://localhost:8081/json').read())[0]['webSocketDebuggerUrl'])"
     ```
   - 출력된 URL을 아래 형식으로 `~/.claude.json`의 `mcpServers` 블록에 추가한다:
     ```json
     "metro-devtools": {
       "command": "npx",
       "args": ["chrome-devtools-mcp@latest", "--wsEndpoint", "ws://localhost:8081/inspector/debug?device=<DEVICE_ID>&page=1"],
       "type": "stdio"
     }
     ```
   - Claude Code를 재시작해야 반영된다. 이후 `mcp__metro-devtools__*` 도구를 사용한다.
   - ⚠ **Metro 재시작마다 device ID가 바뀐다** — 재시작 후 URL을 재추출해 `~/.claude.json`을 업데이트하고 Claude Code를 재시작해야 한다. 콘솔 로그가 당장 필요 없으면 스크린샷(`adb exec-out screencap -p`)만 사용해도 된다.

6. **chrome-devtools-attach (visual-diff·data-verify 필수 — figma·playwright와 동일하게 플러그인 경로)**
   - 이 서버는 `devoks-browser` 플러그인이 번들한다(`:9269` attach 고유 설정, prefix `mcp__chrome-devtools-attach__*`).
   - **`claude mcp add`로 깔지 않는다.** 같은 서버가 플러그인 번들 + user scope에 이중 등록되면
     동일한 `:9269` 디버그 포트에 두 인스턴스가 동시에 attach를 시도해 충돌한다.
   - 감지 결과(`claude mcp list`에 `chrome-devtools-attach` 부재, 또는 SessionStart 훅 경고)로 **누락이면**
     다음을 안내한다: `/plugin install devoks-browser@devoks-plugins`. 이미 devoks-browser가 설치돼 있으면 별도 작업 불필요.
   - Chrome 디버그 실행(`--remote-debugging-port=9269`)은 `docs/mcp-setup-guide.md` 3절을 참조하게 한다.

7. **결과 보고**
   - 설치가 끝나면 `claude mcp list`를 다시 실행해 최종 상태를 요약한다.
   - 변경 사항이 도구로 반영되려면 **세션 재시작이 필요할 수 있음**을 안내한다.

## 주의

- 모든 `npx`/`uvx` 첫 실행은 패키지 다운로드가 필요하다 — 오프라인 환경에서는 첫 시작이 실패할 수 있다.
- 설치 중 에러가 나면 **에러 리포트만** 하고 자동으로 고치지 않는다. 사용자가 판단하도록 명령·로그를 그대로 전달한다.
