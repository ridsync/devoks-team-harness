# 추적성 (Traceability) — REQ/AC/CTR/EDGE ↔ TASK

> 모든 요구사항이 빠짐없이 작업으로 변환됐는지를 **`traces`** 한 장치로 보장한다.
> 대형 템플릿의 Coverage Matrix를 대신해, 각 Task가 자신이 충족하는 명세 ID를 들고 있는다.

## 추적 단위

PLAN의 각 Task 끝에 `traces:`로 자신이 구현/검증하는 FRD 명세 ID를 나열한다.

```
- [ ] TASK-002 [P] 편차 판단 훅 + 테스트 — file: src/.../useX.js — traces: CTR-001, REQ-001
```

추적 대상 ID 종류:
- `REQ-xxx` — 요구사항
- `AC-xxx-y` — Acceptance Criteria (가장 세밀, 테스트와 1:1)
- `CTR-xxx` — Contract 파라미터/상태전이
- `EDGE-xxx` — Edge Case / 에러 처리
- `DSN-xxx` — 설계 결정(§4 Design Spec). **참조용** — 인용은 권장하나 아래 커버리지 누락 0 점검 대상은 아니다(설계는 구조 선택이라 Task와 1:1로 떨어지지 않음).
- `RES-ASSET-xxx`, `RES-API-xxx` — 필요 시 리소스 의존 표기

## 커버리지 규칙 (누락 0)

PLAN 작성·검수 시 **FRD에 존재하는 모든 `AC-*`, `CTR-*`, `EDGE-*` ID가 최소 한 Task의 `traces`에 등장**해야 한다. (`DSN-*`은 참조용으로 제외 — 강제 대상 아님.)

- `REQ-*`는 보통 그 하위 `AC-*`가 커버되면 함께 커버된 것으로 본다(REQ 단독 trace는 선택).
- 한 ID가 여러 Task에 걸쳐도 된다(예: 화면 + 결과 렌더). 0회 등장이 금지다.
- 거꾸로, 어떤 ID도 가리키지 않는 Task는 "왜 필요한가"를 재검토한다(스코프 크리프 신호).

## 커버리지 자가 점검 (스크립트)

PLAN/FRD가 같은 디렉터리에 있을 때, FRD의 ID 집합과 PLAN `traces`의 ID 집합을 비교해 누락을 찾는다.

```bash
# FRD에서 정의된 추적 ID 추출
grep -oE 'AC-[0-9]+-[0-9]+|CTR-[0-9]+|EDGE-[0-9]+' FRD.md | sort -u > /tmp/frd_ids.txt
# PLAN traces에서 참조된 ID 추출
grep -oE 'AC-[0-9]+-[0-9]+|CTR-[0-9]+|EDGE-[0-9]+' PLAN.md | sort -u > /tmp/plan_ids.txt
# FRD에는 있는데 PLAN이 안 가리키는 ID = 커버리지 누락
comm -23 /tmp/frd_ids.txt /tmp/plan_ids.txt
```

마지막 명령 출력이 비어 있어야 "누락 0"이다. 출력이 있으면 그 ID들을 담당할 Task를 추가한다.

## Definition of Done 연결

PLAN §5 DoD의 "모든 REQ/AC/CTR/EDGE가 Task traces로 커버됨 (누락 0)" 항목은 위 점검으로 객관 판정한다.
실행 완료 시점에도 동일 점검을 재실행해, 구현 중 추가된 명세가 누락되지 않았는지 확인한다.
