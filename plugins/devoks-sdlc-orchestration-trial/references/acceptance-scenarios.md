# 실동작 검증 시나리오 표 규칙 (verify 게이트 5)

`devoks-sdlc:verify-acceptance-test`의 **Phase 0(시나리오 합의)·Phase 6(회수)** 을 HOTL용으로 옮긴 trial 문서다.
원본은 사용자와 슬롯을 합의하는 HITL 절차라 그대로 복사하지 않고, 합의 단계를 **spec 단계 초안 작성 → 게이트1에서 사람 리뷰**로 바꿨다.

- 출처: `plugins/devoks-sdlc/skills/verify-acceptance-test/SKILL.md` Phase 0·5·6 (devoks-sdlc 3.9.0, 커밋 `8dd675e`) — 적응 문서라 drift 점검은 `upstream/SOURCES.md` "적응 문서" 절 참고.
- 시나리오 **실행**(사전 상태 확인·조작·UI/영속 대조·연타 (a)/(b) 이중 실행·임시 패치 규칙)은 `devoks-sdlc:acceptance-test-runner` 에이전트가 자기 플러그인의 절차 문서로 수행한다. 이 문서는 **러너에 넘길 입력을 만드는 규칙**만 다룬다.

---

## 1. 적용 조건 — 하나라도 아니면 게이트 5는 `flag`

| 조건 | 판정 방법 | 아닐 때 |
|---|---|---|
| `config.verify.acceptance.enabled == true` | config | `skip` |
| 웹앱이다 | `.claude/project-convention.json`의 `preset`이 `react-native`·`android`·`ios`가 아님 | `flag: 실동작 수동 확인 필요` + §6 수동 체크리스트 |
| 대상 AC가 1개 이상 | §2 선별 결과 | `skip`(대상 없음) |
| chrome-devtools-attach MCP 사용 가능 | `ToolSearch("select:mcp__chrome-devtools-attach__list_pages")`로 스키마 로드 성공 | `flag: 실동작 검증 필요(MCP 미등록)` |
| dev server 기동 명령 설정 | `config.verify.acceptance.devServer.command`가 비어 있지 않음 | `flag: 실동작 검증 필요(devServer.command 미설정)` |
| Chrome 응답 | `curl -sf http://127.0.0.1:9269/json/version` | `flag: 실동작 검증 필요(Chrome 미기동)` |

환경 미비는 RUN 실패가 아니다(설계 D6 — on-the-loop 위임). **Chrome은 기동하지 않는다**(사람의 브라우저·MCP 연결 자원).

### dev server — RUN이 자기 worktree에서 띄운다 (2026-10-27 결정)

고정 URL은 사람이 띄워 둔 **메인 작업트리의 서버**를 가리키게 되어, worktree에 있는 RUN의 코드가 아니라 다른 코드를 검증한다.
그래서 이 게이트에 한해 RUN이 `bash $R/scripts/hotl-devserver.sh start <run-id>`로 **자기 worktree에서** 서버를 띄운다.

- 스크립트가 빈 포트(`portRange`)를 골라 `command`의 `{port}`(및 `PORT` 환경변수)로 기동하고, `readyPath`가 응답할 때까지 기다린 뒤 URL을 출력한다.
- **실동작 락**: Chrome·에뮬레이터·실기기는 기기당 하나이므로, 스크립트가 worktree 공통 git 디렉터리의 락(`hotl-live.lock`)을 잡은 RUN만 서버를 띄운다. 다른 RUN은 `lockTimeoutSec`까지 기다린다. Bash 호출 timeout은 `lockTimeoutSec + readyTimeoutSec`보다 길게 준다(기본 합 390초 → `timeout: 600000`).
- 셸로 `npm run dev` 등을 **직접** 띄우지 않는다 — 포트·종료·락 관리가 빠져 다른 RUN을 막는다(`policy.md` §1·§3).

