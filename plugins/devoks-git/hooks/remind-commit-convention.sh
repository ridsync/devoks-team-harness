#!/usr/bin/env bash
# remind-commit-convention.sh — git commit 실행 직전 커밋 컨벤션(Footer author)을 리마인드
#
# PreToolUse(Bash) 훅으로 실행. /devoks-git:git-commit-msg 커맨드를 거치지 않고
# 에이전트가 즉흥적으로 git commit을 실행할 때도, Claude Code 기본
# `Co-Authored-By: Claude ...` 트레일러 대신 이 프로젝트 컨벤션을 따르도록 보정한다.
#
# 특성: 빠름·non-blocking(항상 exit 0, permissionDecision=allow). git commit이
# 아닌 Bash 호출은 조용히 통과한다. matcher는 툴 이름(Bash)만 필터링하므로,
# 명령어 내용 판별은 이 스크립트가 stdin 원문에서 휴리스틱으로 수행한다
# (거짓양성=리마인더 과다 노출, 거짓음성=리마인더 누락 — 커밋을 막지 않으므로
# 둘 다 저비용. check-setup-state.sh와 동일한 판단 기준).

set -uo pipefail

input="$(cat)"

echo "$input" | grep -Eq '(^|[;&|"[:space:]])git[[:space:]]+commit([[:space:]"]|$)' || exit 0

reminder='[devoks-git] 커밋 컨벤션: Footer author 트레일러는 `by Neo Agent (${AgentName}) 🤖` 형식을 고정 사용한다(`Neo Agent`는 리터럴, `${AgentName}`은 실제 커밋을 수행한 에이전트/도구 이름으로 치환). Claude Code 기본 `Co-Authored-By: Claude ...` 트레일러는 추가하지 않는다. 상세 규칙: /devoks-git:git-commit-msg 또는 .claude/refs/git-convention.md.'

printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow","additionalContext":"%s"}}\n' "$reminder"
exit 0
