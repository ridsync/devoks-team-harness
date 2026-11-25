# 진행 상태 추적 — PLAN이 SSOT

> "어디까지 했나"의 단일 진실원천은 **PLAN.md**다. 세션 도구(Todo/Task)는 그 미러일 뿐,
> 충돌 시 PLAN.md가 이긴다. 세션이 끊겨도 PLAN.md만 있으면 정확히 이어서 재개할 수 있다.

## 2계층 추적 모델

| 계층 | 위치 | 역할 | 수명 |
|------|------|------|------|
| **영속 상태** | `PLAN.md` 체크박스 + frontmatter `status` | 세션을 넘는 진행 SSOT | 작업 종료까지 유지 |
| **세션 상태** | TodoWrite / Task 도구 | 현재 세션의 in-progress 한눈 보기 | 세션 한정, 미러 |

## 승인 상태 전환 (FRD → PLAN)

Phase 경계에서 PLAN frontmatter `status`는 **자동**으로 갱신한다. **FRD는 예외다** — FRD의 `approved`는 사용자가 AC 리뷰 표(`ac-review.md`)를 명시 승인할 때만 Phase 1에서 붙는다. 승인 질문은 별도 프롬프트가 아니라 기존 "확정 후 문서 작성" 확인(절차 7)에 AC 표를 얹어서 받는다. 비-HITL·리뷰 보류는 `review`로 남고 Phase 2 착수 때 자동 승격하되 PLAN §1에 "FRD AC 사용자 미검토"를 남긴다(파이프라인은 막지 않는다).

| 문서 | 시점 | 전환 |
|------|------|------|
| **FRD.md** | Phase 1 완료 — `FRD.md` 작성 시 | HITL + AC 명시 승인 → `draft` → `approved` / 그 외 → `draft` → `review` |
| **FRD.md** | Phase 2 착수 — PLAN 작성 시작 시 | `review`이면 → `approved` (FRD 최종 상태, PLAN §1에 미검토 표기) |
| **PLAN.md** | Phase 2 완료 — `PLAN.md` 작성 시 | `draft` → `approved` |
| **PLAN.md** | Phase 3 첫 Task 착수 시 | `approved` → `in-progress` |
| **PLAN.md** | 모든 Task `[x]` + DoD 충족 시 | `in-progress` → `done` |

**보정 규칙**

- Phase 3(실행) 시작 시 PLAN `status`가 아직 `draft`이면 먼저 `approved`로 올린 뒤, 첫 Task 착수 시 `in-progress`로 전환한다.
- FRD `status`는 `approved`가 최종이다(`done` 사용 안 함).

## 제품 백로그(FEATURES.md) 상태 동기화

FRD frontmatter `feature:`(`<FEATURES.md 경로>#F-n` 또는 `#B-n`)가 있으면, 위 전환과 **같은 시점에** 그 백로그 행의 상태도 바꾼다. 상태 범례·칸 소유의 SSOT는 `../../product-prd-author/assets/FEATURES.template.md` "상태 범례"다.

| 시점 | FEATURES 행 상태 | 함께 바꾸는 칸 |
|------|------------------|----------------|
| `FRD.md` 작성 (Phase 1 완료) | `📝 frd` | FRD 열 = FRD.md 경로(저장소 루트 기준) |
| `PLAN.md` 작성 (Phase 2 완료) | `🗂️ plan` | — |
| 첫 Task 착수 (PLAN `in-progress`) | `🚧 in-progress` | — |
| PLAN `done` 전환 | `✅ done` | — |

- 고치는 것은 **그 행의 상태·FRD 칸과 frontmatter `updated`뿐**이다. 다른 열·행·§3 작업 순서·시드는 건드리지 않는다(소유 스킬 몫).
- **앞으로만 간다** — 이미 더 뒤 상태면 그대로 둔다(예: 진행 중 PLAN을 재계획해도 `in-progress` 유지). 행이 `🚫 dropped`면 고치지 않고 보고에 "dropped 항목에 대한 작업"을 남긴다.
- `feature:`가 없거나 경로·행을 찾지 못하면 건너뛰고 완료 보고에 한 줄 남긴다(추측해서 다른 행을 고치지 않는다).
- 구형식 FEATURES(이모지 없는 `frd` 등)는 구조를 바꾸지 않고 상태 칸만 고친다 — 표기도 그 파일의 기존 형식(키워드만)을 따른다. 새 구조로의 이전은 `product-prd-author` 갱신 모드에서 사용자가 요청할 때만 한다.

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
5. **라우팅은 마커 그대로** — 잔여 미완 Task가 3개 이하로 줄었더라도 남은 `size: M` Task는 위임을 유지한다. 직접 구현으로 전환하는 것은 공통 예외(① tools 밖 도구·② 사용자 명시 요청·③ 스펙 미완결)에 해당하거나 위임이 실제로 blocked로 실패한 경우에 한한다 — 잔여량은 `M`을 직접으로 뒤집는 근거가 아니다. → `task-delegation.md` "위임 손익분기"

## 동기화 원칙

- 한 Task의 상태를 두 계층에 동시에 적되, **PLAN 갱신을 최종 커밋 포인트**로 삼는다.
- 세션 도구만 완료로 두고 PLAN을 안 고치는 일이 없게 한다(재개 시 진행이 유실됨).
