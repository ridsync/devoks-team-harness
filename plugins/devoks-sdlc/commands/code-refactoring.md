---
description: 지정된 파일/모듈을 현황 파악→계획→승인→실행→검증 순서로 리팩토링한다.
---

# 코드 리팩토링 (구조·책임·계약 품질 개선)

## Overview

사용자가 지정한 **파일/폴더/모듈**을 대상으로 현황 파악 → 계획 수립 → 승인 → 실행 → 검증 순으로 리팩토링을 진행한다.

UI 개선이 아닌 **구조·책임·계약·도메인 품질** 개선에 집중한다. 리팩토링은 외부 동작을 변경하지 않는 것이 원칙이며, 동작 변경이 불가피할 경우 반드시 명시한다.

---

## 입력 파라미터

실행 시 아래 정보를 제공받는다.

| 파라미터 | 설명 | 예시 |
|----------|------|------|
| **1) 리팩토링 대상** | 파일, 폴더, 모듈 경로 | `src/context/network/AuthProvider.jsx`, `src/pages/settings/` |
| **2) 리팩토링 목표** | 개선하려는 품질 방향 | `파일 크기 분할`, `Fail-Fast 적용`, `Feature/Provider 분리`, `SSOT 정리` |
| **3) 제약 조건 (선택)** | 제외 범위, 동작 불변 요구 등 | `API 시그니처 변경 금지`, `테스트 제외` |

목표가 없으면 `.claude/CLAUDE.md` 및 `.claude/rules/agent-principles.md` 우선순위 기준으로 위반 항목 전체를 점검한다.

---

## Steps

### 1. 범위 및 목표 확정

1. 대상 파일/모듈 경로 확인
2. 리팩토링 목표 유형 분류:
   - **구조**: 계층 혼재, 모듈 책임 초과, Feature/Provider 미분리
   - **계약**: `require*OrThrow` 누락, Contract 미검증, Fail-Fast 위반
   - **크기**: 파일 1000자 초과, 함수 비대화
   - **네이밍**: 제네릭 이름, 도메인 의미 미반영
   - **코드 품질**: SSOT 위반, 사이드이펙트 미분리, 미사용 코드, import 정렬
3. 제외 범위 명확화
4. 범위 또는 목표가 모호하면 재질문

### 2. 현황 파악 (정보 수집)

대상 파일을 읽고, 동작 이해에 필요한 **직접 의존 모듈만 최소 범위로** 추가 탐색한다.

다음 기준으로 위반 항목을 도출한다.

#### 2-1. 프로젝트 규칙 기준 점검

`.claude/CLAUDE.md`의 프로젝트 구조 및 `.claude/refs/engineering-principles.md`의 Domain and Contract Rules · Code and Comment Rules 전체를 기준으로 점검한다. 핵심 항목:

- 소스 헤더 (`// path/filename` 파일 첫 줄), 코드 크기 (500자 목표 / 1000자 초과 분할)
- 네이밍 (도메인 + 컨텍스트 + 의도 3단어 이상, 제네릭 이름 지양)
- 계층 구조 (Business 상단 → IO/Adapter 중단 → Config/Const/Utils/Types 하단)
- 사이드이펙트 명시·그룹화·격리, Rationale 주석 형식 (`왜:` / `깨짐 영향:` / `수정 경계:`)
- 리팩토링 전 프로젝트 실행 가능 상태 확인

#### 2-2. 프로젝트 규칙 문서 기준 점검

`.claude/rules/` 및 `.claude/refs/` 디렉터리의 규칙 파일을 기준으로 점검한다. 핵심 항목:

- `.claude/refs/engineering-principles.md`: Fail-Fast, SSOT, 평가/실행 분리, 계약 검증 (`require*OrThrow`)
- `.claude/rules/project-convention.md`: 화면·네트워크·DB·제어·모니터링 패턴, Context 훅 (`!ctx`이면 throw), 소스 헤더, import 순서, `useEffect` cleanup, `useMemo`/`useCallback`, console 사용, 입력 검증, 인증/인가, 데이터 보호

> **UDP ingest 예외**: 고빈도 스트림(`UdpProvider.jsx` ingest 경로)은 Fail-Fast 미적용. 단일 이벤트 오류로 파이프라인 중단 금지.

### 3. 리팩토링 계획 수립 및 승인

다음을 정리해 **사용자 승인을 받은 뒤** 코드 변경에 들어간다.

- 수정·생성·삭제 파일 목록
- 문제별 개선 방향 (예: SSOT 위반→분리, 1000자 초과→분할, `require*OrThrow` 누락→추가)
- 동작 불변 보장 전략 또는 동작 변경이 있을 경우 명시
- 리팩토링 우선순위 (아래 기준 참고)

#### 우선순위 기준

| 등급 | 해당 항목 |
|------|-----------|
| **Critical** | SSOT 위반 (중복 상태 정의), Contract 미검증 (입력 검증 누락), Fail-Fast 누락 (silent ignore·과도한 fallback) |
| **High** | 파일 크기 1000자 초과, 계층 구조 혼재 (Business ↔ IO 혼용), 사이드이펙트 미분리, Feature/Provider 미분리 |
| **Medium** | 네이밍 개선 (제네릭 → 도메인 3단어), Rationale 주석 누락·형식 불일치, 소스 헤더 누락 |
| **Low** | import 정렬, console 사용 정리 (→ `createDebugger`), 미사용 코드·import 제거 |

