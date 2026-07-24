# 구현 완료 후 다음 단계 체크리스트

> 구현(Phase 3/태스크 실행)이 끝나면 검증·리뷰·보안·커밋·PR로 이어지는 흐름이 있지만, 이 흐름은
> **에이전트가 그때그때 기억에 의존해 제안하거나 누락**하기 쉽다. 이 문서는 그 표준 메뉴를
> 고정해, `feature-workflow-runner` Phase 4와 `feature-plan-executor`의 "마무리" 절이 **항상
> 같은 체크리스트를 출력**하게 한다.

## 원칙 — HITL 선택 실행 vs 비-HITL 자동 오케스트레이션

- 표준 메뉴는 마무리 시점에 **AskUserQuestion `multiSelect`로 제시**하고, **사용자가 고른 항목만** 이 스킬
  (`feature-workflow-runner`/`feature-plan-executor`)이 **메뉴 순서대로 위임 실행**한다(HITL 선택 실행). 선택은 곧 명시 요청이다.
- 이는 **비-HITL 자동 실행·자동 게이트**(사용자 개입 없이 파이프라인이 스스로 실행·판정)와 다르다 — 그 시나리오는
  `devoks-sdlc-orchestration`의 책임 범위이고 역할이 겹치지 않는다. 여기서는 매 단계가 사용자 선택으로만 시작되고,
  위임 대상 스킬/커맨드는 각자 자체 확인 플로를 유지한다.
- **안전 인터록:** 앞선 검증/리뷰(요구사항·코드 리뷰·데이터 흐름·실동작)에서 **Critical/High** 이슈가 나오면
  커밋·PR 위임 **전에 멈추고** 사용자에게 계속할지 확인한다(깨진 코드 자동 커밋 방지).
- **커밋·PR도 선택 시 위임한다** — 단 `devoks-git:git-commit-msg`/`git-pull-request`가 각자 메시지·본문 확인 플로와
  deny-list(force-push·`main` 직접 push·`--no-verify` 금지)를 **최종 게이트**로 유지한다. 선택하지 않은 항목은 실행하지 않는다.

## 표준 메뉴

구현 완료 시점(Phase 4 / 마무리)에 아래 순서로 검토하고, 해당하는 항목만 리포트에 남긴다.
조건부 항목은 조건에 맞지 않으면 리포트에서 생략해도 된다.

| 순서 | 항목 | 스킬/커맨드 | 조건 | 비고 |
|------|------|------------|------|------|
| 1 | 요구사항 구현 충실도 재확인(F/B/E/D) | `devoks-sdlc:verify-requirements mode=verify spec=<out>/FRD.md` | 항상 | 별도 체크리스트 파일(`mode=checklist`) 생성은 생략한다 — `FRD.md` §3(REQ/AC)·§5(Contract)·§8(Edge Case)이 이미 각각 F/B/E/D 카테고리에 ID로 대응되는 구조화된 문서라 중복 생성 불필요. Phase 4의 traceability 재점검("할당 커버리지" — AC/CTR/EDGE가 어떤 Task에 배정됐는가)과 달리, 이 검증은 "배정된 게 실제 코드로 올바르게 구현됐는가"(diff 수준 충실도, ✅/⚠️/❌+심각도)를 재확인하는 것이 목적. **U(UI/UX 세부 사양)는 범위 밖** — FRD §4 Design Spec은 컴포넌트/아키텍처 구조 중심이라 i18n 키·색상 인디케이터·버튼 활성 조건 같은 UI 세부는 ID로 강제 추적되지 않는다. 이 갭은 `docs/roadmap.md`의 "UI 작업 분리 검토" 항목으로 별도 추적 중(항목 4와 함께 그 결정을 기다린다) |
| 2 | 코드 리뷰 | `devoks-sdlc:code-review-diff-branch` | 항상 | Critical/High 보안 이슈 발견 시 이 스킬이 자체적으로 `code-security-review` 실행을 권장 문구로 제시한다(기존 에스컬레이션 로직 재사용 — 여기서 중복 안내하지 않는다). 정적 분석이라 비용이 낮고, 여기서 구조적 문제가 나오면 이후의 비용이 큰 라이브 검증(3~5번)에 들인 노력이 낭비되므로 앞쪽에 둔다 |
| 3 | 데이터 흐름 정합성 검증 | `devoks-sdlc:verify-data-flow` | 조건부 — 입력→계산→저장→재로드 흐름(폼 제출, 영속화, 상태 동기화 등)이 있는 변경일 때만 | 단순 UI/설정 변경 등 데이터 흐름이 없으면 생략. 여기서 발견되는 불일치도 후속 수정을 유발할 수 있어 최종 확인(5번)보다 앞에 둔다 |
| 4 | UI 시각 품질 확인 | `devoks-browser:browser-visual-diff` 또는 육안 확인 | 조건부 — UI 컴포넌트/스타일링 변경이 포함된 태스크가 있을 때만 | UI 다듬기를 별도 단계로 고정할지는 `docs/roadmap.md`의 "UI 작업 분리 검토" 항목에서 별도 결정 중 — 그 결정 전까지는 조건부 제안으로만 둔다. `browser-visual-diff` 자체가 Phase 5(미세 조정)에서 레이아웃 상수·토큰 적용 코드를 직접 고치므로, 그 변경까지 반영된 코드를 5번이 최종 확인하도록 5번보다 앞에 둔다 |
| 5 | 브라우저 실동작 검증 | `devoks-sdlc:verify-acceptance-test` | 조건부 — 배정된 Task의 AC가 UI 조작+상태 영속(폼 제출 후 화면 반영, 완료 처리 후 배지 표시 등)을 포함할 때만 | devoks-browser 플러그인 설치 전제(Chrome 9269 attach). 유닛테스트가 이미 충분히 커버하는 순수 로직 AC는 대상에서 제외. **커밋 직전 최종 게이트**로 둔다 — 2~4번(코드 리뷰·데이터 흐름 검증·UI 시각 품질)이 유발할 수 있는 후속 코드 변경이 모두 반영된 뒤의 코드를 대상으로 실행해야 검증 결과가 실제로 커밋될 코드와 일치한다. 영속 대조가 다층 계측을 요구한다고 판단되면 이 항목의 리포트가 항목 3과의 재확인 조합을 제안한다 |
| 6 | 테스트 스위트 회귀 확인 | `devoks-sdlc:test-run-triage` | 조건부 — 태스크 단위 테스트는 이미 실행했지만 전체 스위트 회귀를 별도로 확인하고 싶을 때 | 태스크 실행 중 이미 관련 테스트를 통과시켰다면 전체 스위트는 선택 |
| 7 | 커밋 | `devoks-git:git-commit-msg` | 항상(사용자 확인 후) | Conventional Commits 규칙 적용 |
| 8 | PR 생성 | `devoks-git:git-pull-request` | 항상(사용자 확인 후, 커밋 이후) | PR 그룹 경계는 PLAN §3에 이미 기록됨 |

