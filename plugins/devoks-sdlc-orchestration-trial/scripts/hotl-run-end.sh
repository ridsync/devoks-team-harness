#!/usr/bin/env bash
# hotl-run-end.sh — RUN 가드를 끈다(.hotl/ACTIVE 제거). 게이트 정지·실패 종료에서도 반드시 호출한다.
set -euo pipefail
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
# 실동작 단계에서 띄운 dev server·실동작 락이 남으면 다른 RUN이 락을 기다리다 시간 초과되므로 함께 정리한다
if [[ -f "$PROJECT_DIR/.hotl/devserver/pid" ]]; then
  bash "$(dirname "${BASH_SOURCE[0]}")/hotl-devserver.sh" stop || true
fi
rm -f "$PROJECT_DIR/.hotl/ACTIVE"
echo "hotl: 가드 비활성화"
