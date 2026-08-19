# 화면 감지 휴리스틱 (Phase 1 상세)

이 문서는 `new-smoke-test-draft` 생성기 자신이 Phase 1에서 참고하는 절차다 — 대상 프로젝트로 복사되지
않는다. 감지는 항상 **추천 근거**이며, 결과는 Phase 1의 마지막 단계(사용자 확인)를 거쳐야 확정된다.

## 1. 스택 계열 시그널 감지

`devoks-core:setup-project-convention` Step 1과 같은 방식 — `package.json`/설정 파일을 grep해 계열을
추천하되, **감지 결과를 SSOT로 단정하지 않는다.**

| 계열 | 시그널 |
|------|--------|
| React Router | `package.json`에 `react-router-dom` |
| Next.js | `package.json`에 `next` + `app/` 또는 `pages/` 디렉터리 존재 |
| Expo Router | `package.json`에 `expo` + `expo-router` + `app/` 디렉터리 존재 |
| React Navigation | `package.json`에 `expo` 또는 `react-native` + `@react-navigation/*`(단, `expo-router` 없음) |
| Android 네이티브 | `android/` + `build.gradle*`/`settings.gradle*` |
| iOS 네이티브 | `ios/` + `*.xcodeproj`/`*.xcworkspace` |

확신할 시그널이 없으면 곧바로 §3(폴백)으로 간다 — 억지로 하나를 고르지 않는다.

## 2. 계열별 라우트/화면 파일 후보 탐색

| 계열 | 탐색 패턴 |
|------|-----------|
| React Router | Glob `**/routes*.{ts,tsx,js,jsx}`, `**/router*.{ts,tsx,js,jsx}`; Grep `createBrowserRouter(`, `createHashRouter(`, `<Route path=` |
| Next.js App Router | 모든 `app/**/page.{tsx,jsx,ts,js}`(`app/api/` 제외) — 화면 이름은 폴더 경로에서 라우트 그룹 `(name)`을 제거하고 동적 세그먼트 `[param]`은 파라미터로 남긴 값 |
| Next.js Pages Router | 모든 `pages/**/*.{tsx,jsx}`(`_app`·`_document`·`_error`·`pages/api/**` 제외) |
| Expo Router | 모든 `app/**/*.tsx`(`_layout.tsx`는 네비게이터 설정이지 화면이 아니므로 별도 표기하고 화면 목록에서 제외) |
| React Navigation | Glob `navigation/**/*.tsx`, `**/*Navigator.tsx`; Grep `createNativeStackNavigator(`, `createBottomTabNavigator(`, `<Stack.Screen name=`, `<Tab.Screen name=` |
| Android 네이티브 | `AndroidManifest.xml`의 `<activity>` 항목, 또는 `res/navigation/*.xml`의 `<fragment>`/`<destination>` 항목 |
| iOS 네이티브 | Grep `NavigationLink(destination:`, `.tabItem`, 또는 `*.storyboard`의 `<scene>` 항목 |

## 3. 폴백 — 항상 열려 있는 경로

아래 중 하나라도 해당하면 **추측하지 않는다**:

- 후보가 0개
- 서로 다른 계열의 후보가 2개 이상 동시에 그럴듯함(예: `react-router-dom`과 `next`가 함께 있고 라우트
  파일도 두 곳에서 발견됨)
- 라우트가 런타임에 동적으로 조립되어 정적 스캔으로 목록을 확정할 수 없음(예: 설정 배열을 함수로 생성)

이 경우 감지 후보를 있는 그대로 나열하고, 사용자에게 실제 라우트/화면 정의 파일(또는 화면 목록)을 직접
지목해 달라고 한 줄로 요청한다. 확정 전까지 화면 표를 만들거나 파일을 쓰지 않는다.

## 4. 화면 ID 부여 (기계적 규칙 — 도메인 지식 불필요)

체크리스트·딥다이브·리포트 3개 산출물이 같은 화면을 가리킬 수 있도록, 화면마다 고유 ID를 부여한다.
이 ID는 **라우트 경로 문자열만으로** 기계적으로 정해지며, 화면의 실제 업무 의미(예: "추출"→`WK`류
약어)는 알 수 없으므로 절대 추측하지 않는다.

1. 각 화면의 라우트에서 동적 세그먼트(`:id`, `[id]` 등)를 제외한 **첫 번째 경로 세그먼트**를 도메인
   키로 삼는다. 루트(`/`)처럼 세그먼트가 없으면 도메인 키는 `home`으로 둔다.
2. 서로 다른 도메인 키가 **2개 이상**이면 도메인별로 그룹핑해 `<DOMAIN>-<N>` 형식의 ID를 붙인다
   (`<DOMAIN>`은 도메인 키를 그대로 대문자화 — 줄이거나 의역하지 않는다. 예: `/settings/...` → `SETTINGS-1`,
   `SETTINGS-2`, `/items/...` → `ITEMS-1`). 도메인 내부 번호는 화면 표에 등장하는 순서대로 1부터 매긴다.
3. 도메인 키가 1개뿐이면(단일 도메인 앱) 그룹핑 의미가 없으므로 `S-<N>` 형식의 단순 일련번호만 붙인다.
4. 이 ID는 Phase 1의 확인 단계에서 사용자에게 함께 제시하고, 사용자가 원하면 조정할 수 있다 — 다른
   기본값과 마찬가지로 확정된 것으로 단정하지 않는다.

## 5. 화면 표 구성

후보가 하나로 좁혀지면 아래 형태로 정리해 Phase 1의 확인 단계에 제시한다.

| ID | 화면 | 라우트 | 소스 파일:줄 |
|----|------|--------|-------------|
| `<ID>` | `<Screen>` | `<path>` | `<file>:<line>` |

동적 세그먼트(`:id`, `[id]` 등)가 있는 화면은 라우트 칸에 그대로 남기고, 실제 값 확보 방법은 이 단계에서
정하지 않는다(Phase 3에서 생성 결과의 TODO로 남김 — 이 문서의 책임 밖).
