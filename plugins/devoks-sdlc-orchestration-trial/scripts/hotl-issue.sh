#!/usr/bin/env bash
# hotl-issue.sh — HOTL 이슈 어댑터 (계약: references/adapter-contract.md)
#
# RUN은 이슈 시스템을 이 스크립트로만 다룬다. 백엔드를 바꿔도 스킬·파이프라인 문서가
# 바뀌지 않게 하려는 단일 지점이다. 게이트 위조 방지(사람 전용 라벨 거부)도 여기서 한 번 더 막는다
# — 훅(hotl-guard.sh)이 명령 문자열을 놓쳐도 어댑터 자체가 거부하도록 이중으로 둔다.
#
# 종료코드: 0 성공, 2 사용법, 3 승인 없음, 4 승인 actor 부적격, 5 정책 거부, 6 백엔드 오류, 7 미구현

set -uo pipefail

HUMAN_LABELS="hotl:spec-approved hotl:spec-revise hotl:approved hotl:rejected"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
CONFIG="$PROJECT_DIR/.hotl/config.json"
# 헤드리스 래퍼는 RUN을 별도 worktree에서 돌리므로, local 저장소는 원 작업트리 쪽을 가리키게 한다
LOCAL_ROOT="${HOTL_LOCAL_ROOT:-$PROJECT_DIR/.hotl/local}"
LOCAL_DIR="$LOCAL_ROOT/issues"

die() { echo "hotl-issue: $2" >&2; exit "$1"; }
now() { date -u +%Y-%m-%dT%H:%M:%SZ; }

command -v jq >/dev/null 2>&1 || die 6 "jq가 필요합니다"

ADAPTER="${HOTL_ADAPTER:-}"
if [[ -z "$ADAPTER" && -f "$CONFIG" ]]; then
  ADAPTER="$(jq -r '.adapter // empty' "$CONFIG")"
fi
ADAPTER="${ADAPTER:-github}"

is_human_label() {
  local l
  for l in $HUMAN_LABELS; do [[ "$1" == "$l" ]] && return 0; done
  return 1
}

check_label_name() {
  [[ "$1" =~ ^hotl:[a-z-]+$ ]] || die 2 "라벨명은 hotl:<소문자-하이픈> 형식이어야 합니다: $1"
}

