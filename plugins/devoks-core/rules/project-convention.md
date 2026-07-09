# Project Convention

이 문서는 `devoks-team-harness`가 **프로젝트 컨벤션을 어떻게 운영하는지** 설명하는 core rule입니다.
프로젝트에 실제로 적용되는 스택별 코딩 규약 본문은 **별도 preset 선택/주입 단계**를 거쳐
대상 프로젝트의 `.claude/rules/project-convention.md`에 생성·관리합니다.

---

## 운영 원칙

### 1. 스택별 preset SSOT

하네스는 기술스택별 starter preset을 별도 SSOT로 관리합니다.

- `shared/conventions/react-web/project-convention.md`
- `shared/conventions/react-native/project-convention.md`
- `shared/conventions/android/project-convention.md`
- `shared/conventions/ios/project-convention.md`

이 preset들은 초기값이며, 실제 프로젝트에 주입된 뒤에는 프로젝트 상황에 맞게 조정됩니다.

### 2. 프로젝트 active convention

대상 프로젝트의 실제 코딩 규약은 아래 파일이 SSOT입니다.

- `.claude/rules/project-convention.md`

이 파일은 다음 원칙으로 다룹니다.

- 최초 하네스 setup 시 preset을 선택해 **명시적으로 생성/주입**한다.
- 이후에는 SessionStart 훅이 자동 overwrite 하지 않는다.
- 변경은 사용자가 명시적으로 실행한 setup/management 흐름에서만 반영한다.
- 프로젝트가 점진적으로 다듬은 로컬 규칙을 우선 존중한다.

### 3. 역할 분리

- `.claude/CLAUDE.md` → 프로젝트 사실 SSOT (tech stack, commands, architecture, sensitive files, UI guide 경로)
- `.claude/rules/project-convention.md` → 프로젝트 코딩 규약 SSOT (언어/프레임워크/테스트/UI/보안/주석 규칙)
- `.claude/refs/*` → 필요 시 읽는 참조 문서

동일한 사실을 여러 문서에 반복하지 않는다.

---

## 금지 사항

- 범용 하네스 rule에 특정 프로젝트/도메인 고유 규칙을 고정하지 않는다.
- SessionStart마다 프로젝트 convention을 자동 덮어쓰지 않는다.
- preset을 반영할 때 diff/설명/확인 없이 로컬 프로젝트 규칙을 덮어쓰지 않는다.
- `.claude/CLAUDE.md`의 사실 정보와 `.claude/rules/project-convention.md`의 규범 정보를 뒤섞지 않는다.

---

## Setup / Update 계약

- 신규 프로젝트: 설치 후 explicit setup 단계에서 stack preset을 선택한다.
- 기존 프로젝트: management 흐름으로 현재 active convention과 preset 차이를 비교하고, 필요한 항목만 선택 반영한다.
- preset 업데이트는 자동 전파가 아니라 opt-in 반영을 기본으로 한다.

---

## 판단 기준

프로젝트 convention을 읽을 때는 다음 순서를 따른다.

1. `.claude/CLAUDE.md`로 프로젝트 사실(언어·프레임워크·아키텍처)을 확인한다.
2. `.claude/rules/project-convention.md`로 프로젝트 규약을 확인한다.
3. 세부 절차가 필요하면 `.claude/refs/*` 또는 프로젝트 고유 SSOT 문서를 읽는다.

프로젝트 convention이 없거나 오래된 흔적이 의심되면, setup/management 흐름으로 재정렬을 제안한다.
