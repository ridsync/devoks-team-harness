# 테스트 품질 기준 (Test Quality Bar)

> SSOT — `test-author`(작성)·`code-implementer`(PLAN 태스크 인라인 작성)·`test-run-triage`(플래키 원인 추정)가 참조한다.
> 사용자 제공 원본 `docs/testing-rules.md`(276줄)에서 ROI 기준으로 선별·압축했다 — 전체 도입이 아니다.
> 프레임워크 비종속 원칙 중심. 부록의 도구명은 예시일 뿐 강제가 아니다.

## 1. FIRST 원칙

| 원칙 | 의미 | 위반 시 |
|---|---|---|
| Fast | 단위 테스트는 ms 단위 | 실 DB/네트워크/`sleep` 사용 |
| Isolated | 테스트 간·외부 상태와 독립, 순서 무관 | 전역 상태·공유 fixture 오염 |
| Repeatable | 언제 어디서 돌려도 같은 결과 | 실시간 시계·랜덤·타임존 의존 |
| Self-validating | pass/fail이 코드로 자동 판정 | assertion 없음, 로그 육안 확인 |
| Timely | 대상 코드와 가까운 시점에 작성 | 기능 완성 후 한참 뒤 몰아서 작성 |

> Timely는 "작성 시점"에 관한 원칙이지 "선-테스트 순서"를 강제하지 않는다 — 순서 예외는 §7만 참고.

## 2. 행위(behavior)를 테스트하라, 구현(implementation)을 테스트하지 마라

- 공개 계약("무엇을 하는가")에 검증을 걸고, 내부("어떻게 하는가")에 걸지 않는다.
- 리팩터링(동작 불변)으로 테스트가 깨지면 나쁜 테스트다 — 버그로만 깨져야 한다.
- private 함수·내부 필드·호출 횟수를 직접 검증하지 않는다.

```
// BAD: 내부 구현(메서드 호출 여부)에 결합
expect(service._buildQuery).toHaveBeenCalled();
// GOOD: 관찰 가능한 결과에 결합
expect(await service.findUser("u1")).toEqual({ id: "u1", name: "Kim" });
```

## 3. 결정성(Determinism) — flaky 원인과 대응

| 원인 | 대응 |
|---|---|
| 시간 | fake timer / 고정 clock 주입 |
| 난수·UUID | seed 고정 또는 생성기 주입 |
| 동시성·타이밍 | `sleep(임의시간)` 금지 → 조건 기반 대기 |
| 네트워크·FS·DB | 단위 테스트에서 실 I/O 금지 → mock/in-memory |
| 순서 의존 | 정렬 없는 컬렉션을 순서로 비교하지 않는다 |

> `test-run-triage`가 실패를 "플래키"로 분류할 때 이 표를 1차 원인 후보 체크리스트로 쓴다.

## 4. 구조

- **AAA**(Arrange–Act–Assert): 세 구획을 빈 줄로 시각 분리. Act는 원칙적으로 한 줄(한 동작).
- BDD/E2E 시나리오는 Given–When–Then(Gherkin)으로 대체 가능 — Given=Arrange, When=Act, Then=Assert.
- **네이밍**: "조건에서 무엇을 한다/된다"를 서술(함수명 반복 금지). 예: `it("returns 401 when token is expired")`.
- teardown은 자동화(`afterEach` 등)한다 — 수동 정리에 의존하지 않는다.

## 5. 테스트 레벨 결정 — 작성 전에 먼저 정한다

- 로직 분기·계산·엣지 케이스가 핵심 → **Unit**.
- 여러 모듈이 실제로 맞물리는지가 핵심 → **Integration**.
- 사용자가 목표를 달성하는지가 핵심 → **E2E**(핵심 플로우만, 최소한).
- 프런트엔드는 Testing Trophy 관점 유효 — 통합 테스트에 무게, 컴포넌트는 사용자 관점(role/label 접근)으로 검증.
- **자명한 getter/래퍼/단순 위임/DTO는 굳이 단위 테스트하지 않는다** — 분기·경계·계약에 집중한다(시간 낭비 방지).

## 6. 케이스 설계

