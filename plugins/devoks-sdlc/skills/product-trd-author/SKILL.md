---
name: product-trd-author
description: "제품 PRD(PRD.md·FEATURES.md)를 받아 여러 기능이 함께 쓰는 기술 구조를 정하는 TRD.md(기술스택·시스템 구성·공유 도메인 모델·인터페이스 규약·NFR/불변식 보장 설계·계측 설계·개발 기반·기술 리스크·ADR)를 작성하거나 갱신하고, 공통 기반 작업(B-n)을 FEATURES.md 기반 구역에 FRD 시드로 낸다. 기존 코드베이스면 현행 스택을 사실로 기록하고 변경 결정만 남긴다. 사실(기존 시스템·조직 표준·호스팅·연동·규제·팀 역량)은 한 번에 묻고 스택·구조 같은 판단은 대안 비교와 함께 제안해 같은 메시지에서 확인한다. \"TRD 써줘\", \"기술 설계 문서\", \"아키텍처 정해줘\", \"기술스택 정하기\", \"PRD 기반으로 기술 구조\", \"TRD 양식 줘\", \"TRD 업데이트\" 요청에서 사용한다. 무엇을 만들지는 devoks-sdlc:product-prd-author, 기능 하나 안의 설계는 devoks-sdlc:feature-frd-author(§4)가 맡는다."
argument-hint: "[src=<PRD 경로|TRD 입력 양식 경로> (default: <out>/PRD.md)] [out=<디렉터리> (default: docs/product)]"
metadata:
  author: ridsync
  version: 1.0.1
---

# product-trd-author — 제품 TRD · 기술 구조 작성/갱신

PRD가 "무엇을 왜"를 고정했다면 TRD는 **여러 기능이 함께 쓰는 "어떻게"**를 고정한다 — 스택, 경계, 공유 데이터,
불변식을 어디서 보장하는가. 이게 없으면 기능마다 FRD §4가 제각각 구조를 정해 PLAN이 서로 다른 방향으로 흩어진다.
기능 하나 안의 설계(컴포넌트·엔드포인트·EDGE)는 FRD가 소유하므로 쓰지 않는다.

```
PRD.md + FEATURES.md ─▶ [이 스킬] TRD.md + FEATURES.md 기반 구역(B-n) ─▶ (B-n → F-n 순) feature-frd-author
                                       └─▶ /devoks-core:setup-project-convention (stack preset 안내)
```

## 범위 (중요)

| 입력 | 쓸 스킬 |
|---|---|
| PRD가 있고 기술 구조·스택을 정해야 함 / 기존 코드베이스에 PRD 요구를 얹어야 함 | **이 스킬** |
| 기술 결정 변경, PRD 갱신에 따른 TRD 반영 | **이 스킬** (갱신 모드) |
| PRD가 없음 | `devoks-sdlc:product-interview` → `product-prd-author` 먼저 |
| 기능 하나 안의 구조·패턴 | `devoks-sdlc:feature-frd-author` §4 (TRD가 있으면 그 구조를 따른다) |

- 인터뷰 단계가 없다 — 무엇을 만들지는 PRD가 이미 정했으므로 의도를 좁힐 대화가 필요 없다. 확인은 한 번에 묶는다.
- 하지 않는 것: 일정·공수·비용 산정, 엔드포인트 상세·EARS AC, 클래스 수준 설계, 코드·스캐폴딩 생성, preset 자동 적용.

## 호출 방법

```
/devoks-sdlc:product-trd-author [src=<PRD 경로|TRD 입력 양식 경로> (default: <out>/PRD.md)] [out=<디렉터리> (default: docs/product)]
```

> 표기: `key=값` 필수 · `[key=값]` 선택 · `(default: X)` 미지정 시 X로 진행.

- 산출물: `<out>/TRD.md`, `<out>/FEATURES.md`의 "기반" 구역. `<out>/TRD.md`가 이미 있으면 **갱신 모드**.

### 양식만 요청받은 경우

"TRD 양식 줘"처럼 입력 양식만 원하면 `assets/TRD.intake.md`를 `<out>/TRD.intake.md`로 복사하고(이미 있으면 덮어쓰지 않고 경로만 알린다) "채운 뒤 `/devoks-sdlc:product-trd-author src=<out>/TRD.intake.md`"를 안내하고 멈춘다.

## 절차

### 0. 입력 수집 · 모드 판별

