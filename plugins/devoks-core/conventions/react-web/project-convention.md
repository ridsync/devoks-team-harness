# Project Convention — React Web Preset

이 문서는 **React Web 프로젝트용 preset**입니다. bracket 선택형 메뉴가 아니라, 한 가지로 결정된 예시 스택과 실제 코드/테이블로 구성되어 있습니다.
최초 주입 후에는 아래 예시 스택·코드를 프로젝트의 실제 선택으로 즉시 교체하세요.

---

## Stack

- **Language:** TypeScript (`strict: true`) — 규칙은 아래 "TypeScript" 절
- **Build Tool (CSR):** Vite + React 19
- **Framework (SSR):** Next.js 16 (App Router) — CSR/SSR 중 하나를 프로젝트 결정으로 선택 (아래 "SSR Variant" 참고)
- **Routing (CSR):** React Router v7 (Data Router)
- **Styling:** Tailwind CSS v4 + shadcn/ui
- **Animation:** motion (구 `framer-motion`, import는 `motion/react`)
- **State:** Zustand v5 (도메인/앱 상태) + Context API (Auth/Theme 등 provider 경계가 필요한 cross-cutting 값만)
- **Server State / Data Fetching:** TanStack Query v5 + axios
- **Forms:** react-hook-form + zod(`zodResolver`)
- **i18n:** react-i18next
- **Lint/Format:** Biome 단독(format + lint) 기본 / ESLint(flat config) + Prettier 대안 — 둘 중 하나만 쓴다(아래 "Lint/Format 선택"). 접근성 lint는 Biome `a11y` 그룹(`jsx-a11y` 대응, recommended 기본 활성) 또는 ESLint `eslint-plugin-jsx-a11y`
- **Test:** Vitest + @testing-library/react + happy-dom (단위·컴포넌트) / Playwright + `@axe-core/playwright` (E2E·접근성 자동검사)

### SSR Variant (Next.js)

- Next.js 16 App Router가 라우팅 SSOT — React Router는 사용하지 않는다.
- 데이터 패칭은 Server Component/Route Handler가 1차, 클라이언트 상호작용이 필요한 화면만 TanStack Query를 보조로 쓴다.
- Tailwind/shadcn/motion/zustand/react-hook-form+zod/Lint·Format/테스트 스택은 CSR과 동일하게 적용한다.
- 프로젝트가 CSR/SSR 중 하나로 결정되면, 반대쪽 코드 예시는 프로젝트 convention에서 제거한다 — 두 갈래를 동시에 bracket처럼 남기지 않는다.
- Next.js 16부터 `next lint`가 제거되고 `next build`가 lint를 돌리지 않는다 — 어느 lint 도구든 CI에 직접 넣는다. Biome이면 `linter.domains.next`를 켠다.

### Lint/Format 선택 (Biome / ESLint)

lint 도구는 하나만 둔다. 둘을 겹치면 같은 위반이 중복 보고되고 설정·포맷 규칙이 두 벌이 된다.

| | Biome 단독 (기본) | ESLint + Prettier (대안) |
|---|---|---|
| 구성 | 도구 1개·설정 1파일(`biome.json`)로 format·lint·import 정렬 | ESLint(lint) + Prettier(format) 2개, 플러그인별 의존성 |
| 스택 규칙 | `linter.domains`로 `react`·`next`·`tanstackQuery`·`test` 규칙, `a11y` 그룹 | `eslint-plugin-react-hooks`·`eslint-config-next`·`@tanstack/eslint-plugin-query`·`eslint-plugin-jsx-a11y` 공식 플러그인 |
| 타입 인식 규칙 | `types` 도메인(자체 추론, 일부 nursery) — 범위가 좁다 | typescript-eslint type-aware 규칙(`no-floating-promises`·`no-misused-promises` 등) |
| 속도 | 빠름 | 상대적으로 느림(type-aware 시 더) |

- **ESLint를 고르는 경우:** 기존 ESLint 설정·사내 공유 config가 있다 / 타입 인식 규칙을 CI 게이트로 쓴다 / Biome에 없는 플러그인·커스텀 규칙이 필요하다.
- **그 외 greenfield는 Biome.**
- Oxlint는 보조 linter로 두지 않는다 — 위 두 선택지 모두 단독으로 이 스택의 규칙을 커버해, 겹쳐 쓸 때의 중복 보고·설정 비용만 남는다.
- 선택 결과는 아래 Project Decisions에 적고, 고르지 않은 쪽 서술은 프로젝트 convention에서 지운다.

---

## Coding Style

### Naming

