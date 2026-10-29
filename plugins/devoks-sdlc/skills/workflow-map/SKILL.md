---
name: workflow-map
description: DevOKs SDLC 작업의 전체 흐름(단계 순서)과 각 단계의 진입 스킬·커맨드를 한 장의 표로 보여준다. 파이프라인(준비→요구정의→작업분해→구현→검증체인→커밋/PR)과 순서 없는 단발 작업을 구분해 제시한다. "워크플로우 맵", "SDLC 흐름 보여줘", "스킬 표", "어떤 스킬 써야 해", "다음 단계 뭐야", "작업 순서 알려줘", "스킬 목록 정리해줘" 같은 조회성 요청에서 사용한다. 표를 출력할 뿐 어떤 단계도 실행하지 않는다 — 실제 실행은 표에 적힌 각 스킬을 직접 호출한다.
metadata:
  author: ridsync
  version: 1.3.0
---
# workflow-map — SDLC 워크플로우 흐름 맵

HITL(사용자 주도) 작업 중 **"지금 어디쯤이고 다음에 뭘 부르나"** 를 즉시 답하기 위한 조회용 맵이다.
아래 두 표를 **그대로 출력**하는 것이 이 스킬의 전부다.

---

## 범위 (중요)

**한다:**

- 단계 순서와 각 단계의 진입점(스킬/커맨드) 이름을 표로 출력.
- 순서가 있는 파이프라인과 순서가 없는 단발 작업을 구분해 제시.

**안 한다:**

- 어떤 단계도 실행하지 않는다. 사용자가 이어서 요청하면 그때 해당 스킬을 호출한다.
- 진행 상태를 판정하지 않는다(정적 표만 출력). 진행 상태의 SSOT는 `PLAN.md`의 체크박스와 frontmatter `status`다.
- 각 단계의 세부 조건·절차를 여기서 재서술하지 않는다 — 세부는 각 스킬과 아래 SSOT 링크가 갖는다.

---

## 호출 방법

```
/devoks-sdlc:workflow-map
```

---

## 절차

1. 아래 **표 A → 표 A-1 → 표 B** 순서로 출력한다.
2. 표 아래 "참고" 문구를 함께 남긴다.
3. 출력 후 멈춘다. 사용자가 특정 단계를 고르면 그때 해당 스킬로 넘긴다.

---

## 표 A — 파이프라인 (순서 있음)


| #   | 단계         | 진입점                                                                | 산출물                                     |
| --- | ---------- | ------------------------------------------------------------------ | --------------------------------------- |
| 0   | 준비 (최초 1회) | `/devoks-core:setup-mcp` · `/devoks-core:setup-project-convention` | MCP 서버, `.claude/rules`                 |
| 0b  | 제품 정의 (선택, 장기 프로젝트) | `/devoks-sdlc:product-prd-author` | `PRD.md` · `FEATURES.md` (항목별 FRD 시드 → 1) |
| 1a  | 요구 탐색 (선택) | `/devoks-sdlc:feature-interview` → 승인 시 1로 자동 연결 | 정련 요약 (대화)                        |
| 1   | 요구 정의      | `/devoks-sdlc:feature-frd-author`                                  | `FRD.md`                                |
| 2   | 작업 분해      | `/devoks-sdlc:feature-plan-author`                                 | `PLAN.md`                               |
| 3   | 구현         | `/devoks-sdlc:feature-plan-executor`                               | 코드 (`code-implementer` 에이전트에 태스크 단위 위임) |
| 4   | 검증 체인      | ↓ 표 A-1                                                            | 검증 리포트                                  |
| 5   | 마무리        | `/devoks-git:git-commit-msg` → `/devoks-git:git-pull-request`      | 커밋 · PR                                 |


> **통합 진입점:** `/devoks-sdlc:feature-workflow-runner` 는 1~~3을 한 흐름으로 실행하고, 마무리 시점에 4~~5를 선택 메뉴로 제시한다. 1~3을 따로 돌리고 싶을 때만 개별 스킬을 쓴다.

## 표 A-1 — 4단계 검증 체인

순서에 의미가 있다. **정적·저비용 검증을 앞에** 두어 구조적 문제를 먼저 걸러내고, **"지금 커밋될 코드가 실제로 동작하는가"** 를 묻는 실동작 검증을 앞선 단계의 수정이 모두 반영된 뒤 마지막에 둔다.


| 순서  | 검증                   | 진입점                                                                                                                                                                            | 조건                                          |
| --- | -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------- |
| 1   | 요구사항 구현 충실도          | `/devoks-sdlc:verify-requirements`                                                                                                                                             | 항상                                          |
| 2   | 코드 리뷰                | `/devoks-sdlc:code-review mode=diff-branch`                                                                                                                                    | 항상                                          |
| 3   | 데이터 흐름 정합성           | `/devoks-sdlc:verify-data-flow`                                                                                                                                                | 입력→계산→저장→재로드 흐름이 있을 때                       |
| 4   | UI 시각 품질             | `/devoks-browser:browser-visual-diff`                                                                                                                                          | UI 컴포넌트/스타일링 변경이 있을 때 — react-web 한정(RN·네이티브는 육안) |
| 5   | 브라우저 실동작             | `/devoks-sdlc:verify-acceptance-test`                                                                                                                                          | AC에 UI 조작+상태 영속이 걸려 있을 때(react-web 한정, RN·네이티브는 수동 확인) — **커밋 직전 최종 게이트** |
| 옵션  | 테스트 스위트 회귀           | `/devoks-sdlc:test-run-triage`                                                                                                                                                 | 전체 스위트 회귀를 따로 확인할 때                         |
| 옵션  | 프로젝트 전용 스모크 테스트 (참고) | 프로젝트별 상이 — 예: `aware-react-app`의 `verify-app-smoke-test`(`.claude/skills/verify-app-smoke-test/SKILL.md`). 아직 없다면 `/devoks-sdlc:new-smoke-test-draft`로 화면 목록을 스캔해 초안을 생성할 수 있다 | 해당 프로젝트가 배포 전 스모크 테스트 스킬을 자체 보유(또는 생성)할 때만  |


