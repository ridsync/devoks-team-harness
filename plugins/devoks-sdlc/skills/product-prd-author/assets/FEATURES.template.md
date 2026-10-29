---
doc_type: feature-backlog
prd: ./PRD.md
prd_version: 0.1.0
updated: <YYYY-MM-DD>
---

# <제품 이름> — 기능 백로그

> PRD의 `FR`을 사용자가 체감하는 기능 단위로 묶은 목록. 항목 하나 = FRD 하나.
> 상태: `backlog` → `frd` → `plan` → `in-progress` → `done` / `dropped`(지우지 않고 사유를 남긴다)

| ID | 기능 | 포함 FR | 릴리스 | MoSCoW | 의존 | 상태 | FRD |
|---|---|---|---|---|---|---|---|
| F-1 | | FR-1, FR-2 | MVP | Must | — | backlog | — |

## 기반 (product-trd-author 소유)

> 사용자 기능은 아니지만 둘 이상의 F-n이 의존하는 공통 기반. TRD가 쓰고 갱신한다 — PRD 갱신 모드는 이 구역을 건드리지 않는다.
> 시드 형식은 아래 F-n 시드와 같다(Outcome = 이후 기능이 할 수 있게 되는 일, User = 개발자(에이전트) / 이후 F-n).

| ID | 기반 작업 | 선행 대상 | 상태 | FRD |
|---|---|---|---|---|
| — | (TRD 작성 전 — product-trd-author가 채운다. 이후 F-n의 의존 열에 B-n이 들어간다) | | | |

---

## F-1 <기능 이름>

**FRD 시드** — FRD 입력 양식(`FRD.intake.md`)과 같은 칸이다. 아래 블록을 그대로 `/devoks-sdlc:feature-frd-author frd=<본문>`에 넘긴다.

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
- 관련 문서:     PRD.md F-1
```
