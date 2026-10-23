---
description: DevOKs 권장 MCP 서버를 현재 상태에 맞춰 user scope에 1회 설치·초기화한다.
---

# DevOKs MCP Setup (`/devoks-core:setup-mcp`)

## SSOT

- 이 커맨드 자체가 설치 정책·방식·prefix 규칙의 실행 가능한 SSOT다 (아래 Steps 전부 self-contained).
- 감지 로직 참고: `devoks-core` SessionStart 훅 `${CLAUDE_PLUGIN_ROOT}/hooks/check-setup-state.sh`.
- `docs/mcp-setup-guide.md`는 harness 저장소 자체(devoks-team-harness) 안에만 있는 배경 설명·의존성 매트릭스 문서다 — 대상 프로젝트에는 설치되지 않으므로 이 커맨드 실행에 필요한 내용을 그 문서에 미루지 않는다.

## Overview

DevOKs 플러그인은 공유 MCP(context7·figma·serena·codegraph·playwright)를 번들하지 않는다.
번들 MCP와 user-scope MCP는 병합되지 않고 별도 프로세스 + 다른 도구 prefix로 공존해
중복·충돌을 일으키기 때문이다. 이 커맨드는 누락된 권장 MCP만 골라 **user scope에 1회 설치**한다.

**핵심 제약 — 설치 방식이 도구 prefix를 결정한다:**
- `claude mcp add` → `mcp__<server>__*`
- 플러그인 설치 → `mcp__plugin_<plugin>_<server>__*`

스킬이 하드코딩한 prefix와 맞추기 위해 **figma·playwright는 반드시 플러그인으로** 설치한다
(`claude mcp add`로 깔면 prefix 불일치로 스킬이 깨진다). **serena도 플러그인으로 설치한다** — prefix
문제는 아니지만, bare `claude mcp add`가 쓰는 PyPI 패키지명 `serena`가 이 도구(`oraios/serena`)와
무관한 별개 프로젝트(AMQP 클라이언트)와 이름이 충돌해 `uvx serena@latest`가 잘못된 패키지를 설치한다
(2026-08-10 확인, `pypi.org/project/serena`). context7·codegraph는 `claude mcp add`로 설치한다
(codegraph는 공식 플러그인이 없어 CLI 직접 설치가 유일한 경로). **chrome-devtools-attach도 `claude mcp add`로
설치한다** — 스킬·에이전트 `tools:` 화이트리스트가 `mcp__chrome-devtools-attach__*` prefix를 전제하기 때문이다(Step 6).

## Steps

1. **현재 상태 감지 (멱등)**
   - `claude mcp list`를 실행해 등록된 MCP 서버를 확인한다. 보조로 `~/.claude.json`을 확인한다.
   - 이미 설정된 항목은 **건너뛴다**. 아래 액션은 누락된 항목에만 적용한다.

2. **설치 계획 제시 및 확인**
   - `~/.claude.json`은 전역 설정이므로, 실제로 실행할 `claude mcp add` 명령 목록을 먼저 사용자에게 보여주고
     **확인을 받은 뒤** 실행한다.
   - 사용자가 특정 항목만 선택할 수 있게 한다(예: context7만, codegraph 제외 등).

3. **user scope 설치 (shell — 직접 실행)**
   - **context7** (문서조회, 선택):
     ```bash
     claude mcp add context7 --scope user -- npx -y @upstash/context7-mcp@latest
     ```
   - **codegraph** (코드그래프, 선택):
     - 먼저 CodeGraph CLI를 설치한다:
       ```bash
       npm install -g colbymchenry/codegraph
       ```
     - CLI 설치 후 MCP로 등록한다:
       ```bash
       claude mcp add codegraph --scope user -- codegraph serve --mcp
       ```
     - 프로젝트 인덱싱(선택):
       ```bash
       codegraph install "$CLAUDE_PROJECT_DIR"
       ```

