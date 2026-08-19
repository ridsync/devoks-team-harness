<!--
Phase 3 템플릿 — new-smoke-test-draft 생성기가 이 파일을 읽어 아래 꺾쇠괄호(<...>) 자리를 확정된 값으로
채운 뒤, 대상 프로젝트의 `.claude/skills/<생성될 스킬 이름>/SKILL.md`로 쓴다. 이 주석 블록은 채워 넣을 때
제거한다. description에 콜론+공백(`: `)이 들어가면 반드시 따옴표로 감싼다.
-->
---
name: <생성될 스킬 이름>
description: "<프로젝트 이름> 배포 전 <도메인 요약> 주요 화면이 정상 동작하는지, 이미 실행 중인 dev server에 devoks-browser(Chrome DevTools MCP, 9269 attach)로 접속해 화면 진입·핵심 요소 노출·콘솔 에러 유무를 스모크 수준으로 점검하고 화면별 PASS/FAIL/BLOCKED 리포트를 낸다. 단위/통합/E2E 자동화 스위트를 대체하지 않는다 — 배포 직전 큰 문제는 없는지 빠르게 훑는 회귀 스모크 확인용. \"배포 전 테스트\", \"스모크 테스트\", \"주요기능 확인\" 키워드에서 호출한다."
metadata:
  author: <TODO: 담당자>
  version: 1.0.0
  generatedBy: devoks-sdlc:new-smoke-test-draft@1.0.0
  generatedFrom: <감지된 라우트/화면 정의 파일 경로>
---

# <생성될 스킬 이름> — 배포 전 스모크 테스트

이 스킬은 프로젝트 자신이 소유·유지보수한다 — `devoks-sdlc:new-smoke-test-draft`가 <생성 날짜>에 생성한
초안이며, 그 이후 devoks-sdlc는 이 파일과 어떤 동기화 관계도 갖지 않는다.

배포 직전에 주요 화면을 실제 실행 중인 앱에서 훑어, 배포를 막을 만큼 큰 문제(화면이 아예 안 뜸, 콘솔
에러, 핵심 버튼 비활성·무반응)가 없는지 빠르게 확인한다. 단위/통합/E2E 자동화 테스트 스위트를 대체하지
않는다 — 이 스킬은 테스트 코드를 남기지 않는 1회성 실동작 확인이다.

## 모드

| 모드 | 설명 | 실행 시점 |
|------|------|-----------|
| 1. 코어 스크린 스모크 체크 | 아래 화면 목록을 전부 순회하며 로드 성공·콘솔 에러 유무·핵심 요소 노출을 확인 | 배포 전 |
| 2. 온디맨드 딥다이브 | 사용자가 특정 화면을 지정해 "OO 화면 세부 테스트해줘"처럼 요청할 때만, `references/deep-dive-checklist.md`의 해당 섹션을 따라 세부 UX 시나리오를 검증 | 요청 시 |

> 모드 2는 `references/deep-dive-checklist.md`에 화면 목록·섹션 골격까지만 생성돼 있고 실제 시나리오
> 본문은 `TODO`로 비어 있습니다 — `new-smoke-test-draft`는 화면 이름과 라우트만 스캔했을 뿐 실제 조작
> 순서는 모르므로, 시나리오는 프로젝트가 직접 채워야 합니다.

## 전제

- `devoks-browser` 플러그인(Chrome DevTools MCP, `mcp__chrome-devtools-attach__*`, 9269 attach)이 설치돼
  있어야 동작한다. 미설치 시 설치를 안내하고 추측으로 진행하지 않는다.
- dev server가 이미 실행 중이어야 한다. 꺼져 있으면 이 스킬이 직접 켜지 않고 사용자에게 실행을 요청한다.
- Chrome이 `--remote-debugging-port=9269`로 이미 실행 중이어야 한다.

## 스코프: 화면 목록 (실제 코드가 SSOT)

아래 표의 SSOT는 `<감지된 라우트/화면 정의 파일 경로>`입니다 — 라우트가 바뀌면 이 표도 프로젝트가 직접
갱신해야 합니다(`new-smoke-test-draft`의 스캔은 생성 시점의 스냅샷일 뿐입니다).

