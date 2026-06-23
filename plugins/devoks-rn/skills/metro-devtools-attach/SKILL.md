---
description: "React Native 앱 디버깅 — 에뮬레이터/시뮬레이터 스크린샷 자동 캡처, Metro CDP로 JS 콘솔 확인, Zustand·TanStack Query 상태 조회, 네트워크 API 모니터링. RN 디버깅, 화면 확인, 스크린샷, console.log 확인, 에뮬레이터, 시뮬레이터, Metro, Hermes, 앱 상태 조회 키워드에 반드시 사용한다."
---

## 전제 조건

### 플러그인 설치

```sh
/plugin install devoks-rn@devoks
```

플러그인을 설치하면 스킬이 로드되지만, `mcp__metro-devtools__*` 도구를 사용하려면 **Metro JS 디버거를 수동으로 활성화**해야 한다.

### 런타임 전제

| 항목 | 조건 |
|------|------|
| Metro 실행 | `curl -s http://localhost:8081/status` → `packager-status:running` |
| JS 디버거 활성화 | iOS Simulator: `Cmd+D` → "Open JS Debugger" / Android: 쉐이크 → "Open Debugger" |
| Android adb 포트 포워딩 | `adb forward tcp:8081 tcp:8081` (에뮬레이터에서 직접 연결 시) |

**사용할 MCP 도구 prefix**: `mcp__metro-devtools__` (`mcp__chrome-devtools-attach__` 또는 `mcp__plugin_chrome-devtools-mcp_chrome-devtools__`와 절대 혼용 금지)

---

## Step 1: 스크린샷 캡처 (MCP 불필요 — 즉시 사용)

JS 디버거 활성화 없이도 언제든 사용 가능하다.

### iOS Simulator

```bash
xcrun simctl io booted screenshot /tmp/rn_screen.png
```

### Android Emulator

```bash
adb exec-out screencap -p > /tmp/rn_screen.png
```

스크린샷 저장 후 Read tool로 이미지 파일을 읽으면 Claude가 UI를 시각적으로 확인할 수 있다.

#### 트러블슈팅

| 증상 | 원인 | 조치 |
|------|------|------|
| `xcrun simctl` 실패 | 실행 중인 시뮬레이터 없음 | `xcrun simctl list devices booted`로 확인 |
| `adb` 명령 없음 | PATH 미설정 | `export PATH=$PATH:~/Library/Android/sdk/platform-tools` |
| Android 스크린샷 빈 파일 | 에뮬레이터 sleep 상태 | 에뮬레이터 화면 깨우기 |

> iOS 물리 디바이스는 `xcrun simctl` 불가. `idevicescreenshot`(libimobiledevice) 별도 설치 필요.

---

## Step 2: Metro CDP 연결 (JS 디버거 활성화 필요)

### 2-1. Metro 상태 확인

```bash
curl -s http://localhost:8081/status
```

`packager-status:running`이 아니면 Metro(`pnpm start` 또는 `react-native start`)를 먼저 실행한다.

### 2-2. 타겟 목록 조회

```
mcp__metro-devtools__list_pages
```

정상 응답 예시:
```json
[
  { "pageId": 1, "title": "Crema", "url": "...", "type": "page" },
  { "pageId": 2, "title": "React Native Packager", "type": "worker" }
]
```

**연결 실패 시**: JS 디버거가 비활성화된 것이다.
- iOS Simulator: `Cmd+D` → "Open JS Debugger"
- Android Emulator: 쉐이크(`adb shell input keyevent 82`) → "Open Debugger"

### 2-3. 앱 페이지 선택

`type: "page"` + 앱 이름(title)이 포함된 항목을 선택한다. `type: "worker"` 타입은 제외.

```
mcp__metro-devtools__select_page { "pageId": <앱 페이지 ID> }
```

---

## Step 3: 상황별 디버깅 패턴

### 콘솔 에러 확인

```
mcp__metro-devtools__list_console_messages
```

에러만 필터:
```
mcp__metro-devtools__list_console_messages { "types": ["error"] }
```

### Zustand 스토어 상태 조회

```
mcp__metro-devtools__evaluate_script {
  "function": "() => { const stores = globalThis.__zustand_stores__; return stores ? Object.fromEntries([...stores].map(s => [s.getState().constructor?.name || 'store', s.getState()])) : 'zustand devtools not enabled'; }"
}
```

> Zustand devtools가 비활성화된 경우, 스토어 인스턴스를 직접 export해 global에 붙이는 방법을 사용한다.

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

### 현재 화면 재확인

JS 상태 조회 후 UI 변화를 보려면 Step 1로 돌아가 스크린샷을 다시 찍는다.

---

## 트러블슈팅

| 증상 | 원인 | 조치 |
|------|------|------|
| `list_pages` 타임아웃 | JS 디버거 미활성화 | `Cmd+D` → Open JS Debugger |
| `list_pages` 응답은 오지만 앱 페이지 없음 | Metro만 실행되고 앱 미실행 | 앱 빌드 후 재시도 |
| JS eval 무응답 | 앱이 background 상태 | 앱을 foreground로 전환 |
| `evaluate_script` 에러 | Hermes strict mode 제한 | `require()` 대신 import한 모듈 참조 |
| MCP prefix 혼동 | devoks-browser와 혼용 | 반드시 `mcp__metro-devtools__` 사용 |
| adb 없음 | PATH 미설정 | `~/Library/Android/sdk/platform-tools` PATH 추가 |

---

## 스킬 제한사항

- **React DevTools 컴포넌트 트리**: GUI 트리 탐색은 에이전트 직접 조작 불가 (범위 외)
- **iOS 물리 디바이스**: `xcrun simctl` 불가, `idevicescreenshot` 별도 필요
- **Hot Reload 트리거**: CDP로 파일 변경 → 리로드 불가 (Metro watch가 파일 감지)
- **CDP 연결**: JS 디버거 수동 활성화 필수 (자동화 불가)

---

## 빠른 참조

| 목적 | 도구 |
|------|------|
| iOS 스크린샷 | Bash `xcrun simctl io booted screenshot /tmp/rn_screen.png` |
| Android 스크린샷 | Bash `adb exec-out screencap -p > /tmp/rn_screen.png` |
| 타겟 목록 | `mcp__metro-devtools__list_pages` |
| 페이지 선택 | `mcp__metro-devtools__select_page` |
| 콘솔 에러 | `mcp__metro-devtools__list_console_messages` |
| JS 평가 | `mcp__metro-devtools__evaluate_script` |
| 네트워크 | `mcp__metro-devtools__list_network_requests` |
