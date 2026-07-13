---
name: code-security-review
description: code-security-reviewer 에이전트가 호출하는 보안 검증 실행 엔진. baseline 또는 targeted 모드로 위협 모델·신뢰 경계·source-to-sink 흐름·의존성·시크릿·인증인가·서버·브라우저·배포·운영 통제를 검증하고 증거 기반 리포트를 생성한다. 메인 루프에서 직접 실행하지 않고 /devoks-sdlc:code-security-review 커맨드가 code-security-reviewer 에이전트에 위임해 사용한다.
metadata:
  author: ridsync
  version: 1.1.0
---

# code-security-review — 전용 보안 검증 엔진

**호출 주체:** `code-security-reviewer` 에이전트

**진입:** `/devoks-sdlc:code-security-review` 커맨드 → 에이전트 위임

**메인 루프 직접 호출 금지**

일반 `code-review`의 변경분 경량 스크리닝과 역할을 분리한다.

- `code-review`: PR/diff에서 고위험 security delta를 찾고 승격 필요성을 판단한다.
- `code-security-review`: baseline 또는 targeted 범위에서 코드·설정·의존성·위협·운영 통제를 깊게 검증한다.

코드는 수정하지 않는다. 자동 도구 결과를 그대로 확정 finding으로 복사하지 않고 실제 도달 가능성과 보완 통제를 확인한다.

---

## 입력 파라미터

| 파라미터 | 타입 | 기본값 | 설명 |
|----------|------|--------|------|
| `mode` | `baseline` \| `targeted` | `baseline` | 전체 기준선 감사 또는 고위험 영역 집중 감사 |
| `scope` | 경로 | `.` | repo 또는 지정 파일·폴더·모듈 |
| `profile` | `baseline` \| `elevated` \| `high-assurance` | 프로젝트 선언, 없으면 `baseline` | 보증 수준 |
| `focus` | 문자열 또는 목록 | 없음 | auth/session/browser/dependency 등 우선 영역 |
| `exclusions` | 경로 또는 설명 목록 | 생성물·vendor만 자동 제외 | 사용자가 승인한 제외 범위 |

입력되지 않은 선택값은 위 기본값으로 진행하고 리포트에 명시한다. profile을 임의 상향해 합격 기준을 바꾸지 말고, 고위험 자산이 보이면 상향 권고를 finding 또는 다음 액션으로 남긴다.

---

## 필수 참조

검증 전에 아래 문서를 순서대로 읽는다.

1. `.claude/CLAUDE.md` — stack·architecture·명령·민감 파일 사실
2. `.claude/rules/project-convention.md` — 프로젝트가 채택한 보안 구현 규칙
3. `.claude/refs/security-engineering.md` — 범용 요구사항·증거 계약·게이트
4. `.claude/refs/code-review.md §8` — 심각도 SSOT
5. 이 스킬의 `references/security-review-checklist.md` — 카테고리별 실행 체크

문서가 없으면 범용 기준으로 계속하되 누락과 그로 인해 확인하지 못한 결정을 coverage limit에 기록한다.

---

## 실행 절차

### 1. 범위·스택·기준 고정

- 현재 commit/branch, 실제 scope, 제외 경로를 기록한다.
- package manager, framework, server/runtime, database, deployment/edge config, CI를 감지한다.
- app entry point, API/server action, auth/session, 외부 integration, browser policy 설정 위치를 찾는다.
- `baseline`은 repo 전반을, `targeted`는 지정 영역과 직접 연결된 trust boundary까지 본다. targeted라도 source 또는 sink가 scope 밖이면 최소 직접 의존 경로를 따라간다.

### 2. 공격 표면과 신뢰 경계 작성

최소한 아래를 짧게 정리한 뒤 점검한다.

- 보호 자산과 민감 데이터
- 사용자·관리자·외부 서비스·브라우저·서버 등 행위자
- HTTP/API/server action/file/message/URL 등 entry point
- browser ↔ server ↔ database ↔ external service 경계
- 인증·인가·입력 검증·출력 처리·logging control의 실제 집행 위치

구조를 확인할 수 없으면 추측으로 채우지 말고 `미확인`으로 표시한다.

### 3. 자동화 선행 점검

프로젝트에 이미 설치·정의된 명령을 우선한다.

- dependency audit/SCA
- secret pattern과 tracked sensitive file 점검
- lint/type/test/build 중 보안 경로와 관련된 기존 명령
- 사용 가능한 SAST/config/IaC scan

규칙:

- 패키지 설치, lockfile 갱신, 설정 수정, 외부 업로드를 하지 않는다.
- 네트워크·권한·도구 부재로 실패하면 `not-run`과 원인을 기록한다.
- secret 원문을 출력하지 않고 종류·마스킹된 형태·위치만 기록한다.
- scanner finding은 실제 버전·사용 경로·보완 통제를 확인한 뒤 확정한다.
- 각 점검을 `pass` / `fail` / `not-run` / `not-applicable`로 기록한다.

### 4. 수동 보안 리뷰

`references/security-review-checklist.md`의 8개 카테고리를 적용한다.

1. 아키텍처·위협 모델·비즈니스 로직
2. 인증·세션·인가
3. 입력·서버 실행·파일·외부 요청
4. 브라우저·React·클라이언트 저장소
5. 민감 데이터·privacy·logging
6. 의존성·build·CI 공급망
7. 배포·HTTP 정책·runtime 설정
8. 모니터링·취약점 대응·복구

의심 지점은 다음 형식으로 추적한다.

`source → validation/transform → trust boundary → sink → security impact`

