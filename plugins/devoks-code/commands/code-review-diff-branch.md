---
description: 현재 브랜치의 커밋 내역 기준 변경 코드를 리뷰한다.
---

# 코드리뷰 (브랜치 커밋 기준)

## Overview

현재 브랜치의 **커밋 내역**(base 브랜치 대비)을 기준으로 변경된 코드를 수집하고,
`.claude/refs/code-review.md`를 SSOT로 참조해 코드리뷰를 수행한다.

---

## Steps

### 1. 브랜치·커밋 범위 확보

1. **현재 브랜치 확인**
   - `git branch --show-current` 로 현재 브랜치 이름 확인
2. **Base 브랜치 결정**
   - 일반적으로 `main` 또는 `develop`. 없으면 사용자에게 물어본다.
   - `git rev-parse --verify main` 등으로 base 존재 여부 확인
3. **커밋 목록 조회**
   - `git log --oneline <base>..HEAD` 로 현재 브랜치에만 있는 커밋 목록 확인
   - 커밋 메시지를 통해 변경 의도·범위를 파악
4. **변경 파일·diff 확보**
   - `git diff <base>...HEAD --name-only` 로 변경된 파일 목록
   - `git diff <base>...HEAD` 로 전체 diff 확인 (필요 시 `-- packages/` 등 경로 제한)
   - 리뷰 시 **실제 변경된 부분만** 집중할 수 있도록 diff를 기준으로 검토

### 2. 리뷰 전 준비 체크

- [ ] 커밋 메시지·PR/이슈로 원본 요구사항 또는 변경 목적을 확인했다.
- [ ] 변경된 파일 목록과 의존 관계를 파악했다.
- [ ] 이 변경이 시스템(아키텍처·기존 모듈)에서 차지하는 위치를 이해했다.
- [ ] 외부 유입 코드(서드파티·외부 기여)가 포함된 경우, 격리 검토 대상으로 표시했다.

### 3. 자동화 도구 선행 검증

수동 리뷰 전에 최소 품질 게이트를 먼저 확인한다.

- **Lint/Format**: ESLint + Prettier 결과를 먼저 확인한다. lint 오류가 있는 상태로 리뷰 진행 금지.
- **타입 검사**: TypeScript 컴파일 오류 없음을 확인한다.
- 자동화 도구 통과 여부를 리뷰 대상 헤더에 명시한다.

### 4. 리뷰 가이드 적용

`.claude/refs/code-review.md`의 C.L.E.A.R., Layered Examination, Component Type Checklists, Severity Classification을 기준으로 리뷰를 수행한다.

### 5. 리뷰 결과 정리

아래 출력 템플릿으로 작성한다. 
**템플릿에 포함된 이모지(📋 🧭 ✅ ⚠️ ❌ 🔍 🔴 🟠 🟡 🔵 📊 🚀)를 반드시 그대로 포함하여 출력한다.**
심각도 분류 및 이슈 형식은 `.claude/refs/code-review.md §8`을 따른다.

1. **요약** — 리뷰 범위(브랜치, base 대비 커밋 수, 변경 파일 수) 및 전체 평가
2. **C.L.E.A.R. 요약**
3. **주요 이슈** — Critical → High → Medium → Low 심각도 순
4. **다음 액션 제안**
5. **잘된 점**

### 6. 수정 진행 여부 확인

리뷰 후 사용자에게 반영 범위를 확인한다.

- 전체 반영 / High 이상 / Medium 이상 / Low 이상 4가지 선택지와 제외할 사항을 기준으로 수정 진행한다.
- 각 결과에 따라 확인이 필요한 사항이나 추가 문의가 필요하면 사용자에게 먼저 질문하고 계획을 세운다.

---

## 출력 템플릿

```markdown
## 📋 리뷰 대상
- 브랜치: feat/xxx → main
- 커밋 수: N개
- 변경 파일: N개
- 자동화 검사: Lint/Format [통과/실패], Type Check [통과/실패]
- 제외:

## 🧭 전체 평가
- 결과: ✅ 통과 / ⚠️ 조건부 / ❌ 개선 필요
- 한줄 요약:

## ✅ 잘된 점

1.
2.

## 🔍 C.L.E.A.R. 요약
- **C** Context:
- **L** Layered:
- **E** Explicit:
- **A** Alternative:
- **R** Refactoring:

## 🔒 보안 점검 요약
- 외부 입력값 검증: ✅ / ⚠️ / ❌
- SQL 인젝션 위험: ✅ / ⚠️ / ❌
- XSS 위험: ✅ / ⚠️ / ❌
- 하드코딩 자격증명: ✅ / ⚠️ / ❌
- 인증·인가 우회 가능성: ✅ / ⚠️ / ❌
- 자동화 도구(Lint/TS) 통과: ✅ / ❌

---

## 🔍 주요 이슈 (심각도 순)

## 🔴 Critical (머지 차단)

### 1. [이슈 제목]
- 문제:
- 영향:
- 권장:
- 위치: `파일명.jsx:라인번호`

---

## 🟠 High (필수 수정)

### 2. [이슈 제목]
- 문제:
- 영향:
- 권장:
- 위치: `파일명.jsx:라인번호`

---

## 🟡 Medium (권장 수정)

### 3. [이슈 제목]
- 문제:
- 권장:
- 위치: `파일명.jsx:라인번호`

---

## 🔵 Low (선택 개선)

### 4. [이슈 제목]
- 문제:
- 권장:
- 위치: `파일명.jsx:라인번호`

## 📊 이슈 요약

| 심각도 | 개수 | 조치 |
|--------|------|------|
| 🔴 Critical | N | 머지 차단 |
| 🟠 High | N | 필수 수정 |
| 🟡 Medium | N | 권장 수정 |
| 🔵 Low | N | 선택 |

---

## 🚀 다음 액션 제안
- 즉시:
- 다음 배치:
- 보류:
```

---

## 참고

- **프로젝트 규칙**: `.claude/refs/` — `engineering-principles.md`, `code-review.md`, `git-convention.md`, `workflow.md` / `.claude/rules/` — `agent-principles.md`, `project-convention.md` (필요 시 `.claude/CLAUDE.md` 참고)
