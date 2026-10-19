---
name: setup-preset-manage
description: devoks setup(setup-project-convention·setup-mcp)이 플러그인 밖에 남긴 산출물을 점검·갱신한다 — active convention의 preset provenance 확인·diff·selective apply·재적용·스택 전환, devoks 플러그인 업데이트 후 base rules/refs와 ~/.devoks 스크립트(chrome-debug.sh·metro-mcp.js) 갱신. "devoks 업데이트 후 갱신", "base 갱신", "convention 점검", "preset 전환" 요청에서 사용한다.
---

# Setup Preset Manage

## Overview

플러그인 스킬·에이전트·훅은 플러그인 업데이트와 함께 자동으로 최신이 되지만, setup이 **플러그인 밖으로 복사한 파일은 그대로 남는다.**
이 스킬은 그 산출물 전부를 한 곳에서 점검·갱신한다. devoks 플러그인을 업데이트한 뒤 이 스킬을 한 번 실행하는 것이 표준 절차다.

| 산출물 | 위치 | 원본 | 성격 | 다루는 절 |
|---|---|---|---|---|
| active convention | `.claude/rules/project-convention.md` | `${CLAUDE_PLUGIN_ROOT}/conventions/<preset>/` | preset에서 출발해 **프로젝트가 커스터마이징** | Steps 1~6 (섹션 단위) |
| base rules/refs 7종 | `.claude/rules/`·`.claude/refs/` | `${CLAUDE_PLUGIN_ROOT}/rules·refs/` | 원본 사본 | "base 갱신" (파일 단위) |
| `chrome-debug.sh` | `~/.devoks/bin/` | `${CLAUDE_PLUGIN_ROOT}/assets/chrome-debug.sh` | 원본 사본 (기본 URL은 `~/.devoks/chrome-debug.url`에 별도) | "~/.devoks 스크립트 갱신" |
| `metro-mcp.js` | `~/.devoks/mcp/` | devoks-rn 플러그인 `scripts/metro-mcp.js` | 원본 사본 | "~/.devoks 스크립트 갱신" |

핵심 원칙은 **자동 overwrite 금지**이며, 항상 현황 파악 → diff 설명 → 사용자 확인 → 적용 순서를 따른다.
SessionStart 훅(`hooks/check-setup-state.sh`)은 위 산출물이 원본과 달라졌을 때 이 스킬을 안내만 하고, 직접 고치지 않는다.

---

## SSOT

- 프로젝트 active convention: `.claude/rules/project-convention.md`
- preset provenance metadata: `.claude/project-convention.json` (`presetHash` = preset 기준, `devoksCoreVersion` = base 기준)
- preset 원본: `${CLAUDE_PLUGIN_ROOT}/conventions/<preset>/project-convention.md`
- base rules/refs 원본(7종, 목록 SSOT는 `hooks/check-setup-state.sh`의 `BASE_FILES`): `${CLAUDE_PLUGIN_ROOT}/rules/{agent-principles,memory-policy}.md`, `${CLAUDE_PLUGIN_ROOT}/refs/{code-review,engineering-principles,git-convention,interaction-integrity,workflow}.md` → 프로젝트 `.claude/rules/`·`.claude/refs/` 같은 이름
- 적용 당시 원본 스냅샷(3-way merge base): `.claude/.devoks-base/` — `rules/`·`refs/`(base 7종)와 `preset/project-convention.md`. setup·이 스킬이 원본을 반영할 때마다 함께 갱신한다. `.claude/rules/`와 같은 git 추적 정책을 따른다(팀이 rules를 커밋하면 스냅샷도 커밋)
- 버전별 변경 사유: `${CLAUDE_PLUGIN_ROOT}/CHANGELOG.md`
- 프로젝트 사실 SSOT: `.claude/CLAUDE.md`

---

## 지원 작업

