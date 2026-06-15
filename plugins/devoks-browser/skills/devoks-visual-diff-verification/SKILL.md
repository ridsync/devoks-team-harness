---
name: devoks:visual-diff-verification
description: Figma 디자인과 라이브 렌더를 비교해 UI 충실도를 끌어올린다. Figma MCP 로 노드 캡처 → Chrome DevTools MCP(폴백 Playwright) 로 라이브 캡처 → multimodal 시각 diff → 프로젝트 디자인 가이드 정합성 검증 → 토큰/레이아웃 상수 미세 조정 → 임시 패치 회수 → 프로젝트 검증 명령 실행. Figma 비교 / 시각 diff / 픽셀 퍼펙트 / UI 충실도 / Figma vs 실제 렌더 키워드에서 호출.
metadata:
  author: ridsync
  version: 1.0.0
---

# visual-diff-verification

Figma 디자인과 라이브 렌더를 비교해 UI 충실도를 끌어올리는 6 Phase 워크플로우.

## 필요 MCP

이 Skill 을 실행하려면 다음 MCP 가 활성화되어 있어야 한다.

| MCP | 역할 | 필수 여부 |
|-----|------|----------|
| Figma MCP (`mcp__plugin_figma_figma__*`) | Figma 디자인 캡처 + 메타데이터 추출 | **필수** |
| Chrome DevTools MCP (`mcp__plugin_chrome-devtools-mcp_chrome-devtools__*`) | 라이브 렌더 캡처 (**기본 도구**) | **필수** |
| Playwright MCP (`mcp__playwright__*`) | 라이브 렌더 캡처 (폴백 도구) | Chrome DevTools MCP 불가 시 사용 |

### ToolSearch 로드 순서 (규칙)

> ⚠️ **캡처 도구는 반드시 아래 순서대로 로드하고 시도한다. 순서를 건너뛰는 것은 규칙 위반이다.**

1. **Chrome DevTools MCP 스키마를 먼저 로드한다:**
   ```
   ToolSearch("select:mcp__plugin_chrome-devtools-mcp_chrome-devtools__list_pages,mcp__plugin_chrome-devtools-mcp_chrome-devtools__navigate_page,mcp__plugin_chrome-devtools-mcp_chrome-devtools__wait_for,mcp__plugin_chrome-devtools-mcp_chrome-devtools__take_screenshot")
   ```
2. **디버깅 가능한 Chrome 브라우저 연결 상태를 사전 확인한다** (`list_pages` 호출):
   - 페이지 목록이 반환되면 → 연결 성공, 캡처 진행.
   - 연결 실패(오류/빈 결과)이면 → **사용자에게 1줄로 요청**: `"Chrome 브라우저를 --remote-debugging-port=9222 옵션으로 실행해 주세요."`  진행은 사용자 확인 후 재시도.
3. **Chrome DevTools MCP로 캡처를 수행한다.** 성공하면 Playwright MCP 로드 불필요.
4. **Chrome DevTools MCP 호출이 실패(오류/타임아웃/tool not found)한 경우에만** Playwright MCP 스키마를 로드한다:
   ```
   ToolSearch("select:mcp__playwright__browser_navigate,mcp__playwright__browser_wait_for,mcp__playwright__browser_take_screenshot")
   ```
5. Playwright로 전환할 때는 **사용자에게 한 줄 이유를 명시**한다.
   - 예: `"Chrome DevTools MCP 호출 실패(오류: xxx) → Playwright MCP로 폴백합니다."`

## 호출 방법

```
/visual-diff-verification [figma-url=<Figma URL>] [component=<컴포넌트 파일 경로>] [route=<라이브 라우트>] [design-guide=<디자인 가이드 파일 경로>]
```

**예시:**
```
/visual-diff-verification figma-url=https://www.figma.com/design/ABC123/MyApp?node-id=100-200 component=src/components/ResultCard.jsx route=/result
```

인자가 없어도 동작하지만, Phase 0 슬롯 합의 단계에서 사용자에게 1회 확인한다.

## 추상 슬롯 (프로젝트별 사용자가 채움)

