---
name: new-smoke-test-draft
description: 설치된 대상 프로젝트의 라우트/화면 정의 파일을 스캔해, 배포 전 스모크 테스트용 프로젝트 소유 스킬 초안(SKILL.md + 코어 스크린 체크리스트 + 딥다이브 체크리스트 스텁 + 리포트 템플릿)을 그 프로젝트의 `.claude/skills/`에 1회 생성한다. 생성 후 완성·실행·유지보수는 대상 프로젝트 자신이 맡으며, devoks-sdlc는 이 생성기만 소유한다. 감지된 라우트 파일은 추천 근거일 뿐이며 화면 목록은 반드시 사용자 확인을 거쳐 확정한다. "스모크 테스트 스킬 만들어줘", "배포 전 검증 스킬 초안 생성", "화면 목록으로 스모크 체크리스트 만들어줘", "verify-app-smoke-test 같은 거 초안 생성", "smoke test skill draft" 요청에서 사용한다. 생성된 스킬을 실제로 실행하려면(devoks-browser 플러그인 필요) 그 프로젝트 자신의 스킬 문서를 참고한다.
metadata:
  author: ridsync
  version: 1.0.0
---

# Smoke Test Skill Draft (프로젝트 전용 스모크 테스트 초안 생성)

## Overview

이 스킬은 검증을 **수행하지 않는다** — 설치된 대상 프로젝트의 라우트/화면 정의 파일을 스캔해, 배포 전
스모크 테스트를 수행할 **새 스킬 초안**을 그 프로젝트의 `.claude/skills/`에 1회 생성한다.

- **생성기 vs 산출물 소유가 다르다.** devoks-sdlc는 이 생성기(`new-smoke-test-draft`)만 소유·유지보수한다.
  생성된 스킬은 쓰이는 즉시 **완전히 대상 프로젝트 소유**로 넘어간다 — devoks-sdlc는 그 이후 어떤 동기화·재적용
  관계도 갖지 않는다(`devoks-core:project-convention-manage`류 drift 감지·재적용 스킬을 만들지 않는다).
- **이 스킬은 "설치된 대상 프로젝트"에서 쓰라고 만든 것이다.** 이 harness 저장소(`devoks-team-harness`)
  자신에는 스캔할 실제 앱 라우트가 없으므로 이 저장소 자기 자신을 대상으로 실행하지 않는다.
- 라우트 감지는 **추천 근거일 뿐 SSOT가 아니다** — 화면 목록은 반드시 쓰기 전에 사용자 확인을 거친다
  (`devoks-core:setup-project-convention`의 스택 감지 원칙과 동일).

## 의존성

- **이 생성기 자신**은 MCP가 필요 없다 — 대상 프로젝트의 라우트 파일을 Read/Grep/Glob으로 스캔하고, 확정된
  내용을 새 파일로 쓰는 것이 전부다.
- **생성된 초안을 나중에 실행**하려면(이 스킬의 책임 범위 밖) 대상 프로젝트에 `devoks-browser` 플러그인
  (Chrome DevTools MCP, `mcp__chrome-devtools-attach__*`, 9269 attach)과 실행 중인 dev server가 필요하다 —
  생성 단계에서는 필요 없다.

## 호출 방법

```
/devoks-sdlc:new-smoke-test-draft [scan=<스캔 시작 경로>] [name=<생성될 스킬 이름>]
```

두 인자 모두 선택이며 비어 있으면 Phase 0~2에서 확인한다.

---

## Phase 0 — 스캔 범위 합의

1. `scan` 인자가 있으면 그 경로를, 없으면 저장소 루트를 스캔 시작점으로 삼는다.
2. 한 줄 통보: "지금은 초안을 생성하는 단계라 devoks-browser·dev server가 필요 없습니다 — 나중에 생성된
   스킬을 **실행**할 때만 필요합니다."
3. **모노레포 캡션**: `apps/*`, `packages/*` 같은 구조에서 독립된 앱 루트가 여럿 발견되면 **병합하지 않는다**
   — 후보를 나열하고 이번에 초안을 만들 앱 하나를 확인한다(다른 앱은 이 스킬을 다시 호출해 별도 생성).

## Phase 1 — 화면 목록 감지 및 확인

`references/screen-detection-heuristics.md`의 절차를 따른다(요약):

1. `package.json`/설정 파일로 스택 계열 감지(React Router / Next.js / Expo Router / React Navigation /
   Android·iOS 네이티브).
