# issue-parsing-and-gap-analysis — 이슈 로드·파싱·갭 분석 SSOT

**호출 주체:** `devoks-sdlc:new-feature-by-github-issue` 스킬 본문(메인 루프에서 직접 수행).
Phase 0(이슈 로드·파싱·갭 분석)에서 이 문서의 알고리즘·차단 규칙을 그대로 적용한다.

---

## 이슈 본문 가져오기 (우선순위)

1. **GitHub MCP** — 이슈 조회 도구 사용 **전** 해당 MCP의 tool 스키마를 확인한다.
2. **`gh issue view`** — MCP 불가 시.
3. **본문 붙여넣기** — 위 둘 모두 불가할 때.

`owner`/`repo`는 `git remote get-url origin`으로 파싱한다. 실패 시 사용자에게 직접 묻는다(`/devoks-git:git-create-issue`의 저장소 식별과 동일한 패턴).

---

## 이슈 양식 파싱 (고정 헤더)

### 1차 앵커 (SSOT)

`.github/ISSUE_TEMPLATE/feature_task.md`의 최상위 섹션 제목을 그대로 키로 사용한다.

- `### Description`
- `### Objectives`
- `### Definition of Done`
- `### Additional Context`
- `### Decisions (With Agents)`

### 알고리즘

1. YAML 프론트매터(`---` … `---`)가 있으면 제거한 뒤 파싱한다.
2. 본문을 `^### ` 로 시작하는 줄로 분할해 섹션 맵을 만든다.
3. `### Additional Context` 안에 `/devoks-git:git-create-issue`에서 정의한 선택 소제목이 있으면 하위 필드로 매핑한다: `#### 배경 및 문제 정의`, `#### 범위`, `#### 범위 밖`, `#### 영향 파일`, `#### 미결정 사항`. 없으면 "미사용"으로 두고 상위 섹션 전체만 사용한다.
4. **인용 블록**: `Additional Context` 등에 `>` 로 시작하는 줄이 있으면, 파싱용으로 **선행 `>\s?` 를 제거한 정규화 복사본**을 만들어 요약·갭 분석에 쓴다(원문 보존이 필요하면 별도 유지).

### 대체 템플릿

`.github/ISSUE_TEMPLATE/feature_request.md`처럼 `### Definition of Done` 대신 `### Sub Tasks` 만 있는 경우:

- `Sub Tasks`를 구현·검증 체크리스트의 근거로 삼는다.
- `Definition of Done` 이 비어 있으면 완료 조건 갭 분석에 **Sub Tasks**를 반영한다.

### 템플릿 부재·불일치 시 (폴백)

위 고정 헤더 5종은 `/devoks-git:git-create-issue`가 생성하는 이슈 본문 구조이자 **이 스킬 자체의 SSOT**다 — 대상 저장소에 실제 `.github/ISSUE_TEMPLATE/feature_task.md` 파일이 있는지는 전제하지 않는다(파일이 없어도, 팀이 다른 템플릿을 쓰거나 이슈를 수기로 작성했어도 동작해야 한다).

1. 이슈 본문에서 `^### ` 헤더를 먼저 찾는다. 5개 키(`Description`/`Objectives`/`Definition of Done`/`Additional Context`/`Decisions (With Agents)`) 중 **하나도 매칭되지 않으면** 이 템플릿을 쓰지 않은 이슈로 간주한다.
2. 매칭 실패 시 본문 전체를 비정형 텍스트로 보고 휴리스틱으로 대응시킨다: 첫 문단(또는 이슈 제목 다음 요약) → `Description`, "목표"·"Goal"·"왜" 관련 문단 → `Objectives`, 체크박스(`- [ ]`) 목록이나 "완료 조건"·"Acceptance Criteria" 관련 문단 → `Definition of Done`/`Sub Tasks`.
3. 휴리스틱으로도 **완료 조건에 대응하는 내용을 전혀 찾을 수 없으면**, 추측으로 채우지 않고 아래 "이슈가 부실할 때 (갭 분석)"의 갭 유형에 `구조 불일치(템플릿 미사용)`로 올려 사용자에게 확인한다.
4. 대상 저장소에 실제 `.github/ISSUE_TEMPLATE/feature_task.md`가 있고 헤더 구성이 다르면 **그 실제 파일을 우선**한다 — 이 문서의 5개 헤더는 파일이 없거나 확인할 수 없을 때의 참고 기본값이다.

### 연결 이슈

본문에 `Related: #123`, `Closes #456` 형태의 이슈 번호가 있으면, 디자인·스펙이 다른 이슈에 있을 수 있다. **해당 번호 이슈를 추가로 조회할지** 사용자에게 확인하거나, 한 줄로 제안한다.

---

## UI / 디자인 참조

레이아웃·시각 스펙은 **이슈 본문에 링크·식별자로 고정**하거나, 연결 이슈·문서 **한 곳**에 모은다.

### 권장 소제목 (관례)

`### Additional Context` 안에 다음을 두면 파싱·갭 검사가 쉽다.

- `#### UI / Design` — 디자인 도구 **파일 URL + node-id**(해당 시), 기획/스토리보드 링크, 핵심 화면 캡처(이슈 첨부) 등.

### 차단 조건 (UI)

- `Definition of Done`(또는 `Sub Tasks`)에 **UI 변경·화면 작업**이 분명히 포함되는데, 위 소제목·링크·이미지·연결 이슈 중 **어느 것도 없어** 구현 근거가 없을 때 → 구현 착수 전 **갭으로 차단**하고, 링크·캡처·스펙·연결 이슈 중 최소 하나를 요청한다.
- 기능만의 이슈(화면 변경 없음)는 예외로 둔다.

### UI 전용 Skill과 조합

UI 구현이 걸린 이슈면 UI 전용 절차(`/devoks-sdlc:new-ui-draft` 스킬)와 병행한다고 이슈에 적는다.

---

## 이슈가 부실할 때 (갭 분석)

### 구현 착수 전 차단 예시

- `Description`이 비었거나 플레이스홀더만 있다.
- `Definition of Done` 또는 `Sub Tasks`에 측정 가능한 완료 조건·검증이 없다.
- `Decisions (With Agents)` 가 비어 있고 스코프·기술 선택이 모호하다.
- 위 **UI / 디자인** 차단 조건에 해당한다.
- 이슈 본문이 고정 헤더 구조를 전혀 따르지 않고, 폴백 휴리스틱으로도 완료 조건에 대응하는 내용을 찾을 수 없다(`구조 불일치`).

### 에이전트 출력 형식 (고정)

1. **갭 표**: `섹션 | 상태(비어 있음/모호함/TBD) | 리스크`
2. **확인 질문**: 한 번에 **1~2개**만. 사용자에게 선택지를 직접 제시하여 확인한다.
3. **보완 경로**: (A) 채팅에서 답변 (B) GitHub 이슈 본문 수정 후 동일 이슈 URL/번호 재제공.

### 원칙

계약·스코프에 큰 영향이 있는 내용은 **추측으로 채우지 않는다**. 프로젝트의 Fail-Fast·계약 검증 규칙은 `.claude/CLAUDE.md`, `.claude/rules/`, `.claude/refs/`를 따른다.
