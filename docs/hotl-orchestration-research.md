# HOTL 오케스트레이션 — 조사·결정 기록 (참고용)

> 작성: 2026-11-03 · 조사 기간: 2026-10-16 ~ 10-29 · 위치: 브랜치 `experiment/hotl-orchestration-trial` 전용(main 미편입)
>
> `plugins/devoks-sdlc-orchestration-trial/`(0.3.0)을 만들고 돌려 보며 함께 조사·결정한 내용 중 **trial 코드·로드맵에 없는 것**을 남긴다.
> trial의 구조·검증 결과는 `docs/roadmap.md`의 `devoks-sdlc-orchestration` 항목 trial 절, 설계 SSOT는 trial의 `references/`를 본다.
> 외부 솔루션 정보는 조사 시점 기준이며 빠르게 바뀌므로, 재사용 전에 출처를 다시 확인한다. 2차 자료·미확인은 그대로 표기했다.

---

## 1. 결정 기록

| 날짜 | 결정 | 근거·비고 |
|---|---|---|
| 10-27 | trial은 별도 플러그인 `devoks-sdlc-orchestration-trial`, marketplace 미등록·`--plugin-dir` 전용, README·workflow-map 미갱신 | 실험 성격. 기존 sdlc 등은 설치 전제로 이름 참조, 런타임에 파일로 읽는 것만 사본 |
| 10-27 | 사람 게이트 = 게이트1(스펙 승인) + 되돌리기 어려운 작업·예외의 승인 게이트, 머지는 사람 | trial `policy.md` §2, `gate-protocol.md` |
| 10-27 | 이슈 어댑터 추상화 + GitHub 구현(local 보조, linear 슬롯) | trial `adapter-contract.md` |
| 10-27 | `dependencies`는 `devoks-sdlc`만 | 실제 런타임 의존은 sdlc 에이전트 4종뿐 |
| 10-27 | 실동작 검증 dev server는 **RUN이 자기 worktree에서 기동**(a안), Chrome·기기는 기기 전역 실동작 락 | 고정 URL은 메인 작업트리 서버를 검사하는 결함 — trial 0.3.0 |
| 10-27 | 브랜치에만 보존, 실무 적용 예정 없음. 추후 오케스트레이션·작업 스케줄링 솔루션(심포니 등)과 함께 도입 검토 | 로드맵 trial 절 "보존 방식" |
| 10-29 | Claude Tag 불필요 | §5 |
| 10-29 | 트래커는 Linear + GitHub Issues, GitHub 이슈를 Linear와 동기화 | §5 — 승인 라벨 actor 함정 확인 필요 |

정정 이력: "크로스-플러그인 에이전트 위임 resolve 확인"이라고 과장 기록했다가 정정했다. 확인된 것은 **피호출 플러그인(`devoks-sdlc`)이 이미 마켓플레이스로 설치·활성화된 상태에서** `플러그인:에이전트` 이름 호출이 동작한다는 것까지다. 마켓플레이스 설치 시 `dependencies` 자동 해석, 깨끗한 환경(CI), sdlc 비활성 시 실패 처리는 미검증이다.

---

## 2. 이슈 발생 자동 감지 — 방식 비교

현재 trial 진입점은 세션 내 `/devoks-sdlc-orchestration-trial:hotl-run issue=<n>` 또는 `scripts/hotl-headless.sh <n>`로, **누군가 실행해야 한다.**

| 안 | 방식 | 장점 | 한계 |
|---|---|---|---|
| A | GitHub Actions + `claude-code-action` (trial `assets/github-workflow-hotl.yml`) | 서버 불필요, 실시간, write 권한자만 트리거 | 호스티드 러너엔 Chrome·에뮬레이터 없음, 실행당 비용, trial은 marketplace 미등록이라 harness 체크아웃 우회 필요 |
| B | A + 셀프호스트 러너 | 하드웨어·브라우저 검증 가능 | 러너 보안 부담(공개 저장소면 특히) |
| C | 로컬 폴러(launchd/cron + `gh issue list --label hotl:run` → `hotl-headless.sh`) | trial 그대로 동작, 로컬 MCP·Chrome 사용, 인바운드 노출 없음 | 기기 상시 가동, 주기 지연 |
| D | 웹훅 수신 서버 → 큐 → 워커 | 실시간, Linear 통합, 동시성·백프레셔 제어 | 서버·큐·시크릿 운영, 로컬 기기는 공개 엔드포인트(터널) 필요 |
| E | Claude Code 예약 기능(클라우드 루틴) | 인프라 불필요 | 클라우드에서 `--plugin-dir`·로컬 Chrome 사용 가능 여부 미확인 |