| 슬롯 | 의미 | 입력 방법 |
|------|------|----------|
| `<FigmaNodeId>` | 비교 대상 Figma 노드 ID | `figma-url` 인자에서 자동 추출 또는 직접 입력 |
| `<FigmaFileKey>` | Figma 파일 키 | `figma-url` 인자에서 자동 추출 |
| `<ComponentPath>` | 비교 대상 컴포넌트 파일 경로 | `component` 인자 또는 Phase 0 확인 |
| `<LiveRoute>` | 라이브 dev server 의 대상 라우트/URL | `route` 인자 또는 Phase 0 확인 |
| `<DesignGuide>` | 프로젝트 디자인 가이드 문서 경로 | `design-guide` 인자 또는 Phase 0 확인 |
| `<TokenSSOT>` | 컬러/타이포/spacing 토큰 정의 파일 (있다면) | Phase 0 확인 |
| `<ZIndexSSOT>` | z-index 상수 SSOT 파일 (있다면) | Phase 0 확인 |
| `<LayoutScaleSSOT>` | Figma → viewport 변환식 SSOT (있다면) | Phase 0 확인 |
| `<BaselineViewport>` | 라이브 렌더 비교 기준 viewport 크기 | Phase 0 확인 (기본 `1280×720`) |
| `<DevServerURL>` | 라이브 dev server URL | Phase 0 확인 (기본 `http://localhost:3000`) |
| `<VerifyCommands>` | 프로젝트 검증 명령 (lint/test/build) | Phase 0 확인 |

> 슬롯 값은 실행 시점에만 사용되며 SKILL.md 에 저장하지 않는다.

---

## 핵심 원칙

- **Token first** — 임의 hex/rgba 가 아닌 프로젝트 토큰 SSOT(`<TokenSSOT>`) / z-index SSOT(`<ZIndexSSOT>`) 를 우선 참조.
- **Touch target** — `<DesignGuide>` 에 명시된 minimum touch size 를 따른다. 명시가 없으면 Android 48dp / iOS 44pt 권장(WCAG 2.5.5).
- **Baseline viewport 기준 비교** — `<BaselineViewport>` 에서 비교. Figma frame 크기가 다르면 비례 스케일 변환 후 비교 (`references/figma-capture.md` §스케일 변환 참조).
- **Dev server 직접 기동 금지** — Skill 은 이미 실행 중인 dev server 를 사용한다. URL/포트 불확실 시 1줄 확인 후 진행.
- **신규 토큰 정의 금지** — 본 Skill 은 검증 + 미세 조정 전용. 신규 토큰 도입은 사용자 결정 사항(별도 PR).
- **임시 패치는 반드시 회수** — Phase 6 에서 `git restore` 로 완전히 되돌린다.

---

## Phase 0 — 사전 준비 (슬롯 합의)

1. `$ARGUMENTS` 에서 슬롯 값 파싱 (Figma URL → `<FigmaFileKey>` + `<FigmaNodeId>` 자동 추출).
2. 미충족 필수 슬롯이 있으면 **1회** 사용자에게 확인:
   - "Figma 노드 ID / 비교 대상 컴포넌트 경로 / 라이브 라우트 / 프로젝트 디자인 가이드 파일(있다면) / viewport / dev server URL / 검증 명령을 알려주세요."
3. `<DesignGuide>` 파일이 존재하면 컬러/타이포/spacing/z-index/터치 관련 섹션을 Read.
4. `<TokenSSOT>` / `<ZIndexSSOT>` 파일이 존재하면 상수 표 파악.
5. `<LayoutScaleSSOT>` 파일이 존재하면 Figma → device 변환식 확인.

---

## Phase 1 — Figma reference 캡처

```
mcp__plugin_figma_figma__get_screenshot(nodeId=<FigmaNodeId>, fileKey=<FigmaFileKey>)
→ 저장: figma_<screen>.png  (상대 경로, workspace root)
```

- `mcp__plugin_figma_figma__get_metadata(nodeId, fileKey)` → 좌표/사이즈/색상/폰트 수집.
- (옵션) `mcp__plugin_figma_figma__get_design_context(nodeId, fileKey)` → 코드 힌트.
- 권한 오류 발생 시 사용자에게 1줄 확인 후 재시도.
- 상세는 `references/figma-capture.md` 참조.

---

## Phase 2 — 라이브 렌더 캡처

> ⚠️ **이 Phase 진입 시 캡처 도구 로드 순서를 반드시 지킨다 → `필요 MCP § ToolSearch 로드 순서` 참조.**  
> Playwright MCP를 Chrome DevTools MCP보다 먼저 로드하거나 기본 도구로 선택하는 것은 **규칙 위반**이다.

1. `<DevServerURL>` 가용성 확인. 미확인 시 사용자에게 1줄 확인. **Skill 은 dev server 를 기동하지 않는다.**
2. **Chrome 브라우저 연결 사전 확인** (`list_pages` 호출):
   - 연결 실패 시 사용자에게 `"Chrome 브라우저를 --remote-debugging-port=9222 옵션으로 실행해 주세요."` 요청 → 확인 후 재시도.
