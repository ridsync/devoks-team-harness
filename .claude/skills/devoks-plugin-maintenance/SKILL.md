---
name: devoks-plugin-maintenance
description: devoks-team-harness 저장소에서 플러그인 기능 변경, 버그 수정, 스킬/커맨드/에이전트 추가·수정, MCP prefix·permission 정책 변경, 카탈로그/문서 정합성 점검이 필요한 작업을 할 때 사용하는 maintainers용 로컬 워크플로우. 사용자가 devoks-browser/devoks-rn/devoks-core 같은 플러그인 변경을 요청하거나, plugin version bump / validate --strict / README·README.ko·marketplace·MCP guide 동기화가 필요해 보이면 반드시 이 스킬을 먼저 사용한다.
metadata:
  author: ridsync
  version: 0.3.2
---

# devoks-plugin-maintenance

`devoks-team-harness`의 플러그인 변경 작업에서 **절차 누락을 막는 로컬 maintainers용 워크플로우**다.
배포용 플러그인 번들에 포함되는 기능이 아니라, **이 저장소를 관리하는 사람**이 먼저 호출해야 하는 작업 절차다.

## 왜 이 스킬을 먼저 써야 하나

이 저장소는 플러그인 번들, README 카탈로그, MCP 가이드, core hook 문서가 서로 연결되어 있다.
플러그인 코드만 고치고 끝내면 아래가 자주 빠진다.

- `plugin.json` version bump
- `claude plugin validate --strict`
- README / `docs/README.ko.md` / `.claude-plugin/marketplace.json` 반영
- MCP prefix / `permissions.allow` / setup 가이드 정합성
- `devoks-core` rules/refs 와 루트 `.claude/` 사본 동기화 점검

이 스킬의 목적은 **변경 범위를 먼저 고정하고, 플러그인별 체크리스트를 분리한 뒤, 비대상 사유까지 남기게 하는 것**이다.

## 먼저 읽을 SSOT

상황에 맞게 아래 파일을 우선 읽어라.

- 구조·버전·검증 규칙: `docs/plugin-management.md`
- 카탈로그와 사용자-facing 구성: `README.md`, `docs/README.ko.md`
- MCP 설치/prefix 정책: `docs/mcp-setup-guide.md`, `plugins/devoks-core/commands/setup-mcp.md`
- 세션 시작 setup 상태 점검 규칙: `plugins/devoks-core/hooks/check-setup-state.sh`
- legacy sync 종료 맥락: `docs/fix-plan-sync-context-ssot.md`
- 카탈로그 drift 맥락: `docs/roadmap.md`
- 상세 체크표: `references/workflow-checklist.md`

## 실행 원칙

- 먼저 읽고 수정한다. 추측하지 않는다.
- 여러 플러그인이 바뀌면 **플러그인별 체크리스트를 분리**한다.
- 문서를 갱신하지 않을 경우, "왜 비대상인지"를 파일별로 남긴다.
- 기능 변경이 아니어도 `description`, 이름, dependency, MCP prefix, permission 정책이 바뀌면 카탈로그/문서 검토 대상으로 본다.
- `devoks-core`의 `rules/`, `refs/`, hook 변경은 루트 `.claude/` 사본과 운영 문서를 같이 본다.

## Step 1 — 변경 범위 선언

작업 시작 시 아래를 먼저 확정한다.

1. 변경 대상 플러그인
   - 예: `devoks-browser`
   - 예: `devoks-core`, `devoks-rn`
2. 변경 유형
   - `runtime behavior only`
   - `public workflow change`
   - `docs-only`
   - `MCP/prefix/policy change`
   - `naming/catalog change`
   - `core refs/rules change`
3. 변경 이유
   - 버그 수정 / 기능 추가 / 구조 조정 / 설명 정정 / 문서 정합성

범위가 애매하면 바로 수정하지 말고 먼저 사용자에게 확인한다.

**추가 신호**: 아래 중 하나라도 해당하면 Step 4의 "스킬 품질 체크리스트"를 함께 적용 대상으로 표시한다.
- 신규 skill 생성
- 기존 skill의 `description` 또는 핵심 동작(트리거 조건·워크플로 단계)이 바뀌는 변경

## Step 2 — 플러그인별 체크리스트 작성

각 변경 플러그인마다 아래 블록을 만든다.

```md
### Plugin: <name>
- Change type:
- Files touched:
- Version bump required: yes/no
- Validation required: yes/no
- Docs to update:
- Docs intentionally not updated:
- MCP/prefix/permission impact:
- Core sync impact:
```

여러 플러그인을 한 묶음으로 처리하지 마라.

## Step 3 — 버전 bump 판단

