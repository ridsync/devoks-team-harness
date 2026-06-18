# 수정 계획 — sync-context.sh 의 gitignore 자동 추가 제거

> 상태: **하네스측 완료 (gitignore 자동 추가만 제거, 동기화 유지, branch `fix/sync-context-seed-once`) / crema-service Step 5 는 배포·재설치 후 진행**
> 발견 출처: crema-service 프로젝트 현황 조사 세션 (2026-06-18)
> 결정: **rules/refs 동기화(force-sync)는 유지한다(플러그인 번들이 SSOT). 다만 훅이 `.gitignore` 에 항목을 추가하던 동작만 제거하여, 동기화되는 파일들이 프로젝트 git 에 추적·커밋되도록 한다.** 훅은 복사만 하므로 동기화 대상이 아닌 폴더 내 프로젝트 고유 파일에는 관여하지 않는다.
> 영향 파일(SSOT): [`plugins/devoks-core/hooks/sync-context.sh`](../plugins/devoks-core/hooks/sync-context.sh)

---

## 1. 문제 (Finding)

`devoks-core` 의 SessionStart 훅 `sync-context.sh` 가 매 세션 다음 두 가지를 수행한다.

1. **강제 덮어쓰기 (24–39행)** — 플러그인 번들의 `rules/*.md`·`refs/*.md` 를 프로젝트 `.claude/` 로 복사한다. 내용이 다르면 `cp -f` 로 **프로젝트 사본을 덮어쓴다.**
2. **gitignore 추가 (41–48행)** — 프로젝트 `.gitignore` 에 `.claude/rules/`·`.claude/refs/` 를 멱등 추가한다. 주석상 의도: *"생성물은 플러그인이 SSOT이므로 git 추적에서 제외한다."*

### 충돌 내용

- **결정**: 프로젝트(crema-service)는 이 파일들을 **git에 커밋하여 관리**하기로 했다. 즉 프로젝트가 소유·편집 주체다.
- **훅 의도**: 플러그인이 SSOT이고 프로젝트 사본은 생성물(추적 제외·덮어쓰기 대상)이다.
- **결과**:
  - 팀원이 프로젝트에서 `agent-principles.md` 등을 수정·커밋해도, **다음 세션에 훅이 플러그인 번들 내용으로 되돌려(덮어써) 커밋된 커스터마이징이 유실**될 수 있다. ← 핵심 차단 요인
  - `.gitignore` 항목은 이미 추적 중인 파일에는 무해하나, 의도와 어긋나 혼란을 준다(파일이 추적되는데 ignore 목록에 존재).

### 현재 상태 (crema-service 기준, 2026-06-18 확인)

- `.gitignore` 52–53행에 `.claude/rules/`·`.claude/refs/` 존재.
- 그럼에도 아래 파일은 이미 git 추적 중(`git ls-files`):
  - `refs/`: `code-review.md`, `engineering-principles.md`, `git-convention.md`, `workflow.md`
  - `rules/`: `agent-principles.md`, `project-convention.md` (+ 동기화 비대상인 프로젝트 고유 파일 `pitfalls.md`, `project-structure.md`)
- 동기화 대상 = 플러그인 번들에 존재하는 파일뿐(`agent-principles`, `project-convention`, `memory-policy` / `code-review`, `engineering-principles`, `git-convention`, `workflow`). `pitfalls.md`·`project-structure.md` 는 프로젝트 고유로 훅이 건드리지 않음.

---

## 2. 수정 방향 (Decision)

동기화(force-sync) 자체는 그대로 **유지**한다. 플러그인 번들이 rules/refs 의 SSOT 이고, 매 세션 변경분을 프로젝트 `.claude/` 로 복사해 동기 상태를 유지하는 것은 의도된 동작이다. 훅은 **복사만** 하므로 동기화 대상이 아닌 폴더 내 프로젝트 고유 파일(예: `pitfalls.md`, `project-structure.md`)에는 관여하지 않는다.

변경은 단 하나 — **`.gitignore` 자동 추가 블록(41–48행)을 제거**한다. 이 블록이 동기화 대상 파일을 git 추적에서 제외하려 시도하면서 "프로젝트가 이 파일들을 커밋해 관리한다"는 의도와 충돌하고 혼란을 줬다. 블록을 제거하면 동기화되는 파일들이 프로젝트 git 에 그대로 추적·커밋된다.

- 트레이드오프 없음: 동기화는 유지되므로 플러그인 갱신분은 계속 전파된다. 단지 훅이 더 이상 `.gitignore` 를 건드리지 않을 뿐이다.

> **이것은 하네스 전체 정책 결정**이다(모든 사용처에 영향). 동기화 동작은 유지하고 gitignore 관여만 제거한다.

---

## 3. 실행 방법 (하네스 관리 세션)

> 작업 위치: `devoks-team-harness` 레포. 현재 브랜치 `main` → 작업 브랜치 분리 권장.

### Step 0. 브랜치 생성
```bash
cd /Users/okwon/Workspace/OKSpace/devoks-team-harness
git checkout -b fix/sync-context-seed-once
```

### Step 1. `sync-context.sh` 수정
대상: `plugins/devoks-core/hooks/sync-context.sh`

