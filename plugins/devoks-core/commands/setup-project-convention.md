---
description: 기술스택 preset을 선택해 프로젝트 규칙·참조 문서와 active project convention을 명시적으로 구성한다.
---

# Project Convention Setup

## Overview

이 커맨드는 **최초 설치/구성 시점** 또는 사용자가 명시적으로 재구성하고 싶을 때,
base rules/refs 와 선택한 stack preset을 프로젝트에 적용한다.

---

## SSOT

- base rules: `${CLAUDE_PLUGIN_ROOT}/rules/agent-principles.md`, `${CLAUDE_PLUGIN_ROOT}/rules/memory-policy.md`
- stack preset: `${CLAUDE_PLUGIN_ROOT}/conventions/<preset>/project-convention.md`
- 참조 문서: `${CLAUDE_PLUGIN_ROOT}/refs/*.md` — frontmatter에 `scope`가 **없는** 파일은 base refs(항상 복사, 목록 SSOT는 `hooks/check-setup-state.sh`의 `BASE_FILES`), `scope`가 있는 파일은 **스택 한정 refs**(`scope`는 쉼표로 구분한 preset id 목록 — 선택한 preset이 들어 있을 때만 복사, 예: `web-security.md` → `react-web`·`nextjs`)
- 프로젝트 active convention: `.claude/rules/project-convention.md`
- provenance metadata: `.claude/project-convention.json`
- 프로젝트 사실 SSOT: `.claude/CLAUDE.md`

---

## Steps

### 1. 현재 상태 점검

다음을 먼저 확인한다.

- `.claude/CLAUDE.md` 존재 여부
- `.claude/rules/project-convention.md` 존재 여부
- `.claude/project-convention.json` 존재 여부
- 코드베이스 시그널
  - Web/RN: `package.json`, `tsconfig`, `vite.config`, `next.config`, `react-native`, `expo`
  - Next.js: `package.json` 의존성의 `next`, `next.config.*`, `app/`(또는 `src/app/`) 디렉터리 — 모노레포면 앱 패키지(`apps/*/package.json`)까지 본다
  - Android: `android/`, `build.gradle*`, `settings.gradle*`
  - iOS: `ios/`, `Package.swift`, `*.xcodeproj`, `*.xcworkspace`
  - Python FastAPI: `pyproject.toml`(`fastapi`/`uvicorn` 의존성), `requirements.txt`, `alembic.ini`
- 기술 설계 시그널 — `docs/product/TRD.md`(없으면 저장소의 `TRD.md`)의 §2 `stack preset:` 줄과 §3.1 앱 내부 아키텍처 유무

감지 결과는 **preset 추천 근거**에만 사용한다. 감지값을 SSOT로 단정하지 않는다.

근거 우선순위:
- **코드가 없음(그린필드)** — TRD §2 `stack preset`이 1순위다. TRD도 없으면 고를 근거가 없으므로 "스택이 정해지지 않았다면 `/devoks-sdlc:product-trd-author`로 TRD를 먼저 쓰고 돌아오는 것"을 권하고, 사용자가 이미 스택을 정했으면 질문으로 고른다. 그린필드에서 이 커맨드는 **TRD 직후, 첫 FRD/PLAN 전**이 제자리다 — PLAN의 `file:`과 구현이 구조 슬롯을 읽기 때문이다.
- **코드가 있음(브라운필드)** — 코드 시그널이 1순위다. TRD `stack preset`과 다르면 추천하지 말고 차이를 보여 주고 묻는다(TRD가 낡았거나 스택 전환 중일 수 있다).

### 2. 추천 preset 제안

다음 중 하나를 추천하거나, 확신이 낮으면 추천 없이 질문한다.

- React Web (Vite CSR)
- Next.js (App Router)
- React Native
- Android
- iOS
- Python FastAPI
- Custom

추천 시에는 반드시 근거를 함께 말한다.

