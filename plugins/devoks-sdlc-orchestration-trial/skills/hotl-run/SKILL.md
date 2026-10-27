---
name: hotl-run
description: "[trial] HOTL(human-on-the-loop) SDLC RUN 실행기. 이슈(GitHub/local 어댑터)를 받아 spec(FRD/PLAN 작성) → 게이트1(스펙 승인 라벨) → build(devoks-sdlc 에이전트 위임) → 자동 검증 체인 → draft PR까지 진행하고, 되돌리기 어려운 작업·예외에서는 승인 게이트를 이슈에 열고 정지한 뒤 라벨 응답으로 재개한다. 세션 안에서 사용자에게 질문하지 않는다. 트리거: hotl run, HOTL 실행, 이슈로 HOTL 돌려줘, 게이트 승인 후 재개, hotl resume. 대화형(HITL) 기능 개발은 devoks-sdlc:feature-workflow-runner, 기존 비-HITL 설계 MVP는 devoks-sdlc-orchestration:orchestration-run 을 쓴다."
argument-hint: "issue=<이슈 번호/URL> [stage=<auto|spec|build|resume> (default: auto)]"
---

# hotl-run — HOTL SDLC RUN (trial 0.3.0)

**실험 플러그인**이다. 팀 배포 경로가 아니며 `--plugin-dir`로만 로드된다. 목적은 HOTL 설계(게이트 외부화·결정론적 가드·헤드리스 실행)를
실제로 돌려 보고 정식 `devoks-sdlc-orchestration`에 무엇을 승격할지 판단하는 것이다.

## 호출 방법

```
/devoks-sdlc-orchestration-trial:hotl-run issue=<이슈 번호/URL> [stage=<auto|spec|build|resume> (default: auto)]
```

> 표기: `key=값` 필수 · `[key=값]` 선택 · `(default: X)` 미지정 시 X로 진행.

- 무인 실행: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/hotl-headless.sh <issue> [stage]` (worktree 격리 + 가드 + 턴·비용 상한).
- 어댑터는 인자가 아니라 `HOTL_ADAPTER` 환경변수 또는 `.hotl/config.json`의 `adapter`로 정한다.
- `.hotl/config.json`이 없으면 아무것도 하지 않고 `/devoks-sdlc-orchestration-trial:hotl-setup` 실행을 안내한 뒤 종료한다.

## 절대 규칙

1. **사용자에게 질문하지 않는다**(AskUserQuestion 포함). 결정이 필요하면 `gate-protocol.md`대로 이슈에 게이트를 열고 종료한다.
2. **HITL 스킬 본문을 호출하지 않는다**(`devoks-sdlc:feature-*`·`verify-*`·`code-review` 등). `devoks-sdlc`의 **에이전트만** 이름으로 위임한다.
3. 이슈 조작은 `${CLAUDE_PLUGIN_ROOT}/scripts/hotl-issue.sh`로만 한다. 사람 전용 라벨(`hotl:spec-approved`·`hotl:spec-revise`·`hotl:approved`·`hotl:rejected`)은 조회·제거만 한다.
4. 가드 훅이 차단하면 우회하지 않는다 — 차단 사유를 `RUN.md` 정책 이벤트에 남기고, 필요한 작업이면 게이트를 연다.
5. RUN이 어디서 끝나든 `bash ${CLAUDE_PLUGIN_ROOT}/scripts/hotl-run-end.sh`로 가드를 끄고 종료 리포트를 출력한다.

## 실행 절차

1. **로드** — `${CLAUDE_PLUGIN_ROOT}/references/`의 `policy.md`, `gate-protocol.md`, `pipeline.md`를 읽는다. `adapter-contract.md`는 어댑터 명령이 헷갈릴 때만, `acceptance-scenarios.md`는 `config.verify.acceptance.enabled`일 때만(spec의 시나리오 표 작성·verify 게이트 5) 읽는다.
2. **stage 결정** — `stage=auto`면 아래 순서로 판정한다:
   - 이슈 라벨에 `hotl:building`이 있으면 → 중복 실행이므로 종료.
   - 작업 브랜치 `hotl/<issue>-*`(로컬·원격)이 없거나, 라벨에 `hotl:spec-revise`가 있으면 → `spec`.
   - 브랜치의 `RUN.md` `pending_gate.type`이 `spec`이면 → `build`, `action`·`exception`이면 → `resume`.
   - `status: delivered`·`rejected`면 → 할 일 없음, 종료 리포트만.
3. **실행** — `pipeline.md`의 §0(공통) 후 해당 Stage(§2 spec / §3 build→§4 verify→§5 deliver / §6 resume)를 수행한다.
   - FRD/PLAN 골격과 규칙은 `${CLAUDE_PLUGIN_ROOT}/references/upstream/`의 사본을 쓴다(출처: `upstream/SOURCES.md`).
   - 위임 계약·리포트 판정은 `upstream/task-delegation.md`를 그대로 따른다. 그 문서의 "사용자에게 확인"은 trial에서 `exception` 게이트로 읽는다.
4. **종료** — `pipeline.md` §7 형식의 종료 리포트를 출력하고 `hotl-run-end.sh`를 실행한다.

## 범위

- **한다:** 이슈 → FRD/PLAN → 구현 → 자동 검증 → draft PR, 게이트 개방·재개, 작업 브랜치 push.
- **안 한다:** PR 머지·ready 전환, 기본 브랜치 push, 배포·마이그레이션 실행, 정책·config 수정(`policy.md` §3).
- **관련:** 프로젝트 준비는 `devoks-sdlc-orchestration-trial:hotl-setup`. 사람이 단계마다 확인하며 개발하려면 `devoks-sdlc:feature-workflow-runner`.
  기존 비-HITL 설계 MVP(무중단·Linear)는 `devoks-sdlc-orchestration:orchestration-run` — trial은 그 설계의 갭(런타임 참조·위임 계약·게이트 외부화·가드·헤드리스)을 실험한다.
