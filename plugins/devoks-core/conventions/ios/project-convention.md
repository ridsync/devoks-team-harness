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

## 구조 패턴 일괄 치환 (ast-grep)

동일 AST 패턴이 **N건** 있고 그걸 한 번에 바꿔야 할 때만 쓴다. 단건 심볼 편집은 Serena,
경로를 이미 아는 단순 확인은 내장 Read/Grep이 싸다. 이 스택의 언어 id: `swift`.

**기본은 애드혹 — 설정 파일이 필요 없다.**

```bash
# 조회
ast-grep run -p 'DispatchQueue.main.async { $$$BODY }' --lang swift Sources/
# (메인스레드 디스패치 지점 전수 조회(async/await 전환 대상 식별))

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
| 제출·결제·삭제 버튼의 재진입을 막지 않음 | 연타 시 중복 확정(주문 2건 등) | 진행 중 플래그로 탭 차단 + 서버 멱등성 키. 판정 기준은 `.claude/refs/interaction-integrity.md` §1·C4 |

---

## Project Decisions

아래는 preset 주입 후 반드시 프로젝트 실정에 맞게 채운다.

- **Architecture SSOT:** [예: `docs/architecture.md`]
- **Navigation SSOT:** [예: `Sources/App/Navigation/`]
- **Persistence SSOT:** [예: `Sources/App/Data/`]
- **Design Guideline SSOT:** [예: `docs/DESIGN.md`]
- **Sensitive Files:** [예: `GoogleService-Info.plist`, `*.mobileprovision`, signing config]