> 사용자 승인 없이 코드를 변경하지 않는다.

### 4. 실행

우선순위 순서(Critical → High → Medium → Low)로 진행한다.

#### Critical: SSOT·Contract·Fail-Fast

- 중복 상태 정의 → 단일 소스로 통합, 참조 경로 갱신
- 입력 검증 누락 → `require*OrThrow` 또는 `__require*OrThrow` 패턴 추가
- silent ignore / 과도한 fallback → 즉시 throw로 교체
- Context 훅 `!ctx`이면 throw 누락 → 추가

#### High: 구조·크기·사이드이펙트

- 1000자 초과 파일 → 역할 기준으로 분할 (비즈니스 로직 / IO / 상수)
- 계층 혼재 → Business / IO·Adapter / Config·Const·Utils·Types 순으로 재배치
- 사이드이펙트 → 명시적·그룹화·격리 처리
- Feature/Provider 미분리 → 평가 로직은 Feature로, 실행·UI·I/O는 Provider로 분리

#### Medium: 네이밍·주석·소스 헤더

- 제네릭 네이밍 → 도메인 + 컨텍스트 + 의도 3단어 이상으로 개선
- Rationale 주석 추가 또는 수정:
  ```
  // 왜: (왜 이 코드가 필요한지)
  // 깨짐 영향: (변경 시 무엇이 깨지는지)
  // 수정 경계: (안전하게 수정 가능한 범위)
  ```
- 소스 헤더 누락 → 파일 첫 줄에 `// packages/capacitor-app/src/.../파일명.js` 추가

#### Low: import·console·미사용 코드

- import 순서 재정렬 (builtin → external → internal → parent → sibling)
- `console.log` → `console.debug`/`info`/`warn`/`error` 또는 `createDebugger` 교체
- 미사용 import·변수·함수 제거

### 5. 검증 및 마무리

- `npm run lint`(Bash)로 수정한 파일 린트 확인, 오류 수정
- 소스 헤더 존재 확인
- 미사용 import 최종 정리
- 리팩토링 요약 및 잔여 작업(추후 분리 필요 항목 등) 안내

---

## Rules

- **SSOT**: 도메인 상태는 단일 소스. 중복 정의 금지. 파생 필드는 computed/read-only
- **Contract**: 모듈 진입부에 `require*OrThrow` 필수. 누락 시 contract 위반
- **Fail-Fast**: 계약 위반·필수값 누락 → 즉시 throw. UDP ingest 경로 예외
- **코드 크기**: 500자 목표, 1000자 초과 시 반드시 분할
- **소스 헤더**: 파일 첫 줄 `// path/filename` 필수. 누락 시 contract 위반
- **네이밍**: 도메인 + 컨텍스트 + 의도 3단어 이상. 제네릭 이름 금지
- **계층**: Business(상단) → IO/Adapter(중단) → Config/Const/Utils/Types(하단)
- **Rationale 주석**: `왜:` / `깨짐 영향:` / `수정 경계:` 형식, 3~5줄, 한국어, 도메인 용어 우선
- **Feature/Provider 분리**: 평가(Feature)에 React·UI·executor 호출 금지
- **승인 우선**: 계획 수립 후 반드시 사용자 승인 받은 뒤 코드 변경
- **동작 불변**: 외부 동작 변경은 리팩토링 범위 밖. 변경 시 반드시 명시
- **Commit 조건**: 프로젝트가 실행 가능한 상태일 때만 커밋. Conventional Commits 형식, 한국어 메시지

---

## 실행 예시

**유저 입력:**

```
대상: src/context/network/AuthProvider.jsx
목표: 파일 크기 감축, Fail-Fast 적용
제약: API 시그니처 변경 금지
```

**실행 순서:**

1. `AuthProvider.jsx` 읽기 + 직접 의존 모듈(`useLocalDocuments`, `useStatusBar` 등) 최소 탐색
2. 위반 항목 도출: 파일 크기 1000자 초과, `require*OrThrow` 누락, silent ignore 패턴 등
3. 계획: `AuthProvider.jsx` → `useAuthCore.js`(로직 분리) + `AuthProvider.jsx`(Provider 잔존), 입력 검증 추가 → 사용자 승인
4. Critical → High → Medium → Low 순으로 실행
5. `npm run lint` 확인, 요약 안내

---

## Checklist

- [ ] 리팩토링 대상·목표·제약 조건 확정 (모호하면 재질문)
- [ ] 대상 파일 및 직접 의존 모듈 탐색 완료
- [ ] `.claude/CLAUDE.md` 및 `.claude/refs/engineering-principles.md` 기준 위반 항목 도출 (소스 헤더, 코드 크기, 네이밍, 계층, 사이드이펙트)
- [ ] `.claude/rules/` 및 `.claude/refs/` 규칙 파일 기준 위반 항목 도출
- [ ] 수정/생성/삭제 파일 목록 및 개선 방향 작성 후 사용자 승인
- [ ] Critical: SSOT/Contract/Fail-Fast 위반 수정
- [ ] High: 1000자 초과 분할, 계층 재배치, 사이드이펙트 분리
- [ ] Medium: 네이밍 개선, 소스 헤더 추가, Rationale 주석 보완
- [ ] Low: import 정렬, console 정리, 미사용 코드 제거
- [ ] `npm run lint` 확인, 린트 오류 수정
- [ ] 리팩토링 요약 및 추후 작업 안내