- PRD를 읽는다 — 입력 양식의 "기준 PRD" 경로가 있으면 그것을, 없으면 `<out>/PRD.md`와 같은 디렉터리의 `FEATURES.md`. 없으면 TRD를 쓰지 않고 PRD부터 만들 것을 안내하고 멈춘다 — 기준 요구 없이 정한 스택은 취향이다.
- `src`가 `## 기술 입력 요약`(채운 `TRD.intake.md`)이면 그 사실은 다시 묻지 않는다.
- 저장소에 애플리케이션 코드가 있으면 **brownfield**, 없으면 **greenfield**(`references/trd-guide.md` §4). brownfield는 매니페스트·설정·디렉터리 구조를 읽어 현행 스택을 사실로 확보한다.
- `<out>/TRD.md` 존재 → 갱신 모드로.

### 1. 사실 확인 + 판단 제안 — 한 메시지로

`references/trd-guide.md` §2·§3을 따른다.

- **사실**(입력 양식 6칸): PRD §7·저장소에서 확인되지 않는 것만 묻는다.
- **판단**: 스택(레이어별)·구성요소 분할·인증·저장소·불변식 보장 위치를 `제안: X — 대안 Y·Z 대비 <NFR-n·제약·팀 역량> 때문`으로 제시한다. 버전·지원 여부·가격은 Context7 또는 공식 문서로 확인하고 출처를 붙인다 — 확인 못 한 버전은 적지 않는다.
- 두 가지를 **한 메시지에** 담아 확인받는다. 사용자는 "다 맞아"나 고칠 줄만 답하면 된다.
- **비-HITL**: 묻지 않는다. 사실은 `미확정`, 판단은 제안값으로 쓰고 보고에 확인 목록을 남긴다.

### 2. TRD.md 작성

`assets/TRD.template.md` 골격을 따른다(헤더 구조를 바꾸지 않는다 — 갱신 모드와 FRD가 이 구조를 참조한다).

- PRD의 **모든 NFR**(불변식 포함)을 §6에 보장 위치·검증 레벨과 함께 옮기고, **모든 계측 FR**을 §7 이벤트로 설계한다.
- §4는 둘 이상의 F-n이 쓰는 엔티티만. 판단 기준은 "이 결정이 바뀌면 여러 기능이 같이 바뀌는가?"(가이드 §1).
- 주요 판단은 §12 ADR로 남긴다(결정·대안·이유·되돌리는 조건).
- `미확정`·`제안`은 §11에 모은다(`ID | 질문 | 막는 것`).

### 3. 기반 작업 → FEATURES.md 기반 구역

둘 이상의 기능이 의존하는 공통 기반(골격·인증·공유 모델·CI·계측 파이프라인)을 `B-n`으로 뽑아 `FEATURES.md`의 "기반" 구역에 FRD 시드(FRD 입력 양식과 같은 칸)로 쓴다(가이드 §6). 이 구역은 이 스킬이 소유한다. TRD §10에는 목록만 둔다.

### 4. 자체 점검 → 보고

`references/trd-guide.md` §7 체크리스트를 돌려 고친 뒤 보고한다: 산출물 경로, 모드, 섹션별 확정/제안/미확정, 확인 목록(착수를 막는 것 먼저), 다음 단계 — stack preset이 정해졌으면 `/devoks-core:setup-project-convention` 안내, 그다음 B-n → MVP F-n 순으로 `/devoks-sdlc:feature-frd-author frd=<시드>`.
`TRD.md`는 `version: 0.1.0`, `status: draft`로 시작한다.

## 갱신 모드

PRD 버전이 TRD의 `prd_version`보다 높거나 기술 결정을 바꾸자는 요청이 오면, 변경 목록(섹션·ID·연쇄 영향)을 만들어 **확인 후** 쓴다(비-HITL이면 보고만). ADR은 지우지 않고 새 ADR + `superseded by` 표시. 영향받는 FRD는 "재검토 필요"로 보고한다. 상세: 가이드 §8.

## 완료 기준

- §2 모든 선택에 대안·이유(NFR-n·제약·팀 역량 연결)가 있고, 시점 의존 정보는 출처가 있거나 §11로 갔다.
- brownfield면 현행 스택이 근거 경로와 함께 사실로 기록되고 재선정되지 않았다.
- PRD의 모든 NFR이 §6에, 모든 계측 FR이 §7에 있다.
- 엔드포인트 목록·EARS AC·기능 내부 설계가 없다.
- B-n이 FEATURES.md 기반 구역에 FRD 시드로 있다.
- 확인은 한 메시지로 묶였다(HITL) / 확인 목록이 보고에 있다(비-HITL).

> 경계·규칙·체크리스트: `references/trd-guide.md`
