#!/usr/bin/env bash
# selftest.sh — 가드 훅·local 어댑터·RUN 시작/종료 스크립트의 결정론적 스모크 테스트 (네트워크·LLM 불필요)
# usage: bash tests/selftest.sh   (임시 디렉터리에서 실행, 저장소를 건드리지 않는다)

set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GUARD="$ROOT/hooks/hotl-guard.sh"
ISSUE="$ROOT/scripts/hotl-issue.sh"
PASS=0; FAIL=0

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
export CLAUDE_PROJECT_DIR="$TMP"
mkdir -p "$TMP/.hotl"
echo '{"adapter":"local","base":"develop"}' >"$TMP/.hotl/config.json"

ok() { PASS=$((PASS + 1)); }
ng() { FAIL=$((FAIL + 1)); echo "FAIL: $*"; }

# guard <expect: allow|block> <tool> <field> <value>
guard() {
  local expect="$1" tool="$2" field="$3" value="$4" input rc
  input="$(jq -n --arg t "$tool" --arg f "$field" --arg v "$value" '{tool_name:$t, tool_input:{($f):$v}}')"
  DEVOKS_HOTL_RUN="${RUN_FLAG:-1}" bash "$GUARD" <<<"$input" >/dev/null 2>&1; rc=$?
  if [[ "$expect" == block && $rc -eq 2 ]] || [[ "$expect" == allow && $rc -eq 0 ]]; then ok; else ng "guard $expect($rc) $tool: $value"; fi
}

echo "== guard: 비활성 시 통과 =="
RUN_FLAG=0 guard allow Bash command "git push --force origin main"

echo "== guard: git =="
guard block Bash command "git push --force origin hotl/1-x"
guard block Bash command "git push -f origin hotl/1-x"
guard block Bash command "git push origin +hotl/1-x"
guard block Bash command "git push --force-with-lease"
guard block Bash command "git push origin main"
guard block Bash command "git push origin HEAD:master"
guard block Bash command "git push origin develop"
guard block Bash command "git push origin --delete hotl/1-x"
guard block Bash command "git push origin :hotl/1-x"
guard block Bash command "git commit --no-verify -m x"
guard block Bash command "git commit -nm x"
guard block Bash command "cd app && git push -u origin main"
guard allow Bash command "git push -u origin hotl/1-add-main-menu"
guard allow Bash command "git push origin HEAD:hotl/1-x"
guard allow Bash command "git push --follow-tags origin hotl/1-x"
guard allow Bash command "git commit -m 'fix: main page -n option'"
guard allow Bash command "git checkout main && git pull"

echo "== guard: 머지·게이트 위조 =="
guard block Bash command "gh pr merge 12 --squash"
guard block Bash command "gh pr ready 12"
guard block Bash command "gh issue edit 1 --add-label hotl:spec-approved"
guard block Bash command "gh label create hotl:approved"
guard block Bash command "bash scripts/hotl-issue.sh approve 1 hotl:approved"
guard block Bash command "bash \"\$R/scripts/hotl-issue.sh\" label-add 1 hotl:approved"
guard allow Bash command "bash \"\$R/scripts/hotl-issue.sh\" approval 1 hotl:spec-approved --after 2026-10-27T00:00:00Z"
guard allow Bash command "bash scripts/hotl-issue.sh label-rm 1 hotl:approved"
guard allow Bash command "bash scripts/hotl-issue.sh label-add 1 hotl:spec-review"
guard allow Bash command "I=\$R/scripts/hotl-issue.sh; bash \$I approval 1 hotl:spec-approved --after X"
guard allow Bash command "cat > .hotl/runs/1/reports/g.md <<'EOF'
승인: hotl:approved · 거절: hotl:rejected
EOF"
guard block Bash command "gh api repos/o/r/issues/1/labels -f 'labels[]=hotl:approved'"
guard block Bash command "bash \$I approve 1 hotl:approved"
guard allow Bash command "gh pr create --draft --base main --title x --body-file b.md"

echo "== guard: 시크릿·자기 권한 경로 =="
guard block Bash command "cat .env"
guard block Bash command "echo KEY=1 >> .env.local"
guard allow Bash command "cp .env.example .env.example.bak"
guard block Bash command "cat .hotl/local/issues/1.json"
guard block Bash command "rm -f .hotl/ACTIVE"
guard block Bash command "jq '.limits.fixLoops=9' .hotl/config.json > /tmp/c && mv /tmp/c .hotl/config.json"
guard allow Bash command "jq -r .base .hotl/config.json"
guard allow Bash command "cat \$P/references/policy.md; echo ---; cat .hotl/config.json; ls .hotl docs 2>/dev/null"
guard allow Bash command "bash \$I label-rm 1 hotl:spec-approved; bash \$I label-add 1 hotl:building"
guard block Bash command "echo '{}' > .hotl/config.json"
guard block Bash command "cat x >> .claude/settings.local.json"
guard block Bash command "bash \$I label-rm 1 hotl:spec-review; bash \$I label-add 1 hotl:approved"
guard block Write file_path "$TMP/.env"
guard block Edit file_path "$TMP/config/server.pem"
guard block Write file_path "$TMP/.hotl/config.json"
guard block Edit file_path "$TMP/.claude/settings.local.json"
guard allow Write file_path "$TMP/.env.example"
guard allow Write file_path "$TMP/src/app.ts"
guard allow Write file_path "$TMP/.hotl/runs/1-20261027-01/RUN.md"

