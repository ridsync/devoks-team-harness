---
name: code-review
description: code-reviewer 에이전트가 호출하는 코드리뷰 실행 엔진. mode(general|diff-branch)와 scope를 입력받아 코드 수집 → 자동화 선행검증 → C.L.E.A.R./Layered/Checklist/심각도 분류 리뷰 → 포맷된 리포트 생성까지 수행한다. 메인 루프에서 직접 실행하지 않고 code-reviewer 에이전트를 통해서만 사용한다.
metadata:
  author: ridsync
  version: 1.0.0
---

# code-review — 리뷰 실행 엔진

**호출 주체:** `code-reviewer` 에이전트 (subagent 안에서 실행)  
**메인 루프 직접 호출 금지** — 커맨드에서 직접 사용하지 않는다.

---

## 입력 파라미터

| 파라미터 | 타입 | 설명 |
|---------|------|------|
| `mode` | `general` \| `diff-branch` | 리뷰 방식 |
| `scope` | 파일/폴더 경로 (`general`) 또는 base 브랜치 이름 (`diff-branch`) | 커맨드에서 이미 확정된 리뷰 대상 |

---

## Steps

### 1. 코드 수집

**mode=general**
- 지정된 scope(파일/폴더 경로)의 파일을 읽는다.
- 동작 이해에 필요한 **직접 의존 코드만** 최소 범위로 추가 확인한다.

**mode=diff-branch**
- 현재 브랜치와 base를 확인하고 변경 파일·diff를 수집한다:
  ```bash
  git branch --show-current
  git log --oneline <base>..HEAD
  git diff <base>...HEAD --name-only
  git diff <base>...HEAD
  ```
- diff를 기준으로 **실제 변경된 부분만** 집중 검토한다.
- diff 파일이 5개 이상이거나 변경 줄이 300줄 초과 시 레이어(구조 → 로직 → 보안) 또는 파일 단위로 분할 순차 검토한다.

### 2. 자동화 도구 선행 검증

수동 리뷰 전에 최소 품질 게이트를 먼저 확인한다.

- **Lint/Format**: ESLint + Prettier 결과를 먼저 확인한다. **lint 오류가 있는 상태로 리뷰 진행 금지.**
- **타입 검사**: TypeScript 컴파일 오류 없음을 확인한다.
- 자동화 도구 통과 여부를 리포트 `📋 리뷰 대상` 헤더에 명시한다.

### 3. 리뷰 가이드 적용

`.claude/refs/code-review.md`의 C.L.E.A.R., Layered Examination, Component Type Checklists, Severity Classification(§8)을 기준으로 리뷰를 수행한다.

### 4. 리포트 작성

아래 출력 템플릿으로 작성한다.  
**템플릿에 포함된 이모지(📋 🧭 ✅ ⚠️ ❌ 🔍 🔴 🟠 🟡 🔵 📊 🚀)를 반드시 그대로 포함하여 출력한다.**  
심각도 분류 및 이슈 형식은 `.claude/refs/code-review.md §8`을 따른다.

`📋 리뷰 대상` 헤더는 **mode별로 분기**한다 (아래 출력 템플릿 참조).

---

## 출력 템플릿

```markdown
## 📋 리뷰 대상

<!-- mode=general 시 -->
- 범위: [파일/폴더 경로]
- 목적: [로직 / 버그 / 리팩토링 등]
- 자동화 검사: Lint/Format [통과/실패], Type Check [통과/실패]
- 제외:

<!-- mode=diff-branch 시 -->
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

## 참고 기준 문서

- **리뷰 기준 SSOT**: `.claude/refs/code-review.md` (C.L.E.A.R. / Layered / Checklists / §8 Severity)
- **프로젝트 규칙**: `.claude/refs/engineering-principles.md`, `.claude/rules/project-convention.md`
