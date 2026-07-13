# Project Convention — React Web Preset

이 문서는 **React Web 프로젝트용 preset**입니다. bracket 선택형 메뉴가 아니라, 한 가지로 결정된 예시 스택과 실제 코드/테이블로 구성되어 있습니다.
최초 주입 후에는 아래 예시 스택·코드를 프로젝트의 실제 선택으로 즉시 교체하세요.

---

## Stack

- **Language:** JavaScript + JSDoc (TypeScript 미사용)
- **Build Tool (CSR):** Vite + React 19
- **Framework (SSR):** Next.js 16 (App Router) — CSR/SSR 중 하나를 프로젝트 결정으로 선택 (아래 "SSR Variant" 참고)
- **Routing (CSR):** React Router v7 (Data Router)
- **Styling:** Tailwind CSS v4 + shadcn/ui
- **Animation:** motion (구 `framer-motion`, import는 `motion/react`)
- **State:** Zustand v5 (도메인/앱 상태) + Context API (Auth/Theme 등 provider 경계가 필요한 cross-cutting 값만)
- **Server State / Data Fetching:** TanStack Query v5 + axios
- **Forms:** react-hook-form + zod(`zodResolver`)
- **i18n:** react-i18next
- **Lint/Format:** Biome (format + 기본 lint) + Oxlint (고속 보조 lint) — 단, React/Next.js 전용 규칙(`jsx-a11y` 등)은 Biome/Oxlint가 아직 커버하지 않으므로, 필요하면 ESLint로 대체할지 사용자 확인 필요
- **Test:** Vitest + @testing-library/react + happy-dom

### SSR Variant (Next.js)

- Next.js 16 App Router가 라우팅 SSOT — React Router는 사용하지 않는다.
- 데이터 패칭은 Server Component/Route Handler가 1차, 클라이언트 상호작용이 필요한 화면만 TanStack Query를 보조로 쓴다.
- Tailwind/shadcn/motion/zustand/react-hook-form+zod/Biome+Oxlint/테스트 스택은 CSR과 동일하게 적용한다.
- 프로젝트가 CSR/SSR 중 하나로 결정되면, 반대쪽 코드 예시는 프로젝트 convention에서 제거한다 — 두 갈래를 동시에 bracket처럼 남기지 않는다.

---

## Coding Style

### Naming

| 대상 | 규칙 | 예시 |
|------|------|------|
| 컴포넌트 파일 | PascalCase.jsx | `AppHeader.jsx`, `SafeModal.jsx` |
| 유틸/훅 파일 | camelCase.js | `debug.util.js`, `useBootSplash.js` |
| store 파일 | camelCase + `.store.js` | `cart.store.js`, `auth.store.js` |
| 상수 파일 | PascalCase.js | `SchemaNames.js`, `ItemStatus.js` |
| 컴포넌트 | PascalCase | `export default AppHeader` |
| 커스텀 훅 | use + PascalCase | `useBootSplash`, `useInViewport` |
| Context 훅 | useXxxOrThrow | `useToolbarOrThrow()` |
| shadcn/ui 컴포넌트 | CLI 생성 그대로 `components/ui/` 하위 유지 | `components/ui/button.jsx` |
| Private 헬퍼 | # + prefix | `#requireBooleanOrThrow` |
| 상수 | UPPER_SNAKE_CASE | `ZINDEX.HEADER`, `ITEM_STATUS.CREATE` |
| 변수/함수 | camelCase | `showTimeText`, `loadConfig` |

- 이름은 **도메인 + 맥락 + 의도**를 담아 3단어 이상 권장. 제네릭 이름 회피.
- `components/ui/` 하위 shadcn/ui 생성 파일은 CLI가 관리하는 영역으로 간주하고 직접 리팩터링하지 않는다 — 커스터마이징은 `components/` 상위 래퍼에서 한다.

### Code Size

