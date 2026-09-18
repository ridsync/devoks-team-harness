#!/usr/bin/env bash
# setup.sh — DevOKs Team Harness 폴백 부트스트랩 스크립트
# 플러그인 시스템 없이 .claude/ 로 직접 파일을 복사할 때 사용.
# project convention preset은 자동 주입하지 않고, 설치 후 명시적으로 구성한다.
#
# 사용법:
#   ./setup.sh              # 전체 설치
#   ./setup.sh --update     # git pull 후 재설치
#   TARGET_DIR=/other/project ./setup.sh   # 다른 프로젝트에 설치
#
# ~/.claude.json(전역)에 MCP를 기입할 때는 목록을 보여주고 y/N 승인을 받는다(기본 N).
# 비대화형 실행(CI·파이프)에서는 무응답을 승인으로 보지 않고 건너뛴다.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -n "${TARGET_DIR:-}" ]]; then
  CLAUDE_DIR="$TARGET_DIR/.claude"
else
  CLAUDE_DIR="$(pwd)/.claude"
fi

echo "==> DevOKs Team Harness 설치"
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
  "$CLAUDE_DIR/agents" \
  "$CLAUDE_DIR/rules" \
  "$CLAUDE_DIR/refs"

echo "[2/4] 파일 복사 중..."

# 플러그인마다 보유한 디렉토리가 다르다(예: devoks-sdlc는 commands/ 없이 skills/+agents/,
# devoks-git은 commands/만). set -e 환경에서 glob이 매치되지 않으면 cp가 실패해 설치가
# 중간에 죽으므로, 디렉토리 존재를 먼저 확인하고 없으면 조용히 건너뛴다.
copy_flat() {
  local src="$1" dest="$2" label="$3"
  if ! compgen -G "$src/*.md" >/dev/null 2>&1; then
    return 0
  fi
  echo "  $label"
  cp -f "$src/"*.md "$dest/"
}

