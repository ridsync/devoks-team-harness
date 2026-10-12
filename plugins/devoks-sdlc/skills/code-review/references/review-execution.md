# review-execution — 코드리뷰 실행 절차 (엔진 SSOT)

**호출 주체:** `code-reviewer` 에이전트 (subagent 안에서 실행).
진입 스킬(`devoks-sdlc:code-review`)의 Phase 0에서 `mode`·`scope`가 이미 확정된 상태를 전제한다 —
이 문서 안에서 범위 모호성을 다시 확인하지 않는다.

리포트 출력 형식은 `report-template.md`(같은 디렉토리)가 SSOT다.

---

## 입력 파라미터

| 파라미터 | 타입 | 설명 |
|---------|------|------|
| `mode` | `general` \| `diff-branch` | 리뷰 방식 |
| `scope` | 파일/폴더 경로 (`general`) 또는 base 브랜치 이름 (`diff-branch`) | 이미 확정된 리뷰 대상 |

---

## 1. 코드 수집

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

## 2. 자동화 도구 선행 검증

수동 리뷰 전에 최소 품질 게이트를 먼저 확인한다.

- **Lint/Format**: 프로젝트의 lint/format 도구 결과를 먼저 확인한다.
- **타입 검사**: 프로젝트의 타입 검사 도구가 있다면 컴파일 오류 없음을 확인한다.
- 자동화 도구 통과 여부를 리포트 `📋 리뷰 대상` 헤더에 명시한다.
- **실패 시에도 리뷰를 중단하지 않는다** — 이 에이전트는 코드 수정·사용자 질문이 금지라 게이트를 스스로 해소할 수 없다. 대신:
  - 헤더에 `실패`와 오류 개수·대표 1~3건(`file:line` + 원문 메시지)을 기록한다.
  - 타입/컴파일 오류는 **High**로 주요 이슈에 올린다. lint 오류는 규칙 성격에 따라 §8로 분류하되, lint가 이미 잡는 스타일 지적을 수동 리뷰에서 중복 기재하지 않는다.
  - `🚀 다음 액션 제안`의 `즉시:`에 "lint/type 해소 후 재리뷰"를 명시한다.

## 3. 리뷰 가이드 적용

`.claude/refs/code-review.md`의 C.L.E.A.R., Layered Examination, Component Type Checklists, Severity Classification(§8)을 기준으로 리뷰를 수행한다.

**필수 체크리스트 (5개 항목 — 리뷰 중 하나도 빠뜨리지 않는다):**
- [ ] 잠재적 버그는 없는가?
- [ ] 예외 처리가 빠진 곳은 없는가?
- [ ] 성능상 문제는 없는가?
- [ ] 더 읽기 좋은 코드가 있는가?
- [ ] 보안상 위험은 없는가?

각 항목에서 발견된 이슈는 리포트 "주요 이슈" 섹션에 심각도별로 기록하고, 항목별 확인 결과는 "체크리스트 커버리지" 섹션에 남긴다.

## 4. 리포트 작성

`report-template.md`의 출력 템플릿으로 작성한다.
`📋 리뷰 대상` 헤더는 **mode별로 분기**한다(템플릿의 주석 참고).

**보안 이슈 에스컬레이션:** `🔒 보안 점검 요약`에서 Critical/High급 보안 이슈가 하나라도 발견되면, `🚀 다음 액션 제안`의 `즉시:` 항목에 `/devoks-sdlc:code-security-review` 실행을 권장 문구로 명시한다. 이 리뷰는 diff/scope 한정 경량 스크리닝이라 repo 전수·의존성 취약점·위협 모델링은 다루지 않으므로, 발견된 문제의 실제 파급 범위는 전용 심층 검증으로 확인해야 한다.

---

## 참고 기준 문서

- **리뷰 기준 SSOT**: `.claude/refs/code-review.md` (C.L.E.A.R. / Layered / Checklists / §8 Severity)
- **프로젝트 규칙**: `.claude/refs/engineering-principles.md`, `.claude/refs/interaction-integrity.md`, `.claude/refs/git-convention.md`, `.claude/refs/workflow.md` / `.claude/rules/agent-principles.md`, 프로젝트 active convention `.claude/rules/project-convention.md` (필요 시 `.claude/CLAUDE.md`로 stack 사실 확인)
