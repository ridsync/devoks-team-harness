---
name: product-design-author
description: "제품 PRD(+TRD)를 받아 기능 FRD 착수 전에 화면 설계를 고정한다 — 화면 인벤토리·핵심 흐름·화면별 우선순위 블록과 상태·컴포넌트 후보를 담은 도구 독립 SSOT WIREFRAMES.md를 작성하거나 갱신하고, 저해상도 와이어프레임을 디자인 도구(현재 Pencil .pen)로 그려 문서와 1:1 대조한다. 컴포넌트 후보는 TRD의 디자인 시스템 기반 작업(B-n)의 범위가 되고, 화면 상태는 기능 FRD로 넘어간다. 의도는 PRD가 정했으므로 인터뷰 없이 화면 범위·흐름·충실도를 제안해 한 메시지로 확인받는다. \"와이어프레임 그려줘\", \"화면 설계\", \"화면 목록 정리\", \"화면 흐름 잡아줘\", \"UX 흐름\", \"디자인 시작 전 화면 구성\", \"Pencil로 와이어프레임\", \"WIREFRAMES 업데이트\" 요청에서 사용한다. 디자인 시스템 방식(컴포넌트 기반·토큰 SSOT·테마·도구)은 devoks-sdlc:product-trd-author, 화면 하나의 동작 규칙은 devoks-sdlc:feature-frd-author, Figma 시안을 코드로 옮기는 일은 devoks-sdlc:new-ui-draft 가 맡는다."
argument-hint: "[src=<PRD 경로> (default: <out>/PRD.md)] [out=<디렉터리> (default: docs/product)] [tool=<pencil|none> (default: pencil)]"
metadata:
  author: ridsync
  version: 1.0.1
---

# product-design-author — 제품 와이어프레임 · 화면 설계

PRD는 "무엇을", TRD는 "어떤 구조로"를 정했지만 **화면에 무엇을 어떤 순서로 보여 줄지**는 비어 있다. 이 공백을 둔 채
기능마다 FRD를 쓰면 화면 상태가 제각각 정해지고, 디자인 시스템은 범위 없이 만들어진다. 이 스킬은 FRD 착수 전에
저해상도 와이어프레임으로 핵심 흐름을 검증하고, 디자인 시스템의 컴포넌트 범위와 FRD의 화면 상태 입력을 만든다.

```
PRD + TRD(§2.1 UI 기반) ─▶ [이 스킬] WIREFRAMES.md (SSOT) + design/wireframes.pen (뷰)
                                  ├─▶ 디자인 시스템 B-n FRD (§5 컴포넌트 후보 → DESIGN.md)
                                  └─▶ 화면 F-n FRD (§4 화면 상태 → EARS AC)
```

## 범위 (중요)

| 입력 | 쓸 스킬 |
|---|---|
| PRD가 있고 사용자 화면이 있는 제품의 화면 목록·흐름·와이어프레임 | **이 스킬** |
| PRD·TRD 변경이나 화면 변경 요청을 와이어프레임에 반영 | **이 스킬** (갱신 모드) |
| 디자인 시스템 방식(컴포넌트 기반·토큰 SSOT·테마·디자인 도구) | `devoks-sdlc:product-trd-author` §2.1 |
| 토큰 값·컴포넌트 계약(`DESIGN.md`) | 디자인 시스템 B-n → `devoks-sdlc:feature-frd-author` |
| 화면 하나의 동작 규칙·EARS AC | `devoks-sdlc:feature-frd-author` (이 문서의 W-n 상태를 입력으로) |
| Figma 시안을 코드로 구현 | `devoks-sdlc:new-ui-draft` |
| PRD가 없음 | `devoks-sdlc:product-interview` → `product-prd-author` 먼저 |

- 하지 않는 것: hi-fi 비주얼(색·폰트·브랜드), 토큰 값, 컴포넌트 API, EARS AC, 엔드포인트, 코드·스캐폴딩, PRD·TRD·FEATURES.md 수정(영향만 보고).