# ── github ────────────────────────────────────────────────────────────────
# <issue>가 URL이면 owner/repo를 거기서, 번호면 현재 저장소에서 얻는다.
gh_ref() {
  command -v gh >/dev/null 2>&1 || die 6 "gh CLI가 필요합니다"
  if [[ "$1" =~ github\.com/([^/]+/[^/]+)/(issues|pull)/([0-9]+) ]]; then
    REPO="${BASH_REMATCH[1]}"; NUM="${BASH_REMATCH[3]}"
  elif [[ "$1" =~ ^#?([0-9]+)$ ]]; then
    NUM="${BASH_REMATCH[1]}"
    REPO="$(gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null)" || die 6 "현재 디렉터리에서 GitHub 저장소를 찾지 못했습니다"
  else
    die 2 "이슈 식별자를 해석할 수 없습니다: $1"
  fi
}

gh_cmd() {
  local cmd="$1"; shift
  case "$cmd" in
    whoami)
      gh api user --jq .login 2>/dev/null || die 6 "gh 인증 필요(gh auth status)" ;;
    fetch)
      gh_ref "$1"
      gh issue view "$NUM" -R "$REPO" --json number,title,body,url,labels \
        --jq '{number,title,body,url,labels:[.labels[].name]}' || die 6 "이슈 조회 실패" ;;
    comments)
      gh_ref "$1"; local after="${3:-}"
      gh api "repos/$REPO/issues/$NUM/comments" --paginate \
        --jq '.[] | {author:.user.login, body, created_at}' \
        | jq -s --arg a "$after" '[.[] | select($a == "" or .created_at > $a)]' ;;
    comment)
      gh_ref "$1"; [[ -s "${2:-}" ]] || die 2 "본문 파일이 없거나 비어 있습니다"
      gh issue comment "$NUM" -R "$REPO" --body-file "$2" ;;
    label-add)
      gh_ref "$1"; check_label_name "$2"
      is_human_label "$2" && die 5 "사람 전용 라벨은 RUN이 부착할 수 없습니다: $2"
      gh issue edit "$NUM" -R "$REPO" --add-label "$2" >/dev/null ;;
    label-rm)
      gh_ref "$1"; check_label_name "$2"
      gh issue edit "$NUM" -R "$REPO" --remove-label "$2" >/dev/null 2>&1 || true ;;
    approval)
      gh_ref "$1"; check_label_name "$2"; local after="${4:-}"
      local ev actor at perm me
      # --paginate + --jq는 페이지마다 출력하므로 마지막 줄이 가장 최근 이벤트다
      ev="$(gh api "repos/$REPO/issues/$NUM/events" --paginate \
        --jq ".[] | select(.event==\"labeled\" and .label.name==\"$2\") | {actor:.actor.login, at:.created_at}" | tail -1)"
      [[ -n "$ev" ]] || exit 3
      actor="$(jq -r .actor <<<"$ev")"; at="$(jq -r .at <<<"$ev")"
      [[ -z "$after" || "$at" > "$after" ]] || exit 3
      me="$(gh api user --jq .login 2>/dev/null)"
      [[ "$actor" != "$me" && "$actor" != *"[bot]" ]] || { echo "{\"actor\":\"$actor\",\"reason\":\"bot\"}"; exit 4; }
      perm="$(gh api "repos/$REPO/collaborators/$actor/permission" --jq .permission 2>/dev/null)"
      case "$perm" in admin|maintain|write) ;; *) echo "{\"actor\":\"$actor\",\"permission\":\"$perm\"}"; exit 4 ;; esac
      jq -n --arg a "$actor" --arg t "$at" --arg p "$perm" '{actor:$a, at:$t, permission:$p}' ;;
    pr-draft)
      [[ $# -eq 4 && -f "$4" ]] || die 2 "pr-draft <head> <base> <title> <body-file>"
      local existing
      existing="$(gh pr list --head "$1" --state open --json url --jq '.[0].url // empty' 2>/dev/null)"
      if [[ -n "$existing" ]]; then echo "$existing"; return 0; fi
      gh pr create --draft --head "$1" --base "$2" --title "$3" --body-file "$4" ;;
    ensure-labels)
      local spec
      for spec in \
        "hotl:run|0E8A16|HOTL RUN 시작 요청(사람)" \
        "hotl:spec-review|FBCA04|게이트1 스펙 승인 대기(봇)" \
        "hotl:approval-needed|D93F0B|승인 게이트 대기(봇)" \
        "hotl:building|1D76DB|HOTL build 진행 중(봇)" \
        "hotl:pr-open|5319E7|HOTL draft PR 생성됨(봇)" \
        "hotl:spec-approved|0E8A16|스펙 승인(사람 전용)" \
        "hotl:spec-revise|FBCA04|스펙 수정 요청(사람 전용)" \
        "hotl:approved|0E8A16|게이트 승인(사람 전용)" \
        "hotl:rejected|B60205|게이트 거절(사람 전용)"; do
        IFS='|' read -r name color desc <<<"$spec"
        gh label create "$name" --color "$color" --description "$desc" --force >/dev/null || die 6 "라벨 생성 실패: $name"
      done ;;
    approve)
      die 5 "github 백엔드에서는 GitHub UI에서 사람이 직접 라벨을 붙이세요" ;;
    *) die 2 "알 수 없는 명령: $cmd" ;;
  esac
}

