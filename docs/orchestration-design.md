# devoks-sdlc-orchestration 설계 결정 (SSOT)

비-HITL(human-out-of-the-loop을 지향하되 현 단계는 human-on-the-loop) SDLC 오케스트레이션 플러그인
`devoks-sdlc-orchestration`의 **확정 설계 결정** 단일 진실원천.

> 최초 작성: 2026-07-23 · 기준: `devoks-sdlc` 1.10.0
>
> 이 문서는 "무엇을 만들지"의 **결정**을 담는다. 배경·대비표·외부연동 키워드·단계적 도입 표 등
> "왜/후보군"은 `docs/roadmap.md`의 `devoks-sdlc-orchestration` 항목이 SSOT이며 여기서 링크로 참조한다.
> 구현은 별도 세션(단계 1 MVP)에서 진행한다 — 이 문서는 아직 **플러그인 신설 이전의 설계 단계** 산출물이다.

---

## 배경 요약

현재 `devoks-sdlc`(`feature-workflow-runner` 중심)는 FRD 슬롯·설계 스펙·PR 경계·브랜치/이슈 사전체크·
Phase 4 후속 메뉴까지 총 7개 지점에서 사람이 멈춰 서는 **HITL 전제**다. 검증(verify/review/security/실동작)조차
게이트가 아니라 제안 메뉴이며, `post-implementation-checklist.md`는 "자동 실행/자동 게이트(비-HITL)는
`devoks-sdlc-orchestration`의 소관"이라 명시한다. 이 문서는 그 비-HITL 변형의 핵심 설계 축을 확정한다.

**설계 근거 (2025~2026 리서치, Anthropic 공식 중심):**
- 자율성은 스위치가 아니라 **다이얼** — 실수 비용에 비례해 낮게 시작, 신뢰가 쌓이면 상향.
- 사람 승인 대체의 정론: **실행가능 스펙 게이트(EARS)** + **환경층 격리(네트워크 차단 샌드박스; worktree만으론 불충분)** + **체크포인트/롤백** + **재시도상한·deny-list**. LLM-judge 액션 리뷰어는 상위 옵션.
- 실패 모드: reward hacking, spec drift(Goodhart), 불가역 egress → "환경층 격리 먼저, 모델층 유도 나중."
- 프로덕션 스윗스팟: **spec-anchored / human-on-the-loop / PR 단위 리뷰**. 완전 무리뷰는 아직 aspirational.

---

## 확정 결정 (D1~D6)

### D1. 자율성 다이얼 = human-on-the-loop + draft PR
- 예외(게이트 실패·불확실성·blocked) 시에만 사람 개입. 정상 경로는 무중단.
- 산출은 **draft PR 단위 아티팩트 리뷰** — 오버사이트를 "액션 단위"에서 "아티팩트 단위"로 이동.
- **auto-merge 제외 — draft PR only.** main 직접 푸시 금지.
- dial 상향(out-of-the-loop)은 evals·신뢰 축적 후 **별도 후속 결정**.

### D2. HITL 대체 게이트 스택 (MVP 채택 3종) + 검증 순서
1. **EARS 실행가능 스펙 게이트** — AC를 EARS 5패턴으로 정형화(테스트와 1:1). `FRD`·`ears-acceptance-criteria.md`·`traceability.md` 재사용. `traces` 커버리지 0 누락 + `test: required` 통과를 진행 게이트로 승격.
2. **격리·복구** — 네트워크 차단 OS 샌드박스 + worktree 병렬 격리 + git/체크포인트 롤백. 불가역 사고를 **결정론적 경계**로 차단.
3. **한도·안전** — 재시도 N회 상한, 위험행동(force-push·삭제·시크릿/네트워크 egress) **deny-list**, 불확실성/blocked 시 자동 에스컬레이션.
- **MVP 제외:** LLM-judge 액션 리뷰어(auto-mode transcript classifier 패턴). dial 상향 시 1순위 추가 후보.

**자동 게이트가 승격시킬 검증 체인** — 순서 SSOT는 `plugins/devoks-sdlc/skills/feature-workflow-runner/references/post-implementation-checklist.md`이며, 여기서 **복제하지 않고 참조**한다(1.10.0에서 확정된 순서가 이후 또 바뀌어도 drift 없도록).
현재 확정 순서(요지): 요구사항 → 코드리뷰 → 데이터 흐름 → UI 시각 품질 → 브라우저 실동작 검증(커밋 직전 최종 게이트) → 테스트 회귀 → 커밋 → draft PR.
- 원칙: 코드 변경을 유발하는 검증은 앞, "지금 커밋될 코드가 실제 동작하는가"는 모든 변경 반영 후 커밋 직전 최종.

