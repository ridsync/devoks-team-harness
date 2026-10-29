---
doc_type: feature-backlog
prd: ./PRD.md
prd_version: 0.2.0
updated: 2026-10-01
---

# 팀 회고 보드 — 기능 백로그

| ID | 기능 | 포함 FR | 릴리스 | MoSCoW | 의존 | 상태 | FRD |
|---|---|---|---|---|---|---|---|
| F-1 | 회고 세션 진행 | FR-1, FR-2, FR-3 | MVP | Must | — | frd | .claude/workspace/retro-session-20261005/FRD.md |
| F-2 | 액션 아이템 추적 | FR-4, FR-5 | MVP | Must | F-1 | backlog | — |
| F-3 | 카드 자동 그룹핑 | FR-6 | Next | Should | F-1 | backlog | — |

---

## F-1 회고 세션 진행
- 기능: 리드가 세션을 열고 팀원이 익명 카드 작성·투표
- 대상 사용자: 개발팀 리드, 팀원
- Why: G-1, S-1
- Success: 회고 30분 이내
- Non-goals: 실시간 화상 기능
- 관련 제약·NFR: NFR-1, 사내 SSO
- 열린 질문: Q-1
- 출처: PRD v0.2.0 FR-1~3

## F-2 액션 아이템 추적
- 기능: 액션 생성·담당 지정, 다음 회고에서 완료 확인
- 대상 사용자: 개발팀 리드
- Why: G-2, S-2
- Success: 액션 완료율 60%
- Non-goals: 외부 이슈 트래커 연동
- 관련 제약·NFR: 사내 SSO
- 열린 질문: 없음
- 출처: PRD v0.2.0 FR-4~5

## F-3 카드 자동 그룹핑
- 기능: 비슷한 카드 자동 묶음 제안
- 대상 사용자: 개발팀 리드
- Why: G-1
- Success: 미확정
- Non-goals: 카드 내용 요약
- 관련 제약·NFR: NFR-1
- 열린 질문: 없음
- 출처: PRD v0.2.0 FR-6
