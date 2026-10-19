# devoks-core CHANGELOG

플러그인 업데이트 시 **무엇이 왜 바뀌었는지**를 버전별로 기록한다. 특히 **복사 산출물**은 설치된 프로젝트·사용자 홈에 사본으로 남아 자동 갱신되지 않으므로, `devoks-core:setup-preset-manage`가 이 파일을 근거로 "upstream 변경분"과 "로컬 커스터마이징"을 구분한다.

- **복사 산출물** — 플러그인 밖으로 복사되는 파일. 항목 형식: `파일 › 섹션: 추가/변경/삭제 — 사유`
  - base: `rules/agent-principles.md`, `rules/memory-policy.md`, `refs/{code-review,engineering-principles,git-convention,interaction-integrity,workflow}.md`
  - preset: `conventions/<preset>/project-convention.md`
  - 스크립트: `assets/chrome-debug.sh` (→ `~/.devoks/bin/`)
- **스킬·커맨드·훅** — 플러그인과 함께 자동 갱신된다. 사용법이 바뀐 경우만 적는다.

변경이 없는 구역은 생략한다. 1.1.4 이전 기록은 없다.

---

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
