---
description: "코드리뷰를 수행한다. 브랜치 커밋 범위(base 대비 diff) 또는 사용자가 지정한 파일/폴더/모듈 범위 중 하나를 대상으로, 자동화 선행검증(lint·type) → C.L.E.A.R./Layered/체크리스트 리뷰 → 심각도별(Critical/High/Medium/Low) 리포트까지 낸다. \"코드리뷰\", \"코드 리뷰 해줘\", \"변경사항 리뷰\", \"브랜치 리뷰\", \"PR 리뷰\", \"이 파일 리뷰해줘\", \"review this code\" 요청에서 사용한다. repo 전수·의존성 취약점·위협 모델링이 필요한 심층 보안 검증은 devoks-sdlc:code-security-review, 요구사항 충족 판정은 devoks-sdlc:verify-requirements 를 쓴다."
argument-hint: "[mode=general|diff-branch (default: 브랜치 추론)] [scope=<파일/폴더 경로>] [base=<브랜치> (default: main/develop)]"
metadata:
  author: ridsync
  version: 2.0.0
---

# code-review — 코드리뷰

코드리뷰를 두 가지 범위 중 하나로 수행한다.

| mode | 대상 | 쓰는 때 |
|------|------|--------|
| `diff-branch` | 현재 브랜치의 커밋 내역(base 브랜치 대비 diff) | 구현 후 검증 체인 2단계 — 이번 변경만 보고 싶을 때 |
| `general` | 사용자가 지정한 파일/폴더/모듈/프로젝트 범위 | 변경 여부와 무관하게 특정 코드를 보고 싶을 때 |

수집·검사·리뷰 실행은 `code-reviewer` 에이전트에 위임하고 **리포트만** 돌려받는다 — 파일 읽기·diff·lint 출력이
메인 대화 컨텍스트에 적재되지 않도록 격리한다.

---

## 호출 방법

```
/devoks-sdlc:code-review [mode=general|diff-branch (default: 브랜치 추론)] [scope=<파일/폴더 경로>] [base=<브랜치> (default: main/develop)]
```

> 표기: `key=값` 필수 · `[key=값]` 선택 · `(default: X)` 미지정 시 X로 진행.

**예시:**

```
/devoks-sdlc:code-review
/devoks-sdlc:code-review mode=diff-branch base=main
/devoks-sdlc:code-review mode=general scope=src/features/auth
```

인자가 없어도 동작한다. Phase 0에서 1회 확인한다.

| 슬롯 | 의미 | 입력 방법 |
|------|------|----------|
| `mode` | 리뷰 방식 | `mode` 인자 또는 Phase 0 추론·확인 |
| `scope` | `general`이면 파일/폴더 경로, `diff-branch`면 base 브랜치 이름 | `scope`/`base` 인자 또는 Phase 0 확인 |
| 목적 | 로직·버그·안정성·성능·보안·리팩토링·스타일 중 우선순위 | Phase 0 확인 (`general` 한정, 선택) |
| 제외 범위 | 테스트 제외, 특정 폴더 제외 등 | Phase 0 확인 (선택) |

---

## Phase 0 — 범위 합의 (1회)

목적: **어떤 방식으로, 어디를** 리뷰할지 1회 확정한다. 이후 단계는 사용자 확인 없이 진행한다.

1. `$ARGUMENTS`에서 슬롯을 파싱한다.
2. **인자로 확정되면 더 묻지 않는다.**
   - `scope`에 파일/폴더 경로가 들어왔으면 `mode=general` 확정.
   - `mode`가 명시됐으면 그대로 사용.
3. **인자가 없으면 추론하고 1줄로 확인한다.**
   - `git branch --show-current`로 현재 브랜치를 확인한다.
   - 현재 브랜치가 base(`main`/`develop`)가 **아니면** `diff-branch`를 제안한다:
     `"현재 브랜치 <branch> 커밋 범위(base=<base>)로 리뷰할까요? 아니면 특정 파일/폴더 범위를 지정할까요?"`
   - 현재 브랜치가 base **이면** 대상 파일/폴더를 묻는다(`general` 전제).
