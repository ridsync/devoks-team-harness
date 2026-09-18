# security-scan-execution — 보안 검증 실행 절차 (엔진 SSOT)

**호출 주체:** `code-security-reviewer` 에이전트 (subagent 안에서 실행).
진입 스킬(`devoks-sdlc:code-security-review`)의 Phase 0에서 `scope`가 이미 확정된 상태를 전제한다 —
이 문서 안에서 범위 모호성을 다시 확인하지 않는다.

리포트 출력 형식은 `report-template.md`(같은 디렉토리)가 SSOT다.

---

## 입력 파라미터

| 파라미터 | 타입 | 설명 |
|---------|------|------|
| `scope` | 경로 (전체 repo면 `.`) | 호출자가 이미 확정한 검증 대상 |
| `focus` | 선택 | 중점 카테고리(의존성 / 시크릿 / 인증인가 / 입력검증 / 설정) |
| 제외 범위 | 선택 | 벤더 디렉토리, 생성물 등 |

---

## 1. 스캔 범위·스택 감지

- 전체 repo 또는 지정 scope를 확정한다.
- 패키지 매니저·언어·프레임워크를 먼저 감지한다(`package.json`/lockfile/설정파일).
- audit·grep 등 명령은 출력을 파일로 리다이렉트해 실행하고(`<명령> > "$OUT" 2>&1; echo "exit=$?"`), 거기서 **필요한 줄만 추출**한다(대용량 출력 격리 — 원문 전체 Read 금지).

## 2. 프로젝트 고유 정책 감지 (있으면 우선)

- 프로젝트 active convention `.claude/rules/project-convention.md`의 Security 섹션, `.claude/refs/code-review.md`의 보안 항목, `.claude/CLAUDE.md`가 선언한 민감 파일/시크릿 정책이 **존재하면 우선 적용**한다.
- 없으면 범용 기준만 적용한다.
- 이 문서나 SKILL.md에 특정 식별자·파일명을 박지 않는다 — 감지값이 SSOT다.

## 3. 점검 실행

아래 카테고리를 순회하며 증거 기반으로 점검한다(추측 금지). 의심 지점은 코드 흐름을 따라 **실제 도달 가능성**을 확인한다.
`focus`가 지정됐으면 그 카테고리를 먼저·깊게 보되, 나머지 카테고리도 생략하지 않는다.

- **의존성 취약점** — 프로젝트 패키지 매니저를 감지해 해당 audit 실행(`npm/pnpm/yarn audit`, `pip-audit` 등).
- **시크릿 하드코딩** — API 키·토큰·private key·연결문자열 등 범용 패턴 전수 스캔.
- **인증·인가 경계 우회** — 보호 경로가 일관되게 가드되는지 흐름 분석(프로젝트의 가드 패턴을 먼저 식별, 특정 함수명 가정 금지).
- **입력 검증 위협** — 인젝션 / XSS / SSRF 등.
- **민감 데이터 노출 · 안전하지 않은 설정** — 민감값 로깅, CORS·암호화·기본 크리덴셜 등.

## 4. 리포트

`report-template.md`의 템플릿으로 출력한다. 이모지를 그대로 포함한다.
심각도 분류는 `.claude/refs/code-review.md §8`을 따른다.

---

## 완료 기준

- 취약점 0이면 "통과"를 명시적으로 선언한다.
- 발견 시 심각도별 집계 + 위치 + 재현/검증 방법 + 권장 조치 + 후속 테스트 필요 여부 + 즉시/후속 액션이 채워져 있다.
- 코드 수정은 제안만 하고, 적용은 사용자 승인 후.

---

## 참고 기준 문서

- **심각도 분류 SSOT**: `.claude/refs/code-review.md §8`.
- **프로젝트 규칙**: 프로젝트 active convention `.claude/rules/project-convention.md`(Security), `.claude/rules/agent-principles.md`, 필요 시 `.claude/CLAUDE.md`.
