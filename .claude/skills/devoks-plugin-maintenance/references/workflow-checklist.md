# Workflow checklist

`devoks-plugin-maintenance`가 상세 점검 시 참고하는 매트릭스다.

## 1. 변경 유형별 기본 확인

| 변경 유형 | 기본 확인 | 추가 확인 |
|---|---|---|
| runtime behavior only | 대상 플러그인 식별, `plugin.json` version bump 여부, `validate --strict` | 사용자-facing 설명 변경이 있으면 README/README.ko 검토 |
| public workflow change | version bump, `validate --strict`, 관련 skill/command 문서 | `docs/plugin-management.md`, README/README.ko |
| docs-only | 실제 코드/동작 불변인지 확인 | plugin version bump 비대상 사유 기록 |
| MCP/prefix/policy change | `mcpServers`, `permissions.allow`, prefix, setup 문서 | `docs/mcp-setup-guide.md`, `setup-mcp.md`, `check-setup-state.sh` |
| naming/catalog change | 이름/description/dependency 변경 반영 | README, README.ko, marketplace, 다른 SKILL 참조 |
| core refs/rules change | 루트 `.claude/` 사본과 explicit setup/sync 정책 확인 | `docs/fix-plan-sync-context-ssot.md`, 관련 운영 문서 |

## 2. 문서 대상 판단표

| 파일 | 언제 검토하나 |
|---|---|
| `README.md` | 플러그인/skill/command 설명, 설치/업데이트 흐름, 사용자-facing 요약이 바뀔 때 |
| `docs/README.ko.md` | README와 동일한 정보의 한국어 카탈로그가 영향을 받을 때 |
| `docs/plugin-management.md` | 플러그인 생성/검증/배포/유지보수 절차 자체가 바뀔 때 |
| `docs/mcp-setup-guide.md` | MCP 서버 설치 방식, prefix, 정책 설명이 바뀔 때 |
| `plugins/devoks-core/commands/setup-mcp.md` | setup 절차, 예시 명령, 서버별 설치 안내가 바뀔 때 |
| `.claude-plugin/marketplace.json` | 신규 플러그인 추가, description/dependencies/source 관련 정보가 바뀔 때 |
| `docs/ROADMAP.md` | 반복 drift 문제를 후속 개선 과제로 명시해야 할 때 (열린 항목만 — 끝낸 항목은 지운다) |
| `docs/CHANGELOG.md` | **모든 플러그인 변경·로드맵 항목 완료·폐기 결정** — 배경·반영·검증·의도적 미반영. devoks-core는 요약만(상세는 core CHANGELOG) |

## 3. MCP / prefix / permission 점검 포인트

### plugin 설치형 prefix
- `mcp__plugin_<plugin>_<server>__*`
- 플러그인 번들에 의해 제공되는 tool 명칭

### 일반 MCP 등록형 prefix
- `mcp__<server>__*`
- `claude mcp add` 또는 별도 설치로 제공되는 tool 명칭

### 대조 지점
- `plugins/<plugin>/.claude-plugin/plugin.json`
- 관련 SKILL.md / agent 문서
- `docs/mcp-setup-guide.md`
- `plugins/devoks-core/commands/setup-mcp.md`
- `plugins/devoks-core/hooks/check-setup-state.sh`

### 에이전트 `tools:` 화이트리스트 대조 (prefix 점검과 별개)

agent frontmatter의 `tools:`는 **화이트리스트**다 — 거기 없는 도구 호출은 에이전트 안에서 전부
차단되고, 문서에 지시가 남아 있어도 **에러 없이 그냥 실행되지 않는다**. `permissions.allow`가
커버하더라도 화이트리스트에 없으면 무의미하다(두 메커니즘이 별개).

에이전트를 추가·수정할 때 **호출 지시가 있는 모든 곳**을 `tools:`와 대조한다:

- [ ] 에이전트가 읽도록 지시된 `references/*.md`·SKILL.md의 도구 호출
- [ ] **에이전트 본문에 직접 박힌 도구 호출** ← 여기가 두 번 빠져나갔다
- [ ] `tools:`에 MCP 와일드카드(`mcp__<server>__*`)가 필요한지

