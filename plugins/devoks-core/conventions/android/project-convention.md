# Project Convention — Android Preset

이 문서는 **Android 프로젝트용 preset**입니다. bracket 선택형 메뉴가 아니라, 한 가지로 결정된 예시 스택과 실제 코드/테이블로 구성되어 있습니다.
최초 주입 후에는 아래 예시 스택·코드를 프로젝트의 실제 선택으로 즉시 교체하세요.

---

## Stack

- **Language:** Kotlin (Java 금지)
- **UI:** Jetpack Compose
- **Architecture:** MVVM (Repository + UseCase)
- **DI:** Hilt
- **Async:** Coroutines + Flow
- **Storage:** Room + DataStore
- **Test:** JUnit5 + Turbine + Compose UI Test

---

## Coding Style

### Naming

| 대상 | 규칙 | 예시 |
|------|------|------|
| 클래스/컴포저블/ViewModel | PascalCase | `ProductListScreen`, `ProductViewModel` |
| 함수/변수 | camelCase | `loadProductList`, `remainingQty` |
| 상수 | UPPER_SNAKE_CASE | `ITEM_STATUS.CREATE` |
| 패키지 | lowercase, feature-first | `com.app.feature.product` |
| UI resource | 표준 접두 | `layout_`, `ic_`, `color_`, `string_` |
| 테스트 클래스 | 대상 + `Test` suffix | `ProductViewModelTest` |

### Code Size

- **Functions:** ≤50 lines (target), **100 lines max** (hard limit).
- **Files:** ≤500 lines (target), **1000 lines max** (hard limit).

### Package Structure

```
com.app.feature.product/
  data/        // DTO, Repository impl, DataSource
  domain/      // UseCase, domain model
  di/          // Hilt module
  ui/          // Composable, ViewModel, UI state
```

---

## Core Rules

- UI, domain, data, platform integration 책임을 분리한다 (위 패키지 구조 참조).
- `Activity`/`Fragment`에 비즈니스 로직을 누적하지 않는다. ViewModel/UseCase로 위임한다.
- lifecycle-aware API(`repeatOnLifecycle`, `collectAsStateWithLifecycle`)를 우선 사용하고, observer/collector 해제 시점을 명시한다.
- `viewModelScope`/`Dispatchers` 지정과 cancellation 계약을 명시적으로 다룬다.

---

## Design Pattern

### Model / Data Class

```kotlin
data class Product(
    val id: String,
    val name: String,
    val price: Int,
) {
    companion object {
        fun from(dto: ProductDto): Product {
            require(dto.name.isNotBlank()) { "Product.name은 비어 있을 수 없습니다" }
            return Product(id = dto.id, name = dto.name, price = dto.price)
        }
    }
}
```

- 네트워크 DTO, DB entity, domain model, UI state를 한 타입에 섞지 않는다.
- 검증 경계가 있는 모델은 factory/mapper에서 invariant를 잡는다.
- Repository / UseCase / Mapper 계층에서 타입 변환 책임을 명확히 둔다.
- `Bundle`, `Intent` extras 같은 Android framework 객체를 domain model 대신 직접 전파하지 않는다.

### Guard Pattern (`*OrThrow` 대응)

```kotlin
fun requireValidQuantity(qty: Int): Int {
    require(qty >= 0) { "qty는 음수일 수 없습니다" }
    return qty
}
```

- `require`, `check`, `requireNotNull`을 correctness-critical 경계(deep link param, intent extra, config, remote payload, storage decode)에서 우선 사용한다.
- 잘못된 값을 느슨한 null 허용으로 조용히 넘기지 않는다.

### DI Module (Hilt)

```kotlin
@Module
@InstallIn(SingletonComponent::class)
object ProductModule {
    @Provides
    @Singleton
    fun provideProductRepository(api: ProductApi, dao: ProductDao): ProductRepository =
        ProductRepositoryImpl(api, dao)
}
```

- DI module, `CompositionLocal`, navigation graph scope처럼 실제 의존 경계가 있으면 Provider Header로 책임과 lifecycle을 문서화한다.

---

## UI (Compose)

- state hoisting을 기본으로 하고, UI state는 immutable data class로 표현한다.
- Preview 함수는 `@Preview` + 샘플 데이터로 구성한다.
- 다크모드, font scaling, screen size, `contentDescription`(accessibility)을 기본 고려사항으로 둔다.
- navigation, loading, error, empty state 패턴을 화면 전반에서 일관되게 유지한다.

