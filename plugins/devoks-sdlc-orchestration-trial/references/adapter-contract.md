# 이슈 어댑터 계약

RUN은 이슈 시스템을 직접 부르지 않고 `${CLAUDE_PLUGIN_ROOT}/scripts/hotl-issue.sh`만 호출한다. 이슈 시스템을 바꾸려면
이 스크립트에 백엔드를 추가하면 되고, 스킬·파이프라인 문서는 바뀌지 않는다.

- 백엔드 선택: `HOTL_ADAPTER` 환경변수 > `.hotl/config.json`의 `adapter` > 기본 `github`.
- 구현된 백엔드: `github`(gh CLI), `local`(`.hotl/local/` 파일 — 오프라인 스모크·실험용).
- 미구현 슬롯: `linear` — 기존 설계 D4의 목표 트리거. 호출 시 "not implemented"로 실패한다(조용한 폴백 금지).

## 명령

| 명령 | 출력 / 종료코드 | 비고 |
|---|---|---|
| `whoami` | 봇 로그인 1줄 | github: `gh api user`, local: `hotl-bot` |
| `fetch <issue>` | JSON `{number,title,body,url,labels[]}` | `<issue>`는 번호 또는 URL |
| `comments <issue> [--after ISO]` | JSON 배열 `{author,body,created_at}` | spec-revise 피드백·exception 결정 읽기 |
| `comment <issue> <body-file>` | 코멘트 URL(또는 id) | 본문은 파일로 넘긴다(셸 이스케이프 사고 방지) |
| `label-add <issue> <label>` | 0 | **사람 전용 라벨이면 exit 5로 거부** |
| `label-rm <issue> <label>` | 0 | 없으면 무시 |
| `approval <issue> <label> [--after ISO]` | 0 + JSON `{actor,at,permission}` / 3 없음 / 4 actor 부적격 | `gate-protocol.md` 승인 검증 |
| `pr-draft <head> <base> <title> <body-file>` | PR URL | github: `gh pr create --draft`. 기존 PR이 있으면 그 URL |
| `ensure-labels` | 0 | setup 전용 — 게이트 라벨 생성 |
| `approve <issue> <label>` | 0 | **local 전용, 사람이 터미널에서 직접** — 승인 이벤트를 `$USER`로 기록. RUN은 호출 금지(훅 차단) |

종료코드 공통: 0 성공, 2 사용법 오류, 5 정책 거부, 6 백엔드 오류(gh 미인증 등), 7 미구현 백엔드.

## 백엔드별 주의

- **github**: `gh auth status`가 통과해야 한다. 승인 검증은 `issues/<n>/events`의 `labeled` 이벤트 actor와
  `collaborators/<actor>/permission`을 조회한다. CI(`claude-code-action`)에서는 봇이 `github-actions[bot]` 또는 App 봇이다.
- **local**: `.hotl/local/issues/<n>.json`에 이슈·라벨·이벤트·코멘트를 저장한다. 이슈는 `scripts/hotl-issue.sh local-new <title> <body-file>`로 만든다.
  권한 개념이 없어 승인 검증은 "actor ≠ 봇"까지만 한다. 실험·스모크 전용이며 팀 운영 경로가 아니다.
