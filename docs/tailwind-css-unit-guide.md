## CSS 단위 규칙 (px / rem) — Tailwind CSS 기준

> 적용 범위: **웹 CSS 전용.** React Native에는 적용하지 않는다(RN은 무단위 dp와 `fontScale`로 별도 처리).
> 전제 프레임워크: **Tailwind CSS.** 표준 유틸리티를 우선 사용하고, 불가피한 경우에만 arbitrary value(`[...]`)를 쓴다.

### 핵심 원칙

`rem`을 쓰는 유일한 목적은 **사용자의 브라우저 기본 글꼴 크기 설정을 존중**하기 위함이다.
(브라우저 zoom은 px·rem을 동일하게 확대하므로 zoom은 판단 근거가 아니다.)

**Tailwind은 이 판단을 대신 해준다.** `text-*`와 표준 spacing 스케일(`p-`, `m-`, `gap-`, `w-`, `h-` 등)은 내부적으로 rem으로 컴파일되고, `border`·`shadow` 같은 시각 디테일은 px로, breakpoint는 px로 컴파일된다. 이 기본값들은 이미 접근성과 예측 가능성의 균형이 잡혀 있다. 따라서 이 가이드의 메타 원칙은 하나다 — **Tailwind 기본값과 싸우지 말 것. 표준 유틸리티를 벗어난 arbitrary 값은 꼭 필요할 때만 쓸 것.**

---

### 규칙 1 — 글꼴 크기는 `text-*` 유틸리티 사용, 임의 px 금지

- `text-base`, `text-lg` 등 표준 유틸리티는 rem으로 컴파일된다. 이것만 쓴다.
- `text-[16px]`처럼 **arbitrary px로 폰트를 고정하는 것은 금지**(사용자 글꼴 설정 무력화).

```jsx
{/* Good */}
<p className="text-base">본문</p>
{/* Bad — 폰트를 px로 고정 */}
<p className="text-[16px]">본문</p>
```

### 규칙 2 — 여백·크기는 표준 스케일 사용 (버튼·레이아웃 구분 불필요)

대상: `p-`, `m-`, `gap-`, `w-`, `h-`, `min/max-*` 등.

- **표준 스케일 유틸리티(`p-4`, `gap-4`, `w-60`)만 사용한다.** 전부 rem으로 컴파일된다.
- 표준 스케일이 rem이므로 **텍스트를 담은 버튼도 자동으로 함께 스케일**된다. raw CSS 때와 달리 "버튼이냐 레이아웃이냐"를 따로 구분할 필요가 없다.
- **예외(px 허용):** 텍스트 확대와 무관하게 고정돼야 하는 순수 에셋(로고, 아이콘 박스 등)만 `w-[24px]`처럼 arbitrary px 사용.

```jsx
{/* Good — 버튼: 표준 스케일(rem), 글자와 함께 스케일 */}
<button className="px-4 py-2">저장</button>

{/* Good — 레이아웃 간격도 동일하게 표준 스케일 */}
<div className="flex gap-4">...</div>

{/* Good(예외) — 고정 크기 아이콘 에셋만 px */}
<img src={logo} className="w-[24px] h-[24px]" />
```

### 규칙 3 — 시각 디테일은 Tailwind 기본값을 그대로 둔다 (px는 px, radius는 rem)

- `border`(width), `box-shadow`, `outline`, `ring`, `ring-offset`은 Tailwind 기본값이 **px**다 → 그대로 둔다. 스케일되면 hairline이 번진다.
- `rounded-*`(border-radius)는 Tailwind 기본값이 **rem**이다 → 이 또한 그대로 둔다. 모서리 반경이 폰트 설정에 따라 미세하게 커지는 건 사실상 눈에 띄지 않고 무해하며, px로 강제하면 유지보수 마찰만 생긴다.
- 원칙: **시각 디테일은 어느 방향으로도 Tailwind 기본값과 싸우지 않는다.** 임의 두께가 꼭 필요할 때만 `border-[2px]`처럼 px로 지정.

```jsx
{/* Good — 기본값 유지: border(px), rounded(rem) 모두 그대로 */}
<button className="px-4 py-2 border border-border rounded-lg">저장</button>
```

### 규칙 4 — `line-height`는 무단위 배수 유틸리티 사용

- `leading-normal`, `leading-tight`, `leading-relaxed` 등 **배수(무단위) 유틸리티**를 쓴다. 자기 `font-size`에 비례한다.
- `leading-6`(= 1.5rem 고정) 같은 **길이 기반 유틸리티는 지양**. 로컬 폰트 크기 변경 시 비례하지 않는다.

```jsx
{/* Good */}
<p className="text-base leading-normal">본문</p>
{/* Avoid — 고정 길이 line-height */}
<p className="text-base leading-6">본문</p>
```

### 규칙 5 — 반응형 breakpoint는 Tailwind 기본값(px) 그대로

- `sm:`, `md:`, `lg:` 등 표준 prefix를 쓰고, **breakpoint 단위는 Tailwind 기본값(px)을 유지**한다. `screens`를 rem으로 재정의하지 않는다.
- 근거: breakpoint는 뷰포트 **너비**에 대한 분기이지 글자 크기에 대한 분기가 아니다. 폰트·여백은 이미 rem이라 사용자가 기본 글꼴을 키우면 콘텐츠는 알아서 커진다. breakpoint까지 rem으로 바꾸면 글꼴 설정에 따라 레이아웃 분기점이 움직여 오히려 예측이 어려워지고, Tailwind 업그레이드 시 config 유지보수 부담만 는다.
- **px breakpoint + rem 여백/폰트** 조합은 접근성 손실 없이 동작이 일관된다.

```jsx
{/* 표준 prefix 그대로, config 재정의 불필요 */}
<div className="grid grid-cols-1 md:grid-cols-2">...</div>
```

### 규칙 6 — 금지 사항

- `html { font-size: 62.5% }` (1rem=10px 트릭) **채택 금지**. 기본 `1rem = 16px` 유지.
- **표준 스케일을 우회하는 arbitrary 값 남용 금지.** 폰트·여백을 `[...px]`로 고정하지 말 것(규칙 2 예외인 순수 에셋 제외). 시각 디테일도 Tailwind 기본값을 임의 값으로 덮어쓰지 말 것(규칙 3).

---

### 판단 순서 (애매할 때)

1. 글꼴 크기인가? → **`text-*` 표준 유틸리티** (arbitrary px 금지)
2. `line-height`인가? → **`leading-normal` 등 무단위 배수 유틸리티**
3. `border`/`shadow`/`outline`/`ring`/`rounded` 등 시각 디테일인가? → **Tailwind 기본값 그대로** (px든 rem이든 건드리지 않음)
4. 반응형 breakpoint인가? → **표준 prefix + Tailwind 기본 px** (`screens` 재정의 없음)
// TODO 모바일 퍼스트(Mobile-First) 또는 데스크탑 퍼스트(Desktop-First)에 따른 판단 기준 / 가이드 변경이 필요할 수 있음
5. 여백/크기인가?
   - 텍스트 확대와 무관한 **순수 에셋(로고·아이콘)** 인가? → **arbitrary px** (`w-[24px]`)
   - 아니면 → **표준 스케일** (`p-4`, `gap-4` … = rem)

### 한 줄 요약

> **Tailwind 기본값과 싸우지 마라. 표준 유틸리티만 쓰면 rem(폰트·여백)·px(디테일·breakpoint) 배치가 이미 접근성과 예측 가능성을 만족한다. 벗어난 arbitrary 값은 순수 에셋과 불가피한 경우에만.**