각 변경 플러그인에 대해 `plugins/<plugin>/.claude-plugin/plugin.json`을 확인한다.

- 플러그인 번들 내용이 바뀌면 version bump를 기본값으로 본다.
- 저장소 루트 문서만 바뀐 경우는 bump 비대상으로 둘 수 있다.
- bump 이유를 semver로 설명한다.
  - `patch`: 버그 수정, 설명 정정, 동작 불변 개선
  - `minor`: 새 기능, 새 skill, 새 command, 새 선택적 동작
  - `major`: 호환성 깨짐, 이름/호출 방식/정책의 파괴적 변경
- `devoks-core`를 bump하면 `plugins/devoks-core/CHANGELOG.md`에 같은 버전 절을 반드시 추가한다(복사 산출물 변경은 파일·섹션·사유까지 — 기준: `references/workflow-checklist.md` devoks-core 절).

## Step 4 — 구조/스키마 검증

변경된 각 플러그인마다 검증을 요구한다.

```bash
claude plugin validate ./plugins/<plugin> --strict
```

추가로 확인한다.

- 신규/수정 skill frontmatter
- 신규/수정 command frontmatter
- 신규/수정 agent frontmatter (`model` 필드를 의도적으로 선택했는지 — 근거는 `docs/plugin-management.md` §12 참고)
- 경로 구조 유효성
- warning도 실패로 취급할지 여부 (`--strict` 기준)

### 스킬 품질 체크리스트 (신규/변경 스킬 한정)

Step 1에서 "추가 신호"에 해당한다고 표시된 경우에만 적용한다. 상세 판정 기준·체크 명령은 `references/workflow-checklist.md` §7을 따른다. 8축:

1. **description ↔ 실제 동작 일치(효용성 포함)** — `evals/evals.json` 프롬프트를 서브에이전트로 실제 실행해 `expected_output`과 대조한다. **신규 skill은 이 동적 실행을 생략할 수 없다.** 기존 skill 변경은 권장(트리거 조건이 크게 바뀌면 필수로 격상). 발동 여부뿐 아니라 효용성(플러그인 있음/없음 비교 Δ)·출력 품질까지 확신이 필요하면 `claude plugin eval <plugin 경로>`로 단일 플러그인 실측 확인을 선택적으로 추가할 수 있다(상세: `references/workflow-checklist.md` §"동적 검증(축 1·6) 실행 방법" 하위 "보조 옵션").
2. **`references/` 존재** — SKILL.md가 언급하는 `references/*.md`가 실제로 존재하는지 대조한다.
3. **`evals/evals.json` 보유** — 신규 skill은 최소 1~2개 케이스 작성이 blocking이다(축 1 실행에 그대로 사용).
4. **의존 MCP/도구 명시** — Step 6의 MCP/prefix 대조 지점을 그대로 재사용한다(중복 로직 신설 금지).
5. **설치 후 경로 참조 안전성** — 플러그인 루트 밖 상대경로(`../`) 참조가 없는지, 크로스 참조가 필요하면 `${CLAUDE_PLUGIN_ROOT}`를 쓰는지 확인한다.
6. **토큰효율성** — SKILL.md 라인 수·인라인 대용량 예시 유무·`references/` 분리 여부를 정적으로 먼저 살피고, 축 1의 동적 실행 시 소모 토큰/턴 수를 함께 관찰한다. 신규 skill은 축 1과 함께 관찰이 필수.
7. **인접 스킬 경계 명확성(중복 방지)** — 트리거 문구·범위가 인접 스킬과 겹치는지 확인하고, 겹치면 "범위(중요)"·"관련" 섹션에 양방향 라우팅 문구를 둔다(단방향 참조 금지).
8. **`argument-hint` 정합성** — 인자 슬롯이 있는 스킬은 힌트와 본문 usage가 완전히 일치하는지, YAML로 정상 파싱되는지 확인한다.

축 2·3·4·5·7·8은 정적 체크로 항상 필수다(축 7·8은 대상이 있을 때만 — 인접 스킬이 없거나 인자 슬롯이 없으면 해당 없음). 축 1·6의 동적 실행은 신규 skill에서 필수, 기존 skill의 description/동작 변경에서는 권장이다.

> **AskUserQuestion 사용 규칙:** 스킬 본문에 사용자 확인 분기를 넣거나 고칠 때는 `references/workflow-checklist.md` §8의 적용/금지 기준을 따른다(HITL 직접 호출에서만, 비-HITL·서브에이전트 경로에선 기본값 진행 — 가드 문구는 스킬 본문에 baked-in).

## Step 5 — 문서/카탈로그 정합성 검토

