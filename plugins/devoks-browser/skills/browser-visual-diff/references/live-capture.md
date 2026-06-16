# 라이브 렌더 캡처 가이드

실행 중인 dev server 에서 화면을 캡처하는 방법. **Playwright MCP 기본, Chrome DevTools MCP 폴백.**

---

## 사전 조건

- Dev server 가 이미 실행 중이어야 한다. Skill 은 dev server 를 기동하지 않는다.
- `<DevServerURL>` 이 확정되어 있어야 한다 (예: `http://localhost:3000`, `http://localhost:5500`).
- 포트가 불확실하면 사용자에게 1줄 확인 후 진행.

---

## 기본 도구: Playwright MCP

### 기본 흐름

```
1. mcp__playwright__browser_navigate(url=<DevServerURL>/<LiveRoute>)
2. mcp__playwright__browser_wait_for(text=<화면 식별 텍스트>, timeout=5000)
3. mcp__playwright__browser_take_screenshot(filename=render_<screen_name>.png)
```

### 파일명 규칙

- **상대 경로** 사용 (`render_<screen_name>.png`) — workspace root 에 저장.
- 절대 경로(`/tmp/...` 등) 는 `allowed roots` 제약으로 실패할 수 있음.
- 파일명 예: `render_result_pass.png`, `render_settings_modal.png`

### 주요 파라미터

```
browser_take_screenshot({
  filename: "render_<screen_name>.png",  # 상대 경로
  fullPage: false                        # viewport 크기로 캡처 (Figma 비교용)
})
```

### `wait_for` 패턴

화면이 완전히 로딩된 뒤 캡처해야 정확한 비교가 가능하다.

| 상황 | 권장 `wait_for` |
|------|----------------|
| 텍스트가 화면에 있음 | `browser_wait_for(text=<화면의 고유 텍스트>, timeout=5000)` |
| 특정 셀렉터가 있음 | `browser_wait_for(selector=<CSS selector>, timeout=5000)` |
| 단순 페이지 이동 | `browser_wait_for(url=<URL 패턴>, timeout=5000)` |
| HMR 반영 대기 | 위 방법 실패 시 `browser_navigate` 재호출로 강제 리로드 |

---

## 폴백 도구: Chrome DevTools MCP

Playwright MCP 가 없거나 충돌이 발생하면 Chrome DevTools MCP 로 폴백.

### 기본 흐름

```
1. mcp__plugin_chrome-devtools-mcp_chrome-devtools__list_pages()
   → 열려있는 페이지 목록 확인
2. 대상 페이지가 있으면 select_page, 없으면 new_page
3. mcp__plugin_chrome-devtools-mcp_chrome-devtools__navigate_page(url=<DevServerURL>/<LiveRoute>)
4. mcp__plugin_chrome-devtools-mcp_chrome-devtools__wait_for(text=<화면 식별 텍스트>)
5. mcp__plugin_chrome-devtools-mcp_chrome-devtools__take_screenshot(filename=render_<screen_name>.png)
```

### chrome-profile 충돌 해결

Chrome DevTools MCP 와 사용자 Chrome 인스턴스가 같은 프로파일을 사용하면 충돌이 발생할 수 있다.

해결 순서:
1. `list_pages()` 로 현재 열린 페이지 재사용 (`select_page`).
2. 기존 페이지를 재사용할 수 없으면 `close_page` 후 `new_page`.
3. 그래도 실패하면 Playwright MCP 로 전환.

---

## 임시 패치 적용 후 캡처

특정 화면 진입이 자동화되어 있지 않을 때(예: 멀티-스텝 위저드의 중간 화면) 임시 패치로 강제 진입한 뒤 캡처한다.

절차:
1. `references/state-patch-pattern.md` 를 참조해 임시 패치 적용.
2. HMR 반영 확인: `browser_wait_for(text=<패치로 진입한 화면의 고유 텍스트>)`.
3. HMR 이 반영되지 않으면 `browser_navigate` 로 재로드.
4. 캡처 완료 후 **반드시 Phase 6 에서** `git restore` 로 패치 회수.

---

## Viewport 설정

`<BaselineViewport>` 에 맞게 브라우저 viewport 를 조정해야 Figma 와 비례가 맞는다.

```
# Playwright
mcp__playwright__browser_resize(width=1280, height=720)

# Chrome DevTools
mcp__plugin_chrome-devtools-mcp_chrome-devtools__resize_page(width=1280, height=720)
```

> `<BaselineViewport>` 값을 미리 확인하고, Phase 2 시작 전에 한 번만 설정한다.

---

## 트러블슈팅

| 증상 | 원인 | 해결 |
|------|------|------|
| 캡처가 빈 화면 | 페이지 로딩 전 캡처 | `wait_for` timeout 늘리기 또는 특정 요소 대기 |
| HMR 반영 안 됨 | Vite HMR 소켓 연결 문제 | `browser_navigate` 재호출로 강제 리로드 |
| Playwright 연결 실패 | 브라우저 인스턴스 없음 | Chrome DevTools MCP 폴백 |
| 파일 저장 실패 | 절대 경로 사용 | 상대 경로(`render_screen.png`)로 변경 |
| 원하는 화면이 안 나옴 | 인증/가드가 있는 라우트 | state-patch-pattern.md 참조해 강제 진입 |
