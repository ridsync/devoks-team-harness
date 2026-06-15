---
name: devoks-core-rules
description: "DevOks 에이전트 행동 원칙 컨텍스트 주입 — Agent Principles, Project Convention, Memory Policy를 로드한다."
---

# Agent Principles

Behavioral principles the AI agent must follow during development work.

---
## [Philosophy] Code Principles

- **Single Source of Truth (SSOT)** — Specs, types, constants, and schemas must be defined only in the project-designated authoritative files. Do not redefine them elsewhere or replace them with inline literals.
- **DRY (Don't Repeat Yourself)** — If the same logic appears in two or more places, extract it. Eliminate code duplication at the component, hook, and utility levels.
- **Simplicity First (KISS)** — Choose the simplest solution that meets requirements. Avoid premature abstraction and over-engineering. Add complexity only when justified.
- **YAGNI (You Aren't Gonna Need It)** — Do not implement features, configurations, error handling, or infrastructure that are not required by the current task. Future requirements are added when they actually arise.
- **Fail Fast (Core Flows)** — In correctness-critical paths, surface errors immediately and stop execution. Prevent large costs at later stages.
- **Explicit Handling (No Implicit Fallback)** — All failures and edge cases must be handled explicitly; silent or implicit fallback is prohibited.
- **Graceful Degradation for Non-Critical Paths** — Failures in non-critical features (analytics, notifications, telemetry) must not block core flows (auth, brew, sensor-ingest). Isolate failure scope; core flows always apply Fail Fast.

## [Pre-Work] Checklist Before Starting

1. **Read Before Touch** — Never suggest modifications without first reading the relevant code. Always read before acting.
2. **Spec First** — Check the relevant PRD/TRD sections before implementation or design-affecting work.
3. **Scope Declaration** — Explicitly state the change scope (which files, which features). If the user explicitly asks to implement, fix, or update a specific scope, treat that request as approval for that scope.
4. **Ask Before Expanding Scope** — Ask before generating code when the request is ambiguous, context is insufficient, more than 3 files may be affected, architecture/API contracts may change, or work outside the requested scope is needed.

## [Done] Definition of Done

5. **Zero Lint/Type Errors** — Work is complete only when there are no lint or TypeScript errors.
6. **Tests Pass** — Relevant tests must pass. If no tests exist, explicitly flag the need for them.
7. **Spec Compliance** — Directly verify that the implementation matches PRD/TRD specs.
8. **No Silent TODOs** — All unresolved TODOs and temporary code must be explicitly flagged before marking work complete.

## [Prohibited] Hard Rules

9. **No Unauthorized Code** — Do not generate code outside the approved or user-requested scope. If scope is unclear, ask first.
10. **No Dev Server Start** — Do not run the dev server (e.g. `pnpm dev`). Assume it is always already running. For mobile UI verification, use feasible lint/type/test/static checks; if simulator or device validation is required, ask the user to verify it.
11. **No Unauthorized Git** — Do not run `git commit` or `git push` without an explicit request.
12. **No Safety Bypass** — Do not bypass safety mechanisms such as `--no-verify`, `--force`, or `--hard`.
13. **No Scope Creep** — Do not refactor, improve, or add features outside the requested scope.
14. **No Destructive Action** — Do not delete files, branches, or other resources without explicit confirmation.

## [Scope Control] Minimal Change Principle

15. **Minimal Change** — Change only what was requested. Do not clean up unrelated code or add comments.
16. **One Task, One Unit** — Keep a single task to a single PR unit. Do not bundle multiple concerns together.
17. **No Premature Abstraction** — Do not create abstractions for future requirements not in the current scope.

## [State & Context] Maintain Consistency

18. **Explicit Progress** — Share decisions and progress status explicitly during work.
19. **Persist Decisions** — Record decisions and feedback that must persist across sessions in memory.
20. **Apply Past Feedback** — Always apply feedback received in previous conversations to subsequent work.

---

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

---

## Component Pattern

### Context / Provider

```javascript
export const ToolbarContext = createContext(null);
export function useToolbarOrThrow() {
    const ctx = useContext(ToolbarContext);
    if (!ctx) throw new Error("useToolbar must be used within a ToolbarProvider");
    return ctx;
}

export const ToolbarProvider = ({ children }) => {
    const value = useMemo(() => ({ ... }), [deps]);
    return <ToolbarContext.Provider value={value}>{children}</ToolbarContext.Provider>;
};
```

- `createContext(null)` + `useXxxOrThrow()` 패턴
- `useMemo`로 context value 감싸기

---

## Error Handling

| 상황 | 처리 |
|------|------|
| Contract boundary | `*OrThrow` → `throw Error` with context message |
| HTTP | `fetchWithAuth` 에러 → 호출자에서 catch/handle |
| I/O (DB, 파일) | try-catch + `console.error` + rethrow |
| Provider 초기화 | catch + `console.error` + rethrow |

**금지:** silent catch, implicit fallback, typeof 가드로 조용히 넘기기

---

## Test Code

- **Framework:** Vitest + @testing-library/react + happy-dom
- **위치:** 소스 파일과 같은 디렉토리 (`*.test.js`)
- **구조:** `describe(단위)` → `it(동작)` → `expect(결과)`

---

# Memory Policy — 메모리 계층 SSOT

영속 사실이 여러 곳에 흩어지면 drift(불일치)가 생기므로, **계층별 역할을 아래로 고정**한다.
결정·선호·영속 사실의 단일 진실원천(SSOT)은 **Claude 파일 메모리** 하나다.

## 계층별 역할 (확정)

| 계층 | 위치 | 역할 | 운영 규칙 |
|------|------|------|----------|
| **Claude 파일 메모리** | `~/.claude/projects/.../memory/` | **영속 사실·결정·피드백·레퍼런스의 SSOT** | 세션을 넘겨 유지할 결정/선호/사실은 **여기에만** 기록 |
| **context-mode 세션 메모리** | `ctx_search(sort: "timeline")` | **자동 세션 회상 전용** | 자동 캡처만 신뢰. **수동 큐레이션 금지** |
| **Serena memory** | `.serena/memories/` | **사용 안 함** | 결정·사실 저장 금지. Serena는 심볼 탐색·편집 도구로만 사용 |

## 규칙

1. **영속 결정은 SSOT 하나에만** — Claude 파일 메모리에 기록하고 `MEMORY.md`에 인덱스 한 줄.
2. **회상 ≠ 진실원천** — context-mode 회상 결과는 스냅샷. 파일·플래그·심볼 추천 전에 현존 여부 검증.
3. **중복 금지** — 같은 사실을 두 계층에 동시에 적지 않는다. 충돌 시 Claude 파일 메모리가 우선.
4. **승격 패턴** — 세션 메모리에서 발견한 영속 가치 있는 사실은 Claude 파일 메모리로 옮겨 적는다.