- **Functions:** ≤50 lines (target), **100 lines max** (hard limit).
- **Files:** ≤500 lines (target), **1000 lines max** (hard limit).

### Import Order

```javascript
// 1. React / 외부 라이브러리
import { useEffect, useMemo, useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";

// 2. 유틸 / 상수
import { createDebugger } from "../../common/debug.util";
import { ZINDEX } from "../../constants/ZIndexHelper";

// 3. 스토어 / 쿼리 / 모델
import { useCartStore } from "../../store/cart.store";
import { useProductQuery } from "../../queries/useProductQuery";
import Product from "../../model/Product";

// 4. 컴포넌트 / 스타일
import { Button } from "../../components/ui/button";
import UserCard from "./components/UserCard";
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
- **서버 상태와 클라이언트 상태를 분리**: 서버 데이터는 TanStack Query, 화면/도메인 로컬 상태는 Zustand, cross-cutting 값(Auth/Theme)만 Context

---

## Component Pattern

### Context / Provider (cross-cutting 값 전용)

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

- Context는 Auth/Theme처럼 provider 경계가 실제로 필요한 cross-cutting 값에만 사용한다. 화면/도메인 상태를 Context로 끌어올리지 않는다.
- `createContext(null)` + `useXxxOrThrow()` 패턴 (Contract: missing provider → throw)
- `useMemo`로 context value 감싸기 (불필요한 re-render 방지)

### Store (Zustand)

```javascript
// cart.store.js
export const useCartStore = create((set) => ({
    items: [],
    addItem: (item) => set((state) => ({ items: [...state.items, item] })),
    removeItem: (id) => set((state) => ({ items: state.items.filter((i) => i.id !== id) })),
}));
```

- store는 도메인별로 분리한다 (`cart.store.js`, `ui.store.js`).
- selector 단위로 구독해 불필요한 re-render를 막는다: `useCartStore((state) => state.items)`.
- 서버에서 가져온 데이터를 store에 복제해 보관하지 않는다 — 서버 상태는 TanStack Query 캐시가 SSOT.

---

## UI and Styling

- Tailwind CSS v4 유틸리티 클래스가 기본 스타일링 수단이다. v4는 CSS-first 설정(`@theme` 디렉티브)이므로 `tailwind.config.js`에 디자인 토큰을 재정의하지 않는다 — 토큰 SSOT는 CSS의 `@theme` 블록.
- shadcn/ui 컴포넌트를 CLI로 생성해 `components/ui/`에 두고, `cva`(class-variance-authority)로 variant를 관리한다. Ant Design류 런타임 테마 토큰 API는 사용하지 않는다.
- 동적 클래스 조합은 `cn()`(clsx + tailwind-merge) 헬퍼로 처리하고, 인라인 스타일 객체는 Tailwind로 표현 불가능한 값(motion 애니메이션 중간값 등)에만 예외적으로 사용한다.
- z-index는 Tailwind 임의값 대신 `ZINDEX` 상수를 CSS 변수/`@theme` 토큰으로 노출해 사용한다 (SSOT: `constants/ZIndexHelper.js`).

```javascript
import { cn } from "../../lib/cn";
import { Button } from "../../components/ui/button";

function ProductActionBar({ isPending, className }) {
    return (
        <div className={cn("flex items-center gap-2", className)}>
            <Button variant="default" disabled={isPending}>
                주문하기
            </Button>
        </div>
    );
}
```

### Animation (motion)

- 화면 전환/등장 애니메이션은 `motion/react`의 `motion.div` 등으로 선언형으로 작성한다. 커스텀 CSS keyframe은 motion으로 표현 불가능한 경우에만 예외적으로 둔다.
- 레이아웃 애니메이션에는 `layout` prop을, 목록 추가/삭제에는 `AnimatePresence`를 사용한다.

```javascript
import { motion, AnimatePresence } from "motion/react";

<AnimatePresence>
    {isVisible && (
        <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}>
            {children}
        </motion.div>
    )}
