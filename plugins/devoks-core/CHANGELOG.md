# devoks-core CHANGELOG

플러그인 업데이트 시 **무엇이 왜 바뀌었는지**를 버전별로 기록한다. 특히 **복사 산출물**은 설치된 프로젝트·사용자 홈에 사본으로 남아 자동 갱신되지 않으므로, `devoks-core:setup-preset-manage`가 이 파일을 근거로 "upstream 변경분"과 "로컬 커스터마이징"을 구분한다.

- **복사 산출물** — 플러그인 밖으로 복사되는 파일. 항목 형식: `파일 › 섹션: 추가/변경/삭제 — 사유`
  - base: `rules/agent-principles.md`, `rules/memory-policy.md`, `refs/{code-review,engineering-principles,git-convention,interaction-integrity,workflow}.md`
  - preset: `conventions/<preset>/project-convention.md`
  - 스택 한정 refs: `refs/*.md` 중 frontmatter `scope: <preset>`이 있는 파일(active preset과 같을 때만 복사) — `refs/web-security.md`(`react-web`)
  - 스크립트: `assets/chrome-debug.sh` (→ `~/.devoks/bin/`)
- **스킬·커맨드·훅** — 플러그인과 함께 자동 갱신된다. 사용법이 바뀐 경우만 적는다.

변경이 없는 구역은 생략한다. 1.1.4 이전 기록은 없다.

---

## 2.7.1 — 2026-11-12

### 복사 산출물
- `refs/engineering-principles.md` › [Structure & Design] #12 Separation of Concerns: 변경 — "책임 = 변경 이유이며 파일 경계가 아니다, 같은 이유로 바뀌는 함수는 같은 파일"을 덧붙이고 [Structure]를 가리킴. "function마다 책임 하나"가 "함수 1개 = 파일 1개"로 읽혀 과분할 근거가 됐다(careerstack B-7)
- `refs/code-review.md` › Layered Examination Level 1: 변경 — "구조가 일관적인가?"에 판정 기준([Structure]·구조 슬롯 S1~S8)과 신호(함수별 소파일 군집, S4 밖 하위 barrel, 슬롯과 다른 위치)를 연결. 기준 없는 질문이라 리뷰가 과분할을 놓쳤다
- `conventions/react-web/project-convention.md` › Project Decisions S4 Public API: 변경 — 강제 수단 예시 추가(Biome `performance.noBarrelFile`·`performance.noReExportAll` + 공개면 경로만 `overrides`로 해제)

## 2.7.0 — 2026-11-11