- 현재 convention이 어떤 preset 기반인지 확인
- current vs preset 차이 요약
- upstream preset 재적용
- selective apply (일부 섹션만 반영)
- React Web / React Native / Android / iOS / Custom 간 전환
- `.claude/CLAUDE.md`와 convention 사이의 stack drift 점검
- legacy convention이 bundled copy 잔재인지, 실제 프로젝트 커스터마이징인지 추정
- devoks-core 업데이트 후 base rules/refs 7종 갱신 (아래 "base 갱신" 절)
- devoks-core·devoks-rn 업데이트 후 `~/.devoks` 스크립트 갱신 (아래 "~/.devoks 스크립트 갱신" 절)

---

## Steps

### 1. 현황 파악

먼저 아래를 읽는다.

- `.claude/project-convention.json`
- `.claude/rules/project-convention.md`
- `.claude/CLAUDE.md` (있으면)

#### hash 사전 체크 (`presetHash`가 있을 때)

`.claude/project-convention.json`에 `presetHash`가 있으면, 전체 diff·유사도 추론을 돌기 전에 먼저
값싸고 정확한 same/different 사전 필터를 돈다.

1. `${CLAUDE_PLUGIN_ROOT}/conventions/<preset>/project-convention.md`의 현재 `sha256`을 계산한다
   (예: `shasum -a 256`).
2. 저장된 `presetHash`와 **동일** → "업스트림 preset 변경 없음"으로 즉시 보고한다. 사용자가 명시적으로
   전체 diff를 요청하지 않는 한 아래 3~4단계(drift 판단·diff 제시)는 생략한다.
3. **다르면** → "업스트림 preset이 변경됨"을 알리고 3~4단계로 그대로 진행한다. 적용 후에는 `presetHash`를
   최신 값으로 갱신한다(5단계).

`presetHash`가 **없으면**(이 필드 도입 이전에 생성된 레거시 provenance) 에러 없이 아래 기존 추정
체인으로 폴백한다 — 강제 재설정 없음.

metadata가 없으면 다음 순서로 추정하되, **확정으로 단정하지 않는다.**

1. 코드베이스 시그널 확인
2. 현재 convention 내용과 preset 유사도 비교
3. 사용자에게 provenance 확인 질문

### 2. 작업 유형 분류

사용자 요청을 아래 중 하나로 분류한다.

- **점검**: 현재 상태만 설명
- **재적용**: 같은 preset의 최신 내용을 반영
- **전환**: 다른 preset으로 변경
- **정리**: 현재 convention을 구조적으로 정돈
- **선택 반영**: 일부 섹션만 가져오기
- **base 갱신**: devoks-core 업데이트분을 base rules/refs 7종에 반영 — 아래 "base 갱신" 절로 바로 간다(3~5단계는 project-convention.md 전용)
- **스크립트 갱신**: `~/.devoks` 스크립트를 최신 원본으로 교체 — 아래 "~/.devoks 스크립트 갱신" 절로 바로 간다
- **업데이트 후 일괄 점검**("devoks 업데이트했어", "전부 최신인지 봐줘"): 4종 모두의 최신 여부를 한 표로 보여준 뒤, 달라진 항목만 해당 절로 진행한다

"점검" 요청이면 convention 외에 base 7종과 `~/.devoks` 스크립트의 최신 여부(각 절 1단계)도 함께 보고한다.

### 3. drift / provenance 판단

아래를 먼저 요약한다.

- 현재 preset provenance 유무
- `CLAUDE.md`의 stack 사실과 active convention의 일치 여부
- active convention이 preset의 예시 스택/코드를 그대로 쓰는지, 프로젝트 실제 값으로 교체됐는지
- 로컬 커스터마이징이 어느 정도 누적됐는지

### 4. diff 제시

코드/문서 변경 전 반드시 아래를 요약한다. preset 스냅샷(`.claude/.devoks-base/preset/project-convention.md`)이 있으면 스냅샷 ↔ 새 preset diff로 **upstream이 바꾼 섹션만** 먼저 골라내고(사유는 `CHANGELOG.md`), 그 섹션에 한해 현재 convention과 비교한다 — 스냅샷 ↔ 현재 convention 차이는 로컬 커스터마이징이므로 유지 대상이다.

