---
description: "막연한 기능 아이디어를 넓혀 보고(변형안 5~8개) 좁혀서(방향 2~3개 → 1개) 사용자가 고른 방향의 1-pager(Problem·Direction·Assumptions·MVP·Not Doing·Open Questions)로 만들고, FRD 워크스페이스의 FRD.draft.md로 저장해 FRD 정련으로 넘긴다. 기존 코드베이스의 구조·패턴을 근거로 변형안을 만든다. \"아이디어 구체화\", \"이 아이디어 다듬어줘\", \"기능 아이디어 발산\", \"어떤 방향으로 만들지 같이 생각해줘\", \"막연한 아이디어를 PRD로\", \"idea refine\", \"ideate\" 요청에서 사용한다. 원하는 것 자체가 불명확하면 먼저 devoks-sdlc:feature-intent-interview, 방향이 정해진 초안을 정형화하려면 devoks-sdlc:feature-frd-author 를 쓴다."
argument-hint: "[idea=<아이디어 본문> (default: 대화 맥락)] [out=<디렉터리> (default: 워크스페이스)]"
metadata:
  author: ridsync
  version: 1.0.0
---

# feature-idea-refine — 기능 아이디어 구체화 (Define 앞단)

막연한 아이디어를 바로 FRD로 옮기면 첫 번째로 떠오른 형태가 그대로 굳는다. 이 스킬은 **발산(변형안) →
수렴(방향 선택·가정 점검) → 1-pager**로 "무엇을 만들고 무엇을 만들지 않을지"를 먼저 정한다. 결과는
`FRD.draft.md`가 되고, EARS·Contract·Edge 정형화는 `devoks-sdlc:feature-frd-author`가 맡는다(FRD를 직접 쓰지 않는다).

## 범위 (중요)

| 입력 상태 | 쓸 스킬 |
|---|---|
| 원하는 것 자체가 불명확 — 누구를 위한 것인지·성공 기준을 추측해야 함 | `devoks-sdlc:feature-intent-interview` (먼저) |
| 의도는 있으나 **방향이 여러 갈래** — 어떤 형태로 만들지 선택지를 넓혀 보고 좁혀야 함 | **이 스킬** |
| 방향이 정해졌고 초안이 있음 | `devoks-sdlc:feature-frd-author` |

- 첫 질문에서 "누구를 위한 것인지·성공 모습"에 답이 안 나오면 이 스킬을 멈추고 `feature-intent-interview`를 제안한다.
- **HITL 전용** — 단계마다 사용자 반응이 다음 단계의 입력이다. 질문이 사용자에게 전달되지 않는 맥락(위임받은 서브에이전트·`/loop`·자동 파이프라인)에서는 실행하지 않고 blocker로 보고한다.
- 하지 않는 것: 기술 설계(FRD §4 — `feature-frd-author`), 작업 분해(`feature-plan-author`), 코드 작성.

## 호출 방법

```
/devoks-sdlc:feature-idea-refine [idea=<아이디어 본문> (default: 대화 맥락)] [out=<디렉터리> (default: 워크스페이스)]
```

> 표기: `key=값` 필수 · `[key=값]` 선택 · `(default: X)` 미지정 시 X로 진행.

- `out` 기본값과 `FRD.draft.md` 기록 형식은 `../feature-workflow-runner/references/output-location.md`가 SSOT다.
- 같은 워크스페이스에 `FRD.draft.md`가 이미 있으면(예: `feature-intent-interview`의 확정 결정) 먼저 읽고 그 Intent를 전제로 진행한다.

## Phase 1 — 이해하고 넓히기 (발산)

1. **HMW 문장으로 재진술** — "어떻게 하면 <누가> <무엇을> 할 수 있을까?" 한 문장. 무엇을 푸는지 고정한다.
2. **날카로운 질문 3~5개(그 이상 금지)** — 누구를 위한 것인지, 성공 모습, 실제 제약(시간·기술·인력), 이미 시도한 것, 지금 사용자가 쓰는 우회책. 이미 `FRD.draft.md`에 답이 있는 항목은 묻지 않는다. **누구를 위한 것인지와 성공 모습을 모르면 다음 단계로 가지 않는다.**
3. **코드베이스 근거 수집** — 관련 기존 화면·모듈·데이터 모델·패턴을 Glob/Grep/Read로 확인한다. 변형안은 실제로 있는 구조를 근거로 만들고 파일 경로를 인용한다.
4. **변형안 5~8개** — `references/lenses-and-criteria.md`의 렌즈 중 아이디어에 맞는 것만 골라 쓴다(전부 기계적으로 돌리지 않는다). 각 변형안에는 "왜 이 안이 존재하는지" 한 줄을 붙인다. 20개짜리 얕은 목록은 금지.