| 대상 | 규칙 | 예시 |
|------|------|------|
| 컴포넌트 파일 | PascalCase.tsx | `AppHeader.tsx`, `SafeModal.tsx` |
| 유틸/훅 파일 | camelCase.ts | `debug.util.ts`, `useBootSplash.ts` |
| store 파일 | camelCase + `.store.ts` | `cart.store.ts`, `auth.store.ts` |
| 상수 파일 | PascalCase.ts | `SchemaNames.ts`, `ItemStatus.ts` |
| 공유 타입 파일 | camelCase + `.types.ts` | `product.types.ts` |
| 타입 / 인터페이스 | PascalCase, `I`·`T` 접두어 금지 | `ProductDto`, `CartState` |
| Props 타입 | 컴포넌트명 + `Props` | `ProductActionBarProps` |
| 컴포넌트 | PascalCase | `export default AppHeader` |
| 커스텀 훅 | use + PascalCase | `useBootSplash`, `useInViewport` |
| Context 훅 | useXxxOrThrow | `useToolbarOrThrow()` |
| shadcn/ui 컴포넌트 | CLI 생성 그대로 `components/ui/` 하위 유지 | `components/ui/button.tsx` |
| Private 헬퍼 | # + prefix | `#requireBooleanOrThrow` |
| 상수 | UPPER_SNAKE_CASE | `ZINDEX.HEADER`, `ITEM_STATUS.CREATE` |
| 변수/함수 | camelCase | `showTimeText`, `loadConfig` |

- 이름은 **도메인 + 맥락 + 의도**를 담아 3단어 이상 권장. 제네릭 이름 회피.
- `components/ui/` 하위 shadcn/ui 생성 파일은 CLI가 관리하는 영역으로 간주하고 직접 리팩터링하지 않는다 — 커스터마이징은 `components/` 상위 래퍼에서 한다.

### Code Size

- **Functions:** ≤50 lines (target), **100 lines max** (hard limit).
- **Files:** ≤500 lines (target), **1000 lines max** (hard limit).

### Module Structure & Shared Placement

파일 묶음·하위 디렉터리·배치 단계·공개면·승격/강등의 판정 기준은 `.claude/rules/agent-principles.md`의 [Structure]와 DRY가 SSOT다. 이 절은 그 기준을 이 스택에 적용할 때의 고려사항만 적고, 실제 디렉터리·세그먼트·경로는 **Project Decisions의 구조 슬롯(S1~S8)**에 확정한다.

- **프레임워크 단위는 파일당 1개:** 컴포넌트·커스텀 훅은 파일당 공개 1개(default export 규칙 유지). 그 컴포넌트만 쓰는 하위 컴포넌트는 같은 파일에 export 없이 둔다.
- **그 밖의 코드는 세그먼트 파일로 묶는다:** 같은 데이터 소스·규칙·변경 이유를 공유하는 함수는 모듈의 세그먼트 파일 하나에 둔다(예: `product.api.ts`·`product.store.ts`·`product.schema.ts`). 함수마다 파일을 만들지 않는다. 세그먼트 표기와 목록은 S2.
- **SSR 실행 경계(SSR 프로젝트만):** `"use client"`·`"use server"`·`import "server-only"`는 파일 단위로 걸린다. 경계가 갈리면 같은 기능이라도 파일을 나눈다 — 단일 함수 파일을 허용하는 사유다.
- **barrel(`index.ts`):** re-export 파일은 tree-shaking·개발 서버 성능을 떨어뜨리고 순환 import의 통로가 되기 쉽다. 둘 위치는 S4에서 정하고, 모듈 안에서 자기 `index.ts`를 import하지 않는다. 순환 검출 규칙(Biome `noImportCycles` / ESLint `import/no-cycle`)은 S5에 적는다.
- **테스트·픽스처:** 테스트는 세그먼트 파일 단위로 colocated. 테스트 전용 픽스처·헬퍼는 운영 소스 디렉터리 밖(S8)에 두고 공개 API로 내보내지 않는다.

### Import Order

```typescript
// 1. React / 외부 라이브러리
import { useEffect, useMemo, useState } from "react";
import type { ReactNode } from "react";
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
- `Object.freeze()` 적용 (런타임 불변) + `as const` (리터럴 타입 보존)
- 도메인별 그룹화
- `enum` 대신 `as const` 객체 + 파생 유니온 타입을 쓴다 — `enum`은 런타임 코드를 생성하고 `erasableSyntaxOnly`·타입 제거 기반 트랜스파일러와 충돌한다

```typescript
export const ITEM_QUANTITY_RULE = Object.freeze({
    key: "itemQuantity",
    min: 0,
    max: 999,
    precision: 0,
    defaultValue: 1,
} as const);