트리거 설계 원칙:
- **`opened`가 아니라 사람 라벨(`hotl:run`)로 트리거**한다. 이슈 본문은 신뢰할 수 없는 입력(프롬프트 인젝션 경로)이고, 라벨 부착이 "에이전트에 맡긴다"는 의도 게이트(사실상 게이트0)다.
- `GITHUB_TOKEN`으로 일어난 이벤트는 새 워크플로를 만들지 않는다(공식 문서) → 봇 라벨로 자기 루프가 생기지 않는다.
- 같은 문서: `GITHUB_TOKEN`으로 만든 PR의 `pull_request` 워크플로는 **승인 대기 상태**로 생성된다 → 게이트2에서 사람이 CI 실행도 승인한다. 자동 실행하려면 GitHub App 토큰이 필요하다.
- 순서 권장: C(trial 리허설) → A(승격 후, 라벨 트리거) → B(하드웨어 연동 프로젝트의 실동작 검증 전용) → D(Linear 전환·실시간 필요 시). D의 큐·워커·락은 그대로 두고 수신부만 폴러↔웹훅으로 바꿀 수 있다.

---

## 3. 병렬 RUN — 웹훅 → 큐 → 워커

```
웹훅(서명 검증 X-Hub-Signature-256 · 전달 ID 중복 제거 · 사람 라벨만 · actor 권한 확인)
  → 큐(이슈 키 유니크, 상태 대기/실행/게이트대기/완료)
  → 워커 풀 N(시작 2): 각자 hotl-headless.sh <n> → .hotl/worktrees/<n>
  → 자원 락: git 관리 락 · 실동작 락(trial 0.3.0 구현) · 전역 예산
```

| # | 공유 자원 충돌 | 대응 |
|---|---|---|
| 1 | 실동작 검증이 RUN 코드가 아닌 메인 트리 서버를 검사 | **trial 0.3.0에서 해결**(worktree dev server + 실동작 락) |
| 2 | Chrome 9269·에뮬레이터·실기기 싱글턴 | 실동작 락(구현됨) 또는 RUN별 Chrome 포트·프로필 분리(MCP 설정 변경 필요) |
| 3 | worktree들이 `.git` 공유 → `worktree add`·`fetch`·ref 갱신 경합 | 워커가 git 관리 락 안에서 생성·fetch, 커밋·push 재시도 1회 |
| 4 | worktree마다 의존성 설치 | pnpm 공유 store 또는 워커 캐시 |
| 5 | 통합 테스트 포트 충돌 | 포트를 환경변수로 받게 하거나 단계 락 |
| 6 | `hotl:building` 라벨은 확인 후 부착이라 경쟁 조건 | **큐가 잠금 주인**, 라벨은 표시용 |
| 7 | local 어댑터 JSON 동시 쓰기 | 병렬에선 github 어댑터만 |
| 8 | 비용·rate limit | RUN별 상한(구현됨) + 큐의 전역 일일 예산·동시 수 |
| 9 | 원시 웹훅엔 권한 검사 없음, 로컬 자격증명 사용 | 서명·권한 확인, 전용 OS 사용자·최소 토큰, 네트워크 샌드박스 |
| 10 | 같은 파일을 고치는 RUN 간 충돌 | PR 분리 후 사람이 해결(게이트2). 의존성 순서 머지는 Bernstein 사례 참고 |

동시 에이전트 수 ≈ 워커 N × trial `limits.parallel` × (구현 1 + 리뷰 서브에이전트). N=2, parallel=1로 시작해 실측한다.

---

## 4. 유사 솔루션 조사 (2026-10-27 기준)

| 분류 | 솔루션 | 요지 | Claude Code 적합 | 확인 수준 |
|---|---|---|---|---|
| 트래커 구동 오케스트레이터 | **OpenAI Symphony** | Linear 티켓마다 workspace, 오케스트레이터 데몬이 Linear 폴링 → Codex App Server 실행 → PR. 토큰 대신 `linear_graphql` 도구로 접근 통제. Elixir 참조 구현, 재구현을 의도한 명세 | ✘ Codex 앱 서버 전제 | 2026-04-28 공개 보도, "engineering preview"(2차 자료) |
| | symphony-ts | Symphony 비공식 TS 포트, 트래커는 Linear만 확인 | ✘ app-server 런타임 필요 | 저장소 확인 |
| | Sortie | Go, 티켓→자율 세션, 트래커·에이전트 어댑터 | 미확인 | v0.0.6, 오케스트레이터 통합 진행 중 |
| | Composio Agent Orchestrator | 에이전트 10개 병렬(worktree+tmux), 각자 PR. Slack notifier(Block Kit·액션 버튼), reactions(CI 실패 재주입·정체 알림) | 미확인 | 문서 사본 간 설정 형식 상이, 저장소 소유권 이전 보도 |
| | Bernstein | 10개 병렬, worktree·PR 각각, **의존성 순서 머지** | 미확인 | 실무 회고 |
| CI 라벨 트리거 | claude-code-action | trial Actions 템플릿 기반 | ✔ 공식 | 공식 문서 검증 |
| | OpenHands Resolver | `fix-me` 라벨 → 성공 시 draft PR / 실패 시 브랜치 push → 코멘트 → 라벨 제거 | LLM은 Claude 권장 | PyPI 문서 |
| | Copilot coding agent (Jira) | Jira 할당 → draft PR, 진행·질문을 Jira에 게시 | ✘ | public preview(2026-03) |
| 트래커 내장 위임 | Linear Agents | Codex·Cursor·Devin 위임, Agents API로 자체 에이전트 | △ 자체 에이전트로 | §5 |
| 로컬 병렬 | Conductor(macOS) · Vibe Kanban · Claude Squad · Crystal 등 | worktree 격리 병렬 실행·리뷰 UI | 대체로 ✔ | Vibe Kanban 운영 종료 보도는 1차 확인 불가 |

