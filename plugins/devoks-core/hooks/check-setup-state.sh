#!/usr/bin/env bash
# check-setup-state.sh — DevOKs 권장 MCP 서버 설치 및 프로젝트 초기화 상태 점검
#
# SessionStart 훅으로 실행. devoks 플러그인은 범용·공유 MCP(context7·figma·
# serena·codegraph·playwright)를 번들하지 않는다(플러그인별 중복 인스턴스·
# user 로컬 MCP와의 충돌 방지). 대신 사용자 scope(user/project)에 1회 설치한
# 단일 서버에 의존한다. 이 훅은 그 서버들이 설정돼 있는지 확인하고, 프로젝트
# 단위 초기화가 필요한 MCP(serena/codegraph)는 현재 프로젝트 상태까지 점검한다.
#
# 특성: 멱등·빠름·non-blocking(항상 exit 0). 설치/초기화를 강제하지 않으며,
# 모두 설정돼 있으면 아무것도 출력하지 않는다.
#
# 환경변수 (Claude Code 자동 주입):
#   CLAUDE_PROJECT_DIR  — 프로젝트 루트

set -uo pipefail

USER_CFG="${HOME}/.claude.json"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-${PWD:-.}}"
PROJ_MCP="${PROJECT_DIR}/.mcp.json"
CLAUDE_DIR="${PROJECT_DIR}/.claude"

# user 설정(mcpServers·enabledPlugins)과 project .mcp.json 에서 토큰 존재 여부 확인.
# 휴리스틱: 토큰이 보이면 "설정됨"으로 간주(거짓음성=경고 누락, 거짓양성=경고 안 뜸 — 둘 다 저비용).
have() {
  local token="$1"
  { [[ -f "$USER_CFG" ]] && grep -qi "$token" "$USER_CFG"; } && return 0
  { [[ -f "$PROJ_MCP" ]] && grep -qi "$token" "$PROJ_MCP"; } && return 0
  return 1
}

is_project_dir() {
  [[ -n "${PROJECT_DIR:-}" && -d "$PROJECT_DIR" ]]
}

serena_project_ready() {
  is_project_dir || return 0
  [[ -f "$PROJECT_DIR/.serena/project.yml" ]]
}

codegraph_project_ready() {
  is_project_dir || return 0
  [[ -d "$PROJECT_DIR/.codegraph" ]] || return 1

  if command -v codegraph >/dev/null 2>&1; then
    codegraph status "$PROJECT_DIR" >/dev/null 2>&1 || return 1
  fi

  return 0
}

# 프로젝트에 인덱싱할 코드가 실재하는지. 하네스를 먼저 셋업하고 프로젝트를 나중에
# 만드는 순서(greenfield)에서는 설치 시점에 소스가 0개인데, 그 상태로 serena/codegraph
# 인덱싱을 안내하면 코드가 생길 때까지 매 세션 반복되는 오탐이 된다 — 훅의 "정상이면
# 침묵" 속성이 깨진다. 코드가 생기면 다음 세션에 안내가 자동으로 살아난다(자가치유).
# -print -quit 으로 첫 매치에서 멈춘다.
has_source_files() {
  is_project_dir || return 1
  local found
  found="$(find "$PROJECT_DIR" -maxdepth 3 \
    \( -name node_modules -o -name .git -o -name build -o -name dist -o -name .venv \) -prune -o \
    -type f \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' \
      -o -name '*.py' -o -name '*.kt' -o -name '*.java' -o -name '*.swift' \
      -o -name '*.go' -o -name '*.rs' -o -name '*.rb' -o -name '*.sh' \
      -o -name '*.c' -o -name '*.cc' -o -name '*.cpp' -o -name '*.cs' -o -name '*.php' \) \
    -print -quit 2>/dev/null)"
  [[ -n "$found" ]]
}

base_rules_ready() {
  is_project_dir || return 0
  [[ -f "$CLAUDE_DIR/rules/agent-principles.md" && -f "$CLAUDE_DIR/rules/memory-policy.md" ]]
}

refs_ready() {
  is_project_dir || return 0
  [[ -f "$CLAUDE_DIR/refs/code-review.md" \
    && -f "$CLAUDE_DIR/refs/engineering-principles.md" \
    && -f "$CLAUDE_DIR/refs/git-convention.md" \
    && -f "$CLAUDE_DIR/refs/interaction-integrity.md" \
    && -f "$CLAUDE_DIR/refs/workflow.md" ]]
}

project_convention_ready() {
  is_project_dir || return 0
  [[ -f "$CLAUDE_DIR/rules/project-convention.md" && -f "$CLAUDE_DIR/project-convention.json" ]]
}

