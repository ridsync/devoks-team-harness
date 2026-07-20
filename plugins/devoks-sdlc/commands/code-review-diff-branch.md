---
description: 현재 브랜치의 커밋 내역 기준 변경 코드를 리뷰한다.
---

# 코드리뷰 (브랜치 커밋 기준)

## Overview

현재 브랜치의 **커밋 내역**(base 브랜치 대비)을 기준으로 코드리뷰를 수행한다.

수집·검사·리뷰는 `code-reviewer` 에이전트에 위임하고, **리포트만** 돌려받는다.  
출력 형식은 `devoks-sdlc:code-review` 스킬을 따른다.

---

## Steps

### 1. 브랜치·커밋 범위 확보

1. **현재 브랜치 확인**
   - `git branch --show-current` 로 현재 브랜치 이름 확인
2. **Base 브랜치 결정**
   - 일반적으로 `main` 또는 `develop`. 없으면 사용자에게 물어본다.
   - `git rev-parse --verify main` 등으로 base 존재 여부 확인
3. **변경 범위 간략 확인**
   - `git log --oneline <base>..HEAD` 로 커밋 목록 확인
   - 커밋 메시지를 통해 변경 의도·범위를 파악

범위가 모호하거나 base 브랜치가 불명확하면 재질문한다.

### 2. code-reviewer 에이전트 호출

범위 확정 후 `code-reviewer` 에이전트를 아래 파라미터로 호출한다.

| 파라미터 | 값 |
|---------|-----|
| `mode` | `diff-branch` |
| `scope` | 1단계에서 확정한 base 브랜치 이름 |

> ⚠️ **이 단계는 Pass-through 전용이다.** 메인 에이전트는 subagent 리포트를 요약·압축·재작성·생략해서는 안 된다. 기본 brevity 설정과 무관하게, subagent가 반환한 리포트 전문을 **한 글자도 빠뜨리지 않고 그대로** 사용자에게 출력한다.

**금지:**
- 헤더·섹션 축약 (예: "잘된 점" 섹션 생략)
- 이슈 설명 단축 (문제·영향·재현/검증 방법·권장·후속 테스트 필요·위치 항목 축약)
- 표·리스트 구조 변경
- 자체 해석이나 추가 코멘트 삽입 (리포트 본문 앞뒤에 붙이는 것도 금지)

### 3. 수정 진행 여부 확인

리뷰 후 사용자에게 반영 범위를 확인한다.

- 전체 반영 / High 이상 / Medium 이상 / Low 이상 4가지 선택지와 제외할 사항을 기준으로 수정 진행한다.
- 각 결과에 따라 확인이 필요한 사항이나 추가 문의가 필요하면 사용자에게 먼저 질문하고 계획을 세운다.

---

## 참고

- **프로젝트 규칙**: `.claude/refs/` — `engineering-principles.md`, `code-review.md`, `git-convention.md`, `workflow.md` / `.claude/rules/` — `agent-principles.md`, 프로젝트 active convention `project-convention.md` (필요 시 `.claude/CLAUDE.md`로 stack 사실 확인)
