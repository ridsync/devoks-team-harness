---
name: hotl-setup
description: "[trial] 대상 프로젝트에 HOTL RUN 실행 환경을 1회 구성한다 — .hotl/config.json(어댑터·기본 브랜치·게이트·검증 명령·한도) 생성, .hotl/.gitignore, (선택) GitHub Actions 워크플로 초안, (선택) 게이트 라벨 생성, 사람이 해야 할 저장소 설정 안내. 생성 후 파일은 프로젝트가 소유한다. 트리거: hotl setup, HOTL 환경 구성, HOTL 셋업, hotl 설정 만들어줘. RUN 실행은 devoks-sdlc-orchestration-trial:hotl-run 을 쓴다."
---

# hotl-setup — HOTL 프로젝트 셋업 (trial 0.3.0)

대상 프로젝트에 `hotl-run`이 읽는 설정과 (선택) CI 트리거를 만든다. **사용자가 직접 호출하는 HITL 스킬**이다 —
비-HITL RUN 안에서는 호출하지 않는다(`hotl-run` 절대 규칙 2). 생성물은 1회 생성 후 프로젝트 소유이며, 플러그인이 자동으로 다시 쓰지 않는다.

## Phase 0 — 현황 점검 (읽기 전용)

1. git 저장소 루트·기본 브랜치(`git symbolic-ref refs/remotes/origin/HEAD` → 실패 시 현재 브랜치)·`gh auth status`·`jq` 설치를 확인한다.
2. 기존 `.hotl/config.json`, `.github/workflows/hotl.yml`이 있으면 **덮어쓰지 않는다** — 차이만 보여 주고 갱신 여부를 묻는다.
3. 검증 명령 후보를 감지한다: `package.json` scripts(`lint`·`typecheck`·`test`·`build` — 패키지 매니저는 lockfile로 판정, 테스트는 watch가 아닌 1회 실행 형태로), `pyproject.toml`/`Makefile` 등. **감지된 것만** 후보로 낸다(추측 금지).
4. 웹앱 여부를 판정한다: `.claude/project-convention.json`의 `preset`이 `react-native`·`android`·`ios`가 아니고, dev server 스크립트(`dev`·`start` 등)가 있으면 웹앱 후보. dev server 기동 명령은 **포트를 인자로 받는 형태**로 후보를 만든다 — 번들러가 확인될 때만(예: Vite `npm run dev -- --port {port} --strictPort`, Next `npm run dev -- -p {port}`, `PORT` 환경변수를 읽는 서버면 `npm start`). 확인되지 않으면 후보 없이 자유 입력으로 받는다. 영속 저장 방식(localStorage·IndexedDB·서버 API)은 코드에서 확인된 것만 후보로 낸다.

## Phase 1 — 슬롯 확인 (AskUserQuestion, 한 번에)

명확한 기본값이 있으면 묻지 않고 한 줄로 알린다. 아래만 묻는다(최대 4개):

| 슬롯 | 기본값 | 비고 |
|---|---|---|
| 어댑터 | `github`(gh 인증 시) / `local`(그 외) | `local`은 오프라인 실험용 |
| 게이트1(스펙 승인) | 켬 | 끄면 spec 후 바로 build — FRD §10 질문이 있으면 그래도 정지 |
| 검증 명령 | Phase 0 감지 목록 | 순서 = lint → typecheck → test → build |
| GitHub Actions 워크플로 생성 | 생성 안 함 | 생성 시 harness 저장소(`owner/repo`)를 자유 입력으로 받는다 |

**웹앱 후보일 때만** 두 번째 질문 묶음으로 실동작 검증 슬롯을 확인한다(웹앱이 아니면 `acceptance.enabled=false`로 두고 한 줄 알림):

| 슬롯 | 기본값 | 비고 |
|---|---|---|
| 실동작 검증 사용 | 사용 안 함 | 켜면 spec 단계가 시나리오 표를 만들고 verify에서 `acceptance-test-runner`를 돌린다(`references/acceptance-scenarios.md`) |
| dev server 기동 명령 | Phase 0 후보 | `{port}` 자리표시자 포함 — RUN이 실동작 단계에서만 자기 worktree에 이 명령으로 띄우고 끈다(`scripts/hotl-devserver.sh`). 사람이 미리 띄울 필요 없음 |
| 영속 조회 방법 | Phase 0 감지 후보 | 자유 입력(예: `localStorage evaluate_script`) — 비우면 영속 대조가 필요한 시나리오는 flag로 빠진다 |

## Phase 2 — 생성

1. `.hotl/config.json` — `${CLAUDE_PLUGIN_ROOT}/assets/hotl.config.template.json`에 슬롯 값을 채운다.
2. `.hotl/.gitignore` — 아래 항목(실행 잔재·로컬 승인 저장소·worktree·CI 체크아웃은 커밋하지 않는다. `runs/`와 `config.json`은 커밋한다):
   ```
   ACTIVE
   local/
   worktrees/
   logs/
   harness/
   devserver/
   ```
3. (선택) `.github/workflows/hotl.yml` — `${CLAUDE_PLUGIN_ROOT}/assets/github-workflow-hotl.yml`의 `{{HARNESS_REPO}}`·`{{MAX_TURNS}}`를 치환한다.
4. (선택, github 어댑터) 게이트 라벨 생성 — 저장소에 쓰는 외부 부작용이므로 **실행 전에 확인**을 받고 `bash ${CLAUDE_PLUGIN_ROOT}/scripts/hotl-issue.sh ensure-labels`.

커밋·push는 하지 않는다. 생성 파일 목록과 다음 단계를 출력한다.

## Phase 3 — 사람이 해야 할 일 안내 (실행하지 않음)

- 기본 브랜치 보호: 직접 push 금지, PR 리뷰 필수(RUN의 진짜 경계).
- (CI) 저장소 secret `ANTHROPIC_API_KEY`, Actions의 PR 생성 권한(Settings → Actions → Workflow permissions).
- (실동작 검증을 켰다면) RUN 전에 Chrome(`--remote-debugging-port=9269`)을 띄우고 chrome-devtools-attach MCP를 user scope에 등록(`/devoks-core:setup-mcp` Step 6). dev server는 RUN이 띄운다. 둘 중 하나라도 없으면 RUN은 실패하지 않고 "실동작 검증 필요" flag만 남긴다. 여러 RUN이 같은 기기에서 돌면 실동작 단계는 락으로 한 번에 하나씩 진행된다.
- 네트워크 차단 샌드박스는 이 플러그인이 제공하지 않는다 — 로컬 무인 실행 시 러너/컨테이너 쪽에서 구성.
- 첫 실행 권장: `local` 어댑터로 리허설 → `hotl-issue.sh local-new` → `hotl-headless.sh <n> spec`.

## 관련

- RUN 실행: `devoks-sdlc-orchestration-trial:hotl-run`
- devoks 기본 셋업(규칙·MCP): `devoks-core:setup-project-convention`, `devoks-core:setup-mcp` — 이 스킬은 그 산출물을 건드리지 않는다.