**실제 사고 2건:**
- 2026-07-29 `acceptance-test-runner` — `tools:`에 MCP가 없어 `references`가 지시하는
  `mcp__chrome-devtools-attach__*` 호출이 전부 차단, 스킬 Phase 1~4 전체가 동작 불가였다.
  형제 에이전트에서 같은 결함을 이미 고쳤는데 먼저 추가된 이쪽에 적용되지 않았다.
- 2026-09-18 `code-security-reviewer` — `tools: Read, Grep, Glob, Bash`인데 **에이전트 본문**이
  `ctx_batch_execute`/`ctx_execute`를 지시하고 있었다(죽은 코드). 1차 사고 후 재발 방지를
  "reference와 frontmatter 대조"로만 적어둬서, 본문에 직접 박힌 경우가 빠져나갔다.

## 4. 특수 케이스

### 진입점 정책 (command vs skill) — 확정 SSOT, 2026-08-24

새 진입점을 만들거나 기존 진입점을 옮길 때 **이 기준으로만 판단한다.** 논의를 다시 열지 않는다.

> **진입점은 스킬을 기본으로 한다.** 커맨드는 아래 둘 중 **하나 이상**에 해당할 때만 남긴다.
> 1. **저장소 밖으로 나가는 write 부작용**이 있다(git push, GitHub 이슈·PR 생성 등) — 스킬 auto-trigger 오발동 비용이 비대칭적으로 크다.
> 2. **승인 게이트가 절차의 본질**이다(`docs/plugin-management.md` §12 기준 2).
>
> 스킬 진입 대상은 **읽기 전용 리포트** 또는 **저장소 내 산출물**만 만들고, 범위 확정이 단계별 승인이 아니라 **Phase 0 1회 슬롯 확인**으로 끝나는 작업이다.

판정 결과(현 인벤토리):

| 대상 | 판정 | 근거 |
|---|---|---|
| `devoks-git` 3개 커맨드 | 커맨드 유지 | 조건 1+2 — 2026-08-21 확정(아래 §devoks-git) |
| `code-review`·`code-security-review`·`test-author` | **스킬**(2026-08-24 이전 완료) | 읽기 전용 리포트 / 저장소 내 테스트 파일만 생성 |
| `code-analyze-module`·`code-refactoring`·`new-feature-by-github-issue` | **스킬**(2026-09-02 이전 완료) | 부작용 없음. `new-feature-by-github-issue`는 애초에 조건 1(이슈 생성)이 적용되지 않았음이 밝혀짐 — 실제 동작은 기존 이슈를 읽기만 하고 생성하지 않음(로드맵의 낡은 근거 정정). `devoks-sdlc`에 커맨드가 0개가 됨 |

**스킬 진입 이전 시 체크(누락하면 조용히 깨진다):**
- 자연어 트리거 문구를 **agent `description` → 진입 skill `description`으로 이관**했는가. 양쪽에 두면 Phase 0 우회, 어디에도 없으면 라우팅 실패.
- 엔진 절차·리포트 템플릿을 `references/`로 내렸는가(진입 SKILL.md는 트리거마다 메인 루프에 로드된다 — 대용량 템플릿을 본문에 두면 agent 격리 이득이 상쇄된다).
- 진입 skill의 Phase 0(사용자 질문)과 호출자 측 질문이 **이중 질문**이 되지 않는가. 다른 스킬에서 재사용할 때는 skill 본문이 아니라 **agent에 직접 위임**한다(`new-ui-draft` step 7 참고).
- 구 커맨드를 참조하던 지점 전부(카탈로그 양 언어·`workflow-map`·`post-implementation-checklist`·다른 skill의 frontmatter `description`·`evals/evals.json` 기대 문구)를 갱신했는가.


### devoks-browser
- `chrome-devtools-attach` 명칭 유지 여부
- `settings.permissions.allow` prefix
- browser visual diff / browser devtools 관련 설명

### devoks-rn
- `metro-devtools` 관련 allow prefix
- Metro URL / setup 흐름 설명
- RN 전용 optional 성격 설명

