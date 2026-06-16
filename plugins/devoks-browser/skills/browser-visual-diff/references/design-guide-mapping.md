# 프로젝트 디자인 가이드 ↔ Figma 메타데이터 매핑 가이드

Phase 3 에서 추출한 Figma 메타데이터를 프로젝트의 디자인 가이드/토큰 SSOT 와 매핑하는 방법.

---

## 슬롯 확인 우선

이 가이드의 모든 "토큰 SSOT", "z-index SSOT", "스케일 SSOT" 는 **프로젝트의 `<TokenSSOT>`, `<ZIndexSSOT>`, `<LayoutScaleSSOT>` 슬롯** 을 가리킨다. 매핑 전에 해당 파일이 존재하는지 확인하고, 존재하면 그 내용을 Read 해 정확한 값을 파악한다.

---

## 1. 컬러 토큰 매핑

### Figma → hex 추출
`get_metadata` 결과의 `fills[*].color` 는 `{ r, g, b, a }` (각 0~1) 형태다.

```
hex = '#' + [r, g, b].map(c => Math.round(c * 255).toString(16).padStart(2, '0')).join('')
```

### hex → 토큰 매핑 절차

1. `<TokenSSOT>` 파일을 Read 해 토큰 표를 파악.
2. 추출한 hex 가 토큰 표에 있으면 → **토큰 이름 사용 권장**으로 기록.
3. 토큰 표에 없으면 → 아래 3단계 판정:

```
raw hex 발견
    │
    ├─ (1) 기존 토큰의 변형(투명도 조정 등)으로 표현 가능한가?
    │       YES → 토큰 + opacity 로 대체 가능, 권장 항목으로 기록
    │       NO  → ↓
    │
    ├─ (2) 2곳 이상에서 같은 hex 가 반복되는가?
    │       YES → 신규 토큰 후보 (별도 PR에서 추가 권장)
    │       NO  → ↓
    │
    └─ (3) 1회성 사용이고 디자인 가이드에 Known Gaps / 예외로 등록 가능한가?
            YES → Known Gaps 후보로 메모
            NO  → 디자인 오너 확인 필요
```

---

## 2. 타이포그래피 매핑

Figma 메타데이터 `style` 필드에서 추출:

| Figma 필드 | CSS 대응 | 매핑 포인트 |
|-----------|---------|------------|
| `fontFamily` | `font-family` | 프로젝트의 허용 폰트 패밀리 목록과 비교 |
| `fontWeight` | `font-weight` | 숫자(400, 700 등) 또는 Named(`Bold`, `Medium`) |
| `fontSize` | `font-size` | 스케일 변환 필요 (`<LayoutScaleSSOT>` 참조) |
| `lineHeightPx` | `line-height` | px 값 또는 배수로 변환 |
| `letterSpacing` | `letter-spacing` | em 단위 환산 |

`<TokenSSOT>` 에 타이포 토큰이 있으면 (`fontSizeSm`, `fontWeightBold` 등) 해당 토큰 사용 여부 확인.

---

## 3. 간격 / 사이즈 매핑

Figma 메타데이터 `width`, `height`, `paddingLeft`, `paddingTop`, `itemSpacing` 등에서 추출.

- 스케일 변환 필수: `device_value = figma_value × scale` (`figma-capture.md` §스케일 변환 참조).
- `<TokenSSOT>` 에 spacing 토큰(`spacing-4`, `gap-md` 등)이 있으면 가장 가까운 토큰 값과 비교.
- 4px 이내 오차면 해당 토큰 사용으로 대체 가능.

---

## 4. 테두리 반경 (border-radius) 매핑

Figma 메타데이터 `cornerRadius` / `rectangleCornerRadii` 에서 추출.

- 스케일 변환 후 프로젝트의 radius 토큰과 비교.
- 대표적인 표준 값: 4px, 6px, 8px, 12px, 16px (프로젝트마다 다름).

---

## 5. z-index 매핑

- Figma 는 레이어 순서로 z-index 를 표현하므로 직접 추출 불가.
- 라이브 렌더에서 `z-index` 가 직접 숫자로 쓰여 있으면 (`z-index: 1000` 등) → `<ZIndexSSOT>` 의 상수로 대체 권장.
- `<ZIndexSSOT>` 가 없는 프로젝트: 직접 숫자 사용은 코드 리뷰 시 지적 항목으로 메모.

---

## 6. Baseline viewport 검증

`<BaselineViewport>` (예: `1280×720`) 에서 확인할 사항:

| 체크 항목 | 기준 |
|----------|------|
| primary action(CTA 버튼)이 화면 내에 있는가 | fold 밖으로 밀리면 수정 필요 |
| 모달/다이얼로그가 화면에 다 들어오는가 | 프로젝트 최대 모달 폭 제한 초과 여부 |
| 스크롤 없이 핵심 콘텐츠 접근 가능한가 | 정보 표시 화면, 결과 화면 등 |
| 최소 터치 타깃 충족 | `<DesignGuide>` 기준, 없으면 48dp/pt |

---

## 디자인 가이드 없는 경우 폴백 기준

`<DesignGuide>` 가 없거나 해당 항목이 명시되지 않은 경우 다음 표준을 참조:

| 항목 | 폴백 기준 |
|------|----------|
| 터치 타깃 최소 크기 | 48px (WCAG 2.5.5, Android 48dp, iOS 44pt) |
| 색상 대비 (텍스트) | WCAG AA: 4.5:1 (일반) / 3:1 (대형 텍스트) |
| 색상 대비 (UI 컴포넌트) | WCAG AA: 3:1 |
| 폰트 크기 최소 | 12px (접근성 권장 16px) |
| 포커스 인디케이터 | 2px solid 이상 (WCAG 2.4.11) |
| 모달 최대 폭 | 뷰포트 폭의 90% 이내 |

---

## 매핑 결과 기록 형식

Phase 4 에서 발견한 항목을 다음 형식으로 기록:

```markdown
## 디자인 가이드 정합성 결과

### 토큰 매핑 성공
- `#A292FA` → `colorPrimary` 토큰 (버튼 배경)
- `#1A1A1A` → `colorBgElevated` 토큰 (카드 배경)

### 신규 토큰 후보
- `#FC5555` — 에러/실패 색상. 2곳에서 반복 사용. `colorError` 신규 토큰 권장.

### Known Gaps 후보
- `#FFED99` — 경고 강조 색상. 1회성. 현 디자인 가이드에 없음. Known Gaps 등록 검토.

### z-index 상수화 후보
- `SomeOverlay.jsx:15` — `z-index: 1000` 직접 사용. `ZINDEX.OVERLAY` 상수화 권장.

### 디자인 오너 확인 필요
- `#D4A027` (컴포넌트 X 의 특수 강조색) — 토큰 미매핑, 반복도 낮음. 디자인 의도 확인 필요.
```
