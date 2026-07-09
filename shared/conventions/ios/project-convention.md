# Project Convention — iOS Preset

이 문서는 **iOS 프로젝트용 starter preset**입니다.
최초 주입 후에는 이 프로젝트의 실제 선택(Swift/UIKit/SwiftUI, 구조 패턴, 테스트 체인)에 맞게 즉시 수정하세요.

---

## Stack Declaration

- **Language:** [Swift / Objective-C / Mixed]
- **UI:** [SwiftUI / UIKit / Mixed]
- **Architecture:** [MVVM / TCA / VIPER / Clean / Custom]
- **Async:** [Swift Concurrency / Combine / RxSwift / Mixed]
- **Dependency Management:** [SPM / CocoaPods / Mixed]
- **Test:** [XCTest / Snapshot / UI Test / Fastlane-driven]
- **Storage:** [Core Data / SwiftData / Keychain / UserDefaults / Custom]

> 위 선택이 바뀌면 이 문서와 `.claude/CLAUDE.md`를 함께 갱신한다.

---

## Core Rules

- View, state, side effect, platform integration 책임을 분리한다.
- ViewController/View에 비즈니스 로직을 누적하지 않는다.
- lifecycle/task/cancellation 경계를 명시하고, main actor 규칙을 일관되게 유지한다.
- Objective-C bridge, URL scheme, notification, background mode 같은 플랫폼 경계는 화면 코드와 분리한다.

---

## Files & Naming

- 타입명: PascalCase
- 함수/프로퍼티: camelCase
- enum case: lowerCamelCase
- 상수: 프로젝트 선택 규칙을 따른다 (`static let`, namespace enum 등)
- 기능별 그룹화(feature-first)와 계층별 그룹화(layer-first) 중 하나를 고정한다.

---

## UI

- SwiftUI를 쓰면 state source of truth, view decomposition, environment injection 규칙을 정한다.
- UIKit 기반이면 Coordinator/Router/ViewModel 같은 화면 조립 규칙을 명시한다.
- dynamic type, dark mode, safe area, accessibility label/trait, localization을 기본 고려사항으로 둔다.
- loading/error/empty state, modal/navigation 패턴을 일관되게 유지한다.

---

## Design Pattern

### Model Class / Value Type

- 네트워크 DTO, persistence model, domain model, UI state를 한 타입에 섞지 않는다.
- Swift에서는 value type 우선, reference semantics가 필요한 경우에만 class를 사용한다.
- 검증 경계가 있는 모델은 init/factory/mapper에서 invariant를 명시한다.
- plist/user defaults/keychain payload를 domain model처럼 직접 퍼뜨리지 않는다.

### `*OrThrow` / Guard Pattern

- Swift는 `guard`, throwing initializer/factory, `preconditionFailure`가 아니라 명시적 error throw를 우선 고려한다.
- Objective-C 또는 혼합 프로젝트는 validation helper + 명시적 exception/error path를 둔다.
- deep link, storage decode, server payload, feature config 같은 경계에서 느슨한 optional propagation을 피한다.

### Provider / Container Header

- SwiftUI environment/provider, dependency container, coordinator boundary가 있으면 책임 header를 둔다.
- 권장 포맷:
  - `// Domain: <environment/dependency 경계>`
  - `// Contract: <injection 전제, lifecycle, scope>`

---

## Data & Platform Integration

- 네트워크, persistence, keychain, background task, push, deeplink를 분리된 계층에서 다룬다.
- concurrency 모델(Task, MainActor, Combine, Rx 등)은 혼합을 최소화하고 경계를 명확히 한다.
- plist flag, build setting, scheme별 분기는 중앙에서 관리한다.
- Keychain/UserDefaults/Core Data/SwiftData 사용 기준을 문서화한다.

---

## Testing

- unit test / UI test / snapshot test 역할을 분리한다.
- ViewModel, reducer/store, mapper, permission/deeplink branch, persistence contract를 우선 테스트한다.
- flaky UI test를 줄이기 위해 네트워크/시간/기기 상태 의존을 격리한다.
- SwiftUI preview 또는 mock fixture 전략이 있으면 그 패턴을 따른다.

---

## Security & Reliability

- API key, credential, signing 관련 정보 하드코딩 금지
- keychain, universal link, webview, pasteboard, local storage를 우선 점검한다.
- 민감 데이터 저장과 로깅은 프로젝트 보안 SSOT를 따른다.
- crash나 background 작업 실패를 silent ignore 하지 않는다.

---

## Comment Rules

### 프로젝트 기본 주석
- 재사용 public API, side effect helper, 제한된 config 객체에만 주석을 단다.
- Description 1줄 + 필요한 경우 parameter/return/throw 정보를 유지한다.
- 자명한 view layout code나 trivial extension에는 주석을 남발하지 않는다.

### Rationale Comment
- platform workaround, iOS version 차이, architecture trade-off에만 남긴다.
- 권장 포맷:
  - `[WHY]`
  - `[CONTEXT]` (선택)
  - `[TRADE-OFF]` (선택)

### Provider Header
- SwiftUI environment/provider, dependency container, coordinator boundary에 책임 header를 둔다.
- 권장 포맷:
  - `// Domain: <상태/의존 경계>`
  - `// Contract: <injection 전제, scene/lifecycle 제약>`

---

## Pitfalls

| 실수 | 결과 | 방지 |
|------|------|------|
| View/ViewController에 비즈니스 로직 누적 | 테스트 어려움, lifecycle 결합 | ViewModel/Reducer/UseCase 분리 |
| optional payload를 느슨하게 전파 | 늦은 시점 crash | `guard` / throwing factory 검증 |
| MainActor / Task 경계 혼재 | race condition, UI 경합 | concurrency contract 명시 |
| keychain/user defaults 기준 불명확 | 보안·데이터 drift | 저장소 SSOT 명시 |
| environment/provider 경계 문서화 누락 | 주입 순서/범위 버그 | Provider Header + active convention 명시 |

---

## Project Decisions

- **Architecture SSOT:** [예: `docs/architecture.md`]
- **Navigation SSOT:** [예: `Sources/App/Navigation/`]
- **Persistence SSOT:** [예: `Sources/App/Data/`]
- **Design Guideline SSOT:** [예: `docs/DESIGN.md`]
- **Sensitive Files:** [예: `GoogleService-Info.plist`, `*.mobileprovision`, signing config]
