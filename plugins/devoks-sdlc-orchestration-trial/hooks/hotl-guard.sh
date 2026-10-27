#!/usr/bin/env bash
# hotl-guard.sh — HOTL RUN 중 금지 액션을 결정론적으로 차단하는 PreToolUse 훅
#
# 왜 훅인가: 정책 문서(policy.md §3)만으로는 모델이 실수로 force-push·게이트 라벨 위조를
# 할 수 있다. 설계 원칙("환경층 격리 먼저, 모델층 유도 나중")에 따라 되돌릴 수 없는 액션은
# 도구 호출 단계에서 막는다. 단 문자열 패턴 판정이라 우회(변수 치환·스크립트 경유)는 못 막는다
# — CI에서는 토큰 권한·브랜치 보호가 진짜 경계이고, 이 훅은 실수 방지 층이다.
#
# 활성 조건: DEVOKS_HOTL_RUN=1 또는 <project>/.hotl/ACTIVE 존재. 플러그인 훅은 플러그인이
# 켜진 모든 세션에서 실행되므로, RUN이 아닐 때는 즉시 통과시켜 일반 세션에 영향을 주지 않는다.
#
# 판정: 차단 시 exit 2 + stderr(Claude에 사유 전달). 통과 시 exit 0.

set -uo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
if [[ "${DEVOKS_HOTL_RUN:-}" != "1" && ! -f "$PROJECT_DIR/.hotl/ACTIVE" ]]; then
  exit 0
fi

block() {
  echo "HOTL guard: $1 — policy.md §3에 따라 RUN이 수행할 수 없습니다. 필요하면 게이트를 열거나 사람에게 넘기세요." >&2
  exit 2
}

INPUT="$(cat)"

# RUN 중에는 판정 불가 상태로 통과시키지 않는다(fail-closed)
command -v jq >/dev/null 2>&1 || block "jq 미설치로 안전 판정 불가"

TOOL="$(jq -r '.tool_name // empty' <<<"$INPUT")"
HUMAN_LABEL_RE='hotl:(spec-approved|spec-revise|approved|rejected)'

BASE_BRANCH=""
[[ -f "$PROJECT_DIR/.hotl/config.json" ]] && BASE_BRANCH="$(jq -r '.base // empty' "$PROJECT_DIR/.hotl/config.json" 2>/dev/null)"
PROTECTED_RE="main|master${BASE_BRANCH:+|$BASE_BRANCH}"

# 시크릿·자기 권한 경로: RUN이 자기 정책(config)·승인 저장소(local)·권한 설정을 고치면 게이트가 무력화된다
is_protected_path() {
  local p="$1" b
  b="$(basename "$p")"
  case "$b" in
    .env.example|.env.sample|.env.template) return 1 ;;
    .env|.env.*|*.pem|*.key|*.p12|id_rsa*|id_ed25519*|credentials|credentials.*|.npmrc|.pypirc|.netrc) return 0 ;;
  esac
  [[ "$p" == *".hotl/config.json" || "$p" == *".hotl/local/"* || "$p" == *".hotl/ACTIVE" ]] && return 0
  [[ "$p" == *".claude/settings.json" || "$p" == *".claude/settings.local.json" ]] && return 0
  return 1
}