3. 특정 화면 진입이 필요하면 `references/state-patch-pattern.md` 의 임시 패치 적용.
4. **기본 도구 (Chrome DevTools MCP)**:
   ```
   mcp__plugin_chrome-devtools-mcp_chrome-devtools__list_pages()
   → select_page 또는 new_page
   → navigate_page(url=<DevServerURL>/<LiveRoute>)
   → wait_for(text=<화면 식별 텍스트>, timeout=5000)
   → take_screenshot(filename=render_<screen>.png)
   ```
5. **폴백 (Playwright MCP)** — Chrome DevTools MCP 실패 시에만:
   ```
   mcp__playwright__browser_navigate(url=<DevServerURL>/<LiveRoute>)
   mcp__playwright__browser_wait_for(text=<화면 식별 텍스트>, timeout=5000)
   mcp__playwright__browser_take_screenshot(filename=render_<screen>.png)
   ```
6. 상세는 `references/live-capture.md` 참조.

---

## Phase 3 — Multimodal 시각 diff

1. `figma_<screen>.png` 와 `render_<screen>.png` 를 Claude multimodal 로 함께 읽는다.
2. 다음 차원을 비교:
   - **좌표 / 사이즈 / spacing** — 절대 px 값이 아닌 비율로 비교 (Figma frame 크기 차이 보정).
   - **색상** — hex 값 + 시각 색조 비교.
   - **타이포그래피** — font-weight / font-size / font-family / line-height.
   - **장식 요소** — 아이콘 유무 / 테두리 / 그림자 / dot 크기.
3. `references/diff-checklist.md` 템플릿에 결과를 기입한다.

---

## Phase 4 — 프로젝트 디자인 가이드 정합성 검증

1. Phase 3 에서 발견된 hex 색상을 `<DesignGuide>` / `<TokenSSOT>` 의 토큰 표와 매핑 시도.
   - 매핑 가능 → "토큰 사용 권장" 항목으로 기록.
   - 미매핑 hex 가 2개 이상 반복 → "신규 토큰 후보" 또는 "Known Gaps 후보" 로 메모.
2. z-index 가 직접 숫자로 쓰여 있고 `<ZIndexSSOT>` 가 존재하면 → 상수화 후보로 메모.
3. `<BaselineViewport>` 에서 primary action(CTA 버튼 등)이 fold 밖으로 밀리지 않는지 확인.
4. 상세 매핑 규칙은 `references/design-guide-mapping.md` 참조.

> `<DesignGuide>` 가 없는 경우 WCAG 2.5.5 / Material Design / Apple HIG 기준을 폴백으로 사용한다.

---

## Phase 5 — 미세 조정 (선택)

- **허용 변경**: 레이아웃 상수 값 / 이미 정의된 토큰의 적용.
- **금지 변경**: SSOT 변환식 / 비즈니스 로직 / 상태 머신 / 신규 토큰 정의.
- 화면별로 "캡처 → 비교 → 조정 → 재캡처" **1 사이클씩** 진행.
- 변경 단위는 1개 파일, 1회 commit 으로 회수 가능해야 한다.

---

## Phase 6 — 회수 + 검증

1. 임시 패치 회수:
   ```bash
   git restore <패치된 파일>
   ```
2. 잔존 패치 확인:
   ```bash
   grep -r "TEMP-VISUAL-VERIFY" .
   ```
3. 캡처 파일 정리 (선택):
   ```bash
   rm -f render_*.png figma_*.png
   ```
4. 최종 검증 (`<VerifyCommands>` 실행):
   ```bash
   # 프로젝트별 명령으로 치환
   <VerifyCommands>
   ```
5. 변경 범위 확인:
   ```bash
   git diff --stat
   # → 미세 조정 대상 파일만 남아있어야 함. 임시 패치 파일(옵션 A/B 로 수정한 파일)은 없어야 함.
   ```

---

## Reference 파일 목록

| 파일 | 내용 |
|------|------|
| `references/figma-capture.md` | Figma MCP 3개 도구 사용 가이드 + URL 파싱 + 스케일 변환 |
| `references/live-capture.md` | Playwright/Chrome DevTools MCP 캡처 가이드 + 충돌 해결 |
| `references/diff-checklist.md` | 화면 카테고리별 시각 diff 체크리스트 템플릿 |
| `references/state-patch-pattern.md` | 임시 state 강제 진입 패턴 + git restore 회수 |
| `references/design-guide-mapping.md` | 프로젝트 디자인 가이드 ↔ Figma 메타데이터 매핑 가이드 |
