---
name: orchestration-run
description: "devoks-sdlc-orchestration 비-HITL SDLC 파이프라인 진입점. Linear 이슈(수동 입력)를 받아 중간 승인 없이 intake→plan(EARS·traces)→worktree 병렬 구현→검증 체인(자동 게이트)→draft PR→리포트까지 오케스트레이션한다. 기존 devoks-sdlc 에이전트를 이름으로 재사용(수정 없음)하고 정책(deny-list·격리·한도)을 준수한다. 트리거: 오케스트레이션 실행, orchestration run, 비-HITL 파이프라인, 이슈 자동 구현, 자동 SDLC, RUN 실행."
metadata:
  author: ridsync
  version: 0.2.0
---
# orchestration-run — 비-HITL SDLC 오케스트레이션 (0.2.0)

신설 플러그인 `devoks-sdlc-orchestration`의 파이프라인 진입점. **중간 승인 없이(human-on-the-loop)** 이슈를
받아 draft PR까지 오케스트레이션한다. 정상 경로는 무중단, **예외(게이트 실패·blocked·deny-list·불확실성) 시에만**
사람에게 에스컬레이션한다.

- **실행 SSOT:** `${CLAUDE_PLUGIN_ROOT}/references/pipeline.md` (7단계 + RUN 상태 스키마 + 자동 게이트·재시도·에스컬레이션).
- **정책 SSOT:** `${CLAUDE_PLUGIN_ROOT}/references/orchestration-policy.md` (deny-list·격리 allowlist·한도·에스컬레이션, `policy-version 0.2.0`).
- **설계 근거(유지보수자용):** 저장소 `docs/orchestration-design.md`(D1~D6·재사용 경계).

> ⚠️ **0.2.0 검증 상태:** 이 파이프라인은 기존 `devoks-sdlc` 에이전트를 **크로스-플러그인으로 이름 호출**해 재사용한다.
> 이 호출의 실제 resolve는 **post-publish 스모크 테스트로만 최종 확인**된다(dev-live 갭). 아래 §스모크 절차로 먼저 검증한 뒤
> 실사용한다. 모든 위임은 `pipeline.md` "위임 규약" 단일 지점을 거치므로, 전제가 반증되면 그 지점만 교체한다.

---

## 호출

```
/devoks-sdlc-orchestration:orchestration-run [issue=<Linear 이슈 URL/식별자>] [budget=<RUN 토큰 예산>]
```

## 실행 절차

1. **정책·파이프라인 로드** — `${CLAUDE_PLUGIN_ROOT}/references/orchestration-policy.md`와 `pipeline.md`를 읽는다.
2. **파이프라인 실행** — `pipeline.md`의 Stage 1~6을 순서대로 수행한다:
   Intake → Plan(EARS·traces) → Implement(worktree 병렬 최대 4) → Verify 체인(자동 게이트) → Deliver(draft PR) → Report.
3. **RUN 상태 추적** — 대상 프로젝트에 `RUN.md`를 두고 `status`·`gates`·Task 체크박스를 갱신(세션 끊겨도 재개 가능).
4. **예외만 사람에게** — 게이트 2회 재시도 후 미해결·`blocked`·deny-list 저촉·불확실성은 이중 채널(이슈 코멘트 + Slack, 미배선 시 콘솔/리포트)로 에스컬레이션.

**절대 준수(정책 발췌):** `--force`/main 직접 push/`--no-verify`/파일 삭제/시크릿 노출/auto-merge **금지**. 자동화 제외(PII·라이선스·보안경계·인프라/DB)는 draft로 만들되 머지 차단·사람 위임.

---

## post-publish 스모크 테스트 (크로스-플러그인 호출 검증)

로컬 소스는 실행 세션에 즉시 반영되지 않는다(dev-live 갭). 실사용 전 아래로 전제를 검증한다:

1. 커밋 → 원격 push(`ridsync/devoks-team-harness`).
2. `claude plugin marketplace update devoks-plugins`.
3. `devoks-sdlc-orchestration` 설치 — 의존성 `devoks-sdlc`·`devoks-git`·`devoks-core`가 함께 설치되는지 확인.
4. 새 세션에서 **최소 검증**: 사소한 well-specified 태스크 1건(예: `SPIKE_OK.txt` 생성)으로 `code-implementer` 위임이
   실제 resolve·실행되는지 확인. ✅면 전체 파이프라인 사용 가능. ❌면 `pipeline.md` "위임 규약" 지점을 교체(에이전트 사본 번들 등) 후 재검증.

> ⚠️ push 시 팀 마켓플레이스에 노출된다. `version`·description으로 실험 단계(비-HITL, 검증 중)임을 명시한다.