### 복사 산출물
- `rules/agent-principles.md` › [Philosophy] DRY: 변경 — "2곳 이상이면 추출"을 **지식 기준**으로 정정. 사실·규칙(도메인 값·분류·스키마·계산 규칙·문구·토큰·경로)은 첫 사용부터 1곳, 함께 바뀌어야 하는 동일 로직은 2번째에 추출, 차이를 플래그로 흡수해야 하는 유사 코드는 3번째 사례로 변하는 축이 보일 때까지 복제 유지, 호출처별 분기가 늘면 인라인으로 되돌림. 기존 문구는 비슷한 코드까지 즉시 추출하게 해 잘못된 추상화를 부를 수 있었다
- `rules/agent-principles.md` › [Philosophy] Reuse-First Ladder (2): 변경 — 기존 자산 탐색을 project convention의 Shared Placement 슬롯 단계 순서(가까운 단계부터)로 하도록 추가. "기존 것을 써라"만 있고 어디를 찾을지가 없어 근처만 찾고 새로 만드는 일이 있었다
- `rules/agent-principles.md` › [Structure] Module Structure & Shared Placement: 추가 — 스택·구조 무관 판정 기준 6개(파일 = 함께 바뀌는 것·단일 함수 파일 허용 사유, 응집 기준 하위 디렉터리, 사용처의 가장 가까운 공통 조상 배치, 범용 공용 계층의 업무 무지·단방향 의존, 모듈 경계당 공개면 1개·순환 0, 공용화 = 계약·강등). 구체값은 Project Decisions 구조 슬롯(S1~S8)이 갖고, 미확정이면 기준만 적용하고 구조를 지어내지 않는다. 구현·설계 경로(code-implementer·design-spec)가 읽는 곳이 `.claude/rules/`라 refs가 아닌 rules에 둔다
- `refs/engineering-principles.md` › [Structure & Design]: 추가 — 배치·공용화 기준은 agent-principles [Structure]·DRY와 구조 슬롯을 따른다는 포인터 1줄(내용 중복 없음)
- `refs/code-review.md` › Code Quality: 변경 — "DRY를 따르고 있는가?"를 지식 기준 DRY 판정으로 바꾸고, 성급한 공용화(사용처 1곳·호출처별 플래그)와 구조 슬롯 위치·기존 공용 자산 중복 신설 체크 2항목 추가. 기존 체크는 중복 신설 방향만 봤다
- `conventions/{react-web,react-native,android,ios,python-fastapi}/project-convention.md` › Coding Style › Module Structure & Shared Placement: 추가 — 판정 기준 SSOT(agent-principles) 포인터 + 스택별 적용 고려사항만(web: 프레임워크 단위·세그먼트 파일·SSR 지시어 경계·barrel·테스트 픽스처 / RN: 플랫폼 파일·`app/` 라우트 / android: Gradle 모듈·`internal`·Kotlin 파일 묶음 / ios: target·access control / python: 역할 파일·`__init__.py` re-export·순환 `ImportError`). android·ios·python의 기존 구조 절은 "제네릭 예시"로 명시. 특정 프로젝트 구조를 규칙으로 고정하지 않기 위해 구체값은 슬롯으로 넘긴다
- `conventions/{5종}/project-convention.md` › Project Decisions: 추가 — 구조 슬롯 S1~S8(Directory Policy·Module Segment·Shared Placement·Public API·Dependency Direction·Promotion·Shared Catalog·Test-only Code), 스택별 예시 placeholder. `미확정` 허용
- `conventions/react-web/project-convention.md` › Project Decisions: 삭제 — `Directory Policy` 한 줄(S1로 대체)

### 스킬·커맨드
- `commands/setup-project-convention.md` › 7. 구조 슬롯 확정: 추가 — 파일 적용 직후 코드베이스 실측(기존)·TRD §8·ADR·preset 예시(신규)로 S1~S8 초안 + 관찰 목록을 만들어 한 메시지로 확인, 미확정 허용, 구조 결정(S1·S4·S5)은 ADR 여부 함께 질문. 기존 7단계(후속 안내)는 8로 이동. 3단계 적용 범위에 6번 항목 추가
- `skills/setup-preset-manage` › 지원 작업·5·6단계: 추가 — 반영 결과 구조 슬롯이 새로 생기거나 비어 있으면 setup 7단계를 이어서 수행(기존 convention의 Directory Policy·SSOT 경로는 슬롯으로 옮기고 중복으로 남기지 않음), 리포트에 미확정 슬롯·관찰 목록

> 이미 setup한 프로젝트: base rules는 `devoks-core:setup-preset-manage`의 "base 갱신"으로, preset 절·슬롯은 같은 스킬의 선택 반영(Coding Style·Project Decisions)으로 가져온 뒤 슬롯 확정 절차를 진행한다. 이미 프로젝트 고유 모듈 규칙을 적어 둔 convention은 그 내용을 슬롯 값으로 옮기면 되고, 새 절을 거부해도 base rule의 기준은 적용된다.

## 2.6.0 — 2026-11-06