## 출력 형식 — AskUserQuestion 다중선택 (HITL 전용)

Phase 4 / 마무리 시점에, 해당하는 항목만 **AskUserQuestion `multiSelect`** 로 제시한다. 각 옵션 라벨은
**`안내(/스킬명)`** 형식으로 실제 위임 대상 스킬/커맨드를 함께 노출한다. AskUserQuestion은 **질문당 옵션 4개**
제한이 있으므로 **검증 단계 / 마무리 단계**로 나눈다(적용 검증 항목이 4개를 넘으면 검증을 두 질문으로 분할 — 한 호출에 함께 전달).

- **Q "검증 단계" (multiSelect, 표 1~5 중 해당 항목):**
  - 요구사항 충실도 재확인(/devoks-sdlc:verify-requirements)
  - 코드 리뷰(/devoks-sdlc:code-review-diff-branch)
  - 데이터 흐름 검증(/devoks-sdlc:verify-data-flow) — 해당 시
  - UI 시각 품질 확인(/devoks-browser:browser-visual-diff) — 해당 시
  - 실동작 검증(/devoks-sdlc:verify-acceptance-test) — 해당 시
- **Q "마무리 단계" (multiSelect, 표 6~8):**
  - 테스트 스위트 회귀 확인(/devoks-sdlc:test-run-triage) — 선택
  - 커밋(/devoks-git:git-commit-msg)
  - PR 생성(/devoks-git:git-pull-request)

해당 없는 조건부 항목은 옵션에서 제외한다(기계적으로 전부 나열하지 않는다).

### 선택 결과 처리 — 고른 항목을 메뉴 순서대로 위임 실행 (HITL 선택 실행)

사용자가 고른 항목을 **표준 메뉴 순서**(위 표 1→8)대로 해당 스킬/커맨드에 **위임 실행**한다. 선택은 곧 명시 요청이다.

- **읽기전용 검증/리뷰/테스트(1~6):** 부작용이 없으므로 선택 즉시 순차 실행하고 각 리포트를 요약한다.
- **안전 인터록:** 1~6 중 어느 것이든 **Critical/High** 이슈를 보고하면 **7(커밋)·8(PR)로 넘어가기 전에 멈추고**
  사용자에게 계속 진행할지 확인한다.
- **커밋(7)·PR(8):** 선택 시 `devoks-git:git-commit-msg`/`git-pull-request`에 위임한다. 각 커맨드가 메시지·PR 본문
  확인 플로와 deny-list(force-push·`main` 직접 push·`--no-verify` 금지)를 **최종 게이트**로 유지한다.
- 선택하지 않은 항목은 실행하지 않는다. 실행 후에는 각 단계 결과를 한 줄씩 요약 보고한다.

> HITL(사용자 직접 호출) 경로 전용이다. 비-HITL 오케스트레이션 경로에서는 이 문답을 띄우지 않는다
> (사용자 개입 없는 자동 실행·자동 게이트는 `devoks-sdlc-orchestration`의 책임 — 위 "원칙" 절 참고).
