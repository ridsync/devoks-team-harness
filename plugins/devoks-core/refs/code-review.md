---
description: 코드리뷰 규칙
---

# Code Review Guide

AI(Claude Code, Cursor, Copilot 등)와 사람이 코드리뷰 시 일관되게 참고하는 SSOT 가이드.
일반 코드와 AI 생성 코드 모두에 적용한다.

참고: [Vibe Coding – Code Review Guidelines](https://docs.vibe-coding-framework.com/best-practices/code-review-guidelines), [CodeRabbit – Review instructions](https://docs.coderabbit.ai/guides/review-instructions),
[OWASP Secure Code Review Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Secure_Code_Review_Cheat_Sheet.html), [OWASP Secure Coding Practices Quick Reference](https://owasp.org/www-project-secure-coding-practices-quick-reference-guide/stable-en/02-checklist/)

보안 요구사항·증거 계약·게이트의 SSOT는 `.claude/refs/security-engineering.md`다. 이 문서는 일반 리뷰에서 적용할 요약과 공통 심각도만 정의한다.

---

## 1. Review Philosophy

- **제로 트러스트**: 코드를 신뢰하지 않고 모든 로직을 의심하며 검토한다.
- **외부 유입 코드 격리**: 서드파티 통합·외부 기여 코드가 포함되면 격리된 환경에서 우선 검증한다.
- **리뷰 품질 한계 관리**:
  - (사람) 한 세션에서 400줄 이상 또는 60분 이상이면 구간을 분할해 재검토한다.
  - (AI 에이전트) diff 파일이 5개 이상이거나 변경 줄이 300줄을 초과하면
    레이어(구조 → 로직 → 보안) 또는 파일 단위로 분할해 순차 검토한다.

---

## 2. Pre-Review Gate

수동 리뷰 전에 최소 품질 게이트를 통과해야 한다.

- [ ] `eslint` / `prettier` 기준 위반 없음
- [ ] 타입 검사 오류 없음 (`tsc` 또는 프로젝트 타입 체크 명령)

---

## 3. C.L.E.A.R. Framework

| 단계 | 내용 |
|------|------|
| **C - Context** | 요구사항·시스템 내 위치·변경 의도를 먼저 파악한다. |
| **L - Layered Examination** | 구조 -> 로직 -> 보안 -> 성능 -> 유지보수 순으로 점검한다. |
| **E - Explicit Verification** | 핵심 로직을 샘플 데이터와 실패 시나리오로 명시 검증한다. |
| **A - Alternative Consideration** | 대안과 트레이드오프를 비교해 선택의 타당성을 확인한다. |
| **R - Refactoring Recommendations** | 우선순위(High/Medium/Low)와 파일 위치를 포함한 실행 가능한 개선안을 제시한다. |

---

## 4. Layered Examination (Level 1 -> 5)

한 레이어에서 Critical/High 문제가 나오면 다음 레이어로 넘어가기 전에 정리한다.

### Level 1 – Structure / Architecture

- 전체 디렉토리/모듈 구조가 일관적인가?
- 모듈 경계와 책임 분리가 명확한가?
- 에러 처리 전략(throw/return/log)이 일관적인가?
- 평가/실행 분리가 프로젝트 아키텍처 규칙과 충돌하지 않는가?

### Level 2 – Core Logic / Algorithm

- 비즈니스 로직이 요구사항과 일치하는가?
- 상태 변이와 데이터 변환이 정확한가?
- 상태 관리(전역/로컬, 동기/비동기) 방식이 적절한가?
- 의도치 않은 Side Effect(이벤트 발행, 외부 API 호출, 전역 상태 변경)가 없는가?
- 동기/비동기 흐름에서 순서 보장이 필요한 구간이 안전한가?

### Level 3 – Security / Edge Cases

- 변경이 인증·인가·세션·raw HTML·URL/redirect·server action/API/DB·파일·CORS/CSP·dependency/CI 고위험 트리거에 해당하는가?
- 외부 입력의 source → validation/transform → trust boundary → sink 흐름을 확인했는가?
- 클라이언트 검증이나 UI 가드를 서버 보안 통제로 오인하지 않았는가?
- SQL/NoSQL/OS/템플릿 인젝션 없이 파라미터화 또는 안전한 API를 사용하는가?
- React/DOM XSS escape hatch, 실행 가능한 URL scheme, open redirect 위험이 없는가?
- 하드코딩 자격증명, 클라이언트 번들 secret, 민감 로그·캐시 노출이 없는가?
- cookie session의 CSRF, CORS credentials, CSP와 브라우저 저장소 정책이 프로젝트 결정과 일치하는가?
- 경로 탐색, SSRF, 파일 업로드, ReDoS, race/중복 실행 위험을 관련 코드에서 확인했는가?
- 경계값·빈 목록·타임아웃·예외 경로가 권한을 넓히거나 민감 정보를 노출하지 않는가?
- diff만으로 통제를 검증할 수 없다면 targeted security review 승격을 제안했는가?

### Level 4 – Performance / Efficiency

- 불필요한 연산·렌더·네트워크 요청이 없는가?
- 쿼리/API 호출이 적절히 최적화되어 있는가?
- 메모리/연결/구독 등 리소스가 적절히 해제되는가?

### Level 5 – Style / Maintainability

- 네이밍이 도메인과 팀 규칙에 맞는가?
- 코딩 표준(포매팅, 파일/함수 길이, 주석)을 따르는가?
- 읽는 사람이 흐름을 따라가기 쉬운가?

---

## 5. Detailed Analysis

### Architecture & Design

- [ ] 프로젝트의 architecture patterns를 따르고 있는가?
- [ ] 컴포넌트가 feature structure에 적절히 구조화되어 있는가?
- [ ] 관심사 분리가 명확한가? (components, hooks, APIs, queries)

### Code Quality

- [ ] 읽는 사람이 흐름을 빠르게 파악할 수 있는가?
- [ ] Code smells나 anti-patterns가 있는가?
- [ ] DRY를 따르고 있는가?
- [ ] 변수와 함수 이름이 명확한가?
- [ ] 코드 복잡도(중첩 조건, 함수 길이, 분기 수)가 과도하지 않은가?
- [ ] 중복 로직이 분리되어 재사용 가능한 구조인가? 읽는 사람이 흐름을 빠르게 파악할 수 있는가?

### Performance (React)

- [ ] 불필요한 re-render가 있는가?
- [ ] Memoization이 필요한가? (useMemo, useCallback, React.memo)
- [ ] Code splitting이나 lazy loading 기회가 있는가?
- [ ] API 호출이 최적화되어 있는가?

### Best Practices

| 영역 | 체크 항목 |
|------|----------|
| React | Hooks, dependency arrays 올바르게 사용하고 있는가? |
| State Management | 목적에 맞는 상태 관리 방법이 사용되었는가? |
| Error Handling | 에러가 적절히 catch·처리되는가? |
| Accessibility | 적절한 ARIA labels, 키보드 네비게이션이 지원되는가? |
| Testing | 유틸 함수,리엑트 훅,컴포넌트등에 테스트코드가 작성되었는가? Edge cases가 커버되는가? |

---

## 6. Component Type Checklists

### Authentication / Authorization

- [ ] 비밀번호·토큰이 평문으로 로그·응답에 포함되지 않는다.
- [ ] 인증 실패 시 안전한 에러 메시지만 노출.
- [ ] 인증과 객체별 권한 검사가 보호된 **서버 연산 직전**에 수행된다.
- [ ] UI 가드·role state는 표시 보조일 뿐 인가 SSOT가 아니다.
- [ ] 세션 생성·회전·만료·로그아웃·권한 변경 폐기 흐름이 정의돼 있다.
- [ ] 브라우저 저장소에 session/access/refresh token을 보관하지 않는다.
- [ ] cookie 인증의 CSRF 방어와 cookie 속성이 실제 서버 설정에 적용된다.

### Data Access

- [ ] 쿼리는 파라미터화/prepared statement 사용.
- [ ] 필요한 컬럼만 조회, 인덱스 고려.
- [ ] N+1 쿼리 없거나 배치/조인으로 해소.
- [ ] 트랜잭션으로 묶여 있고 롤백 처리 있음.
- [ ] 대량 결과는 페이지네이션·스트리밍으로 제한.

### API Endpoint

- [ ] 입력의 타입·형식·범위 검증.
- [ ] 인증·인가 미들웨어/가드 적용.
- [ ] 응답 형식 일관, 에러 시 민감 정보 미포함.
- [ ] 적절한 HTTP 상태 코드와 에러 메시지.

### UI Component

- [ ] 시맨틱 HTML·ARIA 접근성 요구사항.
- [ ] JSX 기본 이스케이프를 우회하는 raw HTML/DOM sink가 없거나 중앙 sanitizer를 사용한다.
- [ ] 동적 URL은 허용 scheme/host 정책을 통과한다.
- [ ] 사용자 입력 검증은 UX 보조이며 서버 검증이 별도로 존재한다.
- [ ] 로딩·에러·빈 상태 정의 및 표시.
- [ ] 디자인 시스템·스타일 가이드 준수.
- [ ] 키보드·포커스 상호작용 동작 확인.

### Build / Lint Verification

- [ ] `eslint` 오류 없음.
- [ ] `vitest` 테스트 통과.
- [ ] `build` 클린 빌드 성공.
- [ ] 보안 관련 명령이 미실행이면 `not-run` 사유를 명시하고 통과로 처리하지 않음.

---

## 7. AI-Generated Code Considerations

| 특성 | 대응 |
|------|------|
| **맥락 부족** | 원본 프롬프트·요구사항을 먼저 확인, 시스템 내 위치 파악 후 검토. |
| **낯선 패턴** | 팀 패턴(Provider/Feature 분리, 계약 검증)과 비교, 필요 시 대안 고려. |
| **대량 생성** | 레이어별·파일별로 나누어 검토, 고위험 부분 우선. |
| **겉보기 신뢰** | 로직·보안·엣지 케이스를 명시적으로 검증. |
| **기존 시스템 통합** | 연동 지점에서 계약·에러 전파·성능 영향 확인. |

---

## 8. Severity Classification

심각도는 취약점 이름이나 패턴만으로 정하지 않고 **Likelihood × Impact**로 판단한다.

### Likelihood

| 수준 | 판단 기준 |
|------|-----------|
| High | 외부 또는 낮은 권한 공격자가 현실적인 조건에서 반복 가능하고 통제를 우회할 수 있음 |
| Medium | 인증·사용자 상호작용·특정 구성 등 전제조건이 필요하지만 도달 가능한 경로가 확인됨 |
| Low | 강한 전제조건, 제한된 공격 표면, 유효한 보완 통제로 실제 악용 가능성이 낮음 |

### Impact

| 수준 | 판단 기준 |
|------|-----------|
| High | 광범위한 권한 탈취, 중요 비밀·개인정보 노출, 무결성 훼손, 핵심 서비스 중단 |
| Medium | 제한된 사용자·객체·기능 범위의 기밀성·무결성·가용성 영향 |
| Low | 보안 경계 밖의 제한적 영향, 직접 악용보다 방어 심도·운영 품질 저하 |

| 심각도 | 조합과 조치 |
|--------|-------------|
| **Critical** | High Likelihood × High Impact 중 즉시·대규모 악용 가능. 머지·릴리스 차단 |
| **High** | 한 축이 High이고 다른 축이 Medium 이상. 필수 수정 또는 만료일 있는 보안 예외 필요 |
| **Medium** | 제한된 악용 가능성·영향이지만 유효한 결함. 소유자와 기한을 두고 수정 |
| **Low** | 직접 위험이 작거나 방어 심도 개선. 선택·후속 개선 |

보안 finding은 별도로 `Confidence: High/Medium/Low`를 기록한다. 증거가 부족한 패턴 일치는 심각도를 높이지 말고 `확인 필요`와 미확인 가정을 명시한다.

모든 finding 형식: "현재 문제 → 증거·영향 → 재현/검증 → 권장 방향 → 후속 테스트 → 위치(`file_path:line_number`)".

---

## 9. Path-Based Review Focus

| 경로 패턴 | 검토 초점 |
|-----------|-----------|
| `**/context/**` | 네트워크·상태·계약 검증·에러 전파 |
| `**/*.jsx` | UI 컴포넌트 체크리스트 (접근성, 로딩/에러 상태, 디자인 시스템) |
| `**/model/**` | SSOT 준수, 도메인 규칙 |
| `**/common/**` | 범용성, 사이드이펙트 격리 |

---

## 10. Review Pitfalls

| 함정 | 예방 |
|------|------|
| 표면적 검토 | 문법·포맷만 보지 말고, 레이어별 검토와 체크리스트 적용. |
| "AI 코드라 맞을 것" | 로직·보안·엣지 케이스를 직접 설명·추적. |
| 자동화 과신 | 자동화 결과는 참고로만 사용하고, 최종 판단은 수동 리뷰로 확정. |
| 맥락 무시 | 요구사항·시스템 내 위치 먼저 파악. |
| 테스팅 | 컴포넌트,유틸,훅 등 주요 비즈니스 로직이 포함된 함수(클래스)의 테스트 코드 필요성 및 생성 여부 검토. |
| 보안 검토 생략 | 입력 검증·인증/인가·에러 메시지 노출 항상 점검. |
| 리뷰 피로 | 대량 변경은 구간별로 나누고, 고위험 우선 검토. |
