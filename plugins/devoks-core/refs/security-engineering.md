---
description: 서버·브라우저·코드·공급망·운영을 연결하는 애플리케이션 보안 엔지니어링 기준
---

# Security Engineering Guide

사람과 AI 에이전트가 설계·구현·리뷰·배포·운영에서 공통으로 사용하는 애플리케이션 보안 SSOT다.
특정 프레임워크 구현 규칙은 프로젝트 active convention에 두고, 이 문서는 스택과 무관한 기준·증거·게이트를 정의한다.

---

## 1. 기준 우선순위와 버전

1. 법·규제·계약·조직 보안 정책
2. 프로젝트 `.claude/CLAUDE.md`의 사실 정보와 `.claude/rules/project-convention.md`의 채택 규칙
3. 이 문서의 범용 기준
4. 공식 표준과 구현 지침

외부 기준은 아래 순서로 사용한다.

| 목적 | 기준 |
|------|------|
| 검증 가능한 보안 요구사항 | [OWASP ASVS 5.0.0](https://owasp.org/www-project-application-security-verification-standard/) |
| 개별 통제 구현 | [OWASP Cheat Sheet Series](https://cheatsheetseries.owasp.org/) |
| 보안 테스트 시나리오 | [OWASP WSTG](https://owasp.org/www-project-web-security-testing-guide/) |
| Secure SDLC 성숙도 | [OWASP SAMM](https://owasp.org/www-project-samm/), [NIST SSDF SP 800-218](https://csrc.nist.gov/pubs/sp/800/218/final) |
| 브라우저 동작·호환성 | [MDN Web Security](https://developer.mozilla.org/en-US/docs/Web/Security) |

- ASVS 요구사항을 인용할 때는 `v5.0.0-<chapter>.<section>.<requirement>`처럼 버전을 포함한다.
- 실제 요구사항 원문과 매핑을 확인하지 못했으면 ASVS ID를 추측해 만들지 않는다.
- OWASP Top 10은 위험 커뮤니케이션에 사용하고, 완료 체크리스트나 합격 기준으로 단독 사용하지 않는다.

### 내부 적용 프로필

| 프로필 | 적용 대상 | 기준 |
|--------|-----------|------|
| `baseline` | 모든 웹 애플리케이션 | ASVS Level 1을 기본선으로 삼고 이 문서의 필수 통제를 적용 |
| `elevated` | 계정·개인정보·관리자·결제·중요 업무 흐름 | 관련 영역을 ASVS Level 2 수준으로 강화하고 위협 모델 필수 |
| `high-assurance` | 규제·고가치 자산·명시적 고보증 요구 | 보안 담당자와 범위를 확정해 ASVS Level 3 및 별도 검증 적용 |

프로필은 자동 추정하지 않는다. 프로젝트가 선언하지 않았다면 `baseline`으로 검토하되, 고위험 자산이 보이면 상향 필요성을 이슈로 남긴다.

---

## 2. 책임과 SSOT

| 문서 | 소유 정보 |
|------|-----------|
| `.claude/CLAUDE.md` | 실제 stack, 배포 구조, 데이터 분류, 인증 제공자, 민감 파일, 실행 명령 |
| `.claude/rules/project-convention.md` | 프로젝트가 채택한 인증·세션·입력 검증·브라우저·로깅 규칙 |
| `.claude/refs/security-engineering.md` | 범용 보안 기준, 증거 계약, 게이트 |
| 위협 모델 또는 ADR | 자산, 데이터 흐름, 신뢰 경계, 남용 시나리오, 수용한 위험 |

- 보안 통제의 실제 집행 위치와 소유자를 명시한다.
- 클라이언트 UI, 문서, 프록시, 서버 중 어디에서 집행되는지 불명확한 통제는 미검증으로 본다.
- 보안 예외는 사유·영향·보완 통제·승인자·만료일을 기록한다. 만료일 없는 예외는 허용하지 않는다.

---

## 3. Secure SDLC

### Governance

- 보호할 자산과 데이터 등급, 보안 담당자, 취약점 조치 SLA를 정한다.
- 외부 서비스·SDK·패키지의 소유자와 제거 경로를 기록한다.
- Critical/High 위험의 수용은 코드 작성자 혼자 결정하지 않는다.

### Design

고위험 기능은 구현 전에 아래 네 질문에 답한다.

1. 무엇을 만들고 있으며 자산·행위자·데이터 흐름·신뢰 경계는 무엇인가?
2. 공격자나 오용으로 무엇이 잘못될 수 있는가?
3. 어떤 예방·탐지·복구 통제로 대응하는가?
4. 통제가 충분히 동작한다는 것을 어떻게 검증하는가?

인증, 권한, 결제, 파일 처리, 외부 URL/요청, 개인정보, 관리자 기능, 새로운 trust boundary는 위협 모델 필수 트리거다.

### Implementation

- 보안 기본값은 deny, 최소 권한, 최소 노출이다.
- 입력 검증은 신뢰 경계를 넘은 직후, 출력 인코딩은 sink 문맥에 맞게 수행한다.
- 인증·인가·CSRF·세션·암호화 같은 통제는 검증된 라이브러리와 중앙 경계를 재사용한다.
- 실패 시 권한을 넓히거나 검증을 생략하는 implicit fallback을 두지 않는다.

### Verification

- 자동화 결과와 수동 데이터 흐름 리뷰를 함께 사용한다.
- 정상 경로뿐 아니라 미인증, 타 사용자 객체, 변조 입력, 만료·재사용, 동시성, 실패 경로를 테스트한다.
- 도구가 실행되지 않았거나 범위를 확인하지 못했으면 `통과`로 기록하지 않는다.

### Operations

- 인증 실패, 권한 거부, 중요 설정 변경, 민감 작업을 감사 가능하게 기록한다.
- 로그·추적·알림에는 토큰, 비밀번호, 세션 ID, 불필요한 개인정보를 남기지 않는다.
- 취약점 접수, 우선순위화, 패치, 회귀 테스트, 사고 후 재발 방지 흐름을 유지한다.

---

## 4. 실무 통제 기준

### 인증·세션·인가

- 인증 여부와 권한은 보호된 서버 연산 직전에 서버가 검증한다. UI 가드와 숨김 처리는 보안 경계가 아니다.
- 객체 ID를 입력받는 모든 연산은 해당 객체에 대한 권한을 별도로 확인한다.
- 세션은 생성·회전·만료·로그아웃·권한 변경 시 폐기 정책을 가진다.
- 브라우저 쿠키 세션은 `HttpOnly`, `Secure`, 적절한 `SameSite`, 최소 `Domain`/`Path`를 기본으로 하고 상태 변경 요청의 CSRF 방어를 설계한다.
- 민감 작업은 필요 시 재인증, 다중 인증, 거래 단위 권한 확인을 적용한다.

### 입력·출력·서버 실행

- 클라이언트 검증은 UX 보조일 뿐이다. 모든 외부 입력은 서버에서 타입·형식·범위·길이·허용값을 검증한다.
- SQL/NoSQL/OS/템플릿 등 실행 문맥에는 문자열 결합 대신 파라미터화 또는 안전한 API를 사용한다.
- 서버가 외부 URL을 요청할 때 scheme·host·port·redirect·DNS 결과·응답 크기를 제한해 SSRF를 방어한다.
- 파일은 이름·확장자만 믿지 않고 크기·내용·저장 위치·다운로드 응답을 통제한다.
- 오류 응답에는 stack, query, secret, 내부 경로를 노출하지 않는다.

### 브라우저·프론트엔드

- 프레임워크 자동 이스케이프를 우회하는 raw HTML/DOM sink는 기본 금지하고, 불가피하면 중앙 sanitizer와 allowlist를 사용한다.
- 사용자·서버가 제공한 URL은 허용 scheme과 목적지를 검증한다. `javascript:` 등 실행 가능 scheme을 차단한다.
- 인증 토큰·세션 ID·refresh token을 `localStorage`, `sessionStorage`, IndexedDB에 저장하지 않는 것을 기본으로 한다.
- `postMessage`는 정확한 `targetOrigin`과 송신 origin·메시지 schema를 검증한다.
- Service Worker 범위와 캐시를 최소화하고 민감 응답은 저장하지 않는다.
- CSP는 `Report-Only` 관찰 후 nonce/hash 기반 enforcement로 전환한다. `frame-ancestors`, `object-src`, `base-uri` 등 적용 여부를 서버·CDN 설정까지 확인한다.
- 외부 script/style은 필요성을 검토하고 self-host, CSP allowlist, SRI 등으로 공급망 위험을 줄인다.

### 데이터·로그·개인정보

- 필요한 데이터만 수집·조회·전송·보관한다.
- 민감 데이터는 전송·저장·백업·캐시·로그·분석 도구 전체 경로에서 추적한다.
- 클라이언트 번들에 포함되는 코드·환경값·source map에는 비밀이 존재할 수 없다고 가정한다.
- 보안 이벤트 로그는 행위자·대상·행위·결과·시간·상관관계를 남기되 비밀값을 제외한다.

### 의존성·빌드·CI/CD

- lockfile을 유지하고 의존성 변경 diff, 설치 script, maintainer·출처, 알려진 취약점을 검토한다.
- package audit 결과만으로 안전을 단정하지 않고 실제 사용 경로와 완화 통제를 확인한다.
- CI 토큰과 배포 권한은 job 단위 최소 권한으로 제한하고 fork/외부 기여 코드에서 secret 접근을 차단한다.
- 가능하면 SBOM, 서명, provenance, 재현 가능한 build로 릴리스 artifact의 출처를 확인한다.

---

## 5. 보안 리뷰 증거 계약

발견 사항은 추측이나 패턴 일치만으로 확정하지 않는다. 최소한 다음을 포함한다.

| 필드 | 요구사항 |
|------|----------|
| Rule | 내부 `SEC-*`, 확인된 ASVS version ID, 가능한 경우 CWE |
| Evidence | `file:line`과 실제 코드 또는 설정 근거 |
| Data flow | source → validation/transform → trust boundary → sink |
| Attack scenario | 공격 주체, 전제조건, 조작 방법, 도달 가능성 |
| Impact | 기밀성·무결성·가용성·권한·개인정보·업무 영향 |
| Severity | `.claude/refs/code-review.md §8`의 Likelihood × Impact 기준 |
| Confidence | `High` / `Medium` / `Low`; 미확인 가정 명시 |
| Remediation | 최소 변경 방향과 보완 통제 |
| Verification | 재현, 부정 테스트, 설정 확인 또는 수정 후 테스트 |

패턴은 보이지만 실제 source-to-sink 경로를 확인하지 못한 경우 확정 취약점이 아니라 `확인 필요`로 분류한다.

### 자동화 실행 상태

각 도구와 수동 점검은 아래 네 상태 중 하나로 기록한다.

| 상태 | 의미 |
|------|------|
| `pass` | 명령·범위·결과가 확인됐고 발견 사항 없음 |
| `fail` | 실행됐고 검증 실패 또는 유효한 finding 존재 |
| `not-run` | 도구 부재, 네트워크·권한·시간 제약 등으로 미실행 |
| `not-applicable` | 스택·범위상 해당하지 않으며 근거가 있음 |

`not-run`을 `pass`로 바꾸지 않는다. 핵심 카테고리가 `not-run`이면 전체 결과는 최소 `조건부`다.

---

## 6. 리뷰·릴리스 게이트

### PR diff review

- 모든 변경은 경량 보안 스크리닝을 수행한다.
- 인증·인가·세션·raw HTML·URL/redirect·server action/API/DB·파일·CORS/CSP·dependency/CI 변경은 고위험 트리거다.
- 트리거가 있거나 diff만으로 데이터 흐름을 확정할 수 없으면 targeted security review로 승격한다.

### Baseline / release review

- 신규 서비스, 중요 릴리스, 레거시 인수, 사고 후에는 baseline review를 수행한다.
- Critical은 머지·릴리스 차단이다.
- High는 원칙적으로 차단하며, 보안 책임자의 만료일 있는 예외와 보완 통제가 있을 때만 진행할 수 있다.
- Medium/Low는 소유자와 기한을 기록한다.

### 정기 운영

- 의존성·secret·구성 점검은 변경 시와 정기 주기로 반복한다.
- 이전 finding, 예외 만료, CSP report, 인증·인가 이상 징후를 후속 점검한다.

---

## 7. 핵심 참고 문서

- [OWASP Secure Code Review Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Secure_Code_Review_Cheat_Sheet.html)
- [OWASP Threat Modeling Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Threat_Modeling_Cheat_Sheet.html)
- [OWASP Cross Site Scripting Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html)
- [OWASP CSRF Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html)
- [OWASP Session Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html)
- [OWASP Content Security Policy Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Content_Security_Policy_Cheat_Sheet.html)
- [OWASP HTML5 Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/HTML5_Security_Cheat_Sheet.html)
- [OWASP Vulnerable Dependency Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Vulnerable_Dependency_Management_Cheat_Sheet.html)
- [OWASP Risk Rating Methodology](https://owasp.org/www-community/OWASP_Risk_Rating_Methodology)
