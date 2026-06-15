---
description: 현재 브랜치 기준 PR 본문을 작성하고 gh CLI로 PR을 생성한다.
---

# Git Pull Request (브랜치 → GitHub PR)

## Overview

현재 브랜치의 변경사항을 기준으로 PR 본문을 작성한 뒤, **휴먼 개발자가 검토**하고, 검토 완료 후 **원격에 head 브랜치를 푸시**한 다음 **`gh` CLI**로 PR을 생성하고, **Assignees·Reviewers**를 규칙에 따라 설정한다.

## 주요 파라미터

| 파라미터 | 설명 | 예시 |
|----------|------|------|
| **이슈 번호** | 연결할 GitHub 이슈/이슈 번호. Reference 섹션에 반영 | `42`, `#42` |
| **스크린샷 URL** | PR 본문의 Screenshots 섹션에 넣을 이미지 URL (여러 개 가능) | `https://example.com/screen1.png` |

- 파라미터는 사용자가 명시할 때만 사용한다. 없으면 해당 섹션은 비우거나 "(Optional)" 안내만 유지한다.
- 이슈 번호는 필수로 요청한다.
- 스크린샷은 옵셔널로 처리한다.

## Steps

### 1. PR 본문 초안 작성

1. **현재 브랜치 및 base 확인**
   - `git branch --show-current` 로 현재 브랜치
   - base는 보통 `main` 또는 `develop` (없으면 사용자에게 확인)
2. **변경 범위 파악**
   - `git diff <base>...HEAD --name-only` 로 변경 파일 목록
   - `git log <base>..HEAD --oneline` 로 커밋 요약
   - 변경된 파일 내용을 읽어 기능·영향 범위 파악
3. **PR 템플릿 채우기**
   - [.github/PULL_REQUEST_TEMPLATE.md](.github/PULL_REQUEST_TEMPLATE.md) 구조를 따른다.
   - **Short description**: 한두 문장 요약 (코드 변경 상유 및 배경에 대해서 기재 : 필요시 사용자에게 요청)
   - **Proposed changes**: 변경 사항 불릿 나열 (커밋내역 참고, 주요 기능 단위, 간략하게 요약)
   - **Screenshots (Optional)**:
     - 사용자가 **스크린샷 URL**을 제공한 경우: `![설명](URL)` 형태로 링크 추가
     - 여러 URL이면 각각 한 줄씩 나열
     - 없으면 "(없음)" 또는 해당 섹션 생략
   - **What areas of code or functionality does it impact?**: 영향 받는 코드/기능 영역에대한 설명. 그리고, 이 수정사항에 따른 코드품질 측면의 효과가 있다면 설명
   - **How Has This Been Tested?**: 
     - 테스트 항목 : 유저 시나리오 기준
        1. 핵심 기능 동작 확인 (Functional Validation)
        2. 코드 수정 변경사항을 확인하는 회귀테스트 (Regression Testing)
        3. 추가/수정사항에 따른 에지케이스 테스트 또는 부가적으로 필요한 테스트 (Edge Case Testing) **(Optional)**
     - 출력 형식 : 테스트 항목 별 각각 체크리스트 형식으로 테스트 세부사항들을 모두 나열한다.
   - **Reference (Optional)**:
     - 사용자가 **이슈 번호**를 제공한 경우: `_Resolves #번호_` 또는 `_Closes #번호_`, `_Refs #번호_` 중 적절한 것 사용
     - 없으면 `_Resolves #issue-number_` 플레이스홀더만 두거나 생략

### 2. 휴먼 검토

1. 작성한 **PR 본문 전체**를 사용자에게 보여준다.
2. 사용자에게 다음을 확인받는다.
   - 본문 내용 수정·추가 요청이 있는지
   - 이슈 번호/스크린샷 URL 등 파라미터 보정이 필요한지
   - **PR 생성 진행 여부** (진행해도 되는지)
3. 수정 요청이 있으면 본문을 갱신한 뒤 다시 검토 요청한다.
4. **사용자가 "PR 생성해도 된다"고 승인할 때까지** PR을 생성하지 않는다.

### 3. 원격 브랜치 푸시 (PR `head` 준비)

사용자 검토 및 승인 후, **PR 생성 전에** 반드시 수행한다. `gh pr create`의 `--head`는 **원격(`origin`)에 존재하는 브랜치 이름**이어야 한다.

1. **현재 브랜치명 확인** — `git branch --show-current` (아래에서 `<current>`로 표기).
2. **원격에 동일 이름 브랜치가 있는지 확인** — 예: `git ls-remote origin refs/heads/<current>`  
   - 출력이 비어 있으면 아직 푸시되지 않은 브랜치다.
