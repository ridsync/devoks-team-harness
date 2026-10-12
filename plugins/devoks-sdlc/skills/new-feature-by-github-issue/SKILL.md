---
description: "GitHub에 이미 등록된 태스크 이슈 본문을 SSOT로 삼아, 프로젝트 패턴에 맞게 기능을 설계·구현한다(요구 정리 → 설계·승인 → 브랜치 사전체크 → 구현 → 마무리). FRD/PLAN 산출물 없이 이슈 하나로 바로 구현하는 간이 경로다. \"이 이슈로 기능 구현해줘\", \"깃헙 이슈 기반으로 개발\", \"이슈 #42 구현\", \"issue driven development\" 같은 요청에서 사용한다. 이슈 자체를 새로 등록하려면 devoks-git:git-create-issue, 추적 가능한 FRD/PLAN 산출물과 태스크 단위 진행이 필요하면 devoks-sdlc:feature-workflow-runner 를 쓴다."
argument-hint: "issue=<이슈 URL|owner/repo#번호|본문 전체>"
metadata:
  author: ridsync
  version: 1.0.1
---

# new-feature-by-github-issue — GitHub Issue 기반 기능 구현

GitHub에 등록된 **태스크 이슈 본문**을 SSOT로 삼아, 프로젝트 패턴에 맞게 기능을 설계·구현한다. **요구 정리 → 설계·승인 → 브랜치 사전체크 → 구현 → 마무리** 순서를 따른다. 이 스킬에는 **제품·도메인 전용 용어·스택**을 넣지 않는다.

이슈는 **이미 등록된 것을 읽기만** 한다 — 이슈 생성·GitHub write는 이 스킬의 범위가 아니다(새 이슈 등록은 `/devoks-git:git-create-issue`). 계획 수립 → 승인 → 구현이 절차의 본질(추론과 사용자 승인이 반복되는 상호작용)이므로, 서브에이전트로 위임하지 않고 **메인 루프에서 직접 실행**한다.

---

## 호출 방법

```
/devoks-sdlc:new-feature-by-github-issue issue=<이슈 URL|owner/repo#번호|본문 전체>
```

> 표기: `key=값` 필수 · `[key=값]` 선택 · `(default: X)` 미지정 시 X로 진행.

**예시:**

```
/devoks-sdlc:new-feature-by-github-issue issue=https://github.com/my-org/my-app/issues/42
/devoks-sdlc:new-feature-by-github-issue issue=my-org/my-app#42
```

| 슬롯 | 의미 | 입력 방법 |
|------|------|----------|
| `issue` | 이슈 URL / `owner/repo#번호` / 이슈 본문 전체(API·CLI 불가 시 붙여넣기) | `issue` 인자 또는 Phase 0 확인 (필수) |

---

## Steps

### 0. 이슈 로드·파싱·갭 분석

- `issue` 인자로 본문을 가져오거나(GitHub MCP → `gh issue view` → 붙여넣기 순), 붙여넣기로 직접 받는다.
- 고정 헤더·선택 소제목·인용 정규화로 요구사항을 구조화하고, 차단 규칙을 적용해 갭 표를 만든다. 알고리즘·차단 조건 SSOT는 `references/issue-parsing-and-gap-analysis.md`.
- 차단이 있으면 **1단계로 가지 않는다** — 갭 표 + 확인 질문(1~2개) + 보완 경로를 제시한다.

### 1. 요구사항 정리 (갭 없을 때)

- 기능 범위, 입력/출력, 에러 케이스를 이슈에서 확정한다.
- 기존 유사 기능 탐색 (`Grep`, `Glob`).
- API·계약·인증이 이슈에 있으면 반영한다.

### 2. 설계 및 사용자 확인

다음을 정리해 **승인을 받은 뒤** 코드 생성에 들어간다.

- 영향 받는 모듈·파일·경로
- 데이터 흐름 (API → 상태 → UI)
- 에러 처리·로딩·빈 상태 전략
- 신규 API·스키마·상수 정의

디자인 링크가 이슈에만 있고 채팅에 없으면, **승인 직전**에 한 번 더 붙여 재확인하도록 요청할 수 있다.

> 사용자 규칙에 "승인 후 코드 생성"이 있으면 이 단계를 생략하지 않는다. AskUserQuestion은 HITL 직접 호출 경로 전용이다.

### 3. 브랜치 사전체크

구현(코드 작성)에 들어가기 **직전**에, 현재 브랜치를 확인하고 브랜치명 초안을 제안한 뒤 사용자 확인 후 적용한다.

- **이슈는 이미 SSOT로 주어짐** — 이슈 생성·연결 확인 단계는 **스킵**한다.
- **모드 `branch-only`** — 입력 이슈 번호를 브랜치명에 반영(`타입/이슈번호-슬러그`).

→ [`../feature-workflow-runner/references/branch-issue-precheck.md`](../feature-workflow-runner/references/branch-issue-precheck.md) (SSOT — 브랜치명 규칙·적용 범위 포함)

### 4. 구현

