# 진행 상태 추적 — PLAN이 SSOT

> "어디까지 했나"의 단일 진실원천은 **PLAN.md**다. 세션 도구(Todo/Task)는 그 미러일 뿐,
> 충돌 시 PLAN.md가 이긴다. 세션이 끊겨도 PLAN.md만 있으면 정확히 이어서 재개할 수 있다.

## 2계층 추적 모델

| 계층 | 위치 | 역할 | 수명 |
|------|------|------|------|
| **영속 상태** | `PLAN.md` 체크박스 + frontmatter `status` | 세션을 넘는 진행 SSOT | 작업 종료까지 유지 |
| **세션 상태** | TodoWrite / Task 도구 | 현재 세션의 in-progress 한눈 보기 | 세션 한정, 미러 |

## 승인 상태 전환 (FRD → PLAN)

Phase 경계에서 FRD·PLAN frontmatter `status`를 **자동**으로 갱신한다. 별도 확인 프롬프트는 추가하지 않는다(기존 "확정 후 문서 작성" 절차에 편승).

| 문서 | 시점 | 전환 |
|------|------|------|
| **FRD.md** | Phase 1 완료 — `FRD.md` 작성 시 | `draft` → `review` |
| **FRD.md** | Phase 2 착수 — PLAN 작성 시작 시 | `review` → `approved` (FRD 최종 상태) |
| **PLAN.md** | Phase 2 완료 — `PLAN.md` 작성 시 | `draft` → `approved` |
| **PLAN.md** | Phase 3 첫 Task 착수 시 | `approved` → `in-progress` |
| **PLAN.md** | 모든 Task `[x]` + DoD 충족 시 | `in-progress` → `done` |

**보정 규칙**

- Phase 3(실행) 시작 시 PLAN `status`가 아직 `draft`이면 먼저 `approved`로 올린 뒤, 첫 Task 착수 시 `in-progress`로 전환한다.
- FRD `status`는 `approved`가 최종이다(`done` 사용 안 함).

## PLAN.md 갱신 규칙

- Task **착수 시**: 세션 도구에서 해당 항목을 in_progress로. PLAN 체크박스는 아직 `[ ]`.
- Task **완료 시(검증 통과 후에만)**: PLAN의 `- [ ]` → `- [x]` 로 바꾸고, 같은 줄/직후에 근거를 한 줄 남겨도 좋다.
  - 예: `- [x] TASK-002 ... — traces: CTR-001 ✓(test pass)`
- **부분 완료 금지**: 테스트 실패·구현 미완·미해결 에러가 있으면 `[x]` 로 바꾸지 않는다(in_progress 유지).
- frontmatter `status`: 첫 Task 착수 시 `approved` → `in-progress`(아직 `draft`이면 먼저 `approved`로 보정), 모든 Task `[x]` + DoD 충족 시 `done`.

## DoD 체크박스도 함께 갱신

PLAN §5 Definition of Done의 각 항목도 충족될 때 `[x]` 로 바꾼다. 특히:
- "모든 REQ/AC/CTR/EDGE 커버" → `traceability.md`의 comm 점검으로 누락 0 확인 후 체크.
- "핵심 로직 테스트 통과" → 실제 테스트 실행 출력으로 확인 후 체크.

## 재개(Resume) 절차

세션이 끊긴 뒤 다시 시작할 때:
1. PLAN.md를 읽어 `[x]`(완료) / `[ ]`(미완) Task를 식별.
2. frontmatter `status`와 DoD 체크 상태 확인.
3. 의존성 그래프에서 "선행이 모두 `[x]`인 미완 Task" 중 다음 것을 고른다.
4. 세션 도구(Todo/Task)를 PLAN 상태에 맞춰 다시 구성.

## 동기화 원칙

- 한 Task의 상태를 두 계층에 동시에 적되, **PLAN 갱신을 최종 커밋 포인트**로 삼는다.
- 세션 도구만 완료로 두고 PLAN을 안 고치는 일이 없게 한다(재개 시 진행이 유실됨).