</AnimatePresence>
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

- **Zustand** — 도메인/앱 로컬 상태의 기본 저장소. 도메인별 store 분리, selector 구독.
- **Context API** — Auth/Theme/Notification처럼 provider 순서가 의미를 갖는 cross-cutting 값만. `App.jsx`가 Provider 순서 SSOT.
- **Provider 순서 = 의존관계 순서** → 변경 금지 (변경 시 하위 훅 undefined)

### Data Fetching (TanStack Query + axios)

- API 호출은 `src/api/` 아래 axios 인스턴스(`apiClient`) + 도메인별 모듈로만 수행 — 컴포넌트에서 직접 `fetch`/`axios` 호출 금지.
- 서버 상태는 TanStack Query의 `useQuery`/`useMutation`으로만 다루고, 그 결과를 Zustand store에 복제하지 않는다.
- 인증 토큰 갱신, 공통 에러 변환은 axios interceptor에서 처리한다.

```javascript
// src/api/apiClient.js
export const apiClient = axios.create({ baseURL: import.meta.env.VITE_API_BASE_URL });
apiClient.interceptors.response.use(
    (response) => response,
    (error) => Promise.reject(new Error(`API error: ${error.response?.status}`)),
);

// src/api/productApi.js
export async function fetchProduct(id) {
    const { data } = await apiClient.get(`/products/${id}`);
    return data;
}

// src/queries/useProductQuery.js
export function useProductQuery(id) {
    return useQuery({ queryKey: ["product", id], queryFn: () => fetchProduct(id) });
}

// 사용부
const { data, status, error } = useProductQuery(id);
```

### Forms (react-hook-form + zod)

- 폼 상태는 `useForm` + `zodResolver`로 관리하고, 검증 스키마는 zod로 정의해 `*OrThrow` 계약과 동일하게 실패 시 명시적 에러 메시지를 노출한다.
- 폼 스키마는 컴포넌트 파일이 아닌 별도 모듈(`schemas/`)에 SSOT로 둔다.

```javascript
// schemas/productFormSchema.js
export const productFormSchema = z.object({
    name: z.string().min(1, "name is required"),
    price: z.number().min(0),
});

// 사용부
const form = useForm({ resolver: zodResolver(productFormSchema), defaultValues: { name: "", price: 0 } });
```

### Routing

- CSR: React Router v7 Data Router 라우트 정의는 단일 파일(`src/routes.jsx`)에서 SSOT로 관리 — 화면 컴포넌트에 라우트 문자열 하드코딩 금지.
- SSR: Next.js App Router의 파일 기반 라우팅이 SSOT — `src/routes.jsx` 없이 `app/` 디렉토리 구조 자체가 라우트 정의다.
- 대형 페이지는 `lazy` + `Suspense`(CSR) 또는 Next.js의 자동 코드 스플리팅(SSR)으로 지연 로딩한다.
- 테스트/디버그 전용 라우트는 프로덕션 빌드에서 제외 (Pitfalls 참고)

```javascript
const ProductDetailPage = lazy(() => import("./pages/ProductDetailPage"));
```

---

## Performance

- `useMemo`: context value, 비용 높은 계산
- `useCallback`: 이벤트 핸들러 (불필요한 re-render 방지)
- Zustand selector 구독으로 불필요한 리렌더 차단
- Viewport-based lazy rendering (`useInViewport` 훅)
- Dynamic import: 대형 페이지/컴포넌트 지연 로딩
- motion 애니메이션은 `layout`/`AnimatePresence` 남용 시 리렌더 비용이 커질 수 있어 목록 규모에 따라 사용 범위를 제한한다

---

## Testing

