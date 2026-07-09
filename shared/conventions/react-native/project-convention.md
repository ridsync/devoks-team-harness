# Project Convention — React Native Preset

이 문서는 **React Native 프로젝트용 starter preset**입니다.
최초 주입 후에는 이 프로젝트의 실제 선택(Expo/Bare, TypeScript 여부, navigation/state/styling)에 맞게 즉시 수정하세요.

---

## Stack Declaration

- **Runtime:** [Expo / Bare React Native]
- **Language:** [TypeScript / JavaScript + JSDoc]
- **Navigation:** [React Navigation / Expo Router / Custom]
- **State:** [Context / Zustand / Redux Toolkit / TanStack Query / Custom]
- **Styling:** [StyleSheet / NativeWind / Styled Components / Custom]
- **Test:** [Jest / Vitest] + [RTL / Detox / Maestro]
- **Native Bridge:** [없음 / Android module / iOS module / 양쪽]

> 위 선택이 바뀌면 이 문서와 `.claude/CLAUDE.md`를 함께 갱신한다.

---

## Core Rules

- Functional component와 hook 중심으로 구현한다.
- 플랫폼 분기(`Platform.OS`, `.ios.*`, `.android.*`)는 꼭 필요한 경우에만 사용하고, 분기 이유를 명확히 한다.
- 네이티브 모듈/권한/딥링크/foreground-background 전환처럼 플랫폼 경계가 있는 로직은 화면 코드와 분리한다.
- Bridge 호출 실패는 silent ignore 하지 않고 사용자 영향 범위를 명시적으로 처리한다.

---

## Files & Naming

- 컴포넌트: PascalCase
- 훅: `useXxx`
- 유틸/서비스: camelCase
- 플랫폼 전용 파일은 React Native 표준 suffix를 따른다 (`*.ios.*`, `*.android.*`)
- 화면/네비게이션/스토어/서비스 위치는 기존 코드베이스 구조를 우선한다.

---

## UI & UX

- 터치 영역, safe area, keyboard avoidance, loading/error/empty state 처리를 기본 고려사항으로 둔다.
- spacing/color/typography는 디자인 시스템 또는 공용 토큰을 우선한다.
- 기기 크기·platform별 미세 차이는 token/utility/component abstraction으로 흡수한다.
- animation은 사용자 경험상 필요한 경우에만 넣고, 성능 비용이 큰 레이아웃 thrash를 피한다.

---

## Design Pattern

### Model Class / Value Object

- API payload, local storage snapshot, native bridge payload처럼 검증 경계가 있으면 model class/value object를 둔다.
- 권장 패턴:
  - `from()` 또는 parse factory
  - `validate()` 또는 invariant check
  - `toJSON()` 또는 serialize helper
- 단순 화면 전용 UI state까지 class로 만들 필요는 없다.

### `*OrThrow` Contract Pattern

- permission result, deeplink param, storage decode, native bridge result는 `require*OrThrow` / `assert*OrThrow`류 검증으로 Fail Fast 처리한다.
- 잘못된 payload를 조용히 무시하지 않는다.
- correctness-critical flow와 degraded flow를 분리한다.

---

## State, Data Flow, Device Integration

- 서버 상태와 로컬 UI 상태를 분리한다.
- 앱 lifecycle(AppState), network reachability, permission status, deep link state는 명시적으로 관리한다.
- 네이티브 API 사용 시 iOS/Android 계약 차이를 문서화한다.
- background task, push notification, storage sync는 실패 범위를 core flow와 분리한다.

---

## Performance

- FlatList/SectionList 사용 시 render item 안정성, key extractor, memoization 필요 여부를 점검한다.
- 큰 이미지는 lazy loading / caching 전략을 검토한다.
- 불필요한 re-render를 피하도록 context value, selector, callback 분리를 검토한다.
- JS thread와 UI thread를 막는 무거운 연산은 분리한다.

---

## Testing

- 테스트 러너/도구는 실제 프로젝트 설정을 따른다.
- hook, state, permission flow, navigation guard, offline/online 전환 같은 모바일 특화 시나리오를 포함한다.
- 네이티브 모듈 mock은 최소화하되, 플랫폼 경계 contract는 테스트로 드러낸다.
- 실제 기기/시뮬레이터 검증이 필요한 항목은 문서에 명시한다.

---

## Security & Reliability

- token, keychain/secure storage, deep link, webview boundary를 우선 점검한다.
- 권한 요청은 필요한 시점에만 수행하고, 거부 시 fallback UI를 명시한다.
- 민감 데이터는 AsyncStorage 같은 비보안 저장소에 임의 저장하지 않는다.
- crash를 삼키지 말고, 사용자 영향/재시도 정책을 분리한다.

---

## Comment Rules

### 프로젝트 기본 주석
- 재사용 hook/service, side effect helper, 제한된 config 객체만 주석을 단다.
- Description 1줄 + 필요한 경우 `@param`, `@returns`, `@throws`를 사용한다.
- 자명한 component render code에는 주석을 남발하지 않는다.

### Rationale Comment
- 플랫폼 분기, native workaround, device-specific business rule에만 남긴다.
- 권장 포맷:
  - `[WHY]`
  - `[CONTEXT]` (선택)
  - `[TRADE-OFF]` (선택)

### Provider Header
- Context/Provider, store provider, environment provider 파일에는 boundary header를 둔다.
- 권장 포맷:
  - `// Domain: <provider 책임 경계>`
  - `// Contract: <provider 순서·platform 제약>`
- auth, navigation, feature flag, network 상태 provider 순서가 중요한 경우 특히 명시한다.

---

## Pitfalls

| 실수 | 결과 | 방지 |
|------|------|------|
| 플랫폼 분기를 화면 곳곳에 흩뿌림 | 유지보수 악화 | bridge/service 경계로 격리 |
| permission/deeplink payload를 느슨하게 처리 | 재현 어려운 런타임 오류 | `*OrThrow` 검증 |
| AsyncStorage에 민감 데이터 저장 | 보안 취약점 | secure storage SSOT 준수 |
| FlatList 최적화 미흡 | 스크롤 성능 저하 | key/memoization/render 분리 |
| provider 순서 문서화 누락 | 특정 상태가 항상 비정상 | Provider Header + active convention 명시 |

---

## Project Decisions

- **Navigation SSOT:** [예: `src/navigation/`]
- **State SSOT:** [예: `src/store/`]
- **Native Modules:** [예: `android/app/...`, `ios/...`]
- **Design Guideline SSOT:** [예: `docs/DESIGN.md`]
- **Sensitive Files:** [예: `.env*`, `GoogleService-Info.plist`, `google-services.json`]
