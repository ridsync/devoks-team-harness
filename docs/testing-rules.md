# 테스트 코드 작성 규칙 (에이전트용)

> 목적: 에이전트가 테스트 코드를 **작성/수정/리뷰**할 때 따르는 명령형 규칙과 체크리스트.
> 범용 원칙 중심이며, 구체 예시는 JS/TS(Vitest·Jest·Testing Library·Playwright) 기준.

## 0. 사용 규약

- 규칙 강도: **MUST**(반드시), **MUST NOT**(금지), **SHOULD**(원칙적으로), **MAY**(허용).
- 우선순위 충돌 시: `안전·정확성 > 이번 요청 > 프로젝트 컨벤션 > 이 문서 > 간결성`.
- **프로젝트에 기존 테스트 컨벤션(파일 위치, 네이밍, 러너 설정)이 있으면 그것을 최우선**으로 따른다. 이 문서는 공백을 메운다.
- 테스트를 새로 만들기 전 **기존 테스트 1~2개를 먼저 읽어** 스타일을 맞춘다. (MUST)

---

## 1. 핵심 원칙 (MUST)

### 1.1 FIRST

| 원칙 | 의미 | 위반 시 |
|---|---|---|
| **F**ast | 단위 테스트는 ms 단위. 느리면 아무도 안 돌린다 | 실 DB/네트워크/`sleep` 사용 |
| **I**solated | 테스트 간·외부 상태와 독립. 순서 무관 | 전역 상태·공유 fixture 오염 |
| **R**epeatable | 언제 어디서 돌려도 같은 결과 | 실시간 시계·랜덤·타임존 의존 |
| **S**elf-validating | pass/fail이 코드로 자동 판정 | 로그 눈으로 확인, assertion 없음 |
| **T**imely | 대상 코드와 함께(또는 먼저) 작성 | 기능 완성 후 뒤늦게 몰아 작성 |

### 1.2 행위(behavior)를 테스트하라, 구현(implementation)을 테스트하지 마라

- 테스트는 **"무엇을 하는가(공개 계약)"**에 걸고, **"어떻게 하는가(내부)"**에 걸지 않는다.
- 리팩터링(동작 불변)으로 **테스트가 깨지면 나쁜 테스트**다. 버그로만 깨져야 한다.
- private 함수·내부 필드·호출 순서를 직접 검증하지 않는다. 공개 API의 결과·부수효과로 검증한다.

```ts
// BAD: 내부 구현(메서드 호출 여부)에 결합
expect(service._buildQuery).toHaveBeenCalled();

// GOOD: 관찰 가능한 결과에 결합
expect(await service.findUser("u1")).toEqual({ id: "u1", name: "Kim" });
```

### 1.3 결정성(Determinism) — flaky 금지

비결정성 원인은 **주입/고정**한다. (MUST)

- **시간**: 실시간 대신 fake timer / 고정 clock 주입.
- **난수·UUID**: seed 고정 또는 생성기 주입.
- **동시성·타이밍**: `sleep(임의시간)` 금지 → 조건 기반 대기(`waitFor`, `findBy*`).
- **네트워크·FS·DB**: 단위 테스트에서 실제 I/O 금지 → mock/in-memory.
- **순서 의존**: 정렬 없는 컬렉션을 순서로 비교하지 않는다.

```ts
vi.useFakeTimers();
vi.setSystemTime(new Date("2025-01-01T00:00:00Z"));
// ... 시간 의존 로직 실행 ...
vi.useRealTimers();
```

### 1.4 실패 이유는 하나 (one reason to fail)

- 한 테스트는 **하나의 논리적 동작**만 검증한다. (여러 물리적 `expect`는 허용, 여러 시나리오는 분리)
- 실패 메시지만 보고 **원인이 특정**되어야 한다.

---

## 2. 작업 워크플로우 (에이전트 절차)

### 2.1 기본은 명세 우선 → Red-Green-Refactor

