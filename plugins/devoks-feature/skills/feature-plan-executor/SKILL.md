---
description: PLAN.md(작업 분해)를 받아 각 태스크를 의존성 순서대로 단계 실행하고 진행 상태를 추적한다. 선행이 끝난 Task부터 구현 → 관련 테스트/린트 실행으로 검증 → PLAN 체크박스 `[x]`·frontmatter status 갱신. PLAN.md를 진행 SSOT로 삼아 세션이 끊겨도 재개 가능. "PLAN대로 진행해줘", "태스크 단계 실행", "작업 계획 따라 구현", "PLAN 체크리스트 진행", "다음 태스크 이어서" 같은 요청에서 사용한다. 구현 착수 전 `main`이면 작업 브랜치를 생성·체크아웃한다. 커밋·푸시·PR 생성은 하지 않는다(별도 도구·사용자 명시 요청). 전체 흐름은 devoks-feature:feature-workflow-runner.
metadata:
  author: ridsync
  version: 1.0.0
---

# plan-executor — 태스크 단계 실행 (Phase 3)

PLAN.md를 SSOT로 태스크를 의존성 순서대로 실행하고 진행을 추적한다. `devoks-feature:feature-workflow-runner` 의 **Phase 3만** 단독 실행한다.

## 범위 (중요)

- **한다:** 구현 착수 전 작업 브랜치 준비(`main`이면 작업 브랜치 생성·체크아웃), 구현, 관련 테스트/린트 실행, PLAN 체크박스·status 갱신, 진행 추적, 마무리 보고.
- **안 한다:** 커밋·푸시·PR 생성, 다른 커맨드(git-* 등) 오케스트레이션. PR 경계는 *기록만* 한다.

## 호출 방법

```
/devoks-feature:feature-plan-executor [plan=<PLAN.md 경로>] [pr=<특정 PR 그룹만>] [task=<특정 TASK-ID만>]
```

- `plan` 없으면 가장 최근 `.claude/workspace/*/PLAN.md` 를 후보로 제시·확인한다. → `../feature-workflow-runner/references/output-location.md`
- **코드는 PLAN Task의 `file:`(프로젝트 본래 위치)에 작성**한다. 워크스페이스에는 문서(진행 보고 등)만, 코드는 두지 않는다.

## 절차

1. **상태 로드** — PLAN.md를 읽어 `[x]`/`[ ]` Task와 §4 의존성 그래프를 파악. 세션 Task/Todo를 PLAN 상태에 맞춘다. → `../feature-workflow-runner/references/progress-tracking.md`
2. **다음 Task 선택** — **선행이 모두 `[x]`인 미완 Task**를 고른다. `[P]` Task는 함께 진행 가능. (`pr`/`task` 인자 있으면 그 범위로 한정.)
3. **작업 브랜치 준비 (최초 1회)** — 첫 구현 착수 **직전**에 현재 브랜치를 확인한다. `main`(원격 기본 브랜치)이면 작업 목적을 담은 의미론적 이름의 로컬 브랜치를 만들고 체크아웃한 뒤 진행한다. `main`이 아니면(이미 작업 브랜치) 새로 만들지 않고 "이 브랜치에서 진행" 여부만 한 줄로 확인 후 진행한다.
   - **타입**: `feat`·`fix`·`docs`·`style`·`refactor`·`perf`·`test`·`build`·`ci`·`chore` 중 작업 성격에 가장 가까운 것 (Conventional Commits — `devoks-git:git-commit-msg` 규칙).
   - **이름 패턴**: `타입/간단-슬러그` — 슬러그는 **kebab-case**·짧게. 이슈·티켓 번호가 있으면 `타입/번호-슬러그` (예: `feat/128-partner-etc-page`, `fix/mqtt-reconnect-race`).
   - **기준 브랜치**: 원격 기본 브랜치(`main`) 현재 상태 기준으로 분기(`git checkout -b …` 등 저장소 관례에 맞게).
   - **범위**: 브랜치 생성·체크아웃까지만. **커밋·푸시·PR**은 하지 않는다(사용자 명시 요청 시 별도 도구).
4. **구현** — 관련 코드를 먼저 읽고(읽기 전 변경 금지), 기존 유틸/훅/패턴을 재사용해 구현. 프로젝트 규칙(`.claude/rules/` 등)이 있으면 따른다.
5. **검증** — 관련 테스트/린트 실행. 로직 Task는 테스트를 동반하고, 테스트 설명에 AC ID를 박아 추적 연결.
6. **진행 갱신** — **검증 통과 후에만** PLAN `- [ ]` → `- [x]`, 첫 착수 시 frontmatter `status: in-progress`. 실패·미완이면 `[x]`로 바꾸지 않고 막힌 이유 명시.
7. **반복** — 다음 Task로(구현 단계부터). 모든 Task 완료 시 마무리(아래).

## 마무리

- DoD 각 항목 점검 후 `[x]`: 커버리지 누락 0 재점검(`../feature-workflow-runner/references/traceability.md`), 핵심 테스트 통과 확인, Edge case 확인.
- 모든 Task `[x]` + DoD 충족 시 `status: done`.
- 미완 Task·임시 코드·추후 작업(커밋/PR 포함)을 명시적으로 보고(은폐 금지).

## 재개

세션이 끊겼다 다시 시작해도 PLAN.md의 체크박스·status가 SSOT이므로, 1단계만 다시 수행하면 정확히 이어서 진행한다.
