#!/usr/bin/env bash
# hotl-devserver.sh — 실동작 검증(verify 게이트 5) 전용 worktree dev server 기동·종료 + 실동작 락
#
# usage: hotl-devserver.sh start <run-id> | stop | status
#
# 왜 필요한가: 설정에 고정 URL을 두면 사람이 띄워 둔 메인 작업트리의 서버를 검사하게 되어,
# worktree에서 만든 RUN의 코드가 아니라 엉뚱한 코드를 검증한다. 그래서 이 단계에 한해 RUN이
# 자기 worktree에서 서버를 띄운다(2026-10-27 사용자 결정 (a)). 그 외 시점의 dev server 기동은 정책상 금지.
#
# 실동작 락: Chrome(9269 attach)·에뮬레이터·실기기는 기기당 하나라 여러 RUN이 동시에 쓰면 서로의
# 조작이 섞인다. worktree들이 공유하는 git 공통 디렉터리에 mkdir 락을 두어 한 번에 한 RUN만 쓰게 한다.
# 락 주인은 서버 프로세스 그룹이고, 그 프로세스가 죽어 있으면 잔재로 보고 회수한다.
#
# 설정(.hotl/config.json → verify.acceptance.devServer):
#   command          "{port}" 자리표시자 포함 기동 명령 (PORT 환경변수도 함께 export)
#   host             기본 127.0.0.1
#   portRange        [시작, 끝] 기본 [5300, 5399]
#   readyPath        기본 "/"
#   readyTimeoutSec  기본 90
#   lockTimeoutSec   기본 300 (호출 측 Bash timeout을 이보다 길게 줄 것)
#
# 종료코드: 0 성공, 2 사용법, 3 락 대기 초과, 4 기동·준비 실패, 5 설정 없음

set -uo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
CONFIG="$PROJECT_DIR/.hotl/config.json"
STATE_DIR="$PROJECT_DIR/.hotl/devserver"

die() { echo "hotl-devserver: $2" >&2; exit "$1"; }
command -v jq >/dev/null 2>&1 || die 5 "jq가 필요합니다"
[[ -f "$CONFIG" ]] || die 5 "$CONFIG 없음"

cfg() { jq -r "$1 // empty" "$CONFIG"; }
CMD="$(cfg '.verify.acceptance.devServer.command')"
HOST="$(cfg '.verify.acceptance.devServer.host')"; HOST="${HOST:-127.0.0.1}"
PORT_FROM="$(cfg '.verify.acceptance.devServer.portRange[0]')"; PORT_FROM="${PORT_FROM:-5300}"
PORT_TO="$(cfg '.verify.acceptance.devServer.portRange[1]')"; PORT_TO="${PORT_TO:-5399}"
READY_PATH="$(cfg '.verify.acceptance.devServer.readyPath')"; READY_PATH="${READY_PATH:-/}"
READY_TIMEOUT="$(cfg '.verify.acceptance.devServer.readyTimeoutSec')"; READY_TIMEOUT="${READY_TIMEOUT:-90}"
LOCK_TIMEOUT="$(cfg '.verify.acceptance.devServer.lockTimeoutSec')"; LOCK_TIMEOUT="${LOCK_TIMEOUT:-300}"

