# 환경별 수집 (Phase 3)

`<Environment>` 에 맞는 절에 따라 증거를 모은다. 공통 원칙: **태그(`<AuditTag>`)로 필터**, **raw 통째 읽기 금지**.

## browser (브라우저 / 웹앱)

이미 실행 중인 Chrome 디버그 인스턴스에 attach 하는 것이 기본이다(새 인스턴스를 띄우지 않는다).

1. 연결 + 페이지 선택: `list_pages` → `select_page`.
2. 계측 코드 반영 + 콘솔 초기화를 위해 수집 시작 전 **리로드**(`navigate_page type=reload`)한다.
3. 사용자가 `<TriggerFlow>` 실행.
4. 수집: `list_console_messages(types:["info"], includePreservedMessages:true)`.

### ⚠️ 콘솔 함정 — 객체 payload 가 `[object Object]` 로 보인다

`list_console_messages` 는 객체 인자를 `[object Object]` 로만 직렬화한다. 실제 값은 안 보인다.

- **대용량이면** 출력이 파일로 저장된다 → `grep` 으로 태그·msgid·이벤트명만 먼저 추출:
  ```bash
  grep "DATA_AUDIT" <saved.txt> | sed -E 's/.*msgid=([0-9]+).*\] ([a-zA-Z0-9._]+).*/\1 \2/'
  ```
- **실제 payload** 는 `get_console_message(msgid)` 로 개별 조회하면 `Arg #2` 에 JSON 으로 펼쳐진다.
- round 류 반복 로그는 보통 `*.deviation` 이벤트 payload 에 입력 샘플이 포함되므로, 개별 round 는 생략하고 핵심 이벤트(deviation/apply/persist/final) msgid 만 병렬 조회하면 효율적이다.
- 처음부터 텍스트로 읽고 싶으면 계측에서 payload 를 `JSON.stringify` 해 출력하도록 만든다.

### 최종 저장값 직접 확인

`final.snapshot` 외에, 저장소 실제 값을 `evaluate_script` 로 앱 API/`localStorage` 에서 직접 읽어 교차 확인할 수 있다.

> 이 프로젝트(Aware)의 Chrome 디버그 연결 규칙은 메모리 `project_chrome_debug_skill` 와 스킬 `devoks-browser:browser-devtools` 참조(포트·도구 prefix 규칙).

## server (백엔드/Node/API 서버)

1. 계측 로그를 stdout 또는 로그 파일로 출력(`<AuditTag>` prefix).
2. 수집 시작 시점을 표시(로그에 마커 라인 1줄 또는 `tail -f` 시작).
3. `<TriggerFlow>`(요청/잡 실행) 후 `grep "<AuditTag>" <logfile>` 로 필터.
4. 구조화 로그(JSON line)면 `jq` 로 이벤트별 추출:
   ```bash
   grep DATA_AUDIT app.log | jq -c 'select(.event=="persist.x") | {before,after}'
   ```

## db (데이터베이스 직접 검증 / 정적 무결성)

코드 계측 없이 **before/after 스냅샷**으로 대조한다.

1. 트리거 전 대상 행/집계를 스냅샷:
   ```sql
   SELECT id, field_a, field_b FROM t WHERE <조건>;  -- before
   ```
2. `<TriggerFlow>` 실행.
3. 동일 쿼리로 after 스냅샷 → diff.
4. 정적 무결성 점검 쿼리:
   ```sql
   -- 완전성: 필수 컬럼 null
   SELECT count(*) FROM t WHERE required_col IS NULL;
   -- 유일성: 중복
   SELECT key, count(*) FROM t GROUP BY key HAVING count(*) > 1;
   -- 무결성: 고아 참조(FK)
   SELECT count(*) FROM child c LEFT JOIN parent p ON c.pid=p.id WHERE p.id IS NULL;
   -- 유효성: 범위/enum 위반
   SELECT count(*) FROM t WHERE val NOT BETWEEN <min> AND <max>;
   ```

## cli / file (파일·배치 산출물)

1. 입력 파일과 출력 파일을 각각 스냅샷(체크섬·행수·스키마).
2. 변환 전후 레코드 수/합계 대조(reconciliation): `행수_in == 행수_out (± 의도적 필터)`.
3. 스키마/형식 검증은 스키마 검증기(JSON Schema, CSV 헤더 대조 등)로 스크립트화.
4. 큰 파일은 `ctx_execute_file` 또는 스크립트로 집계만 추출(통째 읽기 금지).