1. **명세 추출**: 요구사항/PRD/함수 시그니처에서 검증할 **동작 목록**을 뽑는다.
   (정상 경로 + 경계 + 오류 + 부수효과)
2. **Red**: 실패하는 테스트를 먼저 작성한다. *실제로 실패하는지 확인*한다(가짜 통과 방지).
3. **Green**: 통과할 최소 구현.
4. **Refactor**: 테스트를 안전망 삼아 구조 개선. 이 단계에서 테스트는 **깨지지 않아야** 정상.

> 레거시/기존 코드 수정 시: 먼저 현재 동작을 고정하는 **characterization test**를 깔고 변경한다.

### 2.2 버그 수정 시 (MUST)

- 수정 전, **그 버그를 재현하는 실패 테스트**를 먼저 작성한다(regression test). 그 후 고친다.

---

## 3. 테스트 구조·명세 방식

### 3.1 AAA (Arrange–Act–Act) — 단위/통합 기본 골격

```ts
it("applies 10% discount for premium members", () => {
  // Arrange
  const cart = createCart({ total: 100, member: "premium" });
  // Act
  const result = applyDiscount(cart);
  // Assert
  expect(result.total).toBe(90);
});
```

- 세 구획을 **빈 줄로 시각 분리**. Act는 원칙적으로 한 줄(한 동작).

### 3.2 Given–When–Then / Gherkin — 행위·수용(acceptance) 명세

사용자 관점 시나리오·BDD·E2E에서 사용. 도메인 언어로 기술한다.

```gherkin
Scenario: 재고 부족 시 주문 거절
  Given 상품 A의 재고가 0이다
  When 사용자가 상품 A를 주문하면
  Then 주문은 거절되고 "품절" 메시지가 표시된다
```

- **AAA ↔ GWT 대응**: Given=Arrange, When=Act, Then=Assert.

### 3.3 네이밍 (SHOULD)

- 테스트 이름은 **"조건에서 무엇을 한다/된다"**를 서술. 함수명 반복 금지.
- 권장 형태: `describe("대상")` + `it("조건일 때 기대결과")`.
- 예: `it("returns 401 when token is expired")`, `it("throws on negative quantity")`.

### 3.4 파일 구조 (SHOULD)

- 4-phase(Setup–Exercise–Verify–Teardown) 중 **Teardown은 자동화**(afterEach/리소스 자동정리)한다.
- fixture·helper는 테스트 의도를 가리지 않게 **명시적**으로. 과도한 공유 setup은 결합을 만든다.

---

## 4. 테스트 레벨 결정 (피라미드 / 트로피)

작성 전 **어느 레벨인지 먼저 결정**한다. (MUST)

| 레벨 | 대상 | 비중 | 속도 | 도구(JS/TS) |
|---|---|---|---|---|
| **Unit** | 순수 로직·단일 모듈 | 많이 | ms | Vitest / Jest |
| **Integration** | 모듈 경계·DB·API 결합 | 중간 | 수백 ms | Vitest + Testcontainers / MSW |
| **E2E** | 사용자 플로우 전체 | 적게 | 초 | Playwright / Cypress |

결정 휴리스틱:

- 로직 분기·계산·엣지 케이스가 핵심 → **Unit**.
- "여러 조각이 실제로 맞물리는가"가 핵심 → **Integration**.
- "사용자가 목표를 달성하는가"가 핵심 → **E2E** (핵심 플로우만, 최소한).
- **프런트엔드는 "Testing Trophy"** 관점 유효: 통합 테스트에 무게를 둔다. 컴포넌트는 **사용자가 쓰는 방식**(role/label로 접근, 클릭·입력)으로 검증한다.

```ts
// GOOD (Testing Library): 구현 아닌 사용자 관점
const btn = screen.getByRole("button", { name: /save/i });
await userEvent.click(btn);
expect(await screen.findByText(/saved/i)).toBeInTheDocument();
```