4. **플러그인 설치 (figma·playwright·serena — prefix 일치/패키지명 충돌 회피를 위해 플러그인 경로 유지)**
   - 이들은 `claude mcp add`로 깔지 **않는다**. 다음 슬래시 명령을 안내한다:
     - figma (UI 구현·visual-diff 필수): `/plugin install figma@claude-plugins-official`
     - playwright (visual-diff 폴백, 선택): `/plugin install playwright@claude-plugins-official`
     - serena (심볼 탐색·리팩토링, 권장): `/plugin install serena@claude-plugins-official`
   - `/plugin install`은 대화형 Claude Code 명령이므로 shell로 자동 실행하지 말고, 위 명령을 그대로 안내한다.
   - figma는 최초 도구 호출 시 브라우저 OAuth로 인증된다.
   - serena는 프로젝트별 초기화가 설치 시점 CLI 플래그(`--project`)가 아니라 **런타임 도구 호출**로
     이뤄진다 — 설치 후 `activate_project` 또는 `onboarding` 도구를 사용하도록 안내한다(SessionStart
     훅이 `.serena/project.yml` 부재 시 이미 이 안내를 출력한다).
   - **JS/TS 프로젝트는 `jsconfig.json` 또는 `tsconfig.json`이 있어야** serena의 참조 추적이 동작한다.
     이 파일이 없으면 language server가 파일별 inferred project로 떨어져 `find_referencing_symbols`가
     **에러 없이 빈 결과**를 돌려준다(2026-09-18 실측: 추가 전 0건 → 추가 후 37개 파일, grep 결과와 일치).
     monorepo면 저장소 루트가 아니라 실제 소스 패키지 루트에 둔다. 참조 추적이 0건이면
     "참조가 없다"고 결론내기 전에 이 파일 존재부터 확인한다.

5. **metro-devtools (React Native 전용 — devoks-rn 플러그인 필요)**
   - RN 프로젝트에서 `devoks-rn:metro-devtools-attach` 스킬 사용 시 필요하다 (JS 콘솔·Zustand·TanStack Query 조회).
   - `devoks-rn` 플러그인에 번들된 `metro-mcp.js`를 `~/.devoks/mcp/`에 복사 후 user scope에 등록한다.
     Metro URL을 `/json` 엔드포인트로 **자동 조회**하므로 Metro 재시작마다 수동 갱신이 불필요하다.

   **설치 단계:**
   1. `devoks-rn` 플러그인이 설치돼 있는지 확인한다:
      ```bash
      ls ~/.claude/plugins/cache/devoks-plugins/devoks-rn/ 2>/dev/null || echo "플러그인 미설치"
      ```
      미설치면 먼저 `/plugin install devoks-rn@devoks-plugins`를 안내한다.

   2. 스크립트를 devoks 관리 경로에 복사한다:
      ```bash
      mkdir -p ~/.devoks/mcp
      SCRIPT=$(find ~/.claude/plugins/cache/devoks-plugins/devoks-rn -name "metro-mcp.js" \
                -path "*/scripts/*" 2>/dev/null | sort -V | tail -1)
      cp "$SCRIPT" ~/.devoks/mcp/metro-mcp.js
      ```

   3. user scope에 등록한다:
      ```bash
      claude mcp add metro-devtools --scope user \
        -- node --experimental-websocket ~/.devoks/mcp/metro-mcp.js
      ```

   4. Claude Code를 재시작하면 `mcp__metro-devtools__*` 도구가 활성화된다.

   ⚠ `devoks-rn` 플러그인 업데이트 후에는 `/devoks-core:setup-preset-manage`로 스크립트를 갱신한다(SessionStart 훅이 차이를 감지하면 안내한다). MCP 등록(3단계)은 경로가 같으므로 다시 할 필요가 없다.