export const ITEM_STATUS = Object.freeze({
    CREATE: "create",
    UPDATE: "update",
} as const);
export type ItemStatus = (typeof ITEM_STATUS)[keyof typeof ITEM_STATUS]; // "create" | "update"
```

### TypeScript

- `tsconfig`는 `strict: true`를 끄지 않는다. 신규 프로젝트는 `noUncheckedIndexedAccess`도 켠다(인덱스 접근 결과에 `undefined` 포함).
- **`any` 금지** — 형태를 모르는 외부 값은 `unknown`으로 받고 zod 파싱 또는 타입 가드로 좁힌다. 불가피한 `any`는 `// [WHY]` 주석과 함께 그 줄에만 둔다.
- **타입 단언(`as`)·non-null 단언(`!`)은 계약 경계 밖에서 쓰지 않는다** — 컴파일러를 침묵시킬 뿐 런타임 보장이 없다. 대신 `*OrThrow` 헬퍼나 zod 파싱으로 좁힌다. 예외: `as const`, 테스트 fixture.
- **API 응답은 신뢰 경계다** — 서버 응답 타입은 제네릭(`apiClient.get<ProductDto>`)만으로 보장되지 않는다. 형태가 틀리면 치명적인 응답(결제·권한 등)은 zod 스키마로 파싱하고 `z.infer`로 타입을 얻는다(스키마가 SSOT, 타입 중복 선언 금지).
- Props·state 형태는 `type`으로 선언한다. `interface`는 선언 병합·`extends` 확장이 실제로 필요할 때만 쓴다.
- 컴포넌트는 `React.FC` 대신 함수 시그니처에 Props 타입을 직접 붙인다. `children`은 `ReactNode`로 명시한다.
- 타입 전용 import는 `import type`으로 분리한다(`verbatimModuleSyntax` 대응).
- 함수 반환 타입은 추론에 맡기되, **공개 API(모듈 export되는 api/query/유틸 함수)는 반환 타입을 명시**해 계약을 고정한다.
- **타입체크는 빌드와 별개다** — Vite는 `.ts`를 트랜스파일만 하고 타입 검사를 하지 않는다. `tsc --noEmit`(또는 `tsc -b`)을 `build`·CI 게이트에 포함한다. Next.js는 `next build`가 타입체크를 수행한다.

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

```tsx
// Context 파일 (XxxContext.ts)
export type ToolbarContextValue = {
    items: ToolbarItem[];
    setActive: (id: string) => void;
};

export const ToolbarContext = createContext<ToolbarContextValue | null>(null);
export function useToolbarOrThrow(): ToolbarContextValue {
    const ctx = useContext(ToolbarContext);
    if (!ctx) throw new Error("useToolbar must be used within a ToolbarProvider");
    return ctx;
}

// Provider 파일 (XxxProvider.tsx)
export const ToolbarProvider = ({ children }: { children: ReactNode }) => {
    const value = useMemo<ToolbarContextValue>(() => ({ ... }), [deps]);
    return <ToolbarContext.Provider value={value}>{children}</ToolbarContext.Provider>;
};
export const useToolbar = () => useToolbarOrThrow();
```

- Context는 Auth/Theme처럼 provider 경계가 실제로 필요한 cross-cutting 값에만 사용한다. 화면/도메인 상태를 Context로 끌어올리지 않는다.
- `createContext<T | null>(null)` + `useXxxOrThrow()` 패턴 (Contract: missing provider → throw). `null` 체크가 타입을 `T`로 좁혀 주므로 사용부에 `!` 단언이 필요 없다.
- `useMemo`로 context value 감싸기 (불필요한 re-render 방지)

### Store (Zustand)

```typescript
// cart.store.ts
type CartState = {
    items: CartItem[];
    addItem: (item: CartItem) => void;
    removeItem: (id: string) => void;
};

export const useCartStore = create<CartState>()((set) => ({
    items: [],
    addItem: (item) => set((state) => ({ items: [...state.items, item] })),
    removeItem: (id) => set((state) => ({ items: state.items.filter((i) => i.id !== id) })),
}));
```

- TypeScript에서는 `create<T>()(...)` curried 형태로 쓴다(빈 괄호 `()` 필수 — middleware 타입 추론용).
- store는 도메인별로 분리한다 (`cart.store.ts`, `ui.store.ts`).
- selector 단위로 구독해 불필요한 re-render를 막는다: `useCartStore((state) => state.items)`.
- 서버에서 가져온 데이터를 store에 복제해 보관하지 않는다 — 서버 상태는 TanStack Query 캐시가 SSOT.

---

## UI and Styling

- Tailwind CSS v4 유틸리티 클래스가 기본 스타일링 수단이다. v4는 CSS-first 설정(`@theme` 디렉티브)이므로 `tailwind.config.js`에 디자인 토큰을 재정의하지 않는다 — 토큰 SSOT는 CSS의 `@theme` 블록.
- shadcn/ui 컴포넌트를 CLI로 생성해 `components/ui/`에 두고, `cva`(class-variance-authority)로 variant를 관리한다. Ant Design류 런타임 테마 토큰 API는 사용하지 않는다.
- 동적 클래스 조합은 `cn()`(clsx + tailwind-merge) 헬퍼로 처리하고, 인라인 스타일 객체는 Tailwind로 표현 불가능한 값(motion 애니메이션 중간값 등)에만 예외적으로 사용한다.
- z-index는 Tailwind 임의값 대신 `ZINDEX` 상수를 CSS 변수/`@theme` 토큰으로 노출해 사용한다 (SSOT: `constants/ZIndexHelper.ts`).

```tsx
import { cn } from "../../lib/cn";
import { Button } from "../../components/ui/button";

type ProductActionBarProps = {
    isPending: boolean;
    className?: string;
};

function ProductActionBar({ isPending, className }: ProductActionBarProps) {
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

```tsx
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