# devoks-core base 파일 7종(rules 2 + refs 5) — setup-project-convention이 복사하는 집합.
BASE_FILES=(
  rules/agent-principles.md
  rules/memory-policy.md
  refs/code-review.md
  refs/engineering-principles.md
  refs/git-convention.md
  refs/interaction-integrity.md
  refs/workflow.md
)

# 번들 원본 디렉토리. 플러그인 경로가 없으면(폴백 설치·저장소 직접 실행) 훅 자신의 상위를 쓴다.
bundle_root() {
  local root="${CLAUDE_PLUGIN_ROOT:-}"
  if [[ -n "$root" && -d "$root/rules" ]]; then
    printf '%s' "$root"
    return 0
  fi
  (cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd) 2>/dev/null
}

# 설치된 devoks-core 버전. 플러그인 캐시 경로가 .../devoks-core/<version>/ 구조라
# 경로 마지막 세그먼트가 곧 버전이다 — 순수 파라미터 확장이므로 프로세스 기동 0.
# 경로가 버전 형태가 아닐 때(폴백 설치·저장소 직접 실행)만 매니페스트를 읽는다.
# 매니페스트 위치는 마켓플레이스마다 다르다 — devoks-plugins는 <root>/.claude-plugin/plugin.json
# (저장소와 동일)이지만 flat 배치(<root>/plugin.json)를 쓰는 마켓플레이스도 실재하므로 양쪽을 시도한다.
installed_core_version() {
  local seg="${CLAUDE_PLUGIN_ROOT:-}"
  seg="${seg%/}"
  seg="${seg##*/}"
  if [[ "$seg" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    printf '%s' "$seg"
    return 0
  fi

  local root manifest
  root="$(bundle_root)" || return 1
  for manifest in "$root/.claude-plugin/plugin.json" "$root/plugin.json"; do
    [[ -f "$manifest" ]] || continue
    sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$manifest" | head -1
    return 0
  done
  return 1
}

# provenance가 기록한 기준 버전. devoksCoreVersion 필드가 우선이고, 그 필드가 없는
# 구버전 provenance는 source 경로의 .../devoks-core/<version>/ 에서 회수한다
# (필드 도입 전 적용분도 재설정 없이 판정 대상에 들어오게 하려는 의도).
provenance_core_version() {
  local f="$CLAUDE_DIR/project-convention.json" v
  [[ -f "$f" ]] || return 1

  v="$(sed -n 's/.*"devoksCoreVersion"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$f" | head -1)"
  [[ -n "$v" ]] && { printf '%s' "$v"; return 0; }

  v="$(sed -n 's|.*/devoks-core/\([0-9][0-9.]*\)/.*|\1|p' "$f" | head -1)"
  [[ -n "$v" ]] && { printf '%s' "$v"; return 0; }
  return 1
}

# 스택 한정 refs — frontmatter `scope: <preset>`이 active preset과 같을 때만 복사되는 refs
# (예: web-security.md → react-web). BASE_FILES에 고정하지 않고 번들 frontmatter에서 매번
# 구한다: 업데이트로 새 스택 한정 ref가 생기면 사본이 없어 "다름"으로 잡혀야 base 갱신 안내가 뜬다.
scoped_ref_files() {
  local root="$1" preset f scope
  preset="$(sed -n 's/.*"preset"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$CLAUDE_DIR/project-convention.json" 2>/dev/null | head -1)"
  [[ -n "$preset" ]] || return 0
  for f in "$root"/refs/*.md; do
    [[ -f "$f" ]] || continue
    # 첫 frontmatter 블록 안의 scope만 본다(본문의 우연한 "scope:" 줄 무시).
    scope="$(awk 'NR==1 && $0!="---" {exit} NR>1 && $0=="---" {exit} /^scope:/ {sub(/^scope:[[:space:]]*/, ""); print; exit}' "$f")"
    [[ "$scope" == "$preset" ]] && printf 'refs/%s\n' "${f##*/}"
  done
  return 0
}

# 버전 갭이 실제 base 파일 차이로 이어졌는지 확증. patch bump가 base를 건드리지 않는
# 경우가 실제로 절반쯤 되므로(1.5.0→1.5.1: 0건, 반면 1.4.1→code-review.md, 1.2.1→
# git-convention.md, 1.1.4→4건) 버전 문자열만 비교하면 오탐이 난다. 이 확증은 버전
# 갭이 있을 때만 실행되므로 정상(=버전 일치) 경로에는 비용이 붙지 않는다.
# 원본 스냅샷(.claude/.devoks-base/)이 있으면 사본 대신 스냅샷과 비교한다 — 사본과의 차이는
# 로컬 커스터마이징일 수 있어서, upstream이 실제로 바뀌었는지는 "스냅샷 ≠ 번들"이어야 확정된다.
base_files_differ() {
  local root rel ref files=("${BASE_FILES[@]}")
  root="$(bundle_root)" || return 1
  while IFS= read -r rel; do
    [[ -n "$rel" ]] && files+=("$rel")
  done < <(scoped_ref_files "$root")
  for rel in "${files[@]}"; do
    [[ -f "$root/$rel" ]] || continue
    ref="$CLAUDE_DIR/.devoks-base/$rel"
    [[ -f "$ref" ]] || ref="$CLAUDE_DIR/$rel"
    cmp -s "$root/$rel" "$ref" || return 0
  done
  return 1
}

