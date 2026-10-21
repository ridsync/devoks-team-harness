# 산출물 저장 위치 규칙 (SSOT)

> 문서 산출물과 코드 산출물의 저장 위치를 분리한다. 이 규칙은 4개 스킬이 공유한다.

## 기본 워크스페이스

문서·리소스의 기본 저장 위치와 디렉토리 레이아웃(고정):

```
.claude/workspace/{feature-name}-{date}/
├─ FRD.draft.md     # 본문으로 받은 초안 원문 보존(있을 때)
├─ FRD.md           # 정련 FRD
├─ PLAN.md          # 작업 분해
├─ assets/          # 입력 시안·시각 리소스 사본 (RES-ASSET-NNN_<slug>[_<nodeid>].<ext>)
├─ captures/        # 최종 화면 캡처·스크린샷
├─ verification/    # 최종 인수·데이터 흐름·스모크 검증 리포트와 선별 증거
└─ results/         # captures/·verification/에 속하지 않는 최종 생성물
```

- **디렉토리명** — 항상 `{feature-name}-{date}` 형식(하이픈 구분). 임의 변형 금지.
- `{feature-name}` — FRD의 feature-slug(**kebab-case**). 초안에서 정해지지 않았으면 Goal로부터 짧게 만들고 1회 확인한다.
- `{date}` — 오늘 날짜 **`yyyyMMdd`** (8자리, 예 `20260609`). 실행 시 `date +%Y%m%d` 로 구한다(추측 금지).
- 예: `.claude/workspace/saved-filter-views-20260605/`
- `out` 인자가 주어지면 그 경로가 이 기본값을 덮어쓴다(이 경우에도 위 파일/`assets/`·`captures/`·`verification/`·`results/` 레이아웃은 동일하게 유지).

## 워크스페이스에 두는 것 (문서·리소스)

- **워크플로우 SSOT 문서**: `FRD.md`, `PLAN.md`, 진행 메모 등은 워크스페이스 루트.
- **입력받은 초안 사본**: 사용자가 준 FRD 초안 원문(본문으로 받았으면 `FRD.draft.md` 로 보존, 루트).
  - **`feature-interview`의 정련 요약**: 파일로 따로 남기지 않고 대화로 frd-author에 넘어가, 다른 본문 초안과 똑같이 frd-author가 `FRD.draft.md`로 보존한다(출처 헤더에 `feature-interview` 명시). 사용자가 FRD 정련을 미루면 그때만 `feature-interview`가 같은 형식으로 `FRD.draft.md`를 남긴다.
  - **덮어쓰기 금지**: `FRD.draft.md`가 이미 있으면 기존 내용을 그대로 두고 맨 아래에 새 내용을 추가한다.
- **시각 시안·리소스 사본 → `assets/`**: 작업에 쓰인 figma 스크린샷·노드 캡처·시안 이미지 등 **시각 리소스는 `<out>/assets/` 하위에 사본 저장**한다(아래 네이밍 규칙). 텍스트 메모·스펙 발췌도 여기 둘 수 있다.
- **최종 화면 캡처 → `captures/`**: 라이브 렌더·에뮬레이터·실동작 검증에서 최종 증빙으로 남길 스크린샷은 `<out>/captures/`에 저장한다. 파일명은 목적이 드러나게 `render_<screen>.png`, `acceptance_fail_<ac-id>.png`처럼 짓는다.
- **최종 검증 결과 → `verification/`**: 인수·데이터 흐름·스모크 검증 리포트와 결론에 필요한 선별 로그/스냅샷은 `<out>/verification/`에 저장한다. 대용량 원시 로그는 보관 대상이 아니면 임시 위치에서 정리한다.
- **그 외 최종 생성물 → `results/`**: 위 두 분류에 맞지 않는 최종 파일만 `<out>/results/`에 저장한다. `results/`를 범용 덤프 폴더로 사용하지 않는다.
- **경로만 기록(사본 생략)**: 시안 외 대용량·무관 바이너리, 또는 저장소 안에 이미 있는 리소스는 복사하지 말고 경로만 기록한다.

### `assets/` 네이밍 규칙

- 파일명: **`RES-ASSET-{NNN}_<slug>[_<nodeid>].<ext>`** (예: `RES-ASSET-001_layout_5088-1757.png`).
- `RES-ASSET-{NNN}` ID는 **FRD §6.3 Assets 표의 ID와 일치**시킨다(문서↔파일 양방향 추적).
- FRD §6.3에서는 `assets/RES-ASSET-001_layout_5088-1757.png` 처럼 워크스페이스 상대 경로로 참조한다.

→ 결과적으로 한 기능의 "사고 과정 문서 일체"(문서 + 시안)가 한 디렉터리에 모인다(재개·인수인계 용이).

## 워크스페이스에 두지 않는 것 (코드)

- 스킬이 **생성/수정한 소스 코드**는 워크스페이스가 아니라 **프로젝트 본래 위치**(예: `src/...`)에 둔다.
- PLAN Task의 `file:` 경로는 항상 실제 코드 위치를 가리킨다. 워크스페이스로 옮기지 않는다.

## 재진입 / 조회

- 이미 워크스페이스가 있으면(같은 feature-name) 새로 만들지 말고 그 디렉터리를 이어서 쓴다.
- executor가 PLAN 경로를 못 받으면, 가장 최근 `.claude/workspace/*/PLAN.md` 를 후보로 제시하고 확인한다.