> 조건·비고·안전 인터록(Critical/High 발견 시 커밋·PR 전 정지)의 SSOT는
> `${CLAUDE_PLUGIN_ROOT}/skills/feature-workflow-runner/references/post-implementation-checklist.md` 다.
> 이 표는 그 문서의 **순서와 진입점만** 얕게 비추며, 상세 조건이 다르면 그 문서가 이긴다.
>
> **"옵션" 행의 생성 결과는 devoks-sdlc의 위임 대상이 아니다.** devoks-sdlc는 `/devoks-sdlc:new-smoke-test-draft`로
> 화면 목록을 스캔해 초안(SKILL.md + 체크리스트 + 리포트 템플릿)을 1회 생성해 주는 **생성기만** 소유한다 —
> 생성된 스킬 자체는 해당 프로젝트 자신이 저작·소유·관리하는 문서로 즉시 넘어가고(라우트·화면 구조가
> 프로젝트마다 달라 devoks-sdlc가 범용 실행 스킬로 제공할 수 없다), `post-implementation-checklist.md`의
> 실행 메뉴에도 포함하지 않는다. 생성 이후 완성·실행·유지보수는 프로젝트 몫이며, devoks-sdlc는 생성 시점
> 이후 그 결과물과 어떤 동기화 관계도 갖지 않는다. 실행 방법은 해당 프로젝트의 스킬 문서를 직접 참고한다.

## 표 B — 단발 작업 (순서 없음)

파이프라인과 무관하게 언제든 단독 호출한다.


| 목적                         | 진입점                                     |
| -------------------------- | --------------------------------------- |
| 기존 모듈·비즈니스 로직 파악          | `/devoks-sdlc:code-analyze-module`      |
| 리팩토링                      | `/devoks-sdlc:code-refactoring`         |
| 범위 지정 코드 리뷰 (파일/폴더)        | `/devoks-sdlc:code-review mode=general` |
| 보안 검증 (의존성·시크릿·위협)         | `/devoks-sdlc:code-security-review`     |
| 테스트 작성·보강                  | `/devoks-sdlc:test-author`              |
| Figma 디자인 → UI 구현          | `/devoks-sdlc:new-ui-draft`             |
| 프로젝트 전용 스모크 테스트 스킬 초안 생성   | `/devoks-sdlc:new-smoke-test-draft`     |
| 간이 기능 구현 (FRD/PLAN 산출물 없이) | `/devoks-sdlc:new-feature-by-github-issue` |


---

## 참고 (표와 함께 출력)

- **제품 정의는 기능 정의보다 한 단계 위다.** 여러 기능으로 이뤄진 장기 프로젝트는 `product-prd-author`로 PRD·기능 백로그를 먼저 만들고, 백로그 항목의 FRD 시드를 `feature-frd-author`에 넘긴다. 기능 하나만 만들 때는 건너뛴다.
- **요구 단계 진입점은 사실상 하나다.** 초안이 있으면 `feature-frd-author`(또는 `feature-workflow-runner`)를 바로 쓴다 — 의도가 비었거나 방향이 여러 갈래면 그 스킬이 Phase 0에서 `feature-interview`로 먼저 정련한다. 아이디어만 있을 때 `feature-interview`를 직접 불러도 되고, 정련 요약이 승인되면 FRD 정련으로 자동으로 이어진다.
- **기능 구현 진입점이 둘이다.** 추적 가능한 산출물(`FRD.md`/`PLAN.md`)과 태스크 단위 진행 추적이 필요하면 **표 A**(`feature-workflow-runner`)를, 산출물 없이 바로 구현하는 가벼운 작업이면 **표 B**의 `new-feature-by-github-issue`(GitHub 이슈 본문을 SSOT로 삼는 간이 구현)를 쓴다.
- **타 플러그인 항목**(`/devoks-core:*`, `/devoks-git:*`, `/devoks-browser:*`)은 해당 플러그인이 설치돼 있어야 호출된다. 미설치 환경에서는 그 행을 건너뛴다.
- **진입점은 스킬이 기본이다.** `devoks-sdlc`의 위 표 항목은 전부 스킬이다(커맨드 없음, 2026-08-24·2026-09-02 두 차례 이전으로 완료). 저장소 밖으로 나가는 write 부작용이 있거나 승인 게이트가 절차의 본질인 항목은 여전히 커맨드로 남지만(`/devoks-git:*`), `devoks-sdlc`에는 해당 항목이 없다. `code-reviewer`·`code-security-reviewer`·`test-writer`·`code-implementer`·`acceptance-test-runner`·`code-analyzer` **에이전트**는 스킬이 특정 Phase에서 위임하는 실행 주체이므로 직접 호출 대상이 아니다.

