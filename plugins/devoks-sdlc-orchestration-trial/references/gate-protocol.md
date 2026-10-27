# 게이트 프로토콜 — 사람 개입을 세션 밖(이슈)으로

HOTL에서 사람은 세션 안에서 질문에 답하지 않는다. RUN은 **게이트를 열고 종료**하고, 사람은 이슈에서 **라벨로 응답**하며,
라벨 이벤트(CI) 또는 사람이 다시 실행한 `hotl-run stage=resume`이 RUN을 재개한다. 라벨·코멘트 조작은 전부
이슈 어댑터(`adapter-contract.md`, `scripts/hotl-issue.sh`)를 거친다 — 어댑터를 우회해 `gh`를 직접 부르지 않는다.

## 게이트 종류

| 게이트 | 언제 열리나 | RUN이 남기는 것 | 사람의 응답 |
|---|---|---|---|
| `spec` (게이트1) | spec 단계 완료 직후(`config.gates.spec`가 `false`면 생략) | FRD/PLAN 요약 코멘트 + 브랜치 링크 + 라벨 `hotl:spec-review` | `hotl:spec-approved` → build / 코멘트로 수정 요청 후 `hotl:spec-revise` → spec 재작성 / `hotl:rejected` → 중단 |
| `action` | `policy.md` §2 승인 게이트 대상 작업 **직전** | 무엇을·왜·되돌리는 법·대안 코멘트 + 라벨 `hotl:approval-needed` | `hotl:approved` → 그 작업만 수행 후 재개 / `hotl:rejected` → 그 작업 없이 대안 진행 또는 중단(코멘트로 지정) |
| `exception` | 스펙 공백, 자동 수정 상한 초과, 심각도 차단, 환경 재현 불가, 한도 초과 | 사유 분류·부분 변경 파일·해소 제안 1~2개 + 라벨 `hotl:approval-needed` | 코멘트로 결정을 남기고 `hotl:approved` → 그 결정을 반영해 재개 / `hotl:rejected` → 중단 |
| (게이트2) 머지 | draft PR 생성 후 | 라벨 `hotl:pr-open` | 사람이 PR을 리뷰·ready 전환·머지(RUN 범위 밖) |

## 라벨

| 라벨 | 부착 주체 | 의미 |
|---|---|---|
| `hotl:run` | 사람 | RUN 시작 요청(트리거) |
| `hotl:spec-review` | 봇 | 게이트1 대기 |
| `hotl:approval-needed` | 봇 | `action`/`exception` 게이트 대기 |
| `hotl:building` | 봇 | build 진행 중(중복 실행 방지 표식) |
| `hotl:pr-open` | 봇 | draft PR 생성됨 |
| `hotl:spec-approved` · `hotl:spec-revise` · `hotl:approved` · `hotl:rejected` | **사람 전용** | 게이트 응답 |

**사람 전용 라벨은 RUN이 절대 부착·생성·수정하지 않는다**(`policy.md` §3 게이트 위조). `hotl-guard.sh` 훅이 이 라벨명을 포함한 쓰기 명령을 차단하고,
어댑터의 `label-add`도 거부한다. 봇이 응답 라벨을 **제거**하는 것은 허용한다(소비 처리 — 다음 게이트는 새 승인을 요구).

## 승인 검증 (위조·재사용 방지)

재개 전 RUN은 반드시 `hotl-issue.sh approval <issue> <label> --after <게이트 opened_at>`으로 검증한다. 통과 조건:

1. 해당 라벨이 **게이트가 열린 시각 이후**에 부착됐다(이전 게이트의 승인 재사용 차단).
2. 부착한 actor가 **봇 자신이 아니다**(`hotl-issue.sh whoami`와 다름).
3. actor의 저장소 권한이 `admin`·`maintain`·`write` 중 하나다(local 어댑터는 권한 개념이 없어 2까지만).

검증 실패면 재개하지 않는다 — 게이트를 그대로 두고 "승인 검증 실패: <사유>" 코멘트만 남기고 종료한다.
검증 통과 후 RUN은 응답 라벨과 대기 라벨을 제거하고, 결정 코멘트(있다면)를 `RUN.md` 게이트 이력에 요약해 둔다.

## 게이트 코멘트 형식

사람이 읽는 본문 + 머신 가독 마커 1줄. 마커는 RUN 재개의 보조 근거이고, **진행 SSOT는 브랜치의 `RUN.md`** 다.

```markdown
<!-- hotl:gate {"run":"<run-id>","gate":"action","kind":"dependency","id":"G-002","checkpoint":"TASK-004"} -->
### 🛑 HOTL 승인 필요 — 의존성 추가 (G-002)

- **무엇을:** `zod@3` 를 dependencies에 추가
- **왜:** AC-002-1 입력 스키마 검증 — 기존 의존성으로 대체 시 수작업 검증 80줄
- **되돌리는 법:** 커밋 `<sha>` revert + lockfile 복구
- **대안:** 수작업 검증 함수(라이선스 이슈 없음, 유지보수 비용 증가)

승인: `hotl:approved` · 거절: `hotl:rejected`(대안으로 진행하려면 코멘트에 "대안" 명시)
```

- 시크릿 값·전체 diff 원문을 코멘트에 넣지 않는다(경로·라인·요약만).
- 한 번에 **게이트 하나만** 연다. 여러 승인 대상이 한 시점에 겹치면 하나의 `action` 게이트에 목록으로 묶는다.

## 재개 규칙

- `stage=resume`은 `RUN.md`의 `pending_gate`를 읽어 응답 라벨을 판정한다. `pending_gate`가 없으면 아무것도 하지 않고 종료한다.
- `stage=build`는 `spec` 게이트 승인을 같은 방식으로 검증한 뒤 시작한다.
- 같은 이슈에 `hotl:building`이 이미 있으면 새 RUN을 시작하지 않는다(동시 실행 방지). 비정상 종료로 라벨이 남았다면 사람이 제거한다.
