---
name: devoks:plan-author
description: 정련된 FRD.md를 받아 실행 가능한 PLAN.md(작업 분해)로 만든다. 요구사항을 단일·검증가능·증분 Task로 쪼개고, TASK-ID·`[P]` 병렬 마커·`file:`·`traces:`를 부여하며, PR 단위로 그룹핑하고 의존성 그래프와 Definition of Done을 작성한다. 모든 REQ/AC/CTR/EDGE가 traces로 커버되는지(누락 0) 검증한다. "FRD를 작업으로 분해해줘", "PLAN 짜줘", "태스크/PR 나눠줘", "스펙→태스크 분해", "작업 계획 세워줘" 같은 요청에서 사용한다. 분해 후 실행은 devoks:plan-executor, 전체 흐름은 devoks:feature-workflow-runner.
metadata:
  author: ridsync
  version: 1.0.0
---

# plan-author — PLAN 작성 (Phase 2)

FRD를 추적 가능하고 PR 단위로 분리된 작업 분해로 변환한다. `devoks:feature-workflow-runner` 의 **Phase 2만** 단독 실행한다.
공유 자산/레퍼런스는 통합 스킬 디렉터리를 참조한다(SSOT).

## 호출 방법

```
/devoks:plan-author [frd=<FRD.md 경로>] [out=<산출물 디렉터리>]
```

- `out` 기본값 = FRD.md가 있는 워크스페이스(`.claude/workspace/{feature-name}-{date}/`). 산출물 = `<out>/PLAN.md`. → `../devoks-feature-workflow-runner/references/output-location.md`
- PLAN은 워크스페이스에 저장하되, 각 Task의 `file:`은 항상 **프로젝트 본래 코드 위치**를 가리킨다(워크스페이스 아님).

## 절차

1. **골격 로드** — `../devoks-feature-workflow-runner/assets/PLAN.template.md` 형식을 따른다.
2. **Approach·Resource** — §1 구현 방식·PR 분리 방침, §2 Resource Check(FRD §6에서 가져옴).
3. **Task 분해** — 단일·검증가능·증분. 각 Task에 `TASK-ID`, (가능하면)`[P]`, `file:`, `traces:` 부여. → `../devoks-feature-workflow-runner/references/task-pr-splitting.md`
4. **PR 그룹핑** — 독립 가치/위험/리뷰 부담 기준으로 PR 묶기. PR 간 의존은 단방향.
5. **그래프·DoD** — §4 mermaid 의존성 그래프(사이클 금지), §5 Definition of Done.
6. **커버리지 검증(누락 0)** — FRD의 모든 `AC/CTR/EDGE`가 어떤 Task `traces`에 등장하는지 점검. → `../devoks-feature-workflow-runner/references/traceability.md` 의 comm 스크립트.
7. **작성** — 누락이 없을 때만 `<out>/PLAN.md` 작성. 있으면 담당 Task 추가 후 재검증.

## 완료 기준

- 모든 Task가 `file:`·`traces:`를 가짐, ID 규칙(`TASK-\d+`) 준수.
- `[P]` 가 의존성 그래프와 모순 없음(병렬 Task는 서로를 가리키지 않음).
- 1개 이상 PR생성. PR2개 이상일 경우 PR 그룹, PR 간 의존 단방향 준수.
- 커버리지 점검 출력 공백(누락 0), DoD 섹션 존재.

> 형식이 헷갈리면 `../devoks-feature-workflow-runner/references/example-walkthrough.md` 참고.