```typescript
type ProductInit = { name: string; sku: string; price: number };

export default class Product {
    readonly #name: string; // private field
    constructor({ name, sku, price }: ProductInit) {
        this.#name = Product.#validateText(name, "name");
        this.validate();
    }
    static #validateText(value: unknown, field: string): string { /* ... */ }
    static from(obj: unknown): Product { return new Product(parseProductInitOrThrow(obj)); }
    toJSON(): ProductInit { this.validate(); return { ... }; }
}
```

- ES class + `#private` fields (TS `private` 키워드는 컴파일 타임만 막으므로 런타임 은닉이 필요하면 `#`)
- `from()`의 입력은 `unknown`으로 받고 계약 경계에서 좁힌다 — 생성자 타입만 믿고 외부 값을 그대로 넘기지 않는다
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
- **Context API** — Auth/Theme/Notification처럼 provider 순서가 의미를 갖는 cross-cutting 값만. `App.tsx`가 Provider 순서 SSOT.
- **Provider 순서 = 의존관계 순서** → 변경 금지 (변경 시 하위 훅 undefined)

### Data Fetching (TanStack Query + axios)

- API 호출은 `src/api/` 아래 axios 인스턴스(`apiClient`) + 도메인별 모듈로만 수행 — 컴포넌트에서 직접 `fetch`/`axios` 호출 금지.
- 서버 상태는 TanStack Query의 `useQuery`/`useMutation`으로만 다루고, 그 결과를 Zustand store에 복제하지 않는다.
- 인증 토큰 갱신, 공통 에러 변환은 axios interceptor에서 처리한다.
- `import.meta.env` 키는 `src/vite-env.d.ts`의 `ImportMetaEnv`에 선언해 오타를 컴파일 타임에 잡는다.
- 응답 파싱 수준(전 응답 zod 파싱 / 치명 응답만 / 제네릭 타입만)은 프로젝트 결정이다 — 아래 Project Decisions에 기록한다.

```typescript
// src/api/apiClient.ts
export const apiClient = axios.create({ baseURL: import.meta.env.VITE_API_BASE_URL });
apiClient.interceptors.response.use(
    (response) => response,
    (error: AxiosError) => Promise.reject(new Error(`API error: ${error.response?.status}`)),
);

// src/api/productApi.ts
export async function fetchProduct(id: string): Promise<ProductDto> {
    const { data } = await apiClient.get<unknown>(`/products/${id}`);
    return productDtoSchema.parse(data); // 응답은 신뢰 경계 — 제네릭 단언 대신 파싱
}

// src/queries/useProductQuery.ts
export function useProductQuery(id: string) {
    return useQuery({ queryKey: ["product", id], queryFn: () => fetchProduct(id) });
}

// 사용부
const { data, status, error } = useProductQuery(id);
```

### Forms (react-hook-form + zod)

- 폼 상태는 `useForm` + `zodResolver`로 관리하고, 검증 스키마는 zod로 정의해 `*OrThrow` 계약과 동일하게 실패 시 명시적 에러 메시지를 노출한다.
- 폼 스키마는 컴포넌트 파일이 아닌 별도 모듈(`schemas/`)에 SSOT로 둔다.

```typescript
// schemas/productFormSchema.ts
export const productFormSchema = z.object({
    name: z.string().min(1, "name is required"),
    price: z.number().min(0),
});
export type ProductFormValues = z.infer<typeof productFormSchema>; // 폼 타입 SSOT = 스키마

// 사용부 — 제네릭 생략, resolver에서 입력/출력 타입을 추론
const form = useForm({ resolver: zodResolver(productFormSchema), defaultValues: { name: "", price: 0 } });
```

- `useForm<T>`에 단일 제네릭을 넘기지 않는다 — 스키마에 `.default()`·transform이 있으면 입력/출력 타입이 달라 `zodResolver`와 충돌한다. 생략해 추론시키거나 `useForm<z.input<typeof s>, unknown, z.output<typeof s>>`로 셋 다 명시한다.

### Routing

- CSR: React Router v7 Data Router 라우트 정의는 단일 파일(`src/routes.tsx`)에서 SSOT로 관리 — 화면 컴포넌트에 라우트 문자열 하드코딩 금지.
- SSR: Next.js App Router의 파일 기반 라우팅이 SSOT — `src/routes.tsx` 없이 `app/` 디렉토리 구조 자체가 라우트 정의다.
- 대형 페이지는 `lazy` + `Suspense`(CSR) 또는 Next.js의 자동 코드 스플리팅(SSR)으로 지연 로딩한다.
- 테스트/디버그 전용 라우트는 프로덕션 빌드에서 제외 (Pitfalls 참고)