# 스킬은 디렉토리 단위(SKILL.md + references/ + evals/)로 통째 복사한다.
copy_skill_dirs() {
  local src="$1" label="$2" skill_dir skill_name
  [[ -d "$src" ]] || return 0
  compgen -G "$src/*/" >/dev/null 2>&1 || return 0
  echo "  $label"
  for skill_dir in "$src"/*/; do
    skill_name=$(basename "$skill_dir")
    mkdir -p "$CLAUDE_DIR/skills/$skill_name"
    cp -rf "$skill_dir." "$CLAUDE_DIR/skills/$skill_name/"
  done
}

echo "  rules/ (base)"
cp -f "$SCRIPT_DIR/plugins/devoks-core/rules/agent-principles.md" "$CLAUDE_DIR/rules/"
cp -f "$SCRIPT_DIR/plugins/devoks-core/rules/memory-policy.md" "$CLAUDE_DIR/rules/"

echo "  refs/"
cp -f "$SCRIPT_DIR/plugins/devoks-core/refs/"*.md "$CLAUDE_DIR/refs/"

# commands/·skills/·agents/ 를 플러그인 전체에 대해 일괄 처리한다. 플러그인을 새로
# 추가할 때 여기 목록만 늘리면 되고, 보유하지 않은 디렉토리는 헬퍼가 건너뛴다.
#
# devoks-sdlc-orchestration 은 의도적으로 제외한다. 이 헬퍼들은 commands/·agents/·skills/
# 만 복사하므로 플러그인 루트의 references/ 는 따라오지 않는데, orchestration-run 스킬은
# 그 자리의 orchestration-policy.md(deny-list·격리 allowlist·한도)를 실행 전제로 읽는다.
# 게다가 폴백 설치에는 ${CLAUDE_PLUGIN_ROOT} 가 없어 경로 자체가 해석되지 않는다.
# 비-HITL 파이프라인을 안전 가드 없이 반쪽 설치하느니 폴백 대상에서 빼고, 이 플러그인은
# 플러그인 설치 경로(/plugin install devoks-sdlc-orchestration@devoks-plugins)로만 쓴다.
ALL_PLUGINS=(devoks-core devoks-git devoks-sdlc devoks-browser devoks-rn)

for plugin in "${ALL_PLUGINS[@]}"; do
  plugin_root="$SCRIPT_DIR/plugins/$plugin"
  [[ -d "$plugin_root" ]] || continue
  copy_flat "$plugin_root/commands" "$CLAUDE_DIR/commands" "commands/ ($plugin)"
  copy_flat "$plugin_root/agents"   "$CLAUDE_DIR/agents"   "agents/ ($plugin)"
  copy_skill_dirs "$plugin_root/skills" "skills/ ($plugin)"
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

# ── ~/.claude.json MCP 기입 (제시 → 승인 → 실행) ────────────
# plugin.json 의 mcpServers 는 서버 이름을 최상위 키로 갖는 **플랫 맵**이다.
# required/optional/interactive 중첩 키는 plugin validate 에서 Invalid input 으로
# 떨어지므로 존재할 수 없다 — 과거 이 중첩 경로를 읽던 구현은 항상 no-op 였다.
#
# ~/.claude.json 은 사용자 전역 설정이므로 자동으로 쓰지 않는다. 추가될 서버 목록을
# 먼저 보여주고 y/N 승인을 받은 뒤에만 병합한다(기본 N). stdin 이 tty 가 아니면
# (CI·파이프) 무응답을 승인으로 해석하지 않고 건너뛰며 안내만 출력한다.

# 추가 후보만 계산한다(쓰지 않음). 출력 형식: "<plugin>\t<server>"
collect_mcp_candidates() {
  python3 - "$GLOBAL_CLAUDE_JSON" "$SCRIPT_DIR" "${ALL_PLUGINS[@]}" <<'PYEOF'
import json, os, sys

target_path, script_dir = sys.argv[1], sys.argv[2]
plugins = sys.argv[3:]

existing = {}
if os.path.exists(target_path):
  try:
    with open(target_path) as f:
      existing = json.load(f).get("mcpServers", {}) or {}
  except (json.JSONDecodeError, OSError):
    existing = {}

for plugin in plugins:
  pj = os.path.join(script_dir, "plugins", plugin, ".claude-plugin", "plugin.json")
  if not os.path.exists(pj):
    continue
  try:
    with open(pj) as f:
      servers = json.load(f).get("mcpServers", {}) or {}
  except (json.JSONDecodeError, OSError):
    continue
  for name in servers:
    if name.startswith("_") or name in existing:
      continue
    print(f"{plugin}\t{name}")
PYEOF
}

# 승인 후에만 호출된다. 기존 항목은 유지하고 병합하며, 임시 파일 + rename 으로
# 원자적으로 쓴다 — 쓰기 중 실패해도 원본이 그대로 남는다.
apply_mcp_merge() {
  python3 - "$GLOBAL_CLAUDE_JSON" "$SCRIPT_DIR" "${ALL_PLUGINS[@]}" <<'PYEOF'
import json, os, sys, tempfile

target_path, script_dir = sys.argv[1], sys.argv[2]
plugins = sys.argv[3:]

target = {}
if os.path.exists(target_path):
  with open(target_path) as f:
    try:
      target = json.load(f)
    except json.JSONDecodeError:
      # 파싱 불가 → 덮어쓰지 않고 중단한다(원본 보존).
      print("    \u2716  ~/.claude.json 을 파싱할 수 없어 기입을 중단했습니다 (원본 보존).")
      sys.exit(1)

servers = target.setdefault("mcpServers", {})
added = []

for plugin in plugins:
  pj = os.path.join(script_dir, "plugins", plugin, ".claude-plugin", "plugin.json")
  if not os.path.exists(pj):
    continue
  with open(pj) as f:
    bundled = json.load(f).get("mcpServers", {}) or {}
  for name, cfg in bundled.items():
    if name.startswith("_") or name in servers:
      continue
    servers[name] = {k: v for k, v in cfg.items() if not k.startswith("_")}
    added.append(name)

if not added:
  sys.exit(0)

d = os.path.dirname(target_path) or "."
fd, tmp = tempfile.mkstemp(dir=d, prefix=".claude.json.")
try:
  with os.fdopen(fd, "w") as f:
    json.dump(target, f, ensure_ascii=False, indent=2)
    f.write("\n")
  os.replace(tmp, target_path)
except Exception:
  if os.path.exists(tmp):
    os.unlink(tmp)
  raise

print(f"    \u2713  MCP 추가됨: {', '.join(added)}")
PYEOF
}

# ── settings.json permissions.allow 병합 (형태 가드) ─────────
# 무승인 병합은 "그 플러그인을 설치한 것 자체가 그 플러그인 도구에 대한 의사표시"라는
# 논리에 기댄다. 그 논리는 항목이 **특정 MCP 서버 네임스페이스로 한정**될 때만 성립한다.
# 지금 선언된 항목(mcp__chrome-devtools-attach__*, mcp__metro-devtools__*)이 narrow한 건
# 플러그인 작성자의 자제일 뿐 구조가 강제하는 게 아니므로, 형태로 판정해 강제한다.
#
#   mcp__<server>__...  → 무승인 병합 + 사후 출력 (server 는 비어있지 않은 구체적 이름)
#   그 외               → ~/.claude.json 과 동일한 승인 게이트
#
# 서버명이 없는 전역 와일드카드(mcp__*)는 다른 서버의 도구까지 열리므로 게이트 대상이다.

# 추가 후보를 분류만 한다(쓰지 않음). 출력: "<kind>\t<plugin>\t<entry>"  kind = mcp|other
collect_permission_candidates() {
  python3 - "$PROJECT_SETTINGS_JSON" "$SCRIPT_DIR" "${ALL_PLUGINS[@]}" <<'PYEOF'
import json, os, re, sys

target_path, script_dir = sys.argv[1], sys.argv[2]
plugins = sys.argv[3:]

# mcp__ + 구체적 서버명(와일드카드 아님) + (__ 이 이어지거나 거기서 끝남).
# mcp__<server> 는 "그 서버 전체 허용"이라는 유효한 표기이고 스코프가 mcp__<server>__* 와
# 같으므로, 넓은 쪽만 통과시키고 좁은 쪽을 막지 않도록 $ 종료도 허용한다.
# '*' 는 문자클래스에 없어서 mcp__* / mcp__** / mcp__<server>* 변형은 전부 게이트에 남는다.
SCOPED_MCP = re.compile(r"^mcp__[A-Za-z0-9._-]+(__|$)")

existing = []
if os.path.exists(target_path):
  try:
    with open(target_path) as f:
      existing = json.load(f).get("permissions", {}).get("allow", []) or []
  except (json.JSONDecodeError, OSError):
    existing = []

seen = set(existing)
for plugin in plugins:
  pj = os.path.join(script_dir, "plugins", plugin, ".claude-plugin", "plugin.json")
  if not os.path.exists(pj):
    continue
  try:
    with open(pj) as f:
      entries = json.load(f).get("settings", {}).get("permissions", {}).get("allow", []) or []
  except (json.JSONDecodeError, OSError):
    continue
  for e in entries:
    if not isinstance(e, str) or e in seen:
      continue
    seen.add(e)
    kind = "mcp" if SCOPED_MCP.match(e) else "other"
    print(f"{kind}\t{plugin}\t{e}")
PYEOF
}

# 인자로 받은 항목만 병합한다. 호출자가 kind 에 따라 승인 여부를 이미 판단했다.
apply_permission_merge() {
  [[ $# -gt 0 ]] || return 0
  python3 - "$PROJECT_SETTINGS_JSON" "$@" <<'PYEOF'
import json, os, sys, tempfile

target_path = sys.argv[1]
entries = sys.argv[2:]

target = {}
if os.path.exists(target_path):
  with open(target_path) as f:
    try:
      target = json.load(f)
    except json.JSONDecodeError:
      print("    \u2716  settings.json 을 파싱할 수 없어 권한 기입을 중단했습니다 (원본 보존).")
      sys.exit(1)

allow = target.setdefault("permissions", {}).setdefault("allow", [])
added = [e for e in entries if e not in allow]
if not added:
  sys.exit(0)
allow.extend(added)

d = os.path.dirname(target_path) or "."
os.makedirs(d, exist_ok=True)
fd, tmp = tempfile.mkstemp(dir=d, prefix=".settings.json.")
try:
  with os.fdopen(fd, "w") as f:
    json.dump(target, f, ensure_ascii=False, indent=2)
    f.write("\n")
  os.replace(tmp, target_path)
except Exception:
  if os.path.exists(tmp):
    os.unlink(tmp)
  raise

print(f"    \u2713  settings.json 권한 추가됨: {', '.join(added)}")
PYEOF
}

# 프로젝트 .claude/settings.json 권한 병합.
# mcp__<server>__ 한정 항목만 무승인(설치 자체가 그 플러그인 도구에 대한 의사표시).
# 범용 권한(Bash/Read/Edit/서버명 없는 와일드카드)이 섞이면 전역과 같은 승인 게이트를 태운다.
PERM_CANDIDATES="$(collect_permission_candidates)"
PERM_SCOPED=()
PERM_BROAD=()
PERM_BROAD_LABELS=()

if [[ -n "$PERM_CANDIDATES" ]]; then
  while IFS=$'\t' read -r _kind _plugin _entry; do
    [[ -n "$_entry" ]] || continue
    if [[ "$_kind" == "mcp" ]]; then
      PERM_SCOPED+=("$_entry")
    else
      PERM_BROAD+=("$_entry")
      PERM_BROAD_LABELS+=("$_entry  (제공: $_plugin)")
    fi
  done <<< "$PERM_CANDIDATES"
fi

if [[ ${#PERM_SCOPED[@]} -gt 0 ]]; then
  apply_permission_merge "${PERM_SCOPED[@]}" || echo "    ↩  권한 기입에 실패해 건너뜁니다."
fi

if [[ ${#PERM_BROAD[@]} -gt 0 ]]; then
  echo ""
  echo "  ⚠  아래 권한은 특정 MCP 서버로 한정되지 않아 별도 승인이 필요합니다:"
  for _label in "${PERM_BROAD_LABELS[@]}"; do
    echo "    • $_label"
  done
  echo "    대상: $PROJECT_SETTINGS_JSON"
  echo ""

  if [[ -t 0 ]]; then
    _pans=""
    read -r -p "  추가하시겠습니까? [y/N] " _pans || _pans=""
    case "$_pans" in
      [yY] | [yY][eE][sS])
        apply_permission_merge "${PERM_BROAD[@]}" || echo "    ↩  권한 기입에 실패해 건너뜁니다."
        ;;
      *)
        echo "    ↩  건너뜁니다. 필요하면 settings.json 에 직접 추가하세요."
        ;;
    esac
  else
    # 무응답을 승인으로 해석하지 않는다.
    echo "  ↩  비대화형 실행이라 범용 권한 기입을 건너뜁니다."
    echo "     대화형 셸에서 다시 실행하거나 settings.json 에 직접 추가하세요."
  fi
fi

# ~/.claude.json 은 전역이므로 제시 → 승인 → 실행.
MCP_CANDIDATES="$(collect_mcp_candidates)"

if [[ -z "$MCP_CANDIDATES" ]]; then
  echo "  ↩  ~/.claude.json: 추가할 MCP 서버 없음 (이미 등록됨 또는 번들 없음)"
else
  echo ""
  echo "  ~/.claude.json 에 아래 MCP 서버를 추가할 수 있습니다:"
  while IFS=$'\t' read -r _p _s; do
    [[ -n "$_s" ]] && echo "    • $_s  (제공: $_p)"
  done <<< "$MCP_CANDIDATES"
  echo "    대상: $GLOBAL_CLAUDE_JSON (전역 설정 — 기존 항목은 유지하고 병합합니다)"
  echo ""

  if [[ -t 0 ]]; then
    _ans=""
    read -r -p "  추가하시겠습니까? [y/N] " _ans || _ans=""
    case "$_ans" in
      [yY] | [yY][eE][sS])
        apply_mcp_merge || echo "    ↩  기입에 실패해 건너뜁니다."
        ;;
      *)
        echo "    ↩  건너뜁니다. 나중에 Claude에서 /setup-mcp 를 실행하세요."
        ;;
    esac
  else
    # 무응답을 승인으로 해석하지 않는다.
    echo "  ↩  비대화형 실행이라 기입을 건너뜁니다."
    echo "     대화형 셸에서 다시 실행하거나, Claude에서 /setup-mcp 를 사용하세요."
  fi
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

echo "  ⚠  project-convention preset은 자동 주입하지 않았습니다."
  echo "     설치 후 Claude에서 /setup-project-convention 을 실행해 스택 preset을 선택하세요."

echo ""
echo "✅ 완료!"
echo "   rules/    : $(ls "$CLAUDE_DIR/rules/" 2>/dev/null | wc -l | tr -d ' ')개 파일"
echo "   refs/     : $(ls "$CLAUDE_DIR/refs/" 2>/dev/null | wc -l | tr -d ' ')개 파일"
echo "   commands/ : $(ls "$CLAUDE_DIR/commands/" 2>/dev/null | wc -l | tr -d ' ')개 파일"
echo "   skills/   : $(ls "$CLAUDE_DIR/skills/" 2>/dev/null | wc -l | tr -d ' ')개 디렉토리"
echo "   agents/   : $(ls "$CLAUDE_DIR/agents/" 2>/dev/null | wc -l | tr -d ' ')개 파일"
echo "   MCP       : ~/.claude.json"
echo "   settings  : $CLAUDE_DIR/settings.json"
