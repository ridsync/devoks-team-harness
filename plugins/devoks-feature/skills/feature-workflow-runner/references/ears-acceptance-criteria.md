# EARS 기반 Acceptance Criteria 작성법

> FRD §3의 AC를 **테스트로 자동 변환 가능한 형태**로 쓰기 위한 규칙.
> EARS(Easy Approach to Requirements Syntax)는 자연어 요구사항을 소수의 정형 패턴으로 제한해
> 모호함을 없앤다. AC 한 줄 = 테스트 케이스 한 개가 되도록 작성한다.

## 왜 EARS인가

"~를 잘 처리한다" 같은 서술은 통과/실패를 판정할 수 없다. EARS는 **트리거 조건 + 시스템 응답**을
강제해, 작성자가 빠뜨린 분기(예외·미통과 경로)를 드러내고 그대로 테스트 assert로 옮기게 한다.

## 5가지 패턴

| 패턴 | 형식 | 쓰는 때 |
|------|------|---------|
| Ubiquitous | THE SYSTEM SHALL <동작> | 항상 성립하는 불변 규칙 |
| Event-driven | WHEN <트리거> THE SYSTEM SHALL <동작> | 특정 이벤트/입력에 대한 반응 |
| State-driven | WHILE <상태> THE SYSTEM SHALL <동작> | 특정 상태가 유지되는 동안의 동작 |
| Unwanted (예외) | IF <조건> THEN THE SYSTEM SHALL <동작> | 오류·미통과·폴백 경로 |
| Optional | WHERE <기능 활성> THE SYSTEM SHALL <동작> | 설정/플래그로 켜질 때만 |

## ID 규칙

- 요구사항: `REQ-001`, `REQ-002` ...
- AC: `AC-<REQ번호>-<순번>` — 예: `AC-001-1`, `AC-001-2`. 어느 REQ에 속하는지 ID에 드러낸다.
- 이 ID들은 PLAN의 `traces:`에서 그대로 참조된다(→ `traceability.md`).

## 작성 체크리스트

- [ ] 각 REQ는 **정상 경로(WHEN/WHILE) AC + 예외 경로(IF) AC**를 최소 1개씩 갖는다.
- [ ] 동작(SHALL 뒤)이 **관측 가능**하다 — 화면 전이, 저장값, 반환값 등 검증 가능한 결과.
- [ ] 주어는 항상 `THE SYSTEM`. 사용자 행위는 트리거(WHEN/IF) 절에만 둔다.
- [ ] 하나의 AC에 동작 하나. "그리고 ~도 한다"가 들어가면 AC를 쪼갠다.
- [ ] 수치/임계값은 Contract(§5.1)의 `CTR-xxx`로 빼고 AC는 그 ID를 인용한다.

## 예시 (도메인 중립)

REQ-001: 저장된 필터 뷰 적용

- `AC-001-1` WHEN 사용자가 저장된 뷰를 선택 THE SYSTEM SHALL 해당 뷰의 필터 조합을 목록에 즉시 적용한다.
- `AC-001-2` WHILE 필터가 적용된 동안 THE SYSTEM SHALL 활성 필터 개수를 헤더에 표시한다.
- `AC-001-3` IF 저장된 뷰의 필터 키가 현재 스키마에 없으면 THEN THE SYSTEM SHALL 해당 키를 무시하고 경고 토스트를 노출한다.

## AC → 테스트 변환

각 AC는 `describe(REQ) → it(AC)` 한 개로 옮긴다. 트리거 = arrange/act, SHALL 동작 = assert.

```
describe("REQ-001 저장된 필터 뷰 적용", () => {
  it("AC-001-1: 저장 뷰 선택 시 필터 조합을 즉시 적용한다", () => { /* arrange 트리거 → assert 동작 */ });
  it("AC-001-3: 미존재 필터 키는 무시하고 경고를 노출한다", () => { /* IF 경로 */ });
});
```

테스트 설명에 AC ID를 박아두면 PLAN `traces`와 양방향 추적이 된다.
