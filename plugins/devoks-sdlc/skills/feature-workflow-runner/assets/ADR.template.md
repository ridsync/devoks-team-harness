---
id: ADR-NNN
title: "<결정 한 줄 — 예) 서버 상태는 TanStack Query로 관리한다>"  # 값은 항상 쌍따옴표(콜론+공백 포함 시 YAML 파싱 실패)
status: proposed  # proposed → accepted → superseded | deprecated
date: "<YYYY-MM-DD>"
supersedes: "<ADR-NNN | 없음>"
superseded_by: "<ADR-NNN | 없음>"
source: "<결정 출처 — 예) TRD v0.2.0 §2 / docs/workspace/<기능>/FRD.md DSN-002 / code-refactoring / 대화>"
---
<!-- 쓰기 전에 adr-guide §1 세 관문(A 아키텍처 범위 · B 되돌리기 비용 · C 이유가 코드에 없음)을 모두 통과했는지 확인한다.
     본문 40줄 안팎. 칸을 채울 내용이 없으면 "기록 없음" 등으로 메우지 말고 관문을 다시 의심한다. 이 주석은 지운다. -->

# ADR-NNN: <title>

## Context
<2~5줄. 이 결정을 강제한 요구·제약(NFR-n·불변식·기존 구조·외부 사실)과 지금의 문제. 확인 못 한 사실은 `미확정`.>

## Decision
<1~3문장, 능동형 "~로 한다". 실행 규칙 전문(폴더 표·import 제한·설정값)은 TRD §3.1·project-convention에 두고 여기엔 골자만.>

## Rationale
- <이 안이 Context의 어떤 요구·제약을 충족하는가 — 예: NFR-2 응답 200ms → 캐시 계층 필요. 근거 문서는 출처를 붙인다>
- <"사용자 결정"만 쓰지 않는다 — 그 결정의 이유(제약·우선순위)를 쓴다>

## Considered Alternatives
| 기각한 대안 | 장점 | 기각 이유 |
|---|---|---|
| <대안 B> | <> | <이 프로젝트의 어떤 제약 때문에 안 되는가> |

## Consequences
- **감수하는 것:** <구조적 비용·제약·부채 — 변경 파일 목록·이주 절차는 PR에>
- **이후 코드가 지킬 규약:** <골자 + 상세 규칙 링크 — 없으면 이 줄을 지운다>

## Revisit Conditions
- <관찰 가능한 조건 — 예: 동시 사용자 1만 초과, 모바일 앱 착수>

## Related
- <PRD/TRD 절 · 대체/피대체 ADR · 공식 문서 — 필요한 것만>
