# orchestration 파이프라인 명세 (단계 1b MVP + 단계 2 검증 강화)

`orchestration-run` 스킬이 따르는 비-HITL 파이프라인의 실행 SSOT. 모든 단계는
`${CLAUDE_PLUGIN_ROOT}/references/orchestration-policy.md`(deny-list·격리·한도·에스컬레이션)를 준수한다.

> ⚠️ **미검증 전제:** 크로스-플러그인 에이전트 호출(`devoks-sdlc:code-implementer` 등)은 post-publish 스모크로만
> 최종 확인된다(dev-live 갭). 아래 위임은 모두 **단일 지점**(§위임 규약)을 거치므로, 전제가 반증되면 그 지점만 교체한다.

---

## RUN 상태 스키마

RUN은 대상 프로젝트 워크스페이스에 `RUN.md`(진행 SSOT)를 만들고 frontmatter에 메타를 고정한다.

```yaml
---
run-id: <이슈식별자-YYYYMMDD-nn>
issue-ref: <Linear 이슈 URL/식별자>       # D4: MVP는 수동 입력
policy-version: 0.2.0                      # 실행 시점 정책 버전 고정(감사용)
status: intake|planning|implementing|verifying|delivering|done|escalated
gates: { requirements: -, code-review: -, data-flow: -, ui: -, acceptance: -, tests: - }
---
```

- `RUN.md`는 `devoks-sdlc`의 PLAN-as-SSOT 원칙을 차용 — 세션이 끊겨도 재개 가능(체크박스·status·gates로 재개점 판정).
- 중간 산출은 사람 검토용 리포트가 아니라 **머신 가독 상태 + 이벤트 로그**(D 대비표). 사람은 예외(에스컬레이션) 시만 본다.

---

## 위임 규약 (단일 지점 — 전제 반증 시 여기만 교체)

기존 HITL 스킬은 **수정하지 않는다**. 자율 안전(A등급) 에이전트를 `dependencies`로 선언한 `devoks-sdlc`에서
**이름으로 위임 호출**한다(설계 근거: `docs/orchestration-design.md` "재사용 경계"):

| 용도 | 위임 대상 | 방식 |
|---|---|---|
| 구현 | `devoks-sdlc:code-implementer` | Agent 도구 `subagent_type`, worktree 격리, 단일 태스크 |
| 코드리뷰 | `devoks-sdlc:code-reviewer` | Agent 도구, 리포트 수령 |
| 보안 | `devoks-sdlc:code-security-reviewer` | Agent 도구, 리포트 수령 |
| 실동작 검증 | `devoks-sdlc:acceptance-test-runner` | Agent 도구, 시나리오 표 주입(스킬 본문 아님) |
| 테스트 작성 | `devoks-sdlc:test-writer` | 필요 시 |

> B등급 verify **스킬**(`verify-requirements`·`verify-data-flow`·`verify-acceptance-test`)의 **본문은 호출하지 않는다**
> (Phase 0 사용자 합의 때문). 실동작은 위 runner 에이전트로, 요구사항/데이터흐름은 §Verify의 대체 경로로 처리한다.

---

## Stage 1 — Intake / 정규화

1. 트리거 입력(Linear 이슈 식별자/URL)을 받아 `RUN.md` 생성, `run-id`·`issue-ref`·`policy-version` 고정.
2. 이슈 본문에서 목표·제약·수용 조건을 추출. 입력이 빈약하면 **정책 기본값·코드베이스 스캔**으로 보완하되,
   **추측 상한**을 넘거나 스펙이 결정 불가면 진행하지 않고 **에스컬레이션**(정책 §7).
3. `status: intake → planning`.

## Stage 2 — Plan / 분해 (HITL 스킬 재사용 대신 자체 제어 흐름)

FRD/PLAN **저작 스킬은 HITL이라 재사용 불가** → 오케스트레이터가 그 **규약만** 적용해 직접 산출한다(파일 복사 없음):
1. 요구사항을 **EARS 5패턴** AC로 정형화(`WHEN…SHALL`/`WHILE`/`IF…THEN`/`WHERE`/보편). 각 AC는 테스트와 1:1.
2. 작업을 단일·검증가능·증분 Task로 분해하고 `TASK-ID`·`[P]`(병렬 가능)·`size`(S/M/L)·`test`(required/skip)·`traces`(REQ/AC/CTR/EDGE) 부여.
3. PR 단위 그룹핑(경계 모호 시 **정책 기본값**으로 결정 — 사용자 질문 없음, D1).
4. **traces 커버리지 0 누락** 자기검증(모든 REQ/AC/CTR/EDGE가 Task로 커버). 누락이면 에스컬레이션.
5. `RUN.md`에 Task 목록·의존성 그래프 기록, `status: planning → implementing`.