패턴은 있으나 실제 도달 경로가 확인되지 않으면 취약점으로 단정하지 않고 `확인 필요`로 남긴다.

### 5. 위험도와 finding 확정

- `.claude/refs/code-review.md §8`의 Likelihood × Impact로 Critical/High/Medium/Low를 정한다.
- 취약점 종류만으로 Critical을 부여하지 않는다.
- `Confidence`는 위험도와 별도로 High/Medium/Low를 기록한다.
- ASVS ID는 원문 매핑을 확인했을 때만 `v5.0.0-*` 형식으로 기록한다. 모르면 생략하고 관련 OWASP 문서만 연결한다.
- 같은 root cause의 반복 위치는 하나의 finding으로 묶고 영향 위치를 나열한다.

---

## 출력 형식

아래 섹션을 생략하지 않는다.

```markdown
## 📋 검증 대상
- 모드: baseline / targeted
- 범위:
- commit/branch:
- 스택:
- 보안 프로필:
- focus:
- 제외:
- 적용 기준: 프로젝트 정책 / security-engineering / ASVS 5.0.0 / 관련 OWASP 지침

## 🧭 공격 표면·신뢰 경계
- 보호 자산:
- 행위자·entry point:
- 주요 데이터 흐름:
- trust boundary:
- 통제 집행 위치:
- 미확인 가정:

## 🧪 자동화·검증 증거
| 점검 | 실행 명령/방법 | 상태 | 결과·제약 |
|------|----------------|------|-----------|
| Dependency/SCA | | pass/fail/not-run/not-applicable | |
| Secret scan | | pass/fail/not-run/not-applicable | |
| SAST/config | | pass/fail/not-run/not-applicable | |
| 보안 관련 test/build | | pass/fail/not-run/not-applicable | |

## 🔒 카테고리별 결과
| 카테고리 | 상태 | 핵심 근거 |
|----------|------|-----------|
| 아키텍처·위협·비즈니스 로직 | ✅/⚠️/❌/미검증 | |
| 인증·세션·인가 | ✅/⚠️/❌/해당 없음 | |
| 입력·서버 실행·파일·외부 요청 | ✅/⚠️/❌/해당 없음 | |
| 브라우저·React·저장소 | ✅/⚠️/❌/해당 없음 | |
| 민감 데이터·privacy·logging | ✅/⚠️/❌/해당 없음 | |
| 의존성·build·CI | ✅/⚠️/❌/미검증 | |
| 배포·HTTP 정책·runtime 설정 | ✅/⚠️/❌/미검증 | |
| 모니터링·대응·복구 | ✅/⚠️/❌/미검증 | |

## 🔍 발견 이슈 (심각도 순)

### 🔴 Critical
#### SEC-001 [제목]
- Rule/CWE/ASVS:
- 문제:
- 증거: `file:line`
- Data flow:
- 공격 시나리오·전제조건:
- Likelihood / Impact:
- 영향:
- Confidence: High / Medium / Low
- 권장:
- 수정 후 검증:

### 🟠 High
### 🟡 Medium
### 🔵 Low

## 📊 이슈·게이트 요약
| 심각도 | 개수 | 게이트 |
|--------|------|--------|
| 🔴 Critical | N | 차단 |
| 🟠 High | N | 원칙적 차단 |
| 🟡 Medium | N | 소유자·기한 필요 |
| 🔵 Low | N | 후속 개선 |

- 전체 결과: ✅ 통과 / ⚠️ 조건부 / ❌ 위험
- 머지·릴리스 판단:
- 한줄 근거:

## 🕳️ Coverage limits / not-run
- 미실행 도구·카테고리와 이유:
- scope 밖이어서 확인하지 못한 source/sink/config:
- 추가 증거가 필요한 가정:

## 🚀 다음 액션
- 즉시:
- 다음 배치:
- 재검증:
```

finding이 없는 심각도 섹션도 `없음`이라고 명시한다. finding 위치에 secret 원문이나 공격에 불필요한 민감 데이터를 복사하지 않는다.

---

## 전체 결과 판정

| 결과 | 조건 |
|------|------|
| `❌ 위험` | Critical 또는 High 존재, 핵심 보안 경계의 명백한 우회 확인 |
| `⚠️ 조건부` | Medium/Low 존재, 핵심 점검 `not-run`, 중요한 trust boundary·설정 미확인 |
| `✅ 통과` | 유효한 finding 0, 모든 적용 가능 핵심 카테고리와 필수 점검이 `pass` 또는 근거 있는 `not-applicable` |

자동화가 깨끗하다는 이유만으로 통과하지 않는다. 반대로 패턴 매칭만으로 취약점을 확정하지 않는다.

---

## 완료 기준

- 공격 표면·자산·trust boundary가 요약되어 있다.
- 8개 카테고리 모두 상태와 근거가 있다.
- 자동화 상태가 네 상태 중 하나로 기록되고 `not-run`이 숨겨지지 않는다.
- finding마다 evidence, data flow, scenario, likelihood/impact, confidence, remediation, verification이 있다.
- severity는 `.claude/refs/code-review.md §8`만 참조한다.
- 코드·설정·lockfile을 수정하지 않았다.
- 다음 액션과 재검증 범위가 실행 가능하게 적혀 있다.

---

## 참고 기준

- `.claude/refs/security-engineering.md`
- `.claude/refs/code-review.md §8`
- `.claude/rules/project-convention.md`
- `references/security-review-checklist.md`
- 관련: `devoks-sdlc:code-review` — 변경분 경량 스크리닝과 targeted review 승격 판단
