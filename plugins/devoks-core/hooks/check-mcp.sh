#!/usr/bin/env bash
# check-mcp.sh — DevOks 권장 MCP 서버 설치 및 프로젝트 초기화 상태 점검
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

# JSON 단일 문자열에 들어가므로 큰따옴표·실제 개행 금지. 항목 구분은 리터럴 \n.
missing_mcp=""
missing_project=""
add_missing_mcp() { missing_mcp="${missing_mcp}${missing_mcp:+\n}$1"; }
add_missing_project() { missing_project="${missing_project}${missing_project:+\n}$1"; }

have "context7"   || add_missing_mcp '- context7 (문서조회, 선택): 미설정 시 WebSearch 폴백. 설치: claude mcp add context7 --scope user -- npx -y @upstash/context7-mcp@latest'
have "serena"     || add_missing_mcp '- serena (코드 심볼탐색·리팩토링, 권장): 설치: claude mcp add serena --scope user -- uvx serena@latest --project <프로젝트_절대경로>'
have "codegraph"  || add_missing_mcp '- codegraph (코드그래프, 선택): 설치: claude mcp add codegraph --scope user -- npx -y codegraph-mcp@latest'
have "figma"      || add_missing_mcp '- figma (UI 구현·visual-diff 필수): 공식 Figma 플러그인 설치 → mcp__plugin_figma_figma__* 도구 제공'
have "playwright" || add_missing_mcp '- playwright (visual-diff 폴백 캡처, 선택): Playwright 플러그인 설치 → mcp__plugin_playwright_playwright__* 도구 제공'
# chrome-devtools-attach 는 devoks-browser 플러그인이 번들한다. 직접 등록(~/.claude.json·project)이거나
# devoks-browser 플러그인 활성화 둘 중 하나면 "있음"으로 본다(둘 다 없을 때만 경고).
{ have "chrome-devtools" || have "devoks-browser"; } || add_missing_mcp '- chrome-devtools (visual-diff·data-verify 필수): devoks-browser 플러그인이 chrome-devtools-attach(:9269)를 번들 → /plugin install devoks-browser@devoks (claude mcp add 금지: 중복 인스턴스·포트 충돌)'

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
  have "metro-devtools" || add_missing_mcp '- metro-devtools (RN JS 콘솔·상태 조회, devoks-rn 스킬 필요): Metro WebSocket URL이 동적이라 플러그인 번들 불가 — ~/.claude.json에 직접 추가 필요. /devoks-setup-mcp 또는 devoks-rn:metro-devtools-attach 스킬 Step 2-0 참조'
fi

if have "serena" && ! serena_project_ready; then
  add_missing_project '- serena project: 현재 프로젝트에 .serena/project.yml 이 없습니다. 필요 시 Serena activate_project 또는 onboarding 흐름으로 프로젝트를 초기화하세요.'
fi

if have "codegraph" && ! codegraph_project_ready; then
  add_missing_project '- codegraph index: 현재 프로젝트에 유효한 .codegraph 인덱스가 없습니다. 초기화: codegraph init <프로젝트_절대경로>'
fi

# 누락 없으면 조용히 종료
[[ -z "$missing_mcp" && -z "$missing_project" ]] && exit 0

ctx='[DevOks] 권장 MCP 서버 및 프로젝트 초기화 상태를 확인했습니다. 관련 스킬·커맨드 사용 요청이 들어오면 아래 항목을 사용자에게 안내하세요(이미 처리돼 있다면 무시). 한 번에 설치하려면 /devoks-setup-mcp 커맨드를 안내하세요. 평소 대화에서는 먼저 언급하지 마세요.'

if [[ -n "$missing_mcp" ]]; then
  ctx="${ctx}\n[MCP 서버 미감지]\n${missing_mcp}"
fi

if [[ -n "$missing_project" ]]; then
  ctx="${ctx}\n[프로젝트 초기화 미완료]\n${missing_project}"
fi

# printf %s 는 백슬래시를 해석하지 않으므로 \n 이 그대로 JSON 이스케이프로 남는다.
printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$ctx"
exit 0
