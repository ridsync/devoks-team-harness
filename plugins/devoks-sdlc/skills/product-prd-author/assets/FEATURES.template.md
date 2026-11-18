---
doc_type: feature-backlog
prd: ./PRD.md
prd_version: 0.1.0
updated: <YYYY-MM-DD>
---

# <제품 이름> — 기능 백로그

> PRD의 `FR`을 작업 단위로 묶은 목록. 항목 하나(F-n 또는 B-n) = FRD 하나.
> 구성: **§1 사용자 기능 단위(F-n)** · **§2 공통 기반 작업 단위(B-n)** · **§3 작업 순서** · **§4 기능 단위 상세(FRD 시드)**

## 상태 범례

상태 칸은 `<이모지> <키워드>`로 쓴다. 판정은 키워드로 한다(이모지는 표시용). 상태는 앞으로만 간다 — 되돌리지 않는다.

| 상태 | 의미 | 바꾸는 스킬 · 시점 |
|---|---|---|
| 📋 `backlog` | 시드만 있음 | `product-prd-author`(F-n) · `product-trd-author`(B-n) — 항목 생성 시 |
| 📝 `frd` | FRD 작성됨 | `feature-frd-author` — `FRD.md` 작성 시 (FRD 열에 경로 기입) |
| 🗂️ `plan` | 작업 분해됨 | `feature-plan-author` — `PLAN.md` 작성 시 |
| 🚧 `in-progress` | 구현 중 | `feature-plan-executor` · `feature-workflow-runner` — 첫 Task 착수 시 |
| ✅ `done` | 구현·DoD 완료 | 같은 실행 스킬 — PLAN `status: done` 전환 시 |
| 🚫 `dropped` | 범위에서 제외 | `product-prd-author`(F-n) · `product-trd-author`(B-n) 갱신 모드 — 행을 지우지 않고 `🚫 dropped (v<버전>: 사유)` |

> 칸 소유: 상태·FRD 열은 위 표의 스킬이 바꾸고, 나머지 열은 §1은 `product-prd-author`, §2는 `product-trd-author`만 고친다. 예외 하나 — `product-trd-author`는 B-n을 기다리는 F-n의 의존 열에 B-n을 넣는다. §3 작업 순서는 의존을 바꾼 스킬이 다시 계산한다.

## 1. 사용자 기능 단위 (F-n) — `product-prd-author` 소유

> 사용자가 체감하는 기능. PRD의 모든 `FR`이 정확히 하나의 F-n에 속한다.

| ID | 기능 | 포함 FR | 릴리스 | MoSCoW | 의존 | 상태 | FRD |
|---|---|---|---|---|---|---|---|
| F-1 | | FR-1, FR-2 | MVP | Must | — | 📋 backlog | — |

## 2. 공통 기반 작업 단위 (B-n) — `product-trd-author` 소유

> 사용자 기능은 아니지만 둘 이상의 F-n이 의존하는 공통 기반(골격·인증·공유 모델·CI·계측·디자인 시스템). 이 표와 §4의 B-n 시드를 합쳐 "기반 구역"이라 부른다 — `product-prd-author` 갱신 모드는 건드리지 않는다.

| ID | 기반 작업 | 선행 대상 | 의존 | 상태 | FRD |
|---|---|---|---|---|---|
| — | (TRD 작성 전 — `product-trd-author`가 채운다. 이후 F-n의 의존 열에 B-n이 들어간다) | | | | |

> 선행 대상 = 이 기반이 끝나야 시작할 수 있는 F-n. 의존 = 이 기반이 먼저 기다려야 하는 것(B-n, 또는 `와이어프레임`·`비주얼` 같은 단계).

## 3. 작업 순서

> §1·§2의 **의존 열에서 계산한 보기**다 — 손으로 순서를 따로 정하지 않는다. 의존을 바꾸는 스킬(`product-prd-author`·`product-trd-author`)이 바꿀 때마다 다시 계산한다.

| 단계 | 작업 (`∥` = 동시 진행 가능) | 시작 조건 | 비고 |
|---|---|---|---|
| 1 | F-1 | — | |

읽는 법:
- **같은 단계의 항목은 서로 의존하지 않는다** — 동시에 진행해도 된다(항목마다 워크스페이스·브랜치를 따로 둔다). 같은 공유 엔티티·화면·파일을 고치면 비고에 `충돌 주의`를 적는다 — 동시에 진행하되 병합 순서를 정하거나, 차례로 진행한다.
- **다음 단계는 시작 조건의 항목이 모두 ✅ `done`일 때** 시작한다. 시작 조건에는 해당 단계 항목들의 의존을 모아 적는다.
- 계산: 의존이 없는 항목이 1단계, 그 밖의 항목은 "의존 항목의 가장 늦은 단계 + 1". 릴리스 순서(MVP → Next → Later)를 지킨다 — Next·Later 항목은 MVP 단계 뒤에 이어 적는다.
- 🚫 `dropped` 항목은 빼고 계산한다.

## 4. 기능 단위 상세 — FRD 시드

> 항목별 FRD 입력. 각 블록을 그대로 `/devoks-sdlc:feature-frd-author frd=<본문>`에 넘긴다. 칸은 FRD 입력 양식(`FRD.intake.md`)과 같다.
> F-n 시드는 `product-prd-author`, B-n 시드는 `product-trd-author`가 쓴다(B-n은 Outcome = 이후 기능이 할 수 있게 되는 일, User = 개발자(에이전트) / 이후 F-n).

### F-1 <기능 이름>

```
## 기능 정련 요약 — <기능 이름>
- 원래 요청:     PRD v<버전> FR-1, FR-2
- Outcome:      <사용자가 새로 할 수 있게 되는 일 — 한 문장>
- User:         <PRD §2의 누구>
- Why now:      <PRD G-n / S-n 연결 — 왜 이 기능이 목표에 필요한가>
- Success:      <이 기능이 기여하는 PRD 지표 + 남겨야 할 계측(FR/NFR-n) — 출시 후 목표치는 FRD 범위가 아님>
- Constraint:   <PRD §7의 NFR-n, 제약>
- Out of scope: <이 기능에서 하지 않을 것 — 최소 1개>
- 남은 질문:     <PRD Q-n ID만 — 내용을 다시 적지 않는다 / 없음>
- 관련 문서:     FEATURES.md F-1
```