- **Framework:** Vitest + @testing-library/react + happy-dom
- **위치:** 소스 파일과 같은 디렉토리 (colocated, `*.test.js`)
- **구조:** `describe(단위)` → `it(동작)` → `expect(결과)`
- Provider 의존 컴포넌트 테스트 시: 최소 mock, 실 Provider 우선
- shadcn/ui(Radix 기반) 컴포넌트 테스트 시 `ResizeObserver`/`matchMedia` 등 happy-dom 미구현 API를 test setup에서 mock 처리 (Pitfalls 참고)
- TanStack Query 사용 컴포넌트는 테스트마다 새 `QueryClient`를 주입해 캐시 격리

---

## Security & Reliability

### Error Handling

| 상황 | 처리 |
|------|------|
| Contract boundary | `*OrThrow` → `throw Error` with context message |
| HTTP (axios) | interceptor에서 공통 변환 → 호출자(TanStack Query)에서 catch/handle |
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
- 권한은 RBAC (`hasRoleAccess`) 통해 검증 — 단, 클라이언트 검증은 UX 최적화일 뿐이며 인가 판단은 서버가 재검증
- `dangerouslySetInnerHTML`은 sanitize(DOMPurify 등) 없이 금지, React 밖 DOM 직접 조작(innerHTML 대입 등)으로 이스케이프 우회 금지
- 사용자 입력이 `href`/`src`로 흐르면 URL 스킴 검증 (`javascript:`/`data:` 차단)
- 인증 토큰은 `localStorage`/`sessionStorage` 저장 금지 → HttpOnly+Secure+SameSite 쿠키
- 공개 prefix env(`VITE_`/`NEXT_PUBLIC_`)에 시크릿 배치 금지, 프로덕션 소스맵 비공개
- lockfile 커밋 필수, 의존성 audit 정기 실행 (Critical/High 미해결 금지)
- `postMessage`는 targetOrigin 명시(`'*'` 금지) + 수신 origin 검증
- 심화 기준·탐지 시그널: `.claude/refs/web-security.md`

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

- 적용 대상: Context/Provider 파일(`XxxContext.js`/`XxxProvider.jsx`), Zustand store 파일(`*.store.js`) 최상단, 항상 붙인다
- `Domain` — 이 컨텍스트/store가 담당하는 책임 경계 (필수)
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
| 서버 응답을 Zustand store에 그대로 복제 | TanStack Query 캐시와 store가 따로 놀아 stale drift | 서버 상태는 TanStack Query만 SSOT로 사용 |
| shadcn/ui(Radix) 컴포넌트를 happy-dom에서 그대로 테스트 | `ResizeObserver is not defined` 등으로 실패 | test setup에서 `ResizeObserver`/`matchMedia` mock 등록 |
| Tailwind v4 토큰을 `tailwind.config.js`와 `@theme` 양쪽에 중복 정의 | 토큰 drift | v4는 `@theme` CSS 블록이 SSOT, config 파일에 재정의 금지 |
| 테스트 전용 라우트를 프로덕션 빌드에 노출 | 예기치 못한 진입점 노출 | 라우트 가드 또는 빌드 분기로 제외 |
| Contract 위반 시 `typeof` 가드로 조용히 처리 | 에러 은폐 | `*OrThrow` 헬퍼 사용 |

---

## Project Decisions

아래는 preset 주입 후 반드시 프로젝트 실정에 맞게 채운다.

- **Rendering Mode:** [CSR(Vite) / SSR(Next.js) 중 택1 — 결정 후 반대쪽 예시 코드 제거]
- **Directory Policy:** [feature-first / layer-first / route-first]
- **State SSOT:** [예: Zustand store는 `src/store/`, Context Provider 순서는 `src/App.jsx` 순서를 따름]
- **API Layer SSOT:** [예: `src/api/`, axios 인스턴스는 `src/api/apiClient.js`]
- **Design System SSOT:** [예: `components/ui/`(shadcn/ui) + `@theme` 토큰]
- **Routing SSOT:** [예: `src/routes.jsx`(CSR) 또는 `app/`(SSR)]
- **Sensitive Files:** [예: `.env*`, `*.pem`]
