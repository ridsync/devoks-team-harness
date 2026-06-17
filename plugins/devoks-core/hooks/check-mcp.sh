#!/usr/bin/env bash
# check-mcp.sh — DevOks 권장 MCP 서버 설치 여부 점검 + 가이드
#
# SessionStart 훅으로 실행. devoks 플러그인은 범용·공유 MCP(context7·figma·
# serena·codegraph·playwright)를 번들하지 않는다(플러그인별 중복 인스턴스·
# user 로컬 MCP와의 충돌 방지). 대신 사용자 scope(user/project)에 1회 설치한
# 단일 서버에 의존한다. 이 훅은 그 서버들이 설정돼 있는지 확인하고, 누락된
# 항목만 additionalContext로 안내한다.
#
# 특성: 멱등·빠름·non-blocking(항상 exit 0). 설치를 강제하지 않으며, 모두
# 설정돼 있으면 아무것도 출력하지 않는다.
#
# 환경변수 (Claude Code 자동 주입):
#   CLAUDE_PROJECT_DIR  — 프로젝트 루트

set -uo pipefail

USER_CFG="${HOME}/.claude.json"
PROJ_MCP="${CLAUDE_PROJECT_DIR:-.}/.mcp.json"

# user 설정(mcpServers·enabledPlugins)과 project .mcp.json 에서 토큰 존재 여부 확인.
# 휴리스틱: 토큰이 보이면 "설정됨"으로 간주(거짓음성=경고 누락, 거짓양성=경고 안 뜸 — 둘 다 저비용).
have() {
  local token="$1"
  { [[ -f "$USER_CFG" ]] && grep -qi "$token" "$USER_CFG"; } && return 0
  { [[ -f "$PROJ_MCP" ]] && grep -qi "$token" "$PROJ_MCP"; } && return 0
  return 1
}

# JSON 단일 문자열에 들어가므로 큰따옴표·실제 개행 금지. 항목 구분은 리터럴 \n.
missing=""
add_missing() { missing="${missing}${missing:+\\n}$1"; }

have "context7"   || add_missing '- context7 (문서조회, 선택): 미설정 시 WebSearch 폴백. 설치: claude mcp add context7 --scope user -- npx -y @upstash/context7-mcp@latest'
have "serena"     || add_missing '- serena (코드 심볼탐색·리팩토링, 권장): 설치: claude mcp add serena --scope user -- uvx serena@latest --project <프로젝트_절대경로>'
have "codegraph"  || add_missing '- codegraph (코드그래프, 선택): 설치: claude mcp add codegraph --scope user -- npx -y codegraph-mcp@latest'
have "figma"      || add_missing '- figma (UI 구현·visual-diff 필수): 공식 Figma 플러그인 설치 → mcp__plugin_figma_figma__* 도구 제공'
have "playwright" || add_missing '- playwright (visual-diff 폴백 캡처, 선택): Playwright 플러그인 설치 → mcp__plugin_playwright_playwright__* 도구 제공'

# 누락 없으면 조용히 종료
[[ -z "$missing" ]] && exit 0

ctx="[DevOks] 일부 권장 MCP 서버가 감지되지 않았습니다. 사용자(user/project) scope에 1회만 설치하면 됩니다. 관련 스킬·커맨드 사용 요청이 들어오면 아래 항목을 사용자에게 안내하세요(이미 설정돼 있다면 무시). 평소 대화에서는 먼저 언급하지 마세요.\\n${missing}"

# printf %s 는 백슬래시를 해석하지 않으므로 \n 이 그대로 JSON 이스케이프로 남는다.
printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$ctx"
exit 0