# ── local ─────────────────────────────────────────────────────────────────
# 오프라인 스모크·실험 전용. 권한 개념이 없어 승인 검증은 "actor ≠ 봇"까지만 한다.
local_file() {
  [[ "$1" =~ ^#?([0-9]+)$ ]] || die 2 "local 이슈는 번호로 지정합니다: $1"
  LF="$LOCAL_DIR/${BASH_REMATCH[1]}.json"
  [[ -f "$LF" ]] || die 6 "local 이슈가 없습니다: $LF"
}

local_update() { # $1 = jq 필터, 나머지 = jq 인자
  local f="$1"; shift
  local tmp; tmp="$(mktemp "${LF}.XXXX")"
  jq "$@" "$f" "$LF" >"$tmp" && mv "$tmp" "$LF"
}

local_cmd() {
  local cmd="$1"; shift
  case "$cmd" in
    whoami) echo "hotl-bot" ;;
    local-new)
      [[ $# -eq 2 && -f "$2" ]] || die 2 "local-new <title> <body-file>"
      mkdir -p "$LOCAL_DIR"
      local n=1
      while [[ -f "$LOCAL_DIR/$n.json" ]]; do n=$((n + 1)); done
      jq -n --argjson n "$n" --arg t "$1" --rawfile b "$2" \
        '{number:$n, title:$t, body:$b, url:("local://issues/" + ($n|tostring)), labels:[], events:[], comments:[]}' \
        >"$LOCAL_DIR/$n.json"
      echo "$n" ;;
    fetch)
      local_file "$1"; jq '{number,title,body,url,labels}' "$LF" ;;
    comments)
      local_file "$1"; local after="${3:-}"
      jq --arg a "$after" '[.comments[] | select($a == "" or .created_at > $a)]' "$LF" ;;
    comment)
      local_file "$1"; [[ -s "${2:-}" ]] || die 2 "본문 파일이 없거나 비어 있습니다"
      local_update '.comments += [{author:"hotl-bot", body:$b, created_at:$t}]' --rawfile b "$2" --arg t "$(now)"
      echo "local-comment" ;;
    label-add)
      local_file "$1"; check_label_name "$2"
      is_human_label "$2" && die 5 "사람 전용 라벨은 RUN이 부착할 수 없습니다: $2"
      local_update '.labels = (.labels + [$l] | unique) | .events += [{event:"labeled", label:$l, actor:"hotl-bot", at:$t}]' \
        --arg l "$2" --arg t "$(now)" ;;
    label-rm)
      local_file "$1"; check_label_name "$2"
      local_update '.labels -= [$l] | .events += [{event:"unlabeled", label:$l, actor:"hotl-bot", at:$t}]' \
        --arg l "$2" --arg t "$(now)" ;;
    approve)
      # 사람이 터미널에서 직접 실행하는 승인 시뮬레이션. RUN에서의 호출은 hotl-guard.sh가 차단한다.
      local_file "$1"; check_label_name "$2"
      is_human_label "$2" || die 2 "approve는 사람 전용 라벨에만 씁니다: $2"
      local actor="${USER:-human}"
      [[ "$actor" != "hotl-bot" ]] || die 5 "봇 이름으로 승인할 수 없습니다"
      # 같은 초에 게이트가 열린 경우 --after 비교가 실패하지 않도록 1초 뒤 시각을 기록
      sleep 1
      local_update '.labels = (.labels + [$l] | unique) | .events += [{event:"labeled", label:$l, actor:$u, at:$t}]' \
        --arg l "$2" --arg u "$actor" --arg t "$(now)" ;;
    approval)
      local_file "$1"; check_label_name "$2"; local after="${4:-}"
      local ev
      ev="$(jq -c --arg l "$2" '[.events[] | select(.event=="labeled" and .label==$l)] | last // empty' "$LF")"
      [[ -n "$ev" ]] || exit 3
      jq -e --arg l "$2" '.labels | index($l)' "$LF" >/dev/null || exit 3
      local actor at
      actor="$(jq -r .actor <<<"$ev")"; at="$(jq -r .at <<<"$ev")"
      [[ -z "$after" || "$at" > "$after" ]] || exit 3
      [[ "$actor" != "hotl-bot" ]] || { echo "{\"actor\":\"$actor\",\"reason\":\"bot\"}"; exit 4; }
      jq -n --arg a "$actor" --arg t "$at" '{actor:$a, at:$t, permission:"local"}' ;;
    pr-draft)
      [[ $# -eq 4 && -f "$4" ]] || die 2 "pr-draft <head> <base> <title> <body-file>"
      local d="$LOCAL_ROOT/prs"; mkdir -p "$d"
      local f="$d/${1//\//_}.json"
      jq -n --arg h "$1" --arg b "$2" --arg t "$3" --rawfile body "$4" \
        '{head:$h, base:$b, title:$t, body:$body, draft:true}' >"$f"
      echo "local://prs/${1//\//_}" ;;
    ensure-labels) echo "local 백엔드는 라벨을 미리 만들 필요가 없습니다" ;;
    *) die 2 "알 수 없는 명령: $cmd" ;;
  esac
}

[[ $# -ge 1 ]] || die 2 "usage: hotl-issue.sh <command> [args] (references/adapter-contract.md)"
case "$ADAPTER" in
  github) gh_cmd "$@" ;;
  local) local_cmd "$@" ;;
  linear) die 7 "linear 백엔드는 아직 구현되지 않았습니다(adapter-contract.md 슬롯)" ;;
  *) die 2 "알 수 없는 어댑터: $ADAPTER" ;;
esac
