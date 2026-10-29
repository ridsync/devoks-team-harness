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

---

## F-1 <기능 이름>

**FRD 시드** — 이 블록을 그대로 `/devoks-sdlc:feature-frd-author frd=<본문>`에 넘긴다.

- 기능: <한 문장>
- 대상 사용자: <PRD §2의 누구>
- Why: <PRD G-n / S-n 연결 — 왜 이 기능이 목표에 필요한가>
- Success: <이 기능이 기여하는 PRD 지표 + 이 기능이 남겨야 할 계측(FR/NFR-n) — 출시 후 목표치는 FRD 범위가 아님>
- Non-goals: <이 기능에서 하지 않을 것 — 최소 1개>
- 관련 제약·NFR: <PRD §7의 NFR-n, 제약>
- 열린 질문: <PRD Q-n ID만 — 내용을 다시 적지 않는다 / 없음>
- 출처: PRD v<버전> FR-1, FR-2
