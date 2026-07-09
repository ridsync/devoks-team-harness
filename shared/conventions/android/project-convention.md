# Project Convention — Android Preset

이 문서는 **Android 프로젝트용 starter preset**입니다.
최초 주입 후에는 이 프로젝트의 실제 선택(Kotlin/Java, Compose/XML, DI, 테스트 체인)에 맞게 즉시 수정하세요.

---

## Stack Declaration

- **Language:** [Kotlin / Java / Mixed]
- **UI:** [Jetpack Compose / XML Views / Mixed]
- **Architecture:** [MVVM / MVI / Clean / Custom]
- **DI:** [Hilt / Koin / Manual / Custom]
- **Async:** [Coroutines / RxJava / Mixed]
- **Test:** [JUnit / Kotest / Robolectric / Espresso / Macrobenchmark]
- **Storage:** [Room / DataStore / SharedPreferences / Custom]

> 위 선택이 바뀌면 이 문서와 `.claude/CLAUDE.md`를 함께 갱신한다.

---

## Core Rules

- UI, domain, data, platform integration 책임을 분리한다.
- Android framework type(Activity, Fragment, Service)에 비즈니스 로직을 누적하지 않는다.
- lifecycle-aware API를 우선 사용하고, observer/collector 해제 시점을 명시한다.
- thread, coroutine scope, cancellation contract를 명시적으로 다룬다.

---

## Files & Naming

- 클래스/컴포저블/Fragment/Activity: PascalCase
- 함수/변수: camelCase
- 상수: UPPER_SNAKE_CASE
- 패키지 구조는 feature-first 또는 layer-first 중 하나로 일관되게 유지한다.
- UI resource naming은 Android 표준 접두 규칙(layout_, ic_, color_, string_)을 따른다.

---

## UI

- Compose를 쓰면 state hoisting, immutable UI state, preview 전략을 정한다.
- XML 기반이면 view binding/data binding 사용 기준을 명시한다.
- 다크모드, font scaling, screen size, accessibility label/content description을 기본 고려사항으로 둔다.
- navigation, loading, error, empty state 패턴을 일관되게 유지한다.

---

## Design Pattern

### Model Class / Data Class

- 네트워크 DTO, DB entity, domain model, UI state를 한 타입에 섞지 않는다.
- 검증 경계가 있는 모델은 constructor/factory/mapper에서 invariant를 잡는다.
- Repository / UseCase / Mapper 계층이 있다면 타입 변환 책임을 명확히 둔다.
- Android framework 객체(Bundle, Intent extras)를 domain model 대신 직접 전파하지 않는다.

### `*OrThrow` / Guard Pattern

- Kotlin이면 `require`, `check`, `requireNotNull` 또는 프로젝트 `require*OrThrow` 헬퍼를 우선한다.
- Java이면 validation helper + 명시적 exception으로 Fail Fast 처리한다.
- deep link param, intent extra, config, remote payload, storage decode 같은 경계에서 느슨한 null 허용을 피한다.

### Provider / Container Boundary

- DI module, service locator, store/provider boundary는 책임과 생성 규칙을 문서화한다.
- Compose `CompositionLocal`, DI container, navigation graph scope가 실제 의존 경계면 header/주석으로 드러낸다.

---

## Data & Platform Integration

- Repository / UseCase / DataSource 경계를 프로젝트 선택에 맞게 고정한다.
- Room/DataStore/네트워크/파일 I/O는 main thread에서 직접 수행하지 않는다.
- permission, background work, notification, deep link, intent contract를 분리된 경계에서 다룬다.
- BuildConfig/flavor별 분기는 중앙에서 관리한다.

---

## Testing

- unit test / instrumentation test / UI test 경계를 명확히 한다.
- ViewModel, use case, repository contract, mapper, permission branch를 우선 테스트한다.
- Compose UI test 또는 Espresso 규칙은 프로젝트가 채택한 패턴을 따른다.
- flaky 테스트를 줄이기 위해 time/network/device 의존을 격리한다.

---

## Security & Reliability

- secret, signing config, API key 하드코딩 금지
- exported component, intent filter, deep link, webview, local storage를 우선 점검한다.
- 민감 정보는 보안 저장소/암호화 전략이 있으면 그 SSOT를 따른다.
- crash, ANR, background work failure는 silent ignore 하지 않는다.

---

## Comment Rules

### 프로젝트 기본 주석
- 재사용 public API, side effect helper, 제한된 config 객체에만 주석을 단다.
- Description 1줄 + 필요한 경우 param/return/throw 정보를 유지한다.
- 자명한 getter/setter, 단순 compose/xml binding code에는 주석을 남발하지 않는다.

### Rationale Comment
- platform workaround, OEM 차이, build variant trade-off, Android framework bug 우회 시 남긴다.
- 권장 포맷:
  - `[WHY]`
  - `[CONTEXT]` (선택)
  - `[TRADE-OFF]` (선택)

### Provider Header
- DI module, provider, container, CompositionLocal boundary 파일에는 책임 header를 둔다.
- 권장 포맷:
  - `// Domain: <DI/상태 경계>`
  - `// Contract: <scope, lifecycle, 사용 전제>`

---

## Pitfalls

| 실수 | 결과 | 방지 |
|------|------|------|
| Activity/Fragment에 비즈니스 로직 누적 | lifecycle 결합, 테스트 어려움 | ViewModel/UseCase 분리 |
| Intent extra/deeplink를 느슨하게 처리 | 런타임 crash 또는 잘못된 화면 진입 | `require*OrThrow` / guard 검증 |
| main thread에서 I/O 수행 | jank, ANR | repository/data layer 비동기화 |
| flavor/build setting 분산 관리 | 환경 drift | 중앙 설정 SSOT 유지 |
| DI/provider scope 문서화 누락 | 객체 생명주기 버그 | Provider Header + scope 명시 |

---

## Project Decisions

- **Architecture SSOT:** [예: `docs/architecture.md`]
- **DI SSOT:** [예: `app/src/main/java/.../di/`]
- **Navigation SSOT:** [예: `app/src/main/java/.../navigation/`]
- **Storage SSOT:** [예: `app/src/main/java/.../data/`]
- **Sensitive Files:** [예: `keystore.properties`, `*.jks`, `local.properties`]
