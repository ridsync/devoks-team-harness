---
description: 코드리뷰 규칙
---

# Code Review Guide

AI(Claude Code, Cursor, Copilot 등)와 사람이 코드리뷰 시 일관되게 참고하는 SSOT 가이드.
일반 코드와 AI 생성 코드 모두에 적용한다.

참고: [Vibe Coding – Code Review Guidelines](https://docs.vibe-coding-framework.com/best-practices/code-review-guidelines), [CodeRabbit – Review instructions](https://docs.coderabbit.ai/guides/review-instructions),
[OWASP Secure Code Review Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Secure_Code_Review_Cheat_Sheet.html), [OWASP Secure Coding Practices Quick Reference](https://owasp.org/www-project-secure-coding-practices-quick-reference-guide/stable-en/02-checklist/)

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

- 외부/사용자 입력 검증 누락이 없는가? (타입, 범위, 포맷)
- SQL 인젝션 위험(문자열 결합 쿼리) 없이 파라미터화되어 있는가?
- XSS 위험(미검증 입력 렌더링, 미이스케이프 출력)이 없는가?
- 하드코딩 자격증명(비밀번호, 토큰, 키)이 없는가?
- 인증/인가 검사가 보호 연산 **이전**에 수행되는가?
- 경로 탐색, 명령어 인젝션, ReDoS 위험은 해당 코드에서 최소한으로 확인했는가?
- 경계값/빈 목록/타임아웃/예외 경로에서 민감 정보 노출이 없는가?
- 위험 싱크(innerHTML류 DOM API, 동적 코드 실행, 미검증 URL의 href/src)를 직접 사용하지 않는가?
- 토큰·자격증명이 스크립트 접근 가능한 저장소(webStorage 등)나 로그에 노출되지 않는가?
- 웹 프론트엔드 코드는 `.claude/refs/web-security.md`(존재 시)의 탐지 시그널·심화 체크를 함께 적용한다.

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
- [ ] 권한 검사가 보호된 연산 **이전**에 수행된다.
- [ ] 토큰 만료·갱신·저장 방식이 보안 권장사항을 따른다.

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
- [ ] 사용자 입력 검증·이스케이프 (XSS 방지) — 원시 HTML 렌더링은 sanitize 필수.
- [ ] 사용자 입력이 href/src/URL로 흐를 때 스킴 검증 (javascript: 차단).
- [ ] 프레임워크 이스케이프를 우회하는 DOM 직접 조작 없음 (상세: `.claude/refs/web-security.md`).
- [ ] 로딩·에러·빈 상태 정의 및 표시.
- [ ] 디자인 시스템·스타일 가이드 준수.
- [ ] 키보드·포커스 상호작용 동작 확인.

### Build / Lint Verification

- [ ] `eslint` 오류 없음.
- [ ] `vitest` 테스트 통과.
- [ ] `build` 클린 빌드 성공.

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

| 심각도 | 대상 | 예시 |
|--------|------|------|
| **Critical** | 보안 취약·데이터 손실·시스템 오류 | SQL 인젝션, 민감 정보 노출 |
| **High** | 보안·정확성·심각한 버그 | rate limiting 누락, 잘못된 비즈니스 로직 |
| **Medium** | 유지보수·일관성·성능 | 중복 코드, 과도한 re-render |
| **Low** | 스타일·문서·코스메틱 | 네이밍, 포맷팅, 주석 |

형식: "현재 문제 → 권장 방향 → 해당 위치(`file_path:line_number`)"

---

## 9. Path-Based Review Focus

| 경로 패턴 | 검토 초점 |
|-----------|-----------|
| `**/context/**` | 네트워크·상태·계약 검증·에러 전파 |
| `**/*.jsx`, `**/*.tsx` | UI 컴포넌트 체크리스트 (접근성, 로딩/에러 상태, 디자인 시스템) + 보안(XSS·URL 인젝션·위험 싱크) |
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