### devoks-core
- `rules/`, `refs/`, hook 변경 시 루트 `.claude/` 사본과 관계
- `check-setup-state.sh`, explicit setup/sync 정책 문서와 설명 일치 여부
- **`CHANGELOG.md` 기재(version bump 시 필수)** — `plugins/devoks-core/CHANGELOG.md`에 새 버전 절을 추가한다. 복사 산출물(base 7종·스택 한정 refs·preset·`assets/`)이 바뀌었으면 `파일 › 섹션: 추가/변경/삭제 — 사유`를 **빠짐없이** 적는다 — 설치 프로젝트의 `setup-preset-manage`가 이 기록을 근거로 upstream 변경과 로컬 커스터마이징을 구분하므로, 누락은 곧 잘못된 병합 판단이 된다. 프로젝트 환경에 따라 거부해도 되는 변경은 그렇다고 명시한다. 스킬·커맨드·훅은 사용법이 바뀐 경우만 적는다
- **setup 산출물 등록** — 플러그인 밖(대상 프로젝트 `.claude/`, `~/.devoks/` 등)으로 파일을 복사하는 변경(어느 플러그인이든)은 `skills/setup-preset-manage/SKILL.md` Overview 표 + 갱신 절차와 `check-setup-state.sh` stale 감지에 함께 등록한다. 미등록 산출물은 플러그인 업데이트 후 조용히 옛 버전으로 남는다(2026-10-19 base rules 미반영 사례). 복사 대상은 번들 원본과 바이트 동일하게 유지한다(사용자별 값은 별도 파일로 — `chrome-debug.url` 패턴)

### devoks-sdlc
- 구 devoks-code/devoks-feature/devoks-test/devoks-verify 통합체 — skill·command·agent 수가 5개 플러그인 중 가장 많아 변경 영향 범위가 가장 넓다(정확한 개수는 하드코딩하지 않는다 — 드리프트하므로 `ls skills/*/ commands/*.md agents/*.md`로 확인)
- **agent-internal 경계 (2026-08-24 단순화, 2026-09-02 agent 1개 추가)** — `devoks-sdlc`의 **모든 agent가 agent-internal**이고, **agent-internal skill은 없다**. 커맨드도 0개다(2026-09-02, `code-analyze-module`·`code-refactoring`·`new-feature-by-github-issue` 스킬 이전 완료로 `commands/` 디렉터리 자체가 사라짐):
  - agent-internal **agent** (전부): `code-reviewer`, `code-security-reviewer`, `test-writer`, `code-implementer`, `acceptance-test-runner`, `code-analyzer` — 호출 스킬의 특정 Phase에서만 위임받는다.
  - **직접 트리거 가능한 agent: 없음.** 사용자 진입은 전부 스킬이다(진입점 정책 참고). 자연어 트리거 문구는 **진입 스킬의 `description`이 소유**하며 agent `description`에 중복해 두지 않는다 — 두면 스킬 Phase 0(범위 확정)을 건너뛰고 agent로 직행하는 우회 경로가 생긴다(2026-08-24 이전 구조의 실제 결함).
  - 예외: `devoks-sdlc-orchestration`은 이 agent들을 **이름으로 직접 위임**한다(`references/pipeline.md`). `직접 호출 금지` 마킹은 사용자용 소프트 가드일 뿐이므로 정책 충돌이 아니다 — 대신 **각 agent의 입력 파라미터 표를 자기완결 상태로 유지**해야 한다(진입 스킬 Phase 0에 암묵 의존하는 문장 금지).
  - 변경 시 각 파일 `description` 앞머리의 `(agent-internal — …)` 표기와 README/문서 설명이 위 구분과 일치하는지 확인(`grep -l "agent-internal" agents/*.md skills/*/SKILL.md` → agent 6개 전부 / skill 0개)
- `gh` CLI, CodeGraph MCP, Serena MCP 의존 — 플러그인 자체 번들 MCP 아님(일반 MCP 등록형), README dependency summary와 실제 의존 일치 여부 확인
- skill 간 cross-reference(예: `feature-workflow-runner` ↔ `feature-plan-executor` ↔ `branch-issue-precheck.md`)가 많아 하나만 고치면 다른 곳의 참조·완료 기준 문구가 어긋나기 쉬움 — 관련 SKILL.md 전체를 grep으로 교차 확인