check_bash() {
  local cmd="$1" seg
  # ; && || | 로 이어진 명령을 조각별로 본다(조각 안에서만 플래그를 매칭해 오탐을 줄인다)
  local raw
  while IFS= read -r raw; do
    # 게이트 위조: 사람 전용 라벨을 "붙이는" 쓰기 동사만, 같은 조각 안에서만 막는다. 라벨명이 들어 있기만 한
    # 명령(승인 조회·라벨 제거·코멘트 본문)이나 `label-rm <사람 라벨>; label-add hotl:building`처럼 다른 조각의
    # 동사까지 묶어 막으면 RUN이 게이트를 처리할 수 없다(E2E에서 확인된 오탐 2건).
    if [[ "$raw" =~ $HUMAN_LABEL_RE && "$raw" =~ (--add-label|label[[:space:]]+(create|edit)|label-add|/labels) ]]; then
      block "사람 전용 게이트 라벨 부착·생성"
    fi
    # 자기 정책·권한 파일: 그 경로가 쓰기 대상일 때만 막는다(`cat .hotl/config.json 2>/dev/null`의 `>` 오탐 방지)
    if [[ "$raw" =~ [\>][\>]?[[:space:]]*[^[:space:]]*(\.hotl/(config\.json|ACTIVE)|\.claude/settings) ]]; then
      block "RUN 정책·권한 파일 수정"
    fi
    if [[ "$raw" =~ \.hotl/(config\.json|ACTIVE) || "$raw" =~ \.claude/settings ]] \
      && [[ "$raw" =~ (^|[[:space:]])(tee|mv|cp|rm|ln|truncate|sed[[:space:]]+-i|perl[[:space:]]+-[a-z]*i)([[:space:]]|$) ]]; then
      block "RUN 정책·권한 파일 수정"
    fi
    # 커밋 메시지 같은 따옴표 안 문자열은 플래그가 아니므로 지우고 판정한다
    seg="$(sed -E "s/'[^']*'//g; s/\"[^\"]*\"//g" <<<"$raw")"
    if [[ "$seg" =~ git[[:space:]].*push ]]; then
      [[ "$seg" =~ (--force|--force-with-lease|--mirror)([[:space:]=]|$) ]] && block "force push"
      [[ "$seg" =~ [[:space:]]-[a-zA-Z]*f([[:space:]]|$) ]] && block "force push(-f)"
      [[ "$seg" =~ [[:space:]]\+[^[:space:]]+ ]] && block "force push(+refspec)"
      [[ "$seg" =~ (--delete|[[:space:]]-d([[:space:]]|$)|[[:space:]]:[^[:space:]]+) ]] && block "원격 브랜치·태그 삭제"
      [[ "$seg" =~ [[:space:]:](${PROTECTED_RE})([[:space:]]|$) ]] && block "기본 브랜치로 push"
      [[ "$seg" =~ HEAD:(${PROTECTED_RE})([[:space:]]|$) ]] && block "기본 브랜치로 push"
    fi
    [[ "$seg" =~ git[[:space:]].*--no-verify ]] && block "--no-verify"
    [[ "$seg" =~ git[[:space:]]+commit.*[[:space:]]-[a-zA-Z]*n[a-zA-Z]*([[:space:]]|$) ]] && block "commit -n(--no-verify)"
    [[ "$seg" =~ gh[[:space:]]+pr[[:space:]]+(merge|ready) ]] && block "PR 머지·ready 전환"
    [[ "$seg" =~ gh[[:space:]]+api.*/merge([[:space:]\"\']|$) ]] && block "PR 머지(API)"
  done < <(sed -E 's/(\|\||&&|;|\|)/\n/g' <<<"$cmd")

  if [[ "$cmd" =~ (^|[[:space:]/\"])approve[[:space:]]+[0-9#] ]]; then
    block "local 승인 시뮬레이션(approve)은 사람 전용"
  fi

  # 시크릿 출력·승인 저장소 직접 접근
  if [[ "$cmd" =~ (^|[[:space:]/\'\"=])\.env(\.[A-Za-z0-9_-]+)?($|[[:space:]\'\"]) ]] && ! [[ "$cmd" =~ \.env\.(example|sample|template) ]]; then
    block ".env 파일 접근"
  fi
  [[ "$cmd" =~ \.hotl/local/ ]] && block ".hotl/local 직접 접근(어댑터 경유만 허용)"
  return 0
}

case "$TOOL" in
  Bash)
    check_bash "$(jq -r '.tool_input.command // empty' <<<"$INPUT")" ;;
  Write|Edit|MultiEdit|NotebookEdit)
    path="$(jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' <<<"$INPUT")"
    [[ -n "$path" ]] && is_protected_path "$path" && block "보호 경로 쓰기: $path" ;;
esac
exit 0