### 복사 산출물
- `rules/agent-principles.md` › [State & Context] 19 Persist Decisions: 변경 — 메모리 대상을 작업 선호·피드백·맥락으로 한정하고, 팀 엔지니어링 결정은 저장소 문서로 보낸다. 파일 메모리는 사용자 로컬에만 있어 팀원·CI가 읽지 못하는데, 기존 문구대로면 에이전트가 팀 결정을 개인 메모리에 적을 수 있었다
- `rules/agent-principles.md` › [State & Context] 20 Record Engineering Decisions: 추가 — 이후 코드 작성 방식을 구속하는 엔지니어링 결정(라이브러리·아키텍처·모듈/디렉토리 구조·API 규약·인증·저장/캐싱·테스트 전략)이 되돌리기 비용·모듈 파급·대안 비교·"왜?" 신호 중 하나를 가지면 ADR을 제안하고 사용자 확인 후 `docs/decisions/ADR-NNN-<slug>.md`에 기록. 제품·도메인 정책·버그 수정·기존 패턴 적용은 제외. 스킬 밖 대화에서 내린 결정도 남기기 위한 트리거(형식 SSOT는 devoks-sdlc `adr-guide.md`). 기존 20 Apply Past Feedback은 21로 번호 이동
- `rules/memory-policy.md` › 머리말·계층별 역할·규칙 1·3: 변경 — "저장소 문서"(ADR·PRD·TRD·FRD) 계층을 팀 공유 결정의 SSOT로 추가하고, 파일 메모리는 작업 선호·피드백·맥락의 SSOT로 한정. 충돌 시 팀 결정은 저장소 문서 우선

> 이미 setup한 프로젝트는 `devoks-core:setup-preset-manage`로 base rules를 갱신한다. 로컬에서 규칙 번호(20)를 인용한 문서가 있으면 21로 맞춘다.

## 2.5.0 — 2026-11-04