### devoks-git
- skill 없이 command만 존재(`git-commit-msg`, `git-create-issue`, `git-pull-request`) — 변경 시 command frontmatter/문서만 대상
- **이 구성은 확정된 정책이다**(2026-08-21, `docs/CHANGELOG.md` 「[폐기] 4개 항목 폐기」(2026-08-21) 폐기 ③·④): 진입점은 **커맨드**, 실행은 **메인 루프**. 근거 — git/gh write 액션은 스킬 auto-trigger 오발동 리스크가 크고, 승인 게이트가 절차의 본질이라 `docs/plugin-management.md` §12 기준 2("승인 게이트형 작업은 의도적으로 메인 루프에서 실행")에 걸리며, 커밋 메시지·PR 본문의 "왜"는 cold diff에서 나오지 않아 서브에이전트 위임 시 품질이 떨어진다. **스킬 전환·haiku 위임 제안이 다시 나오면 그 폐기 근거부터 확인할 것**
- `gh` CLI 의존, 별도 MCP 서버·prefix 없음
- devoks-sdlc의 여러 커맨드/스킬이 `/devoks-git:git-commit-msg`, `/devoks-git:git-create-issue`를 텍스트로 참조함(plugin.json `dependencies`엔 미기재) — devoks-git 쪽 커맨드명·규칙을 바꾸면 devoks-sdlc 참조도 함께 확인

## 5. 비대상 사유 작성 규칙

업데이트하지 않는 파일은 아래 형식으로 남긴다.

- `<file>`: `<왜 비대상인지>`

예시:
- `README.md`: 내부 hook 주석 정정만 포함, 사용자-facing 설명 불변
- `.claude-plugin/marketplace.json`: 플러그인 추가/삭제/description/dependency 변경 없음

## 6. 완료 전 최종 확인

- [ ] 변경 플러그인별 체크리스트가 분리되어 있는가
- [ ] 각 플러그인의 version bump 필요 여부가 설명되어 있는가
- [ ] `claude plugin validate ./plugins/<plugin> --strict` 실행 여부가 기록되었는가
- [ ] 문서 대상/비대상 판단이 파일별로 남아 있는가
- [ ] MCP/prefix/permission 대조 지점이 확인되었는가
- [ ] 에이전트를 추가·수정했으면 `tools:` 화이트리스트를 **에이전트 본문과 references 양쪽**의 도구 호출과 대조했는가
- [ ] core sync 영향이 있으면 `.claude/` 사본과 문서까지 함께 봤는가
- [ ] 신규/변경 skill이면 §7 스킬 품질 체크리스트(8축)를 적용했는가

## 7. 스킬 품질 체크리스트 (신규/변경 스킬 한정)

적용 조건: 신규 skill 생성 또는 기존 skill의 `description`/핵심 동작(트리거 조건·워크플로 단계) 변경.

| # | 축 | 검증 방식 | 적용 강도 |
|---|---|---|---|
| 1 | description ↔ 실제 동작 일치(효용성 포함) | 동적 — `evals/evals.json` 프롬프트를 서브에이전트로 실행해 `expected_output`과 대조 | 신규 skill: 필수 / 기존 skill 변경: 권장(트리거 조건 대폭 변경 시 필수) |
| 2 | `references/` 존재 | 정적 — SKILL.md 내 `references/*.md` 언급을 grep, 실제 파일과 대조 | 필수 |
| 3 | `evals/evals.json` 보유 | 정적 — 파일 존재 확인 | 신규 skill: blocking(없으면 최소 1~2개 작성) / 기존 skill 변경: 권장 |
| 4 | 의존 MCP/도구 명시 | 정적 — 위 "3. MCP / prefix / permission 점검 포인트" 대조 지점 재사용 | 필수 |
| 5 | 설치 후 경로 참조 안전성 | 정적 — 플러그인 루트 밖 상대경로(`../`) grep, `${CLAUDE_PLUGIN_ROOT}` 사용 확인 | 필수 |
| 6 | 토큰효율성 | 정적(SKILL.md 라인수·인라인 대용량 예시·`references/` 분리 여부) + 동적(축 1 실행 시 토큰/턴수 관찰) | 신규 skill: 필수 / 기존 skill 변경: 권장 |
| 7 | 인접 스킬 경계 명확성(중복 방지) | 정적 — 아래 "인접 스킬 경계 검사" 절차 | 신규 skill: 필수 / 기존 skill의 description·트리거·범위가 넓어지는 변경: 필수 |
| 8 | `argument-hint` 정합성 | 정적 — 아래 "argument-hint 정합성" 절차 | 인자 슬롯 있는 스킬: 항상 필수 / 인자 슬롯 없는 스킬: 힌트가 있으면 제거 대상 |