echo "== local 어댑터 =="
export HOTL_ADAPTER=local
printf 'slugify 추가\n' >"$TMP/body.md"
n="$(bash "$ISSUE" local-new "slugify" "$TMP/body.md")"; [[ "$n" == 1 ]] && ok || ng "local-new → $n"
bash "$ISSUE" fetch 1 | jq -e '.title == "slugify"' >/dev/null && ok || ng "fetch"
bash "$ISSUE" label-add 1 hotl:spec-review && ok || ng "label-add bot label"
bash "$ISSUE" label-add 1 hotl:approved 2>/dev/null; [[ $? -eq 5 ]] && ok || ng "label-add human label must exit 5"
OPENED="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
bash "$ISSUE" approval 1 hotl:spec-approved --after "$OPENED" >/dev/null; [[ $? -eq 3 ]] && ok || ng "approval before approve must exit 3"
USER=hotl-bot bash "$ISSUE" approve 1 hotl:spec-approved 2>/dev/null; [[ $? -eq 5 ]] && ok || ng "approve as bot must exit 5"
USER=alice bash "$ISSUE" approve 1 hotl:spec-approved && ok || ng "approve as human"
bash "$ISSUE" approval 1 hotl:spec-approved --after "$OPENED" | jq -e '.actor == "alice"' >/dev/null && ok || ng "approval after approve"
bash "$ISSUE" approval 1 hotl:spec-approved --after "2999-01-01T00:00:00Z" >/dev/null; [[ $? -eq 3 ]] && ok || ng "stale approval must exit 3"
bash "$ISSUE" label-rm 1 hotl:spec-approved && ok || ng "label-rm"
bash "$ISSUE" approval 1 hotl:spec-approved >/dev/null; [[ $? -eq 3 ]] && ok || ng "consumed approval must exit 3"
printf 'gate\n' >"$TMP/c.md"; bash "$ISSUE" comment 1 "$TMP/c.md" >/dev/null && ok || ng "comment"
bash "$ISSUE" comments 1 | jq -e 'length == 1' >/dev/null && ok || ng "comments"
bash "$ISSUE" pr-draft hotl/1-x main "feat: x" "$TMP/c.md" | grep -q '^local://prs/' && ok || ng "pr-draft"
HOTL_ADAPTER=linear bash "$ISSUE" whoami 2>/dev/null; [[ $? -eq 7 ]] && ok || ng "linear must exit 7"

echo "== RUN 시작/종료 =="
bash "$ROOT/scripts/hotl-run-start.sh" 1-20261027-01 >/dev/null && [[ -f "$TMP/.hotl/ACTIVE" ]] && ok || ng "run-start"
bash "$ROOT/scripts/hotl-run-start.sh" 1-20261027-02 >/dev/null 2>&1; [[ $? -eq 4 ]] && ok || ng "run-start twice must exit 4"
RUN_FLAG=0 guard block Bash command "git push --force origin hotl/1-x"   # ACTIVE 파일만으로 가드 활성
bash "$ROOT/scripts/hotl-run-end.sh" >/dev/null && [[ ! -f "$TMP/.hotl/ACTIVE" ]] && ok || ng "run-end"

echo "== dev server·실동작 락 =="
DS="$ROOT/scripts/hotl-devserver.sh"
if command -v python3 >/dev/null 2>&1; then
  W1="$(mktemp -d)"; W2="$(mktemp -d)"; LOCKDIR="$(mktemp -d)"
  for w in "$W1" "$W2"; do
    git -C "$w" init -q; mkdir -p "$w/.hotl"
    echo '{"verify":{"acceptance":{"devServer":{"command":"python3 -m http.server {port} --bind 127.0.0.1","portRange":[5390,5399],"readyTimeoutSec":15,"lockTimeoutSec":1}}}}' >"$w/.hotl/config.json"
  done
  export HOTL_LIVE_LOCK="$LOCKDIR/hotl-live.lock"   # 두 임시 저장소가 같은 기기 락을 공유하는 상황을 재현
  U1="$(CLAUDE_PROJECT_DIR="$W1" bash "$DS" start r1)" && curl -sf -o /dev/null "$U1" && ok || ng "devserver start/reach"
  CLAUDE_PROJECT_DIR="$W2" bash "$DS" start r2 >/dev/null 2>&1; [[ $? -eq 3 ]] && ok || ng "second RUN must wait→exit 3"
  CLAUDE_PROJECT_DIR="$W1" bash "$ROOT/scripts/hotl-run-end.sh" >/dev/null   # run-end가 서버·락을 정리하는지
  ! curl -sf -o /dev/null "$U1" 2>/dev/null && [[ ! -d "$HOTL_LIVE_LOCK" ]] && ok || ng "run-end must stop server and release lock"
  U2="$(CLAUDE_PROJECT_DIR="$W2" bash "$DS" start r2)" && ok || ng "lock reacquire"
  kill -KILL "$(cat "$W2/.hotl/devserver/pid")" 2>/dev/null; sleep 0.5   # 비정상 종료로 락 잔재
  U3="$(CLAUDE_PROJECT_DIR="$W1" bash "$DS" start r3 2>/dev/null)" && ok || ng "stale lock recovery"
  CLAUDE_PROJECT_DIR="$W1" bash "$DS" stop >/dev/null; CLAUDE_PROJECT_DIR="$W2" bash "$DS" stop >/dev/null
  unset HOTL_LIVE_LOCK; rm -rf "$W1" "$W2" "$LOCKDIR"
else
  echo "(python3 없음 — dev server 테스트 생략)"
fi

echo
echo "selftest: PASS=$PASS FAIL=$FAIL"
[[ $FAIL -eq 0 ]]