- 비즈니스 로직과 UI 분리 (훅, 유틸, Provider 등).
- 입력 검증·계약 준수.
- 로딩·에러·빈 상태 UI.
- i18n이 프로젝트에 있으면 해당 규칙에 맞게 키 추가.

### 5. 테스트 작성·검증 (조건부)

- 구현에 로직(비즈니스 로직, 상태 관리, 데이터 흐름, 계약 검증 등)이 포함됐으면 테스트 작성 필요 여부를 **AskUserQuestion 단일선택**으로 확인한다: `[작성 (권장)]` / `[생략 (사유 기록)]`. (HITL 직접 호출 경로 전용 — 비-HITL 오케스트레이션·서브에이전트 경로에선 묻지 않고 위임 계약/정책 기본값을 따른다.)
  - 규모가 작고(단순 CRUD·설정값 변경 등) 테스트 실익이 낮으면 `생략` 선택 시 사유를 기록한다.
  - 순수 UI/스타일링만 있으면 이 단계 자체를 생략한다(질문을 띄우지 않는다).
- 작성이 필요하면 **`test-writer` 에이전트에 직접 위임한다**(`devoks-sdlc:test-author` 스킬 본문을 거치지 않는다 — 그 스킬의 Phase 0은 대상 확정 질문이라 위 AskUserQuestion과 이중 질문이 된다). `target`에 이번에 구현한 파일을, `context`에 관련 에러 케이스·계약을 전달한다(위임된 `test-writer`가 자체 실행·검증까지 수행한다).
- 이 구현으로 영향받는 **기존** 테스트가 있으면 `devoks-sdlc:test-run-triage`(또는 대상 파일만 좁혀 직접 실행)로 회귀 여부를 확인한다. 영향받는 테스트가 전혀 없으면 이 항목은 생략한다.

### 6. 마무리

- 프로젝트의 린트 스크립트(예: `npm run lint`, `pnpm lint`)(Bash)로 린트 확인.
- 프로젝트의 포맷 스크립트(예: `npm run format`, `pnpm format`)(Bash)가 있으면 수정한 파일에 실행. 없으면 생략(요약에 명시).
- 미사용 import 제거.
- 구현 요약 및 남은 작업 안내(테스트를 생략했다면 그 사실과 사유를 명시).

---

## Rules (준수)

- **승인 우선**: 구현 계획 후 사용자 승인 다음 코드 생성.
- **패턴 우선**: 기존 코드 스타일·구조 유지.
- **이슈 SSOT**: 채팅만의 새 요구로 이슈 범위를 바꾸지 않는다. 범위 변경은 이슈 수정 또는 명시적 합의 후 반영.

기능 구현 시 `.claude/rules/` 및 `.claude/refs/` 디렉터리의 규칙 파일들을 참조한다. **이 스킬에 내용을 복사하지 않고 원본 파일을 직접 읽어 적용한다.**

---

## 금지·주의

- 로컬 **작업 브랜치 생성·체크아웃**은 위 Steps에 포함되며, 이와 별개로 사용자가 명시적으로 요청하지 않는 한 **`git commit` / `git push` 하지 않는다.**
- 이 스킬은 **GitHub 이슈를 생성하지 않는다** — 이슈는 이미 존재한다고 전제하며, 새 이슈 등록이 필요하면 `/devoks-git:git-create-issue`로 안내한다.
- 이슈·PR·채팅에 **토큰·비밀번호·내부 키·개인정보**를 넣지 않는다.

---

## Checklist

- [ ] 이슈 본문 로드·고정 헤더 파싱·인용 정규화
- [ ] 고정 헤더 미매칭 시 폴백 휴리스틱 적용 → 완료조건 갭(`구조 불일치`) 여부 확인
- [ ] 갭 표 작성; 차단 시 사용자 보완 후 재파싱
- [ ] UI 범위 시 디자인 참조·연결 이슈 확인
- [ ] 설계 작성 후 사용자 승인
- [ ] 구현 전 브랜치 사전체크(제안→확인→적용, 모드 `branch-only`) — `branch-issue-precheck.md`
- [ ] `.claude/CLAUDE.md` / `.claude/rules/` / `.claude/refs/` 원본 참조
- [ ] 로직 포함 시 테스트 작성 필요 여부 확인 → 필요하면 `test-author`(`test-writer`)로 위임, 생략 시 사유 명시
- [ ] 영향받는 기존 테스트 있으면 `test-run-triage`(또는 직접 실행)로 회귀 확인
- [ ] 린트·포맷 확인, 미사용 import 정리
- [ ] 구현 요약 및 추후 작업 안내

---

## 참고 기준 문서

- **이슈 파싱·갭 분석 SSOT**: `references/issue-parsing-and-gap-analysis.md`
- **브랜치 사전체크 SSOT**: `../feature-workflow-runner/references/branch-issue-precheck.md`
- **관련**: 이슈 신규 등록은 `/devoks-git:git-create-issue`, FRD/PLAN 산출물과 태스크 단위 진행 추적이 필요하면 `devoks-sdlc:feature-workflow-runner`.