> 2026-09-02: 축 7·8 신설. 축 8(`argument-hint` 정합성)은 이 문서에 원래도 "항상 필수, 정적"으로 존재했으나 위 표에 집계되지 않아 "6축 다 확인" 표기가 실제로는 이 항목을 빠뜨릴 수 있는 구조였다 — 표에 편입해 정정. 축 7은 신규 — 근거는 아래 "인접 스킬 경계 검사" 절 참고. 검토했으나 **채택하지 않은 후보**(2026-09-02 논의): "효용성"을 축 1에서 분리한 별도 축, Step 1의 사전 중복 검색 게이트, eval assertion의 판별력(discriminating power) 검증 — 전부 정성적 판단에 크게 의존해 정적/동적 검증으로 조작화하기 어렵고, 축을 늘릴수록 매 스킬 변경마다 체크 비용이 커지는 트레이드오프가 있어 이번엔 보류. 재론의 시 이 사유부터 반박할 것.

### 동적 검증(축 1·6) 실행 방법

1. 대상 skill의 `evals/evals.json`에서 프롬프트를 가져온다(없으면 최소 1~2개 신규 작성).
2. 서브에이전트(`Agent` 도구, 신선한 컨텍스트)에 프롬프트를 그대로 전달해 skill을 실제로 트리거시킨다.
3. 결과를 `expected_output`과 대조해 description-동작 일치·효용성을 판정한다.
4. 실행 과정에서 관찰된 토큰/턴 소모가 skill의 목적·워크플로 복잡도 대비 과도한지 판단한다(예: 단순 조회성 skill이 references를 불필요하게 여러 개 순차 로드하는지).
5. 신규 skill은 이 실행을 생략할 수 없다.

#### 보조 옵션 — `claude plugin eval`로 실측 확인 (선택, 2026-09-14 추가)

위 서브에이전트 방법은 항상 필수인 최소 기준이며, 이걸 대체하지 않는다. `claude plugin eval <plugin 경로>`는 단순 발동 여부 확인에 그치지 않는다 — 기본 동작(`--ablation with-without`)이 **플러그인 있음/없음 두 arm을 각각 실행해 점수를 비교**하므로, "이 skill이 bare 세션 대비 실제로 더 나은 결과를 내는가"(Δ, 효용성)까지 자동으로 측정한다. 이는 2026-09-02 항목("스킬 품질 체크리스트 6축→8축 확장")에서 *"효용성을 축1에서 분리한 별도 축 후보 — 자동화된 판정 방법이 없어 보류"*로 기록해둔 공백을 부분적으로 메운다. 단, 이 사실 하나로 필수 축을 신설하지는 않는다 — 아래처럼 **선택적 온디맨드 확인 수단**으로만 채택한다. GA 확인: 2026-09-14, v2.1.270에서 `--help`/`init --bare` 정상 동작.

케이스 하나에 grader를 조합해 세 층위를 함께(또는 선택적으로) 확인할 수 있다:
- **발동 여부**: `tool_used` grader(스킬/툴 호출 횟수·입력 매칭)
- **효용성(Δ)**: `--ablation with-without`(기본값)의 with-score − without-score — 플러그인이 없을 때보다 실제로 더 나은 결과를 내는가
- **출력 품질**: `llm` grader(judge 모델이 rubric으로 채점), `regex`/`baseline` grader(결정적 패턴·레퍼런스 대조) — "발동은 했지만 결과가 나쁜" 경우까지 잡아낸다

