---
description: 대상 코드·모듈의 자동화 테스트(단위·통합)를 작성하거나 기존 테스트를 확장한다. 프로젝트의 실제 테스트 러너·라이브러리·파일 패턴을 먼저 감지해 그 컨벤션에 맞춰 작성한다. "테스트 작성해줘", "테스트 짜줘", "유닛 테스트 추가", "테스트 커버리지 보강", "이 함수 테스트 만들어줘", "write tests" 요청에서 사용한다. 테스트 실행·실패 분석은 devoks-test:test-run-triage, 요구·보안 충족 판정은 devoks-verify:verify-requirements / devoks-code:code-security-review 를 쓴다.
metadata:
  author: ridsync
  version: 1.0.0
---

# test-author — 테스트 작성/확장

대상 코드의 자동화 테스트를 **프로젝트의 실제 테스트 컨벤션에 맞춰** 작성·확장한다.
이 스킬은 특정 테스트 프레임워크를 가정하지 않는다 — 프로젝트에서 쓰는 도구를 먼저 감지한다.

---

## 범위 (중요)

**한다:**
- 지정된 함수/컴포넌트/모듈의 단위·통합 테스트 생성.
- 기존 테스트 파일에 누락된 케이스(경계·실패 경로) 확장.
- 작성한 테스트만 실행해 통과 확인(자기검증).

**안 한다:**
- 프로덕션 코드 수정(테스트가 드러낸 버그는 보고만 하고 수정은 사용자 승인 후).
- 전체 스위트 실행·실패 triage → `devoks-test:test-run-triage`.
- 요구·보안 충족 판정 → `devoks-verify:verify-requirements`, `devoks-code:code-security-review`.

---

## 호출 방법

```
/devoks-test:test-author [target=<파일/모듈/심볼 경로>]
```

- `target` 미지정 시 직전 작업·변경 범위 또는 사용자가 가리킨 대상을 확인 후 진행. 불명확하면 한 줄로 확인한다.

---

## 절차

### 1. 테스트 환경 감지 (Spec First)

프로젝트의 실제 테스트 설정을 **먼저 감지한다**. 특정 프레임워크를 가정하지 않는다.

- `package.json`의 `scripts`(test 계열)·`devDependencies`에서 테스트 러너·라이브러리 식별.
- 테스트 설정 파일(`vitest.config.*`, `jest.config.*`, `pytest.ini` 등) 확인.
- 기존 테스트 파일의 **위치(colocated vs `__tests__` vs `test/`)와 네이밍 패턴**(`*.test.js`, `*.spec.ts` 등)을 샘플로 파악.
- 프로젝트 컨벤션 문서(`.claude/rules/project-convention.md` 등)가 있으면 Test 섹션 규칙을 따른다.

> 감지값이 SSOT다. 본 스킬에 러너/라이브러리/경로를 하드코딩하지 않는다.

### 2. 대상 분석 (Read Before Touch)

- 테스트 대상의 시그니처·분기·엣지·실패 경로를 읽고 식별한다.
- 계약 경계(입력 검증 `*OrThrow`류, Provider/Context, Model `validate()` 등)가 있으면 정상·위반 양쪽을 케이스로 잡는다.

### 3. 테스트 케이스 설계

- 정상 / 경계 / 실패(계약 위반) 케이스를 표로 정리하고 **요구↔케이스**를 매핑한다.
- FRD/PLAN의 EARS Acceptance Criteria가 있으면 케이스에 `traces`로 연결한다.

### 4. 테스트 작성

- 감지된 컨벤션(위치·네이밍·구조)을 그대로 따른다.
- 외부 의존은 최소 mock, 가능하면 실제 의존(실 Provider 등) 우선.
- 매직값 금지 — 의미 있는 named constant·fixture로 추출한다.

### 5. 자기검증

- **작성·수정한 테스트만** 실행해 통과를 확인한다.
- 테스트가 프로덕션 버그를 드러내면 수정하지 말고 명시적으로 보고한다.
- 전체 스위트 실행·실패 분석이 필요하면 `devoks-test:test-run-triage`로 넘긴다.

---

## 완료 기준

- 새/확장 테스트가 통과한다.
- 프로젝트 테스트 컨벤션(위치·네이밍·구조)을 준수한다.
- 요구↔케이스 매핑이 명시되어 있다.
- 미해결 TODO·미커버 경로는 명시적으로 플래그한다(은폐 금지).

---

## 참고 기준 문서

- **프로젝트 규칙**: `.claude/rules/project-convention.md`(Test 섹션), `.claude/rules/agent-principles.md`(Definition of Done).
- 관련 스킬: `devoks-test:test-run-triage`(실행·triage), `devoks-verify:verify-requirements`(요구 충족 판정).