- **테스트할 가치 판단**: 자명한 getter/래퍼/타입만 옮기는 코드는 굳이 단위 테스트하지 않는다. **분기·경계·계약**에 집중한다.

---

## 5. 테스트 더블 (Test Doubles, Meszaros 분류)

| 종류 | 역할 | 언제 |
|---|---|---|
| **Dummy** | 자리만 채움(사용 안 됨) | 필수 인자 채우기 |
| **Stub** | 정해진 값 반환 | 입력 상태 세팅 |
| **Spy** | 호출 기록 관찰 | 부수효과 발생 확인 |
| **Mock** | 기대한 상호작용을 사전 규정·검증 | 협력 계약 검증 |
| **Fake** | 가볍게 동작하는 실제 구현 | in-memory DB/repo |

규칙:

- **상태 검증(state) > 상호작용 검증(interaction)**. 결과로 검증 가능하면 mock 대신 실제 결과를 assert한다.
- **소유하지 않은 타입(3rd-party)을 직접 mock하지 마라.** 얇은 어댑터로 감싸고 그 경계를 mock/fake한다.
- **과도한 mocking 금지**: mock이 많을수록 테스트는 구현에 결합되고 리팩터링에 취약해진다.
- HTTP는 함수 레벨 mock보다 **네트워크 레벨 mock**(MSW) 선호 — 실제 요청 경로를 더 사실적으로 검증.

---

## 6. 테스트 케이스 설계 기법

입력 공간을 체계적으로 덮는다.

- **동등 분할(Equivalence Partitioning)**: 같은 처리 받는 입력군마다 대표 1개.
- **경계값 분석(Boundary Value)**: 경계 `min-1, min, min+1 … max-1, max, max+1`에서 버그가 몰린다. **경계는 반드시 테스트**. (MUST)
- **필수 3종 세트**: `정상(happy) · 엣지(edge) · 오류(error/예외)`를 각각 최소 1개.
- **부정 케이스**: null/빈값/음수/초과길이/권한없음/타임아웃.
- **Property-based testing (SHOULD, 로직 무거울 때)**: 개별 예시 대신 **불변식**을 다수 무작위 입력으로 검증. (예: `decode(encode(x)) === x`, 정렬 후 길이·원소 보존)

```ts
import fc from "fast-check";
it("round-trips any string", () => {
  fc.assert(fc.property(fc.string(), (s) => decode(encode(s)) === s));
});
```

---

## 7. 고급 기법 (필요 시 MAY)

- **Contract testing**: 서비스 간 경계(예: 프런트↔API, MSA)에서 **provider/consumer 계약**을 검증. 통합 환경 전체를 띄우지 않고 계약 위반을 잡는다. (Pact 등)
- **Snapshot testing**: UI/직렬화 출력에 유용하나 **남용 금지**. 큰 스냅샷은 리뷰 불가·무의미 통과를 유발한다. 작고 의도가 분명한 스냅샷만. 무지성 `--update` 금지. (MUST NOT: 검토 없이 스냅샷 갱신)
- **Mutation testing (품질 점검용)**: 커버리지가 높아도 테스트가 실제로 버그를 잡는지 의심될 때, 코드를 변형(mutant)시켜 테스트가 잡아내는지 측정. (Stryker) 상시 아님, 게이트/점검용.
- **Characterization test**: 명세 없는 레거시의 현재 동작을 있는 그대로 고정 → 안전한 변경 기반 확보.

---

## 8. 금지 안티패턴 (MUST NOT)

