# HOTL trial 정책 (policy-version: trial-0.1.0)

`hotl-run` RUN이 지키는 정책의 단일 진실원천. 기존 `devoks-sdlc-orchestration`의 정책(0.2.0)을 출발점으로 하되,
trial은 **세 등급(허용 / 승인 게이트 / 금지)** 으로 다시 나눈다. 0.2.0은 "금지 → 에스컬레이션" 두 갈래뿐이라,
사람이 승인하면 진행해도 되는 작업까지 영구 차단되거나 추측으로 진행될 여지가 있었다.

> 이 정책에 명시적으로 허용되지 않은 것은 **승인 게이트**로 취급한다(추측 진행 금지, allowlist 우선).

---

## 1. 허용 — 승인 없이 수행

- 작업 브랜치 `hotl/<issue>-<slug>` 생성·체크아웃·커밋·**일반 push**(force 아님, 기본 브랜치 아님).
- 브랜치 내 소스 코드 편집·신규 파일 생성, `.hotl/runs/<run-id>/` 상태 파일 기록.
- 테스트·lint·타입체크·빌드 등 검증 명령 실행(`.hotl/config.json`의 `verify.commands`).
- **실동작 검증(verify 게이트 5) 동안에 한해** `scripts/hotl-devserver.sh`로 **RUN 자신의 worktree** dev server를 기동·종료(실동작 락 보유 중, `acceptance-scenarios.md` §1). 2026-10-27 결정 — 고정 URL은 메인 작업트리 서버를 검사하게 되므로.
- `devoks-sdlc` 에이전트 위임, 검증 체인 실행, 자동 수정 루프(상한 §4).
- 이슈 어댑터를 통한 **봇 라벨 부착·코멘트 작성**(게이트 요청·상태 보고), **draft PR 생성**.

## 2. 승인 게이트 — 사람이 승인해야 진행 (되돌리기 어렵거나 중대한 검증이 필요한 작업)

RUN은 해당 작업 **직전에 정지**하고 `gate-protocol.md`의 `action` 게이트를 연다. 승인되면 그 작업만 수행하고 이어간다.

| kind | 대상 | 예 |
|---|---|---|
| `delete` | 소스·설정 파일 삭제, 대량(10파일 초과) 이동 | `git rm`, `rm src/...` |
| `dependency` | 의존성 추가·교체·메이저 업그레이드(라이선스·공급망) | `package.json` dependencies 변경, lockfile 대규모 변경 |
| `security-boundary` | 인증·인가·암호화·세션·권한 검사 로직 변경 | auth middleware, token 검증 |
| `schema` | DB 스키마·마이그레이션 **파일 작성**(실행은 §3 금지) | `migrations/*` 신규 |
| `ci-config` | CI·빌드·배포 설정 변경(에이전트 자기 권한 경로) | `.github/workflows/*`, `Dockerfile`, 배포 스크립트 |
| `pii` | 개인정보가 오가는 필드·로그·저장 로직 변경 | 이메일·전화번호 저장/전송 |
| `scope-change` | 승인된 PLAN 밖 파일·요구가 필요해짐(스펙 drift) | 승인 PLAN에 없는 모듈 변경 |

예외 상황도 같은 게이트 메커니즘을 쓴다 — `gate-protocol.md`의 `exception` 게이트(스펙 공백, 자동 수정 상한 초과, 심각도 차단, 환경 재현 불가).

## 3. 금지 — 승인이 있어도 RUN이 수행하지 않음 (사람이 직접)

| 범주 | 금지 액션 | 강제 수단 |
|---|---|---|
| Git 파괴적 | `push --force`/`--force-with-lease`/`+refspec`, 기본 브랜치(`main`·`master`·config의 `base`)로 push, `--no-verify`, `reset --hard` 후 push, 브랜치·태그 원격 삭제 | 훅 `hotl-guard.sh` |
| 머지 | PR 머지·auto-merge 활성화·draft 해제(ready 전환) | 훅 + 정책 |
| 시크릿 | `.env*`·키·인증서·credential 파일 생성/수정/출력 | 훅 |
| 게이트 위조 | 사람 전용 라벨(`hotl:spec-approved`·`hotl:spec-revise`·`hotl:approved`·`hotl:rejected`) 부착·생성·수정 | 훅 + 어댑터 actor 검증 |
| 인프라·데이터 | 마이그레이션 실행, 프로덕션 배포, 클라우드 리소스 변경 | 정책(명령 패턴이 프로젝트마다 달라 훅으로 일반화 불가 — §6) |
| 프로세스 | §1 예외 밖의 dev server·장기 실행 프로세스 기동(셸에서 `npm run dev` 등 직접 기동 포함), Chrome·에뮬레이터 기동, 실동작 락을 쥔 채 구현 진행 | 정책(기동 명령이 프로젝트마다 달라 훅으로 일반화 불가) |

## 4. 한도

| 항목 | 기본값 | config 키 |
|---|---|---|
| 태스크당 재위임 | 2회 | `limits.taskRetries` |
| 검증 게이트 자동 수정 루프 | 2회 | `limits.fixLoops` |
| 동시 구현 태스크 | 1(순차) — worktree 병렬은 실험 옵션 | `limits.parallel` |
| 헤드리스 턴 상한 | 120 | `limits.maxTurns` (`hotl-headless.sh`가 `--max-turns`로 전달) |
| 헤드리스 비용 상한 | 15 USD | `limits.budgetUsd` (`--max-budget-usd`) |

상한 도달은 조용히 축소하지 않는다 — `exception` 게이트로 정지하고 무엇이 잘렸는지 남긴다.

## 5. 심각도 차단

코드리뷰·보안 리뷰의 **Critical/High** 는 게이트 실패다. 자동 수정 루프(§4) 후에도 남으면 `exception` 게이트(`severity-block`).
draft PR은 만들 수 있지만 본문 최상단에 차단 사유를 표기한다(머지는 원래 사람 몫).

## 6. 강제 수단의 한계 (trial이 측정할 것)

- 훅은 **RUN 활성 시에만** 동작한다(`DEVOKS_HOTL_RUN=1` 또는 `.hotl/ACTIVE` 존재). 일반 세션에는 영향이 없다.
- 훅은 명령 **문자열 패턴**으로 판정한다. 변수 치환·스크립트 파일 경유 같은 우회는 막지 못한다 — 그래서 CI에서는
  토큰 권한(브랜치 보호, `contents: write`만, 머지 권한 없음)이 진짜 경계다. 훅은 "실수 방지" 층이다.
- §2 승인 게이트는 **정책(모델 층)** 으로 집행한다 — 파일 삭제처럼 훅으로 잡을 수 있는 것도 있지만, `security-boundary`·`pii`처럼
  의미 판단이 필요한 것은 훅으로 판정할 수 없다. trial의 RUN 리포트는 "게이트를 열어야 했는데 열지 않은" 사례를 사후 리뷰로 수집한다.