### D3. 실행 모델 = Workflow 툴 + worktree 병렬 (라이브 검증은 직렬 barrier)
- `task-delegation.md`의 **순차 위임 금지** 근거("단일 워킹트리 Edit 충돌")를 worktree 격리가 해소 → **orchestration에서만** 금지를 해제하고 `Workflow` 툴의 `pipeline`/`parallel`로 독립 태스크 병렬 구현.
- **경계:** `devoks-sdlc`(HITL)의 순차 위임 규칙은 **불변**. 병렬 해제는 orchestration RUN 한정.
- **라이브 검증 barrier:** 브라우저 실동작 검증은 Chrome attach(9269)가 **싱글턴 공유 자원**이라 worktree 병렬 불가 → 구현은 병렬, **병합 후 실동작 검증은 단일 직렬 게이트**로 수렴.

### D4. 진입 트리거
- **목표 트리거 SSOT = Linear**(이슈 → RUN 매핑).
- **MVP = 수동 트리거**(Linear 이슈 식별자/URL 입력). 웹훅·라벨·assignee·스케줄 자동 트리거는 **단계 3으로 연기**.

### D5. 에스컬레이션 = 이중 채널 (원본 이슈 코멘트 + Slack 알림) 동시
- RUN이 막히면 원본 이슈(Linear)에 사유·부분변경·제안 코멘트 **그리고** Slack 알림을 함께 발송.
- 두 채널 모두 어댑터(MCP/CLI thin-wrapper) 필요 → **단계 2~3에서 배선**. MVP fallback: 콘솔/RUN 종료 리포트.

### D6. 브라우저 실동작 검증 = 조건부 게이트 (graceful degradation)
- **감지 시 자동 게이트:** dev server 기동 + Chrome(9269 attach) 사전 확인되면 `verify-acceptance-test`를 **커밋 직전 직렬 게이트**로 자동 실행. 이 스테이지에 한해 샌드박스는 **localhost(dev server)+9269만 allowlist 예외**(네트워크 전면 차단의 최소 개구부).
- **미감지 시 위임:** 환경이 없으면 게이트를 강제하지 않고 **draft PR에 "실동작 검증 필요" 플래그**를 남겨 on-the-loop에서 사람이 수행.
- 근거: 저장소 원칙("명시적 처리 + 비핵심 경로 graceful degradation") + D1(on-the-loop) 정합. 라이브 환경 복잡도를 MVP 필수경로에서 분리.

---

## 재사용 경계 — 기존 HITL 스킬 수정 없음 (검증 2026-07-23)

`devoks-sdlc`의 기존 스킬/에이전트는 **한 줄도 수정하지 않는다.** 신규 `devoks-sdlc-orchestration` 플러그인만
생성하고, 기존 자산은 `plugin.json`의 `dependencies`에 `devoks-sdlc`를 선언한 뒤 **이름으로 호출**해 재사용한다.
재사용 경계는 세 층으로 갈린다:

| 층 | 자산 | 재사용 방식 |
|---|---|---|
| **① 자율 안전 에이전트** | `code-implementer`·`code-reviewer`·`code-security-reviewer`·`test-writer`·`acceptance-test-runner` | **그대로 위임 호출**. 모두 "사용자 질문 금지, blocked 반환" 명시(자율 안전). `직접 호출 금지` 마킹은 사용자용 소프트 가드일 뿐 스킬/오케스트레이터 위임은 허용(plugin-management.md:389). |
| **② HITL verify 스킬** | `verify-requirements`·`verify-data-flow`·`verify-acceptance-test` | 본문은 Phase 0 사용자 합의가 있어 **직접 재사용 불가(수정도 안 함)**. `verify-acceptance-test`는 A등급 러너 `acceptance-test-runner`를 직접 구동. `verify-data-flow`는 사람이 앱을 구동하는 지점(L128)이 있어 **MVP 완전자율 부적합 → D6식 조건부/플래그 위임**. `verify-requirements`는 슬롯(spec=FRD) 선주입 구동 또는 자체 검증 호출. |
| **③ FRD/PLAN 저작 스킬** | `feature-frd-author`·`feature-plan-author`·`feature-plan-executor`·`feature-workflow-runner` | "제안→확인/누락 슬롯 질문" 루프가 **설계상 의도된 HITL 척추**(plugin-management.md:389). 스킬 본문 재사용 불가(수정도 안 함) → 오케스트레이터가 **자체 비-HITL 제어 흐름**을 구현하고 저수준 **자산만** 재사용. |

**저수준 재사용 자산(HITL 없음):** FRD/PLAN 템플릿, `traceability.md`(커버리지 comm 스크립트), `ears-acceptance-criteria.md`, `task-pr-splitting.md`. 단, **플러그인 루트 밖 경로 참조 금지**(plugin-management.md:32) — 소유 스킬을 이름으로 호출하거나, 오케스트레이터가 **자체 사본을 번들**한다(경로 include 불가).

**순차 위임 규칙 유지:** `task-delegation.md:82-85`의 "한 번에 한 태스크(같은 워킹트리 병렬 Edit 충돌 방지)"는 devoks-sdlc의 reference 자산이며 **수정하지 않는다**. 병렬 실행(D3)은 오케스트레이터가 **worktree 격리 + Workflow 툴**로 자체 구현 — devoks-sdlc의 순차 규칙과 충돌하지 않는다(서로 다른 제어 흐름).