상세 매트릭스는 `references/workflow-checklist.md`를 따른다.

최소한 아래 파일의 반영 필요 여부를 판단한다.

- `README.md`
- `docs/README.ko.md`
- `docs/plugin-management.md`
- `docs/mcp-setup-guide.md`
- `plugins/devoks-core/commands/setup-mcp.md`
- `.claude-plugin/marketplace.json`

**중요:** 업데이트하지 않는 파일은 "비대상 사유"를 남긴다.  
예: "README.md 비대상 — 내부 hook comment 정정만 포함, 사용자-facing 설명 불변"

## Step 6 — MCP / prefix / permission 정합성 검토

아래 차이를 항상 구분한다.

- plugin 설치형 prefix: `mcp__plugin_<plugin>_<server>__*`
- `claude mcp add`형 prefix: `mcp__<server>__*`

다음을 서로 대조한다.

- `plugin.json`의 `mcpServers`
- `plugin.json`의 `settings.permissions.allow`
- 관련 SKILL.md / agent 문서의 tool 명칭
- `docs/mcp-setup-guide.md`
- `plugins/devoks-core/commands/setup-mcp.md`
- `plugins/devoks-core/hooks/check-setup-state.sh`

**에이전트를 추가·수정했으면** frontmatter `tools:` 화이트리스트를 그 에이전트가 읽는 `references/`
**와 에이전트 본문 양쪽**의 도구 호출 지시와 대조한다 — `tools:`에 없는 도구는 **에러 없이** 차단되고,
`settings.permissions.allow`가 커버해도 무의미하다(두 메커니즘이 별개). 실제 사고 2건과 체크 목록은
`references/workflow-checklist.md` §3 「에이전트 `tools:` 화이트리스트 대조」.

### 특수 케이스

- `devoks-browser`
  - `chrome-devtools-attach`
  - 관련 permission allow prefix
- `devoks-rn`
  - `metro-devtools`
  - setup-mcp 안내와 allow prefix
- Figma / Playwright
  - 플러그인 설치 전제인지, 일반 MCP 등록인지

## Step 7 — core sync 점검

아래 변경은 추가 확인이 필요하다.

- `plugins/devoks-core/refs/*`
- `plugins/devoks-core/rules/*`
- `plugins/devoks-core/hooks/check-setup-state.sh`
- legacy `sync-context.sh` 제거 또는 explicit setup 정책 변경

확인 항목:

- 루트 `.claude/rules/`에 `plugins/devoks-core/rules|refs/*` 번들 사본이 다시 나타나지 않았는지(2026-07-14 잔재 제거 완료 — 루트에는 이 저장소 전용 `project-convention.md`만 있어야 한다)
- 운영 문서 설명과 실제 동작이 맞는지
- explicit setup/sync 정책이 바뀌면 관련 문서도 함께 갱신했는지

## Step 8 — 결과 보고 형식

항상 아래 형식으로 정리한다.

```md
## Maintenance review

### Changed plugins
- <plugin-a>: <change summary>
- <plugin-b>: <change summary>

### Required follow-ups
- [ ] version bump
- [ ] validate --strict
- [ ] docs/catalog updates
- [ ] MCP/prefix/permission checks
- [ ] core sync checks
- [ ] 스킬 품질 체크(해당 시 — 8축, 신규 skill은 동적 실행 포함)

### Docs updated
- <file>

### Docs intentionally not updated
- <file>: <reason>

### Verification
- <command or check>

### Risks / follow-up
- <remaining concern>
```

## 스모크 테스트 프롬프트

- `devoks-browser 에서 chrome-devtools 관련 버그를 수정하려고 해. 버전 bump랑 문서 반영까지 포함해서 절차대로 점검해줘.`
- `devoks-rn 의 metro-devtools prefix 정책을 손봐야 해. setup 문서, permissions, validate 체크까지 빠짐없이 관리해줘.`
- `devoks-core 의 refs/rules 와 sync-context 훅 설명을 같이 바꾸려 해. 루트 .claude 사본과 운영 문서 정합성까지 확인해줘.`
- `devoks-sdlc 의 code-reviewer agent에 새 체크 항목을 추가하고 관련 skill 설명도 손보려고 해. 유지보수 절차대로 버전 bump부터 문서 반영까지 점검해줘.`
- `devoks-git 의 git-pull-request 커맨드에 새 옵션을 추가하려고 해. 버전 bump랑 문서 반영까지 유지보수 절차로 점검해줘.`
- `devoks-sdlc 에 새 skill을 하나 추가하려고 해. 목적만 있고 이름은 아직 안 정했어. 유지보수 절차대로 점검해줘.`