| `start` 결과 | 게이트 5 |
|---|---|
| URL 출력(exit 0) | 진행 |
| exit 3 락 대기 초과 | `flag: 실동작 검증 필요(실동작 락 대기 초과 — 다른 RUN 사용 중)` |
| exit 4 기동·준비 실패 | `flag: 실동작 검증 필요(dev server 기동 실패)` + 로그 tail 5줄을 PR 본문에. 빌드 오류가 원인이면 게이트 6에서 다시 드러난다 |

## 2. 대상 AC 선별 (spec 단계)

FRD의 AC·CTR·EDGE 중 **UI 조작이 트리거이고, 결과가 화면 상태 또는 영속 상태로 관측되는 것만** 고른다.

- 포함: "WHEN 사용자가 <버튼/입력> … THE SYSTEM SHALL <화면 표시/저장>" 형태, UI로 드러나는 EDGE(에러 모달·재시도 등).
- 제외: 순수 계산·변환·타입·설정값 AC — 유닛테스트가 이미 커버한다(원본 Phase 0 2번과 같은 기준).
- 선별 결과가 0개면 `ACCEPTANCE.md`를 만들지 않는다(`RUN.md` gates 5에 `skip: 대상 AC 없음` 예약).

## 3. 시나리오 표 작성 (spec 단계, `.hotl/runs/<run-id>/ACCEPTANCE.md`)

```markdown
| AC ID | 진입 경로 | 사전 상태 | 조작 | 기대 UI 상태 | 기대 영속 상태 | 근거 |
|---|---|---|---|---|---|---|
| AC-003-1 | `/settings/extraction` | 기계보정 미완료 | "보정 완료" 버튼 클릭 | "완료" 배지 표시 | `calibration.completedAt` 값 존재 | FRD §3 AC-003-1, CTR-002, 라우트 `src/routes.tsx:42` |
```

칸별 근거 — **추측으로 채우지 않는다.** 근거가 없는 칸은 `?`로 두고 FRD §10에 질문으로 올린다(게이트1에서 사람이 답한다).

| 칸 | 채우는 근거 |
|---|---|
| 진입 경로 | FRD §4.1 화면/흐름 → 코드베이스 라우트 정의 파일(경로:라인을 근거 칸에) |
| 사전 상태 | AC의 WHILE/IF 조건, CTR 기본값, 시드 데이터 위치 |
| 조작 | AC의 WHEN 트리거를 클릭/입력/대기 순서로 분해 |
| 기대 UI 상태 | SHALL 뒤 화면 결과 — **문구·배지·단계처럼 텍스트로 대조 가능한 형태**로(러너가 `wait_for(text=…)`로 확인) |
| 기대 영속 상태 | SHALL 뒤 저장 결과 + CTR 값. 영속이 걸리지 않는 AC는 `-` |

**빠른 반복 조작**: 대상 프로젝트에 `.claude/refs/interaction-integrity.md`가 있으면 그 §1 판정을 따르고, 없으면 AC·EDGE에 연타·반복·연속 입력이 명시된 경우만 해당으로 본다. 해당 시 조작 칸에 **횟수와 간격**(`∧ 5회 연타(간격 없음)`), 기대 UI 상태는 **수치**(`입력 횟수만큼 반영`), I/O가 있으면 기대 영속 상태에 `저장 요청 1회로 코얼레싱`을 적는다.

**게이트1 코멘트**에 시나리오 표 요약(대상 AC 수, `?` 칸 목록)을 포함한다. 사람의 승인 = 시나리오 합의다.

## 4. 슬롯 — 질문 대신 설정·도출

| 러너 슬롯 | 값 출처 | 없을 때 |
|---|---|---|
| 시나리오 표 | 승인된 `ACCEPTANCE.md` | — |
| `<DevServerURL>` | `hotl-devserver.sh start`가 출력한 URL(그 RUN의 worktree 서버) | §1 dev server 표대로 `flag` |
| `<PersistenceCheckMethod>` | `config.verify.acceptance.persistenceCheckMethod`(예: `localStorage evaluate_script`, `IndexedDB(PouchDB) 앱 모듈 경유 조회`) | 영속 칸이 `-`가 아닌 시나리오만 `flag: 영속 조회 방법 미설정`으로 빼고 나머지는 실행 |
| `<AuditMarker>` | `config.verify.acceptance.auditMarker` | 기본 `ACCEPT-TEMP` |
| `<WorkspaceVerificationDir>` | `.hotl/runs/<run-id>/verification/` | 만들어서 사용 |
| `<WorkspaceCapturesDir>` | `.hotl/runs/<run-id>/captures/` | 만들어서 사용 |

