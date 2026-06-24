# Workflow checklist

`devoks-plugin-maintenance`가 상세 점검 시 참고하는 매트릭스다.

## 1. 변경 유형별 기본 확인

| 변경 유형 | 기본 확인 | 추가 확인 |
|---|---|---|
| runtime behavior only | 대상 플러그인 식별, `plugin.json` version bump 여부, `validate --strict` | 사용자-facing 설명 변경이 있으면 README/README.ko 검토 |
| public workflow change | version bump, `validate --strict`, 관련 skill/command 문서 | `docs/plugin-management.md`, README/README.ko |
| docs-only | 실제 코드/동작 불변인지 확인 | plugin version bump 비대상 사유 기록 |
| MCP/prefix/policy change | `mcpServers`, `permissions.allow`, prefix, setup 문서 | `docs/mcp-setup-guide.md`, `setup-mcp.md`, `check-mcp.sh` |
| naming/catalog change | 이름/description/dependency 변경 반영 | README, README.ko, marketplace, 다른 SKILL 참조 |
| core refs/rules change | 루트 `.claude/` 사본과 sync 정책 확인 | `sync-context.sh`, 관련 운영 문서 |

## 2. 문서 대상 판단표

| 파일 | 언제 검토하나 |
|---|---|
| `README.md` | 플러그인/skill/command 설명, 설치/업데이트 흐름, 사용자-facing 요약이 바뀔 때 |
| `docs/README.ko.md` | README와 동일한 정보의 한국어 카탈로그가 영향을 받을 때 |
| `docs/plugin-management.md` | 플러그인 생성/검증/배포/유지보수 절차 자체가 바뀔 때 |
| `docs/mcp-setup-guide.md` | MCP 서버 설치 방식, prefix, 정책 설명이 바뀔 때 |
| `plugins/devoks-core/commands/setup-mcp.md` | setup 절차, 예시 명령, 서버별 설치 안내가 바뀔 때 |
| `.claude-plugin/marketplace.json` | 신규 플러그인 추가, description/dependencies/source 관련 정보가 바뀔 때 |
| `docs/roadmap.md` | 반복 drift 문제를 후속 개선 과제로 명시해야 할 때 |

## 3. MCP / prefix / permission 점검 포인트

### plugin 설치형 prefix
- `mcp__plugin_<plugin>_<server>__*`
- 플러그인 번들에 의해 제공되는 tool 명칭

### 일반 MCP 등록형 prefix
- `mcp__<server>__*`
- `claude mcp add` 또는 별도 설치로 제공되는 tool 명칭

### 대조 지점
- `plugins/<plugin>/.claude-plugin/plugin.json`
- 관련 SKILL.md / agent 문서
- `docs/mcp-setup-guide.md`
- `plugins/devoks-core/commands/setup-mcp.md`
- `plugins/devoks-core/hooks/check-mcp.sh`

## 4. 특수 케이스

### devoks-browser
- `chrome-devtools-attach` 명칭 유지 여부
- `settings.permissions.allow` prefix
- browser visual diff / browser devtools 관련 설명

### devoks-rn
- `metro-devtools` 관련 allow prefix
- Metro URL / setup 흐름 설명
- RN 전용 optional 성격 설명

### devoks-core
- `rules/`, `refs/`, hook 변경 시 루트 `.claude/` 사본과 관계
- `check-mcp.sh`, `sync-context.sh`와 문서 설명 일치 여부

## 5. 비대상 사유 작성 규칙

업데이트하지 않는 파일은 아래 형식으로 남긴다.

- `<file>`: `<왜 비대상인지>`

예시:
- `README.md`: 내부 hook 주석 정정만 포함, 사용자-facing 설명 불변
- `.claude-plugin/marketplace.json`: 플러그인 추가/삭제/description/dependency 변경 없음

## 6. 완료 전 최종 확인

- [ ] 변경 플러그인별 체크리스트가 분리되어 있는가
- [ ] 각 플러그인의 version bump 필요 여부가 설명되어 있는가
- [ ] `claude plugin validate ./plugins/<plugin> --strict` 실행 여부가 기록되었는가
- [ ] 문서 대상/비대상 판단이 파일별로 남아 있는가
- [ ] MCP/prefix/permission 대조 지점이 확인되었는가
- [ ] core sync 영향이 있으면 `.claude/` 사본과 문서까지 함께 봤는가
