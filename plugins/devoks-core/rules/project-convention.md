# Project Convention

이 문서에서는 코딩 스타일, 네이밍 규칙, 파일 구조 등 프로젝트의 일관된 conventions를 정리합니다.

---

## Coding Style

**Language:** JavaScript + JSDoc (TypeScript 미사용)

### Naming

| 대상 | 규칙 | 예시 |
|------|------|------|
| 컴포넌트 파일 | PascalCase.jsx | `AppHeader.jsx`, `SafeModal.jsx` |
| 유틸/훅 파일 | camelCase.js | `debug.util.js`, `useBootSplash.js` |
| 상수 파일 | PascalCase.js | `SchemaNames.js`, `BeanStatus.js` |
| 컴포넌트 | PascalCase | `export default AppHeader` |
| 커스텀 훅 | use + PascalCase | `useBootSplash`, `useInViewport` |
| Context 훅 | useXxxOrThrow | `useToolbarOrThrow()` |
| Private 헬퍼 | # + prefix | `#requireBooleanOrThrow` |
| 상수 | UPPER_SNAKE_CASE | `ZINDEX.HEADER`, `BEAN_STATUS.CREATE` |
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
import MenuBrew from "./components/MenuBrew";
import styles from "./brewing.style";
```

### Constants

- 매직 넘버/문자열 금지 → named constant 추출
- 파일 상단 (import 직후, 함수 전)
- `Object.freeze()` 적용
- 도메인별 그룹화

```javascript
export const BEAN_AMOUNT_RULE = Object.freeze({
    key: "beanAmount",
    min: 0.0,
    max: 20.0,
    precision: 1,
    defaultValue: 18.0,
});
```

---

## React

- **Functional 컴포넌트만** 사용 (class 컴포넌트 금지)
- **default export** (컴포넌트)
- Props는 함수 시그니처에서 **destructuring**
- Hooks: `useXxx` prefix, 커스텀 훅은 `hooks/` 디렉토리

```javascript
const AppHeader = ({ toggleDrawer }) => {
    const { token } = theme.useToken();
    // ...
};
export default AppHeader;
```

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

## State Management

- **Context API + Provider chain** — App.jsx가 Provider 순서 SSOT
- **Provider 순서 = 의존관계 순서** → 변경 금지 (변경 시 하위 훅 undefined)
- 도메인별 Provider 분리 (Auth, Mqtt, Monitoring, Document, Udp 등)
- Provider에서 `useMemo`로 value 감싸기

---

## Design Pattern

### Model Class

```javascript
export default class Bean {
    #name; // private field
    constructor({ name, version, brandName } = {}) {
        this.name = Bean.#validateText(name, "name");
        this.validate();
    }
    static #validateText(value, field) { /* ... */ }
    static from(obj) { return new Bean(obj); }
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

### Source Header

- 파일 첫 줄에 `// path/filename.js` 형태의 소스 헤더 권장

---

## Error Handling

| 상황 | 처리 |
|------|------|
| Contract boundary | `*OrThrow` → `throw Error` with context message |
| HTTP (ApiController) | `fetchWithAuth` 에러 → 호출자에서 catch/handle |
| I/O (DB, 파일) | try-catch + `console.error` + rethrow or explicit handle |
| Provider 초기화 | catch + `console.error` + rethrow |

**금지:**
- silent catch (빈 catch 블록)
- implicit fallback (에러 삼키고 기본값 반환)
- `typeof` 가드로 조용히 넘기기 → `*OrThrow` 사용

---

## Comment Rules

- **한국어** 사용: 도메인 규칙, 계약 이유, throw 사유, 사이드이펙트, 성능 이슈
- 자명한 코드에 주석 금지
- 타겟 독자: 5년차 미드레벨 엔지니어
- 아래 3종은 독립적으로 판단한다. 한 대상이 둘 이상에 해당하면 각 블록을 나란히 작성한다 (순서 무관)

### 프로젝트 기본 주석

컴포넌트·훅·유틸 함수·상수 등 **재사용되는 대상의 사용법(계약)**을 설명할 때 사용한다. 자명한 함수·private 헬퍼에는 사용하지 않는다.
자명한 코드에는 추가하지 않는다 — 이름과 시그니처만으로 사용법이 드러나면 주석 불필요.

**추가 대상 (아래 중 하나에 해당할 때만):**
- 모듈 경계를 넘어 재사용되는 공개 API로, 파라미터·반환값의 의미가 이름만으로 드러나지 않을 때
- 사이드이펙트가 있는 훅/유틸 (구독·타이머·이벤트 리스너 등록 등)
- 특정 조합·범위만 허용되는 상수/설정 객체

**태그 정의 (구체적 문법은 JSDoc/TSDoc 등 프로젝트 언어 컨벤션을 따르며 강제하지 않음):**
- Description — 무엇을 하는지 한 줄 요약 (**필수**)
- `@param` — 파라미터 의미가 이름만으로 드러나지 않을 때 (선택)
- `@returns` — 반환값의 의미가 이름만으로 드러나지 않을 때 (선택)
- `@throws` — 발생 가능한 예외가 있을 때 (선택)

```javascript
/**
 * 원두 잔량이 재주문 임계값 이하인지 판단한다.
 * @param {number} remainingGrams - 현재 재고(g)
 * @param {number} thresholdGrams - 재주문 트리거 임계값(g)
 * @returns {boolean} 임계값 이하면 true
 * @throws {Error} remainingGrams가 음수일 때
 */
function shouldReorderBeans(remainingGrams, thresholdGrams) {
    if (remainingGrams < 0) throw new Error("remainingGrams는 음수일 수 없습니다");
    return remainingGrams <= thresholdGrams;
}
```

### Rationale Comment

자명한 코드에는 주석을 달지 않는다. 이름만으로 의도가 드러나면 주석 대신 네이밍으로 해결한다.
**"왜"가 코드 문법만으로는 전혀 드러나지 않을 때만** 추가하며, 모든 변수·함수에 기계적으로 붙이지 않는다.

**추가 대상 (아래 중 하나에 해당할 때만):**
- **Workaround/Hack** — 외부 라이브러리, 특정 브라우저, 레거시 시스템의 버그·특이 동작을 우회할 때
- **Business Rule** — 오프라인 정책, 비직관적인 제품 스펙 등 코드만으로는 유추 불가능한 도메인 규칙에 의존할 때
- **Non-obvious Trade-off** — 가독성보다 성능·보안을 택한 경우 (예: 비트 연산, 복잡한 정규식, 캐싱 레이어)

**태그 정의 (최대 1~2줄, 무거운 템플릿 금지):**
- `[WHY]` — 이 코드가 왜 필요한가 / 왜 이 방식을 택했는가 (**필수**)
- `[CONTEXT]` — 관련 배경, 제약, 참고 링크·이슈 (선택)
- `[TRADE-OFF]` — 포기한 대안과 그 이유 (선택)

```javascript
// [WHY] 외부 결제 SDK가 iOS Safari에서 blur 이벤트를 중복 발생시키는 버그 우회
// [CONTEXT] 오프라인 매장은 재고 음수를 허용하는 정책(온라인과 다른 룰)
// [TRADE-OFF] O(1) 조회를 위해 메모리 캐시 사용, 최대 10MB 제한
```

### Provider Header

Context/Provider 파일(`XxxContext.js`/`XxxProvider.jsx`) 최상단에 붙이는 헤더.

**적용 대상:** Context/Provider 쌍으로 구현되는 파일 (일반 컴포넌트·훅에는 사용하지 않음)

**태그 정의:** Source Header(파일 첫 줄 경로 표기)와 같은 성격의 고정 항목 — "자명한 코드에 주석 금지" 원칙은 인라인 주석 판단에 적용되는 것이며, 이 헤더 자체는 Context/Provider 파일이면 항상 붙인다.
- `Domain` — 이 컨텍스트가 담당하는 책임 경계 (SSOT 여부 등). 코드만으로는 알 수 없는 아키텍처 정보가 있으면 그것을, 없으면 책임 범위를 한 줄로 요약한다 (**필수**)
- `Contract` — 이 컨텍스트/훅을 올바르게 쓰기 위한 전제조건·사용 규칙 중 코드만으로는 드러나지 않는 것 (예: Provider 배치 순서, 특정 환경·라우트 제약) (선택)

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

## Logging

| 레벨 | 용도 |
|------|------|
| `console.error(msg, err)` | caught error — 모듈명 + 맥락 포함 |
| `console.warn(msg)` | fallback/degraded path |
| `createDebugger(namespace)` | 도메인별 디버그 (개발 전용) |

---

## Performance

- `useMemo`: context value, 비용 높은 계산
- `useCallback`: 이벤트 핸들러 (불필요한 re-render 방지)
- Viewport-based lazy rendering (`useInViewport` 훅)
- Dynamic import: 대형 페이지/컴포넌트 지연 로딩

---

## Security

- API key, token, credential 하드코딩 금지
- Sensitive files 목록 참조 (CLAUDE.md → Sensitive Files)
- 권한은 RBAC (`hasRoleAccess`) 통해 검증

---

## Test Code

- **Framework:** Vitest + @testing-library/react + happy-dom
- **위치:** 소스 파일과 같은 디렉토리 (colocated, `*.test.js`)
- **구조:** `describe(단위)` → `it(동작)` → `expect(결과)`
- Provider 의존 컴포넌트 테스트 시: 최소 mock, 실 Provider 우선

---

## Pitfall

| 실수 | 결과 | 방지 |
|------|------|------|
| Provider 순서 변경 | 하위 훅 undefined | App.jsx 순서 = 의존관계 SSOT |
| features.js에 side-effect | 자동화 평가 오류 | 순수 함수만, React/side-effect는 Module Provider에서 |
| SSOT 외부 정규화 | 타입명 불일치 | PouchDB 문서 타입은 schemaNames.js에서만 정의 |
| /dev 라우트 사용 | 프로덕션 오류 | /dev, /dev2~4는 테스트 전용 |
| Contract 위반 시 typeof 가드 | 에러 은폐 | `*OrThrow` 헬퍼 사용 |
