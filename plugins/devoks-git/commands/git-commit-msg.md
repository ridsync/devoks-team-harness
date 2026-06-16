---
description: Conventional Commits 규칙에 따라 git commit 메시지를 작성하고 커밋한다.
---

# Git Create Commit (Conventional Commits)

## SSOT

- 커밋 메시지·타입·스코프·브랜치 권장: [`.claude/refs/git-convention.md`](../refs/git-convention.md)를 따른다.
- 타입 선택이 애매하면 위 파일의 **타입별 권장 매핑**을 먼저 적용한다.

## Overview

Staged 변경을 검토한 뒤, SSOT에 맞는 커밋 메시지를 작성하고, 반드시 사용자에게 커밋 메시지를 확인받은 후 커밋한다.

## Steps

1. **변경 검토**
   - `git diff --cached`(staged) 또는 `git diff`(unstaged)로 실제 변경 확인
   - 무엇이 어떻게 바뀌었는지 파악
2. **이슈 키 확인 (선택)**
   - 브랜치명 등에서 이슈 키(Linear, Jira, GitHub #123 등)가 있으면 활용
   - 사용자에게 관련된 이슈/PR 넘버 포함 여부를 물어본다
3. **스테이징 된 파일만 대상**
4. **커밋 메시지 작성 및 커밋**
   - 제목·타입·스코프·breaking은 SSOT의 **커밋 형식**과 **Scope** 절, **타입별 권장 매핑**을 따른다.
   - `git commit -m "타입(스코프): 설명"` 또는 본문이 있으면 `-m "제목" -m "본문"` 형태로 실행
   - 커밋 수행하기 전에 사용자에게 커밋 내용 확인을 받고 커밋 수행
   - 커밋 시 에러가 발생하면 에러에 대한 리포트만 하고 자동으로 수정하지 않는다

## 이 커맨드 전용 규칙 (SSOT에 없는 실행 절차)

- **본문**:
  - 필요 시 제목 다음 빈 줄 뒤, 불릿(`-`)으로 상세 나열.
  - 본문 변경 상세 내역이 5줄 이하로 작성하되, 변경사항이 많은경우 그중에 중요한 변경사항들 위주로만 기재. 
  - 변경에 따른 결과·효과를 기재.
- **Footer (이 커맨드)**:
  - 이슈 번호가 있으면(선택) `Resolved #이슈번호` 등으로 연결.
  - 이 커밋을 진행한 Agent 정보를 `by {$AgentName} AI Agent 🤖` 형식으로 기재한다(필수). `{$AgentName}`은 실제 에이전트 이름(예: Cursor)으로 치환.
- **제목 길이**: 가독을 위해 **100자 이내 권장** (SSOT은 길이를 고정하지 않음).

## 예시 (형식 참고 — 상세 타입 설명은 SSOT)

```
chore(naming): React 컴포넌트 네이밍 컨벤션 적용

페이지 컴포넌트 파일명을 소문자에서 PascalCase로 변경하여
React 컴포넌트 네이밍 컨벤션을 준수하도록 통일.

- 레이아웃(라우트,아웃렛 포함) 컴포넌트: *Layout.jsx
- 페이지 컴포넌트: *Page.jsx
- 라우트 컴포넌트: *Route.jsx

관련 import 경로 및 참조 업데이트 포함하여 수정.

Resolved #1234
by Neo Agent (Claude Code) 🤖
```

- 참고: [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)
