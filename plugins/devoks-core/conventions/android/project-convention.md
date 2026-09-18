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

## 구조 패턴 일괄 치환 (ast-grep)

동일 AST 패턴이 **N건** 있고 그걸 한 번에 바꿔야 할 때만 쓴다. 단건 심볼 편집은 Serena,
경로를 이미 아는 단순 확인은 내장 Read/Grep이 싸다. 이 스택의 언어 id: `kotlin` · `java`.

**기본은 애드혹 — 설정 파일이 필요 없다.**

```bash
# 조회
ast-grep run -p 'findViewById<$T>($ID)' --lang kotlin app/src/
# (deprecated View 조회 API를 쓰는 지점 전수 조회)

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
| 제출·결제·삭제 버튼의 재진입을 막지 않음 | 연타 시 중복 확정(주문 2건 등) | 진행 중 플래그로 클릭 차단 + 서버 멱등성 키. 판정 기준은 `.claude/refs/interaction-integrity.md` §1·C4 |

---

## Project Decisions

아래는 preset 주입 후 반드시 프로젝트 실정에 맞게 채운다.

- **Architecture SSOT:** [예: `docs/architecture.md`]
- **DI SSOT:** [예: `app/src/main/java/.../di/`]
- **Navigation SSOT:** [예: `app/src/main/java/.../navigation/`]
- **Storage SSOT:** [예: `app/src/main/java/.../data/`]
- **Sensitive Files:** [예: `keystore.properties`, `*.jks`, `local.properties`]
