# HOTL trial 파이프라인

`hotl-run` 스킬의 실행 SSOT. 정책은 `policy.md`, 게이트는 `gate-protocol.md`, 이슈 조작은 `adapter-contract.md`를 따른다.
아래에서 `$R` = `${CLAUDE_PLUGIN_ROOT}`, `issue` = `$R/scripts/hotl-issue.sh`.

```
[hotl:run] → spec ─▶ (게이트1 spec) ─▶ build ─▶ verify ─▶ deliver(draft PR) ─▶ (게이트2 머지: 사람)
                          ▲                │  └─▶ (action/exception 게이트) ─▶ resume ─┘
                          └── spec-revise ─┘
```

## 0. 공통 — RUN 시작·종료 처리

1. `.hotl/config.json`을 읽는다. 없으면 **exception으로 정지하지 않고 즉시 종료**하며 "`/devoks-sdlc-orchestration-trial:hotl-setup` 먼저 실행"을 출력한다(게이트를 열 이슈 맥락도 확정되지 않은 상태라).
2. **가드 활성화**: `bash $R/scripts/hotl-run-start.sh <run-id>`로 `.hotl/ACTIVE`를 만든다(헤드리스 래퍼는 `DEVOKS_HOTL_RUN=1`도 함께 건다). 종료 시(정상·게이트 정지·실패 모두) 반드시 `bash $R/scripts/hotl-run-end.sh`로 지운다 — 남으면 일반 세션에서도 가드가 켜진다.
   - `.hotl/ACTIVE`를 셸로 직접 만들거나 지우지 않는다. 가드가 RUN 중 그 경로의 쓰기를 차단한다(RUN이 스스로 가드를 끄지 못하게 하려는 것). 시작·종료 스크립트만 쓴다.
3. **동시 실행 방지**: 이슈 라벨에 `hotl:building`이 있으면 새 RUN을 시작하지 않고 종료한다.
4. 모든 단계에서 **사용자에게 질문하지 않는다**(AskUserQuestion 금지). 결정이 필요하면 게이트를 연다.
5. **본문 파일**: 게이트 코멘트·PR 본문은 Write 도구로 `.hotl/runs/<run-id>/reports/<gate-id 또는 pr>.md`에 **매번 새 파일**로 쓴 뒤 어댑터에 넘긴다. 셸 리다이렉트로 같은 임시 파일을 재사용하지 않는다(zsh `noclobber` 환경에서 덮어쓰기가 조용히 실패해 빈 코멘트가 올라간 사례 — 어댑터는 빈 본문을 거부한다).
6. **커밋 메시지**는 대상 프로젝트의 커밋 컨벤션(`.claude/rules`·`.claude/refs`의 git 규칙, 훅이 주입하는 안내)을 **첫 커밋 전에** 확인해 따른다. push한 커밋은 force push가 금지이므로 고칠 수 없다.
7. **HITL 스킬 본문을 호출하지 않는다**(`devoks-sdlc:feature-*`, `verify-*`, `code-review` 등 — Phase 0 질문 때문). 에이전트만 이름으로 위임한다.

## 1. RUN 상태

- 작업 브랜치: `hotl/<issue번호>-<slug>` (slug = 이슈 제목 kebab-case 영문 5단어 이내, 없으면 `task`). **브랜치가 진행 SSOT**다 — CI 러너는 휘발성이므로 상태는 브랜치 커밋과 이슈 라벨에만 둔다.
- 상태 디렉터리: `.hotl/runs/<run-id>/` — `RUN.md`(템플릿 `$R/assets/RUN.template.md`), `FRD.md`, `PLAN.md`, `reports/`.
- `run-id` = `<issue번호>-<YYYYMMDD>-<nn>`. 같은 이슈의 재실행은 기존 브랜치·run-id를 이어 쓴다(spec-revise 포함).
- `RUN.md` frontmatter의 `status`·`pending_gate`·`gates[]`·Task 체크박스가 재개점이다. 상태를 바꿀 때마다 브랜치에 커밋한다(메시지 `chore(hotl): <run-id> <상태>`).

## 2. Stage spec — 이슈 → FRD/PLAN → 게이트1

