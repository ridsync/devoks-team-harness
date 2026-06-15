#!/usr/bin/env bash
# setup.sh — DevOks Team Harness 폴백 동기화 스크립트
# 플러그인 시스템 없이 .claude/ 로 직접 파일을 복사할 때 사용.
#
# 사용법:
#   ./setup.sh              # 전체 설치
#   ./setup.sh --update     # git pull 후 재동기화
#   TARGET_DIR=/other/project ./setup.sh   # 다른 프로젝트에 설치

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -n "${TARGET_DIR:-}" ]]; then
  CLAUDE_DIR="$TARGET_DIR/.claude"
else
  CLAUDE_DIR="$(pwd)/.claude"
fi

echo "==> DevOks Team Harness 설치"
echo "    소스: $SCRIPT_DIR"
echo "    대상: $CLAUDE_DIR"
echo ""

if [[ "${1:-}" == "--update" ]]; then
  echo "[1/4] Git pull..."
  git -C "$SCRIPT_DIR" pull --ff-only
  echo ""
fi

mkdir -p \
  "$CLAUDE_DIR/commands" \
  "$CLAUDE_DIR/skills" \
  "$CLAUDE_DIR/rules" \
  "$CLAUDE_DIR/refs"

echo "[2/4] 파일 복사 중..."

echo "  rules/"
cp -f "$SCRIPT_DIR/shared/rules/"*.md "$CLAUDE_DIR/rules/"

echo "  refs/"
cp -f "$SCRIPT_DIR/shared/refs/"*.md "$CLAUDE_DIR/refs/"

echo "  commands/ (git)"
cp -f "$SCRIPT_DIR/plugins/devoks-git/commands/"*.md "$CLAUDE_DIR/commands/"

echo "  commands/ (feature)"
cp -f "$SCRIPT_DIR/plugins/devoks-feature/commands/"*.md "$CLAUDE_DIR/commands/"

echo "  commands/ (code)"
cp -f "$SCRIPT_DIR/plugins/devoks-code/commands/"*.md "$CLAUDE_DIR/commands/"

echo "  skills/ (feature)"
for skill_dir in "$SCRIPT_DIR/plugins/devoks-feature/skills/"/*/; do
  skill_name=$(basename "$skill_dir")
  mkdir -p "$CLAUDE_DIR/skills/$skill_name"
  cp -rf "$skill_dir"* "$CLAUDE_DIR/skills/$skill_name/" 2>/dev/null || true
done

echo "  skills/ (browser)"
for skill_dir in "$SCRIPT_DIR/plugins/devoks-browser/skills/"/*/; do
  skill_name=$(basename "$skill_dir")
  mkdir -p "$CLAUDE_DIR/skills/$skill_name"
  cp -rf "$skill_dir"* "$CLAUDE_DIR/skills/$skill_name/" 2>/dev/null || true
done

echo ""

# ──────────────────────────────────────────────────────────────
# [3/4] MCP 설정 및 .claude/settings.json 병합
# ──────────────────────────────────────────────────────────────
echo "[3/4] MCP 설정 및 권한 병합 중..."

GLOBAL_CLAUDE_JSON="$HOME/.claude.json"
PROJECT_SETTINGS_JSON="$CLAUDE_DIR/settings.json"

# python3 가용 여부 확인
if ! command -v python3 &>/dev/null; then
  echo "  ⚠  python3 가 없어 MCP 자동 설정을 건너뜁니다."
  echo "     수동으로 shared/setup/claude.json.template 을 참고해 ~/.claude.json 을 설정하세요."
  echo ""
else

# ── MCP required 항목을 ~/.claude.json 에 병합 ──────────────
merge_mcp_required() {
  local plugin_json="$1"
  python3 - "$plugin_json" "$GLOBAL_CLAUDE_JSON" <<'PYEOF'
import json, sys, os

plugin_path, target_path = sys.argv[1], sys.argv[2]

with open(plugin_path) as f:
  plugin = json.load(f)

required = plugin.get("mcpServers", {}).get("required", {})
if not required:
  sys.exit(0)

target = {}
if os.path.exists(target_path):
  with open(target_path) as f:
    try:
      target = json.load(f)
    except json.JSONDecodeError:
      target = {}

existing = target.setdefault("mcpServers", {})
added, skipped = [], []

for key, cfg in required.items():
  if key in existing:
    skipped.append(key)
  else:
    existing[key] = {k: v for k, v in cfg.items() if not k.startswith("_")}
    added.append(key)

with open(target_path, "w") as f:
  json.dump(target, f, ensure_ascii=False, indent=2)
  f.write("\n")

if added:
  print(f"    ✓  MCP 추가됨: {', '.join(added)}")
if skipped:
  print(f"    ↩  이미 존재 (건너뜀): {', '.join(skipped)}")
PYEOF
}

