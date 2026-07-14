# Project Convention — React Native Preset

이 문서는 **React Native 프로젝트용 preset**입니다. bracket 선택형 메뉴가 아니라, 한 가지로 결정된 예시 스택과 실제 코드/테이블로 구성되어 있습니다.
최초 주입 후에는 아래 예시 스택·코드를 프로젝트의 실제 선택으로 즉시 교체하세요.

---

## Stack

- **Runtime:** Expo SDK 55 (managed workflow), React Native 0.83, React 19.2
- **Architecture:** New Architecture 고정 — SDK 55부터 Legacy Architecture 옵트아웃 자체가 제거됨 (`newArchEnabled` 플래그 없음)
- **Bundler:** Metro (Expo 번들, 별도 버전 선택 불필요)
- **Language:** TypeScript
- **Navigation:** Expo Router v6 (내부적으로 React Navigation 기반, file-based routing)
- **State:** Zustand v5 (persist가 필요하면 MMKV 기반 storage adapter 사용, `AsyncStorage` 직접 사용 지양)
- **Server State / Data Fetching:** TanStack Query v5
- **Styling:** NativeWind v4 (Tailwind CSS v3.4 문법 기반) + 공용 디자인 토큰
- **Animation:** Reanimated v4 + `react-native-worklets` (New Architecture 필수 — SDK 55 기준 항상 충족)
- **Lint/Format:** Biome (format + 기본 lint) + Oxlint(+`oxlint-config-universe`) — 단, Biome은 아직 React Native 전용 lint 규칙 플러그인이 없으므로, 필요하면 ESLint로 대체할지 사용자 확인 필요
- **Test:** Jest + React Native Testing Library

---

## Coding Style

### Naming

| 대상 | 규칙 | 예시 |
|------|------|------|
| 화면 파일 | PascalCase + `Screen` suffix | `ProductListScreen.tsx` |
| 컴포넌트 파일 | PascalCase.tsx | `ItemCard.tsx`, `SafeModal.tsx` |
| 훅 파일 | camelCase.ts, `useXxx` | `useAppStateOrThrow.ts` |
| store 파일 | camelCase + `.store.ts` | `cart.store.ts` |
| query 파일 | camelCase + `.query.ts` | `product.query.ts` |
| 유틸 파일 | camelCase.ts | `debug.util.ts` |
| 플랫폼 전용 파일 | RN 표준 suffix | `Header.ios.tsx`, `Header.android.tsx` |
| 상수 | UPPER_SNAKE_CASE | `ZINDEX.HEADER`, `ITEM_STATUS.CREATE` |
| Private 헬퍼 | # + prefix (class 내부) | `#requireBooleanOrThrow` |

### Code Size

- **Functions:** ≤50 lines (target), **100 lines max** (hard limit).
- **Files:** ≤500 lines (target), **1000 lines max** (hard limit).

### Import Order

```typescript
// 1. React / React Native / 외부 라이브러리
import { useEffect, useMemo, useState } from "react";
import { View, Text } from "react-native";
import { useRouter } from "expo-router";

// 2. 유틸 / 상수
import { createDebugger } from "../../common/debug.util";
import { ZINDEX } from "../../constants/ZIndexHelper";

// 3. 스토어 / 쿼리 / 모델
import { useCartStore } from "../../store/cart.store";
import { useProductQuery } from "../../query/product.query";
import Item from "../../model/Item";

// 4. 컴포넌트 / 스타일
import ItemCard from "./components/ItemCard";
```

### Constants

```typescript
export const ITEM_QUANTITY_RULE = Object.freeze({
    key: "itemQuantity",
    min: 0,
    max: 999,
    precision: 0,
    defaultValue: 1,
});
```

- 매직 넘버/문자열 금지 → named constant 추출, 파일 상단에 `Object.freeze()`로 선언

---

## Core Rules

- Functional component와 hook 중심으로 구현한다.
- `Platform.OS` 분기와 `.ios.*`/`.android.*` 파일 분리는 꼭 필요한 경우에만 사용하고, 분기 이유를 Rationale Comment로 남긴다.
- 네이티브 모듈/권한/딥링크/foreground-background 전환처럼 플랫폼 경계가 있는 로직은 화면 코드와 분리한다.
- Bridge 호출 실패는 silent ignore 하지 않고 사용자 영향 범위를 명시적으로 처리한다.
- 서버 상태(TanStack Query)와 로컬 UI 상태(Zustand)를 섞지 않는다 — 서버 응답을 store에 복제 저장하지 않는다.

---

## Component Pattern

### Navigation (Expo Router)

- 라우트는 `app/` 디렉토리 구조 자체가 SSOT — 별도 라우트 정의 파일을 두지 않는다.
- 화면 간 이동은 `useRouter()`/`<Link>`를 사용하고, 문자열 경로를 컴포넌트 곳곳에 하드코딩하지 않고 라우트 상수 모듈로 모은다.