사용 시 유의점:
- **단일 플러그인만 대상으로 한다.** target은 한 번에 하나(`plugins/<plugin>` 경로, 이름, 또는 `plugin@marketplace`)만 받는다 — 여러 플러그인을 한 번에 스캔하는 배치 실행은 도입하지 않는다(플러그인 수만큼 실비용이 선형으로 늘어나 "필요할 때 하나만" 원칙과 맞지 않음).
- 케이스는 **상시 저작·커밋 대상이 아니다.** 확인이 필요할 때 `evals/<임시케이스>/prompt.md`+`graders/*.md`(또는 `init` 인터랙티브)로 즉석 작성 → `--runs 1`(최소 비용, Δ까지 보려면 `--ablation` 기본값 유지) 실행 → 확인 후 커밋 없이 지워도 된다.
- 기존 `evals/evals.json` 포맷과는 **다른 스키마**라 자동 변환 없음 — 위 서브에이전트 방법(축 1의 필수 최소 기준)을 대체하지 않고, 그 위에 얹는 선택적 심화 확인이다.
- 근거: `docs/CHANGELOG.md` 「evals 하니스 확대」 폐기 항목(2026-08-21) 참고 — early-access 게이트는 풀렸으나(2026-09-11 GA), 포맷 비호환·상시 확대 YAGNI 근거는 그대로 유효해 이 좁은 용도로만 채택했다.

### 정적 체크(축 2~6) 실행 방법

- 축 2: `grep -o 'references/[a-zA-Z0-9_.-]*\.md' SKILL.md` 결과와 `references/` 디렉토리 실제 파일 목록 대조
- 축 3: `evals/evals.json` 파일 존재 확인
- 축 4: 위 §3 "MCP / prefix / permission 점검 포인트" 절차 재사용
- 축 5: `grep -n '\.\./' skills/<name>/SKILL.md` 등으로 플러그인 루트 밖 상대경로 참조 여부 확인
- 축 6: SKILL.md 라인 수(`wc -l`), 본문 내 대용량 코드블록/예시 유무, `references/` 분리 여부 확인
- 축 7: 아래 "인접 스킬 경계 검사" 절차
- 축 8: 아래 "argument-hint 정합성" 절차

### 인접 스킬 경계 검사 (축 7 — 신규 skill 필수 / 범위 확장 시 필수, 정적)

**배경**: 이 저장소는 스킬을 만들고 난 **뒤에** 인접 스킬과의 경계가 흐려져 재작업한 이력이 여러 번 있다 —
`code-review`↔`code-security-review`(보안 에스컬레이션 규칙+상호참조 추가, 2026-07-20), `verify-acceptance-test`↔`verify-data-flow`,
`browser-visual-diff`↔`verify-data-flow`(중복 구현 금지 명시). 이 축은 그 재작업을 **사전에** 줄이기 위한 최소 점검이다 —
완벽한 중복 탐지가 목적이 아니라, "명백히 겹치는데 아무도 안 봤다"를 막는 것이 목적이다.

1. **트리거 문구 겹침 grep**: 대상 skill의 `description`에서 따옴표로 감싼 예시 트리거 문구를 뽑아, 같은 플러그인(및 `plugin.json`의 `dependencies`로 연결된 플러그인) 내 다른 `SKILL.md`의 `description`과 키워드 단위로 대조한다. 완전히 같은 키워드가 두 스킬 모두에 있으면 겹침 후보로 표시한다.
2. **범위 섹션 확인**: 대상 skill의 SKILL.md에 "범위(중요) — 한다/안 한다" 또는 "참고 기준 문서 — 관련" 같은 섹션이 있고, 1번에서 찾은 겹침 후보 스킬을 **명시적으로 라우팅**하는지 확인한다(예: "요구 충족 판정은 `verify-requirements`, 코드 품질 리뷰는 `code-review`를 쓴다").
3. **양방향 확인**: 겹침 후보 스킬 쪽에도 반대 방향 참조가 있는지 확인한다. 한쪽만 참조하는 단방향 구조는 과거 `code-security-review → code-review`만 있고 반대가 없던 것과 같은 결함이다 — 발견하면 반대쪽에도 추가한다.
4. 겹침이 실제로 있는데 라우팅 문구가 없으면 **문서 갭**으로 보고한다(신규 skill이면 이 단계에서 범위 문구를 추가해 blocking으로 해소, 기존 skill 변경이면 갭만 보고하고 해소 여부는 변경 규모에 따라 판단).

