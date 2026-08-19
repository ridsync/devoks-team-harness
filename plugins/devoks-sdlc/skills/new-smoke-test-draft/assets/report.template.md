<!--
Phase 3 템플릿 — new-smoke-test-draft 생성기가 이 파일을 확정된 스킬 이름으로 채운 뒤, 대상 프로젝트의
`.claude/skills/<생성될 스킬 이름>/references/report-template.md`로 쓴다. 채워 넣을 때 이 주석 블록은
제거한다. 이 파일 자체는 매 실행마다 그대로 복사해 채우는 리포트 양식이다(devoks-sdlc의
`verify-acceptance-test/references/report-template.md`와 같은 계열의 형식).
-->
# 스모크 테스트 리포트 템플릿

이번 스모크 테스트 실행 결과를 표준 형식으로 남기는 템플릿이다. 저장은 선택 — 남기고 싶으면
`doc/reports/<날짜>-Smoke-Test-Result.md`로 저장한다.

## 템플릿 본문 (그대로 복사해 채워 쓴다)

```markdown
# <생성될 스킬 이름> — 배포 전 스모크 테스트 결과

- 대상 브랜치/리비전: `<branch or commit>`
- devoks-browser 연결: 정상 / 실패
- 실행 시각: `<YYYY-MM-DD HH:MM ~ HH:MM>`

## 종합 판정: ✅ 전체 통과 / ⚠️ 일부 실패·갭 / ❌ 실패

<한 단락 요약>

## 도메인별 요약 (도메인이 2개 이상일 때만 — 단일 도메인이면 이 표는 생략)

| 도메인 | PASS | FAIL | BLOCKED | 미검증(스킵) |
|--------|------|------|---------|--------------|
| <DOMAIN> | | | | |

## 화면별 결과

ID는 `references/core-screens-checklist.md`와 동일한 화면 ID다.

| ID | 화면 | 라우트 | 판정 | 비고 |
|----|------|--------|------|------|
| <ID> | <Screen> | <route-path> | ✅ PASS / ❌ FAIL / 🚫 BLOCKED | |

## 스킵한 화면 (있다면)

- <화면> — <사유(데이터 부재·환경 제약 등) — 침묵 생략 금지>

## 발견 사항

- **[Critical/Major/Minor]** <불일치>: <증거(콘솔 에러 메시지·스크린샷 파일명 등)>

## 소요 시간

- 총 <mm:ss>
```

## 작성 팁

- 화면별 결과 표는 `references/core-screens-checklist.md`의 화면 목록과 ID를 그대로 이어받는다 — 새로 설계하지 않는다.
- 도메인별 요약 표는 화면 ID의 도메인 접두어(`<DOMAIN>-N`)별로 집계한다 — 접두어 없이 `S-N`만 쓰는 단일 도메인 프로젝트는 이 표를 생략한다.
- FAIL은 반드시 증거(콘솔 에러 메시지, 관찰한 실제 동작)와 함께 남긴다.
- 스킵한 화면은 침묵 생략하지 않는다 — 사유를 반드시 남긴다.