### Store (Zustand)

```typescript
// cart.store.ts
export const useCartStore = create<CartState>((set, get) => ({
    items: [],
    addItem: (item) => set((state) => ({ items: [...state.items, item] })),
    removeItem: (id) => set((state) => ({ items: state.items.filter((i) => i.id !== id) })),
}));
```

- store는 도메인별로 분리한다 (`cart.store.ts`, `auth.store.ts`).
- selector 단위로 구독해 불필요한 re-render를 막는다.
- persist가 필요한 store는 `zustand/middleware`의 `persist` + MMKV 기반 `StateStorage` adapter를 사용한다 (`AsyncStorage`는 비동기·저성능이라 지양).
- 앱 전역 환경값(테마, locale 등)처럼 provider 경계가 필요한 것만 Context로 두고, 나머지는 store로 관리한다.

---

## UI & UX

- NativeWind `className`으로 spacing/color/typography를 표현하고, 디자인 토큰은 Tailwind 설정(v3.4 문법)에 둔다 — 하드코딩 금지.
- Reanimated `useAnimatedStyle`이 반환하는 애니메이션 스타일은 NativeWind `className`과 직접 병합할 수 없다 — 정적/조건부 스타일은 NativeWind, 애니메이션 값은 `style` prop으로 분리한다 (Pitfalls 참고).
- 터치 영역, safe area (`SafeAreaView`/`useSafeAreaInsets`), keyboard avoidance, loading/error/empty state 처리를 기본 고려사항으로 둔다.
- 기기 크기·platform별 미세 차이는 토큰/유틸/컴포넌트 추상화로 흡수한다.
- animation은 사용자 경험상 필요한 경우에만 Reanimated로 넣고, 성능 비용이 큰 레이아웃 thrash를 피한다.

---

## Design Pattern

### Model Class / Value Object

```typescript
export default class Item {
    #name: string;
    constructor({ name, sku, price }: ItemInput) {
        this.name = Item.#validateText(name, "name");
        this.validate();
    }
    static #validateText(value: string, field: string): string { /* ... */ }
    static from(payload: unknown): Item { return new Item(payload as ItemInput); }
    toJSON(): ItemPayload { this.validate(); return { ... }; }
}
```

- API payload, local storage snapshot, native bridge payload처럼 검증 경계가 있으면 model class/value object를 둔다.
- `from()` factory + `validate()` invariant check + `toJSON()` serializer 패턴을 기본으로 한다.
- 단순 화면 전용 UI state까지 class로 만들 필요는 없다.

### `*OrThrow` Contract Pattern

- permission result, deeplink param, storage decode, native bridge result는 `require*OrThrow` / `assert*OrThrow`류 검증으로 Fail Fast 처리한다.
- 잘못된 payload를 조용히 무시하지 않는다.
- correctness-critical flow(결제, 인증)와 degraded flow(추천, 배너)를 분리한다.

---

## State, Data Flow, Device Integration

### Data Fetching (TanStack Query)

- 서버 상태는 TanStack Query의 `useQuery`/`useMutation`으로만 다루고, `query/` 아래 도메인별 모듈로 분리한다.
- 웹과 달리 RN에는 `window` focus/online 이벤트가 없다 — `focusManager`는 `AppState`, `onlineManager`는 `@react-native-community/netinfo`(또는 `expo-network`)로 수동 연결해야 자동 refetch가 동작한다.

```typescript
// query/queryClientSetup.ts
focusManager.setEventListener((handleFocus) => {
    const subscription = AppState.addEventListener("change", (state) => handleFocus(state === "active"));
    return () => subscription.remove();
});
onlineManager.setEventListener((setOnline) =>
    NetInfo.addEventListener((state) => setOnline(!!state.isConnected)),
);
```

### State / Device Integration

- 앱 lifecycle(`AppState`), network reachability, permission status, deep link state는 명시적으로 관리한다.
- 네이티브 API 사용 시 iOS/Android 계약 차이를 문서화한다.
- background task, push notification, storage sync는 실패 범위를 core flow와 분리한다.

---

## Performance

- `FlatList`/`SectionList` 사용 시 `keyExtractor`, `renderItem` 안정성, memoization 필요 여부를 점검한다.
- 큰 이미지는 lazy loading / caching 전략을 검토한다.
- 불필요한 re-render를 피하도록 store selector, `useCallback`, `useMemo` 분리를 검토한다.
- JS thread를 막는 무거운 연산은 분리하거나 배치 처리한다.
- Reanimated 애니메이션은 worklet(UI thread) 안에서 실행되도록 작성하고, JS thread로 값을 넘길 때만 `runOnJS`를 사용한다.