### argument-hint 정합성 (축 8 — 인자 슬롯이 있는 스킬 항상 필수, 정적)

`claude plugin validate --strict`는 매니페스트만 검증하고 SKILL.md frontmatter를 파싱하지 않으므로
아래를 직접 돌린다. 판정 기준은 `docs/plugin-management.md` §4.

```bash
# (1) frontmatter YAML 파싱 + argument-hint가 String인지 (배열이면 따옴표 누락)
ruby -ryaml -e '
Dir.glob("plugins/**/SKILL.md").sort.each do |p|
  l = File.read(p).split("\n"); c = (1...l.size).find { |i| l[i].strip == "---" }
  fm = YAML.safe_load(l[1...c].join("\n")); h = fm["argument-hint"]
  puts format("%-9s %s", h.nil? ? "-" : (h.is_a?(String) ? "OK" : "!!#{h.class}"), p)
rescue => e then puts "PARSE ERR #{p}: #{e.message.lines.first.strip}" end'

# (2) 힌트 == 본문 "## 호출 방법" usage 인자부 (완전 일치여야 한다)
for f in $(grep -rl '^argument-hint:' plugins --include=SKILL.md); do
  hint=$(grep -m1 '^argument-hint:' "$f" | sed 's/^argument-hint: "//; s/"$//')
  usage=$(awk '/^## 호출/{f=1} f&&/^\/[a-z]/{sub(/^[^ ]+ /,""); print; exit}' "$f")
  [ -z "$usage" ] && continue   # 위치 인자형(usage 블록 없음) — 아래 예외 참고
  [ "$hint" = "$usage" ] || { echo "DIFF $f"; echo "  hint : $hint"; echo "  usage: $usage"; }
done
```

- 본문에 `## 호출 방법` 슬롯이 있는데 `argument-hint`가 없으면 **누락**으로 본다.
- 인자 슬롯이 없는 스킬(대화 맥락만으로 동작)에 힌트가 붙어 있으면 **제거 대상**이다.
- **예외 — 위치 인자형**: `## 호출 방법` usage 블록 대신 `## 입력 파라미터`로 필수 입력을 선언하는 스킬은
  힌트도 위치형으로 쓴다(`new-ui-draft` → `"<Figma URL> <구현 추가정보>"`). 위 (2)는 `continue`로 건너뛰므로,
  이 경우 `## 입력 파라미터` 표의 필수/선택 서술과 힌트를 **눈으로** 대조한다.

#### 필수/선택·기본값 표기 판정 (usage string 관례)

| 표기 | 의미 | 판정 근거를 어디서 찾나 |
|------|------|----------------------|
| `key=<값>` (대괄호 없음) | **필수** — 값이 확정되지 않으면 실행 불가 | Phase 0의 "미충족 슬롯을 1회 확인" 질문 목록에 포함된 슬롯. Phase 0가 없는 스킬은 그 값 없이 파이프라인이 시작될 수 없는 슬롯 |
| `[key=<값>]` | 선택 — 없으면 생략·미반영 | 슬롯표에 "(있다면)"·"(선택)" 표기, 또는 Phase 0 질문 목록에 없음 |
| `[key=<값> (default: X)]` | 선택 + 결정적 기본값 X로 **묻지 않고** 진행 | 본문에 `기본값 =` / `미지정 시` / `없으면 …로 진행` 서술 |

- **legend는 표기법만 정의한다.** 필수 슬롯 생략 시의 처리(되묻기 여부)를 legend에 쓰지 말 것 — 스킬마다 다르다.
  대부분은 Phase 0에서 되묻지만 비-HITL 파이프라인(`orchestration-run`)은 **중간 승인 없이** 동작해 되묻는 단계가 없다.
  2026-08-28 재점검에서 legend에 "생략 시 Phase 0에서 확인"을 넣었다가 이 2건(`orchestration-run`·`feature-plan-author`)에서
  **존재하지 않는 단계를 약속**하는 것을 발견해 표기법만 남기도록 정정했다.