6. **chrome-devtools-attach (visual-diff·data-verify 필수 — `claude mcp add`로 user scope 등록)**
   - `:9269` attach 고유 설정이다. **`devoks-browser`는 이 서버를 번들하지 않는다**(2.0.0부터) — 정의가 한 곳
     (user scope)에만 있어야 Node 버전·PATH 같은 로컬 설정을 그 자리에서 다룰 수 있다.
   - prefix는 `mcp__chrome-devtools-attach__*` — 스킬·에이전트 `tools:` 화이트리스트가 전제하는 값이다.
   - 누락이면(`claude mcp list`에 `chrome-devtools-attach` 부재, 또는 SessionStart 훅 경고) Step 2 확인을 거쳐 등록한다:
     ```bash
     claude mcp add chrome-devtools-attach --scope user -- npx chrome-devtools-mcp@latest --browserUrl http://127.0.0.1:9269
     ```
   - **이중 등록 점검:** `claude mcp list`에 `plugin:devoks-browser:chrome-devtools-attach`가 함께 보이면 구버전
     (1.x) devoks-browser가 번들한 것이다. 같은 `:9269`에 두 인스턴스가 붙으므로 `devoks-browser`를 2.0.0 이상으로
     업데이트하도록 안내한다(이 커맨드가 플러그인 서버를 직접 끄지 않는다).
   - **Node 22 이상을 권장한다.** `chrome-devtools-mcp`의 `engines`는 `^20.19.0`을 허용하지만, Node 20.19.0에서
     `get_css_styles`가 `longhandValues.intersection is not a function`으로 실패했다(`Set.prototype.intersection`은
     Node 22+, 2026-10-23 실측 — Node 22.22.2에서는 `typeof new Set().intersection === 'function'`). 나머지 도구는
     Node 20에서도 동작했다. 강제하지 않고 안내만 한다. `claude mcp add`에 `-e PATH=...`로 특정 Node를 고정하는 것은
     사용자 로컬 선택이다 — 이 커맨드가 nvm 절대경로를 대신 정하지 않는다.

   **런처 스크립트 생성** (Step 5가 `metro-mcp.js`를 `~/.devoks/mcp/`에 두는 것과 동일한 관리 경로 패턴)

   매번 긴 명령을 안내하는 대신 런처를 한 번 만들어 둔다. 포트(`9269`)와 `--user-data-dir`은
   `devoks-browser` 스킬이 attach 대상으로 기대하는 값이라 **고정값**이고, 시작 URL만 인자로 받는다
   (프로젝트마다 dev server 포트가 다르다).

   1. 시작 URL의 기본값을 사용자에게 **확인받는다** — 추정하지 않는다(현재 실행 중인 dev server 주소).
      확인받은 값을 `~/.devoks/chrome-debug.url`에 한 줄로 저장한다(런처가 인자 없이 실행될 때 읽는 기본값).

   2. 번들 런처를 devoks 관리 경로에 복사하고 실행 권한을 준다. 기존 `~/.devoks/bin/chrome-debug.sh`가
      있고 번들과 다르면 덮어쓰기 전에 확인받는다(로컬에서 손봤을 수 있다). 런처 본문에는 URL을 넣지 않는다 —
      번들 원본과 바이트 동일해야 `devoks-core:setup-preset-manage`가 업데이트 여부를 판정할 수 있다.
      ```bash
      mkdir -p ~/.devoks/bin
      command cp -f "${CLAUDE_PLUGIN_ROOT}/assets/chrome-debug.sh" ~/.devoks/bin/chrome-debug.sh
      chmod +x ~/.devoks/bin/chrome-debug.sh
      ```

   3. 실행·연결 확인:
      ```bash
      ~/.devoks/bin/chrome-debug.sh                       # 기본 URL로
      ~/.devoks/bin/chrome-debug.sh http://localhost:3000  # URL 지정

      curl -s http://127.0.0.1:9269/json | python3 -m json.tool
      ```

7. **ast-grep CLI (구조 패턴 일괄 치환 — 선택)**
   - MCP가 아니라 CLI 의존성이다. 동일 AST 패턴 N건을 한 번에 치환할 때 쓴다
     (단건 심볼 편집은 serena, 경로를 이미 아는 단순 확인은 내장 Read/Grep).
   - 설치:
     ```bash
     brew install ast-grep        # macOS
     # 또는
     npm install -g @ast-grep/cli
     ```
   - 설치 확인: `ast-grep --version`
   - **`sgconfig.yml` 스캐폴드는 이 커맨드가 만들지 않는다.** 규칙 디렉토리 경로와 언어 목록이
     스택·레이아웃에 따라 달라지므로, 스택을 확정하는 `/devoks-core:setup-project-convention`이
     적용한 preset의 "구조 패턴 일괄 치환(ast-grep)" 절을 따른다.
   - monorepo면 `sgconfig.yml`을 저장소 루트가 아니라 **실제 소스 패키지 루트**에 둬야 한다
     (예: `packages/<app>/sgconfig.yml`) — `ruleDirs`가 설정 파일 기준 상대경로로 해석된다.