시사점:
- Symphony는 **명세로 참고**한다(직접 도입 시 런타임 교체 필요). 재구현하면 trial = "워커가 실행하는 1 RUN", Symphony식 데몬 = §3의 큐·워커.
- 로컬 병렬 도구들은 승인 게이트·정책 가드가 약하다 — trial의 게이트 외부화·가드가 그 공백 위치.
- "이슈에서 질문·라벨 소비"는 업계 공통 패턴(Copilot·OpenHands) — trial `exception` 게이트와 같은 구조.
- 병렬의 진짜 난제는 머지(Bernstein) — §3의 10번.

---

## 5. Slack 가상 동료 · Linear + GitHub 연동 (2026-10-29)

### 5.1 조사 대상의 Slack 연동

| 솔루션 | Slack에서 일 받기 | Slack으로 알리기 |
|---|---|---|
| symphony-ts | ✘ 문서상 없음 | ✘ 문서상 없음 |
| Composio AO | ✘ 확인 못 함 | ✔ notifier |
| Linear Agents | △ `@Linear`로 스레드 → 이슈 → 에이전트 위임 | △ 동기화 스레드 |

Claude Tag(Slack `@Claude`, Team·Enterprise, 임시 클라우드 샌드박스)는 "Slack 동료"에 가장 가깝지만 **불필요로 결정**했다(10-29). 참고로 로컬 Chrome·기기 자원을 쓸 수 없다.

### 5.2 Linear ↔ GitHub Issues 동기화 (Linear 공식 문서)
- one-way(GitHub→Linear) 또는 two-way. **two-way는 저장소 1개만**, 나머지는 단방향.
- 동기화: 제목·본문·상태·**라벨**·하위 이슈·코멘트(동기화 스레드). assignee는 각자 GitHub 계정을 연결해야 한다.
- 켠 이후 **새 이슈만** 동기화(기존은 importer).
- 개인 GitHub 계정을 연결하면 동기화 활동이 본인으로 귀속, 아니면 일반 GitHub 활동으로 표시.

### 5.3 함정 — Linear에서 붙인 승인 라벨의 GitHub actor
trial은 GitHub 라벨 이벤트 actor(봇 아님·write 권한)로 승인을 검증한다(`hotl-issue.sh approval`).
- 사람이 **Linear에서** `hotl:approved`를 붙이면 GitHub엔 동기화가 붙인다. 이때 actor가 **사람인지 Linear 앱 봇인지 미확인**이다. 봇이면 trial이 정당한 승인을 거부한다(exit 4).
- Actions 경로에서 `allowed_bots`로 Linear 봇을 허용하면, 공식 문서 경고대로 **허용된 봇은 저장소 권한 검사를 받지 않아** Linear 쪽 누구나 RUN을 트리거할 수 있다.
- **확인 테스트**: 테스트 저장소에서 개인 GitHub 계정을 연결한 Linear 사용자로 라벨 1회 부착 → `gh api repos/<o>/<r>/issues/<n>/events`의 `labeled` 이벤트 actor 확인. 사람이면 B1에서도 Linear에서 승인 가능, 봇이면 "승인 라벨은 GitHub에서" 규칙 필요.

### 5.4 구성안

공통: Slack 스레드 `@Linear` → Linear 이슈 ⇄ GitHub 이슈(two-way) — 코드·브랜치·PR은 GitHub, 진행은 Linear 동기화 스레드 → Slack 스레드.

