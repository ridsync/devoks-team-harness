# Project Convention — iOS Preset

이 문서는 **iOS 프로젝트용 preset**입니다. bracket 선택형 메뉴가 아니라, 한 가지로 결정된 예시 스택과 실제 코드/테이블로 구성되어 있습니다.
최초 주입 후에는 아래 예시 스택·코드를 프로젝트의 실제 선택으로 즉시 교체하세요.

---

## Stack

- **Language:** Swift
- **UI:** SwiftUI
- **Architecture:** MVVM
- **Async:** Swift Concurrency (`async/await`, `Task`)
- **Dependency Management:** Swift Package Manager
- **Storage:** SwiftData + Keychain
- **Test:** XCTest

---

## Coding Style

### Naming

| 대상 | 규칙 | 예시 |
|------|------|------|
| 타입명 (View/ViewModel/Model) | PascalCase | `ProductListView`, `ProductViewModel` |
| 함수/프로퍼티 | camelCase | `loadProductList`, `remainingQty` |
| enum case | lowerCamelCase | `.loading`, `.failed(error:)` |
| 상수 | `static let` + camelCase | `static let maxRetryCount = 3` |
| 테스트 클래스 | 대상 + `Tests` suffix | `ProductViewModelTests` |

### Code Size

- **Functions:** ≤50 lines (target), **100 lines max** (hard limit).
- **Files:** ≤500 lines (target), **1000 lines max** (hard limit).

### File Organization

```
Sources/App/Feature/Product/
  Product.swift              // domain model
  ProductRepository.swift    // data access
  ProductViewModel.swift     // state + use case 호출
  ProductListView.swift      // SwiftUI view
```

- 기능별 그룹화(feature-first)를 기본으로 하고, layer-first가 필요하면 프로젝트 전체에 일관되게 적용한다.

---

## Core Rules

- View, state, side effect, platform integration 책임을 분리한다 (위 파일 구조 참조).
- `View`/`ViewController`에 비즈니스 로직을 누적하지 않는다. ViewModel/UseCase로 위임한다.
- `@MainActor` 경계와 `Task` lifecycle/cancellation을 명시적으로 다룬다.
- Objective-C bridge, URL scheme, notification, background mode 같은 플랫폼 경계는 화면 코드와 분리한다.

---

## Design Pattern

### Model / Value Type

```swift
struct Product: Codable, Identifiable {
    let id: String
    let name: String
    let price: Int

    static func from(_ dto: ProductDTO) throws -> Product {
        guard !dto.name.isEmpty else {
            throw ValidationError.invalidField("Product.name")
        }
        return Product(id: dto.id, name: dto.name, price: dto.price)
    }
}
```

- 네트워크 DTO, persistence model, domain model, UI state를 한 타입에 섞지 않는다.
- value type(`struct`)을 기본으로 하고, reference semantics가 필요한 경우(공유 상태, 참조 동일성)에만 `class`를 사용한다.
- 검증 경계가 있는 모델은 throwing factory에서 invariant를 명시한다.

### Guard Pattern (`*OrThrow` 대응)

```swift
func requireValidQuantity(_ qty: Int) throws -> Int {
    guard qty >= 0 else {
        throw ValidationError.invalidField("qty")
    }
    return qty
}
```

- deep link, storage decode, server payload, feature config 같은 경계에서 `guard` + throwing factory로 Fail Fast 처리한다.
- 느슨한 optional propagation(`??` 기본값, `try?` 무시)으로 에러를 숨기지 않는다.

### Environment / Dependency Container

```swift
// Domain: 앱 전역 의존성 경계
// Contract: RootView 최상단에서 주입 — 하위 View는 @Environment로만 접근
struct ProductRepositoryKey: EnvironmentKey {
    static let defaultValue: ProductRepository = ProductRepositoryImpl()
}
extension EnvironmentValues {
    var productRepository: ProductRepository {
        get { self[ProductRepositoryKey.self] }
        set { self[ProductRepositoryKey.self] = newValue }
    }
}
```

- SwiftUI environment/dependency container, coordinator boundary가 있으면 책임 header를 둔다.

---

## UI (SwiftUI)