예:
- `package.json`에 `react-native`와 `expo`가 있어 React Native 추천
- `package.json`에 `next`가 있고 `app/` 디렉터리가 있어 Next.js 추천 — `next`가 있으면 React Web보다 우선한다(react-web의 SSR Variant는 레거시 경로)
- `android/`만 있고 Gradle 설정이 보여 Android 추천
- `ios/`와 Xcode project가 있어 iOS 추천
- `pyproject.toml`에 `fastapi`/`uvicorn` 의존성이 있어 Python FastAPI 추천
- 코드는 없고 `docs/product/TRD.md` §2에 `stack preset: nextjs`가 있어 Next.js 추천

### 3. 적용 범위 설명

사용자에게 아래 적용 범위를 설명하고 확인받는다.

1. `.claude/rules/agent-principles.md` 복사/갱신
2. `.claude/rules/memory-policy.md` 복사/갱신
3. `.claude/refs/` base refs 복사/갱신 + 선택한 preset의 스택 한정 refs 복사(있을 때만 — 어떤 파일인지 이름을 밝힌다)
4. 선택한 preset을 `.claude/rules/project-convention.md`로 생성 또는 교체
5. `.claude/project-convention.json` 생성/갱신
6. Project Decisions 구조 슬롯(S1~S8) 확정 — 코드베이스 실측·TRD 기반 초안과 "현행 vs 목표" 비교를 한 번에 확인 (7단계)

적용 모드는 아래 중 하나로 제안한다.

- **fresh apply** — 파일이 없을 때 바로 생성
- **diff first** — 기존 파일이 있으면 차이 요약 후 결정
- **cancel** — 적용하지 않음

### 4. 기존 convention이 있을 때의 처리

기존 `.claude/rules/project-convention.md`가 있으면 바로 덮어쓰지 않는다.

반드시 아래 순서로 진행한다.

1. 기존 파일 존재 사실 알림
2. provenance metadata 존재 여부 확인
3. 아래 중 하나를 질문
   - `새로 적용`
   - `diff 먼저 보기`
   - `취소`

#### diff 요약 형식

전체 raw diff를 길게 던지지 말고 아래 관점으로 요약한다.

- 추가되는 섹션
- 제거되는 섹션
- placeholder로 남는 항목
- 기존 로컬 커스터마이징이 사라질 가능성이 있는 항목
- `.claude/CLAUDE.md`와 충돌하는 stack 사실

### 5. Custom 흐름

`Custom` 선택 시에는 가장 가까운 preset을 출발점으로 삼되, 부족한 항목을 짧게 질의한다.

필수 확인 슬롯:
- Language / Type system
- Framework / Runtime
- UI / Styling
- State / DI / Architecture
- Test stack
- 민감 파일 / 보안 저장소

그 결과를 반영해 `.claude/rules/project-convention.md` 초안을 만든다.

### 6. 파일 적용

승인되면 아래를 수행한다.

- `.claude/rules/` 및 `.claude/refs/`가 없으면 생성
- base rules/refs 를 명시적으로 복사
- 스택 한정 refs 복사 — `${CLAUDE_PLUGIN_ROOT}/refs/*.md` 중 frontmatter `scope` 목록에 선택한 preset id(`react-web`·`nextjs` 등, provenance `preset` 값과 같은 표기)가 들어 있는 파일만. `Custom`은 출발점으로 삼은 preset 기준
- 선택한 preset 원본을 `.claude/rules/project-convention.md`로 복사
- 필요 시 `Custom` 보정 내용을 같은 파일에 반영
- **원본 스냅샷 기록** — 복사한 base 원본 7종·스택 한정 refs와 preset 원본을 `.claude/.devoks-base/`에 그대로 둔다(`rules/`·`refs/`는 같은 이름, preset은 `preset/project-convention.md`). 다음 업데이트 때 `devoks-core:setup-preset-manage`가 이 스냅샷을 merge base로 써서 upstream 변경과 로컬 커스터마이징을 구분한다(구버전 플러그인 캐시는 업데이트 14일 뒤 삭제되므로 캐시에 의존하지 않는다). 복사는 `command cp -f`로 한다(셸 프로필의 `cp -i` 별칭 회피)
- preset 원본 파일의 `sha256` 해시를 계산(예: `shasum -a 256 "${CLAUDE_PLUGIN_ROOT}/conventions/<preset>/project-convention.md"`)
- 적용에 사용한 devoks-core 버전을 확인한다 — 플러그인 캐시 경로가 `.../devoks-core/<version>/` 구조이므로
  `basename "${CLAUDE_PLUGIN_ROOT}"`가 곧 설치 버전이다. 경로가 버전 형태가 아니면(폴백 설치)
  `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`의 `version`을 읽는다. 이 경로가 없으면
  `${CLAUDE_PLUGIN_ROOT}/plugin.json`도 시도한다 — 매니페스트 배치가 마켓플레이스마다 갈린다
  (devoks-plugins는 `.claude-plugin/` 하위지만 flat 배치를 쓰는 마켓플레이스도 있다).