2. 감지된 계열에 맞는 라우트/화면 정의 파일 후보를 탐색한다.
3. **후보가 0개**이거나 **서로 다른 계열의 후보가 2개 이상 동시에 그럴듯하면** — 추측하지 않고 사용자에게
   실제 라우트/화면 정의 파일을 직접 지목해 달라고 요청한다.
4. 후보가 하나로 좁혀지면 `references/screen-detection-heuristics.md` §4의 기계적 규칙(라우트 경로의
   첫 세그먼트로 도메인 그룹핑, 도메인 지식 추측 없음)으로 화면마다 ID를 부여하고, `ID | 화면 이름 |
   라우트 경로 | 소스 파일:줄` 표로 정리한다.
5. **쓰기 전 필수 확인**: 이 표를 사용자에게 보여주고 추가·삭제·정정을 받는다(ID도 조정 가능함을 함께
   안내한다). 확인 없이 다음 Phase로 넘어가지 않는다 — 감지 결과는 추천 근거일 뿐 SSOT가 아니다.

## Phase 2 — 생성 대상 이름/경로 확정

1. 생성될 스킬 이름은 `name` 인자가 있으면 그 값을, 없으면 기본값 `verify-app-smoke-test`를 쓴다. 명확한
   기본값이 있는 경우이므로 묻지 않고 한 줄로 통보 후 진행한다: "생성될 스킬 이름: `verify-app-smoke-test`
   (다른 이름을 원하면 지금 말씀해 주세요)."
2. 대상 경로: `.claude/skills/<name>/`(SKILL.md, `references/core-screens-checklist.md`,
   `references/deep-dive-checklist.md`, `references/report-template.md`).
3. **자동 덮어쓰기 금지** — 대상 경로의 **4개 파일을 각각 개별로** 존재 확인한다(중단된 이전 실행의 부분
   생성물이 조용히 이어서 덮이지 않도록). 하나라도 있으면 `AskUserQuestion` 단일선택으로 확인한다:
   `재생성(덮어쓰기)` / `다른 이름으로` / `취소`. 아무것도 없으면 바로 Phase 3으로 진행한다.

## Phase 3 — 산출물 생성

`${CLAUDE_PLUGIN_ROOT}/skills/new-smoke-test-draft/assets/`의 4개 템플릿을 확정된 화면 목록·라우트 경로·
프로젝트 정보로 채워 대상 경로에 쓴다.

- `assets/skill-draft.template.md` → `.claude/skills/<name>/SKILL.md`
- `assets/checklist.template.md` → `.claude/skills/<name>/references/core-screens-checklist.md`
- `assets/deep-dive-checklist.template.md` → `.claude/skills/<name>/references/deep-dive-checklist.md`
- `assets/report.template.md` → `.claude/skills/<name>/references/report-template.md`

작성 시 지킬 것:

- Phase 1에서 확정한 화면 ID를 `core-screens-checklist.md`·`deep-dive-checklist.md`(코어 체크리스트 대응
  ID 컬럼)·`report-template.md` 3개 파일 전부에 **동일하게** 반영한다 — 세 파일이 서로 다른 ID를 쓰면
  화면을 교차 참조할 수 없다. 도메인이 2개 이상이면 `report-template.md`에 도메인별 집계 표도 포함한다.
- **생성하는 SKILL.md의 `description`에 콜론+공백(`: `)이 들어가면 반드시 따옴표로 감싼다** — 이 저장소의
  YAML frontmatter 규칙은 생성기 자신뿐 아니라 생성기가 만드는 파일에도 그대로 적용된다.
- `metadata.author`는 대상 저장소에서 `git config user.name`을 시도하고, 실패하면 `<TODO: 담당자>`
  플레이스홀더로 남긴다 — harness 저자(`ridsync`)를 하드코딩하지 않는다.
- `metadata.generatedBy: devoks-sdlc:new-smoke-test-draft@1.0.0`, `metadata.generatedFrom: <감지된 라우트
  파일 경로>`를 1회성 참고 정보로만 남긴다(지속 동기화 값이 아니다 — 이후 devoks-sdlc는 이 값을 다시
  읽거나 비교하지 않는다).
- 동적 라우트(`:id` 등) 화면의 파라미터 확보 방법은 생성 결과의 Phase 0에 `TODO:` 플레이스홀더로 남기고,
  임의 값(`test-id` 등)을 지어내 채우지 않는다 — 이 생성기는 대상 프로젝트의 실제 시드 데이터를 알 수 없다.