**의존성:** `devoks-sdlc` 선언 시 권한 재선언 없이 에이전트/스킬 호출 가능(roadmap.md:204, `deploy-kit`↔`secrets-vault` 검증 패턴). 단 크로스-플러그인 **에이전트 이름 해석**은 in-repo 검증 선례가 없고 설계 의도(roadmap.md:91)로만 서술됨 → **MVP 빌드 시 실제 호출 가능 여부를 우선 스모크 검증**한다.

---

## 파이프라인 (확정 결정 반영)

```
[수동 트리거: Linear 이슈] → [Intake/정규화] → [Plan/분해(EARS·traces)] → [Implement(worktree 병렬)]
   → ═══ 병합 barrier ═══ → [Verify 체인(직렬, 순서=post-implementation-checklist SSOT)]
        요구사항 → 코드리뷰 → 데이터흐름 → UI → (조건부)실동작검증 → 테스트회귀
   → [Deliver: 브랜치·커밋·draft PR(auto-merge 금지)] → [Report + 이중채널 에스컬레이션(예외 시)]
```

- **공유 자산(devoks-sdlc 재사용):** FRD/PLAN 템플릿, `task-delegation`·`traceability`, EARS AC, 검증·리뷰 스킬(`verify-requirements`·`verify-data-flow`·`code-review`·`code-security-review`·`test-run-triage`·`verify-acceptance-test`), 심각도 SSOT, 에이전트(`code-implementer`·`code-reviewer`·`code-security-reviewer`·`acceptance-test-runner`).
- **신설(orchestration 전용):** 오케스트레이터 스킬(Workflow 기반), RUN 상태 스키마(`run-id`·`issue-ref`·`policy-version`), 트리거/에스컬레이션 어댑터, 재시도·롤백·deny-list 정책, `devoks-git` 연동.
- **의존성:** `devoks-core`·`devoks-git`·`devoks-sdlc`(스킬 참조). `verify-acceptance-test`를 쓰므로 **`devoks-browser`가 transitive 의존**(1.10.0에서 devoks-sdlc가 이미 `dependencies`로 선언).
- **격리 처방 층위:** 대상 프로젝트에 "네트워크 차단 샌드박스 + worktree"를 **필수 전제로 처방/문서화**(플러그인은 OS 샌드박스를 강제 못하므로 정책·가이드로 규정). 실동작 검증 스테이지만 localhost+9269 allowlist 예외(D6).

---

## 단계적 도입에 확정 결정 매핑

`docs/roadmap.md`의 단계 표(0~4)를 SSOT로 하고, 각 단계에 확정 결정을 매핑한다.

| 단계 | 확정 결정 반영 |
|---|---|
| **0 — 정책** | D1·D2·D5·D6 반영한 정책 SSOT `plugins/devoks-sdlc-orchestration/references/orchestration-policy.md`(자동화 허용 범위·deny-list·에스컬레이션·격리 allowlist, `policy-version 0.2.0` — 번들 단일본, docs 사본 없음) |
| **1 — MVP** | D3·D4·D6 — 수동 트리거 → worktree 병렬 구현 → 검증 체인(실동작=조건부) → draft PR → 리포트. **0.2.0 저작 완료(2026-07-23): `orchestration-run` 스킬 + `references/pipeline.md`(7단계·RUN 스키마) + 정책 번들 이관. validate --strict ✔.** 크로스-플러그인 에이전트 호출 실동작은 **post-publish 스모크 대기** |
| **1b/2 검증 게이트** | (2에 포함) 자동 게이트·재시도(2회)·blocked 자동분류·에스컬레이션을 `pipeline.md` Stage 4에 저작 — 스모크 통과 후 실동작 |
| **2 — 검증 강화** | D2·D5 — 검증 체인 자동 게이트·재시도(2회)·blocked 자동분류는 `pipeline.md` Stage 4에 **저작 완료**. 이슈 코멘트/Slack **어댑터 배선은 미완**(단계 3, MVP는 콘솔 fallback) |
| **3 — 트리거** | D4·D5 — Linear 웹훅·라벨 RUN 큐, Slack 완성 |
| **4 — 운영** | RUN 큐·동시성·비용상한·감사로그·evals. dial 상향(out-of-the-loop) 검토 진입점 |

---

## 남은(의도적으로 열어둔) 결정

- dial 상향(out-of-the-loop/auto-merge) 시점·조건 및 LLM-judge 리뷰어 도입.
- Linear 이슈 스키마 ↔ RUN 메타(`run-id`·`issue-ref`·`policy-version`) 매핑, 웹훅/스케줄 설계(단계 3).
- Slack/Linear 어댑터를 MCP로 할지 CLI thin-wrapper로 할지.
- 조건부 실동작 게이트(D6)의 환경 감지 방식(dev server·9269 프로브)과 병렬 RUN 간 Chrome 싱글턴 큐잉 정책.