---

## Data & Platform Integration

- Repository → UseCase → ViewModel 순서로 의존하며, 역방향 의존을 두지 않는다.
- Room/DataStore/네트워크/파일 I/O는 `Dispatchers.IO`에서 수행하고 main thread에서 직접 호출하지 않는다.
- permission, background work(`WorkManager`), notification, deep link, intent contract는 분리된 경계에서 다룬다.
- `BuildConfig`/flavor별 분기는 중앙(`di/` 또는 `config/`)에서 관리한다.

---

## Testing

- **Framework:** JUnit5 + Turbine(Flow 테스트) + Compose UI Test
- ViewModel, UseCase, Repository contract, Mapper, permission branch를 우선 테스트한다.
- unit test(`test/`) / instrumentation test(`androidTest/`) 경계를 명확히 한다.
- flaky 테스트를 줄이기 위해 time/network/device 의존을 fake/mock으로 격리한다.

---

## Security & Reliability

- secret, signing config, API key 하드코딩 금지 (`local.properties`/`BuildConfig`로 주입)
- exported component, intent filter, deep link, webview, local storage를 우선 점검한다.
- 민감 정보는 `EncryptedSharedPreferences` 또는 Keystore 기반 저장소를 사용한다.
- crash, ANR, background work failure는 silent ignore 하지 않고 로깅·리포팅한다.

---

## Comment Rules

### 프로젝트 기본 주석
- 재사용 public API, side effect가 있는 UseCase/Repository, 제한된 config 객체에만 주석을 단다.
- Description 1줄 + 필요한 경우 파라미터/반환/예외 설명을 유지한다.
- 자명한 getter, 단순 Composable binding code에는 주석을 남발하지 않는다.

```kotlin
/**
 * 재고 수량이 재주문 임계값 이하인지 판단한다.
 * @param remainingQty 현재 재고 수량
 * @param thresholdQty 재주문 트리거 임계값
 */
fun shouldReorderStock(remainingQty: Int, thresholdQty: Int): Boolean {
    require(remainingQty >= 0) { "remainingQty는 음수일 수 없습니다" }
    return remainingQty <= thresholdQty
}
```

### Rationale Comment
- platform workaround, OEM 차이, build variant trade-off, Android framework 버그 우회 시 남긴다.

```kotlin
// [WHY] 특정 OEM의 알림 채널 캐시 버그로 앱 재설치 전까지 채널 설정이 갱신되지 않아 버전 suffix로 채널 ID를 갈아탐
// [CONTEXT] Android 8+ 알림 채널 정책
```

### Provider Header
- DI module, provider, container, `CompositionLocal` boundary 파일에는 책임 header를 둔다.

```kotlin
// Domain: Product repository DI boundary
// Contract: SingletonComponent 범위 — Application lifecycle 전체에서 단일 인스턴스 유지
@Module
@InstallIn(SingletonComponent::class)
object ProductModule { /* ... */ }
```

---

## Pitfalls

| 실수 | 결과 | 방지 |
|------|------|------|
| `Activity`/`Fragment`에 비즈니스 로직 누적 | lifecycle 결합, 테스트 어려움 | ViewModel/UseCase 분리 |
| Intent extra/deeplink를 느슨하게 처리 | 런타임 crash 또는 잘못된 화면 진입 | `require`/guard 검증 |
| main thread에서 I/O 수행 | jank, ANR | `Dispatchers.IO`로 분리 |
| flavor/build setting 분산 관리 | 환경 drift | 중앙 설정 SSOT 유지 |
| DI/provider scope 문서화 누락 | 객체 생명주기 버그 | Provider Header + scope 명시 |

---

## Project Decisions

아래는 preset 주입 후 반드시 프로젝트 실정에 맞게 채운다.

- **Architecture SSOT:** [예: `docs/architecture.md`]
- **DI SSOT:** [예: `app/src/main/java/.../di/`]
- **Navigation SSOT:** [예: `app/src/main/java/.../navigation/`]
- **Storage SSOT:** [예: `app/src/main/java/.../data/`]
- **Sensitive Files:** [예: `keystore.properties`, `*.jks`, `local.properties`]
