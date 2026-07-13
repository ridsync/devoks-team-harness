---
description: code-reviewer 에이전트가 호출하는 코드리뷰 실행 엔진. mode(general|diff-branch)와 scope를 입력받아 코드 수집 → 자동화 선행검증 → C.L.E.A.R./Layered/보안 delta/심각도 분류 리뷰 → 증거 기반 리포트 생성까지 수행한다. 메인 루프에서 직접 실행하지 않고 code-reviewer 에이전트를 통해서만 사용한다.
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
- 본 리뷰 전 아래를 확인한다.
  - [ ] 커밋 메시지·PR/이슈로 원본 요구사항 또는 변경 목적을 확인했다.
  - [ ] 변경된 파일 목록과 의존 관계를 파악했다.
  - [ ] 이 변경이 시스템(아키텍처·기존 모듈)에서 차지하는 위치를 이해했다.
  - [ ] 외부 유입 코드(서드파티·외부 기여)가 포함된 경우, 격리 검토 대상으로 표시했다.

### 2. 자동화 도구 선행 검증

수동 리뷰 전에 최소 품질 게이트를 먼저 확인한다.

- **Lint/Format**: ESLint + Prettier 결과를 먼저 확인한다. **lint 오류가 있는 상태로 리뷰 진행 금지.**
- **타입 검사**: TypeScript 컴파일 오류 없음을 확인한다.
- 프로젝트의 실제 명령을 우선하며 도구 설치나 설정 변경은 하지 않는다.
- 실행 불가 항목은 실패로 꾸미거나 통과로 간주하지 않고 `not-run`과 사유를 기록한다.
- 자동화 도구 상태를 `pass` / `fail` / `not-run` / `not-applicable` 중 하나로 리포트 `📋 리뷰 대상` 헤더에 명시한다.

### 3. 리뷰 가이드 적용

`.claude/refs/code-review.md`의 C.L.E.A.R., Layered Examination, Component Type Checklists, Severity Classification(§8)을 기준으로 리뷰를 수행한다.

모든 리뷰에서 아래 5축을 각각 확인하고 근거를 남긴다. 하나의 일반 평가로 합쳐 생략하지 않는다.

1. 잠재적 버그는 없는가?
2. 예외 처리가 빠진 곳은 없는가?
3. 성능상 문제는 없는가?
4. 보안상 위험은 없는가?
5. 더 읽기 좋은 코드가 있는가?

보안 레이어에서는 `.claude/refs/security-engineering.md`의 PR diff gate를 함께 적용한다.

1. 인증·인가·세션·raw HTML·URL/redirect·server action/API/DB·파일·CORS/CSP·dependency/CI 변경 여부를 분류한다.
2. 관련 변경은 source → validation/transform → trust boundary → sink를 추적한다.
3. 자동화 결과가 아니라 실제 도달 가능성과 보완 통제를 확인한다.
4. scope 밖 코드나 배포 설정이 있어 결론을 낼 수 없으면 `확인 필요`로 쓰고 targeted `code-security-review` 승격을 제안한다.

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
- 자동화 검사: Lint/Format [pass/fail/not-run/not-applicable], Type Check [pass/fail/not-run/not-applicable]
- 제외:

<!-- mode=diff-branch 시 -->
- 브랜치: feat/xxx → main
- 커밋 수: N개
- 변경 파일: N개
- 자동화 검사: Lint/Format [pass/fail/not-run/not-applicable], Type Check [pass/fail/not-run/not-applicable]
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

## 🧩 필수 5축 점검
| 축 | 상태 | 핵심 근거 |
|----|------|-----------|
| 잠재적 버그 | ✅/⚠️/❌ | |
| 예외 처리 누락 | ✅/⚠️/❌ | |
| 성능 문제 | ✅/⚠️/❌ | |
| 보안 위험 | ✅/⚠️/❌ | |
| 가독성 개선 | ✅/⚠️/❌ | |

## 🔒 보안 점검 요약
- 고위험 변경 트리거: [없음 / 항목 목록]
- 서버 인증·객체별 인가: ✅ / ⚠️ / ❌ / 해당 없음
- 입력 → trust boundary → sink: ✅ / ⚠️ / ❌ / 해당 없음
- 브라우저·세션(XSS/URL/storage/CSRF/CSP): ✅ / ⚠️ / ❌ / 해당 없음
- secret·민감 데이터·로그: ✅ / ⚠️ / ❌ / 해당 없음
- dependency·build·CI 구성: ✅ / ⚠️ / ❌ / 해당 없음
- 전용 보안 리뷰 승격: [불필요 / 필요 — 이유]

---

## 🔍 주요 이슈 (심각도 순)

각 finding은 아래 필드를 모두 포함한다.

- Rule/CWE: [해당 시]
- 문제:
- 증거·영향:
- 재현/검증:
- Confidence: High / Medium / Low
- 권장:
- 후속 테스트:
- 위치: `파일명.jsx:라인번호`

## 🔴 Critical (머지 차단)

### 1. [이슈 제목]

---

## 🟠 High (필수 수정)

### 2. [이슈 제목]

---

## 🟡 Medium (권장 수정)

### 3. [이슈 제목]

---

## 🔵 Low (선택 개선)

### 4. [이슈 제목]

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
- **보안 기준 SSOT**: `.claude/refs/security-engineering.md` (PR diff gate / evidence contract / escalation)
- **프로젝트 규칙**: `.claude/refs/engineering-principles.md`, 프로젝트 active convention `.claude/rules/project-convention.md`, 프로젝트 사실 SSOT `.claude/CLAUDE.md`