사용자가 어떤 안에 끌리는지·어디에 반대하는지 반응할 때까지 기다린다.

## Phase 2 — 평가하고 좁히기 (수렴)

1. **방향 2~3개로 묶기** — 반응이 좋았던 안을 서로 **의미 있게 다른** 방향으로 묶는다.
2. **세 축으로 점검** — 사용자 가치(진통제인가 비타민인가, 지금의 우회책 대비 무엇이 나아지나) · 실현성(가장 어려운 부분, 기존 코드 재사용 여지, 외부 의존) · 차별성(기존 흐름·대체 수단과 무엇이 다른가). 기준은 `references/lenses-and-criteria.md`.
3. **숨은 가정 드러내기** — 방향마다: 검증 안 됐는데 참이라고 걸고 있는 것, 이 아이디어를 죽일 수 있는 것, 일부러 무시하는 것(과 그래도 되는 이유). **가장 자주 건너뛰는 단계 — 생략 금지.**
4. **약한 안에는 솔직하게** — 근거를 들어 반대한다. 맞장구 기계가 되지 않는다.

사용자가 방향 하나를 고를 때까지 기다린다(고르지 못하면 Phase 2를 한 번 더 좁히거나, 의도 문제로 보이면 `feature-intent-interview`를 제안).

## Phase 3 — 1-pager로 다듬기

고른 방향으로 아래 1-pager를 보여주고 확인받는다.

```markdown
# <아이디어 이름>

## Problem
<HMW 한 문장>

## Recommended Direction
<고른 방향과 이유 — 2~3문단 이내, 근거가 된 기존 코드 경로 포함>

## Key Assumptions to Validate
- [ ] <가정> — <확인 방법>

## MVP Scope
<핵심 가정을 검증하는 최소 버전 — 포함 / 제외>

## Not Doing (and Why)
- <안 하는 것> — <이유>

## Open Questions
- <만들기 전에 답해야 할 질문>
```

**Not Doing이 가장 중요한 절이다** — 좋은 아이디어에 "아니요"라고 말하는 것이 초점이다. 최소 1개.

## 기록하고 멈춤

사용자가 1-pager를 승인하면:

1. 워크스페이스를 확정한다(`output-location.md` — feature-name 1회 확인, 이미 있으면 이어 쓴다. 사용자가 `out`이나 경로를 이미 지정했으면 확인 없이 그 경로를 쓴다).
2. `<out>/FRD.draft.md`에 기록한다. **덮어쓰지 않는다.**
   - 파일이 없으면 출처 헤더(`feature-idea-refine`, 날짜, 원래 아이디어 원문 verbatim 인용) + 승인된 1-pager로 만든다.
   - 파일이 있으면 맨 아래에 `## 확정 결정 — feature-idea-refine (<yyyy-MM-dd>)` 섹션으로 1-pager를 추가한다. 이때 1-pager의 heading은 두 단계 내린다(`#` → `###`, `##` → `####`) — 섹션 아래에 H1이 들어가 문서 계층이 뒤집히지 않게.
   - Recommended Direction의 근거 코드 경로를 확인하지 못했으면(코드베이스 접근 불가 등) 그 사실을 Key Assumptions에 확인 항목으로 남긴다.
3. 다음 경로를 제안하고 **턴을 끝낸다**: `/devoks-sdlc:feature-frd-author frd=<out>/FRD.draft.md`
   (FRD → PLAN → 실행을 한 흐름으로 원하면 `/devoks-sdlc:feature-workflow-runner frd=<out>/FRD.draft.md`)

## 완료 기준

- HMW 문제 진술이 있고, 대상 사용자와 성공 기준이 정해졌다.
- 첫 아이디어만이 아니라 여러 방향을 탐색했고, 변형안이 코드베이스 근거를 인용한다.
- 숨은 가정이 확인 방법과 함께 목록화됐다.
- Not Doing이 1개 이상 있다.
- 사용자가 방향과 1-pager를 명시적으로 승인했고, `FRD.draft.md`에 기록됐다(기존 내용 보존).

> 렌즈·평가 기준: `references/lenses-and-criteria.md`
