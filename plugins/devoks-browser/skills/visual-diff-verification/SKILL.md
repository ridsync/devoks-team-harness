---
name: visual-diff-verification
description: Figma 디자인과 라이브 렌더를 비교해 UI 충실도를 끌어올린다. Phase 0(슬롯 합의·Chrome 연결 확인) → Phase 1~4를 visual-diff-capture 에이전트에 위임(캡처·시각diff·디자인가이드 정합성 검증 결과를 충실도 리포트로 수령) → Phase 5(미세조정) → Phase 6(회수+검증). Figma 비교 / 시각 diff / 픽셀 퍼펙트 / UI 충실도 / Figma vs 실제 렌더 키워드에서 호출.
metadata:
  author: ridsync
  version: 1.0.0
---

# visual-diff-verification

Figma 디자인과 라이브 렌더를 비교해 UI 충실도를 끌어올리는 워크플로우.

**Phase 1~4의 실제 실행 주체는 `visual-diff-capture` 에이전트이다.**  
스크린샷·멀티모달 바이트는 에이전트 컨텍스트에 격리되고, 메인 루프에는 **충실도 리포트만** 리턴된다.

## 필요 MCP

Phase 1~4는 `visual-diff-capture` 에이전트가 수행하며, 에이전트가 아래 MCP를 로드한다.

| MCP | 역할 | 필수 여부 |
|-----|------|----------|
| Figma MCP (`mcp__plugin_figma_figma__*`) | Figma 디자인 캡처 + 메타데이터 추출 | **필수** |
| Chrome DevTools MCP (`mcp__plugin_chrome-devtools-mcp_chrome-devtools__*`) | 라이브 렌더 캡처 (**기본 도구**) | **필수** |
| Playwright MCP (`mcp__playwright__*`) | 라이브 렌더 캡처 (폴백 도구) | Chrome DevTools MCP 불가 시 사용 |

### ToolSearch 로드 순서 (에이전트 내부 규칙)

> ⚠️ **캡처 도구는 반드시 아래 순서대로 로드하고 시도한다. 에이전트가 이 규칙을 준수한다.**

1. **Chrome DevTools MCP 스키마를 먼저 로드한다.**
2. **디버깅 가능한 Chrome 브라우저 연결 상태를 사전 확인한다** (`list_pages` 호출):
   - 연결 실패 → 에이전트가 리포트에 "Chrome DevTools MCP 연결 실패" 기록 → 이 스킬(메인 루프)에서 사용자에게 1줄 요청: `"Chrome 브라우저를 --remote-debugging-port=9222 옵션으로 실행해 주세요."` 후 재시도.
3. **Chrome DevTools MCP 호출이 실패한 경우에만** Playwright MCP로 폴백.

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
- **Dev server 직접 기동 금지** — 이미 실행 중인 dev server 를 사용한다. URL/포트 불확실 시 1줄 확인 후 진행.
- **신규 토큰 정의 금지** — 본 Skill 은 검증 + 미세 조정 전용. 신규 토큰 도입은 사용자 결정 사항(별도 PR).
- **임시 패치는 반드시 회수** — 에이전트가 캡처 직후 `git restore` 로 회수한다. Phase 6 에서 잔존 여부 재확인.

---

## Phase 0 — 사전 준비 (슬롯 합의)

1. `$ARGUMENTS` 에서 슬롯 값 파싱 (Figma URL → `<FigmaFileKey>` + `<FigmaNodeId>` 자동 추출).
2. 미충족 필수 슬롯이 있으면 **1회** 사용자에게 확인:
   - "Figma 노드 ID / 비교 대상 컴포넌트 경로 / 라이브 라우트 / 프로젝트 디자인 가이드 파일(있다면) / viewport / dev server URL / 검증 명령을 알려주세요."
3. `<DesignGuide>` 파일이 존재하면 컬러/타이포/spacing/z-index/터치 관련 섹션을 Read.
4. `<TokenSSOT>` / `<ZIndexSSOT>` 파일이 존재하면 상수 표 파악.
5. `<LayoutScaleSSOT>` 파일이 존재하면 Figma → device 변환식 확인.

---

## Phase 1~4 — 캡처·시각 diff·가이드 검증 (에이전트 위임)

> ⚠️ **실행 주체는 `visual-diff-capture` 에이전트이다.**  
> 스크린샷·멀티모달 바이트는 에이전트 컨텍스트에 격리되고, 메인 루프에는 충실도 리포트만 리턴된다.

Phase 0에서 확정된 슬롯 값으로 `visual-diff-capture` 에이전트를 호출한다:

- **전달 슬롯**: `<FigmaFileKey>`, `<FigmaNodeId>`, `<DevServerURL>`, `<LiveRoute>`,
  `<ComponentPath>`, `<DesignGuide>`, `<TokenSSOT>`, `<ZIndexSSOT>`, `<BaselineViewport>`
- **에이전트 수행 내용**:
  - Phase 1 — Figma reference 캡처 (`references/figma-capture.md` 참조)
  - Phase 2 — 라이브 렌더 캡처 (`references/live-capture.md`, `references/state-patch-pattern.md` 참조)
  - Phase 3 — Multimodal 시각 diff (`references/diff-checklist.md` 참조)
  - Phase 4 — 프로젝트 디자인 가이드 정합성 검증 (`references/design-guide-mapping.md` 참조)
- **리턴값**: 차이 목록·토큰/상수 후보·Phase 5 미세조정 대상을 담은 **충실도 리포트**

에이전트가 리포트를 리턴하면 그대로 수령한다.

**예외 처리**: 에이전트 리포트에 "Chrome DevTools MCP 연결 실패"가 포함된 경우,
사용자에게 1줄로 요청한다: `"Chrome 브라우저를 --remote-debugging-port=9222 옵션으로 실행해 주세요."` → 확인 후 에이전트 재시도.

---

## Phase 5 — 미세 조정 (선택)

- **허용 변경**: 레이아웃 상수 값 / 이미 정의된 토큰의 적용.
- **금지 변경**: SSOT 변환식 / 비즈니스 로직 / 상태 머신 / 신규 토큰 정의.
- 화면별로 "캡처 → 비교 → 조정 → 재캡처" **1 사이클씩** 진행.
- 변경 단위는 1개 파일, 1회 commit 으로 회수 가능해야 한다.

---

## Phase 6 — 회수 + 검증

1. 임시 패치 회수 (에이전트가 캡처 직후 회수했으나 잔존 여부 재확인):
   ```bash
   git restore <패치된 파일>
   ```
2. 잔존 패치 확인 (에이전트 리포트에 잔존 기록이 있으면 반드시 포함):
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

| 파일 | 내용 | 참조 주체 |
|------|------|---------|
| `references/figma-capture.md` | Figma MCP 3개 도구 사용 가이드 + URL 파싱 + 스케일 변환 | visual-diff-capture 에이전트 |
| `references/live-capture.md` | Playwright/Chrome DevTools MCP 캡처 가이드 + 충돌 해결 | visual-diff-capture 에이전트 |
| `references/diff-checklist.md` | 화면 카테고리별 시각 diff 체크리스트 템플릿 | visual-diff-capture 에이전트 |
| `references/state-patch-pattern.md` | 임시 state 강제 진입 패턴 + git restore 회수 | visual-diff-capture 에이전트 |
| `references/design-guide-mapping.md` | 프로젝트 디자인 가이드 ↔ Figma 메타데이터 매핑 가이드 | visual-diff-capture 에이전트 |
