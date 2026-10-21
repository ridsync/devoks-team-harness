---
description: "지정된 파일/폴더/모듈을 대상으로 현황 파악 → 계획 수립 → 승인 → 실행 → 검증 순서로 리팩토링한다. UI 개선이 아닌 구조·책임·계약·도메인 품질(SSOT, Fail-Fast, 계층 분리, 네이밍, 사이드이펙트) 개선에 집중하며 외부 동작 변경은 원칙적으로 하지 않는다. \"리팩토링해줘\", \"이 파일 구조 정리\", \"코드 품질 개선\", \"SSOT 위반 고쳐줘\", \"Fail-Fast 적용\" 같은 요청에서 사용한다. 새 기능 구현은 devoks-sdlc:feature-plan-executor 또는 devoks-sdlc:new-feature-by-github-issue, 코드 문제 발견(수정 아님)은 devoks-sdlc:code-review 를 쓴다."
argument-hint: "target=<파일|폴더|모듈 경로> [goal=<개선 목표>] [constraints=<제외 범위·동작 불변 요구 등>]"
metadata:
  author: ridsync
  version: 1.1.0
---

# code-refactoring — 코드 리팩토링 (구조·책임·계약 품질 개선)

사용자가 지정한 **파일/폴더/모듈**을 대상으로 현황 파악 → 계획 수립 → 승인 → 실행 → 검증 순으로 리팩토링을 진행한다.

UI 개선이 아닌 **구조·책임·계약·도메인 품질** 개선에 집중한다. 리팩토링은 외부 동작을 변경하지 않는 것이 원칙이며, 동작 변경이 불가피할 경우 반드시 명시한다.

계획 수립 → 승인 → 실행이 절차의 본질(추론과 사용자 승인이 반복되는 상호작용)이므로, 이 스킬은
서브에이전트로 위임하지 않고 **메인 루프에서 직접 실행**한다.

---

## 호출 방법

```
/devoks-sdlc:code-refactoring target=<파일|폴더|모듈 경로> [goal=<개선 목표>] [constraints=<제외 범위·동작 불변 요구 등>]
```

> 표기: `key=값` 필수 · `[key=값]` 선택 · `(default: X)` 미지정 시 X로 진행.

**예시:**

```
/devoks-sdlc:code-refactoring target=src/context/network/AuthProvider.jsx
/devoks-sdlc:code-refactoring target=src/pages/settings/ goal="파일 크기 분할, Fail-Fast 적용" constraints="API 시그니처 변경 금지"
```

| 슬롯 | 의미 | 입력 방법 |
|------|------|----------|
| `target` | 리팩토링 대상 파일/폴더/모듈 경로 | `target` 인자 또는 Phase 0 확인 (필수) |
| `goal` | 개선하려는 품질 방향(파일 크기 분할, Fail-Fast 적용, Feature/Provider 분리, SSOT 정리 등) | `goal` 인자 또는 Phase 0 확인 (선택, 없으면 `.claude/CLAUDE.md`·`.claude/rules/agent-principles.md` 우선순위 기준 위반 항목 전체 점검) |
| `constraints` | 제외 범위, 동작 불변 요구 등 | `constraints` 인자 또는 Phase 0 확인 (선택) |

---

## Phase 0 — 범위 및 목표 확정

1. `$ARGUMENTS`에서 슬롯을 파싱한다.
2. `target`이 없으면 반드시 질문한다.
3. `goal`이 없으면 리팩토링 목표 유형(구조/계약/크기/네이밍/코드 품질)을 확인하거나, 명시가 없으면 `.claude/CLAUDE.md` 및 `.claude/rules/agent-principles.md` 우선순위 기준으로 위반 항목 전체를 점검하기로 1줄 안내한다.
4. 제외 범위·동작 불변 요구 등 `constraints`를 확인한다.
5. 범위 또는 목표가 모호하면 진행 전에 재질문한다.

> AskUserQuestion은 HITL 직접 호출 경로 전용이다. 슬롯이 인자로 명확히 왔으면 묻지 않고 진행한다.

---

## Phase 1 — 현황 파악 → 계획 → 승인 → 실행 → 검증

Phase 0에서 확정된 `target`·`goal`·`constraints`로 아래 절차를 **메인 루프에서 직접** 수행한다. 세부 절차(2. 현황 파악, 3. 계획 수립 및 승인, 4. 실행, 5. 검증 및 마무리) SSOT는 `references/refactoring-execution.md`다.

> 사용자 승인 없이 코드를 변경하지 않는다(계획 수립 후 반드시 승인 → 실행).

---

## Checklist

- [ ] 리팩토링 대상·목표·제약 조건 확정 (모호하면 재질문)
- [ ] 대상 파일 및 직접 의존 모듈 탐색 완료
- [ ] `.claude/CLAUDE.md` 및 `.claude/refs/engineering-principles.md` 기준 위반 항목 도출 (코드 크기, 네이밍, 계층, 사이드이펙트)
- [ ] `.claude/rules/` 및 `.claude/refs/` 규칙 파일 기준 위반 항목 도출
- [ ] 수정/생성/삭제 파일 목록 및 개선 방향 작성 후 사용자 승인
- [ ] Critical: SSOT/Contract/Fail-Fast 위반 수정
- [ ] High: 1000자 초과 분할, 계층 재배치, 사이드이펙트 분리
- [ ] Medium: 네이밍 개선, 주석 3종(프로젝트 기본 주석/Rationale/Provider Header) 보완(불필요한 주석 제거 포함)
- [ ] Low: import 정렬, console 정리, 미사용 코드 제거
- [ ] 동작 불변 검증 — 기존 테스트 있으면 `test-run-triage`로 회귀 확인, 없으면 `test-author` 보강 제안
- [ ] 프로젝트의 린트 스크립트(예: `npm run lint`, `pnpm lint`) 확인, 린트 오류 수정
- [ ] 프로젝트의 포맷 스크립트(예: `npm run format`, `pnpm format`) 확인·적용 (없으면 생략하고 명시)
- [ ] 리팩토링 요약 및 추후 작업 안내

---

## 참고 기준 문서

- **실행 절차·우선순위·Rules SSOT**: `references/refactoring-execution.md`
- **관련**: 구조 파악이 먼저 필요하면 `devoks-sdlc:code-analyze-module`, 품질 이슈 발견(수정 아님)은 `devoks-sdlc:code-review`.