- `.claude/project-convention.json`에 provenance 저장 — 해시를 `presetHash`, 버전을 `devoksCoreVersion`으로 함께 기록

metadata 예시:

```json
{
  "preset": "react-web",
  "source": "${CLAUDE_PLUGIN_ROOT}/conventions/react-web/project-convention.md",
  "presetHash": "<sha256>",
  "devoksCoreVersion": "<설치된 devoks-core 버전, 예: 1.6.0>",
  "managedBy": "devoks-core:setup-project-convention",
  "mode": "fresh-apply"
}
```

`presetHash`는 이후 `devoks-core:setup-preset-manage`가 "업스트림 preset이 그 사이 바뀌었는지"를
값싸고 정확하게 판단하는 사전 필터로 쓴다 — preset 원본 내용이 변경될 때만 값이 달라진다.

`devoksCoreVersion`은 **base rules/refs**(`presetHash`가 커버하지 않는 7개 파일 + 스택 한정 refs)의 stale 여부를
SessionStart 훅이 판정하는 기준이다. 훅은 이 값이 설치 버전과 다르고 **또한** base 파일 내용이 실제로
다를 때만 1줄 경고한다 — 버전만 비교하면 base를 건드리지 않은 patch bump에서 오탐이 난다.
필드가 없는 구버전 provenance는 훅이 `source` 경로의 `/devoks-core/<version>/`에서 회수하므로,
이 필드를 추가하려고 기존 프로젝트를 재설정할 필요는 없다. 경고가 나오면 이 커맨드를 다시 돌리지 않고
`devoks-core:setup-preset-manage`의 "base 갱신"으로 base 7종만 교체한다(preset 재선택 불필요).

### 7. 구조 슬롯 확정

파일 적용 직후 `.claude/rules/project-convention.md` Project Decisions의 **구조 슬롯(S1~S8)**을 프로젝트 구조에 맞게 채운다. 판정 기준은 `.claude/rules/agent-principles.md` [Structure]·DRY이고, 슬롯 값은 프로젝트가 고른다 — preset의 슬롯 예시나 다른 프로젝트의 구조를 그대로 옮겨 적지 않는다.

1. **입력 수집**
   - 기존 코드가 있으면 실측한다: 최상위 디렉터리 맵, 모듈 안 파일 표기 관례(접미사·하위 디렉터리)와 그 빈도, `index`·`__init__` re-export 유무, 공용 디렉터리 후보와 그쪽으로 향하는 import 방향, 테스트·픽스처 위치, lint 도구의 순환 import 규칙 설정 여부.
   - TRD가 있으면 §3.1 앱 내부 아키텍처(목표 디렉터리 맵·계층·진입점별 데이터 접근·강제 수단), §8 개발 기반(저장소 구조)과 구조 관련 ADR(`docs/decisions/`)을 읽는다. §3.1이 있으면 그것이 **목표 구조**이고 S1~S5의 1차 근거다.
   - 신규 프로젝트면 TRD §3.1을 1순위로 쓰고, TRD §3.1에 없는 항목만 preset 슬롯 예시를 **제안**으로 보여 준다(확정은 사용자). TRD §3.1이 아예 없으면 S1·S3·S5(디렉터리 맵·배치·의존 방향)는 여러 기능에 걸친 결정이므로 `/devoks-sdlc:product-trd-author`로 §3.1을 먼저 정하길 권하고, 사용자가 지금 정하지 않으면 `미확정`으로 둔다.
