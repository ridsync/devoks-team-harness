---
id: ADR-NNN
title: "<결정 한 줄 — 예) 서버 상태는 TanStack Query로 관리한다>"  # 값은 항상 쌍따옴표(콜론+공백 포함 시 YAML 파싱 실패)
status: proposed  # proposed → accepted → superseded | deprecated
date: "<YYYY-MM-DD>"
supersedes: "<ADR-NNN | 없음>"
superseded_by: "<ADR-NNN | 없음>"
source: "<결정 출처 — 예) TRD v0.2.0 §2 / docs/workspace/<기능>/FRD.md DSN-002 / code-refactoring / 대화>"
---

# ADR-NNN: <title>

## Context
<왜 지금 이 결정이 필요한가. 강제하는 요구·제약(NFR-n·불변식·기존 구조·팀 역량)과 관련 사실. 확인 못 한 사실은 `미확정`으로 적는다.>

## Decision
<무엇을 하기로 했는가 — 한두 문장, 능동형. "~를 검토한다"가 아니라 "~로 한다".>

## Rationale
<왜 이 안인가 — Context의 요구·제약 중 무엇을 이 안이 충족하는지 연결한다(예: NFR-2 응답 200ms → 캐시 계층 필요). 근거가 된 사실·측정·공식 문서는 출처를 붙인다. 대안별 기각 이유는 아래 표에 둔다.>

## Considered Alternatives
| 대안 | 장점 | 기각 이유 |
|---|---|---|
| <대안 A — 채택> | | (채택) |
| <대안 B> | | |

## Consequences
- **좋아지는 것:** <>
- **감수하는 것:** <비용·제약·부채>
- **이후 코드가 지킬 규약:** <이 결정 때문에 앞으로 따라야 하는 방식 — 없으면 "없음">

## Revisit Conditions
<어떤 사실이 바뀌면 이 결정을 다시 여는가 — 예: 동시 사용자 1만 초과, 계획 플랫폼(태블릿 앱) 착수.>

## Related
- <PRD/TRD 섹션 · FRD 경로 · PR · 이슈 · 대체/피대체 ADR>