- state source of truth를 ViewModel(`@Published`/`@Observable`)에 둔다.
- view decomposition은 화면당 하나의 root view + 하위 subview로 나눈다.
- dynamic type, dark mode, safe area, accessibility label/trait, localization을 기본 고려사항으로 둔다.
- loading/error/empty state, modal/navigation 패턴을 화면 전반에서 일관되게 유지한다.

---

## Data & Platform Integration

- 네트워크, persistence, keychain, background task, push, deeplink를 분리된 계층에서 다룬다.
- concurrency 모델은 Swift Concurrency로 통일하고, Combine과의 혼합은 경계를 명확히 한다.
- plist flag, build setting, scheme별 분기는 중앙(`Config/`)에서 관리한다.
- Keychain은 민감 정보(토큰, 자격증명), `UserDefaults`는 비민감 설정값에만 사용한다.

---

## Testing

- **Framework:** XCTest
- ViewModel, mapper, permission/deeplink branch, persistence contract를 우선 테스트한다.
- unit test / UI test / snapshot test 역할을 분리한다.
- flaky UI test를 줄이기 위해 네트워크/시간/기기 상태 의존을 fake/mock으로 격리한다.
- SwiftUI Preview는 실제 fixture 데이터를 재사용해 프로덕션 코드와 drift를 줄인다.

---

## Security & Reliability

- API key, credential, signing 관련 정보 하드코딩 금지 (`.xcconfig` + 별도 secret 관리)
- keychain, universal link, webview, pasteboard, local storage를 우선 점검한다.
- 민감 데이터는 Keychain에 저장하고, 로그에 노출하지 않는다.
- crash나 background 작업 실패를 silent ignore 하지 않고 로깅한다.

---

## Comment Rules

### 프로젝트 기본 주석
- 재사용 public API, side effect가 있는 ViewModel/Repository, 제한된 config 객체에만 주석을 단다.
- Description 1줄 + 필요한 경우 parameter/throws 설명을 유지한다.
- 자명한 view layout code나 trivial extension에는 주석을 남발하지 않는다.

```swift
/// 재고 수량이 재주문 임계값 이하인지 판단한다.
/// - Parameters:
///   - remainingQty: 현재 재고 수량
///   - thresholdQty: 재주문 트리거 임계값
/// - Throws: remainingQty가 음수일 때 `ValidationError`
func shouldReorderStock(remainingQty: Int, thresholdQty: Int) throws -> Bool {
    guard remainingQty >= 0 else { throw ValidationError.invalidField("remainingQty") }
    return remainingQty <= thresholdQty
}
```

### Rationale Comment
- platform workaround, iOS 버전 차이, architecture trade-off에만 남긴다.

```swift
// [WHY] iOS 16 이하에서 NavigationStack이 없어 NavigationView + isActive 바인딩으로 우회
// [CONTEXT] 최소 지원 버전이 iOS 15이므로 당분간 유지
```

### Provider Header
- SwiftUI environment/provider, dependency container, coordinator boundary에 책임 header를 둔다.

```swift
// Domain: 상품 목록 상태 경계
// Contract: RootView 하위에서만 접근 — 상위 주입 없으면 defaultValue(mock)로 대체됨
```

---

## Pitfalls

| 실수 | 결과 | 방지 |
|------|------|------|
| View/ViewController에 비즈니스 로직 누적 | 테스트 어려움, lifecycle 결합 | ViewModel/UseCase 분리 |
| optional payload를 느슨하게 전파 (`??`, `try?`) | 늦은 시점 crash 또는 잘못된 기본값 | `guard`/throwing factory 검증 |
| `@MainActor`/`Task` 경계 혼재 | race condition, UI 경합 | concurrency contract 명시 |
| Keychain/UserDefaults 기준 불명확 | 보안·데이터 drift | 저장소 SSOT 명시 |
| environment/provider 경계 문서화 누락 | 주입 순서/범위 버그 | Provider Header + active convention 명시 |

---

## Project Decisions

아래는 preset 주입 후 반드시 프로젝트 실정에 맞게 채운다.

- **Architecture SSOT:** [예: `docs/architecture.md`]
- **Navigation SSOT:** [예: `Sources/App/Navigation/`]
- **Persistence SSOT:** [예: `Sources/App/Data/`]
- **Design Guideline SSOT:** [예: `docs/DESIGN.md`]
- **Sensitive Files:** [예: `GoogleService-Info.plist`, `*.mobileprovision`, signing config]
