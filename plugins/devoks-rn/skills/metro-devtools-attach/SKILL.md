---
description: "React Native 앱 디버깅 — 에뮬레이터/시뮬레이터 스크린샷 자동 캡처, Metro CDP로 JS 콘솔 확인, Zustand·TanStack Query 상태 조회, 네트워크 API 모니터링. RN 디버깅, 화면 확인, 스크린샷, console.log 확인, 에뮬레이터, 시뮬레이터, Metro, Hermes, 앱 상태 조회 키워드에 반드시 사용한다."
---

## 전제 조건

### 플러그인 설치

```sh
/plugin install devoks-rn@devoks
/reload-plugins
```

### 런타임 전제

| 항목 | 조건 |
|------|------|
| Metro 실행 | `curl -s http://localhost:8081/status` → `packager-status:running` |
| 에뮬레이터 | Android: `adb devices` / iOS: `xcrun simctl list devices booted` |

### MCP 도구 Prefix

플러그인으로 설치하면 prefix가 자동 부여된다:

```
mcp__plugin_devoks-rn_metro-devtools__<tool>
```

`~/.claude.json`에 `metro-devtools`로 직접 등록한 경우:

```
mcp__metro-devtools__<tool>
```

**devoks-browser(`mcp__chrome-devtools-attach__`)와 절대 혼용 금지.**

---

## Step 1: 스크린샷 캡처 (항상 사용 가능 — MCP 불필요)

Metro 상태나 JS 디버거 활성화와 무관하게 즉시 사용할 수 있다.

### Android Emulator

```bash
adb exec-out screencap -p > /tmp/rn_screen.png
```

### iOS Simulator

```bash
xcrun simctl io booted screenshot /tmp/rn_screen.png
```

스크린샷 저장 후 Read tool로 이미지 파일을 읽으면 Claude가 UI를 시각적으로 확인할 수 있다.

#### 트러블슈팅

| 증상 | 원인 | 조치 |
|------|------|------|
| `adb` 명령 없음 | PATH 미설정 | `export PATH=$PATH:~/Library/Android/sdk/platform-tools` |
| Android 스크린샷 빈 파일 | 에뮬레이터 sleep 상태 | 에뮬레이터 화면 깨우기 |
| `xcrun simctl` 실패 | Xcode CLI 미설치 또는 PATH | `xcode-select --install` |
| iOS 물리 디바이스 | `xcrun simctl` 불가 | `idevicescreenshot`(libimobiledevice) 별도 설치 |

---

## Step 2: Metro CDP 연결 (선택 — JS 상태 조회 필요 시)

Metro의 CDP 인터페이스는 Chrome과 응답 포맷이 다르므로(`type: "node"` vs `type: "page"`), **첫 사용 전에 아래 설정이 필요하다.**

### 2-0. CDP 수동 설정 (최초 1회 — Metro 재시작마다 반복)

Metro의 WebSocket 엔드포인트는 세션마다 device ID가 바뀐다. 현재 URL을 추출해 `~/.claude.json`에 직접 등록해야 한다.

**1단계 — 현재 WebSocket URL 추출:**

```bash
curl -s http://localhost:8081/json | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['webSocketDebuggerUrl'])"
```

출력 예시:
```
ws://localhost:8081/inspector/debug?device=be85314c...&page=1
```

**2단계 — `~/.claude.json`에 추가 (기존 `mcpServers` 블록에 병합):**

```json
{
  "mcpServers": {
    "metro-devtools": {
      "command": "npx",
      "args": ["chrome-devtools-mcp@latest", "--wsEndpoint", "ws://localhost:8081/inspector/debug?device=<DEVICE_ID>&page=1"],
      "type": "stdio"
    }
  }
}
```

**3단계 — Claude Code 재시작** (새 MCP 서버 적용)

재시작 후 도구 prefix는 `mcp__metro-devtools__`로 사용한다.

> **주의**: 플러그인이 등록한 `mcp__plugin_devoks-rn_metro-devtools__` 버전은 `--browserUrl` 방식으로 동작하는데, Metro의 CDP 응답 포맷 차이로 인해 현재 연결이 실패한다. 위 `--wsEndpoint` 방식이 Metro에서 안정적으로 동작한다.

---

### 2-1. Metro 상태 및 타겟 확인

