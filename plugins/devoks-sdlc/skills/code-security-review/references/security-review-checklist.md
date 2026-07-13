# Security Review Checklist

`code-security-review`가 stack과 scope에 맞는 점검을 선택할 때 사용하는 실행 체크리스트다.
모든 항목을 기계적으로 지적하지 말고 적용 가능성, 실제 데이터 흐름, 보완 통제를 확인한다.

## 1. 아키텍처·위협·비즈니스 로직

- [ ] 자산, 사용자/관리자/외부 서비스, entry point, trust boundary를 찾았다.
- [ ] 인증·인가·검증·암호화·logging 통제의 실제 집행 위치가 명확하다.
- [ ] 클라이언트, 프록시, 서버, DB, 외부 서비스 사이의 신뢰 가정을 확인했다.
- [ ] 고위험 기능의 abuse case와 실패·재시도·동시성·순서 우회가 검토됐다.
- [ ] 서버가 가격, role, ownership, 상태 전이 등 클라이언트 제공 권위 값을 신뢰하지 않는다.
- [ ] multi-step workflow를 생략·반복·역순 실행하거나 두 세션에서 동시에 실행할 때 안전하다.
- [ ] rate/size/quota/idempotency/transaction 경계가 비즈니스 피해를 제한한다.

## 2. 인증·세션·인가

- [ ] 모든 보호 연산은 서버에서 인증 후 객체·행위 단위 권한을 확인한다.
- [ ] default deny이며 guard 누락 경로, alternate endpoint, direct object reference 우회가 없다.
- [ ] session 생성, fixation 방지 회전, idle/absolute timeout, logout, 권한 변경 폐기가 정의돼 있다.
- [ ] cookie는 `HttpOnly`, `Secure`, 적절한 `SameSite`, 최소 `Domain`/`Path`를 사용한다.
- [ ] cookie 인증의 state-changing 요청은 CSRF token 또는 검증된 동등 통제를 가진다.
- [ ] access/refresh/session token이 브라우저 저장소, URL, 로그, 오류, analytics에 노출되지 않는다.
- [ ] password reset, email change, payment, admin 등 민감 작업은 재인증·MFA·거래 권한을 고려한다.
- [ ] OAuth/OIDC redirect URI, state/nonce, PKCE, token audience/issuer 검증이 해당 흐름에 적용된다.

## 3. 입력·서버 실행·파일·외부 요청

- [ ] 모든 HTTP field, header, cookie, path, query, body, file, message를 서버에서 schema 검증한다.
- [ ] allowlist, length/range/cardinality 제한과 Unicode/canonicalization 처리 순서가 안전하다.
- [ ] SQL/NoSQL/OS/LDAP/template expression은 파라미터화 또는 안전한 API를 사용한다.
- [ ] serializer/parser가 위험한 type, prototype pollution, entity expansion, unsafe deserialization을 허용하지 않는다.
- [ ] file upload는 크기·내용·형식·이름·저장 위치·실행 권한·다운로드 header를 통제한다.
- [ ] path join과 archive extraction이 traversal/symlink/zip bomb을 방어한다.
- [ ] 서버 outbound request는 scheme/host/port/redirect/DNS/private network/response size를 제한한다.
- [ ] regex, pagination, search, export, compression에 resource exhaustion 제한이 있다.
- [ ] error response가 stack, query, secret, 내부 경로를 노출하지 않는다.

## 4. 브라우저·React·클라이언트 저장소

- [ ] JSX 기본 렌더링과 raw HTML/DOM sink를 구분했다.
- [ ] `dangerouslySetInnerHTML`, `innerHTML`, Markdown/CMS HTML은 중앙 sanitizer와 회귀 테스트를 가진다.
- [ ] 동적 `href`, `src`, navigation/redirect가 `javascript:` 등 위험 scheme과 open redirect를 차단한다.
- [ ] DOM API, third-party widget, analytics script가 untrusted 데이터를 executable context에 넣지 않는다.
- [ ] `postMessage`의 target origin, sender origin, message schema를 검증한다.
- [ ] session/access/refresh token, credential, 중요 개인정보를 local/session storage나 IndexedDB에 저장하지 않는다.
- [ ] Service Worker scope가 최소이며 민감 응답을 Cache API에 저장하지 않는다.
- [ ] CSP는 실제 응답에서 확인하고 nonce/hash, `object-src`, `base-uri`, `frame-ancestors` 적용을 검토한다.
- [ ] 외부 script/style은 self-host/SRI/CSP allowlist와 소유자·제거 경로를 가진다.
- [ ] source map, public env, debug route, dev tool이 production에서 비밀·내부 기능을 노출하지 않는다.

### React safe/unsafe 구분 예

- 일반적인 `<p>{userText}</p>`는 React가 text로 이스케이프하므로 입력이 있다는 이유만으로 XSS finding이 아니다.
- raw HTML, 위험 URL, 직접 DOM sink, sanitizer 설정 우회는 별도 검증 대상이다.
- client-side route/role check는 UI 행위 제어일 뿐 서버 인가 증거가 아니다.
- Server Component/Function/Action/Route Handler는 서버 trust boundary로 리뷰한다.

