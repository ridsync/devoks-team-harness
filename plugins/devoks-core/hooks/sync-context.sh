#!/usr/bin/env bash
# sync-context.sh — DevOks Core 원칙·참조 문서 동기화
#
# SessionStart 훅으로 실행. 번들된 rules/·refs/ 를 프로젝트 .claude/ 로 복사한다.
# 정책: 플러그인 번들이 rules/refs 의 SSOT. 변경분이 있으면 프로젝트 사본을 덮어써
#       항상 번들과 동기 상태를 유지한다. 복사만 수행하므로 동기화 대상이 아닌
#       프로젝트 고유 파일(예: pitfalls.md)에는 관여하지 않는다.
#       .gitignore 에는 손대지 않는다 → 프로젝트가 이 파일들을 git 으로 추적·커밋한다.
# 특성: 멱등·빠름 (변경분만 복사). 실패해도 세션을 막지 않는다.
#
# 환경변수 (Claude Code 자동 주입):
#   CLAUDE_PLUGIN_ROOT  — 이 플러그인의 설치 경로
#   CLAUDE_PROJECT_DIR  — 프로젝트 루트

set -uo pipefail

SRC="${CLAUDE_PLUGIN_ROOT:-}"
DEST="${CLAUDE_PROJECT_DIR:-.}/.claude"

# 플러그인 루트가 없으면 조용히 종료
if [[ -z "$SRC" || ! -d "$SRC" ]]; then
  exit 0
fi

mkdir -p "$DEST/rules" "$DEST/refs"

# ── rules 동기화 ──────────────────────────────────────────────
for src_file in "$SRC"/rules/*.md; do
  [[ -e "$src_file" ]] || continue
  dst_file="$DEST/rules/$(basename "$src_file")"
  if [[ ! -e "$dst_file" ]] || ! cmp -s "$src_file" "$dst_file"; then
    cp -f "$src_file" "$dst_file"
  fi
done

# ── refs 동기화 ───────────────────────────────────────────────
for src_file in "$SRC"/refs/*.md; do
  [[ -e "$src_file" ]] || continue
  dst_file="$DEST/refs/$(basename "$src_file")"
  if [[ ! -e "$dst_file" ]] || ! cmp -s "$src_file" "$dst_file"; then
    cp -f "$src_file" "$dst_file"
  fi
done

exit 0