2. **슬롯별 초안** — 기존 코드는 현행을 사실로 적되 감지값은 제안일 뿐 SSOT로 단정하지 않는다. 기준과 어긋나는 곳(예: 도메인 규칙이 앱 범용 유틸에 있음, 함수마다 파일)은 슬롯 값에 섞지 말고 **관찰 목록**으로 따로 적는다. 이 단계에서 코드를 옮기지 않는다.
3. **현행 vs 목표 비교 (기존 코드가 있을 때)** — 실측 초안을 그대로 확정하면 지금 구조가 맞는지 묻지 않은 채 규칙으로 굳는다. 슬롯마다 목표를 하나 정해 현행과 나란히 둔다.
   - TRD §3.1이 있으면 그 값이 목표다. 현행과 다른 슬롯은 "현행 / 목표 / 차이"로 적는다.
   - TRD §3.1이 없으면 목표 후보를 preset의 구조 고려사항(Module Structure 절 — 프레임워크 공식 권장 근거 포함)으로 만들어 제안하고, 각 슬롯을 **현행 유지 / 목표로 전환 / 미확정** 중 하나로 고르게 한다. 진입점·계층·실행 환경 경계처럼 여러 기능에 걸친 차이가 보이면 슬롯에서 바로 결정하지 말고 `/devoks-sdlc:product-trd-author`(§3.1 앱 내부 아키텍처)로 먼저 목표를 정하도록 안내한다.
   - **슬롯 값은 목표 구조로 적는다.** 목표와 다른 현행 코드는 관찰 목록에 "목표와 다름 — 리팩토링 후보"로 남긴다(코드는 옮기지 않는다). "현행 유지"를 고른 슬롯만 현행 값이 곧 슬롯 값이다.
4. **한 메시지로 확인** — S1~S8 초안 표(비교 결과 포함)와 관찰 목록을 보여주고 한 번에 확인받는다. 답이 없거나 아직 정할 수 없는 슬롯은 `미확정`으로 적는다. 에이전트는 미확정 슬롯에 대해 기준만 적용하고 구조를 지어내지 않으며, 첫 기능 구현 때 다시 확정을 제안한다.
5. **반영** — 확인된 값으로 Project Decisions의 슬롯 placeholder를 교체한다. 되돌리기 비용이 큰 구조 결정(S1·S4·S5)은 `agent-principles.md` 규칙 20에 따라 ADR 기록 여부를 같은 메시지에서 묻는다. 관찰 목록은 convention에 넣지 않고 후속 리팩토링 후보로 리포트에만 남긴다.

### 8. 후속 안내

적용 후 아래를 짧게 안내한다.

- `.claude/rules/project-convention.md`는 이제 **프로젝트 active convention**이며 자동 overwrite 되지 않음
- preset 전환 / diff / selective apply, devoks-core 업데이트 후 base rules/refs 갱신은 `devoks-core:setup-preset-manage` 흐름으로 수행
- `.claude/CLAUDE.md`의 Tech Stack / Commands / Architecture / Sensitive Files가 비어 있으면 함께 정리 권장
- preset은 starter이므로 placeholder와 pitfall 섹션을 프로젝트 실정에 맞게 채워야 함
- `미확정`으로 남긴 구조 슬롯과 7단계 관찰 목록(후속 리팩토링 후보)
- **그린필드:** 프로젝트 골격 B-n(스캐폴드 생성 포함)을 구현한 직후 실제 디렉터리와 S1~S3 슬롯을 한 번 대조한다 — 스캐폴드 도구가 고르는 차이(예: `src/` 사용 여부, 별칭 경로)가 슬롯과 어긋나면 그때 슬롯이나 골격 중 하나를 맞춘다(`devoks-core:setup-preset-manage`)

---

## Rules

- 자동 덮어쓰기 금지
- 감지 결과를 SSOT로 단정하지 말고, preset 추천 근거로만 사용
- 기존 프로젝트 커스터마이징이 있으면 요약 diff + 재확인 후 적용
- `Custom` 선택 시 가장 가까운 preset을 기반으로 하되, 부족한 항목은 사용자 질의로 채운다
- `CLAUDE.md`의 사실 정보와 새 convention 초안이 충돌하면 적용 전 먼저 정리한다