| | B1 — GitHub를 게이트 채널로 (지금) | B2 — Linear를 게이트 채널로 (승격 시) |
|---|---|---|
| 트리거 | 사람이 GitHub에서 `hotl:run` | Linear에서 자체 에이전트(예: devoks-hotl)에 위임 → `AgentSessionEvent` 웹훅 |
| 실행 | C 폴러 또는 A Actions(봇 허용 없이) | 수신 서버(**10초 내 응답**) → 큐 → 기기 워커 |
| 게이트 | GitHub 라벨(trial 그대로) | Agent Activity 확인 질문, 응답자=Linear 사용자 → GitHub 권한 매핑. `stop` 신호=중단 |
| 필요 작업 | 거의 없음(규칙 안내, actor 테스트) | trial `linear` 백엔드, 게이트 프로토콜 매핑, OAuth 앱, 웹훅 서버 |
| 위험 | Linear에서 승인 시 거부 가능(§5.3) | Agents API가 Developer Preview |

Slack 알림 보강(선택): 워커에 Slack incoming webhook으로 우선순위 이벤트(게이트 열림·상한 도달·PR 생성)만 전송 — Composio AO notifier 패턴 참고.

---

## 6. 다음 행동

1. §5.3 actor 확인 테스트(테스트 저장소, 1회).
2. B1 + C 폴러로 운영 리허설 — 폴러 스크립트(`scripts/hotl-poll.sh` + launchd plist)는 아직 없다.
3. trial 미검증 항목: `action` 게이트 승인 후 resume, `exception` 게이트, worktree 병렬, GitHub 어댑터·Actions 실행, 실제 웹앱 실동작 검증, 마켓플레이스 설치 시 의존성 해석.
4. 심포니 연계 검토 시: Symphony 명세 → Linear Agents 위임 웹훅 + §3 큐·워커 + trial RUN으로 B2 설계.
5. HITL 대비 얇은 검증 보강 후보: 테스트 실패 분류(`test-run-triage` 기준) → 요구 충실도 판정(`verify-requirements` 기준).

---

## 출처

- claude-code-action: [usage.md](https://raw.githubusercontent.com/anthropics/claude-code-action/main/docs/usage.md) · [security.md](https://raw.githubusercontent.com/anthropics/claude-code-action/main/docs/security.md) · [migration-guide.md](https://raw.githubusercontent.com/anthropics/claude-code-action/main/docs/migration-guide.md)
- GitHub: [GITHUB_TOKEN](https://docs.github.com/en/actions/concepts/security/github_token)
- Symphony: [noqta](https://www.noqta.tn/en/news/openai-symphony-codex-autonomous-orchestrator-linear-2026) · [Daniel Vaughan](https://codex.danielvaughan.com/2026/04/28/openai-symphony-codex-orchestration-linear-autonomous-agent-workflows/) · [Better Stack](https://betterstack.com/community/guides/ai/openai-symphony/) · [letsdatascience](https://letsdatascience.com/news/openai-releases-symphony-project-management-spec-for-coding-21c19085) · [symphony-ts](https://github.com/OasAIStudio/symphony-ts)
- 오케스트레이터: [Sortie](https://pkg.go.dev/github.com/sortie-ai/sortie@v0.0.6) · [Composio AO workflows](https://www.mintlify.com/ComposioHQ/agent-orchestrator/concepts/workflows) · [Composio AO Slack notifier](https://www.mintlify.com/ComposioHQ/agent-orchestrator/plugins/notifier/slack) · [Composio AO reactions](https://www.mintlify.com/ComposioHQ/agent-orchestrator/configuration/reactions) · [Ry Walker 리뷰](https://rywalker.com/research/agent-orchestrator) · [Bernstein](https://bernstein.readthedocs.io/en/latest/blog/ten-agents-one-release/) · [Augment 정리](https://www.augmentcode.com/tools/open-source-agent-orchestrators)
- CI·트래커 위임: [OpenHands Resolver](https://pypi.org/project/openhands-resolver/0.3.1) · [Copilot coding agent for Jira](https://github.blog/changelog/2026-03-05-github-copilot-coding-agent-for-jira-is-now-in-public-preview/)
- Linear: [GitHub 통합·Issues Sync](https://linear.app/docs/github) · [Slack agent](https://linear.app/changelog/2025-10-23-linear-agent-for-slack) · [Slack docs](https://linear.app/docs/slack.md) · [Agents](https://linear.app/agents) · [Agents API](https://linear.app/developers/agents) · [Agent interaction](https://linear.app/developers/agent-interaction) · [Hookdeck 가이드](https://hookdeck.com/webhooks/platforms/how-to-build-linear-agents-with-hookdeck-cli)
- 로컬 병렬: [Conductor](https://korben.info/en/conductor-run-ai-agents-parallel-codebase.html) · [Vibe Kanban](https://virtuslab.com/blog/ai/vibe-kanban/)
- Claude: [Claude Tag](https://claude.com/docs/claude-tag/overview) · [Claude Code in Slack](https://code.claude.com/docs/en/slack)
