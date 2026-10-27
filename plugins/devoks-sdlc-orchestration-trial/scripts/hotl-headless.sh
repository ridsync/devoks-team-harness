#!/usr/bin/env bash
# hotl-headless.sh — hotl-run을 무인(claude -p)으로 실행하는 로컬 래퍼
#
# usage: hotl-headless.sh <issue> [stage] [--adapter github|local] [--in-place]
#   stage: auto(기본) | spec | build | resume
#
# 하는 일:
#   1. 대상 프로젝트 안 .hotl/worktrees/<issue> 에 git worktree를 만들어 사용자의 작업트리와 격리한다
#      (--in-place면 현재 작업트리에서 실행 — CI처럼 이미 격리된 환경용).
#   2. DEVOKS_HOTL_RUN=1로 가드 훅을 켜고, .hotl/config.json의 limits로 --max-turns·--max-budget-usd를 건다.
#   3. --bare를 쓰지 않는다 — --bare는 플러그인 훅을 건너뛰어 가드가 꺼진다.
#
# 네트워크 차단 OS 샌드박스는 이 스크립트가 제공하지 않는다(설계 D2의 필수 전제 — 프로젝트·러너 쪽 책임).
#
# 환경변수:
#   HOTL_PERMISSION_MODE  기본 dontAsk(허용 목록 밖 도구는 자동 거부). bypassPermissions는 권하지 않는다.
#   HOTL_ALLOWED_TOOLS    기본 아래 DEFAULT_TOOLS
#   HOTL_CLAUDE_BIN       기본 claude

set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_TOOLS="Bash Read Edit Write Glob Grep Agent Skill ToolSearch TodoWrite mcp__chrome-devtools-attach__*"

usage() { sed -n '3,6p' "$0" >&2; exit 2; }
[[ $# -ge 1 ]] || usage

ISSUE="$1"; shift
STAGE="auto"; ADAPTER=""; IN_PLACE=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    auto|spec|build|resume) STAGE="$1" ;;
    --adapter) ADAPTER="${2:-}"; shift ;;
    --in-place) IN_PLACE=1 ;;
    *) usage ;;
  esac
  shift
done

PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "hotl: git 저장소 안에서 실행하세요" >&2; exit 2; }
CONFIG="$PROJECT_DIR/.hotl/config.json"
[[ -f "$CONFIG" ]] || { echo "hotl: $CONFIG 없음 — hotl-setup을 먼저 실행하세요" >&2; exit 3; }
command -v jq >/dev/null || { echo "hotl: jq 필요" >&2; exit 3; }

ADAPTER="${ADAPTER:-$(jq -r '.adapter // "github"' "$CONFIG")}"
BASE="$(jq -r '.base // "main"' "$CONFIG")"
MAX_TURNS="$(jq -r '.limits.maxTurns // 120' "$CONFIG")"
BUDGET="$(jq -r '.limits.budgetUsd // 15' "$CONFIG")"
ISSUE_NUM="$(grep -oE '[0-9]+$' <<<"$ISSUE" || true)"
[[ -n "$ISSUE_NUM" ]] || { echo "hotl: 이슈 번호를 해석할 수 없습니다: $ISSUE" >&2; exit 2; }

RUN_DIR="$PROJECT_DIR"
if [[ $IN_PLACE -eq 0 ]]; then
  RUN_DIR="$PROJECT_DIR/.hotl/worktrees/$ISSUE_NUM"
  if [[ ! -d "$RUN_DIR" ]]; then
    # 같은 이슈의 작업 브랜치가 이미 있으면(재개) 그 브랜치로, 없으면 base에서 detached로 시작한다
    BR="$(git -C "$PROJECT_DIR" for-each-ref --format='%(refname:short)' "refs/heads/hotl/$ISSUE_NUM-*" | head -1)"
    if [[ -z "$BR" ]]; then
      git -C "$PROJECT_DIR" fetch -q origin 2>/dev/null || true
      RBR="$(git -C "$PROJECT_DIR" for-each-ref --format='%(refname:short)' "refs/remotes/origin/hotl/$ISSUE_NUM-*" | head -1)"
      [[ -n "$RBR" ]] && BR="${RBR#origin/}" && git -C "$PROJECT_DIR" branch -q "$BR" "$RBR"
    fi
    if [[ -n "$BR" ]]; then
      git -C "$PROJECT_DIR" worktree add -q "$RUN_DIR" "$BR"
    else
      git -C "$PROJECT_DIR" worktree add -q --detach "$RUN_DIR" "$BASE"
    fi
  fi
  # config가 아직 커밋되지 않은 경우를 위해 원 작업트리의 설정을 복사한다
  mkdir -p "$RUN_DIR/.hotl"
  [[ -f "$RUN_DIR/.hotl/config.json" ]] || cp "$CONFIG" "$RUN_DIR/.hotl/config.json"
fi

LOG_DIR="$PROJECT_DIR/.hotl/logs"; mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/$ISSUE_NUM-$(date -u +%Y%m%dT%H%M%SZ).json"

# RUN이 비정상 종료(턴·예산 상한 포함)해도 가드·dev server·실동작 락을 남기지 않는다
cleanup() { CLAUDE_PROJECT_DIR="$RUN_DIR" bash "$PLUGIN_ROOT/scripts/hotl-run-end.sh" >/dev/null 2>&1 || rm -f "$RUN_DIR/.hotl/ACTIVE"; }
trap cleanup EXIT

PROMPT="/devoks-sdlc-orchestration-trial:hotl-run issue=$ISSUE stage=$STAGE"
echo "hotl: $PROMPT  (dir=$RUN_DIR, adapter=$ADAPTER, max-turns=$MAX_TURNS, budget=\$$BUDGET)"

STATUS=0
# shellcheck disable=SC2086
(cd "$RUN_DIR" && \
  DEVOKS_HOTL_RUN=1 HOTL_ADAPTER="$ADAPTER" HOTL_LOCAL_ROOT="$PROJECT_DIR/.hotl/local" \
  "${HOTL_CLAUDE_BIN:-claude}" -p "$PROMPT" \
    --plugin-dir "$PLUGIN_ROOT" \
    --permission-mode "${HOTL_PERMISSION_MODE:-dontAsk}" \
    --allowedTools ${HOTL_ALLOWED_TOOLS:-$DEFAULT_TOOLS} \
    --max-turns "$MAX_TURNS" \
    --max-budget-usd "$BUDGET" \
    --output-format json) >"$LOG" || STATUS=$?

jq -r '"hotl: 종료 subtype=\(.subtype // "-") turns=\(.num_turns // "-") cost=$\(.total_cost_usd // "-")\n\(.result // "")"' "$LOG" 2>/dev/null || cat "$LOG"
echo "hotl: 로그 $LOG"
exit $STATUS
