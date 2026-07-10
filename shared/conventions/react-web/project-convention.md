# Project Convention — React Web Preset

이 문서는 **React Web 프로젝트용 preset**입니다. bracket 선택형 메뉴가 아니라, 한 가지로 결정된 예시 스택과 실제 코드/테이블로 구성되어 있습니다.
최초 주입 후에는 아래 예시 스택·코드를 프로젝트의 실제 선택으로 즉시 교체하세요.

---

## Stack

- **Language:** JavaScript + JSDoc (TypeScript 미사용)
- **Framework:** React (Vite)
- **UI Library:** Ant Design
- **State:** Context API + Provider chain
- **Routing:** React Router
- **Data Fetching:** fetch + 커스텀 API 모듈 (`src/api/`)
- **i18n:** react-i18next
- **Test:** Vitest + @testing-library/react + happy-dom

---

## Coding Style

### Naming

| 대상 | 규칙 | 예시 |
|------|------|------|
| 컴포넌트 파일 | PascalCase.jsx | `AppHeader.jsx`, `SafeModal.jsx` |
| 유틸/훅 파일 | camelCase.js | `debug.util.js`, `useBootSplash.js` |
| 상수 파일 | PascalCase.js | `SchemaNames.js`, `ItemStatus.js` |
| 컴포넌트 | PascalCase | `export default AppHeader` |
| 커스텀 훅 | use + PascalCase | `useBootSplash`, `useInViewport` |
| Context 훅 | useXxxOrThrow | `useToolbarOrThrow()` |
| Private 헬퍼 | # + prefix | `#requireBooleanOrThrow` |
| 상수 | UPPER_SNAKE_CASE | `ZINDEX.HEADER`, `ITEM_STATUS.CREATE` |
| 변수/함수 | camelCase | `showTimeText`, `loadConfig` |

- 이름은 **도메인 + 맥락 + 의도**를 담아 3단어 이상 권장. 제네릭 이름 회피.

### Code Size

- **Functions:** ≤50 lines (target), **100 lines max** (hard limit).
- **Files:** ≤500 lines (target), **1000 lines max** (hard limit).

### Import Order

```javascript
// 1. React / 외부 라이브러리
import { useEffect, useMemo, useState } from "react";
import { Button, Typography } from "antd";
import { useTranslation } from "react-i18next";

// 2. 유틸 / 상수
import { createDebugger } from "../../common/debug.util";
import { ZINDEX } from "../../constants/ZIndexHelper";

// 3. 컨텍스트 / 모델
import { useAuth } from "../../context/network/AuthProvider";
import MenuItem from "../../model/MenuItem";

// 4. 컴포넌트 / 스타일
import UserCard from "./components/UserCard";
import styles from "./userCard.style";
```

### Constants

- 매직 넘버/문자열 금지 → named constant 추출
- 파일 상단 (import 직후, 함수 전)
- `Object.freeze()` 적용
- 도메인별 그룹화

```javascript
export const ITEM_QUANTITY_RULE = Object.freeze({
    key: "itemQuantity",
    min: 0,
    max: 999,
    precision: 0,
    defaultValue: 1,
});
```

---

## Core Rules

- **Functional 컴포넌트만** 사용(class 컴포넌트 금지), **default export**
- Props는 함수 시그니처에서 **destructuring**
- Hooks: `useXxx` prefix, 커스텀 훅은 `hooks/` 디렉토리
- **i18n:** 하드코딩 텍스트 금지 → `useTranslation()` 사용, 번역 키는 화면/도메인 단위 네임스페이스로 분리(예: `common.save`, `productList.title`)

---

## Component Pattern

### Context / Provider

```javascript
// Context 파일 (XxxContext.js)
export const ToolbarContext = createContext(null);
export function useToolbarOrThrow() {
    const ctx = useContext(ToolbarContext);
    if (!ctx) throw new Error("useToolbar must be used within a ToolbarProvider");
    return ctx;
}

// Provider 파일 (XxxProvider.jsx)
export const ToolbarProvider = ({ children }) => {
    const value = useMemo(() => ({ ... }), [deps]);
    return <ToolbarContext.Provider value={value}>{children}</ToolbarContext.Provider>;
};
export const useToolbar = () => useToolbarOrThrow();
```

- Context와 Provider 파일 분리
- `createContext(null)` + `useXxxOrThrow()` 패턴 (Contract: missing provider → throw)
- `useMemo`로 context value 감싸기 (불필요한 re-render 방지)
- Composition over inheritance

---

## UI and Styling