## 5. verify 단계 실행

1. **표 재확인(구현 후)** — build 중 라우트·문구가 바뀌었으면 **진입 경로·조작 대상 같은 실행 세부만** 현재 코드에 맞게 고친다. 기대 UI·영속 상태는 승인된 스펙이므로 **고치지 않는다**. 고친 칸은 `ACCEPTANCE.md`에 `(수정: 사유)`로 남기고 PR 본문에 옮긴다.
2. **서버 기동** — `bash $R/scripts/hotl-devserver.sh start <run-id>`(Bash timeout 600000). 출력 URL이 `<DevServerURL>`이다. 실패 시 §1 dev server 표대로 flag 처리하고 3~4를 건너뛴다.
3. **위임** — `Agent(subagent_type="devoks-sdlc:acceptance-test-runner")`. 프롬프트에 §4 슬롯 전부와 시나리오 표 전문을 넣는다. 러너는 질문하지 않고 리포트만 리턴한다. 실동작 락을 쥔 동안만 실행되므로 다른 RUN과 Chrome을 동시에 쓰지 않는다(설계 D3). 러너에게 "dev server는 이미 떠 있다 — 기동 금지"를 함께 넣는다.
4. **결과 매핑** — 리포트를 `verification/acceptance-report.md`로 저장하고 시나리오별로 판정한다(아래 표).
5. **서버 종료** — 결과와 무관하게 **즉시** `bash $R/scripts/hotl-devserver.sh stop`으로 서버를 끄고 락을 푼다. FAIL로 수정 루프에 들어가도 먼저 끈다 — 수정 구현 동안 락을 쥐고 있으면 다른 RUN이 기다리다 시간 초과된다. 재실행 시 2부터 다시 한다.
| 러너 판정 | 게이트 5 | 후속 |
|---|---|---|
| ✅ PASS | pass | — |
| ❌ FAIL | fail | 수정 Task로 `code-implementer` 재위임 → 게이트 5부터 재실행(`limits.fixLoops`) |
| ⚠️ 검증 환경 갭 | flag | PR 본문에 재현 못 한 상태를 그대로 옮김 |
| ➖ 영속 확인 불충분 | flag | `데이터 흐름 검증 필요`로 PR 본문에(게이트 4 flag와 합친다) |
| 리포트에 "Chrome DevTools MCP 연결 실패" | flag | 재시도하지 않는다(사람에게 Chrome 기동을 요청할 수 없음) |

6. **임시 패치 회수 확인** — 러너가 회수했다고 보고해도 메인 루프가 직접 확인한다: `grep -rn "<AuditMarker>" <소스 루트>` 결과 0줄, `git status --porcelain`에 승인된 변경 외 흔적 없음. 잔존하면 `git restore <파일>`로 원복하고 정책 이벤트에 기록한다. 원복할 수 없으면 `exception` 게이트(`env-gap`).
7. 게이트 6(검증 명령)은 회수가 끝난 코드로 실행된다 — 순서를 바꾸지 않는다.

> RUN이 어디서 끝나든 `hotl-run-end.sh`가 남은 서버·락을 정리하고, 헤드리스 래퍼도 종료 시 같은 정리를 한다. 그래도 기기가 꺼지는 등으로 락이 남으면 다음 `start`가 주인 프로세스 부재를 감지해 회수한다.

## 6. 수동 체크리스트 (웹앱이 아니거나 flag일 때)

PR 본문 "수동 확인 필요" 절에 시나리오 표의 AC ID·조작·기대 UI·기대 영속을 체크박스로 옮긴다. 웹앱이 아닌 프로젝트(RN·네이티브)는 Chrome에서 흉내 내지 않는다.
