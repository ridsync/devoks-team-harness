---
description: (agent-internal — test-writer 에이전트 전용, 사용자 요청으로 직접 호출 금지) test-writer 에이전트가 호출하는 테스트 작성 실행 엔진. target을 입력받아 프로젝트의 실제 테스트 러너·라이브러리·파일 패턴을 감지하고 그 컨벤션에 맞춰 단위·통합 테스트를 작성·확장한 뒤 자기검증까지 수행한다. 진입은 /devoks-sdlc:test-author 커맨드. 테스트 실행·실패 분석은 devoks-sdlc:test-run-triage, 요구·보안 충족 판정은 devoks-sdlc:verify-requirements / devoks-sdlc:code-security-review 를 쓴다.
metadata:
  author: ridsync
  version: 2.1.0
---

# test-author — 테스트 작성/확장 (엔진)

**호출 주체:** `test-writer` 에이전트 (subagent 안에서 실행)
**진입:** `/devoks-sdlc:test-author` 커맨드 → 에이전트 위임. **메인 루프 직접 호출 금지.**

대상 코드의 자동화 테스트를 **프로젝트의 실제 테스트 컨벤션에 맞춰** 작성·확장한다.
이 스킬은 특정 테스트 프레임워크를 가정하지 않는다 — 프로젝트에서 쓰는 도구를 먼저 감지한다.
품질 기준(FIRST·행위검증·결정성·테스트 더블·안티패턴 등)은 `references/test-quality-bar.md`를 따른다.

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

## 입력 파라미터

호출자(`test-writer` 에이전트)가 아래 파라미터를 전달한다. `target`은 커맨드에서 이미 확정된 값이므로 이 스킬 내부에서 모호성을 다시 확인하지 않는다.

| 파라미터 | 필수 | 설명 |
|---------|------|------|
| `target` | ✅ | 테스트 대상 파일/모듈/심볼 경로 |
| `plan` / `frd` | 선택 | PLAN.md/FRD.md 절대경로 — EARS AC와 케이스를 `traces`로 연결할 때 |
| `context` | 선택 | 우선 커버해야 할 케이스, 알려진 제약, 버그 수정 여부 등 추가 힌트 |

---

## 절차

### 1. 테스트 환경 감지 (Spec First)

프로젝트의 실제 테스트 설정을 **먼저 감지한다**. 특정 프레임워크를 가정하지 않는다.

- `package.json`의 `scripts`(test 계열)·`devDependencies`에서 테스트 러너·라이브러리 식별.
- 테스트 설정 파일(`vitest.config.*`, `jest.config.*`, `pytest.ini` 등) 확인.
- 기존 테스트 파일의 **위치(colocated vs `__tests__` vs `test/`)와 네이밍 패턴**(`*.test.js`, `*.spec.ts` 등)을 샘플로 파악.
- 프로젝트 active convention(`.claude/rules/project-convention.md`)이 있으면 Test 섹션 규칙을 따른다. 스택 사실은 필요 시 `.claude/CLAUDE.md`로 교차 확인한다.

> 감지값이 SSOT다. 본 스킬에 러너/라이브러리/경로를 하드코딩하지 않는다.

### 2. 대상 분석 (Read Before Touch)

- 테스트 대상의 시그니처·분기·엣지·실패 경로를 읽고 식별한다.
- 계약 경계(입력 검증 `*OrThrow`류, Provider/Context, Model `validate()` 등)가 있으면 정상·위반 양쪽을 케이스로 잡는다.

### 3. 테스트 케이스 설계

- 정상 / 경계 / 실패(계약 위반) 케이스를 표로 정리하고 **요구↔케이스**를 매핑한다.
- FRD/PLAN의 EARS Acceptance Criteria가 있으면 케이스에 `traces`로 연결한다.
- 케이스 설계·레벨 결정은 `references/test-quality-bar.md` §5(레벨 결정)·§6(케이스 설계)을 따른다.
- `context`에 버그 수정 신호가 있으면 `references/test-quality-bar.md` §7 예외를 적용한다 — 수정 전 그 버그를 재현하는 실패 테스트부터 작성해 실제로 실패함을 확인한 뒤 고친다.

### 4. 테스트 작성

- 감지된 컨벤션(위치·네이밍·구조)을 그대로 따른다.
- 외부 의존은 최소 mock, 가능하면 실제 의존(실 Provider 등) 우선.
- 매직값 금지 — 의미 있는 named constant·fixture로 추출한다.

### 5. 자기검증

- **작성·수정한 테스트만** 실행해 통과를 확인한다.
- 테스트가 프로덕션 버그를 드러내면 수정하지 말고 명시적으로 보고한다.
- 전체 스위트 실행·실패 분석이 필요하면 `devoks-sdlc:test-run-triage`로 넘긴다.

---

## 완료 기준

- 새/확장 테스트가 통과한다.
- 프로젝트 테스트 컨벤션(위치·네이밍·구조)을 준수한다.
- 요구↔케이스 매핑이 명시되어 있다.
- 미해결 TODO·미커버 경로는 명시적으로 플래그한다(은폐 금지).
- 안티패턴 없음(`references/test-quality-bar.md` §9) — assertion 없는 테스트·over-mocking·커버리지용 허수 테스트가 없다.

---

## 리포트 형식

`test-writer` 에이전트의 최종 메시지는 아래 둘 중 하나다.

**`status: done`**
- `target`, 생성/수정한 테스트 파일 목록(신규/수정 구분)
- **케이스 표** — 정상/경계/실패 케이스와 요구↔케이스 매핑(`traces` 있으면 AC ID 포함)
- **자기검증 근거(필수)** — 실행 명령 원문·종료코드·출력 tail 1줄 원문(pass/fail 카운트 또는 최종 결과 줄, 재서술 금지)
- **발견된 프로덕션 버그(있으면)** — 수정하지 않고 사실만 보고
- 미커버 경로·TODO(있으면 명시, 은폐 금지)

**`status: blocked`**
- `target`, 시도한 것
- 정확한 blocker — 테스트 환경 미검출/컨벤션 충돌/대상 코드 자체의 스펙 불명 등
- 부분 변경 파일 목록과 상태(은폐 금지)
- 해소 제안 1~2개

---

## 참고 기준 문서

- **프로젝트 규칙**: 프로젝트 active convention `.claude/rules/project-convention.md`(Test 섹션), `.claude/rules/agent-principles.md`(Definition of Done), 필요 시 `.claude/CLAUDE.md`.
- **품질 기준**: `references/test-quality-bar.md`(FIRST·결정성·테스트 레벨·케이스 설계·버그수정 예외·테스트 더블·안티패턴·커버리지 철학).
- 관련 스킬: `devoks-sdlc:test-run-triage`(실행·triage), `devoks-sdlc:verify-requirements`(요구 충족 판정).
