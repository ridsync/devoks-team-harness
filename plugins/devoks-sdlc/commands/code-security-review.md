---
description: baseline 또는 targeted 모드로 리포지토리·의존성·서버·브라우저·위협 수준의 전용 보안 검증을 수행한다.
---

# 보안 검증 (Security Review)

## Overview

리포지토리·의존성·서버·브라우저·배포·위협 수준의 **전용 보안 검증**을 수행한다. 변경분 단위 경량 보안 체크(`code-review`에 포함)에서 승격하거나, repo 기준선을 독립적으로 감사할 때 사용한다.

스캔·분석은 `code-security-reviewer` 에이전트에 위임하고, **리포트만** 돌려받는다.  
출력 형식은 `devoks-sdlc:code-security-review` 스킬을 따른다.

---

## Steps

### 1. 검증 모드·범위 확정

검증 시작 전에 아래를 확인한다.

1. **모드**
   - `baseline`: 신규/인수/중요 릴리스/사고 후 repo 전반 기준선 감사
   - `targeted`: auth, session, raw HTML, API, dependency 등 고위험 영역 집중 감사
2. **대상 범위** — 전체 repo / 특정 폴더·모듈 경로
3. **보안 프로필** — 프로젝트 선언값, 없으면 `baseline`
4. **중점 영역(선택)** — auth/session/browser/dependency/data/deploy 등
5. **제외 범위(선택)** — 벤더 디렉토리, 생성물 등

모드와 범위가 모호하면 `baseline`, 전체 repo(`.`), profile `baseline`로 진행하되 한 줄로 안내한다. 특정 고위험 변경을 사용자가 지목했다면 `targeted`로 해석한다.

### 2. code-security-reviewer 에이전트 호출

범위 확정 후 `code-security-reviewer` 에이전트를 아래 파라미터로 호출한다.

| 파라미터 | 값 |
|---------|-----|
| `mode` | 1단계에서 확정한 `baseline` 또는 `targeted` |
| `scope` | 1단계에서 확정한 경로 (전체 repo면 `.`) |
| `profile` | 프로젝트 선언값, 없으면 `baseline` |
| `focus` | 선택한 중점 영역, 없으면 빈 값 |
| `exclusions` | 승인된 제외 범위, 없으면 생성물·vendor 기본 제외 |

> ⚠️ **이 단계는 Pass-through 전용이다.** 메인 에이전트는 subagent 리포트를 요약·압축·재작성·생략해서는 안 된다. 기본 brevity 설정과 무관하게, subagent가 반환한 리포트 전문을 **한 글자도 빠뜨리지 않고 그대로** 사용자에게 출력한다.

**금지:**
- 헤더·섹션 축약 (예: "요약" 섹션 생략)
- 이슈 설명 단축 (심각도·근거·권장 조치 항목 축약)
- 표·리스트 구조 변경
- 자체 해석이나 추가 코멘트 삽입 (리포트 본문 앞뒤에 붙이는 것도 금지)

### 3. 조치 진행 여부 확인

리뷰 후 사용자에게 반영 범위를 확인한다.

- Critical 즉시 / High 이상 / 전체 중 선택지와 제외 사항을 기준으로 조치 진행한다.
- 수정이 필요한 항목은 확인 후 계획을 세워 진행한다(보안 스킬은 제안만 하며 자동 수정하지 않는다).
- `not-run`과 coverage limit은 취약점 0과 별도로 재검증 계획을 세운다.
