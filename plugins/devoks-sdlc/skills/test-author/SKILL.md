---
description: "대상 코드·모듈의 자동화 테스트(단위·통합)를 작성하거나 기존 테스트를 확장한다. 프로젝트의 실제 테스트 러너·라이브러리·파일 패턴을 감지하고 그 컨벤션에 맞춰 정상/경계/실패 케이스를 설계·작성한 뒤 작성한 테스트만 실행해 자기검증까지 수행한다. \"테스트 작성해줘\", \"테스트 짜줘\", \"유닛 테스트 추가\", \"테스트 커버리지 보강\", \"이 함수 테스트 만들어줘\" 요청에서 사용한다. 이미 있는 테스트 스위트를 실행하고 실패 원인을 분류하는 일은 devoks-sdlc:test-run-triage, 요구·보안 충족 판정은 devoks-sdlc:verify-requirements / devoks-sdlc:code-security-review 를 쓴다."
argument-hint: "[target=<파일|모듈|심볼 경로> (default: 직전 변경 범위)] [plan=<PLAN.md 경로>] [frd=<FRD.md 경로>] [context=<추가 힌트>]"
metadata:
  author: ridsync
  version: 3.0.0
---

# test-author — 테스트 작성/확장

지정된 **파일/모듈/심볼**을 대상으로 자동화 테스트를 작성하거나 기존 테스트를 확장한다.
특정 테스트 프레임워크를 가정하지 않는다 — 프로젝트에서 쓰는 도구를 먼저 감지한다.

작성·자기검증 실행은 `test-writer` 에이전트에 위임하고 **리포트만** 돌려받는다 — 대상 코드·기존 테스트
다독과 자기검증 실행 로그가 메인 대화 컨텍스트에 적재되지 않도록 격리한다.

---

## 범위 (중요)

**한다:**
- 지정된 함수/컴포넌트/모듈의 단위·통합 테스트 생성.
- 기존 테스트 파일에 누락된 케이스(경계·실패 경로) 확장.
- 작성한 테스트만 실행해 통과 확인(자기검증).

**안 한다:**
- 프로덕션 코드 수정(테스트가 드러낸 버그는 보고만 하고 수정은 사용자 승인 후).
- 전체 스위트 실행·실패 triage → `devoks-sdlc:test-run-triage`.
- 요구·보안 충족 판정 → `devoks-sdlc:verify-requirements`, `devoks-sdlc:code-security-review`.

---

## 호출 방법

```
/devoks-sdlc:test-author [target=<파일|모듈|심볼 경로> (default: 직전 변경 범위)] [plan=<PLAN.md 경로>] [frd=<FRD.md 경로>] [context=<추가 힌트>]
```

> 표기: `key=값` 필수 · `[key=값]` 선택 · `(default: X)` 미지정 시 X로 진행.

**예시:**

```
/devoks-sdlc:test-author target=src/lib/calibration.ts
/devoks-sdlc:test-author target=src/lib/parser.ts frd=.claude/workspace/mark-20260722/FRD.md
```

인자가 없어도 동작한다. Phase 0에서 1회 확인한다.

| 슬롯 | 의미 | 입력 방법 |
|------|------|----------|
| `target` | 테스트 대상 파일/모듈/심볼 경로 | `target` 인자 또는 Phase 0 확인 |
| `plan` / `frd` | EARS Acceptance Criteria와 케이스를 `traces`로 연결할 때의 문서 경로 | 인자 또는 Phase 0 확인 (선택) |
| `context` | 우선 커버할 케이스, 알려진 제약, 버그 수정 신호 | 인자 또는 Phase 0 도출 (선택) |

---

## Phase 0 — 대상 확정 (1회)

1. `$ARGUMENTS`에서 슬롯을 파싱한다.
2. `target`이 없으면 직전 작업·변경 범위 또는 사용자가 가리킨 대상으로 확인한다. **불명확하면 진행 전에 반드시 한 줄로 재질문한다**(자유 입력이므로 모달이 아니라 한 줄 질문).
3. 연관 PLAN/FRD가 있으면 경로를 확인한다(EARS AC ↔ 케이스 `traces` 연결용).
4. 사용자 요청에 **버그/재현/회귀 신호**가 있으면 `context`에 담는다 — 이 신호가 있으면 엔진이 "수정 전 재현 실패 테스트부터" 순서를 적용한다.

---

## Phase 1 — 작성·자기검증 (에이전트 위임)

> ⚠️ **실행 주체는 `test-writer` 에이전트이다.** 대상 코드 다독·자기검증 실행 로그는 에이전트 컨텍스트에
> 격리되고, 메인 루프에는 **포맷된 리포트만** 리턴된다.

Phase 0에서 확정된 값으로 `test-writer` 에이전트를 호출한다.

| 파라미터 | 값 |
|---------|-----|
| `target` | Phase 0에서 확정한 파일/모듈/심볼 경로 |
| `plan` / `frd` | Phase 0에서 확인한 경로(있으면) |
| `context` | Phase 0에서 확인한 버그 수정 신호 등(있으면) |

에이전트가 따르는 실행 절차·리포트 스키마 SSOT는 `references/test-authoring-execution.md`,
품질 기준은 `references/test-quality-bar.md`다.

---

## Phase 2 — 리포트 출력 (Pass-through 전용)

> ⚠️ **이 단계는 Pass-through 전용이다.** 메인 에이전트는 subagent 리포트를 요약·압축·재작성·생략해서는 안 된다. 기본 brevity 설정과 무관하게, subagent가 반환한 리포트 전문을 **한 글자도 빠뜨리지 않고 그대로** 사용자에게 출력한다.

**금지:**
- 케이스 표·검증 근거(실행 명령·종료코드·출력 tail) 축약
- 자체 해석이나 추가 코멘트 삽입(리포트 본문 앞뒤에 붙이는 것도 금지)

---

## Phase 3 — 후속 조치 확인

- 리포트에 **발견된 프로덕션 버그**가 있으면(테스트는 수정하지 않고 보고만 함) 수정 진행 여부를 사용자에게 확인한다.
- `status: blocked`면 blocker를 그대로 전달하고 해소 방향을 확인한 뒤 재위임한다.
- 전체 스위트 회귀까지 확인이 필요하면 `devoks-sdlc:test-run-triage`를 제안한다.

---

## 참고 기준 문서

- **실행 절차·리포트 스키마 SSOT**: `references/test-authoring-execution.md`
- **품질 기준**: `references/test-quality-bar.md`(FIRST·결정성·테스트 레벨·케이스 설계·버그수정 예외·테스트 더블·안티패턴·커버리지 철학).
- **프로젝트 규칙**: 프로젝트 active convention `.claude/rules/project-convention.md`(Test 섹션), `.claude/rules/agent-principles.md`(Definition of Done), 필요 시 `.claude/CLAUDE.md`.
- 관련 스킬: `devoks-sdlc:test-run-triage`(실행·triage), `devoks-sdlc:verify-requirements`(요구 충족 판정).
