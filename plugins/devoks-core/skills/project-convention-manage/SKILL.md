---
name: project-convention-manage
description: 현재 프로젝트의 active convention을 점검하고, preset provenance 확인·diff·selective apply·재적용·스택 전환을 안전하게 수행한다.
---

# Project Convention Manage

## Overview

이 스킬은 현재 프로젝트의 `.claude/rules/project-convention.md`를 관리한다.
핵심 원칙은 **자동 overwrite 금지**이며, 항상 현황 파악 → diff 설명 → 사용자 확인 → 적용 순서를 따른다.

---

## SSOT

- 프로젝트 active convention: `.claude/rules/project-convention.md`
- preset provenance metadata: `.claude/project-convention.json`
- preset 원본: `shared/conventions/<preset>/project-convention.md`
- 프로젝트 사실 SSOT: `.claude/CLAUDE.md`

---

## 지원 작업

- 현재 convention이 어떤 preset 기반인지 확인
- current vs preset 차이 요약
- upstream preset 재적용
- selective apply (일부 섹션만 반영)
- React Web / React Native / Android / iOS / Custom 간 전환
- `.claude/CLAUDE.md`와 convention 사이의 stack drift 점검
- legacy convention이 bundled copy 잔재인지, 실제 프로젝트 커스터마이징인지 추정

---

## Steps

### 1. 현황 파악

먼저 아래를 읽는다.

- `.claude/project-convention.json`
- `.claude/rules/project-convention.md`
- `.claude/CLAUDE.md` (있으면)

metadata가 없으면 다음 순서로 추정하되, **확정으로 단정하지 않는다.**

1. 코드베이스 시그널 확인
2. 현재 convention 내용과 preset 유사도 비교
3. 사용자에게 provenance 확인 질문

### 2. 작업 유형 분류

사용자 요청을 아래 중 하나로 분류한다.

- **점검**: 현재 상태만 설명
- **재적용**: 같은 preset의 최신 내용을 반영
- **전환**: 다른 preset으로 변경
- **정리**: 현재 convention을 구조적으로 정돈
- **선택 반영**: 일부 섹션만 가져오기

### 3. drift / provenance 판단

아래를 먼저 요약한다.

- 현재 preset provenance 유무
- `CLAUDE.md`의 stack 사실과 active convention의 일치 여부
- active convention이 starter placeholder를 그대로 많이 포함하는지
- 로컬 커스터마이징이 어느 정도 누적됐는지

### 4. diff 제시

코드/문서 변경 전 반드시 아래를 요약한다.

- 바뀌는 섹션
- 유지되는 로컬 커스터마이징
- 제거/덮어쓰기 되는 내용
- `CLAUDE.md`와 충돌하는 항목
- placeholder가 새로 생기거나 여전히 남는 항목

#### selective apply 옵션

재적용/전환 시 아래 같은 단위로 선택 반영을 제안할 수 있다.

- Stack Declaration
- Core Rules
- Design Pattern
- Comments & Docs / Comment Rules
- Pitfalls
- Project Decisions

전체 재적용이 필요하지 않으면 일부 섹션만 반영하는 쪽을 우선 제안한다.

### 5. 사용자 확인 후 적용

적용 시 아래 원칙을 지킨다.

- `.claude/rules/project-convention.md`를 직접 덮어쓸 수 있는 작업은 반드시 사용자 확인 후에만 수행
- provenance metadata를 함께 갱신
- preset 전환 후에는 `.claude/CLAUDE.md`의 Tech Stack / Commands / Architecture / Sensitive Files도 drift 여부를 점검
- `Custom` 흐름은 가장 가까운 preset + 사용자 보정값으로 처리

### 6. 마무리 리포트

최종 리포트에는 아래를 포함한다.

- 적용한 preset / source
- 적용 모드 (`full apply` / `selective apply` / `switch` / `cleanup`)
- 유지한 로컬 커스터마이징
- 추가로 사용자가 채워야 할 placeholder
- 필요 시 다음 액션 (`CLAUDE.md` 보강, 테스트 스택 명시, UI guideline SSOT 연결 등)

---

## Rules

- preset은 시작점이지 프로젝트 절대 진실이 아니다.
- 프로젝트가 실제로 정착시킨 규칙을 존중한다.
- 감지 결과와 `.claude/CLAUDE.md` 사실이 충돌하면 사용자에게 확인한다.
- 대규모 재적용은 diff 요약 없이 바로 수행하지 않는다.
- 가능하면 full overwrite보다 selective apply를 먼저 검토한다.