# ── MCP optional/interactive 안내 출력 ──────────────────────
print_mcp_optional() {
  local plugin_name="$1"
  local plugin_json="$2"
  python3 - "$plugin_name" "$plugin_json" <<'PYEOF'
import json, sys

plugin_name, plugin_path = sys.argv[1], sys.argv[2]

with open(plugin_path) as f:
  plugin = json.load(f)

mcp = plugin.get("mcpServers", {})
optional = mcp.get("optional", {})
interactive = mcp.get("interactive", {})

if optional:
  print(f"\n  [{plugin_name}] 선택적 MCP (직접 ~/.claude.json 에 추가 권장):")
  for key, cfg in optional.items():
    clean = {k: v for k, v in cfg.items() if not k.startswith("_")}
    print(f"    • {key}: {json.dumps(clean, ensure_ascii=False)}")

if interactive:
  print(f"\n  [{plugin_name}] 커스터마이징 필요 MCP (경로 등을 직접 수정 후 추가):")
  for key, cfg in interactive.items():
    note = cfg.get("_note", "")
    clean = {k: v for k, v in cfg.items() if not k.startswith("_")}
    print(f"    • {key}: {json.dumps(clean, ensure_ascii=False)}")
    if note:
      print(f"      ↳ {note}")
PYEOF
}

# ── settings.json permissions.allow 병합 ────────────────────
merge_settings_permissions() {
  local plugin_json="$1"
  python3 - "$plugin_json" "$PROJECT_SETTINGS_JSON" <<'PYEOF'
import json, sys, os

plugin_path, target_path = sys.argv[1], sys.argv[2]

with open(plugin_path) as f:
  plugin = json.load(f)

allow_entries = plugin.get("settings", {}).get("permissions", {}).get("allow", [])
if not allow_entries:
  sys.exit(0)

target = {}
if os.path.exists(target_path):
  with open(target_path) as f:
    try:
      target = json.load(f)
    except json.JSONDecodeError:
      target = {}

perms = target.setdefault("permissions", {})
existing_allow = perms.setdefault("allow", [])
added = [e for e in allow_entries if e not in existing_allow]
existing_allow.extend(added)

with open(target_path, "w") as f:
  json.dump(target, f, ensure_ascii=False, indent=2)
  f.write("\n")

if added:
  print(f"    ✓  settings.json 권한 추가됨: {', '.join(added)}")
PYEOF
}

# 플러그인 순서대로 처리
PLUGINS=(devoks-core devoks-git devoks-feature devoks-code devoks-browser)
OPTIONAL_HINTS=""

for plugin in "${PLUGINS[@]}"; do
  pjson="$SCRIPT_DIR/plugins/$plugin/.claude-plugin/plugin.json"
  [[ -f "$pjson" ]] || continue

  echo "  [$plugin]"
  merge_mcp_required "$pjson"
  merge_settings_permissions "$pjson"
  OPTIONAL_HINTS+="$(print_mcp_optional "$plugin" "$pjson")"$'\n'
done

# optional/interactive 안내를 마지막에 한 번에 출력
if [[ -n "${OPTIONAL_HINTS// /}" ]]; then
  echo ""
  echo "  ── 추가 MCP 안내 ────────────────────────────────────"
  echo "$OPTIONAL_HINTS"
fi

fi  # python3 가용 여부 분기 끝

echo ""

# ──────────────────────────────────────────────────────────────
# [4/4] CLAUDE.md 확인
# ──────────────────────────────────────────────────────────────
echo "[4/4] CLAUDE.md 확인..."

if [[ ! -f "$CLAUDE_DIR/CLAUDE.md" ]]; then
  echo "  ⚠  $CLAUDE_DIR/CLAUDE.md 가 없습니다."
  echo "     템플릿을 복사해 커스터마이징하세요:"
  echo "     cp '$SCRIPT_DIR/shared/templates/CLAUDE.md.project.template' '$CLAUDE_DIR/CLAUDE.md'"
else
  echo "  ✓  CLAUDE.md 존재 확인"
fi

echo ""
echo "✅ 완료!"
echo "   rules/    : $(ls "$CLAUDE_DIR/rules/" 2>/dev/null | wc -l | tr -d ' ')개 파일"
echo "   refs/     : $(ls "$CLAUDE_DIR/refs/" 2>/dev/null | wc -l | tr -d ' ')개 파일"
echo "   commands/ : $(ls "$CLAUDE_DIR/commands/" 2>/dev/null | wc -l | tr -d ' ')개 파일"
echo "   skills/   : $(ls "$CLAUDE_DIR/skills/" 2>/dev/null | wc -l | tr -d ' ')개 디렉토리"
echo "   MCP       : ~/.claude.json"
echo "   settings  : $CLAUDE_DIR/settings.json"
