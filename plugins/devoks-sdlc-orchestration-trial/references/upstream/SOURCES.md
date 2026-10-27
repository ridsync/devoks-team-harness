# upstream 사본 출처 (devoks-sdlc)

이 디렉터리의 파일은 `devoks-sdlc`의 reference·template을 **바이트 동일하게** 복사한 것이다.
플러그인 루트 밖 파일은 설치 후 읽을 수 없으므로(플러그인 경계), trial 런타임이 **파일로 직접 읽어야 하는 것만** 복사했다.
스킬·에이전트는 복사하지 않고 이름으로 호출한다(`devoks-sdlc:code-implementer` 등).

- 복사 기준: `devoks-sdlc` 3.9.0 (커밋 `8dd675e`), 2026-10-27
- 원본 경로 접두: `plugins/devoks-sdlc/skills/feature-workflow-runner/`

| 사본 | 원본 | sha256(앞 12자) | trial에서 쓰는 이유 |
|---|---|---|---|
| `FRD.template.md` | `assets/FRD.template.md` | `9ae73b68d135` | spec 단계가 FRD.md를 이 골격으로 작성 — `code-implementer` 입력 계약(`frd` 경로) 충족 |
| `PLAN.template.md` | `assets/PLAN.template.md` | `174e85c22c07` | spec 단계가 PLAN.md를 이 골격으로 작성 — `code-implementer` 입력 계약(`plan` 경로) 충족 |
| `ears-acceptance-criteria.md` | `references/ears-acceptance-criteria.md` | `6f4f8f12da1b` | AC를 EARS로 정형화(게이트1 리뷰 품질의 바닥) |
| `traceability.md` | `references/traceability.md` | `2863481c201a` | traces 누락 0 점검 스크립트 |
| `task-pr-splitting.md` | `references/task-pr-splitting.md` | `269d6cabb267` | `size`·`test` 마커 부여 기준(실행 라우팅 신호) |
| `task-delegation.md` | `references/task-delegation.md` | `35839ca37ece` | `code-implementer` 입력 계약·리포트 스키마·테스트 무력화 점검 |

## 적응 문서 (바이트 사본 아님)

원본이 HITL 절차(사용자 합의)를 본문에 품고 있어 그대로 복사하면 질문 단계가 딸려 오는 경우, 규칙만 옮겨 trial 문서로 다시 썼다.
바이트 비교로 drift를 잡을 수 없으므로, 원본 파일의 변경 이력을 기준 커밋 이후로 확인한다.

| trial 문서 | 원본 | 기준 | 옮긴 범위 |
|---|---|---|---|
| `../acceptance-scenarios.md` | `plugins/devoks-sdlc/skills/verify-acceptance-test/SKILL.md` | 3.9.0 / `8dd675e` | Phase 0(대상 AC 선별·시나리오 표·연타 규칙·슬롯) → spec 단계 초안 + 게이트1 리뷰, Phase 5 저장 위치, Phase 6 임시 패치 회수 확인 |

```bash
git log --oneline 8dd675e..HEAD -- plugins/devoks-sdlc/skills/verify-acceptance-test/ plugins/devoks-sdlc/agents/acceptance-test-runner.md
```

출력이 있으면 원본 변경을 검토해 `acceptance-scenarios.md`를 갱신하고 위 기준 커밋을 올린다. 러너 입력 슬롯 표가 바뀌었다면 §4를 반드시 맞춘다.

## 사본 안의 상대 참조

사본 본문에 남은 `references/...`·`skills/test-author/...` 같은 경로는 **원본(devoks-sdlc) 기준**이다. trial 런타임은 그
경로를 따라가지 않는다 — 이 디렉터리에 없는 파일이 필요하면 해당 devoks-sdlc 스킬/에이전트를 이름으로 호출한다.

사본 중 HITL 문구(사용자 확인·질문)는 trial에서 **게이트 프로토콜로 대체**해 읽는다(`../gate-protocol.md`).
예: `task-delegation.md` "에스컬레이션 1. 사용자에게 확인" → trial에서는 예외 게이트(`exception`)로 정지.

## drift 점검 (harness 저장소 유지보수자용)

설치된 환경에서는 실행하지 않는다(원본이 없음). harness 저장소 루트에서:

```bash
S=plugins/devoks-sdlc/skills/feature-workflow-runner; T=plugins/devoks-sdlc-orchestration-trial/references/upstream
for f in assets/FRD.template.md assets/PLAN.template.md references/ears-acceptance-criteria.md \
         references/traceability.md references/task-pr-splitting.md references/task-delegation.md; do
  cmp -s "$S/$f" "$T/$(basename "$f")" || echo "DRIFT: $f"
done
```

출력이 없으면 동기 상태다. drift가 있으면 원본 변경을 검토해 사본을 다시 복사하고 위 표의 sha·기준 커밋을 갱신한다.