- 바뀌는 섹션
- 유지되는 로컬 커스터마이징
- 제거/덮어쓰기 되는 내용
- `CLAUDE.md`와 충돌하는 항목
- preset 예시값(스택 선택, SSOT 경로 등)이 새로 생기거나 여전히 프로젝트 실제 값으로 교체되지 않고 남는 항목

#### selective apply 옵션

재적용/전환 시 아래 같은 단위로 선택 반영을 제안할 수 있다.

- Stack
- Core Rules
- Design Pattern
- Comments & Docs / Comment Rules
- Pitfalls
- Project Decisions

전체 재적용이 필요하지 않으면 일부 섹션만 반영하는 쪽을 우선 제안한다.

### 5. 사용자 확인 후 적용

적용 시 아래 원칙을 지킨다.

- `.claude/rules/project-convention.md`를 직접 덮어쓸 수 있는 작업은 반드시 사용자 확인 후에만 수행
- provenance metadata를 함께 갱신 — `presetHash`도 현재 preset 원본의 최신 해시로 갱신
- preset 스냅샷(`.claude/.devoks-base/preset/project-convention.md`)을 반영한 preset 원본으로 갱신(`command cp -f`) — 일부 섹션만 반영했어도 거부한 섹션이 다시 제안되지 않도록 갱신한다
- preset 전환 후에는 `.claude/CLAUDE.md`의 Tech Stack / Commands / Architecture / Sensitive Files도 drift 여부를 점검
- `Custom` 흐름은 가장 가까운 preset + 사용자 보정값으로 처리

### 6. 마무리 리포트

최종 리포트에는 아래를 포함한다.

- 적용한 preset / source
- 적용 모드 (`full apply` / `selective apply` / `switch` / `cleanup`)
- preset이 최신 상태였는지, 업스트림 변경으로 갱신됐는지 (`presetHash` 일치 여부)
- 유지한 로컬 커스터마이징
- 추가로 프로젝트 실제 값으로 바꿔야 할 preset 예시 항목 (Stack, Project Decisions 등)
- 필요 시 다음 액션 (`CLAUDE.md` 보강, 테스트 스택 명시, UI guideline SSOT 연결 등)

---

## base 갱신

base 7종은 devoks-core 원본의 사본이지만, 프로젝트가 일부 줄을 고쳐 쓰는 경우가 있다. 사본과 새 원본만 비교하는 2-way diff로는 "upstream이 바꾼 줄"과 "로컬에서 고친 줄"을 구분할 수 없으므로, **적용 당시 원본 스냅샷**을 기준(merge base)으로 3-way 판정한다. 각 변경의 **사유**는 `${CLAUDE_PLUGIN_ROOT}/CHANGELOG.md`에서 가져온다.

### 1. 상태 판정

설치 버전(`basename "${CLAUDE_PLUGIN_ROOT}"`, 버전 형태가 아니면 `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json` → `${CLAUDE_PLUGIN_ROOT}/plugin.json`의 `version`)과 provenance의 `devoksCoreVersion`을 함께 보여준다. 7종 각각에 대해 사본(`.claude/<rel>`)·스냅샷(`.claude/.devoks-base/<rel>`)·새 원본(`${CLAUDE_PLUGIN_ROOT}/<rel>`)을 `cmp -s`로 비교해 하나로 분류한다.

| 상태 | 조건 | 처리 |
|---|---|---|
| 최신 | 사본 = 새 원본 | 없음 (스냅샷이 다르면 새 원본으로 맞춰 둔다) |
| upstream만 변경 | 사본 = 스냅샷 ≠ 새 원본 | 새 원본으로 교체 가능 |
| 로컬만 변경 | 스냅샷 = 새 원본 ≠ 사본 | 없음 — 로컬 커스터마이징 유지 |
| 양쪽 변경 | 셋 다 다름 | 3단계 병합 |
| 신규 | 사본 없음 | 새 원본 복사 |
| 스냅샷 없음 | 스냅샷 파일 없음 | 아래 "스냅샷 없는 프로젝트(이전)" 절차 |