- **필수 3종**: 정상(happy) · 경계(edge) · 오류(error) 각 최소 1개.
- **경계값 분석**: `min-1, min, min+1 … max-1, max, max+1`에서 버그가 몰린다 — 경계는 반드시 테스트한다.
- **부정 케이스**: null/빈값/음수/초과길이/권한없음/타임아웃.
- Property-based testing(예: 프로젝트에 `fast-check` 등 동등 도구가 이미 있을 때만, MAY) — 개별 예시 대신 불변식(`decode(encode(x)) === x` 류)을 검증하고 싶을 때.

## 7. 버그 수정 예외 (MUST — 이 문서에서 유일하게 "작성 순서"를 규정)

- 대상이 버그 수정이면, 수정 전에 **그 버그를 재현하는 실패 테스트**를 먼저 작성하고 실제로 실패함을 확인한 뒤 고친다(regression test).
- 그 외 일반 로직 태스크는 이 순서를 강제하지 않는다 — 사후 작성이 기본값이다(근거: 순서 강제의 토큰비용 대비 품질개선 증거 부족 — `docs/roadmap.md`의 관련 결정 참고).
- 레거시/명세 없는 코드를 변경해야 하면, 변경 전 현재 동작을 고정하는 characterization test를 먼저 깔 수 있다(MAY).

## 8. 테스트 더블 (Meszaros 분류)

| 종류 | 역할 |
|---|---|
| Dummy | 자리만 채움(사용 안 됨) |
| Stub | 정해진 값 반환 |
| Spy | 호출 기록 관찰 |
| Mock | 기대한 상호작용을 사전 규정·검증 |
| Fake | 가볍게 동작하는 실제 구현(in-memory DB 등) |

- **상태 검증(state) > 상호작용 검증(interaction)** — 결과로 검증 가능하면 mock 대신 실제 결과를 assert한다.
- **소유하지 않은 3rd-party 타입을 직접 mock하지 않는다** — 얇은 어댑터로 감싸고 그 경계를 mock/fake한다.
- **과도한 mocking 금지** — mock이 많을수록 테스트는 구현에 결합되고 리팩터링에 취약해진다.
- HTTP는 함수 레벨 mock보다 **네트워크 레벨 mock**(예: MSW류) 선호 — 실제 요청 경로를 더 사실적으로 검증.

## 9. 금지 안티패턴 (MUST NOT)

- ❌ Assertion 없는 테스트(실행만 하고 검증 없음).
- ❌ 구현 세부 결합(private 호출·내부 필드·호출 횟수에 과도 의존).
- ❌ Over-mocking(로직 대부분이 mock이라 실제로 검증되는 게 없음).
- ❌ 커버리지용 허수 테스트(라인만 밟고 동작은 검증하지 않음).
- ❌ 테스트 간 의존/순서 의존(앞 테스트 상태에 기대는 테스트).
- ❌ 테스트에 조건분기/루프로 로직을 재구현(복잡한 테스트는 신뢰 불가 — 선형·명료해야 한다).

## 10. 커버리지 철학

- 커버리지는 **바닥(floor)이지 목표(target)가 아니다** — 100% 자체를 목적화하지 않는다.
- 라인 커버리지보다 **브랜치 커버리지**(분기·경계가 덮였는가)가 의미 있다.
- "커버됐다 ≠ 검증됐다" — 의심되면 mutation testing(예: Stryker류)으로 실효성을 점검한다(MAY, 상시 게이트 아님).

## 11. 고급 기법 (MAY — 프로젝트에 이미 해당 도구/관행이 있을 때만)

- Contract testing(예: Pact류) — 서비스 경계의 provider/consumer 계약을 검증, 통합 환경 전체를 안 띄워도 됨.
- Snapshot testing — UI/직렬화 출력에 유용하나 남용 금지. **검토 없이 `--update`로 일괄 갱신하지 않는다(MUST NOT)**.

## 부록 — 예시 도구 (참고용 · 비강제, 프로젝트가 실제 쓰는 도구가 항상 우선)

| 목적 | 예시 도구 |
|---|---|
| 러너/단위 | Vitest, Jest, pytest 등 |
| 컴포넌트(웹) | Testing Library류(role/label 접근) |
| HTTP mock | MSW류(네트워크 레벨) |
| E2E | Playwright, Cypress 등 |
| Property-based | fast-check 등 |
| Mutation | Stryker 등 |
