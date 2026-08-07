---
name: workflow-map
description: DevOks SDLC 작업의 전체 흐름(단계 순서)과 각 단계의 진입 스킬·커맨드를 한 장의 표로 보여준다. 파이프라인(준비→요구정의→작업분해→구현→검증체인→커밋/PR)과 순서 없는 단발 작업을 구분해 제시한다. "워크플로우 맵", "SDLC 흐름 보여줘", "스킬 표", "어떤 스킬 써야 해", "다음 단계 뭐야", "작업 순서 알려줘", "스킬 목록 정리해줘" 같은 조회성 요청에서 사용한다. 표를 출력할 뿐 어떤 단계도 실행하지 않는다 — 실제 실행은 표에 적힌 각 스킬을 직접 호출한다.
metadata:
  author: ridsync
  version: 1.0.0
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

| # | 단계 | 진입점 | 산출물 |
|---|------|--------|--------|
| 0 | 준비 (최초 1회) | `/devoks-core:setup-mcp` · `/devoks-core:setup-project-convention` | MCP 서버, `.claude/rules` |
| 1 | 요구 정의 | `/devoks-sdlc:feature-frd-author` | `FRD.md` |
| 2 | 작업 분해 | `/devoks-sdlc:feature-plan-author` | `PLAN.md` |
| 3 | 구현 | `/devoks-sdlc:feature-plan-executor` | 코드 (`code-implementer` 에이전트에 태스크 단위 위임) |
| 4 | 검증 체인 | ↓ 표 A-1 | 검증 리포트 |
| 5 | 마무리 | `/devoks-git:git-commit-msg` → `/devoks-git:git-pull-request` | 커밋 · PR |

> **통합 진입점:** `/devoks-sdlc:feature-workflow-runner` 는 1~3을 한 흐름으로 실행하고, 마무리 시점에 4~5를 선택 메뉴로 제시한다. 1~3을 따로 돌리고 싶을 때만 개별 스킬을 쓴다.

## 표 A-1 — 4단계 검증 체인

순서에 의미가 있다. **정적·저비용 검증을 앞에** 두어 구조적 문제를 먼저 걸러내고, **"지금 커밋될 코드가 실제로 동작하는가"** 를 묻는 실동작 검증을 앞선 단계의 수정이 모두 반영된 뒤 마지막에 둔다.

| 순서 | 검증 | 진입점 | 조건 |
|------|------|--------|------|
| 1 | 요구사항 구현 충실도 | `/devoks-sdlc:verify-requirements` | 항상 |
| 2 | 코드 리뷰 | `/devoks-sdlc:code-review-diff-branch` | 항상 |
| 3 | 데이터 흐름 정합성 | `/devoks-sdlc:verify-data-flow` | 입력→계산→저장→재로드 흐름이 있을 때 |
| 4 | UI 시각 품질 | `/devoks-browser:browser-visual-diff` | UI 컴포넌트/스타일링 변경이 있을 때 |
| 5 | 브라우저 실동작 | `/devoks-sdlc:verify-acceptance-test` | AC에 UI 조작+상태 영속이 걸려 있을 때 — **커밋 직전 최종 게이트** |
| 6 | 테스트 스위트 회귀 | `/devoks-sdlc:test-run-triage` | 전체 스위트 회귀를 따로 확인할 때 |

> 조건·비고·안전 인터록(Critical/High 발견 시 커밋·PR 전 정지)의 SSOT는
> `${CLAUDE_PLUGIN_ROOT}/skills/feature-workflow-runner/references/post-implementation-checklist.md` 다.
> 이 표는 그 문서의 **순서와 진입점만** 얕게 비추며, 상세 조건이 다르면 그 문서가 이긴다.

## 표 B — 단발 작업 (순서 없음)

파이프라인과 무관하게 언제든 단독 호출한다.

| 목적 | 진입점 |
|------|--------|
| 기존 모듈·비즈니스 로직 파악 | `/devoks-sdlc:code-analyze-module` |
| 리팩토링 | `/devoks-sdlc:code-refactoring` |
| 범위 지정 코드 리뷰 (파일/폴더) | `/devoks-sdlc:code-review-general` |
| 보안 검증 (의존성·시크릿·위협) | `/devoks-sdlc:code-security-review` |
| 테스트 작성·보강 | `/devoks-sdlc:test-author` |
| Figma 디자인 → UI 구현 | `/devoks-sdlc:new-ui-draft` |
| 간이 기능 구현 (FRD/PLAN 산출물 없이) | `/devoks-sdlc:new-feature-draft` · `/devoks-sdlc:new-feature-github-issue` |

---

## 참고 (표와 함께 출력)

- **기능 구현 진입점이 둘이다.** 추적 가능한 산출물(`FRD.md`/`PLAN.md`)과 태스크 단위 진행 추적이 필요하면 **표 A**(`feature-workflow-runner`)를, 산출물 없이 바로 구현하는 가벼운 작업이면 **표 B**의 `new-feature-draft` 계열을 쓴다.
- **타 플러그인 항목**(`/devoks-core:*`, `/devoks-git:*`, `/devoks-browser:*`)은 해당 플러그인이 설치돼 있어야 호출된다. 미설치 환경에서는 그 행을 건너뛴다.
- 표에 없는 `code-review`·`code-security-review`·`test-author` **스킬**은 에이전트 전용 실행 엔진이라 직접 호출 대상이 아니다. 사용자 진입점은 위 표의 커맨드 이름이다.