```bash
# Metro 실행 확인
curl -s http://localhost:8081/status

# CDP 타겟 확인 (WebSocket URL 확인용)
curl -s http://localhost:8081/json
```

### 2-2. 페이지 목록 조회

```
mcp__metro-devtools__list_pages
```

**연결 실패 시**: `~/.claude.json`의 wsEndpoint가 최신 WebSocket URL인지 확인한다 (Metro 재시작 시 device ID 변경).

### 2-3. 앱 페이지 선택

목록에서 `type: "node"` + 앱 이름(title)이 포함된 항목을 선택한다.

```
mcp__metro-devtools__select_page { "pageId": <ID> }
```

---

## Step 3: 상황별 디버깅 패턴

### 콘솔 에러 확인

```
mcp__metro-devtools__list_console_messages { "types": ["error"] }
```

### Zustand 스토어 상태 조회

```
mcp__metro-devtools__evaluate_script {
  "function": "() => { const stores = globalThis.__zustand_stores__; return stores ? Object.fromEntries([...stores].map(s => [s.getState().constructor?.name || 'store', s.getState()])) : 'zustand devtools not enabled'; }"
}
```

> Zustand devtools가 비활성화된 경우: 스토어 인스턴스를 `globalThis.__myStore__ = store`로 직접 노출한다.

### TanStack Query 캐시 조회

```
mcp__metro-devtools__evaluate_script {
  "function": "() => { const qc = globalThis.__queryClient__; return qc ? qc.getQueryCache().getAll().map(q => ({ key: q.queryKey, state: q.state.status, data: q.state.data })) : 'queryClient not exposed'; }"
}
```

### 네트워크 API 요청 확인

```
mcp__metro-devtools__list_network_requests
```

### JS 평가 (임의 표현식)

```
mcp__metro-devtools__evaluate_script {
  "function": "() => 'hello from RN'"
}
```

AsyncStorage 확인:
```javascript
() => {
  return new Promise(resolve => {
    require('@react-native-async-storage/async-storage').default.getAllKeys((err, keys) => {
      resolve(keys);
    });
  });
}
```

---

## 트러블슈팅

| 증상 | 원인 | 조치 |
|------|------|------|
| `list_pages` — "Invalid URL: undefined" | 플러그인 MCP(`mcp__plugin_devoks-rn_*`)의 `--browserUrl` 호환 문제 | Step 2-0의 `--wsEndpoint` 수동 설정으로 전환 |
| `list_pages` 연결 실패 | Metro 재시작으로 device ID 변경 | `curl .../json`으로 URL 재추출 → `~/.claude.json` 업데이트 → 재시작 |
| JS eval 무응답 | 앱 background 상태 | 앱을 foreground로 전환 |
| `evaluate_script` 에러 | Hermes strict mode | `require()` 대신 빌드 시 import한 모듈 참조 |
| adb 없음 | PATH 미설정 | `~/Library/Android/sdk/platform-tools` PATH 추가 |

---

## 스킬 제한사항

- **CDP 설정**: Metro 재시작마다 `~/.claude.json` WebSocket URL 업데이트 + Claude Code 재시작 필요
- **React DevTools 컴포넌트 트리**: GUI 트리 탐색 에이전트 직접 조작 불가
- **Hot Reload 트리거**: CDP로 파일 변경 → 리로드 불가 (Metro watch가 파일 감지)
- **iOS 물리 디바이스**: `xcrun simctl` 불가, `idevicescreenshot` 별도 필요

---

## 빠른 참조

| 목적 | 도구 | 전제 |
|------|------|------|
| Android 스크린샷 | `adb exec-out screencap -p > /tmp/rn_screen.png` | adb 연결 |
| iOS 스크린샷 | `xcrun simctl io booted screenshot /tmp/rn_screen.png` | Xcode CLI |
| Metro WebSocket URL | `curl -s http://localhost:8081/json` | Metro 실행 |
| 타겟 목록 | `mcp__metro-devtools__list_pages` | wsEndpoint 설정 |
| 페이지 선택 | `mcp__metro-devtools__select_page` | 위 동일 |
| 콘솔 에러 | `mcp__metro-devtools__list_console_messages` | 위 동일 |
| JS 평가 | `mcp__metro-devtools__evaluate_script` | 위 동일 |
| 네트워크 | `mcp__metro-devtools__list_network_requests` | 위 동일 |