- **Ant Design token** (`theme.useToken()`) 으로 동적 테마 색상 사용
- **인라인 스타일 객체** — 동적 값에 사용
- **CSS 파일** — 애니메이션/키프레임 전용
- z-index는 `ZINDEX` 상수 사용 (SSOT: `constants/ZIndexHelper.js`)

```javascript
const { token } = theme.useToken();
const styles = {
    header: {
        position: "sticky",
        height: "5.33rem",
        zIndex: ZINDEX.HEADER,
        borderBottom: `1px solid ${token.colorBorder}`,
    },
};
```

---

## Design Pattern

### Model Class

```javascript
export default class Product {
    #name; // private field
    constructor({ name, sku, price } = {}) {
        this.name = Product.#validateText(name, "name");
        this.validate();
    }
    static #validateText(value, field) { /* ... */ }
    static from(obj) { return new Product(obj); }
    toJSON() { this.validate(); return { ... }; }
}
```

- ES6 class + `#private` fields
- `from()` static factory method
- `toJSON()` for serialization
- `validate()` on construction

### Validation (Contract)

- `*OrThrow` 헬퍼 함수: 계약 경계에서 입력 검증, 실패 시 throw
- context message 포함: `throw new Error(\`\${module}: \${field} is required\`)`

---

## Data & Platform Integration

### State Management

- **Context API + Provider chain** — `App.jsx`가 Provider 순서 SSOT
- **Provider 순서 = 의존관계 순서** → 변경 금지 (변경 시 하위 훅 undefined)
- 도메인별 Provider 분리 (Auth, Theme, Notification, Analytics 등)
- Provider에서 `useMemo`로 value 감싸기

### Data Fetching / API Layer

- API 호출은 `src/api/` 아래 도메인별 모듈로만 수행 — 컴포넌트에서 직접 `fetch` 금지
- 요청 상태는 `idle/loading/success/error` 4단계로 표현하고, 화면은 각 단계를 명시적으로 렌더링

```javascript
// src/api/productApi.js
export async function fetchProduct(id) {
    const response = await fetchWithAuth(`/products/${id}`);
    if (!response.ok) throw new Error(`fetchProduct: ${response.status}`);
    return response.json();
}

// 사용부
const [state, setState] = useState({ status: "idle", data: null, error: null });
useEffect(() => {
    setState({ status: "loading", data: null, error: null });
    fetchProduct(id)
        .then((data) => setState({ status: "success", data, error: null }))
        .catch((error) => setState({ status: "error", data: null, error }));
}, [id]);
```

### Routing

- 라우트 정의는 단일 파일(`src/routes.jsx` 등)에서 SSOT로 관리 — 화면 컴포넌트에 라우트 문자열 하드코딩 금지
- 대형 페이지는 `lazy` + `Suspense`로 지연 로딩 (아래 Performance의 dynamic import 원칙과 동일)
- 테스트/디버그 전용 라우트는 프로덕션 빌드에서 제외 (Pitfalls 참고)

```javascript
const ProductDetailPage = lazy(() => import("./pages/ProductDetailPage"));
```

---

## Performance

- `useMemo`: context value, 비용 높은 계산
- `useCallback`: 이벤트 핸들러 (불필요한 re-render 방지)
- Viewport-based lazy rendering (`useInViewport` 훅)
- Dynamic import: 대형 페이지/컴포넌트 지연 로딩

---

## Testing

- **Framework:** Vitest + @testing-library/react + happy-dom
- **위치:** 소스 파일과 같은 디렉토리 (colocated, `*.test.js`)
- **구조:** `describe(단위)` → `it(동작)` → `expect(결과)`
- Provider 의존 컴포넌트 테스트 시: 최소 mock, 실 Provider 우선

---

## Security & Reliability

### Error Handling

| 상황 | 처리 |
|------|------|
| Contract boundary | `*OrThrow` → `throw Error` with context message |
| HTTP (ApiController) | `fetchWithAuth` 에러 → 호출자에서 catch/handle |
| I/O (DB, 파일) | try-catch + `console.error` + rethrow or explicit handle |
| Provider 초기화 | catch + `console.error` + rethrow |

**금지:** silent catch(빈 catch 블록) / implicit fallback(에러 삼키고 기본값 반환) / `typeof` 가드로 조용히 넘기기 → `*OrThrow` 사용

### Logging

| 레벨 | 용도 |
|------|------|
| `console.error(msg, err)` | caught error — 모듈명 + 맥락 포함 |
| `console.warn(msg)` | fallback/degraded path |
| `createDebugger(namespace)` | 도메인별 디버그 (개발 전용) |

### Security