- ❌ **Assertion 없는 테스트** / 실행만 하고 검증 없음.
- ❌ **구현 세부 결합**: private 호출·내부 필드·호출 횟수에 과도하게 의존.
- ❌ **Flaky 유발**: 실시간 시계, 시드 없는 랜덤, `sleep(ms)` 고정 대기, 실제 외부 I/O.
- ❌ **테스트 간 의존/순서 의존**: 앞 테스트 상태에 기대는 테스트.
- ❌ **Over-mocking**: 로직 대부분이 mock이라 실제로 검증되는 게 없는 테스트.
- ❌ **커버리지용 허수 테스트**: 라인만 밟고 동작을 검증하지 않는 테스트.
- ❌ **테스트에 조건분기/루프로 로직 재구현**: 테스트가 복잡하면 신뢰 불가. 테스트는 선형·명료해야 한다.
- ❌ **로직 없는 코드 테스트**: 단순 위임/DTO를 억지로 테스트하며 시간 낭비.

---

## 9. 커버리지·품질 게이트

- 커버리지는 **바닥(floor)이지 목표(target)가 아니다.** 100% 자체를 목적화하지 않는다.
- **라인 커버리지보다 브랜치 커버리지**가 의미 있다. 분기·경계가 덮였는지 본다.
- 게이트는 **핵심 도메인 로직**에 강하게, 어댑터/보일러플레이트엔 느슨하게.
- "커버됐다 ≠ 검증됐다". 의심되면 **mutation testing**으로 실효성을 점검한다.

---

## 10. 제출 전 최종 체크리스트 (MUST 통과)

```
[ ] 테스트가 실제로 "실패→통과"함을 확인했다 (가짜 통과 아님)
[ ] 정상 / 경계 / 오류 케이스를 각각 최소 1개 포함
[ ] 외부 I/O(네트워크·DB·FS)·시간·랜덤을 제거/고정했다
[ ] 순서·병렬 실행에 무관하게 독립적이다
[ ] 구현이 아니라 공개 동작/계약을 검증한다
[ ] 리팩터링(동작 불변)으로는 깨지지 않는다
[ ] 각 테스트의 실패 원인이 하나로 특정된다
[ ] 이름만 봐도 "조건→기대결과"를 알 수 있다
[ ] 기존 프로젝트 테스트 스타일/도구와 일치한다
[ ] 자원 정리(teardown)가 자동화되어 누수가 없다
```

---

## 부록 A. JS/TS 스택 빠른 참조

| 목적 | 도구 | 비고 |
|---|---|---|
| 러너/단위 | Vitest, Jest | 신규는 Vitest 선호(ESM·속도) |
| React 컴포넌트 | Testing Library + userEvent | role/label 접근, 구현 결합 회피 |
| HTTP mock | MSW | 네트워크 레벨, 통합에 사실적 |
| E2E | Playwright | 자동 대기, 병렬, trace |
| 통합(실인프라) | Testcontainers | 실 DB/브로커 컨테이너 |
| Property-based | fast-check | 불변식 검증 |
| Contract | Pact | consumer/provider 계약 |
| Mutation | Stryker | 테스트 실효성 점검 |

핵심 idiom:

```ts
// 비동기 UI 등장 대기: sleep 금지, 조건 기반
await screen.findByRole("alert");        // 나타날 때까지
await waitFor(() => expect(fn).toHaveReturned());

// 예외 검증
await expect(() => svc.charge(-1)).rejects.toThrow(/positive/);
```

---

### 참고 개념 출처(정본 확인용)

- **TDD** — Kent Beck, *Test-Driven Development: By Example*
- **FIRST / Clean Tests** — Robert C. Martin, *Clean Code*
- **Test Doubles 분류(Dummy/Stub/Spy/Mock/Fake)** — Gerard Meszaros, *xUnit Test Patterns*
- **BDD / Given-When-Then** — Dan North; Gherkin(Cucumber)
- **Testing Trophy / 사용자 관점** — Kent C. Dodds, Testing Library 원칙
- **경계값·동등분할** — 소프트웨어 테스팅 표준 기법(ISTQB)

> 위 프레임워크의 **버전별 API·설정**은 시간에 따라 바뀌므로, 실제 코드 생성 시 Context7/공식 문서로 재확인할 것.
