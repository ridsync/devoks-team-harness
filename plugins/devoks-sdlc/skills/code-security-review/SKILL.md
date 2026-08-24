---
description: "리포지토리·의존성·위협 수준의 전용 보안 검증을 수행한다. scope를 대상으로 의존성 취약점·시크릿 하드코딩·인증인가 경계 우회·인젝션/XSS/SSRF·민감 데이터 노출·안전하지 않은 설정을 repo 전수로 점검하고 심각도별 리포트를 낸다. \"보안 점검\", \"보안 검토\", \"취약점 스캔\", \"시크릿 노출 확인\", \"의존성 취약점 확인\", \"security review\", \"security audit\" 요청에서 사용한다. 이번 변경분(diff) 단위의 경량 보안 스크리닝은 devoks-sdlc:code-review에 포함된 별개 기능이다."
metadata:
  author: ridsync
  version: 2.0.0
---

# code-security-review — 전용 보안 검증

리포지토리·의존성·위협 수준의 **깊은 보안 전용 패스**를 수행한다.

스캔·분석 실행은 `code-security-reviewer` 에이전트에 위임하고 **리포트만** 돌려받는다 — 의존성 audit·시크릿
전수 스캔 등 대용량 출력이 메인 대화 컨텍스트에 적재되지 않도록 격리한다.

**경계 (중복 금지):** `devoks-sdlc:code-review`에도 보안 점검(🔒 보안 점검 요약)이 있으나, 그것은 *이번 변경분(diff)에 대한 인라인 경량 스크리닝*이다. 이 스킬은 *변경 여부와 무관하게 repo 전수 + 의존성 + 위협 모델링*을 본다.

**범용성:** 임의의 다운스트림 프로젝트에서 동작한다. 특정 프로젝트의 함수명·민감 파일 목록을 가정하지 않는다 — 스택과 프로젝트 정책을 **런타임에 감지**하고, 없으면 범용 보안 기준으로 진행한다.

---

## 범위 (중요)

**한다 (언어/스택 불문 범용 카테고리):**
- **의존성 취약점** — 프로젝트 패키지 매니저를 감지해 해당 audit 실행(`npm/pnpm/yarn audit`, `pip-audit` 등).
- **시크릿 하드코딩** — API 키·토큰·private key·연결문자열 등 범용 패턴 전수 스캔.
- **인증·인가 경계 우회** — 보호 경로가 일관되게 가드되는지 흐름 분석(프로젝트의 가드 패턴을 먼저 식별, 특정 함수명 가정 금지).
- **입력 검증 위협** — 인젝션 / XSS / SSRF 등.
- **민감 데이터 노출 · 안전하지 않은 설정** — 민감값 로깅, CORS·암호화·기본 크리덴셜 등.

**안 한다:**
- 코드 자동 수정(제안만, 적용은 승인 후).
- 일반 코드 품질 리뷰 → `devoks-sdlc:code-review`.
- 라이선스 감사.

---

## 호출 방법

```
/devoks-sdlc:code-security-review [scope=<경로|.>] [focus=<중점 영역>]
```

**예시:**

```
/devoks-sdlc:code-security-review
/devoks-sdlc:code-security-review scope=src/api focus=인증인가
```

인자가 없어도 동작한다. Phase 0에서 1회 확인한다.

| 슬롯 | 의미 | 입력 방법 |
|------|------|----------|
| `scope` | 검증 대상 경로 (전체 repo면 `.`) | `scope` 인자 또는 Phase 0 — **기본값 전체 repo** |
| `focus` | 의존성 / 시크릿 / 인증인가 / 입력검증 / 설정 중 우선순위 | `focus` 인자 또는 Phase 0 (선택) |
| 제외 범위 | 벤더 디렉토리, 생성물 등 | Phase 0 (선택) |

---

## Phase 0 — 검증 범위 확정 (1회)

1. `$ARGUMENTS`에서 슬롯을 파싱한다.
2. `scope`가 없으면 **기본값(전체 repo)으로 진행하되 한 줄로 안내한다** — 되묻지 않는다.
3. `focus`·제외 범위는 사용자가 언급했을 때만 반영한다(명확한 기본값이 있으므로 별도 질문 금지).

---

## Phase 1 — 스캔 실행 (에이전트 위임)

> ⚠️ **실행 주체는 `code-security-reviewer` 에이전트이다.** 의존성 audit·시크릿 전수 스캔 출력은 에이전트
> 컨텍스트에 격리되고, 메인 루프에는 **포맷된 리포트만** 리턴된다.

Phase 0에서 확정된 값으로 `code-security-reviewer` 에이전트를 호출한다.

| 파라미터 | 값 |
|---------|-----|
| `scope` | Phase 0에서 확정한 경로 (전체 repo면 `.`) |
| `focus` | Phase 0에서 확인한 중점 영역(있으면) |

에이전트가 따르는 실행 절차·리포트 형식 SSOT는 `references/security-scan-execution.md`·`references/report-template.md`다.

---

## Phase 2 — 리포트 출력 (Pass-through 전용)

> ⚠️ **이 단계는 Pass-through 전용이다.** 메인 에이전트는 subagent 리포트를 요약·압축·재작성·생략해서는 안 된다. 기본 brevity 설정과 무관하게, subagent가 반환한 리포트 전문을 **한 글자도 빠뜨리지 않고 그대로** 사용자에게 출력한다.

**금지:**
- 헤더·섹션 축약 (예: "요약" 섹션 생략)
- 이슈 설명 단축 (심각도·근거·권장 조치 항목 축약)
- 표·리스트 구조 변경
- 자체 해석이나 추가 코멘트 삽입 (리포트 본문 앞뒤에 붙이는 것도 금지)

---

## Phase 3 — 조치 진행 여부 확인

리뷰 후 사용자에게 반영 범위를 확인한다.

- Critical 즉시 / High 이상 / 전체 중 선택지와 제외 사항을 기준으로 조치 진행한다.
- 수정이 필요한 항목은 확인 후 계획을 세워 진행한다(**이 스킬은 제안만 하며 자동 수정하지 않는다**).

---

## 참고 기준 문서

- **실행 절차·리포트 SSOT**: `references/security-scan-execution.md`, `references/report-template.md`
- **심각도 분류 SSOT**: `.claude/refs/code-review.md §8`.
- **프로젝트 규칙**: 프로젝트 active convention `.claude/rules/project-convention.md`(Security), `.claude/rules/agent-principles.md`, 필요 시 `.claude/CLAUDE.md`.
- 관련: `devoks-sdlc:code-review`(변경분 인라인 보안 스크리닝 — 본 스킬과 역할 분리).
