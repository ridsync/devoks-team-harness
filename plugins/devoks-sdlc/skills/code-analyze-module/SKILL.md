---
description: "사용자가 지정한 진입점(파일·폴더·기능 설명)을 중심으로 복잡한 모듈이나 비즈니스 로직을 읽고, 코드를 처음 읽는 사람이 인지하는 순서(디렉토리 지도 → 진입 → 실행 → 책임·규칙 → 훅·모듈 연결)에 맞춘 구조화된 마크다운 분석 문서로 정리한다. 저장소 전체 맵이 아니라 지정 범위만 다룬다. \"이 모듈 분석해줘\", \"비즈니스 로직 파악\", \"코드 분석 문서 만들어줘\", \"이 기능 어떻게 동작하는지 정리해줘\", \"온보딩 문서 작성\" 같은 요청에서 사용한다. 요구 충족 판정은 devoks-sdlc:verify-requirements, 코드 품질 리뷰는 devoks-sdlc:code-review 를 쓴다."
argument-hint: "entry=<파일|폴더|기능 설명> [out=<저장 경로> (default: 채팅 출력만)]"
metadata:
  author: ridsync
  version: 1.0.0
---

# code-analyze-module — 코드·비즈니스 로직 분석

사용자가 지정한 **진입점**(파일·폴더·기능 설명)을 중심으로 복잡한 모듈 또는 비즈니스 로직을 읽고 구조화된 분석 문서로 정리한다.

다독·문서 작성은 `code-analyzer` 에이전트에 위임하고 **완성된 분석 문서만** 돌려받는다 — 진입점과 연결된
대량 파일 읽기·의존성 추적 결과가 메인 대화 컨텍스트에 적재되지 않도록 격리한다.

---

## 호출 방법

```
/devoks-sdlc:code-analyze-module entry=<파일|폴더|기능 설명> [out=<저장 경로> (default: 채팅 출력만)]
```

> 표기: `key=값` 필수 · `[key=값]` 선택 · `(default: X)` 미지정 시 X로 진행.

**예시:**

```
/devoks-sdlc:code-analyze-module entry=src/features/checkout
/devoks-sdlc:code-analyze-module entry=결제 실패 재시도 로직 out=docs/analysis/checkout-retry.md
```

| 슬롯 | 의미 | 입력 방법 |
|------|------|----------|
| `entry` | 분석 대상 진입점(파일·폴더 경로 또는 기능 설명) | `entry` 인자 또는 Phase 0 확인 (필수) |
| `out` | 산출물 저장 경로 | `out` 인자 또는 Phase 0 확인 (선택, 없으면 채팅에만 출력) |

---

## Phase 0 — 진입점·범위 확정 (1회)

1. `$ARGUMENTS`에서 슬롯을 파싱한다.
2. `entry`가 없으면 대화·에디터에서 지정한 파일 참조로 확인하거나, 없으면 반드시 질문한다.
3. **범위·과대 진입점**: 한 번에 읽기 어려울 만큼 넓어 보이면(예: 저장소 전체, 여러 도메인 혼재) 하위 모듈·기능 단위로 나눌지, 우선 진입점을 좁힐지 사용자에게 확인한다. 모호할 때는 질문을 우선한다.
4. `out`이 있으면 그대로 확정, 없으면 채팅 출력만으로 진행함을 1줄 안내한다.

> AskUserQuestion은 HITL 직접 호출 경로 전용이다. `entry`가 인자로 명확히 왔으면 묻지 않고 진행한다.

---

## Phase 1 — 분석 실행 (에이전트 위임)

> ⚠️ **실행 주체는 `code-analyzer` 에이전트이다.** 대량 파일 읽기·의존성 추적은 에이전트 컨텍스트에 격리되고,
> 메인 루프에는 **완성된 분석 문서만** 리턴된다.

Phase 0에서 확정된 값으로 `code-analyzer` 에이전트를 호출한다.

| 파라미터 | 값 |
|---------|-----|
| `entry` | Phase 0에서 확정한 진입점 |
| `out` | Phase 0에서 확정한 저장 경로(있으면) |

에이전트가 따르는 실행 절차·산출 템플릿 SSOT는 `references/analysis-execution.md`다.

---

## Phase 2 — 문서 출력 (Pass-through 전용)

> ⚠️ **이 단계는 Pass-through 전용이다.** 메인 에이전트는 subagent가 반환한 분석 문서를 요약·압축·재작성·생략해서는 안 된다. 기본 brevity 설정과 무관하게, 반환된 마크다운 전문을 **한 글자도 빠뜨리지 않고 그대로** 사용자에게 출력한다.

**금지:**
- 섹션(`## 1.`~`## 6.`, 부록 A) 축약·생략
- 표·트리·Mermaid 다이어그램 구조 변경
- 자체 해석이나 추가 코멘트 삽입(문서 앞뒤에 붙이는 것도 금지)

---

## 참고 기준 문서

- **실행 절차·산출 템플릿 SSOT**: `references/analysis-execution.md`
- **관련**: 구현이 요구를 만족하는지 판정은 `devoks-sdlc:verify-requirements`, 코드 품질·버그 리뷰는 `devoks-sdlc:code-review`, 리팩토링은 `devoks-sdlc:code-refactoring`.
