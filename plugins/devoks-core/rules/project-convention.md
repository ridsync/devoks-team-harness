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

### Rationale Comment

```javascript
// 왜: 레이어 계층 SSOT
// 깨짐 영향: 오버레이/모달 겹침
// 수정 경계: 계층 순서 유지(Modal > PopOver > Header)
```

### Provider Header

```javascript
// Domain: Toolbar context SSOT boundary
// Contract: ToolbarProvider must wrap any consumer of useToolbar
// Fail-Fast: missing provider → throw
```

### JSDoc

복잡한 public API에만 사용. 간단한 함수에는 불필요.

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