1. `issue fetch <n>`으로 이슈를 읽는다. spec-revise 재진입이면 `issue comments <n> --after <spec 게이트 opened_at>`으로 사람 피드백을 읽어 반영 대상으로 삼는다.
2. 브랜치를 만들거나 체크아웃한다(`config.base`에서 분기). 코드베이스를 스캔해 관련 모듈·패턴·테스트 위치를 파악한다.
3. **FRD.md 작성** — 골격은 `$R/references/upstream/FRD.template.md`, AC는 `ears-acceptance-criteria.md` 규칙. 이슈에 없는 값은 코드베이스 근거로만 채우고, 근거 없는 결정은 **§10 Assumptions & Open Questions에 "질문"으로 남긴다**(추측 기입 금지).
4. **PLAN.md 작성** — 골격 `PLAN.template.md`, `size`·`test` 마커는 `task-pr-splitting.md`. PR은 1개 기본(분리 근거가 없으면 나누지 않는다).
5. **traces 누락 0 점검** — `traceability.md`의 스크립트를 `.hotl/runs/<run-id>/`에서 실행. 누락이 있으면 Task를 보강하고 다시 점검.
5-1. **실동작 시나리오 표** — `config.verify.acceptance.enabled`이면 `$R/references/acceptance-scenarios.md` §2·§3대로 대상 AC를 선별해 `ACCEPTANCE.md`를 쓴다(근거 없는 칸은 `?` + FRD §10 질문). 꺼져 있으면 건너뛴다.
6. **위험 예측** — PLAN의 Task별로 `policy.md` §2 승인 게이트 대상이 될 작업(의존성 추가·삭제·보안 경계 등)을 미리 표시한다(RUN.md `risk_forecast`). 게이트1 리뷰어가 미리 승인 범위를 판단할 수 있게 한다.
7. 브랜치 커밋·push(일반 push). `config.gates.spec == false`면 8을 건너뛰고 바로 Stage build로.
8. **게이트1 열기** — 코멘트(`gate-protocol.md` 형식): 목표 1줄, REQ/AC 개수와 목록, Task 표(size·test·file), §10 질문, `risk_forecast`, 시나리오 표 요약(대상 AC 수·`?` 칸 — 있을 때), 브랜치 링크. `issue label-add <n> hotl:spec-review`. `RUN.md`에 `pending_gate`(type `spec`, `opened_at`) 기록·커밋·push 후 **종료**.

> FRD §10에 "질문"이 있는데 게이트1이 꺼져 있으면(`gates.spec=false`) build로 넘어가지 않고 `exception` 게이트(`spec-gap`)를 연다.

## 3. Stage build — 구현

1. `pending_gate.type == spec`이면 `issue approval <n> hotl:spec-approved --after <opened_at>`로 검증한다. 실패면 종료(`gate-protocol.md` 재개 규칙). 통과하면 응답·대기 라벨을 제거하고 `hotl:building`을 부착한다. 사람이 승인 코멘트에 조건을 남겼으면 `comments --after`로 읽어 `context`에 반영한다.
2. PLAN의 선행이 끝난 Task부터 순서대로 실행한다. 라우팅은 `upstream/task-delegation.md`의 `size` 규칙을 따르되 **공통 예외 ①(사용자 상호작용 필요)·③(스펙 미완결)은 trial에서 `exception` 게이트로 대체**한다.
   - `S` → 메인 루프 직접 구현.
   - `M`·위임 가능한 `L` → `Agent(subagent_type="devoks-sdlc:code-implementer")`. 프롬프트에 `task`(Task 원문)·`plan`·`frd`(절대 경로)·`context`(인계 노트 윈도잉 + "사용자 질문 금지, 스펙 공백은 blocked")를 넣는다.
   - `limits.parallel > 1`이고 `[P]` Task가 둘 이상이면 `isolation: "worktree"`로 동시 위임할 수 있다(실험). 각 worktree 결과는 Task 순서대로 작업 브랜치에 병합하고, 충돌이 나면 그 Task를 순차로 재실행한다.
3. **위임 결과 판정** — `upstream/task-delegation.md` 리포트 스키마·재실행 트리거·**테스트 무력화 점검**을 그대로 적용한다. done이면 `[x]`·인계 노트 기록·커밋. blocked면 재위임(상한 `limits.taskRetries`) 후에도 막히면 `exception` 게이트.
4. **승인 게이트 직전 정지** — 구현 중 `policy.md` §2 작업이 필요해지면, 그 작업을 하기 **전에** 현재까지 커밋·push하고 `action` 게이트를 연 뒤 종료한다(`RUN.md` `pending_gate.checkpoint` = 다음에 할 Task·작업). 게이트에서 멈출 때는 `hotl:building`을 **제거**한다 — 남아 있으면 다음 `stage=auto`가 중복 실행으로 판정해 재개하지 못한다. 게이트1에서 `risk_forecast`로 이미 명시 승인된 작업은 다시 묻지 않는다(승인 코멘트에 해당 항목이 명시된 경우만).
5. 모든 Task `[x]` → Stage verify.

## 4. Stage verify — 자동 게이트 체인

순서는 `devoks-sdlc`의 구현 후 체크리스트(원칙: 코드 변경을 유발하는 검증은 앞, 실동작 확인은 마지막)를 따른다. 결과는 `RUN.md` `gates[]`에 `pass|fail|flag|skip` + 근거 1줄로 기록한다.