| ID | 화면 | 라우트 | 사전조건 | 확인 항목 |
|----|------|--------|----------|-----------|
| <ID> | <Screen> | <route-path> | <TODO: 동적 라우트면 파라미터 확보 방법 — 프로젝트가 채움> | 로드 성공(콘솔 에러 0) · 핵심 요소 노출 |

딥다이브(모드 2)가 필요한 화면은 `references/deep-dive-checklist.md`를 참고하세요.

---

## Phase 0 — 스코프 합의

1. **범위 확인** — 전체 또는 특정 화면만 확인할지 1회 확인한다(요청에 이미 명시돼 있으면 생략).
2. **연결 확인** — `mcp__chrome-devtools-attach__list_pages`로 devoks-browser 연결 상태와 현재 페이지를
   확인한다. 연결 실패 시 Chrome을 `--remote-debugging-port=9269`로 실행해 달라고 안내 후 재시도.
3. **라우트 대조** — 위 SSOT 파일을 다시 확인해 이 표가 stale하지 않은지 점검하고, 라우트가 추가/제거됐으면
   표를 먼저 갱신한 뒤 실행한다.
4. **route param 화면의 값 확보** — `<TODO: 동적 라우트 화면마다 실제 UI 액션을 통한 런타임 내비게이션으로
   id를 확보하는 방법을 프로젝트가 직접 채운다 — 임의 값을 지어내 채우지 않는다>`.

## Phase 1~2 — 실행

화면마다:

1. `navigate_page`로 라우트 이동
2. `list_console_messages`(직전 네비게이션 이후, `error`/`warn`만)로 콘솔 에러 확인
3. `take_snapshot`으로 핵심 요소 노출·주요 버튼 활성/비활성 상태 확인
4. 표기된 확인 항목이 있으면 해당 동작을 실제로 수행해 완료 신호까지 확인

> **TODO — 전담 서브에이전트 추가(선택)**: 스크린샷·콘솔 바이트를 메인 루프 밖으로 격리하고 싶다면 아래를
> 따라 서브에이전트를 추가하세요(이 초안 v1은 서브에이전트 없이 메인 루프에서 직접 실행합니다).
> 1. 제안 파일 경로: `.claude/agents/<생성될 스킬 이름>-runner.md`
> 2. 필수 frontmatter: `name`, `description`(agent-internal 성격 표기), `tools`, `model: sonnet`
>    (스펙이 닫힌 실행 역할이라 상위 모델을 쓸 이득이 없습니다).
> 3. **주의**: `tools:` frontmatter는 화이트리스트로 동작합니다 — 실제 사용할 MCP 도구(devoks-browser가
>    제공하는 Chrome DevTools MCP 등)의 정확한 이름을 하나라도 빠뜨리면 에이전트가 그 도구를 호출하는
>    모든 단계에서 조용히 차단됩니다. 만들기 전에 devoks-browser 스킬 문서에서 실제 tool 이름을 확인하고,
>    추측으로 채우지 마세요.
> 4. 참고할 기존 패턴: `devoks-sdlc:verify-acceptance-test`의 `acceptance-test-runner`, 또는
>    `devoks-browser:browser-visual-diff`의 `browser-visual-diff-capture`(이름만 참고 — 내용을 그대로
>    복사하지 마세요).

**금지**: 실제 배포·파괴적 설정 변경(계정 삭제 등)은 실행하지 않는다 — 조회·진입·비파괴적 버튼까지만.
**해피패스 원칙**: 실제 존재하는 데이터로만 진입한다 — 데이터가 없으면 임의 값을 만들지 않고 BLOCKED로
남긴다.

## Phase 3 — 리포트

`references/report-template.md` 형식으로 화면별 PASS/FAIL/BLOCKED, 콘솔 에러 목록, 스킵한 화면(사유
포함), 소요 시간을 정리한다.

---

## Rules

- 화면 목록 SSOT(`<감지된 라우트/화면 정의 파일 경로>`)가 바뀌면 이 파일의 화면 목록도 프로젝트가 직접
  갱신한다 — `new-smoke-test-draft`는 재실행되지 않는다.
- 라우트 파라미터 값을 임의로 지어내지 않는다.
- `references/deep-dive-checklist.md`의 시나리오 본문이 비어 있으면(`TODO`) 임의로 채우지 않는다 — 프로젝트가
  직접 채운 뒤에만 그 섹션으로 모드 2를 실행한다.
- 리포트 형식은 스코프가 좁은 요청이어도 그대로 적용한다.