COMMON_DIR="$(git -C "$PROJECT_DIR" rev-parse --git-common-dir 2>/dev/null)" || die 5 "git 저장소가 아닙니다"
[[ "$COMMON_DIR" = /* ]] || COMMON_DIR="$PROJECT_DIR/$COMMON_DIR"
LOCK="${HOTL_LIVE_LOCK:-$COMMON_DIR/hotl-live.lock}"

alive() { [[ -n "${1:-}" ]] && kill -0 "$1" 2>/dev/null; }
port_busy() { (exec 3<>"/dev/tcp/$HOST/$1") 2>/dev/null; }

lock_acquire() { # $1 = run-id
  local waited=0 owner
  while ! mkdir "$LOCK" 2>/dev/null; do
    owner="$(awk '{print $2}' "$LOCK/owner" 2>/dev/null)"
    # 주인 프로세스가 없거나 아직 기록 전인데 오래됐으면 잔재로 회수
    if [[ -n "$owner" ]] && ! alive "$owner"; then
      echo "hotl-devserver: 잔재 락 회수($(cat "$LOCK/owner" 2>/dev/null))" >&2
      rm -rf "$LOCK"; continue
    fi
    (( waited >= LOCK_TIMEOUT )) && die 3 "실동작 락 대기 초과(${LOCK_TIMEOUT}s) — 주인: $(cat "$LOCK/owner" 2>/dev/null)"
    sleep 5; waited=$((waited + 5))
  done
  printf '%s %s %s\n' "$1" "$$" "$PROJECT_DIR" >"$LOCK/owner"
}

lock_release_if_mine() {
  [[ -d "$LOCK" ]] || return 0
  [[ "$(awk '{print $3}' "$LOCK/owner" 2>/dev/null)" == "$PROJECT_DIR" ]] && rm -rf "$LOCK"
  return 0
}

do_stop() {
  local pid
  pid="$(cat "$STATE_DIR/pid" 2>/dev/null)"
  if alive "$pid"; then
    # 서버는 자기 프로세스 그룹으로 띄웠으므로 그룹 전체를 끈다(npm → vite 같은 자식 포함)
    kill -TERM -- "-$pid" 2>/dev/null || kill -TERM "$pid" 2>/dev/null
    for _ in 1 2 3 4 5 6 7 8 9 10; do alive "$pid" || break; sleep 0.5; done
    alive "$pid" && { kill -KILL -- "-$pid" 2>/dev/null || kill -KILL "$pid" 2>/dev/null; }
  fi
  rm -f "$STATE_DIR/pid" "$STATE_DIR/port" "$STATE_DIR/url"
  lock_release_if_mine
  echo "hotl-devserver: 종료"
}

do_start() {
  local run_id="$1" port="" p pid url waited=0
  [[ -n "$CMD" ]] || die 5 "verify.acceptance.devServer.command 미설정"
  if alive "$(cat "$STATE_DIR/pid" 2>/dev/null)"; then
    cat "$STATE_DIR/url"; return 0
  fi
  lock_acquire "$run_id"
  for ((p = PORT_FROM; p <= PORT_TO; p++)); do
    port_busy "$p" || { port="$p"; break; }
  done
  [[ -n "$port" ]] || { lock_release_if_mine; die 4 "빈 포트 없음(${PORT_FROM}-${PORT_TO})"; }

  mkdir -p "$STATE_DIR"
  local cmd="${CMD//\{port\}/$port}"
  set -m   # 백그라운드 작업이 자기 프로세스 그룹(pgid = pid)을 갖게 해 종료 시 자식까지 정리한다
  (cd "$PROJECT_DIR" && PORT="$port" HOST="$HOST" exec bash -c "$cmd") >"$STATE_DIR/server.log" 2>&1 &
  pid=$!
  set +m
  echo "$pid" >"$STATE_DIR/pid"; echo "$port" >"$STATE_DIR/port"
  # 락 주인을 서버 프로세스로 바꿔, 이 스크립트가 끝나도 서버가 살아 있는 동안 락이 유지되게 한다
  printf '%s %s %s\n' "$run_id" "$pid" "$PROJECT_DIR" >"$LOCK/owner"

  url="http://$HOST:$port"
  until curl -sf -o /dev/null "$url$READY_PATH"; do
    if ! alive "$pid" || (( waited >= READY_TIMEOUT )); then
      echo "hotl-devserver: 준비 실패 — 로그 tail:" >&2; tail -5 "$STATE_DIR/server.log" >&2
      do_stop >/dev/null; exit 4
    fi
    sleep 1; waited=$((waited + 1))
  done
  echo "$url" >"$STATE_DIR/url"
  echo "$url"
}

case "${1:-}" in
  start) [[ $# -eq 2 && "$2" =~ ^[0-9A-Za-z._-]+$ ]] || die 2 "start <run-id>"; do_start "$2" ;;
  stop) do_stop ;;
  status)
    if alive "$(cat "$STATE_DIR/pid" 2>/dev/null)"; then echo "running $(cat "$STATE_DIR/url" 2>/dev/null)"; else echo "stopped"; fi
    [[ -d "$LOCK" ]] && echo "lock: $(cat "$LOCK/owner" 2>/dev/null)" || echo "lock: free" ;;
  *) die 2 "usage: hotl-devserver.sh start <run-id> | stop | status" ;;
esac
