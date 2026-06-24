---
description: "React Native 앱 디버깅 — 에뮬레이터/시뮬레이터 스크린샷 자동 캡처, Metro CDP로 JS 콘솔 확인, Zustand·TanStack Query 상태 조회, 네트워크 API 모니터링. RN 디버깅, 화면 확인, 스크린샷, console.log 확인, 에뮬레이터, 시뮬레이터, Metro, Hermes, 앱 상태 조회 키워드에 반드시 사용한다."
---

## 전제 조건

### 플러그인 설치

```sh
/plugin install devoks-rn@devoks-plugins
/reload-plugins
```

### 런타임 전제

| 항목 | 조건 |
|------|------|
| Metro 실행 | `curl -s http://localhost:8081/status` → `packager-status:running` |
| 에뮬레이터 | Android: `adb devices` / iOS: `xcrun simctl list devices booted` |

### MCP 도구 Prefix

`/devoks-setup-mcp` Step 5로 설치하면 user scope에 등록된다:

```
mcp__metro-devtools__<tool>
```

미설치 시 `/devoks-setup-mcp`를 실행한다. **`mcp__chrome-devtools-attach__`와 절대 혼용 금지.**

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

## Step 2: Metro CDP 연결 확인 (선택 — JS 상태 조회 필요 시)

`/devoks-setup-mcp` Step 5로 설치된 `metro-mcp.js`는 Metro URL을 자동 조회하므로 수동 설정이 불필요하다.

### 2-1. Metro 상태 확인

```bash
# Metro 실행 확인
curl -s http://localhost:8081/status   # → packager-status:running

# MCP 연결 상태 확인
mcp__metro-devtools__get_metro_status
```

### 2-2. 연결 테스트

```
mcp__metro-devtools__evaluate_script { "function": "() => 'connected'" }
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
| `get_metro_status` — Metro not reachable | Metro 미실행 또는 포트 불일치 | `pnpm start` / `npx expo start` 실행 후 재시도 |
| JS eval 무응답 | 앱 background 상태 | 앱을 foreground로 전환 |
| `evaluate_script` 에러 | Hermes strict mode | `require()` 대신 빌드 시 import한 모듈 참조 |
| `mcp__metro-devtools__*` 도구 없음 | metro-devtools user scope 미등록 | `/devoks-setup-mcp` Step 5 실행 |
| `get_metro_status` → "WebSocket is not defined" | Node.js 20에서 `--experimental-websocket` 플래그 없이 등록됨 | `~/.devoks/mcp/metro-mcp.js` 재등록: `claude mcp add metro-devtools --scope user -- node --experimental-websocket ~/.devoks/mcp/metro-mcp.js` |
| `evaluate_script` → "Property 'global' doesn't exist" | Hermes에서 `global` 전역 없음 | `global.xxx` → `globalThis.xxx` 로 교체 |
| adb 없음 | PATH 미설정 | `~/Library/Android/sdk/platform-tools` PATH 추가 |

---

## 스킬 제한사항

- **React DevTools 컴포넌트 트리**: GUI 트리 탐색 에이전트 직접 조작 불가
- **Hot Reload 트리거**: CDP로 파일 변경 → 리로드 불가 (Metro watch가 파일 감지)
- **iOS 물리 디바이스**: `xcrun simctl` 불가, `idevicescreenshot` 별도 필요

---

## 빠른 참조

| 목적 | 도구 | 전제 |
|------|------|------|
| Android 스크린샷 | `adb exec-out screencap -p > /tmp/rn_screen.png` | adb 연결 |
| iOS 스크린샷 | `xcrun simctl io booted screenshot /tmp/rn_screen.png` | Xcode CLI |
| Metro 연결 상태 | `mcp__metro-devtools__get_metro_status` | metro-devtools 등록 |
| 콘솔 에러 | `mcp__metro-devtools__list_console_messages` | 위 동일 |
| JS 평가 | `mcp__metro-devtools__evaluate_script` | 위 동일 |
| 네트워크 | `mcp__metro-devtools__list_network_requests` | 위 동일 |