전부 `최신`·`로컬만 변경`이면 "upstream 변경 없음"으로 보고하고 끝낸다(버전만 다르면 `devoksCoreVersion` 갱신만 제안).

### 2. 변경 사유 제시

`upstream만 변경`·`양쪽 변경`·`신규` 파일에 대해 CHANGELOG에서 `devoksCoreVersion` **초과** ~ 설치 버전 **이하** 구간의 해당 파일 항목을 모아 `파일 › 섹션: 변경 — 사유`로 보여준다. CHANGELOG에 항목이 없는데 내용이 다르면 그 사실을 명시한다(기록 누락 — harness에 보고 대상).

CHANGELOG가 "거부해도 된다"고 적은 변경(예: 1.6.0 `memory-policy.md` context-mode 행 삭제)이나 프로젝트 환경과 맞지 않는 변경은 사용자가 **거부**할 수 있음을 알린다.

### 3. 병합 (`양쪽 변경`)

```bash
git merge-file -p -L 로컬 -L 기준 -L 새원본 .claude/<rel> .claude/.devoks-base/<rel> "${CLAUDE_PLUGIN_ROOT}/<rel>" > <임시파일>
```

- 종료코드 0 = 충돌 없이 병합됨, 양수 = 충돌 블록 수, 음수 = 실행 오류. git 저장소 밖에서도 동작한다.
- 충돌 블록마다 로컬·새 원본 양쪽 내용과 CHANGELOG 사유를 함께 보여주고 어느 쪽을 쓸지 확인받는다. 충돌 표시(`<<<<<<<`)가 남은 채로 쓰지 않는다.

### 4. 사용자 확인 후 적용

파일별로 **반영 / 거부 / 보류** 중 하나를 확인받는다.

- **반영** — `upstream만 변경`·`신규`는 `command cp -f <새 원본> .claude/<rel>`(셸 프로필의 `cp -i` 별칭이 덮어쓰기를 조용히 거부하는 것을 피한다), `양쪽 변경`은 병합 결과로 사본을 쓴다.
- **거부** — 사본은 그대로 둔다. upstream 변경을 의도적으로 받지 않은 것이므로 다음 갱신 때 다시 제안되지 않게 스냅샷은 갱신한다.
- **보류** — 사본·스냅샷 모두 그대로 둔다(다음 갱신 때 다시 제안된다).

반영·거부한 파일은 스냅샷을 새 원본으로 갱신한다(`command cp -f <새 원본> .claude/.devoks-base/<rel>`). 마지막으로 `.claude/project-convention.json`의 `devoksCoreVersion`을 설치 버전으로 갱신한다(다른 필드는 그대로) — 보류한 파일이 있어도 갱신하고, 리포트에 보류 목록을 남긴다.

### 5. 리포트

파일별 상태·처리(반영/거부/보류/유지)·근거가 된 CHANGELOG 항목·버전 변화(`<이전> → <현재>`)를 표로 남긴다.

### 스냅샷 없는 프로젝트(이전)

devoks-core 2.1.0 이전에 setup했거나 provenance(`.claude/project-convention.json`) 자체가 없는 프로젝트(레거시 자동 동기화 시절 사본 포함)는 merge base가 없다. 1회만 아래 절차로 기준을 추정하고, 그 뒤로는 스냅샷을 기록해 3-way로 운영한다.