# JSON 단일 문자열에 들어가므로 큰따옴표·실제 개행 금지. 항목 구분은 리터럴 \n.
missing_mcp=""
missing_project=""
setup_steps=""
stale_setup=""
add_missing_mcp() { missing_mcp="${missing_mcp}${missing_mcp:+\n}$1"; }
add_missing_project() { missing_project="${missing_project}${missing_project:+\n}$1"; }
add_setup_step() { setup_steps="${setup_steps}${setup_steps:+\n}$1"; }
add_stale_setup() { stale_setup="${stale_setup}${stale_setup:+\n}$1"; }

have "context7"   || add_missing_mcp '- context7 (문서조회, 선택): 미설정 시 WebSearch 폴백. 설치: claude mcp add context7 --scope user -- npx -y @upstash/context7-mcp@latest'
have "serena"     || add_missing_mcp '- serena (코드 심볼탐색·리팩토링, 권장): 설치: /plugin install serena@claude-plugins-official (claude mcp add 금지 — PyPI serena 패키지명 충돌, 상세: /devoks-core:setup-mcp)'
have "codegraph"  || add_missing_mcp '- codegraph (코드그래프, 선택): 설치: npm install -g colbymchenry/codegraph && claude mcp add codegraph --scope user -- codegraph serve --mcp (상세: /devoks-core:setup-mcp)'
have "figma"      || add_missing_mcp '- figma (UI 구현·visual-diff 필수): 공식 Figma 플러그인 설치 → mcp__plugin_figma_figma__* 도구 제공'
have "playwright" || add_missing_mcp '- playwright (visual-diff 폴백 캡처, 선택): Playwright 플러그인 설치 → mcp__plugin_playwright_playwright__* 도구 제공'
# chrome-devtools-attach 는 user scope 에 직접 등록한다(devoks-browser 2.0.0 부터 플러그인 번들 없음).
# 예전엔 "devoks-browser" 문자열도 있음으로 봤지만, 번들이 사라진 뒤로는 플러그인 활성화가 서버 존재를
# 보장하지 않아 폴백을 뺐다. 구버전(1.x)이 번들 중이면 이중 등록되므로 setup-mcp Step 6 이 점검을 안내한다.
have "chrome-devtools" || add_missing_mcp '- chrome-devtools (visual-diff·data-verify 필수): /devoks-core:setup-mcp Step 6 실행 또는 claude mcp add chrome-devtools-attach --scope user -- npx chrome-devtools-mcp@latest --browserUrl http://127.0.0.1:9269 (devoks-browser 2.0.0 부터 플러그인 번들 없음. Node 22 이상 권장)'

# metro-devtools: RN 프로젝트에서 devoks-rn 스킬 사용 시 필요.
# Metro WebSocket device ID가 재시작마다 바뀌어 플러그인 번들·claude mcp add로 정적 등록 불가.
# 현재 프로젝트(또는 최대 3단계 하위)에 react-native가 있을 때만 경고한다.
_rn_detected=false
while IFS= read -r -d '' _pkg; do
  if grep -q '"react-native"' "$_pkg" 2>/dev/null; then
    _rn_detected=true
    break
  fi
done < <(find "${PROJECT_DIR}" -maxdepth 3 -name "package.json" -not -path "*/node_modules/*" -print0 2>/dev/null)
if $_rn_detected; then
  have "metro-devtools" || add_missing_mcp '- metro-devtools (RN JS 콘솔·상태 조회, devoks-rn 스킬 필요): /devoks-core:setup-mcp Step 5 실행 — devoks-rn 플러그인의 metro-mcp.js를 ~/.devoks/mcp/에 복사 후 user scope 등록 (Metro URL 자동 조회, 재시작 불필요)'
fi

# 두 경고가 같은 가드를 쓰므로 find 를 한 번만 돌린다.
_has_source=false
if have "serena" || have "codegraph"; then
  has_source_files && _has_source=true
fi

