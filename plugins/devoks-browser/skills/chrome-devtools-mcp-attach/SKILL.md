---
name: chrome-devtools-mcp-attach
description: "이미 실행 중인 Chrome 브라우저(--remote-debugging-port=9269)에 Chrome DevTools MCP로 즉시 연결해 개발 및 디버깅을 수행한다. 브라우저 콘솔 확인, JS 평가, 네트워크 요청 검사, 스크린샷, 페이지 상태 분석 등이 필요할 때 반드시 이 스킬을 사용한다. 키워드: 콘솔 에러, console error, 브라우저 디버깅, 화면 확인, 스크린샷, 네트워크 요청, evaluate, DOM 검사, 라이브 앱 확인, live app, localhost 확인."
---

## 전제 조건

### 환경 셋업 (신규 머신 기준)

**1단계 — 플러그인 설치** (스킬 파일 로딩)
```sh
/plugin install chrome-devtools-mcp@chrome-devtools-plugins
```

**2단계 — `~/.claude.json`에 MCP 서버 추가** (실제 9269 연결)
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
> 플러그인만 설치하면 스킬은 로드되지만 `mcp__chrome-devtools-attach__*` 도구가 없어 동작하지 않는다.
> `~/.claude.json` 수동 추가가 반드시 필요하다.

### 런타임 전제

- Chrome이 `--remote-debugging-port=9269`로 실행 중이어야 한다.
```bash
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --remote-debugging-port=9269 --user-data-dir=~/.claude/chrome-dev-mcp/ http://localhost:5500
```

**사용할 MCP 도구 prefix**: `mcp__chrome-devtools-attach__` (플러그인 기본값인 `mcp__plugin_chrome-devtools-mcp_chrome-devtools__`와 다름 — 절대 혼용하지 말 것)

---

## Step 1: 연결 확인 및 페이지 선택

브라우저 작업 전 항상 이 순서로 시작한다.

### 1-1. 열린 페이지 목록 조회

```
mcp__chrome-devtools-attach__list_pages
```

정상 응답 예시:
```
[
  { "pageId": 1, "title": "React App", "url": "http://localhost:5500/...", "type": "page" },
  { "pageId": 2, "title": "DevTools - ...", "type": "page" },
  ...
]
```

**연결 실패 시**: Chrome이 9269 포트로 실행 중인지 확인한다.
```bash
curl -s http://127.0.0.1:9269/json | python3 -m json.tool
```
응답이 없으면 Chrome을 재시작해야 한다. Claude Code 재시작도 필요할 수 있다.

### 1-2. 올바른 페이지 선택

`list_pages` 결과에서 타깃 페이지를 고른다:
- `type: "page"` + URL이 `localhost`를 포함하는 것
- `type: "browser_ui"`, `type: "worker"` 페이지는 제외
- DevTools 자체 탭 (`devtools://` URL)도 제외

```
mcp__chrome-devtools-attach__select_page { "pageId": <앱 페이지의 ID> }
```

**이 프로젝트의 기본 앱 URL**: `http://localhost:5500`

---

## Step 2: 상황별 디버깅 패턴

페이지를 선택한 후 목적에 맞는 도구를 사용한다.

### 콘솔 에러/로그 확인

```
mcp__chrome-devtools-attach__list_console_messages
```
- `types: ["error"]`로 필터링해 에러만 볼 수 있다.
- `pageSize`로 개수 제한 가능.

특정 메시지 상세 조회:
```
mcp__chrome-devtools-attach__get_console_message { "msgid": <id> }
```

### 현재 화면 스크린샷

```
mcp__chrome-devtools-attach__take_screenshot
```
- 파일로 저장: `{ "filePath": "/tmp/screen.png" }`
- 전체 페이지: `{ "fullPage": true }`

### 페이지 구조 (A11y 트리) 확인

```
mcp__chrome-devtools-attach__take_snapshot
```
- 각 요소에 `uid`가 있어 `click`, `fill` 등에 활용
- UI가 예상과 다를 때, 또는 요소의 현재 상태를 파악할 때 사용

### JavaScript 평가 (React 상태, DOM 값 등)

```
mcp__chrome-devtools-attach__evaluate_script {
  "function": "() => { return document.title; }"
}
```

React 컴포넌트 내부 상태 확인 예시:
```javascript
() => {
  // React Fiber를 통해 컴포넌트 props/state 접근
  const el = document.querySelector('[data-testid="xxx"]');
  const fiber = el?._reactFiber || el?.__reactFiber;
  return fiber?.memoizedProps;
}
```

로컬 스토리지 / 세션 스토리지 확인:
```javascript
() => ({
  local: { ...localStorage },
  session: { ...sessionStorage }
})
```

### 네트워크 요청 검사

모든 요청 목록:
```
mcp__chrome-devtools-attach__list_network_requests
```

특정 요청 상세 (reqid는 list 결과에서 획득):
```
mcp__chrome-devtools-attach__get_network_request { "reqid": <id> }
```

---

## Step 3: 페이지 인터랙션

snapshot의 `uid`로 요소를 조작한다.

### 클릭
```
mcp__chrome-devtools-attach__click { "uid": "<uid>" }
```

### 입력
```
mcp__chrome-devtools-attach__fill { "uid": "<uid>", "value": "입력값" }
```

### 페이지 이동 (현재 탭)
```
mcp__chrome-devtools-attach__navigate_page { "type": "url", "url": "http://localhost:5500/settings" }
```

### 새 탭 열기
```
mcp__chrome-devtools-attach__new_page { "url": "http://localhost:5500/another-path" }
```

---

## 주의사항 및 트러블슈팅

| 증상 | 원인 | 조치 |
|------|------|------|
| `list_pages` 타임아웃 | Chrome이 실행 안 됨 또는 9269 포트 불일치 | `curl http://127.0.0.1:9269/json`으로 확인 |
| `select_page` 후 도구 작동 안 함 | DevTools 탭이나 worker 탭 선택 | `type: "page"` + `localhost` URL인 탭 재선택 |
| 스냅샷에 요소 안 보임 | 페이지 아직 로딩 중 | `wait_for`로 특정 텍스트 대기 후 재시도 |
| 두 개 MCP 서버 충돌 | `mcp__plugin_chrome-devtools-mcp_*` 도구 혼용 | 반드시 `mcp__chrome-devtools-attach__` prefix만 사용 |

### Chrome 실행 명령 (필요 시 사용자에게 안내)

```bash
# macOS 기본 Chrome
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
  --remote-debugging-port=9269 \
  --user-data-dir=/tmp/chrome-debug-profile
```

---

## 빠른 참조: 도구 목록

| 목적 | 도구 |
|------|------|
| 페이지 목록 | `list_pages` |
| 페이지 선택 | `select_page` |
| 콘솔 메시지 | `list_console_messages`, `get_console_message` |
| 스크린샷 | `take_screenshot` |
| DOM/A11y 트리 | `take_snapshot` |
| JS 실행 | `evaluate_script` |
| 네트워크 | `list_network_requests`, `get_network_request` |
| 클릭 | `click` |
| 입력 | `fill`, `fill_form` |
| 이동 | `navigate_page`, `new_page` |
| 대기 | `wait_for` |
| 성능 분석 | `performance_start_trace`, `performance_stop_trace`, `performance_analyze_insight` |