- rules/refs 복사 루프는 **그대로 유지**(force-sync). 변경분이 있으면 덮어써 동기 상태를 유지한다.
- `.gitignore` 멱등 추가 블록(41–48행) **전체 삭제** — 이것이 유일한 동작 변경이다.
- 주석(헤더)에 정책 명시: 번들이 SSOT 라 동기화는 유지, 복사만 하므로 프로젝트 고유 파일엔 비관여, `.gitignore` 에는 손대지 않아 파일이 git 추적·커밋된다.

> 버전 bump: `plugins/devoks-core/.claude-plugin/plugin.json` 의 `version` 을 `1.0.0` → `1.0.1` 로 올려 캐시 무효화·재설치를 유도(설치 캐시 경로가 버전 디렉토리 단위이므로).

### Step 2. 하네스 자체 검증
```bash
bash -n plugins/devoks-core/hooks/sync-context.sh        # 문법 검사
# 동기화 + gitignore 미관여 스모크 테스트 (임시 디렉토리)
TMP=$(mktemp -d)
CLAUDE_PLUGIN_ROOT="$PWD/plugins/devoks-core" CLAUDE_PROJECT_DIR="$TMP" \
  bash plugins/devoks-core/hooks/sync-context.sh
ls "$TMP/.claude/rules" "$TMP/.claude/refs"               # 동기화 복사 확인
echo "DRIFT" >> "$TMP/.claude/rules/agent-principles.md"   # 번들과 달라지게 변경
CLAUDE_PLUGIN_ROOT="$PWD/plugins/devoks-core" CLAUDE_PROJECT_DIR="$TMP" \
  bash plugins/devoks-core/hooks/sync-context.sh
cmp -s "$PWD/plugins/devoks-core/rules/agent-principles.md" "$TMP/.claude/rules/agent-principles.md" \
  && echo "PASS: 번들과 동기화(덮어쓰기) 정상" || echo "FAIL: 동기화 안 됨"
test -f "$TMP/.gitignore" && echo "FAIL: gitignore가 생성됨" || echo "PASS: gitignore 미생성"
rm -rf "$TMP"
```

### Step 3. 문서 갱신
- [`README.md`](../README.md): "rules/refs 는 플러그인 번들(SSOT)과 동기화되며, 훅은 `.gitignore` 에 손대지 않아 프로젝트가 이 파일들을 git 으로 추적·커밋한다"는 정책을 명시. (`plugin-management.md` 는 일반 작성 가이드로 sync 동작 설명 섹션이 없어 비대상.)

### Step 4. 커밋·배포
```bash
git add plugins/devoks-core/hooks/sync-context.sh \
        plugins/devoks-core/.claude-plugin/plugin.json \
        README.md docs/plugin-management.md docs/fix-plan-sync-context-ssot.md
git commit   # 메시지 예: "fix(devoks-core): sync-context를 seed-once로 전환하고 gitignore 강제 추가 제거"
git push -u origin fix/sync-context-seed-once
# 마켓플레이스(github:ridsync/devoks-team-harness) 반영 후 각 사용처에서 플러그인 업데이트
```

### Step 5. crema-service 측 마무리 정리 (하네스 배포·재설치 후)
> 하네스 fix 가 배포되고 crema-service에서 플러그인을 업데이트한 **뒤**에 수행해야 재추가/덮어쓰기가 재발하지 않는다.

```bash
cd /Users/okwon/Workspace/OKSpace/crema-service
# .gitignore 52-53행 제거: ".claude/rules/" , ".claude/refs/"
# (이미 추적 중이므로 git rm --cached 불필요 — 추적 유지)
git ls-files .claude/rules .claude/refs   # 추적 상태 재확인
# .gitignore 수정 후 커밋
```

---

## 4. 검증 (Definition of Done)

- [x] `sync-context.sh` 의 rules/refs 동기화(force-sync)는 유지된다(Step 2 스모크: 번들과 동기화 PASS).
- [x] 훅이 `.gitignore` 를 더 이상 수정하지 않는다(Step 2 스모크: gitignore 미생성 PASS).
- [x] `plugin.json` version bump(`1.0.0` → `1.0.1`)으로 재설치 시 신규 스크립트가 적용된다.
- [x] README 에 정책(동기화 유지 + gitignore 비관여 + git 추적) 명시(`plugin-management.md` 는 sync 동작 설명 섹션이 없어 비대상).
- [ ] crema-service `.gitignore` 에서 `.claude/rules/`·`.claude/refs/` 제거, 파일은 추적 유지, 세션 재시작 후 working-tree 변경 없음. ← 하네스 배포·재설치 후(Step 5)

## 5. 롤백

- 하네스: `git revert` 또는 해당 커밋 되돌리고 version 재bump.
- crema-service: `.gitignore` 항목 재추가(원복).

---

## 부록. 근거 (읽은 파일)

| 파일 | 확인 내용 |
|------|-----------|
| `plugins/devoks-core/hooks/sync-context.sh` | 24–39행 force-copy, 41–48행 gitignore 추가 |
| `plugins/devoks-core/hooks/hooks.json` | SessionStart `startup\|resume\|clear\|compact` 매처 |
| crema-service `.gitignore` 52–53행 | `.claude/rules/`·`.claude/refs/` 이미 존재 |
| crema-service `git ls-files .claude/{rules,refs}` | 동기화 대상 파일이 이미 추적 중 |