```tsx
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

### 반복 입력 대응 (적용 대상일 때만)

먼저 `.claude/refs/interaction-integrity.md` **§1 적용 대상 판정**을 통과하는지 확인한다 — 통과하지 못하면 아래를 적용하지 않는다.
라우트 이동·모달 토글처럼 표시만 바꾸는 조작, I/O 없는 단발 조작은 대상이 아니다(단발 조작은 `disabled` 한 줄로 충분).

대상이면 §2 의미 분류에 따라 **필요한 것만** 적용한다.

| 조작 의미 | 적용 |
|---|---|
| 누적 (스테퍼·수량) | 이벤트 핸들러는 `useRef` 버퍼 또는 `setState(prev => …)` 함수형 갱신으로 다음 값을 계산한다. I/O만 debounce로 코얼레싱 |
| 최종값 (슬라이더·검색어) | state는 입력 즉시 반영하고, I/O는 debounce. 진행 중 요청은 `AbortController`로 취소하거나 요청 순번을 대조해 최신 응답만 반영 |
| 단발 (제출·결제) | 진행 중 플래그로 재진입 차단 + 서버 멱등성 키. 클라이언트 가드만으로는 부족하다 |

I/O를 코얼레싱하는 경우 공통으로 지킨다.

- 응답을 기다렸다 state를 반영하지 않는다 — 늦게 도착한 과거 응답이 더 새로운 입력을 덮어쓴다.
- 저장 실패 시 마지막 확정값으로 롤백하고 사용자에게 알린다(silent catch 금지 — Error Handling 절과 동일 규칙).
- 대기 중 unmount·라우트 이탈 시 `useEffect` cleanup에서 즉시 flush한다.

---

## Testing

- **Framework:** Vitest + @testing-library/react + happy-dom
- **위치:** 소스 파일과 같은 디렉토리 (colocated, `*.test.ts` / 컴포넌트는 `*.test.tsx`)
- **타입체크:** 테스트 실행(Vitest)은 타입 오류를 잡지 않는다 — 검증 단계에서 `tsc --noEmit`을 테스트와 별도로 돌린다
- **구조:** `describe(단위)` → `it(동작)` → `expect(결과)`
- Provider 의존 컴포넌트 테스트 시: 최소 mock, 실 Provider 우선
- shadcn/ui(Radix 기반) 컴포넌트 테스트 시 `ResizeObserver`/`matchMedia` 등 happy-dom 미구현 API를 test setup에서 mock 처리 (Pitfalls 참고)
- TanStack Query 사용 컴포넌트는 테스트마다 새 `QueryClient`를 주입해 캐시 격리
- **접근성 자동검사:** axe는 실제 브라우저(Playwright)에서만 돌린다 — 주요 라우트마다 `new AxeBuilder({ page }).withTags([...]).analyze()`의 `violations`가 0건임을 단언한다. 태그는 TRD §2.1 접근성 보장의 WCAG 수준을 따른다(예: 2.1 AA → `wcag2a`·`wcag2aa`·`wcag21a`·`wcag21aa`). 모달·드롭다운처럼 열린 상태가 따로 있는 UI는 그 상태로 만든 뒤 스캔한다
- axe 자동검사는 일부 기준만 잡는다 — 키보드 조작·포커스 순서·스크린리더 낭독은 코드리뷰 체크리스트와 UI 셀프체크로 보완한다

---

## Security & Reliability

### Error Handling

| 상황 | 처리 |
|------|------|
| Contract boundary | `*OrThrow` → `throw Error` with context message |
| HTTP (axios) | interceptor에서 공통 변환 → 호출자(TanStack Query)에서 catch/handle |
| I/O (DB, 파일) | try-catch + `console.error` + rethrow or explicit handle |
| Provider 초기화 | catch + `console.error` + rethrow |

**금지:**
- silent catch (빈 catch 블록)
- implicit fallback (에러 삼키고 기본값 반환)
- `typeof` 가드로 조용히 넘기기

→ `*OrThrow` 사용

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
- 업로드 파일(SVG·HTML 포함)은 앱 origin에서 인라인 렌더 금지, LLM 응답은 사용자 입력과 같은 등급으로 sanitize·스킴 검증
- 분석·세션 리플레이·에러 트래킹 payload에 PII 미포함
- 심화 기준·탐지 시그널: `.claude/refs/web-security.md`

---

## 구조 패턴 일괄 치환 (ast-grep)

동일 AST 패턴이 **N건** 있고 그걸 한 번에 바꿔야 할 때만 쓴다. 단건 심볼 편집은 Serena,
경로를 이미 아는 단순 확인은 내장 Read/Grep이 싸다. 이 스택의 언어 id: `tsx`(TS+JSX) · `ts` · `jsx`/`js`.

**기본은 애드혹 — 설정 파일이 필요 없다.**

```bash
# 조회
ast-grep run -p '<Menu $$$PROPS>$$$CHILDREN</Menu>' --lang tsx src/
# (deprecated 컴포넌트 API를 쓰는 지점 전수 조회)

