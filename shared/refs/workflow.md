# Workflow

워크플로우 규칙은 작업 진행 절차와 기준을 정의하며, 테스트 작성, 코드 리뷰, Git 컨벤션, 배포 방식 등 개발 과정 전반에 필요한 핵심 지침을 요약합니다. 모든 팀원은 일관된 품질과 효율을 위해 본 문서의 내용을 준수해야 합니다.

---

## Testing

> 명령어: `CLAUDE.md > Commands` 참조

- 새 기능: 관련 테스트 작성 권장. 미작성 시 이유를 완료 메시지에 명시.
- 기존 테스트 깨짐: 수정 필수
- 환경: happy-dom (경량 DOM), setupFiles: `src/setupTests.js`

---

## Code Review

> 상세 규칙: `.claude/code-review.md` (SSOT)

---

## Git Convention

> 상세 규칙: `.claude/git-convention.md` (SSOT)

### Pre-commit

**Lefthook** (`lefthook.yml`):
- `lint`: staged 파일 ESLint 검사
- `format`: staged 파일 Prettier 포맷
- 자동 stage fixed files

---

## Deploy (CI/CD)

### APK 빌드

```bash
MODE=debug ./app.deploy.sh     # 디버그 빌드
MODE=release ./app.deploy.sh   # 릴리스 빌드
npm run release                # Gradle assembleRelease
```

- **MODE 명시 필수** — fallback/auto-inference 금지
- Docker 기반 빌드 환경 (node:20 + OpenJDK-21 + Android SDK 34)
- Android 12+ (AOSP) 타겟

### Web 배포

```bash
./deploy.sh                    # S3 sync + CloudFront
```
