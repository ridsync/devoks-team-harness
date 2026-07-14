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
- 참조 문서: `${CLAUDE_PLUGIN_ROOT}/refs/*.md`
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
  - Android: `android/`, `build.gradle*`, `settings.gradle*`
  - iOS: `ios/`, `Package.swift`, `*.xcodeproj`, `*.xcworkspace`

감지 결과는 **preset 추천 근거**에만 사용한다. 감지값을 SSOT로 단정하지 않는다.

### 2. 추천 preset 제안

다음 중 하나를 추천하거나, 확신이 낮으면 추천 없이 질문한다.

- React Web
- React Native
- Android
- iOS
- Custom

추천 시에는 반드시 근거를 함께 말한다.

예:
- `package.json`에 `react-native`와 `expo`가 있어 React Native 추천
- `android/`만 있고 Gradle 설정이 보여 Android 추천
- `ios/`와 Xcode project가 있어 iOS 추천

### 3. 적용 범위 설명

사용자에게 아래 적용 범위를 설명하고 확인받는다.

1. `.claude/rules/agent-principles.md` 복사/갱신
2. `.claude/rules/memory-policy.md` 복사/갱신
3. `.claude/refs/*.md` 복사/갱신
4. 선택한 preset을 `.claude/rules/project-convention.md`로 생성 또는 교체
5. `.claude/project-convention.json` 생성/갱신

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
- 선택한 preset 원본을 `.claude/rules/project-convention.md`로 복사
- 필요 시 `Custom` 보정 내용을 같은 파일에 반영
- preset 원본 파일의 `sha256` 해시를 계산(예: `shasum -a 256 "${CLAUDE_PLUGIN_ROOT}/conventions/<preset>/project-convention.md"`)
- `.claude/project-convention.json`에 provenance 저장 — 이 해시를 `presetHash`로 함께 기록

metadata 예시:

```json
{
  "preset": "react-web",
  "source": "${CLAUDE_PLUGIN_ROOT}/conventions/react-web/project-convention.md",
  "presetHash": "<sha256>",
  "managedBy": "devoks-core:setup-project-convention",
  "mode": "fresh-apply"
}
```

`presetHash`는 이후 `devoks-core:project-convention-manage`가 "업스트림 preset이 그 사이 바뀌었는지"를
값싸고 정확하게 판단하는 사전 필터로 쓴다 — preset 원본 내용이 변경될 때만 값이 달라진다.

### 7. 후속 안내

적용 후 아래를 짧게 안내한다.

- `.claude/rules/project-convention.md`는 이제 **프로젝트 active convention**이며 자동 overwrite 되지 않음
- preset 전환 / diff / selective apply는 `devoks-core:project-convention-manage` 흐름으로 수행
- `.claude/CLAUDE.md`의 Tech Stack / Commands / Architecture / Sensitive Files가 비어 있으면 함께 정리 권장
- preset은 starter이므로 placeholder와 pitfall 섹션을 프로젝트 실정에 맞게 채워야 함

---

## Rules

- 자동 덮어쓰기 금지
- 감지 결과를 SSOT로 단정하지 말고, preset 추천 근거로만 사용
- 기존 프로젝트 커스터마이징이 있으면 요약 diff + 재확인 후 적용
- `Custom` 선택 시 가장 가까운 preset을 기반으로 하되, 부족한 항목은 사용자 질의로 채운다
- `CLAUDE.md`의 사실 정보와 새 convention 초안이 충돌하면 적용 전 먼저 정리한다
