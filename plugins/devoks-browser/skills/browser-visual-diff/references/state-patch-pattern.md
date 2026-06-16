# 임시 State 강제 진입 패턴

특정 화면이 다단계 워크플로우의 중간/종료 상태라서 자동으로 진입하기 어려울 때, 임시 코드 패치로 강제 진입시킨다. 검증 후 `git restore` 로 완전히 되돌린다.

---

## 핵심 원칙

1. **1개 파일, 1줄 또는 1 블록** — 임시 패치는 최소 단위. 여러 파일 동시 패치 금지.
2. **`git restore` 1회로 완전 회수** — 패치 후 `git restore <파일>` 한 번으로 원상복구 가능해야 한다.
3. **주석 prefix 필수** — `// TEMP-VISUAL-VERIFY` 로 임시 패치임을 명시. 회수 누락 시 `grep` 으로 검출 가능.
4. **부수 효과 평가** — 패치 전 "이 화면 진입이 외부 API 호출 / 상태 머신 전환 / 하드웨어 명령을 발사하는가?" 를 확인. 위험하면 옵션 B 사용.

---

## 옵션 A: state 초기값 강제

가장 단순한 방법. 컴포넌트의 `useState` 초기값을 직접 변경.

```jsx
// TEMP-VISUAL-VERIFY: remove via git restore
- const [currentStep, setCurrentStep] = useState(STEPS.INITIAL);
+ const [currentStep, setCurrentStep] = useState(STEPS.RESULT_PASS);
```

**장점**: 구현이 단순, 변경이 1줄.  
**단점**: React `useEffect` 가 state 변경에 반응해 외부 시스템에 명령을 보낼 수 있음 (외부 API, 하드웨어 명령, WebSocket 등).

**사용 권장 조건**: 진입만 하고 특별한 부수 효과가 없는 화면. 인증, 하드웨어 제어, 서버 요청 등이 연동된 화면에는 사용 주의.

---

## 옵션 B: mock prop 단독 렌더

컴포넌트를 최상위 JSX 에서 직접 렌더링해 부수 효과를 완전 차단.

```jsx
// TEMP-VISUAL-VERIFY: remove via git restore
if (true) {
    return (
        <div style={{ width: "100%", height: "100%" }}>
            <SomeTargetComponent
                propA={mockValueA}
                propB={mockValueB}
                onAction={() => {}}
            />
        </div>
    );
}
```

**장점**: 부수 효과 완전 차단. 하드웨어/API 명령이 발사되지 않음.  
**단점**: Layout 컴포넌트(헤더, nav, 배경 등) 가 빠질 수 있음. mock prop 을 직접 조립해야 함.

**Layout 재현이 필요한 경우**: 상위 컴포넌트 안에 타깃 컴포넌트를 포함하는 방식으로 대응.

---

## 옵션 선택 기준

| 조건 | 권장 옵션 |
|------|----------|
| 화면 진입 시 외부 시스템 명령 없음 | 옵션 A |
| 화면 진입 시 API / 하드웨어 명령 발사 | 옵션 B |
| Layout (헤더, nav, 배경) 포함 비교 필요 | 옵션 B (Layout 래퍼 포함) |
| mock prop 조립이 복잡함 | 옵션 A (부수 효과가 무시할 수 있는 수준이면) |

---

## 패치 회수 절차

패치 화면 1개 검증 완료 후 즉시 회수. 다음 화면 검증 전에 반드시 회수해야 한다.

```bash
# 패치 파일 회수
git restore <패치된 파일 경로>

# 잔존 패치 검색
grep -r "TEMP-VISUAL-VERIFY" .

# 변경 없음 확인
git diff --stat
```

---

## 패치 적용 → 캡처 → 회수 전체 예시

```bash
# 1. 패치 적용 (에디터 또는 Edit 툴로)
# SomeWizardPage.jsx 의 초기 state 를 STEPS.RESULT_PASS 로 변경

# 2. Playwright 로 캡처
mcp__playwright__browser_navigate(url=http://localhost:3000/some-wizard)
mcp__playwright__browser_wait_for(text="보정이 완료되었습니다")
mcp__playwright__browser_take_screenshot(filename=render_result_pass.png)

# 3. 즉시 회수
git restore src/pages/SomeWizardPage.jsx

# 4. 잔존 패치 없음 확인
grep -r "TEMP-VISUAL-VERIFY" .
# → 결과 없음 (OK)
```

---

## 주의사항

- 임시 패치가 적용된 상태에서 **`git commit` 절대 금지**.
- 임시 패치가 있는 채로 다른 화면 검증 시작 금지 (직전 패치 효과가 현재 화면에 영향을 줄 수 있음).
- HMR 이 예상대로 동작하지 않으면 Playwright/Chrome DevTools 에서 강제 리로드 후 재캡처.