---

## Testing

- **Framework:** Jest + React Native Testing Library
- **위치:** 소스 파일과 같은 디렉토리 (colocated, `*.test.tsx`)
- **구조:** `describe(단위)` → `it(동작)` → `expect(결과)`
- hook, store, permission flow, navigation guard, offline/online 전환 같은 모바일 특화 시나리오를 포함한다.
- TanStack Query 사용 컴포넌트는 테스트마다 새 `QueryClient`를 주입해 캐시 격리
- 네이티브 모듈 mock은 최소화하되, 플랫폼 경계 contract는 테스트로 드러낸다.
- 실제 기기/시뮬레이터 검증이 필요한 항목은 PR 설명에 명시한다.

---

## Security & Reliability

- token, secure storage(`expo-secure-store`/Keychain), deep link, webview boundary를 우선 점검한다.
- 권한 요청은 필요한 시점에만 수행하고, 거부 시 fallback UI를 명시한다.
- 민감 데이터는 `AsyncStorage`/평문 MMKV 같은 비보안 저장소에 임의 저장하지 않는다.
- crash를 삼키지 말고, 사용자 영향/재시도 정책을 분리한다.

---

## Comment Rules

### 프로젝트 기본 주석
- 재사용 hook/store/util, side effect helper, 제한된 config 객체만 주석을 단다.
- Description 1줄 + 필요한 경우 `@param`, `@returns`, `@throws`를 사용한다.
- 자명한 component render code에는 주석을 남발하지 않는다.

```typescript
/**
 * 재고 수량이 재주문 임계값 이하인지 판단한다.
 * @param remainingQty - 현재 재고 수량
 * @param thresholdQty - 재주문 트리거 임계값
 * @throws {Error} remainingQty가 음수일 때
 */
function shouldReorderStock(remainingQty: number, thresholdQty: number): boolean {
    if (remainingQty < 0) throw new Error("remainingQty는 음수일 수 없습니다");
    return remainingQty <= thresholdQty;
}
```

### Rationale Comment
- 플랫폼 분기, native workaround, device-specific business rule에만 남긴다.

```typescript
// [WHY] Android 13 이하에서 알림 권한 요청 시점이 다르므로 OS 버전별 분기 필요
// [CONTEXT] iOS는 최초 실행 시, Android 13+는 알림 발생 시점에 요청하는 정책
```

### Provider Header
- Context/Provider, store provider, environment provider 파일에는 boundary header를 둔다.

```typescript
// Domain: Cart store SSOT boundary
// Contract: AuthProvider보다 하위에 위치해야 함 — 로그인 상태로 항목을 필터링하므로 순서가 바뀌면 장바구니가 항상 비어 보임
export const useCartStore = create<CartState>(...);
```

---

## Pitfalls

| 실수 | 결과 | 방지 |
|------|------|------|
| 플랫폼 분기를 화면 곳곳에 흩뿌림 | 유지보수 악화 | bridge/service 경계로 격리 |
| permission/deeplink payload를 느슨하게 처리 | 재현 어려운 런타임 오류 | `*OrThrow` 검증 |
| `AsyncStorage`에 민감 데이터 저장 | 보안 취약점 | secure storage SSOT 준수 |
| Zustand store에 서버 응답을 그대로 복제 저장 | TanStack Query 캐시와 이중 관리, drift | 서버 상태는 TanStack Query만 SSOT |
| Reanimated `useAnimatedStyle` 결과를 NativeWind `className`과 병합 시도 | 스타일 미적용/워크릿 오류 | 애니메이션 값은 `style` prop, 정적 스타일은 `className`으로 분리 |
| TanStack Query에서 RN의 focus/online 이벤트 미연결 | 앱 포그라운드 복귀 시 자동 refetch 안 됨 | `focusManager`/`onlineManager`를 `AppState`/`NetInfo`로 수동 연결 |
| `FlatList` 최적화 미흡 | 스크롤 성능 저하 | `keyExtractor`/memoization/render 분리 |
| store/provider 순서 문서화 누락 | 특정 상태가 항상 비정상 | Provider Header + active convention 명시 |

---

## Project Decisions

아래는 preset 주입 후 반드시 프로젝트 실정에 맞게 채운다.

- **Navigation SSOT:** [예: `app/` (Expo Router file-based routing)]
- **State SSOT:** [예: `src/store/`]
- **Data Fetching SSOT:** [예: `src/query/`]
- **Native Modules:** [예: `android/app/...`, `ios/...`]
- **Design Guideline SSOT:** [예: `docs/DESIGN.md`, NativeWind 토큰 설정]
- **Sensitive Files:** [예: `.env*`, `GoogleService-Info.plist`, `google-services.json`]
