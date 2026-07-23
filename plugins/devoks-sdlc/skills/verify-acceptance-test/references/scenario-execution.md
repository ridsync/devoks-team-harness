# 시나리오 실행 절차 (Phase 1~4, acceptance-test-runner 에이전트)

## 도구 로드 순서

1. Chrome DevTools MCP 스키마 로드:
   ```
   ToolSearch("select:mcp__chrome-devtools-attach__list_pages,mcp__chrome-devtools-attach__navigate_page,mcp__chrome-devtools-attach__wait_for,mcp__chrome-devtools-attach__click,mcp__chrome-devtools-attach__fill,mcp__chrome-devtools-attach__take_screenshot,mcp__chrome-devtools-attach__evaluate_script,mcp__chrome-devtools-attach__list_console_messages")
   ```
2. 연결 확인(`list_pages`) — 실패 시 리포트에 "Chrome DevTools MCP 연결 실패"를 기록하고 다음 시나리오로 넘어가지 않는다(메인 루프가 사용자에게 재확인 요청).

## 시나리오 1건 실행 순서

Phase 0의 시나리오 표 각 행에 대해 아래를 반복한다.

1. **사전 상태 세팅 확인** — `<PreconditionSetup>`이 이미 충족돼 있는지 `evaluate_script` 또는 화면 확인으로 먼저 점검한다. 충족 안 됐으면 `<PersistenceCheckMethod>`로 세팅하거나(가능한 경우), 세팅이 코드 변경 없이 불가능하면 리포트에 "사전 상태 세팅 불가 — 수동 세팅 필요"로 기록하고 다음 시나리오로 넘어간다.
2. **진입** — `navigate_page(url=<DevServerURL>/<EntryRoute>)` → `wait_for(text=<진입 확인 텍스트>)`.
3. **조작** — `<Interactions>`를 순서대로 수행(`click`/`fill`/`press_key` 등).
4. **UI 상태 대조** — `wait_for(text=<ExpectedUIState 문구>, timeout=5000)`로 확인. 타임아웃되면 FAIL로 기록하고 `take_screenshot`으로 실패 시점 캡처.
5. **영속 상태 대조** — `<PersistenceCheckMethod>`로 실제 저장값을 조회해 `<ExpectedPersistence>`와 대조한다. 얕은 1회 조회로 충분한지 판단하고, 다층 계측이 필요하면 FAIL 대신 "영속 확인 불충분 — verify-data-flow 권장"으로 기록한다.

## 프로젝트별 영속 조회 패턴 예시

`<PersistenceCheckMethod>`는 프로젝트마다 다르다. Phase 0에서 확인된 방법을 그대로 쓰되, 예시:

- **웹앱 + IndexedDB(PouchDB 등)**: `evaluate_script`로 앱이 이미 로드한 DB 모듈을 통해 직접 조회(동적 import 경로는 프로젝트별로 다르므로 Phase 0에서 확인).
- **웹앱 + localStorage/sessionStorage**: `evaluate_script(function: () => localStorage.getItem('<key>'))`.
- **서버 연동 앱**: 별도 API 호출 또는 `list_network_requests`로 저장 요청의 응답 payload 확인.
- 위 방법으로 부족하면(레이어별 계측 필요) 직접 수행하지 말고 리포트에서 `verify-data-flow` 호출을 제안한다.

## 임시 패치가 필요한 경우

진입 경로/사전 상태를 코드 변경 없이는 만들 수 없는 경우(예: 에뮬레이터가 목표 상태를 재현 못함)에만 임시 패치를 허용한다.

1. 추가하는 모든 코드에 `// [<AuditMarker>]` 주석을 단다(기본 `ACCEPT-TEMP`).
2. 시나리오 확인 직후 즉시 회수: `git restore <패치된 파일>`.
3. 회수 실패나 잔존이 있으면 리포트에 명시한다(Phase 6에서 메인 루프가 재확인).
4. 패치로도 목표 상태를 재현할 수 없으면(에뮬레이터/환경 자체의 한계) FAIL이 아니라 "검증 환경 갭"으로 분류하고, 어떤 상태를 재현하지 못했는지 구체적으로 기록한다.

## 금지 사항

- **사용자에게 질문 금지** — 슬롯 값은 호출 시 주입받는다. 연결 오류·환경 갭은 리포트에 기록한다.
- **dev server 기동 금지** — 이미 실행 중인 서버만 사용한다.
- **임시 패치 잔존 금지** — 시나리오 확인 직후 즉시 회수, 실패 시 리포트에 명시.
- **리포트 외 잡설 금지** — 최종 메시지는 검증 리포트 전문이다.