## 5. 민감 데이터·privacy·logging

- [ ] 데이터 분류와 최소 수집·최소 조회·보존·삭제 정책이 존재한다.
- [ ] 민감 데이터의 server → response → state → storage/cache → log/analytics/error-report 전체 경로를 확인했다.
- [ ] TLS와 저장 암호화가 필요한 데이터에 적용되고 key가 데이터와 분리돼 관리된다.
- [ ] 비밀번호는 검증된 password hashing을 사용하고 자체 암호화를 만들지 않는다.
- [ ] 로그는 actor/action/target/result/correlation을 남기되 token/password/session/불필요한 PII를 redaction한다.
- [ ] 오류·telemetry·support export·backup·test fixture에 production 민감 데이터가 섞이지 않는다.
- [ ] 브라우저와 CDN cache 정책이 개인화·민감 응답을 공유 저장하지 않는다.

## 6. 의존성·build·CI 공급망

- [ ] package manager와 lockfile이 일치하고 lockfile 변경을 검토했다.
- [ ] 알려진 취약점은 package name/version만이 아니라 import·runtime reachability·보완 통제를 확인했다.
- [ ] 신규 dependency의 maintainer, source, install/postinstall script, release 상태, 대체 가능성을 검토했다.
- [ ] CI action/image/tool version이 변경 불가능한 digest 또는 조직 정책에 맞게 pin돼 있다.
- [ ] CI token 권한이 job 단위 최소이며 fork/외부 PR에서 protected secret을 사용할 수 없다.
- [ ] build log, artifact, cache, source map에 secret이 포함되지 않는다.
- [ ] 가능하면 SBOM, signature, provenance와 artifact promotion 경로를 확인한다.

## 7. 배포·HTTP 정책·runtime 설정

- [ ] production은 HTTPS만 사용하고 reverse proxy/CDN까지 TLS·redirect·HSTS 책임이 명확하다.
- [ ] CORS allow-origin, credentials, method/header가 최소이며 origin 반사나 wildcard+credentials 조합이 없다.
- [ ] CSP, frame protection, MIME sniffing 방지, referrer policy, permissions policy가 실제 응답에 적용된다.
- [ ] cookie와 cache header가 framework 코드가 아닌 최종 배포 응답에서도 유지된다.
- [ ] debug mode, default credential, directory listing, verbose error, test route가 production에서 비활성화된다.
- [ ] environment 분리와 secret manager 사용, key rotation, 최소 권한 service account를 확인한다.
- [ ] database/network/storage가 public exposure를 최소화하고 backup/restore 권한을 분리한다.

## 8. 모니터링·대응·복구

- [ ] login failure, privilege change, authorization denial, sensitive action, security config change가 감사 가능하다.
- [ ] 이상 징후가 alert와 담당자·runbook으로 연결된다.
- [ ] CSP violation, dependency advisory, secret exposure, suspicious auth event를 처리할 경로가 있다.
- [ ] vulnerability intake, severity, owner, SLA, retest, closure evidence가 기록된다.
- [ ] security exception은 보완 통제·승인자·만료일을 가진다.
- [ ] session revoke, key rotation, third-party script 제거, Service Worker unregister 등 kill switch가 필요한 영역에 존재한다.
- [ ] incident 후 threat model, regression test, secure coding rule을 갱신한다.

## 자동화 도구 실행 원칙

| 점검 | 선택 원칙 | 금지·주의 |
|------|-----------|-----------|
| Dependency audit | 현재 lockfile의 package manager 명령 우선 | install/lockfile 수정 금지, 네트워크 실패는 `not-run` |
| Secret scan | repo 제공 도구 또는 마스킹된 pattern scan | secret 원문 출력·외부 서비스 업로드 금지 |
| SAST | repo script/config가 있으면 사용 | 새 도구를 임의 설치해 결과를 기준선으로 삼지 않음 |
| Test/build | 보안 경로 관련 기존 명령과 negative test 확인 | 전체 suite 미실행을 통과로 표현하지 않음 |
| Browser/header | 기존 dev server/배포 URL이 명확할 때 실제 응답 확인 | 서버 임의 시작 금지, URL 불명확 시 `not-run` |

## Finding 확정 전 질문

1. 실제 attacker-controlled source인가?
2. validation/sanitization/authorization을 우회해 sink까지 도달하는가?
3. framework 또는 upstream control이 이미 안전하게 처리하는가?
4. production 구성에서도 같은 경로가 활성화되는가?
5. 공격 전제조건과 영향 범위를 설명할 수 있는가?
6. 재현 또는 부정 테스트로 확인할 수 있는가?

하나라도 핵심 답이 없으면 확정 finding 대신 `확인 필요`와 필요한 증거를 기록한다.