8. **MCP prefix 확정 → permissions 베이스라인 산출 (자동 기입 금지)**

   이 커맨드는 "무엇을 어떤 방식으로 설치했는지 = prefix가 무엇인지"를 아는 **유일한 지점**이다.
   그러므로 여기서 프로젝트 `.claude/settings.local.json`의 `permissions.allow` 항목을 산출한다.

   **자동으로 쓰지 않는다.** Step 2와 같은 순서를 지킨다: 변경 목록 제시 → 사용자 확인 → 적용.
   사용자가 **항목별로** 선택할 수 있게 제시한다.

   **8-1. 설치 방식 → prefix 대조표** (Step 1 감지 결과 + Step 3·4·5·6에서 실제로 설치한 것만)

   | 서버 | 이 커맨드의 설치 방식 | allow 항목 |
   |------|----------------------|-----------|
   | context7 | `claude mcp add` (Step 3) | `mcp__context7__*` |
   | codegraph | `claude mcp add` (Step 3) | `mcp__codegraph__*` |
   | figma | 플러그인 (Step 4) | `mcp__plugin_figma_figma__*` |
   | playwright | 플러그인 (Step 4) | `mcp__plugin_playwright_playwright__*` |
   | serena | 플러그인 (Step 4) | `mcp__plugin_serena_serena__*` |
   | metro-devtools | `claude mcp add` (Step 5) | `mcp__metro-devtools__*` |
   | chrome-devtools-attach | `claude mcp add` (Step 6) | `mcp__chrome-devtools-attach__*` |

   - 표는 **이 커맨드가 안내한 경로**를 기준으로 한다. 사용자가 다른 방식으로 깔았다면 prefix가 달라지므로
     `claude mcp list` / `/mcp` 실제 출력으로 대조한 뒤 항목을 만든다. 추정 금지.
   - `metro-devtools`·`chrome-devtools-attach`는 각각 `devoks-rn`·`devoks-browser`의 `plugin.json`
     `settings.permissions.allow`에 이미 들어 있다 — 해당 플러그인을 설치했다면 프로젝트 파일에 **중복 기입 불필요**.

   **8-2. 기존 항목 점검 (stale prefix)**
   - `.claude/settings.local.json`의 기존 `permissions.allow`를 읽어 위 표와 대조한다.
   - **설치 방식이 바뀌면 옛 prefix가 죽은 항목으로 남는다.** 실측된 사례:
     - `mcp__playwright__*` → 현재 `mcp__plugin_playwright_playwright__*`
     - `mcp__plugin_chrome-devtools-mcp_chrome-devtools__*` → 현재 `mcp__chrome-devtools-attach__*`
   - stale 항목은 **제거 후보로 따로 묶어** 제시한다. 추가와 제거를 한 덩어리로 승인받지 않는다.

   **8-3. 제시 → 확인 → 적용**
   - `추가할 항목` / `제거 후보(stale)` / `이미 있음(변경 없음)` **3개 목록으로 분리**해 보여준다.
   - 사용자가 고른 것만 반영한다. 파일이 없으면 생성 여부도 함께 확인받는다.
   - 사용자가 직접 넣겠다고 하면 **붙여넣을 JSON 조각만 출력**하고 파일은 건드리지 않는다.
   - `settings.local.json`은 로컬 전용이다 — 팀 공유가 필요한 항목이면 `settings.json` 쪽을
     사용자에게 물어 결정한다. 임의로 바꾸지 않는다.

9. **결과 보고**
   - 설치가 끝나면 `claude mcp list`를 다시 실행해 최종 상태를 요약한다.
   - 변경 사항이 도구로 반영되려면 **세션 재시작이 필요할 수 있음**을 안내한다.
   - 프로젝트 규칙/refs 는 SessionStart 자동 동기화가 아니므로, 신규 설치 후에는 **별도로** `/devoks-core:setup-project-convention`을 실행해 stack preset 기반 `project-convention.md`를 구성하도록 안내한다.

## 주의

- 모든 `npx`/`uvx` 첫 실행은 패키지 다운로드가 필요하다 — 오프라인 환경에서는 첫 시작이 실패할 수 있다.
- 설치 중 에러가 나면 **에러 리포트만** 하고 자동으로 고치지 않는다. 사용자가 판단하도록 명령·로그를 그대로 전달한다.