# 치환 (-r 추가, --dry-run 으로 먼저 확인)
ast-grep run -p '<pattern>' -r '<rewrite>' --lang <lang> --dry-run <경로>
```

**영속 규칙(`sgconfig.yml` + `ruleDirs`)은 지금 넣을 규칙이 있을 때만 만든다.**
설정만 만들고 규칙을 비워두면 `ast-grep scan`이 영원히 0줄을 출력하며 아무도 이상을 눈치채지
못한다 — 설정 없는 상태보다 나쁘다.

만들 때는:

1. `ast-grep new project -y` — `sgconfig.yml` + `rules/` + `rule-tests/` + `utils/`를 만든다.
2. **`sgconfig.yml`의 절대경로를 상대경로로 반드시 교정한다** — 스캐폴드가 절대경로를 박아서
   팀 공유·CI에서 깨진다. `ruleDirs`·`utilDirs`는 경로 나열이지만 `testConfigs`는
   `- testDir: <경로>` **구조체**라 형식이 다르다:
   ```yaml
   ruleDirs:
     - rules
   testConfigs:
     - testDir: rule-tests
   utilDirs:
     - utils
   ```
3. `ast-grep new rule <id> -l <lang> -y`로 규칙과 테스트를 함께 만들고, `rule-tests/<id>-test.yml`의
   `valid:`/`invalid:` 인라인 샘플을 채운다.
4. **`ast-grep test`가 PASS하는 것을 스캐폴드 완료 판정으로 삼는다.**

4번이 중요하다 — `ast-grep test`는 **프로젝트 소스가 0개여도** 규칙의 정확성을 판정한다
(인라인 샘플로 검증하므로). 반대로 `ast-grep scan`은 소스가 없거나 패턴이 틀려도 똑같이 0줄을
출력해 둘을 구분할 수 없다. 규칙을 넣었는데 `scan`이 0건이면 **규칙이 죽었는지 우리 코드가
깨끗한지를 `test`로 먼저 가른다.**

monorepo면 저장소 루트가 아니라 실제 소스 패키지 루트에 두고, `ast-grep scan`·`test`도
**`sgconfig.yml`이 있는 그 디렉토리에서** 실행한다.

### 어떤 규칙을 쓸 수 있나

| 종류 | 필요한 전제 | 언제 쓸 수 있나 |
|------|------------|----------------|
| **스택 일반** — 프레임워크·라이브러리 deprecated API | 스택·버전 사실만 | 소스가 없어도 작성 가능 |
| **프로젝트 고유** — 자체 SSOT·컨벤션 위반 검출 | 그 SSOT가 실재하고 합의돼야 함 | 코드가 쌓인 뒤 |

프로젝트 고유 규칙을 SSOT가 확정되기 전에 넣으면 규칙이 곧 거짓이 된다 — 순서를 지킨다.

### 함정 (실측 확인)

| 증상 | 원인 | 대응 |
|------|------|------|
| 패턴이 조용히 0건 | `키: $V` 형태는 오브젝트 속성이 아니라 `labeled_statement`로 파싱된다 | `--debug-query=pattern`으로 파싱 형태를 먼저 확인하고, 속성 매칭은 `pattern.context` + `selector: pair`로 쓴다 |
| `scan`이 전부 안 돌고 에러 | 규칙 YAML **1개**만 깨져도 스캔 전체가 중단된다 | `context` 등 `:`가 들어가는 값은 **큰따옴표로 감싼다** |
| `.md` 같은 비코드 파일이 매치 | `--lang` 미지정 | `--lang`을 항상 명시한다 |
| CI에서 통과해버림 | `scan`은 `severity: error` 항목이 있을 때만 exit 1 | 게이트로 쓸 규칙은 `severity: error`로 둔다 |

`node_modules`·`dist`·빌드 산출물은 gitignore를 따라 자동 제외되므로 별도 ignore 설정은 불필요하다.

---

## Comment Rules

- **한국어** 사용, 자명한 코드에는 금지, 타겟 독자는 5년차 미드레벨 엔지니어
- 아래 3종은 독립 판단 — 한 대상이 여러 개 해당하면 나란히 작성(순서 무관)

### 프로젝트 기본 주석

- 재사용되는 공개 API로 파라미터·반환값 의미가 이름만으로 드러나지 않을 때
- 사이드이펙트가 있는 훅/유틸 (구독·타이머·이벤트 리스너 등록 등)
- 특정 조합·범위만 허용되는 상수/설정 객체
- Description은 필수, `@param`/`@returns`/`@throws`는 의미가 자명하지 않을 때만 추가
- TSDoc 문법을 쓴다 — 타입은 시그니처가 SSOT이므로 `@param {number}`처럼 주석에 타입을 다시 적지 않는다(중복은 drift가 된다)

```typescript
/**
 * 재고 수량이 재주문 임계값 이하인지 판단한다.
 * @param remainingQty - 현재 재고 수량
 * @param thresholdQty - 재주문 트리거 임계값
 * @returns 임계값 이하면 true
 * @throws remainingQty가 음수일 때
 */