1. **기준 추정** — 플러그인 캐시에 남아 있는 devoks-core 버전들(`ls -d ~/.claude/plugins/cache/*/devoks-core/*/`)의 각 파일과 사본을 `diff`로 비교해, 차이가 가장 작은 버전을 그 파일의 기준 후보로 삼는다. 구버전 캐시는 업데이트 14일 뒤 정리되므로 남아 있는 버전으로만 판단할 수 있다.
2. **CHANGELOG 대조** — 사본과 새 원본의 차이 줄을 CHANGELOG의 과거 항목과 대조해 "upstream 원본의 잔재"와 "로컬 커스터마이징"을 구분한다. 예: 1.1.4에서 삭제된 `workflow.md` APK 섹션이나 `agent-principles.md`의 `(auth, brew, sensor-ingest)` 예시가 사본에 남아 있다면 로컬 커스터마이징이 아니라 upstream 잔재다. 어느 쪽인지 판정할 수 없는 줄은 그렇다고 표시한다(추측으로 분류하지 않는다).
3. **추정 기준을 스냅샷으로 써서** 위 1~5단계를 그대로 진행한다. 캐시에 쓸 만한 버전이 없으면 2단계 판정만 근거로 파일별 반영 여부를 확인받는다.
4. provenance가 없었으면 preset을 사용자에게 확인받아 `.claude/project-convention.json`을 생성한다(`managedBy`: `devoks-core:setup-preset-manage`, `mode`: `base-merge`). preset 원본 스냅샷도 함께 기록한다 — `project-convention.md` 자체는 이 절에서 바꾸지 않는다.

---

## ~/.devoks 스크립트 갱신

`setup-mcp`가 사용자 홈에 복사한 실행 스크립트다. 프로젝트와 무관한 user 단위 산출물이므로 provenance 없이 원본과 직접 비교한다. **사용자 파일이 없으면 setup을 안 한 것이므로 건너뛴다**(새로 만들지 않는다 — 설치는 `/devoks-core:setup-mcp` 소관).

1. **원본 위치 확인**
   - `chrome-debug.sh`: `${CLAUDE_PLUGIN_ROOT}/assets/chrome-debug.sh`
   - `metro-mcp.js`: devoks-rn은 다른 플러그인이라 `${CLAUDE_PLUGIN_ROOT}`로 닿지 않는다. 공식 캐시 구조(`~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/`)에서 찾는다 — `setup-mcp` Step 5와 같은 방식:
     ```bash
     find ~/.claude/plugins/cache/devoks-plugins/devoks-rn -name metro-mcp.js -path "*/scripts/*" 2>/dev/null | sort -V | tail -1
     ```
     결과가 없으면 devoks-rn 미설치로 보고하고 이 항목은 건너뛴다.
2. **차이 확인** — `cmp -s <원본> <사용자 파일>`로 `동일 / 변경`을 판정한다. `변경`이면 `diff -u <사용자 파일> <원본>`을 읽고 1~3줄로 요약한다.
   - **`chrome-debug.sh` 구버전 이전**: devoks-core 2.0.0 이전 런처는 기본 URL을 본문(`START_URL="${1:-<URL>}"`)에 박아 넣었다. 그 줄에서 URL을 추출해 `~/.devoks/chrome-debug.url`이 없으면 그 값으로 만들도록 함께 제안한다(교체 후에도 인자 없는 실행이 그대로 동작하게).
   - 그 외 사용자가 손댄 흔적이 보이면 덮어쓰면 사라진다고 명시한다.
3. **사용자 확인 후 적용** — `command cp -f <원본> <사용자 파일>` 후 `chmod +x`(`chrome-debug.sh`). MCP 등록은 경로가 그대로이므로 다시 하지 않는다. `metro-mcp.js`를 교체했으면 **Claude Code 재시작 후 반영**된다고 안내한다(MCP 서버 프로세스가 기존 파일로 떠 있다).
4. **리포트** — 항목별 `동일 / 교체 / 건너뜀(사유)`.

---

## Rules

- preset은 시작점이지 프로젝트 절대 진실이 아니다.
- 프로젝트가 실제로 정착시킨 규칙을 존중한다.
- 감지 결과와 `.claude/CLAUDE.md` 사실이 충돌하면 사용자에게 확인한다.
- 대규모 재적용은 diff 요약 없이 바로 수행하지 않는다.
- 가능하면 full overwrite보다 selective apply를 먼저 검토한다.
- 새 setup 산출물(플러그인 밖으로 복사되는 파일)을 추가하는 플러그인 변경은 이 스킬의 Overview 표와 SessionStart 훅 감지에 함께 등록한다 — 등록하지 않으면 업데이트 누락이 다시 생긴다.