3. **푸시**
   - 최초 푸시 또는 upstream 미설정: `git push --set-upstream origin <current>`
   - 이미 추적 중이고 로컬에만 추가 커밋이 있으면: `git push`
4. **실패 시** — 인증·권한·충돌 등으로 푸시가 실패하면 PR을 만들지 말고, 에러만 사용자에게 전달한다.

### 4. `gh` CLI로 PR 생성

원격 푸시(3단계)까지 성공한 뒤에만 수행한다.

1. **저장소 정보 확인**
   - 원격 저장소 `owner`/`repo` 확인 (예: `git remote get-url origin`으로 파싱하거나 사용자에게 확인)
   - `--head` = 현재 작업 브랜치명(원격에 방금 푸시한 이름과 동일), `--base` = 병합 대상(보통 `main` 또는 `develop`)

2. **PR 생성**
   - `gh pr create --title "제목" --body "본문" --base <base> --head <head>` 사용
   - `--body`: 1단계에서 확정한 PR 본문(마크다운) 전체
   - 선택: `--draft` (드래프트 PR 원할 때)
3. **결과 안내**
   - 생성된 PR 번호·URL을 사용자에게 알려준다. 다음 **5단계(담당·리뷰어)**에서 PR 번호가 필요하다.

### 5. Assignees 및 Reviewers 자동 할당

PR 생성 직후, 아래 순서로 담당자·리뷰 요청을 맞춘다. `gh pr edit`로 Assignees·Reviewers를 설정한다.

1. **`.github/CODEOWNERS` 존재 여부 확인** — 저장소 루트 또는 [.github/CODEOWNERS](.github/CODEOWNERS) 경로. `Read` 등으로 내용을 읽을 수 있는지 확인한다.

2. **분기: CODEOWNERS가 있는 경우**
   - **CODEOWNERS 파일을 읽고**, 1단계에서 확정한 **변경 파일 경로**(`git diff <base>...HEAD --name-only`)와 규칙을 대조한다.
   - GitHub CODEOWNERS 규칙에 따라 해당 경로의 **소유자(사용자 `@login` 또는 팀)** 를 **Reviewers** 후보로 정한다.
   - `gh pr edit <번호> --add-reviewer <login>` 으로 Reviewers를 설정한다. (팀 리뷰 `@org/team`은 API·권한에 따라 별도 처리가 필요할 수 있음.)
   - **Assignees**는 CODEOWNERS만으로 고정되지 않는다. 팀에서 담당 이슈 연계 규칙이 있으면 따르고, 없으면 아래 **CODEOWNERS 없음**과 동일하게 **현재 인증 사용자**를 Assignee로 두는 것을 기본으로 한다.

3. **분기: CODEOWNERS가 없는 경우**
   - **Assignees**: `gh api user`로 인증된 사용자의 **login**을 구한 뒤, `gh pr edit <번호> --add-assignee <login>`으로 PR **Assignee**로 할당한다.
   - **Reviewers**: **미할당** — 자동 리뷰 요청을 하지 않는다.

4. **실패 시** — 권한·팀 멤버십·API 제한으로 할당이 실패하면 사용자에게만 알리고, PR 자체는 이미 생성된 상태이므로 URL을 안내한다.

## PR 본문 작성 시 참고

- **템플릿 경로**: [.github/PULL_REQUEST_TEMPLATE.md](.github/PULL_REQUEST_TEMPLATE.md)
- **프로젝트 규칙**: `.claude/refs/` — `engineering-principles.md`, `code-review.md`, `git-convention.md`, `workflow.md` / `.claude/rules/` — `agent-principles.md`, `project-convention.md` — 영향 영역·테스트 항목 정리 시 참고 (필요 시 `.claude/CLAUDE.md` 참고)

## 요약

| 단계 | 담당 | 비고 |
|------|------|------|
| 1. PR 본문 초안 | AI | 템플릿 + 선택 파라미터(이슈 번호, 스크린샷 URL) 반영 |
| 2. 검토 및 승인 | 휴먼 | 수정 요청 시 본문 갱신 후 재검토 |
| 3. 원격 브랜치 푸시 | AI | `head`가 `origin`에 있어야 PR 생성 가능; 실패 시 PR 생성 안 함 |
| 4. PR 생성 | AI (gh CLI) | 2·3단계 완료 후에만 `gh pr create` 실행 |
| 5. Assignees / Reviewers | AI | CODEOWNERS 있으면 파일·변경 경로 기준 Reviewers; 없으면 Assignees=`gh api user` login, Reviewers 미할당 |
