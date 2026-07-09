# Project Convention — React Web Preset

이 문서는 **React Web 프로젝트용 starter preset**입니다.
최초 주입 후에는 이 프로젝트의 실제 선택(언어, 프레임워크, UI 라이브러리, 테스트 스택)에 맞게 즉시 수정하세요.

---

## Stack Declaration

아래 항목을 프로젝트 기준으로 확정해 적는다.

- **Language:** [TypeScript / JavaScript + JSDoc]
- **Build Tool:** [Vite / Next.js / CRA / Custom]
- **UI Library:** [Ant Design / MUI / Chakra / Tailwind / Custom]
- **Styling:** [CSS Modules / Tailwind / styled-components / Emotion / inline style]
- **State:** [Context / Zustand / Redux Toolkit / TanStack Query / Custom]
- **Routing:** [React Router / Next App Router / 없음]
- **Test:** [Vitest / Jest] + [RTL / Cypress / Playwright]

> 위 선택이 바뀌면 이 문서와 `.claude/CLAUDE.md`를 함께 갱신한다.

---

## Core Rules

- Functional component만 사용한다. class component는 레거시 호환 목적 외에는 추가하지 않는다.
- props는 함수 시그니처에서 destructuring 한다.
- 상태·파생값·부수효과를 분리한다. `useEffect`는 동기화/구독/타이머처럼 **부수효과가 실제로 있을 때만** 사용한다.
- 데이터 fetching, 캐시, mutation 규칙은 프로젝트가 채택한 상태관리/서버 상태 라이브러리의 SSOT를 따른다.
- DOM 직접 접근은 ref 기반으로 제한하고, imperative escape hatch는 필요한 경우만 사용한다.

---

## Naming & Files

- 컴포넌트 파일: PascalCase
- 훅 파일: `useXxx`
- 유틸/헬퍼 파일: camelCase
- 상수 파일: 프로젝트가 정한 패턴으로 통일 (`PascalCase` 또는 `camelCase` 중 하나 고정)
- 테스트 파일 위치와 suffix는 기존 코드베이스 패턴을 따른다 (`*.test.*`, `*.spec.*`, colocated vs `__tests__`)
- 이름은 도메인 + 맥락 + 의도를 드러내고, 제네릭 이름(`data`, `info`, `handler`)은 피한다.

---

## Components & Hooks

- 재사용 컴포넌트는 UI 표현과 도메인 규칙을 분리한다.
- 커스텀 훅은 UI 렌더링보다 **상태/동작 캡슐화**에 집중한다.
- Context를 사용할 때는 provider boundary와 consumer contract를 문서화한다.
- provider value는 불필요한 re-render를 막도록 memoization 필요 여부를 검토한다.
- 비즈니스 로직이 큰 경우 component 안에 계속 누적하지 말고 hook/service/util로 분리한다.

---

## Design Pattern

### Model Class / Value Object

- 직렬화/역직렬화·검증 경계가 중요하면 model class 또는 value object를 둔다.
- 권장 패턴:
  - `from()` 또는 factory 함수
  - `validate()` 또는 invariant check
  - `toJSON()` 또는 serializer 분리
- 단순 DTO까지 무조건 class로 만들지 않는다. **검증 경계가 있는 경우에만** 도입한다.

### `*OrThrow` Contract Pattern

- correctness-critical한 입력 경계는 `require*OrThrow` / `assert*OrThrow`류 헬퍼로 검증한다.
- `typeof` 가드나 silent fallback으로 에러를 숨기지 않는다.
- form, query param, route param, storage decode, API response normalize 같은 경계에서 우선 적용한다.

---

## Styling & Design System

- 스타일링은 프로젝트가 채택한 SSOT(디자인 토큰, UI 가이드, 디자인 시스템 문서)를 우선한다.
- 임의 색상/간격/폰트 상수 하드코딩을 피하고, 토큰 또는 공용 상수를 우선한다.
- 반응형·접근성·다크모드 요구사항이 있으면 해당 SSOT를 따른다.
- UI 라이브러리 커스터마이징은 라이브러리 권장 확장 포인트(theme/token/slot)를 우선한다.

---

## State, Data Flow, Side Effects

- 서버 상태와 UI 상태를 분리한다.
- 파생 가능한 값은 상태로 중복 보관하지 않는다.
- effect 내부에서 조건 분기/cleanup을 명시하고, silent failure를 두지 않는다.
- 비동기 흐름은 로딩/성공/실패 상태를 명확히 드러낸다.
- 권한·인증·feature flag처럼 correctness-critical한 경계는 Fail Fast를 우선한다.

---

## Testing

- 테스트 러너·유틸은 프로젝트에서 이미 채택한 조합을 따른다.
- 사용자 관점 테스트를 우선하고, implementation detail assertion은 최소화한다.
- Provider 의존 컴포넌트는 최소 mock 또는 실제 provider wrapper를 사용한다.
- 네트워크/스토리지/시간/브라우저 API mocking 방식은 기존 패턴을 우선 재사용한다.
- 새 기능·버그 수정에는 관련 테스트 추가를 기본으로 한다.

---

## Security & Reliability

- secret, token, API key 하드코딩 금지
- 인증/인가 우회 fallback 금지
- 에러는 삼키지 말고 명시적으로 처리한다.
- 사용자 입력·query param·HTML 렌더링 경계는 XSS/인젝션 위험을 먼저 점검한다.
- 브라우저 저장소(localStorage/sessionStorage)에 민감 정보를 저장할 때는 프로젝트 정책을 따른다.

---

## Comment Rules

### 프로젝트 기본 주석
- 공개 API, 사이드이펙트가 있는 hook/util, 제한된 설정 객체만 주석을 단다.
- Description 1줄 + 필요한 경우 `@param`, `@returns`, `@throws`를 사용한다.
- 자명한 함수·private helper에는 붙이지 않는다.

### Rationale Comment
- workaround, business rule, non-obvious trade-off만 남긴다.
- 권장 포맷:
  - `[WHY]`
  - `[CONTEXT]` (선택)
  - `[TRADE-OFF]` (선택)

### Provider Header
- Context/Provider 파일 최상단에는 boundary header를 둔다.
- 권장 포맷:
  - `// Domain: <context 책임 경계>`
  - `// Contract: <provider 순서·환경 제약>`
- provider chain 순서가 깨지면 동작이 달라지는 프로젝트에서는 특히 명시한다.

---

## Pitfalls

| 실수 | 결과 | 방지 |
|------|------|------|
| 서버 상태와 UI 상태를 중복 저장 | 동기화 drift, stale UI | 파생값은 계산으로 유지 |
| `useEffect`를 계산용으로 사용 | 불필요한 re-render, cleanup 누락 | effect는 부수효과에만 사용 |
| UI token 대신 임의 style 하드코딩 | 디자인 drift | 디자인 토큰/SSOT 우선 |
| route/query/storage decode를 느슨하게 처리 | 런타임 오류 은폐 | `*OrThrow` 경계 검증 |
| Context contract를 문서화하지 않음 | provider 순서 버그 | Provider Header + active convention 명시 |

---

## Project Decisions

아래는 preset 주입 후 반드시 프로젝트 실정에 맞게 채운다.

- **Import Order:** [프로젝트 실제 규칙]
- **Directory Policy:** [feature-first / layer-first / route-first]
- **State SSOT:** [예: Zustand stores under `src/store/`]
- **API Layer SSOT:** [예: `src/api/`]
- **UI Guideline SSOT:** [예: `docs/DESIGN.md`]
- **Sensitive Files:** [예: `.env*`, `*.pem`]