## Stage 3 — Implement (worktree 병렬)

1. 선행이 끝난 Task부터, **동시 최대 4개**(정책 §5) worktree에 배치해 `code-implementer`에 병렬 위임.
   - `[P]` Task만 동시 실행. 같은 파일군을 만지는 Task는 순차(worktree로 충돌 격리하되 병합 순서 고려).
2. 각 위임은 단일 Task + 검증 근거(명령·exit code·출력 tail·`test: required` 시 테스트 케이스) 리턴을 요구.
3. `done` 리포트의 근거를 확인해야 Task를 완료로 표시. `blocked`면 **재시도 최대 2회**(정책 §5) 후 에스컬레이션.
4. 모든 Task 완료 → worktree 병합(barrier) → `status: implementing → verifying`.

## Stage 4 — Verify 체인 (단계 2: 자동 게이트)

순서 SSOT = `post-implementation-checklist.md`. **각 게이트를 자동 실행**하고 결과를 `RUN.md`의 `gates`에 기록:

1. **요구사항** — FRD의 REQ/AC 대비 구현 충실도 확인(슬롯 선주입으로 비대화식 실행; B등급 스킬 본문 대신 대체 경로).
2. **코드리뷰** — `code-reviewer` 위임. **Critical/High 발견 시 게이트 실패**(정책 §4) → draft 유지·머지 차단.
3. **보안** — `code-security-reviewer` 위임. 심각도 임계 동일 적용.
4. **데이터 흐름** — `verify-data-flow`는 사람이 앱 구동을 요구하는 지점이 있어 **MVP 완전자율 부적합**(D6식) →
   조건부: 자동 계측 가능 범위만 확인, 아니면 **"데이터 흐름 검증 필요" 플래그**를 draft PR에 남기고 통과 처리.
5. **UI 시각 품질** — 해당 시 visual diff(조건부).
6. **브라우저 실동작 검증(D6, 조건부·직렬)** — dev server + Chrome(9269) **감지 시** `acceptance-test-runner`에
   시나리오 표를 주입해 커밋 직전 직렬 실행(정책 §3 allowlist 예외). **미감지 시** "실동작 검증 필요" 플래그로 위임.
   Chrome attach는 싱글턴이라 병렬 불가 → 병합 후 단일 직렬.
7. **테스트 회귀** — `test-run-triage`로 스위트 회귀 확인.

### 게이트 실패 처리 (단계 2)
- **자동 수정 루프 최대 2회**(정책 §5): 실패 게이트의 원인을 Task로 만들어 `code-implementer` 재위임 → 재검증.
- 2회 내 미해결 → `status: verifying → escalated`, blocked 자동 분류(아래) + 에스컬레이션.
- 모든 게이트 통과 → `status: verifying → delivering`.

### blocked 자동 분류 (단계 2)
`blocked` 리포트를 범주로 분류해 에스컬레이션 메시지에 태그:
`spec-gap`(스펙 공백) · `flaky`(비결정 테스트) · `env-gap`(검증 환경 재현 불가) · `severity-block`(심각도 초과) · `deny-list`(정책 저촉) · `budget`(한도 초과).

## Stage 5 — Deliver (draft PR)

1. Conventional Commits로 커밋(`devoks-git` 규약 재사용). **deny-list 준수**(force-push·main 직접 push·`--no-verify` 금지).
2. **draft PR** 생성(D1: auto-merge 금지). 본문 = 추적성(traces)·테스트 요약·리스크·미해결 플래그(실동작/데이터흐름 검증 필요 등).
3. 심각도 차단 or 자동화 제외(정책 §8) 항목이 걸리면 **머지 차단 + 필수 사람 리뷰** 플래그.
4. `status: delivering → done`(또는 게이트 미통과분이 있으면 draft 유지).

## Stage 6 — Report + 에스컬레이션

1. RUN 종료 리포트(성공/부분/실패) + 아티팩트 링크(PR·RUN.md).
2. **에스컬레이션(이중 채널, 정책 §6)** — 원본 이슈(Linear) 코멘트 + Slack 알림 동시.
   - **MVP fallback:** 어댑터(Linear/Slack) 미배선 시 **콘솔 + RUN 종료 리포트**로 대체(단계 3에서 배선).
   - 시크릿·전체 diff 원문 노출 금지(요약·경로·라인 참조만).

---

## 재개 (resume)

세션이 끊기면 `RUN.md`의 `status`·`gates`·Task 체크박스만 다시 읽어 재개점을 판정한다(`devoks-sdlc` progress-tracking 원칙 차용).
