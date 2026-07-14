# Convention Presets

기술스택별 `project-convention.md` starter preset SSOT 모음.

## 운영 원칙

- 이 디렉토리의 문서는 **하네스가 제공하는 초기 preset 원본**이다.
- preset은 bracket 선택형 메뉴가 아니라, 스택별로 하나의 예시를 **구체적으로 결정한 코드/테이블 형태**로 작성한다. 프로젝트는 이 예시를 실제 선택으로 즉시 교체한다.
- 실제 프로젝트에는 setup 흐름이 선택한 preset을 `.claude/rules/project-convention.md`로 주입한다.
- 주입 이후의 `.claude/rules/project-convention.md`는 **프로젝트 active convention**이며, 프로젝트가 점진적으로 다듬는다.
- preset 업데이트는 자동 overwrite 하지 않는다. 명시적 setup/management 흐름으로만 반영한다.
- preset 예시에는 특정 프로젝트의 도메인 용어(제품명, 업종 특화 로직 등)를 남기지 않는다. 어느 프로젝트에도 재사용 가능한 제네릭 예시(Product, Item 등)만 사용한다.

## Presets

- `react-web/`
- `react-native/`
- `android/`
- `ios/`

필요 시 새 스택 preset을 추가하되, 플랫폼·언어·UI·테스트·보안·프로젝트 결정 섹션의 공통 골격은 유지한다.

---

## 프로젝트 규칙 문서 간 역할 분리

대상 프로젝트에는 아래 3종 문서가 각자 다른 역할을 맡는다. 동일한 사실을 여러 문서에 반복하지 않는다.

- `.claude/CLAUDE.md` → 프로젝트 사실 SSOT (tech stack, commands, architecture, sensitive files, UI guide 경로)
- `.claude/rules/project-convention.md` → 프로젝트 코딩 규약 SSOT (언어/프레임워크/테스트/UI/보안/주석 규칙) — 이 디렉토리의 preset이 주입되는 대상
- `.claude/refs/*` → 필요 시 읽는 참조 문서

## 금지 사항

- 범용 preset에 특정 프로젝트/도메인 고유 규칙을 고정하지 않는다.
- SessionStart마다 프로젝트 convention을 자동 덮어쓰지 않는다.
- preset을 반영할 때 diff/설명/확인 없이 로컬 프로젝트 규칙을 덮어쓰지 않는다.
- `.claude/CLAUDE.md`의 사실 정보와 `.claude/rules/project-convention.md`의 규범 정보를 뒤섞지 않는다.

## 판단 기준

프로젝트 convention을 읽을 때는 다음 순서를 따른다.

1. `.claude/CLAUDE.md`로 프로젝트 사실(언어·프레임워크·아키텍처)을 확인한다.
2. `.claude/rules/project-convention.md`로 프로젝트 규약을 확인한다.
3. 세부 절차가 필요하면 `.claude/refs/*` 또는 프로젝트 고유 SSOT 문서를 읽는다.

프로젝트 convention이 없거나 오래된 흔적이 의심되면, `devoks-core:setup-project-convention` / `devoks-core:project-convention-manage` 흐름으로 재정렬을 제안한다.
