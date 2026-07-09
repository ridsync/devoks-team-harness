# Convention Presets

기술스택별 `project-convention.md` starter preset SSOT 모음.

## 운영 원칙

- 이 디렉토리의 문서는 **하네스가 제공하는 초기 preset 원본**이다.
- 실제 프로젝트에는 setup 흐름이 선택한 preset을 `.claude/rules/project-convention.md`로 주입한다.
- 주입 이후의 `.claude/rules/project-convention.md`는 **프로젝트 active convention**이며, 프로젝트가 점진적으로 다듬는다.
- preset 업데이트는 자동 overwrite 하지 않는다. 명시적 setup/management 흐름으로만 반영한다.

## Presets

- `react-web/`
- `react-native/`
- `android/`
- `ios/`

필요 시 새 스택 preset을 추가하되, 플랫폼·언어·UI·테스트·보안·프로젝트 결정 섹션의 공통 골격은 유지한다.