4. `mode=diff-branch`면 base 브랜치를 확정한다.
   - 통상 `main` 또는 `develop`. `git rev-parse --verify <base>`로 존재를 확인한다.
   - 존재하지 않거나 후보가 둘 이상이면 그때만 재질문한다.
   - `git log --oneline <base>..HEAD`로 커밋 목록을 확인해 변경 의도·범위를 파악한다(범위가 비어 있으면 진행 전 안내).
5. `mode=general`이면 대상 범위(단일 파일 / 다중 파일 / 폴더 / 프로젝트)·리뷰 목적·제외 범위를 함께 확정한다. 범위가 모호하면 반드시 재질문한다.

> AskUserQuestion은 HITL 직접 호출 경로 전용이다. mode가 진짜 갈림길일 때만 쓰고, 인자로 확정된 경우·명확한 기본값이 있는 경우에는 묻지 않고 1줄 통보로 진행한다.

---

## Phase 1 — 리뷰 실행 (에이전트 위임)

> ⚠️ **실행 주체는 `code-reviewer` 에이전트이다.** 파일·diff·lint 출력은 에이전트 컨텍스트에 격리되고,
> 메인 루프에는 **포맷된 리포트만** 리턴된다.

Phase 0에서 확정된 값으로 `code-reviewer` 에이전트를 호출한다.

| 파라미터 | 값 |
|---------|-----|
| `mode` | Phase 0에서 확정한 `general` 또는 `diff-branch` |
| `scope` | Phase 0에서 확정한 파일/폴더 경로 또는 base 브랜치 이름 |

에이전트가 따르는 실행 절차·리포트 형식 SSOT는 `references/review-execution.md`·`references/report-template.md`다.

---

## Phase 2 — 리포트 출력 (Pass-through 전용)

> ⚠️ **이 단계는 Pass-through 전용이다.** 메인 에이전트는 subagent 리포트를 요약·압축·재작성·생략해서는 안 된다. 기본 brevity 설정과 무관하게, subagent가 반환한 리포트 전문을 **한 글자도 빠뜨리지 않고 그대로** 사용자에게 출력한다.

**금지:**
- 헤더·섹션 축약 (예: "잘된 점" 섹션 생략)
- 이슈 설명 단축 (문제·영향·재현/검증 방법·권장·후속 테스트 필요·위치 항목 축약)
- 표·리스트 구조 변경
- 자체 해석이나 추가 코멘트 삽입 (리포트 본문 앞뒤에 붙이는 것도 금지)

---

## Phase 3 — 수정 진행 여부 확인

리뷰 후 사용자에게 반영 범위를 확인한다.

- 전체 반영 / High 이상 / Medium 이상 / Low 이상 4가지 선택지와 제외할 사항을 기준으로 수정 진행한다.
- 각 결과에 따라 확인이 필요한 사항이나 추가 문의가 필요하면 사용자에게 먼저 질문하고 계획을 세운다.

---

## 참고 기준 문서

- **실행 절차·리포트 SSOT**: `references/review-execution.md`, `references/report-template.md`
- **리뷰 기준 SSOT**: `.claude/refs/code-review.md` (C.L.E.A.R. / Layered / Checklists / §8 Severity)
- **프로젝트 규칙**: `.claude/refs/engineering-principles.md`, `.claude/refs/interaction-integrity.md`, `.claude/refs/git-convention.md`, `.claude/refs/workflow.md` / `.claude/rules/agent-principles.md`, 프로젝트 active convention `.claude/rules/project-convention.md`, 프로젝트 사실 SSOT `.claude/CLAUDE.md`
- **관련**: `devoks-sdlc:code-security-review` — 이 스킬은 diff/scope 한정 경량 보안 스크리닝만 수행한다. Critical/High급 보안 이슈 발견 시, 또는 repo 전수·의존성 취약점·위협 모델링이 필요하면 `/devoks-sdlc:code-security-review`(전용 심층 검증, 역할 분리)로 확장한다.