| # | 게이트 | 방법 | 실패 기준 |
|---|---|---|---|
| 1 | traces·요구 충실도 | 실행 시점 traces 재점검 + FRD AC별로 diff·테스트 설명의 AC ID 대조(메인 루프) | 누락 AC 존재 |
| 2 | 코드 리뷰 | `Agent(devoks-sdlc:code-reviewer)` — `mode: diff-branch`, `scope: <config.base>` | Critical/High |
| 3 | 보안 리뷰 | 조건부 — 2에서 보안 지적이 있거나 diff가 인증·입력검증·시크릿·의존성을 건드릴 때 `Agent(devoks-sdlc:code-security-reviewer)` `scope: <변경 경로>` | Critical/High |
| 4 | 데이터 흐름 · UI 시각 | 자동 판정하지 않는다 — 해당 변경이면 `flag`("데이터 흐름 검증 필요"/"UI 확인 필요")로 PR 본문에 남김 | — |
| 5 | 실동작 | 조건부 — `$R/references/acceptance-scenarios.md`: §1 적용 조건(설정·웹앱·MCP·devServer.command·9269 응답) 충족 시 `hotl-devserver.sh start`로 **RUN worktree의 dev server**를 띄우고(실동작 락) 승인된 `ACCEPTANCE.md`와 §4 슬롯으로 `Agent(devoks-sdlc:acceptance-test-runner)` → 즉시 `stop`. 결과는 §5 매핑·임시 패치 회수 확인. 미충족이면 `flag`/`skip` | FAIL 시나리오 |
| 6 | 검증 명령 | `config.verify.commands`(lint·test·build 등)를 순서대로 직접 실행 — **결정론적 최종 게이트** | 비0 종료 |

- 실패 시 원인을 수정 Task로 만들어 `code-implementer`에 재위임 → 실패한 게이트부터 재실행(상한 `limits.fixLoops`).
- 상한 후에도 실패면 `exception` 게이트(`severity-block` 또는 `test-failure`). 단 `config.deliverOnBlock == true`면 draft PR을 만든 뒤 게이트를 연다(리뷰어가 PR에서 상황을 볼 수 있게).

## 5. Stage deliver — draft PR

1. 남은 변경을 Conventional Commits로 커밋(`devoks-git` 규약 — 커맨드 본문은 호출하지 않고 형식만 따른다)하고 일반 push.
2. PR 본문 파일 작성: 이슈 링크(`Closes #n`은 쓰지 않는다 — 머지 판단은 사람), 요약, REQ/AC ↔ Task ↔ 테스트 추적표, `gates[]` 결과, `flag` 목록(수동 확인 필요), 승인된 게이트 이력, 미확인·리스크(위임 리포트에서 수집), 테스트 무력화 점검 결과.
3. `issue pr-draft <branch> <base> "<type>: <요약> (#n)" <body-file>` → PR URL.
4. `issue label-rm <n> hotl:building`, `issue label-add <n> hotl:pr-open`, 이슈에 PR 링크 코멘트. `RUN.md` `status: delivered` 커밋·push.

## 6. Stage resume — 게이트 응답 처리

1. `RUN.md`의 `pending_gate`를 읽는다. 없으면 종료.
2. `hotl:rejected`가 게이트 이후에 붙었으면(`approval`로 검증) 거절 처리: `action`이면 코멘트에 "대안"이 있을 때 대안으로 checkpoint부터 재개, 없으면 `status: rejected`로 종료. `exception`·`spec`이면 `status: rejected` 종료.
3. `hotl:approved`(spec 게이트는 `hotl:spec-approved`) 검증 통과 → 결정 코멘트를 `gates` 이력에 요약 → 라벨 소비 → `checkpoint`부터 해당 Stage를 이어서 실행.
4. 응답이 없으면 아무것도 바꾸지 않고 종료(대기 유지).

## 7. 종료 리포트

RUN이 어느 지점에서 끝나든(게이트 정지 포함) 마지막 출력은 다음 형식이다. 헤드리스에서는 이것이 로그에 남는다.

```
HOTL RUN <run-id> — <status>
- 이슈: <url> · 브랜치: <branch> · PR: <url|-> 
- 진행: Task <done>/<total> · 게이트: <gates 요약>
- 대기: <pending_gate 요약 | 없음>
- 정책 이벤트: <가드 차단·게이트 개방 횟수와 사유>
- 다음 행동(사람): <라벨 응답 / PR 리뷰 / 없음>
```

마지막으로 `$R/scripts/hotl-run-end.sh`를 실행해 `.hotl/ACTIVE`를 제거한다(실동작 단계에서 띄운 dev server·락이 남아 있으면 함께 정리).
