#!/usr/bin/env bash
# hotl-run-start.sh <run-id> — RUN 가드를 켠다(.hotl/ACTIVE 생성)
#
# 가드(hotl-guard.sh)는 RUN 중 .hotl/ACTIVE에 대한 셸 쓰기를 차단한다. RUN이 스스로 가드를
# 끄지 못하게 하려는 것이므로, 켜고 끄는 일은 이 스크립트와 hotl-run-end.sh만 한다.

set -euo pipefail
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
[[ $# -eq 1 && "$1" =~ ^[0-9A-Za-z._-]+$ ]] || { echo "usage: hotl-run-start.sh <run-id>" >&2; exit 2; }
[[ -f "$PROJECT_DIR/.hotl/config.json" ]] || { echo "hotl: .hotl/config.json 없음 — hotl-setup을 먼저 실행하세요" >&2; exit 3; }
if [[ -f "$PROJECT_DIR/.hotl/ACTIVE" ]]; then
  echo "hotl: 이미 활성 RUN이 있습니다: $(cat "$PROJECT_DIR/.hotl/ACTIVE") — 비정상 종료 잔재라면 사람이 hotl-run-end.sh로 정리하세요" >&2
  exit 4
fi
printf '%s %s\n' "$1" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >"$PROJECT_DIR/.hotl/ACTIVE"
echo "hotl: RUN $1 가드 활성화"
