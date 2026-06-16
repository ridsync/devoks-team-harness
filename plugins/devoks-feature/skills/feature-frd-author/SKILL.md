---
description: 거친 기능 아이디어나 FRD 초안을 받아, EARS Acceptance Criteria·Contract(파라미터/상태전이)·Resource 체크리스트·Edge Case·Testing Strategy를 갖춘 정련된 FRD.md로 완성한다. "FRD 초안 정리해줘", "기능 요구서 다듬기", "요구사항을 EARS로 정형화", "AC/Contract 정리", "스펙 문서 작성" 같은 요청에서 사용한다. FRD→PLAN→실행 전체를 한 번에 돌리려면 devoks-feature:feature-workflow-runner, 작성 후 작업 분해는 devoks-feature:feature-plan-author 를 쓴다.
metadata:
  author: ridsync
  version: 1.0.0
---

# frd-author — FRD 정련 (Phase 1)

거친 초안을 검증 가능한 FRD로 만든다. `devoks-feature:feature-workflow-runner` 의 **Phase 1만** 단독 실행하는 얇은 스킬이다.
공유 자산/레퍼런스는 통합 스킬 디렉터리를 그대로 참조한다(중복 정의 금지, SSOT).

## 호출 방법

```
/devoks-feature:feature-frd-author [frd=<초안 경로 또는 본문>] [out=<산출물 디렉터리>]
```

- `out` 기본값 = `.claude/workspace/{feature-name}-{date}/`. 산출물 = `<out>/FRD.md`. → `../devoks-feature-workflow-runner/references/output-location.md`
- 워크스페이스에는 FRD 문서와 입력 초안·리소스 사본만 모은다. 코드는 두지 않는다(이 스킬은 코드 미생성).

## 절차

0. **워크스페이스 확정 · 초안 원문 보존** — `out` 경로 `.claude/workspace/{feature-name}-{date}/`(date=`yyyyMMdd`)를 정한다. 시안·시각 리소스 사본은 **`<out>/assets/`** 에 `RES-ASSET-NNN_<slug>` 네이밍으로 저장하고(시안 외 대용량·저장소 안 리소스는 경로만 기록), FRD §6.3 Assets 표 ID와 일치시킨다. **본문으로 받은 초안은 `<out>/FRD.draft.md` 로 원문 그대로 보존**한다: 짧은 출처 헤더 + 초안 원문 verbatim + 정련 중 사용자 확인으로 확정된 결정 누적(추측 금지). 정련 결과는 `FRD.md`. → 디렉토리·`assets/`·보존 형식 근거는 `../devoks-feature-workflow-runner/references/output-location.md`(SSOT).
1. **골격 로드** — `../devoks-feature-workflow-runner/assets/FRD.template.md` 를 읽어 형식을 따른다.
2. **요구 추출** — 초안에서 Goal·Context·요구사항 후보를 뽑는다.
3. **EARS 정형화** — 각 요구를 `REQ-xxx` + `AC-xxx-y`(정상 WHEN/WHILE + 예외 IF 최소 1쌍)로. → `../devoks-feature-workflow-runner/references/ears-acceptance-criteria.md`
4. **분리 기재** — 수치/세팅/상태전이 → §5 Contract(`CTR-xxx`), 예외 상황 → §8 Edge(`EDGE-xxx`).
5. **착수 리소스** — §6(참고 코드·외부 문서·시안·API), §7 Constraints(PR 분리 기준·기술 제약)를 채운다.
6. **§4 설계 스펙** — 복잡도 임계(파일 3개 초과·신규 모듈/계층·아키텍처 변경·새 패턴) 초과 시 코드 패턴을 먼저 탐색하고 **설계안을 제안·확인**한 뒤 컴포넌트 구조·패턴(`DSN`)·모듈 배치를 채운다. 단순 기능은 §4.1만 간결히. → `../devoks-feature-workflow-runner/references/design-spec.md`
7. **확인 후 작성** — 누락 슬롯은 한 번에 모아 사용자에게 확인(추측 금지 — 요구는 묻고, 설계는 제안 후 확인) → `<out>/FRD.md` 작성.

## 완료 기준

- 모든 REQ가 검증 가능한 AC를 가짐(통과/실패 판정 가능).
- 측정값은 CTR로, 예외는 EDGE로 분리됨.
- 복잡도 임계 초과 기능은 §4 설계 스펙(컴포넌트/패턴/배치)이 채워지고 확인됨.
- ID 체계(`REQ`/`AC`/`CTR`/`EDGE`/`DSN`)가 일관되어 다음 단계(PLAN)의 `traces`로 바로 인용 가능.

> 막히면 `../devoks-feature-workflow-runner/references/example-walkthrough.md` 의 완성 예시를 참고한다.