function shouldReorderStock(remainingQty: number, thresholdQty: number): boolean {
    if (remainingQty < 0) throw new Error("remainingQty는 음수일 수 없습니다");
    return remainingQty <= thresholdQty;
}
```

### Rationale Comment

자명한 코드에는 주석을 달지 않는다. 이름만으로 의도가 드러나면 주석 대신 네이밍으로 해결한다.
**"왜"가 코드 문법만으로는 전혀 드러나지 않을 때만** 추가하며, 모든 변수·함수에 기계적으로 붙이지 않는다.

- **Workaround/Hack** — 외부 라이브러리·특정 브라우저·레거시 시스템의 버그·특이 동작 우회
- **Business Rule** — 코드만으로 유추 불가능한 도메인 규칙(오프라인 정책, 비직관적 제품 스펙 등)
- **Non-obvious Trade-off** — 가독성보다 성능·보안을 택한 경우 (비트 연산, 복잡한 정규식, 캐싱 레이어 등)
- `[WHY]`(필수)/`[CONTEXT]`/`[TRADE-OFF]` 태그로 1~2줄만, 무거운 템플릿 금지

```typescript
// [WHY] 외부 결제 SDK가 iOS Safari에서 blur 이벤트를 중복 발생시키는 버그 우회
// [CONTEXT] 오프라인 매장은 재고 음수를 허용하는 정책(온라인과 다른 룰)
// [TRADE-OFF] O(1) 조회를 위해 메모리 캐시 사용, 최대 10MB 제한
```

### Provider Header

- 적용 대상: Context/Provider 파일(`XxxContext.ts`/`XxxProvider.tsx`), Zustand store 파일(`*.store.ts`) 최상단, 항상 붙인다
- `Domain` — 이 컨텍스트/store가 담당하는 책임 경계 (SSOT 여부 등). 코드만으로는 알 수 없는
  아키텍처 정보가 있으면 그것을 적고, 없으면 책임 범위를 한 줄로 요약한다 (필수)
- `Contract` — Provider 배치 순서 등 코드로 드러나지 않는 전제조건 (선택)

```typescript
// Domain: Toolbar context SSOT boundary
// Contract: AuthProvider보다 하위에 위치해야 함 — 로그인 상태로 노출 항목을 계산하므로 순서가 바뀌면 툴바가 항상 비어 보임
export const ToolbarContext = createContext<ToolbarContextValue | null>(null);
export function useToolbarOrThrow(): ToolbarContextValue {
    const ctx = useContext(ToolbarContext);
    if (!ctx) throw new Error("useToolbar must be used within a ToolbarProvider");
    return ctx;
}
```

---

## Pitfalls

| 실수 | 결과 | 방지 |
|------|------|------|
| Provider 순서 변경 | 하위 훅 undefined | `App.tsx` 순서 = 의존관계 SSOT |
| Vite `build`만 통과하면 타입도 맞다고 간주 | Vite는 타입 검사 없이 트랜스파일만 해 타입 오류가 배포됨 | `tsc --noEmit`을 `build` 스크립트·CI 게이트에 포함 |
| `apiClient.get<Dto>()` 제네릭을 런타임 보장으로 오해 | 서버 응답 형태가 바뀌어도 컴파일은 통과, 런타임에 `undefined` 접근 | 치명 응답은 zod로 파싱, 타입은 `z.infer`로 얻음 |
| `as`·`!`로 타입 오류 침묵 | 컴파일러가 잡던 버그가 런타임으로 이동 | `*OrThrow`·타입 가드·zod로 좁힘 |
| `useForm<T>` 단일 제네릭 + `.default()` 스키마 | `zodResolver` 입력/출력 타입 충돌 | 제네릭 생략 또는 input/context/output 3개 명시 |
| 파생 가능한 값을 state로 중복 보관 | 동기화 drift, stale UI | 계산으로 유지하거나 `useMemo` 사용 |
| 서버 응답을 Zustand store에 그대로 복제 | TanStack Query 캐시와 store가 따로 놀아 stale drift | 서버 상태는 TanStack Query만 SSOT로 사용 |
| shadcn/ui(Radix) 컴포넌트를 happy-dom에서 그대로 테스트 | `ResizeObserver is not defined` 등으로 실패 | test setup에서 `ResizeObserver`/`matchMedia` mock 등록 |
| Vitest(happy-dom)에서 axe-core 실행 | `TypeError: Cannot set property isConnected ... which has only a getter`로 실패(happy-dom#978 미해결). jsdom으로 바꿔도 레이아웃이 없어 `color-contrast`는 판정 불가 | axe는 Playwright(실제 브라우저)에서만 실행 |
| 기존 코드베이스에 axe 게이트를 처음부터 "위반 0건"으로 켬 | 누적 위반이 한꺼번에 터져 CI가 막히고 결국 게이트를 끄게 됨 | 기존 위반은 화면별 기준선(허용 rule id 목록)으로 고정하고 신규 위반만 실패 처리, 손대는 화면부터 기준선을 줄인다 |
| Biome과 ESLint(또는 Oxlint)를 함께 켬 | 같은 위반 중복 보고, 포맷 규칙 충돌로 저장할 때마다 diff 발생 | lint/format 도구는 Project Decisions에서 고른 하나만 설치·실행 |
| Tailwind v4 토큰을 `tailwind.config.js`와 `@theme` 양쪽에 중복 정의 | 토큰 drift | v4는 `@theme` CSS 블록이 SSOT, config 파일에 재정의 금지 |
| 테스트 전용 라우트를 프로덕션 빌드에 노출 | 예기치 못한 진입점 노출 | 라우트 가드 또는 빌드 분기로 제외 |
| Contract 위반 시 `typeof` 가드로 조용히 처리 | 에러 은폐 | `*OrThrow` 헬퍼 사용 |
| 반복 트리거 조작에서 입력마다 즉시 저장/요청 | 저사양 기기에서 I/O 큐 적체 → 터치 반응 지연 | state는 즉시 반영, I/O는 debounce로 코얼레싱 |
| 이벤트 핸들러가 클로저에 캡처된 state로 다음 값 계산 | 이벤트가 한 배치로 몰릴 때 갱신 유실(N번 눌러도 1번 반영) | 이벤트 경로는 `useRef` 버퍼 또는 함수형 갱신에서 읽는다. **ref는 "이벤트 경로의 누적 원천", state는 그 파생 렌더값 — 단방향(ref → state)일 때만 허용한다. 양방향으로 동기화하면 위의 "파생 가능한 값을 state로 중복 보관"에 해당한다** |

---

## Project Decisions

아래는 preset 주입 후 반드시 프로젝트 실정에 맞게 채운다.

- **Rendering Mode:** [CSR(Vite) / SSR(Next.js) 중 택1 — 결정 후 반대쪽 예시 코드 제거]
- **Lint/Format:** [Biome 단독 / ESLint + Prettier 중 택1 — 고른 이유("Lint/Format 선택" 기준) 한 줄]
- **State SSOT:** [예: Zustand store는 `src/store/`, Context Provider 순서는 `src/App.tsx` 순서를 따름]
- **API Layer SSOT:** [예: `src/api/`, axios 인스턴스는 `src/api/apiClient.ts`]
- **API 응답 검증 수준:** [예: 결제·권한 응답만 zod 파싱, 나머지는 DTO 타입만]
- **tsconfig 추가 엄격도:** [예: `strict` + `noUncheckedIndexedAccess` / `exactOptionalPropertyTypes` 여부]
- **Design System SSOT:** [예: `components/ui/`(shadcn/ui) + `@theme` 토큰]
- **접근성 기준·게이트:** [예: WCAG 2.1 AA — 신규 화면은 axe 위반 0건 / 기존 화면은 기준선 고정 후 신규 위반만 실패. TRD §2.1 접근성 보장과 일치시킨다]
- **Routing SSOT:** [예: `src/routes.tsx`(CSR) 또는 `app/`(SSR)]
- **Sensitive Files:** [예: `.env*`, `*.pem`]

**구조 슬롯 (S1~S8)** — 판정 기준은 `.claude/rules/agent-principles.md` [Structure]·DRY. setup에서 코드베이스 실측(기존 프로젝트)이나 아래 예시(신규 프로젝트)로 제안·확인해 채운다. 정하지 못한 슬롯은 `미확정`으로 두면 에이전트는 기준만 적용하고 구조를 지어내지 않는다.

- **S1 Directory Policy:** [분할 방식(feature-first / layer-first / route-first / 혼합) + 최상위 디렉터리 맵. 예: `src/app/`(라우트) · `src/features/<domain>/` · `src/shared/`]
- **S2 Module Segment:** [역할 표기(파일 접미사 / 하위 디렉터리 / 이름만) + 세그먼트 목록 + 하위 디렉터리 임계. 예: `<domain>.api.ts`·`<domain>.store.ts`·`<domain>.schema.ts`·`<Name>.tsx`, 모듈 파일이 8개를 넘으면 하위 디렉터리]
- **S3 Shared Placement:** [배치 단계별 실제 경로 — 이 순서가 기존 자산 탐색 순서. 예: 모듈 `src/features/<domain>/` → 앱 범용 `src/shared/ui`·`src/shared/lib` → 앱 도메인 `src/entities/<domain>/` → 워크스페이스 `packages/shared`(멀티 패키지일 때만)]
- **S4 Public API:** [모듈 공개면 + 강제 수단. 예: 패키지 루트 `index.ts`만 / 모듈별 `index.ts` / barrel 없이 파일 직접 import. 강제 예: Biome `performance.noBarrelFile`·`performance.noReExportAll`을 켜고 허용할 공개면 경로만 `overrides`로 끈다]
- **S5 Dependency Direction:** [허용 방향 + 강제 도구. 예: shared → features → app, features 간 import 금지, Biome `noImportCycles` 활성화]
- **S6 Promotion:** [`기본`(agent-principles DRY) 또는 다르게 정한 기준과 이유]
- **S7 Shared Catalog:** [공용 자산을 찾는 장치. 예: Storybook / 개발용 컴포넌트 확인 화면 / 없음]
- **S8 Test-only Code:** [테스트 전용 픽스처·헬퍼 위치. 예: `src/test/`]