if have "serena" && $_has_source && ! serena_project_ready; then
  add_missing_project '- serena project: 현재 프로젝트에 .serena/project.yml 이 없습니다. 필요 시 Serena activate_project 또는 onboarding 흐름으로 프로젝트를 초기화하세요.'
fi

if have "codegraph" && $_has_source && ! codegraph_project_ready; then
  add_missing_project '- codegraph index: 현재 프로젝트에 유효한 .codegraph 인덱스가 없습니다. 초기화: codegraph init <프로젝트_절대경로>'
fi

if ! base_rules_ready || ! refs_ready || ! project_convention_ready; then
  add_setup_step '1. /devoks-core:setup-mcp — 권장 MCP 서버·의존성 설치/초기화'
  add_setup_step '2. /devoks-core:setup-project-convention — base rules/refs 적용 + stack preset 선택'
fi

# setup을 이미 거친 프로젝트만 대상 — 미완료면 위 setup_steps 안내가 이미 나간다.
# 버전 문자열이 다르고 && 실제 base 파일도 다를 때만 경고한다(오탐 차단, 상세: base_files_differ 주석).
if project_convention_ready; then
  _core_ver="$(installed_core_version)" || _core_ver=""
  _prov_ver="$(provenance_core_version)" || _prov_ver=""
  if [[ -n "$_core_ver" && "$_prov_ver" != "$_core_ver" ]] && base_files_differ; then
    add_stale_setup "- base rules/refs가 devoks-core ${_prov_ver:-미기록} 기준입니다 (현재 ${_core_ver}). /devoks-core:setup-preset-manage 로 base 갱신 권장 (preset 재선택 불필요, project-convention.md는 건드리지 않음)."
  fi
fi

# setup-mcp가 ~/.devoks에 복사한 스크립트도 플러그인 업데이트를 따라가지 않는다.
# 사본이 있을 때(=setup을 거쳤을 때)만 비교한다 — 없으면 설치 안내는 위 MCP 점검이 맡는다.
script_stale() { [[ -f "$1" && -f "$2" ]] && ! cmp -s "$1" "$2"; }
_root="$(bundle_root)" || _root=""
if [[ -n "$_root" ]]; then
  script_stale "$_root/assets/chrome-debug.sh" "$HOME/.devoks/bin/chrome-debug.sh" &&
    add_stale_setup "- ~/.devoks/bin/chrome-debug.sh 가 devoks-core 번들 런처와 다릅니다. /devoks-core:setup-preset-manage 로 갱신 권장."

  # devoks-rn은 다른 플러그인이라 CLAUDE_PLUGIN_ROOT로 닿지 않는다. 캐시 구조
  # (cache/<marketplace>/<plugin>/<version>/)상 같은 marketplace 아래 형제이고,
  # 저장소 직접 실행이면 plugins/ 아래 형제다. 버전 디렉토리가 여럿이면 최신만 본다.
  if [[ -f "$HOME/.devoks/mcp/metro-mcp.js" ]]; then
    _rn_src="$(ls -d "$_root"/../../devoks-rn/*/scripts/metro-mcp.js "$_root"/../devoks-rn/scripts/metro-mcp.js 2>/dev/null | sort -V | tail -1)"
    [[ -n "$_rn_src" ]] && script_stale "$_rn_src" "$HOME/.devoks/mcp/metro-mcp.js" &&
      add_stale_setup "- ~/.devoks/mcp/metro-mcp.js 가 설치된 devoks-rn 원본과 다릅니다. /devoks-core:setup-preset-manage 로 갱신 권장 (갱신 후 Claude Code 재시작)."
  fi
fi

# 누락 없으면 조용히 종료
[[ -z "$missing_mcp" && -z "$missing_project" && -z "$setup_steps" && -z "$stale_setup" ]] && exit 0

ctx='[DevOKs] 플러그인 설치 후 필요한 setup 상태를 확인했습니다. 관련 스킬·커맨드 사용 전 아래 안내를 우선 참고하세요.'

if [[ -n "$setup_steps" ]]; then
  ctx="${ctx}\n[설치 직후 권장 setup]\n${setup_steps}"
fi

if [[ -n "$missing_mcp" ]]; then
  ctx="${ctx}\n[MCP 서버 미감지]\n${missing_mcp}"
fi

if [[ -n "$missing_project" ]]; then
  ctx="${ctx}\n[프로젝트 초기화 미완료]\n${missing_project}"
fi

if [[ -n "$stale_setup" ]]; then
  ctx="${ctx}\n[setup 갱신 권장]\n${stale_setup}"
fi

# printf %s 는 백슬래시를 해석하지 않으므로 \n 이 그대로 JSON 이스케이프로 남는다.
printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$ctx"
exit 0