## 호출 방법

```
/devoks-sdlc:product-design-author [src=<PRD 경로> (default: <out>/PRD.md)] [out=<디렉터리> (default: docs/product)] [tool=<pencil|none> (default: pencil)]
```

> 표기: `key=값` 필수 · `[key=값]` 선택 · `(default: X)` 미지정 시 X로 진행.

- 산출물: `<out>/WIREFRAMES.md`, `tool=pencil`이면 `<out>/design/wireframes.pen`. `WIREFRAMES.md`가 이미 있으면 **갱신 모드**.
- `tool=none`: 문서만 쓴다(디자인 도구가 없거나 비-HITL 실행). 이후 같은 문서로 `tool=pencil` 재실행하면 그리기만 이어서 한다.
- 도구 어댑터: `pencil` → `references/tool-pencil.md`. 문서 형식은 도구와 무관하다 — 다른 도구는 어댑터 파일만 추가한다.

## 절차

### 0. 입력 수집 · 모드 판별

- PRD(`src`)와 같은 디렉터리의 `FEATURES.md`를 읽는다. PRD가 없으면 멈추고 PRD부터 안내한다 — 아이디어만 있으면 `product-interview`, 기획 메모가 있으면 `product-prd-author`. 시나리오 없이 그린 화면은 근거가 없다.
- `<out>/TRD.md`가 있으면 §2.1 UI 기반(플랫폼·뷰포트·컴포넌트 기반·디자인 도구)을 따른다. §2.1 값이 `제안` 상태면 제안값으로 쓰고 §1에 "(TRD 제안)"으로 표시한다. 없거나 §2.1이 비었으면 PRD §7 제약에서 플랫폼을 가정하고 §7 오픈 이슈에 "TRD §2.1 미정"을 남긴다. TRD §2.1의 디자인 도구가 `tool` 값(`pencil`·`none`)으로 대응되고 서로 다를 때만 HITL에서 확인한다 — 대응되지 않는 서술(예: "디자이너 도구 미정")이면 `tool`을 따른다.
- 사용자 화면이 없는 제품(API·배치 전용)이면 쓰지 않고 그 판단을 보고한다.
- 저장소에 기존 화면 코드가 있으면(brownfield) 라우트·페이지 목록을 가볍게 훑어 현행 화면을 W-n에 "현행"으로 표시한다 — 재설계 대상은 PRD 요구와 닿는 화면만.
- `<out>/WIREFRAMES.md` 존재 → 갱신 모드로.

### 1. 범위 제안 — 한 메시지로

`references/design-guide.md` §2를 따른다. **플랫폼 전제**(주 타깃 플랫폼·역할별 기기·기준/보조 뷰포트)를 맨 앞에 두고, 화면 인벤토리 초안·그릴 핵심 흐름·충실도·도구 사전 조건·제외 화면을 **한 메시지에** 담아 확인받는다. 사용자는 "좋아"나 고칠 줄만 답하면 된다.
- 플랫폼 전제는 TRD §2.1이 확정이면 인용만 하고, `제안`이거나 TRD가 없으면 첫 확인 항목으로 묻는다 — 확인 전에는 인벤토리를 확정하지 않는다. 논의 결과가 TRD와 다르면 보고에 "TRD §2.1 갱신 필요"를 남긴다(TRD는 고치지 않는다).
- **비-HITL**(서브에이전트 위임, `/loop`, 자동 파이프라인, 사용자가 묻지 말라고 한 경우): 묻지 않는다. 제안 범위로 진행하고 보고에 확인 목록을 남긴다. 플랫폼 전제가 확정되지 않았으면 보고 첫머리에 blocker로 남긴다.
- 화면 구성을 바꾸는 PRD 미결 질문(Q-n)이 있어도 멈추지 않는다 — 제안값으로 가정해 같은 메시지에서 확인한다(가이드 §2).

