---
run-id: <issue>-<YYYYMMDD>-<nn>
issue: <issue url>
adapter: <github|local>
branch: hotl/<issue>-<slug>
base: <base branch>
policy-version: trial-0.1.0
status: spec          # spec | spec-review | building | verifying | delivered | waiting-gate | rejected | failed
pending_gate:         # 대기 중인 게이트가 없으면 비운다
#  id: G-001
#  type: spec          # spec | action | exception
#  kind:               # action: delete|dependency|security-boundary|schema|ci-config|pii|scope-change / exception: spec-gap|severity-block|test-failure|env-gap|budget
#  opened_at: <ISO UTC>
#  checkpoint:         # 재개 지점(TASK-ID 또는 stage 이름)
---

# HOTL RUN <run-id>

## 위험 예측 (risk_forecast)
> spec 단계에서 PLAN Task별로 `policy.md` §2 승인 게이트 대상이 될 작업을 미리 적는다. 게이트1 리뷰어가 승인 범위를 판단한다.

| Task | kind | 내용 |
|---|---|---|

## 게이트 이력
| id | type/kind | 열림 | 응답(actor·시각) | 결정 요약 |
|---|---|---|---|---|

## 검증 게이트 결과 (gates)
| # | 게이트 | 결과 | 근거 |
|---|---|---|---|

## 인계 노트
> `upstream/task-delegation.md` 윈도잉 규칙(PR 그룹 내, 20줄 이하).

## 미확인·리스크
> 위임 리포트의 "미확인·리스크"를 모아 PR 본문에 옮긴다.

## 정책 이벤트
> 가드 차단(명령·사유), 게이트 개방, 상한 도달을 시간순으로 1줄씩.
