# 계측 로깅 패턴 (Phase 2)

런타임 데이터 흐름을 드러내기 위한 **임시** 로깅 패턴. 목표는 적은 코드로 각 레이어의 실측값을
일관된 형식으로 남기고, 끝나면 흔적 없이 회수하는 것이다.

## 1. 임시 로거 1개로 통일

레이어마다 같은 태그 `<AuditTag>` 로거를 쓴다. 콘솔/로그에서 태그 하나로 필터되어 수집이 쉽다.

```js
// [AUDIT-TEMP] 데이터 정합성 검증용 — 검증 후 제거
const audit = createDebugger("DATA_AUDIT", { enabled: true, level: "info" });
// 프로젝트에 로거 유틸이 없으면: const audit = { i: (e, p) => console.info(`[DATA_AUDIT] ${e}`, p) };
```

- 훅 안에서는 `useRef(createDebugger(...)).current`, 모듈 레벨이면 상수로 둔다.
- 이벤트명은 `단계.항목` 형식(`apply.offset`, `persist.localSettings`, `final.snapshot`)으로 통일 — 스캔이 쉽고 리포트 표와 1:1 매핑된다.

## 2. 모든 추가 코드에 마커

추가하는 로거·로깅 호출·deps 항목 전부에 `// [<AuditMarker>]`(기본 `// [AUDIT-TEMP]`) 주석을 단다.
회수 시 `grep -rn "AUDIT-TEMP"` 한 번으로 전량 식별하기 위함이다.

## 3. 레이어별로 무엇을 찍나

| 레이어 | 이벤트 예 | payload |
|--------|-----------|---------|
| 입력 | `input.raw` | 원자료(센서/사용자 입력/측정값 배열) |
| 계산/변환 | `calc.deviation` | 입력 샘플 + 기준값 + 계산 결과 + 적용 공식 파라미터 + verdict |
| 적용 | `apply.<field>` | 적용 의도값 + `before → after` + 분기 조건 |
| **영속 SSOT** | `persist.<store>` | watch-key 변경분만 `{key: {before, after}}` |
| 완료 | `final.snapshot` | 전 대상 값 재로드 스냅샷 1회 |

## 4. 영속 SSOT watch-key 필터 (결정적 증거)

모든 쓰기가 통과하는 저장 함수(DB write / localStorage setter / 파일 flush)에 **변경된 watch-key만** 로깅한다.
보정과 무관한 쓰기까지 찍히면 noise 가 되므로 집합으로 거른다.

```js
// [AUDIT-TEMP] 검증용 — 저장 직후, 추적 대상 키 변경분만 before→after
const WATCH = new Set(["fieldA", "fieldB", /* ... */]);
try {
  const changed = {};
  for (const k of Object.keys(patch)) {
    if (WATCH.has(k)) changed[k] = { before: current[k], after: saved[k] };
  }
  if (Object.keys(changed).length) audit.i("persist.<store>", changed);
} catch (e) { console.error("audit(persist) failed", e); }
```

`before` 는 저장 전 현재값, `after` 는 검증·coerce 를 거쳐 **실제 저장된 값**이어야 한다(쓰기 직후 캡처).

## 5. 누적·증분 값은 before/after 가 필수

`x += delta` 형태(누적 오프셋, 가중치 등)는 **이중 합산** 버그가 잦다. `{delta, before, next}` 를 찍어
`next == before + delta` 를 Phase 4 에서 확인할 수 있게 한다.

## 6. 함정

- **React deps**: 로깅 호출이 `useCallback`/`useEffect` 안이면 로거를 deps 에 추가해 lint(exhaustive-deps)를 통과시킨다(ref 라 stable 해도 일관성 위해).
- **과한 payload**: 거대 객체/순환참조/민감정보는 찍지 않는다. "작은 구조화 객체"만.
- **계측이 흐름을 바꾸지 않게**: 로깅은 부수효과 없이 값만 읽는다. 저장·상태변경을 로깅 안에서 하지 않는다.

## 7. 정적 검증이면 계측 대신 스냅샷

기존 데이터의 무결성만 본다면 코드 계측 없이, 검증 전후 스냅샷을 쿼리/스크립트로 떠서 비교한다
(`collection-by-environment.md` §DB/파일 참조).