### 2. WIREFRAMES.md 작성

`assets/WIREFRAMES.template.md` 골격을 따른다(헤더 구조를 바꾸지 않는다 — 갱신 모드·FRD·디자인 시스템 B-n이 이 구조를 참조한다). 규칙은 가이드 §3~§5.
- 모든 W-n은 F-n/FR-n·S-n으로 역추적되고, 화면이 있는 모든 MVP F-n은 W-n을 가진다.
- 화면마다 우선순위 블록(실제 핵심 문구 초안)·주요 동작 1개·상태(기본/로딩/빈/오류 + 해당 게이트)·검증할 제약을 쓴다.
- §5 컴포넌트 후보는 2화면 이상 또는 변형 3개 이상만, 역할 이름으로.

### 3. 그리기 — 도구 어댑터

`tool=none`이면 건너뛴다. `tool=pencil`이면 `references/tool-pencil.md` 순서대로: 사전 조건 확인(열린 `.pen` 없으면 HITL은 한 번 요청, 비-HITL은 건너뜀) → **Pencil `read_skill`로 공식 가이드 선행 로드** → lo-fi 회색조로 W-n 프레임 작성 → 프레임 목록을 문서 §2와 1:1 대조.
그리지 못했으면 문서는 그대로 완성하고 보고에 이유와 재실행 방법을 남긴다.

### 4. 검증 → 보고

§4 "검증할 제약"을 판정해 §6에 남기고(미작도면 "판단 불가 — 미작도"), 가이드 §7 체크리스트를 돌려 고친 뒤 보고한다.
보고: 산출물 경로, 모드, 화면 수·프레임 대조 결과, §6 결과 중 PRD·TRD 영향(갱신 필요 항목), 확인 목록(착수를 막는 것 먼저), 다음 단계 — TRD가 없으면 먼저 `/devoks-sdlc:product-trd-author`(§2.1 확정·디자인 시스템 B-n 생성), 그다음 디자인 시스템 B-n(`FEATURES.md` 기반 구역의 시드로 `/devoks-sdlc:feature-frd-author frd=<시드>`, 시드가 없으면 "TRD 갱신 필요") → MVP 화면 F-n FRD(이 문서의 W-n을 관련 문서로).
`WIREFRAMES.md`는 `version: 0.1.0`, `status: draft`로 시작한다.

## 갱신 모드

PRD·TRD 버전이 frontmatter보다 높거나 화면 변경 요청이 오면, 변경 목록(W-n·연쇄 영향 — FRD·디자인 시스템 B-n)을 만들어 **확인 후** 쓴다(비-HITL이면 보고만). 문서를 먼저 고치고 디자인 파일을 맞춘다. 삭제한 W-n은 `dropped`로 남긴다. 상세: 가이드 §8.

## 완료 기준

- 모든 W-n이 F-n/FR-n·S-n으로 역추적되고, 화면이 있는 MVP F-n이 모두 W-n을 가진다.
- 모든 핵심 시나리오가 §3 흐름에 있고, 모든 W-n에 우선순위 블록·주요 동작·상태·검증할 제약이 있다.
- §5 컴포넌트 후보가 있고, 색·토큰 값·EARS AC·엔드포인트가 없다.
- `tool=pencil`로 그렸으면 프레임과 §2가 1:1로 대조됐다 / 그리지 못했으면 이유와 재실행 방법이 보고에 있다.
- 플랫폼 전제(주 타깃·역할별 기기·뷰포트)가 확인됐거나 TRD 확정값을 인용했다 / 미확정이면 blocker로 보고했다.
- 범위 확인은 한 메시지로 묶였다(HITL) / 확인 목록이 보고에 있다(비-HITL).

> 경계·규칙·체크리스트: `references/design-guide.md` · Pencil 절차: `references/tool-pencil.md`