- API key, token, credential 하드코딩 금지
- Sensitive files 목록 참조 (CLAUDE.md → Sensitive Files)
- 권한은 RBAC (`hasRoleAccess`) 통해 검증

---

## Comment Rules

- **한국어** 사용, 자명한 코드에는 금지, 타겟 독자는 5년차 미드레벨 엔지니어
- 아래 3종은 독립 판단 — 한 대상이 여러 개 해당하면 나란히 작성(순서 무관)

### 프로젝트 기본 주석

- 재사용되는 공개 API로 파라미터·반환값 의미가 이름만으로 드러나지 않을 때
- 사이드이펙트가 있는 훅/유틸 (구독·타이머·이벤트 리스너 등록 등)
- 특정 조합·범위만 허용되는 상수/설정 객체
- Description은 필수, `@param`/`@returns`/`@throws`는 의미가 자명하지 않을 때만 추가

```javascript
/**
 * 재고 수량이 재주문 임계값 이하인지 판단한다.
 * @param {number} remainingQty - 현재 재고 수량
 * @param {number} thresholdQty - 재주문 트리거 임계값
 * @returns {boolean} 임계값 이하면 true
 * @throws {Error} remainingQty가 음수일 때
 */
function shouldReorderStock(remainingQty, thresholdQty) {
    if (remainingQty < 0) throw new Error("remainingQty는 음수일 수 없습니다");
    return remainingQty <= thresholdQty;
}
```

### Rationale Comment

- **Workaround/Hack** — 외부 라이브러리·특정 브라우저·레거시 시스템의 버그·특이 동작 우회
- **Business Rule** — 코드만으로 유추 불가능한 도메인 규칙(오프라인 정책, 비직관적 제품 스펙 등)
- **Non-obvious Trade-off** — 가독성보다 성능·보안을 택한 경우 (비트 연산, 복잡한 정규식, 캐싱 레이어 등)
- `[WHY]`(필수)/`[CONTEXT]`/`[TRADE-OFF]` 태그로 1~2줄만, 무거운 템플릿 금지

```javascript
// [WHY] 외부 결제 SDK가 iOS Safari에서 blur 이벤트를 중복 발생시키는 버그 우회
// [CONTEXT] 오프라인 매장은 재고 음수를 허용하는 정책(온라인과 다른 룰)
// [TRADE-OFF] O(1) 조회를 위해 메모리 캐시 사용, 최대 10MB 제한
```

### Provider Header

- 적용 대상: Context/Provider 파일(`XxxContext.js`/`XxxProvider.jsx`) 최상단, 항상 붙인다
- `Domain` — 이 컨텍스트가 담당하는 책임 경계 (필수)
- `Contract` — Provider 배치 순서 등 코드로 드러나지 않는 전제조건 (선택)

```javascript
// Domain: Toolbar context SSOT boundary
// Contract: AuthProvider보다 하위에 위치해야 함 — 로그인 상태로 노출 항목을 계산하므로 순서가 바뀌면 툴바가 항상 비어 보임
export const ToolbarContext = createContext(null);
export function useToolbarOrThrow() {
    const ctx = useContext(ToolbarContext);
    if (!ctx) throw new Error("useToolbar must be used within a ToolbarProvider");
    return ctx;
}
```

---

## Pitfalls

| 실수 | 결과 | 방지 |
|------|------|------|
| Provider 순서 변경 | 하위 훅 undefined | `App.jsx` 순서 = 의존관계 SSOT |
| 파생 가능한 값을 state로 중복 보관 | 동기화 drift, stale UI | 계산으로 유지하거나 `useMemo` 사용 |
| API 응답 타입을 여러 파일에서 재정의 | 타입명 불일치 | 타입은 `SchemaNames.js` 등 단일 SSOT에서만 정의 |
| 테스트 전용 라우트를 프로덕션 빌드에 노출 | 예기치 못한 진입점 노출 | 라우트 가드 또는 빌드 분기로 제외 (Data & Platform Integration › Routing 참고) |
| Contract 위반 시 `typeof` 가드로 조용히 처리 | 에러 은폐 | `*OrThrow` 헬퍼 사용 |

---

## Project Decisions

아래는 preset 주입 후 반드시 프로젝트 실정에 맞게 채운다.

- **Directory Policy:** [feature-first / layer-first / route-first]
- **State SSOT:** [예: Provider chain은 `src/App.jsx` 순서를 따름]
- **API Layer SSOT:** [예: `src/api/`]
- **Routing SSOT:** [예: `src/routes.jsx`]
- **UI Guideline SSOT:** [예: `docs/DESIGN.md`]
- **Sensitive Files:** [예: `.env*`, `*.pem`]