- 따라서 `key=<값>`(필수)로 표기할 때는 **그 스킬에 값 확정 경로가 실제로 있는지** 확인한다:
  Phase 0의 확인 질문, 슬롯표의 "인자 또는 Phase 0 확인", 또는 "반드시 제공받는다" 서술 중 하나가 있어야 한다.
  셋 다 없으면 그 스킬의 **문서 갭**이므로 표기만 바꾸지 말고 갭 자체를 보고한다.

- 기본값 키워드는 `default:` 고정(한국어 `기본` 금지). 단 **usage string이 아닌 산문**(슬롯표 "입력 방법" 열 등)은 한국어 `기본`을 유지한다 — `default:`는 `argument-hint`·본문 usage 라인·legend 3곳 전용이다.
- `(default: X)`는 콜론+공백을 포함하므로 **따옴표 누락 시 조용한 오파싱 또는 하드 에러**가 된다(`docs/plugin-management.md` §4 표). 위 (1) 스크립트로 String 여부를 반드시 확인한다.
- 기본값 문구는 **본문에 실제로 서술된 것만** 쓴다. 근거 없이 추정해 넣지 않는다.
- "인자가 없어도 동작한다"와 `key=<값>`(필수) 표기는 **모순이 아니다** — 인자 생략은 가능하고, 대신 Phase 0이 묻는다.
- 힌트만 바꾸고 본문 usage를 그대로 두면 필수/선택이 서로 모순된다. **항상 같이 고친다**(위 (2)가 이걸 잡는다).

## 8. AskUserQuestion 사용 규칙 (스킬 저작 컨벤션 SSOT)

스킬/커맨드 본문에 **사용자 확인 분기**를 넣을 때 `AskUserQuestion` 사용 여부는 아래 기준으로 판단한다.
스킬은 대상 프로젝트에 배포되면 이 문서를 런타임에 읽지 못하므로, **스킬 본문 자체에 가드 문구를 baked-in** 한다
(이 절은 그 문구를 일관되게 쓰기 위한 저작 기준이다).

| 상황 | 처리 |
|---|---|
| HITL(사용자 직접 호출) + 진짜 갈림길(기본값 없음/애매) + 이산 선택지 | `AskUserQuestion` 적용. 서로 독립된 후속작업이면 `multiSelect` |
| 명확한 기본값이 있음 | 묻지 말고 진행 + 한 줄 통보 |
| 자유 입력(경로·URL·임의 텍스트) | 한 줄 텍스트 질문(모달 아님) |
| 에이전트 자체 점검 목록 | 모달 아님 — 그냥 실행 |
| **서브에이전트 내부** | **질문 금지**(계약: `code-implementer`/`test-writer` 등). 메인 루프로 반환 후 질문 |
| **비-HITL 오케스트레이션 구동 중** | **질문 금지** → 문서화된 기본값/정책으로 무중단 진행 |

**제약(툴 스펙):** 한 호출에 질문 1~4개, 질문당 옵션 2~4개, "Other"는 자동 추가. 항목이 4개를 넘으면 질문을 분할한다.

**탐지 플래그 금지(YAGNI):** "지금 비-HITL로 구동 중인가"를 런타임에 탐지하는 플래그를 새로 만들지 않는다.
`devoks-sdlc-orchestration`은 HITL 스킬 본문을 호출하지 않으므로(그 플러그인 `references/pipeline.md`의 불변식) 비-HITL 경로가 애초에 없다.
그 불변식이 깨지면 그때 억제 플래그를 도입한다.

**현재 적용 스킬(참고):** `devoks-sdlc`의 `new-ui-draft`(테스트 작성 여부)·`code-review`(mode 갈림길)·`feature-plan-executor`/`feature-workflow-runner`(브랜치·이슈 사전체크, PR 그룹핑, 다음 단계). 다음 단계는 사용자가 고른 항목을 메뉴 순서대로 **위임 실행**한다(HITL 선택 실행): 읽기전용 검증/리뷰/테스트는 즉시, 커밋·PR은 git 커맨드 자체 확인 플로를 최종 게이트로 두고 **앞선 검증에서 Critical/High 발견 시 커밋·PR 전 정지** — `post-implementation-checklist.md` 참고. (비-HITL 자동 실행과 구분 — 매 단계가 사용자 선택으로만 시작.)
