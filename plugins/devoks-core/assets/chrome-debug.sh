#!/usr/bin/env bash
# chrome-debug.sh — chrome-devtools-attach(:9269) 전용 Chrome 실행기
#
# 포트와 user-data-dir은 devoks-browser 번들이 attach 대상으로 기대하는 값이라 고정이다.
# 전용 user-data-dir을 쓰는 이유: 평소 프로필로 디버그 포트를 열면 이미 떠 있는
# Chrome 인스턴스에 흡수돼 포트가 열리지 않는다.
# 기본 시작 URL은 이 파일이 아니라 ~/.devoks/chrome-debug.url 에 둔다 — 스크립트를 번들 원본과
# 바이트 동일하게 유지해야 devoks-core:setup-preset-manage가 업데이트 여부를 cmp로 판정할 수 있다.
set -euo pipefail

PORT=9269
USER_DATA_DIR="$HOME/.claude/chrome-dev-mcp"
URL_FILE="$HOME/.devoks/chrome-debug.url"
START_URL="${1:-$(cat "$URL_FILE" 2>/dev/null || true)}"

if [[ -z "$START_URL" ]]; then
  echo "시작 URL이 없습니다. 인자로 주거나 ${URL_FILE} 에 기본 URL을 한 줄로 저장하세요." >&2
  exit 1
fi

# 이미 떠 있으면 재실행하지 않는다 — 같은 포트에 두 인스턴스가 붙으면 attach가 충돌한다.
if curl -sf -m 2 "http://127.0.0.1:${PORT}/json/version" >/dev/null 2>&1; then
  echo "이미 :${PORT} 에서 디버그 모드로 실행 중입니다."
  exit 0
fi

case "$(uname -s)" in
  Darwin) CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ;;
  Linux)  CHROME="$(command -v google-chrome || command -v chromium || true)" ;;
  *)      echo "지원하지 않는 OS: $(uname -s)" >&2; exit 1 ;;
esac

if [[ -z "${CHROME:-}" || ! -x "$CHROME" ]]; then
  echo "Chrome 실행 파일을 찾지 못했습니다: ${CHROME:-<없음>}" >&2
  exit 1
fi

mkdir -p "$USER_DATA_DIR"
"$CHROME" \
  --remote-debugging-port="$PORT" \
  --user-data-dir="$USER_DATA_DIR" \
  "$START_URL" >/dev/null 2>&1 &

echo "Chrome 디버그 모드 실행: :${PORT} → ${START_URL}"