- 생성 결과의 모드 표는 **2행(코어 스크린 스모크 + 딥다이브)** 을 채운다. 딥다이브 행의 상태는
  `references/deep-dive-checklist.md`의 화면별 상태(전부 `TODO: 시나리오 미작성`)를 그대로 반영한다 —
  이 스킬은 딥다이브 파일의 **구조**(화면 목록·섹션 골격)까지는 생성하지만, 실제 UX 시나리오 **본문**은
  생성기가 알 수 없으므로 임의로 지어내지 않는다.
- 생성 결과의 Phase 1~2(실행)에는 전담 서브에이전트 추가 여부를 아래 **구조화된 지시**로 안내한다(v1은
  서브에이전트 파일 자체를 생성하지 않는다 — 안내만 남긴다):
  1. 제안 파일 경로: `.claude/agents/<name>-runner.md`
  2. 필수 frontmatter: `name`, `description`(agent-internal 성격 표기), `tools`, `model: sonnet`
     (스펙이 닫힌 실행 역할이라 상위 모델 이득이 없다 — `devoks-sdlc:verify-acceptance-test`의
     `acceptance-test-runner` 패턴과 동일 근거).
  3. **함정 경고를 그대로 포함한다**: "`tools:` frontmatter는 화이트리스트로 동작한다 — 실제 사용할 MCP
     도구(devoks-browser가 제공하는 Chrome DevTools MCP 등)의 정확한 이름을 하나라도 빠뜨리면 에이전트가
     그 도구를 호출하는 모든 Phase에서 조용히 차단된다. 만들기 전에 devoks-browser 스킬 문서에서 실제 tool
     이름을 확인하고, 추측으로 채우지 않는다."
  4. 참고할 기존 패턴 이름만 가리킨다(`verify-acceptance-test`의 `acceptance-test-runner`, 또는
     `browser-visual-diff`의 `browser-visual-diff-capture`) — 에이전트 파일 내용을 복사하지 않는다.

## Phase 4 — 마무리 안내

- 생성한 4개 파일의 경로를 요약한다.
- "이 파일들은 이제부터 완전히 이 프로젝트 소유입니다 — devoks-sdlc는 이후 이 결과물과 어떤 동기화 관계도
  갖지 않습니다"를 명시한다.
- 생성 결과에 남은 `TODO:` 항목(라우트 파라미터 확보 방법, 담당자 등)이 있으면 첫 실행 전에 채워야 함을
  안내한다.
- 대상 프로젝트에 `devoks-browser` 플러그인이 안 보이면(차단은 아님) 생성 결과를 실제로 **실행**하기 전에
  설치가 필요하다고 안내한다.

---

## Rules

- 감지 결과는 추천 근거일 뿐이다 — 화면 목록·계열 판정 어느 쪽도 사용자 확인 없이 SSOT로 단정하지 않는다.
- 후보가 없거나 상충하면 추측 대신 사용자에게 라우트 파일을 직접 지목해 달라고 요청한다.
- 대상 경로에 이미 파일이 있으면 절대 자동 덮어쓰지 않는다.
- 동적 라우트 파라미터 확보 방법을 임의로 지어내지 않는다 — TODO로 남긴다.
- 딥다이브 체크리스트의 시나리오 본문을 화면 목록만으로 지어내지 않는다 — 구조(화면 목록·섹션 골격)만
  생성하고 내용은 TODO로 남긴다.
- 모노레포에서 여러 앱 후보를 하나로 병합하지 않는다.
- 이 스킬 자신은 devoks-browser를 요구하지 않는다(생성 단계 한정) — 요구하는 것은 생성 결과를 실행할 때다.
- 생성 후에는 산출물과 어떤 지속 동기화·재적용 관계도 만들지 않는다(1회성 생성).

---

## Reference 파일 목록

| 파일 | 역할 |
|------|------|
| `references/screen-detection-heuristics.md` | 생성기 전용 — 스택별 라우트 파일 탐지 절차(대상 프로젝트로 복사되지 않음) |
| `assets/skill-draft.template.md` | 대상 프로젝트 `.claude/skills/<name>/SKILL.md`로 채워져 쓰이는 템플릿 |
| `assets/checklist.template.md` | 대상 프로젝트 `.claude/skills/<name>/references/core-screens-checklist.md`로 채워져 쓰이는 템플릿 |
| `assets/deep-dive-checklist.template.md` | 대상 프로젝트 `.claude/skills/<name>/references/deep-dive-checklist.md`로 채워져 쓰이는 템플릿(구조 스텁) |
| `assets/report.template.md` | 대상 프로젝트 `.claude/skills/<name>/references/report-template.md`로 채워져 쓰이는 템플릿 |
