# Figma MCP 캡처 가이드

Figma 디자인을 MCP 를 통해 캡처하고 메타데이터를 추출하는 방법.

---

## URL 파싱 — fileKey / nodeId 추출

Figma URL 형태별 추출 규칙:

| URL 형태 | fileKey | nodeId |
|---------|---------|--------|
| `figma.com/design/:fileKey/:name?node-id=100-200` | `:fileKey` | `100-200` → `100:200` (`-` → `:` 변환) |
| `figma.com/design/:fileKey/branch/:branchKey/:name` | `:branchKey` | `node-id` 파라미터 |
| `figma.com/board/:fileKey/:name?node-id=...` | `:fileKey` | FigJam 파일 → `get_figjam` 사용 |
| `figma.com/slides/:fileKey/:name?node-id=...` | `:fileKey` | 동일 |
| `figma.com/make/:makeFileKey/:name` | `:makeFileKey` | — |

**핵심**: `node-id` 쿼리 파라미터의 `-` 를 `:` 로 변환해야 한다.

```
# 예시
URL:    figma.com/design/l1FatcIO30RsZ8AiRDsWRN/MyApp?node-id=4105-1517
fileKey: l1FatcIO30RsZ8AiRDsWRN
nodeId:  4105:1517
```

---

## 도구 3종 사용 순서

### 1. `get_screenshot` — 시각 참조 캡처 (필수)

```
mcp__plugin_figma_figma__get_screenshot(
  nodeId = "<FigmaNodeId>",
  fileKey = "<FigmaFileKey>"
)
```

- 결과를 **상대 경로** `figma_<screen_name>.png` 로 저장.
  - 절대 경로는 `allowed roots` 제약으로 실패할 수 있음.
- 프레임 전체 또는 컴포넌트 단위 캡처 모두 가능. 비교 목적이라면 **컴포넌트 단위** 가 편리.

### 2. `get_metadata` — 좌표/사이즈/색상/폰트 (필수)

```
mcp__plugin_figma_figma__get_metadata(
  nodeId = "<FigmaNodeId>",
  fileKey = "<FigmaFileKey>"
)
```

메타데이터에서 추출하는 항목:

| 항목 | Figma 필드 | 용도 |
|------|-----------|------|
| 위치 | `x`, `y` | 절대 좌표 → 비례 변환 후 비교 |
| 크기 | `width`, `height` | 박스 사이즈 비교 |
| 색상 | `fills[*].color` | hex 추출 → 토큰 매핑 |
| 테두리 반경 | `cornerRadius` | border-radius 비교 |
| 폰트 | `style.fontFamily`, `style.fontWeight`, `style.fontSize` | 타이포 비교 |
| 테두리 | `strokes[*].color`, `strokeWeight` | border 비교 |
| 라인 높이 | `style.lineHeightPx` | line-height 비교 |
| 불투명도 | `opacity` | opacity 비교 |

### 3. `get_design_context` — 코드 힌트 (선택)

```
mcp__plugin_figma_figma__get_design_context(
  nodeId = "<FigmaNodeId>",
  fileKey = "<FigmaFileKey>"
)
```

- Code Connect 매핑이 있으면 실제 컴포넌트 코드 스니펫을 반환.
- 없으면 React + Tailwind 기반의 참조 코드를 반환 — **그대로 사용하지 말고** 프로젝트 스택에 맞게 적용.

---

## 스케일 변환

Figma frame 크기와 라이브 렌더의 `<BaselineViewport>` 가 다를 수 있다. 비교 전에 반드시 스케일을 맞춘다.

**공식:**
```
scale = <BaselineViewport 폭> / <Figma frame 폭>

device_value = figma_value × scale
```

**예시:**
- Figma frame 1920px, device viewport 1280px → `scale = 1280 / 1920 ≈ 0.6667`
- Figma frame 1440px, device viewport 1440px → `scale = 1.0` (변환 불필요)
- Figma frame 375px (모바일), device viewport 390px → `scale = 390 / 375 ≈ 1.04`

> 스케일 변환 SSOT 가 프로젝트에 있으면(`<LayoutScaleSSOT>`) 그 값을 우선 사용한다.

---

## 색상 추출 패턴

Figma 메타데이터의 색상은 `{ r, g, b, a }` 형태(각 0~1)로 반환된다.

```
hex = '#' + [r, g, b].map(c => Math.round(c * 255).toString(16).padStart(2, '0')).join('')
```

Figma variable (디자인 토큰)이 적용된 노드는 `fills[*].boundVariables` 로 변수 ID를 확인할 수 있다. 변수 이름은 `get_variable_defs` 로 조회 가능.

---

## 권한 / 접근 가드

- **Figma workspace 접근 불가**: `get_screenshot` 가 실패하면 사용자에게 "Figma MCP 인증이 필요합니다 — Figma 계정 로그인 후 재시도해주세요" 한 줄 안내.
- **Private 노드**: 공개 링크가 아닌 경우 workspace 멤버 권한 필요. 권한 없으면 사용자에게 접근 권한 확인 요청.
- **노드 미발견**: 삭제/이동된 노드 ID 가능성. 사용자에게 최신 URL 재확인 요청.
