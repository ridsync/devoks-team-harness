---
description: PLAN.md(작업 분해)를 받아 각 태스크를 의존성 순서대로 단계 실행하고 진행 상태를 추적한다. 선행이 끝난 Task부터 `size` 마커로 라우팅해(S 직접·M 위임·L 분해 재검토) code-implementer 에이전트에 구현·검증을 위임(기본 경로) → done 리포트의 검증 근거·인계 노트 확인 → PLAN 체크박스 `[x]`·frontmatter status 갱신. PLAN.md를 진행 SSOT로 삼아 세션이 끊겨도 재개 가능. "PLAN대로 진행해줘", "태스크 단계 실행", "작업 계획 따라 구현", "PLAN 체크리스트 진행", "다음 태스크 이어서" 같은 요청에서 사용한다. 구현 착수 전 브랜치·이슈 사전체크(제안→확인→적용)를 수행한다. 커밋·푸시·PR 생성은 하지 않는다(별도 도구·사용자 명시 요청). 전체 흐름은 devoks-sdlc:feature-workflow-runner.
metadata:
  author: ridsync
  version: 1.2.0
---

# plan-executor — 태스크 단계 실행 (Phase 3)

PLAN.md를 SSOT로 태스크를 의존성 순서대로 실행하고 진행을 추적한다. `devoks-sdlc:feature-workflow-runner` 의 **Phase 3만** 단독 실행한다.

## 범위 (중요)

- **한다:** 구현 착수 전 브랜치·이슈 사전체크(제안→확인→적용), 태스크의 `size` 라우팅(S 직접/M 위임/L 분해 재검토)과 `code-implementer` 위임(기본 경로), 리포트 판정·인계 노트 윈도잉, PLAN 체크박스·status 갱신, 진행 추적, 마무리 보고. → `../feature-workflow-runner/references/branch-issue-precheck.md`, `../feature-workflow-runner/references/task-delegation.md`
- **안 한다:** 커밋·푸시·PR 생성, 다른 커맨드(git-* 등) 오케스트레이션. PR 경계는 *기록만* 한다.

## 호출 방법

```
/devoks-sdlc:feature-plan-executor [plan=<PLAN.md 경로>] [pr=<특정 PR 그룹만>] [task=<특정 TASK-ID만>]
```

- `plan` 없으면 가장 최근 `.claude/workspace/*/PLAN.md` 를 후보로 제시·확인한다. → `../feature-workflow-runner/references/output-location.md`
- **코드는 PLAN Task의 `file:`(프로젝트 본래 위치)에 작성**한다. 워크스페이스에는 문서(진행 보고 등)만, 코드는 두지 않는다.

## 절차

1. **상태 로드** — PLAN.md를 읽어 `[x]`/`[ ]` Task와 §4 의존성 그래프를 파악. 세션 Task/Todo를 PLAN 상태에 맞춘다. PLAN `status`가 아직 `draft`이면 `approved`로 보정. → `../feature-workflow-runner/references/progress-tracking.md`
2. **다음 Task 선택** — **선행이 모두 `[x]`인 미완 Task**를 고른다. `[P]` Task는 함께 진행 가능. (`pr`/`task` 인자 있으면 그 범위로 한정.)
3. **브랜치·이슈 사전체크 (최초 1회)** — 첫 구현 착수 **직전**에 현재 브랜치·연결 이슈를 확인하고, 브랜치명·이슈 초안을 제안한 뒤 사용자 확인 후 적용한다(모드 `full`). → `../feature-workflow-runner/references/branch-issue-precheck.md`
4. **라우팅 → 구현·검증** — Task의 `size` 마커를 기계적으로 적용한다: `S`는 메인 루프 직접, `M`(및 마커 없음)은 `code-implementer` 위임(기본 경로), `L`은 분해 재검토(못 쪼개면 직접), 공통 예외(③ 스펙 미완결·① tools 밖 도구·② 사용자 직접 요청)는 직접. 위임 전 공통 예외 ③(스펙 미완결)을 점검한다. 위임 시 Task 블록 원문·`plan`·`frd` 경로·`context`(인계 노트 윈도잉 적용)를 주입하면, 에이전트가 코드 읽기→기존 패턴 재사용 구현→테스트/린트 검증까지 수행하고 done|blocked 리포트를 리턴한다. **한 번에 한 태스크만**(`[P]`는 선택 순서의 자유일 뿐 동시 fan-out 아님). → `../feature-workflow-runner/references/task-delegation.md`
5. **리포트 처리** — `done`이면 검증 근거(실행 명령·**종료코드**·출력 **tail 1줄 원문**·로직 Task 시 테스트 파일·케이스명)를 확인하고(네 가지 중 하나라도 빠지면 done 아님; 의심 시 동일 명령 재실행) **인계 노트를 윈도잉 규칙에 맞게 수집해 다음 위임의 `context`에 주입**한다. `blocked`이면 스펙 문제는 사용자 확인 후 결정을 `context`에 덧붙여 재위임, 기계적 문제는 직접 해소 후 재위임, 스코프 초과(사실상 `L`)는 메인 루프가 인수하거나 재분해.
6. **진행 갱신 (메인 루프가 수행)** — **검증 근거(명령·종료코드·tail 1줄 원문) 확인 후에만** PLAN `- [ ]` → `- [x]`, 첫 착수 시 frontmatter `status: approved → in-progress`. 실패·blocked이면 `[x]`로 바꾸지 않고 막힌 이유 명시. 에이전트는 PLAN·FRD를 수정하지 않는다.
7. **반복** — 다음 Task로(위임 단계부터). 모든 Task 완료 시 마무리(아래).

## 마무리

- DoD 각 항목 점검 후 `[x]`: 커버리지 누락 0 재점검(`../feature-workflow-runner/references/traceability.md`), 핵심 테스트 통과 확인, Edge case 확인.
- 모든 Task `[x]` + DoD 충족 시 `status: done`.
- 미완 Task·임시 코드·추후 작업(커밋/PR 포함)을 명시적으로 보고(은폐 금지).

## 재개

세션이 끊겼다 다시 시작해도 PLAN.md의 체크박스·status가 SSOT이므로, 1단계만 다시 수행하면 정확히 이어서 진행한다.