### 복사 산출물
- `conventions/react-web/project-convention.md` › Stack › Lint/Format: 변경 — `Biome + Oxlint` 병용을 **Biome 단독(기본) / ESLint + Prettier(대안) 택1**로 전환하고 Oxlint 제거. 병용 채택 근거가 기록된 적 없고(2026-07-10 스택 최신화 때 도입), 두 선택지 모두 단독으로 스택 규칙(react·next·tanstackQuery·a11y)을 커버해 병용은 중복 보고·설정 비용만 남는다. 함께 "Biome/Oxlint가 `jsx-a11y`를 커버하지 않는다"는 사실과 다른 서술 정정(Biome `a11y` 그룹 recommended 기본 활성)
- `conventions/react-web/project-convention.md` › Stack › Lint/Format 선택: 추가 — Biome/ESLint 비교표(구성·스택 규칙·타입 인식 규칙·속도)와 ESLint를 고르는 조건(기존 설정·사내 config, type-aware 게이트, Biome에 없는 플러그인)
- `conventions/react-web/project-convention.md` › Stack › SSR Variant: 추가 — Next.js 16 `next lint` 제거·`next build` lint 미실행 → CI에 직접, Biome이면 `next` 도메인
- `conventions/react-web/project-convention.md` › Pitfalls·Project Decisions: 추가 — lint 도구 병용 금지, Lint/Format 택1 기록
- `conventions/react-native/project-convention.md` › Stack › Lint/Format: 변경 — `Biome + Oxlint(+oxlint-config-universe)` → **Biome 단독(기본) / ESLint(`eslint-config-expo`) + Prettier(대안) 택1**, Oxlint 제거. "Biome에 RN 전용 규칙이 없다"는 서술이 사실과 달라 정정(Biome `reactNative` 도메인 존재). Expo 공식 경로는 ESLint(`npx expo lint`)지만 웹 preset과 기본값을 맞추는 사용자 결정 — Biome으로도 lint·format은 동작한다. `oxlint-config-universe`는 Expo 내부 프로젝트용이며 `expo/*` 규칙이 없다
- `conventions/react-native/project-convention.md` › Stack › Lint/Format 선택: 추가 — Biome/ESLint 비교표, ESLint를 고르는 조건, Biome일 때 Expo env 규칙 부재 보완(ast-grep 규칙·리뷰)
- `conventions/react-native/project-convention.md` › Pitfalls: 추가 — `EXPO_PUBLIC_*` 동적 접근·구조분해 시 인라인 안 됨(런타임 `undefined`), lint 도구 병용 금지
- `conventions/react-native/project-convention.md` › Project Decisions: 추가 — Lint/Format 택1과 Biome일 때 env 접근 보완 방식
- `conventions/react-web/project-convention.md` › Stack › Test: 변경 — E2E·접근성 자동검사로 Playwright + `@axe-core/playwright` 추가
- `conventions/react-web/project-convention.md` › Testing: 추가 — 실제 브라우저에서 라우트별 axe 스캔·`violations` 0건 단언, 태그는 TRD §2.1 WCAG 수준을 따름, 자동검사의 한계(키보드·포커스·스크린리더는 수동 보완)
- `conventions/react-web/project-convention.md` › Pitfalls: 추가 — happy-dom에서 axe-core 실행 실패(happy-dom#978)·jsdom의 `color-contrast` 판정 불가, 기존 코드베이스에 0건 게이트를 바로 켜는 문제(기준선 고정 후 신규 위반만 실패)
- `conventions/react-web/project-convention.md` › Project Decisions: 추가 — 접근성 기준·게이트

> 이미 setup한 프로젝트는 `devoks-core:setup-preset-manage`의 diff에서 선택 반영한다 — 기존 코드베이스라면 Pitfalls의 기준선 방식으로 도입한다. Biome+Oxlint를 이미 쓰는 프로젝트는 Oxlint 제거 여부를 프로젝트 결정으로 판단한다(강제 아님).

## 2.4.0 — 2026-11-02

### 복사 산출물
- `conventions/react-web/project-convention.md` › Stack: 변경 — Language를 `JavaScript + JSDoc`에서 `TypeScript (strict: true)`로 전환. 신규 웹 프로젝트의 기본 선택이 TS이고, 에이전트 구현에서 타입체커가 계약 위반을 컴파일 타임에 잡아 주는 이득이 커서다(react-native preset은 이미 TS)
- `conventions/react-web/project-convention.md` › Coding Style › Naming: 변경 — 확장자 `.jsx/.js` → `.tsx/.ts`, 공유 타입 파일(`*.types.ts`)·타입/Props 네이밍 행 추가
- `conventions/react-web/project-convention.md` › Coding Style › Constants: 변경 — `Object.freeze({...} as const)` + 파생 유니온 타입, `enum` 금지와 사유
- `conventions/react-web/project-convention.md` › Coding Style › TypeScript: 추가 — strict·`any` 금지(`unknown`+좁히기)·`as`/`!` 제한·API 응답은 신뢰 경계(zod 파싱+`z.infer`)·`type` 우선·`import type`·공개 API 반환 타입 명시·타입체크는 빌드와 별개(Vite는 타입 검사 안 함)
- `conventions/react-web/project-convention.md` › Component Pattern·UI and Styling·Design Pattern·Data & Platform Integration: 변경 — 모든 코드 예시를 TS로 전환(Context `createContext<T | null>`, Zustand `create<T>()(...)` curried, Props 타입, Model class 타입, axios 응답 zod 파싱, `useForm` 제네릭 규칙), `ImportMetaEnv` 선언 안내
- `conventions/react-web/project-convention.md` › Testing: 변경 — `*.test.ts(x)`, `tsc --noEmit`을 테스트와 별도로 실행
- `conventions/react-web/project-convention.md` › Comment Rules: 변경 — TSDoc 기준, 주석에 타입 재기재 금지
- `conventions/react-web/project-convention.md` › Pitfalls: 추가 — Vite 빌드≠타입체크, 응답 제네릭 오해, `as`/`!` 침묵, `useForm` 단일 제네릭 충돌
- `conventions/react-web/project-convention.md` › Project Decisions: 추가 — API 응답 검증 수준, tsconfig 추가 엄격도. 경로 예시를 `.tsx/.ts`로 변경

> 이미 JS로 setup한 프로젝트는 `devoks-core:setup-preset-manage`의 diff에서 이 변경을 **선택적으로** 반영한다 — JS 코드베이스에 그대로 적용하면 규칙과 코드가 어긋난다.

---

## 2.3.0 — 2026-10-23

복사 산출물 변경 없음(`assets/chrome-debug.sh` 주석의 "번들" 표현은 의도적으로 두었다 — 주석만 고쳐도 `setup-preset-manage`가 갱신 대상으로 판정한다).

### 스킬·커맨드·훅
- `setup-mcp` › Step 6: 변경 — chrome-devtools-attach를 플러그인 번들 안내(`/plugin install devoks-browser`)에서 `claude mcp add --scope user` 등록으로 전환. `devoks-browser` 2.0.0이 번들을 제거한 것과 짝이다. 구버전 번들과의 이중 등록 점검, Node 22 이상 권장(`get_css_styles`가 Node 20에서 `Set.prototype.intersection` 부재로 실패 — 2026-10-23 실측)을 추가
- `setup-mcp` › Overview·Step 8 대조표: 변경 — chrome-devtools-attach 설치 방식을 `claude mcp add`로 정정(prefix `mcp__chrome-devtools-attach__*`는 불변)
- `check-setup-state.sh` › chrome-devtools 감지: 변경 — `have "devoks-browser"` 폴백 제거. 번들이 사라져 플러그인 활성화가 서버 존재를 보장하지 않는다. 경고 문구도 `setup-mcp` Step 6·`claude mcp add` 안내로 교체

---

## 2.2.0 — 2026-10-21

### 복사 산출물
- `refs/web-security.md`: 추가(스택 한정, `scope: react-web`) — React 웹 보안 심화 SSOT(규칙·근거·탐지 시그널, OWASP Top 10:2025 매핑). 2026-07-13 작성분(`a0c0e98`·`1f342ac`)이 브랜치에서 main에 머지되지 않아 누락돼 있던 것을 복원했다. 복원과 함께 §0.1 신뢰 경계 매핑, §7 개인정보 최소화(분석·리플레이·에러 트래킹 payload), §11 파일 업로드, §12 AI/LLM 기능(OWASP LLM Top 10 2025 매핑)을 추가했다. react-web preset이 아니면 복사되지 않는다
- `refs/engineering-principles.md` › [Security]: 추가 — 20. Never Trust the Client. 이후 [Operations & Improvement] 항목 번호가 20~23 → 21~24로 밀렸다(내용 불변)
- `refs/code-review.md` › §4 Level 3: 추가 — 위험 싱크·토큰 저장/로그 노출·LLM 출력 신뢰 금지 체크, 스택 한정 보안 ref 참조 포인터
- `refs/code-review.md` › §6 UI Component: 변경 — XSS 항목에 sanitize 명시, URL 스킴 검증·DOM 직접 조작 금지 2항목 추가
- `refs/code-review.md` › §9: 변경 — `**/*.tsx` 포함, 보안(XSS·URL 인젝션·위험 싱크) 초점 추가
- `conventions/react-web/project-convention.md` › Security: 추가 — 클라이언트 검증은 UX뿐·sanitize·URL 스킴·토큰 저장·공개 env·lockfile·postMessage·업로드/LLM 출력·PII 요약과 `web-security.md` 링크(전문은 ref가 소유)

### 스킬·커맨드·훅
- `setup-project-convention` › refs를 base(frontmatter `scope` 없음)와 스택 한정(`scope: <preset>`)으로 구분, 스택 한정 refs는 선택한 preset과 같을 때만 복사하고 스냅샷에도 기록
- `setup-preset-manage` › base 갱신 대상에 active preset의 스택 한정 refs 포함(목록은 새 원본 frontmatter에서 매번 구함 — 새로 생긴 스택 한정 ref는 `신규`), preset 전환 시 새 preset의 스택 한정 refs 복사·이전 preset 전용 ref는 삭제 여부 확인
- `check-setup-state.sh` › base stale 판정에 active preset의 스택 한정 refs 포함(2.2.0 이전에 setup한 react-web 프로젝트는 `web-security.md` 사본이 없어 base 갱신이 안내된다)

## 2.1.0 — 2026-10-19

### 스킬·커맨드·훅
- `setup-project-convention` › 적용 시 base 7종·preset 원본 스냅샷을 `.claude/.devoks-base/`에 기록 — 다음 갱신의 3-way merge base(구버전 플러그인 캐시는 업데이트 14일 후 삭제되므로 캐시에 의존하지 않는다)
- `setup-preset-manage` › base 갱신을 3-way(스냅샷·사본·새 원본)로 전환, 이 CHANGELOG의 사유를 함께 제시, 스냅샷 없는 프로젝트용 이전 절차 추가
- `check-setup-state.sh` › 스냅샷이 있으면 "스냅샷 ≠ 번들"일 때만 base 갱신을 안내(로컬 커스터마이징만으로는 경고하지 않음)
- 이 `CHANGELOG.md` 신설

## 2.0.0 — 2026-10-19

### 복사 산출물
- `assets/chrome-debug.sh`: 추가 — 기존 `setup-mcp` 본문 인라인 런처를 번들 파일로 분리. 기본 시작 URL은 본문이 아니라 `~/.devoks/chrome-debug.url`에서 읽는다(사본이 원본과 바이트 동일해야 갱신 판정 가능). 구버전 런처의 `START_URL="${1:-<URL>}"` 값은 갱신 시 url 파일로 이전한다

### 스킬·커맨드·훅
- **BREAKING** `project-convention-manage` → `setup-preset-manage` 개명. 관리 대상을 setup 산출물 4종(convention·base 7종·`chrome-debug.sh`·`metro-mcp.js`)으로 확장
- `check-setup-state.sh` › `~/.devoks` 스크립트 2종의 원본 대비 차이 감지

## 1.8.0 — 2026-10-19

### 스킬·커맨드·훅
- `project-convention-manage` › "base 갱신" 작업 유형 추가(이전에는 base 7종 갱신 경로가 `setup-project-convention` 재실행뿐이었다)

## 1.7.0 — 2026-10-19

### 복사 산출물
- `rules/agent-principles.md` › [Philosophy] YAGNI: 변경 — 미구현 대상 목록에서 "error handling" 제거, Safety Floor 참조 추가(맨 YAGNI 지시가 안전 가드를 빠뜨린다는 외부 벤치마크 근거)
- `rules/agent-principles.md` › [Philosophy] Safety Floor (Never Cut): 추가 — 신뢰 경계 검증·데이터 손실 방지 에러 처리·보안·접근성·명시 요청은 단순화 대상이 아님
- `rules/agent-principles.md` › [Philosophy] Reuse-First Ladder: 추가 — 필요성 → 코드베이스 재사용 → 표준 라이브러리 → 설치된 의존성 → 최소 코드, 버그 수정 시 호출부 전수 확인
- `rules/agent-principles.md` › [Done] 6 Tests Pass: 변경 — 테스트 필요 신호(분기·루프·파서·상태 전이·금액/보안·버그 수정·새 스크립트)와 "깨지면 실패하는 테스트 1개" 하한
- `rules/agent-principles.md` › [Done] 8: 변경 — "No Silent TODOs or Gaps"로 개명, 완료 보고에 미확인 범위·잔여 리스크 1~2줄

## 1.6.0 — 2026-09-18

### 복사 산출물
- `rules/memory-policy.md` › 3계층 표: 삭제 — context-mode 세션 메모리 행(context-mode 도입 기각). 규칙 2 "회상 ≠ 진실원천" → "기록 ≠ 현재 사실"로 도구 무관 일반화, 규칙 4 "승격 패턴" 삭제. **context-mode를 실제로 쓰는 환경이면 이 삭제는 거부해도 된다**
- `conventions/*/project-convention.md` (5종) › 구조 패턴 일괄 치환(ast-grep): 추가

## 1.5.0 — 2026-09-15

### 복사 산출물
- `conventions/python-fastapi/project-convention.md`: 추가 — Python FastAPI preset 신설

## 1.4.1 — 2026-08-26

### 복사 산출물
- `refs/code-review.md` › Level 5·Code Quality·§8 Low: 변경 — "주석" 일반 항목을 "자명한 코드에 붙은 불필요한 주석(JSDoc 포함)" 판정으로 구체화, 기준을 프로젝트 Comment Rules로 연결

## 1.4.0 — 2026-08-25

### 복사 산출물
- `refs/code-review.md` › Level 1: 추가 — 기존 호출자 계약(반환 의미·에러 계약·페이로드 스키마·옵셔널→필수) 위반 검증, 타입이 통과해도 깨지는 것에 집중

## 1.3.0 — 2026-08-19

### 복사 산출물
- `refs/interaction-integrity.md`: 추가 — 반복·동시 트리거 정합성(C1~C4) 심화 SSOT
- `refs/code-review.md` › Level 2(C1·C2)·Level 4(C3)·§5 Performance(C3·C4 멱등성·C1/C2)·§10 "개발 머신 기준 판정": 추가 — 위 SSOT를 참조하는 리뷰 체크
- `conventions/{react-web,react-native,android,ios}/project-convention.md` › 반복 입력 관련 스택별 구체 문법: 추가

## 1.2.2 — 2026-07-27

### 복사 산출물
- `conventions/react-web/project-convention.md` › 주석·에러 처리·Provider Header 가이드: 보강

## 1.2.1 — 2026-07-27

### 복사 산출물
- `refs/git-convention.md` › revert 예시: 변경 — 특정 도메인 예시를 범용 예시로 교체(내용 변화 없음)

## 1.2.0 — 2026-07-14

### 복사 산출물
- `conventions/{react-web,react-native,android,ios}/project-convention.md`, `conventions/README.md`: 추가 — preset 원본을 플러그인 내부로 이전(이전에는 플러그인 루트 밖에 있어 설치 프로젝트에서 접근 불가)

## 1.1.4 — 2026-07-13

### 복사 산출물
- `refs/code-review.md` › Pre-Review Gate·Performance·Best Practices·Build 검증: 변경 — eslint/prettier/vitest/React 등 스택 고유명을 "프로젝트의 lint/타입/테스트 도구"로 일반화
- `refs/git-convention.md` › 예시 전반: 변경 — 특정 도메인(brew·mqtt) 예시를 범용 예시로 교체, lefthook 미설정 안내 줄 삭제
- `refs/workflow.md` › SSOT 링크: 변경 — `.claude/code-review.md`·`.claude/git-convention.md` → `.claude/refs/...`(경로 버그 수정)
- `refs/workflow.md` › 배포: 삭제 — APK 빌드(`app.deploy.sh`·Gradle) 명령. 배포 파이프라인은 프로젝트별이라 `.claude/CLAUDE.md` 또는 `project-convention.md`에 두도록 안내로 교체. **로컬 사본에 APK 섹션이 남아 있다면 upstream 원본의 잔재이지 로컬 커스터마이징이 아니다**
- `rules/agent-principles.md` › Graceful Degradation: 변경 — core flows 예시 `(auth, brew, sensor-ingest)` → `(auth, checkout, payment)`(특정 도메인 하드코딩 제거). **로컬 사본에 `brew, sensor-ingest`가 남아 있다면 upstream 원본의 잔재다**
