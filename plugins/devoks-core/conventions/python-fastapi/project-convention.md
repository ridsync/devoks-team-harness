# Project Convention — Python FastAPI Preset

이 문서는 **Python FastAPI 백엔드 프로젝트용 preset**입니다. bracket 선택형 메뉴가 아니라, 한 가지로 결정된 예시 스택과 실제 코드/테이블로 구성되어 있습니다.
최초 주입 후에는 아래 예시 스택·코드를 프로젝트의 실제 선택으로 즉시 교체하세요.

---

## Stack

- **Language:** Python 3.12+ (전면 타입힌트, PEP 604 `X | Y` union 표기 사용)
- **Framework:** FastAPI — 라우팅/미들웨어/ASGI 계약은 Starlette 계층, 요청·응답 검증은 Pydantic v2 계층
- **Validation:** Pydantic v2 (`model_validate`/`model_dump`) — v1 문법(`parse_obj`, `.dict()`) 금지
- **Package/Dependency Manager:** uv (`pyproject.toml` + `uv.lock`)
- **ORM:** SQLAlchemy 2.0 (async, `AsyncSession`, `Mapped`/`mapped_column` typed style) + Alembic(migration)
- **DB (예시):** PostgreSQL + `asyncpg`
- **Settings:** pydantic-settings (`BaseSettings`, `.env` 로드)
- **ASGI Server:** uvicorn(dev, `--reload`) / gunicorn + `UvicornWorker`(prod)
- **Lint/Format:** Ruff(format + lint)
- **Type Check:** mypy(+ `pydantic.mypy` plugin)
- **Test:** pytest + pytest-asyncio + httpx(`AsyncClient` + `ASGITransport`)

---

## Coding Style

### Naming

| 대상 | 규칙 | 예시 |
|------|------|------|
| 도메인 모듈 디렉토리 | snake_case | `app/product/` |
| 라우터 파일 | 고정 파일명 `router.py` | `app/product/router.py` |
| Pydantic 스키마 | PascalCase + 용도 접미사(Create/Update/Read) | `ProductCreate`, `ProductRead` |
| SQLAlchemy 모델 | PascalCase 단수 | `Product` |
| 서비스 함수 | snake_case 동사구 | `create_product`, `get_product_by_id` |
| 의존성 함수(Depends 대상) | `get_` 접두 | `get_db_session`, `get_current_user` |
| 상수 | UPPER_SNAKE_CASE | `ITEM_STATUS.CREATE` |
| 테스트 파일 | `test_*.py` | `test_router.py` |

- 이름은 **도메인 + 맥락 + 의도**를 담아 3단어 이상 권장. 제네릭 이름 회피.

### Code Size

- **Functions:** ≤50 lines (target), **100 lines max** (hard limit).
- **Files:** ≤500 lines (target), **1000 lines max** (hard limit).

### Package Structure (Domain/module-first)

```
app/
  core/
    config.py        # Settings(BaseSettings) — 환경변수 SSOT
    db.py             # engine, async_session_factory
    security.py        # 인증/인가 공용 유틸
  product/
    router.py          # APIRouter — 엔드포인트
    schemas.py           # Pydantic (Create/Update/Read)
    models.py             # SQLAlchemy 모델
    service.py             # 비즈니스 로직
    dependencies.py          # 이 도메인 전용 Depends 대상
    exceptions.py             # 도메인 커스텀 예외
  main.py                     # FastAPI() 생성, include_router, lifespan
tests/
  product/
    test_router.py
```

- 도메인(기능) 단위로 라우터·스키마·모델·서비스를 한 디렉토리에 묶는다 — 기술 계층(전체 `routers/`, 전체 `models/`)으로 최상위를 나누지 않는다.
- 여러 도메인이 공유하는 의존성·설정·DB 엔진만 `core/`에 둔다.

### Import Order

```python
# 1. 표준 라이브러리
from datetime import datetime

# 2. 서드파티
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

# 3. 로컬(app.*)
from app.core.db import get_db_session
from app.product.schemas import ProductCreate, ProductRead
from app.product import service as product_service
```

- import 정렬은 Ruff(isort 규칙 포함)가 자동 수행 — 수동 정렬/도구 추가 불필요.

---

## Core Rules

- 라우터 함수는 **얇게** 유지한다 — 검증된 입력을 service 계층에 위임하고, 반환값을 응답 스키마로 변환하는 역할만 맡는다. 비즈니스 로직을 라우터 본문에 직접 두지 않는다.
- DB 세션은 항상 `Depends(get_db_session)`으로 요청 스코프에서 주입받는다 — 전역 세션/커넥션을 모듈 레벨 변수로 만들지 않는다.
- Pydantic 스키마(API 계약)와 SQLAlchemy 모델(DB 계약)을 같은 클래스로 섞지 않는다.
- 동기 blocking 호출(예: 동기 HTTP 클라이언트, CPU-bound 연산)을 async 엔드포인트에서 직접 await 없이 실행하지 않는다 — 비동기 드라이버를 쓰거나 `run_in_threadpool`로 위임한다.

---

## Design Pattern

### Schema (Pydantic v2)

```python
from pydantic import BaseModel, ConfigDict, Field


class ProductCreate(BaseModel):
    name: str = Field(min_length=1)
    price: int = Field(ge=0)


class ProductRead(BaseModel):
    id: int
    name: str
    price: int

    model_config = ConfigDict(from_attributes=True)
```

- Create/Update/Read 스키마를 분리한다 — 입력에만 필요한 필드(비밀번호 등)와 응답에 노출할 필드가 다르다.
- `model_config = ConfigDict(from_attributes=True)`로 SQLAlchemy 모델 인스턴스를 직접 응답 스키마로 변환한다.

### Model (SQLAlchemy 2.0 typed style)

```python
from sqlalchemy import String
from sqlalchemy.orm import Mapped, mapped_column

from app.core.db import Base


class Product(Base):
    __tablename__ = "products"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(200))
    price: Mapped[int]
```

- `Mapped[...]` + `mapped_column()` typed 선언을 사용한다 — legacy `Column()` 단독 선언 방식은 신규 코드에 쓰지 않는다.

### Dependency Injection (FastAPI `Depends`)

```python
from collections.abc import AsyncIterator

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.db import async_session_factory
from app.product import service as product_service
from app.product.schemas import ProductCreate, ProductRead

router = APIRouter(prefix="/products", tags=["product"])


async def get_db_session() -> AsyncIterator[AsyncSession]:
    async with async_session_factory() as session:
        yield session


@router.post("", response_model=ProductRead, status_code=201)
async def create_product(
    payload: ProductCreate,
    session: AsyncSession = Depends(get_db_session),
) -> ProductRead:
    return await product_service.create_product(session, payload)
```

- 여러 라우터가 공유하는 의존성(DB 세션, 인증 사용자, 페이지네이션 파라미터)은 `dependencies.py`에 모아 `Annotated[X, Depends(...)]` 별칭으로 재사용한다.

### Validation (Contract)

- 요청 경계 검증은 Pydantic 스키마 자체가 담당한다(Contract at boundary) — 형식 검증 실패는 FastAPI가 422로 자동 변환한다.
- 스키마로 표현 못 하는 비즈니스 규칙 위반은 `exceptions.py`의 커스텀 예외를 raise하고, 전역 `exception_handler`에서 HTTP status로 매핑한다. 서비스 함수 안에서 `HTTPException`을 직접 raise하지 않는다(HTTP 계층과의 결합 방지 — 서비스가 non-HTTP 컨텍스트(배치, CLI)에서 재사용될 때도 깨지지 않아야 한다).

---

## Data & Platform Integration

### Database (SQLAlchemy async + Alembic)

```python
# core/db.py
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase

from app.core.config import settings


class Base(DeclarativeBase):
    pass


engine = create_async_engine(settings.database_url, pool_size=10)
async_session_factory = async_sessionmaker(engine, expire_on_commit=False)
```

- 커넥션 풀(`engine`)은 앱 시작 시 1회 생성해 재사용한다 — 요청마다 새 engine을 만들지 않는다. 앱 종료 시 정리는 `main.py`의 `lifespan`에서 담당한다.
- 스키마 변경은 반드시 Alembic revision으로 남긴다(`alembic revision --autogenerate`) — 운영 DB에 수동 DDL을 직접 실행하지 않는다.

### Settings (pydantic-settings)

```python
# core/config.py
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    database_url: str
    model_config = SettingsConfigDict(env_file=".env")


settings = Settings()
```

- 환경변수 SSOT는 `core/config.py`의 `Settings` 하나다 — 코드 곳곳에서 `os.environ`/`os.getenv`를 직접 호출하지 않는다.

### Background/Async Tasks

- 응답 이후 처리해도 되는 짧은 후처리는 FastAPI `BackgroundTasks`로 충분하다.
- 재시도·큐잉·장시간 실행이 필요한 작업은 별도 워커(Celery/RQ/Arq 등)로 분리한다 — 채택 여부와 도구는 Project Decisions에서 확정한다.

---

## Performance

- DB 커넥션 풀 크기·타임아웃은 워커 프로세스 수 대비 명시적으로 설정한다 — 기본값 방치 시 워커 스케일 아웃에서 커넥션 고갈이 발생한다.
- 연관 데이터를 함께 조회해야 하면 `selectinload`/`joinedload`를 명시한다 — N+1 쿼리를 lazy load에 맡기지 않는다.
- 목록 API 응답 스키마에는 상세 조회에만 필요한 무거운 필드(대용량 텍스트 등)를 포함하지 않는다 — 목록/상세 스키마를 분리한다.
- 재시도 가능한 단발 API(결제, 주문 생성 등)는 Idempotency-Key로 서버가 중복 실행을 직접 차단한다(아래 Pitfalls의 `interaction-integrity.md` C4 참고 — 클라이언트 재진입 가드만으로는 불완전).

---

## Testing

- **Framework:** pytest + pytest-asyncio(`asyncio_mode = "auto"`) + httpx(`AsyncClient` + `ASGITransport`)
- **위치:** `tests/<domain>/` — 소스 도메인 구조와 대응.
- 외부 API 등 네트워크 의존은 dependency override 또는 `respx`로 대체한다 — 테스트에서 실제 네트워크 호출을 금지한다.
- DB 의존 테스트는 트랜잭션 롤백 또는 테스트 전용 스키마로 격리해 테스트 간 데이터 오염을 막는다.

```python
import pytest
from httpx import ASGITransport, AsyncClient

from app.main import app


@pytest.fixture
async def client():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        yield ac


async def test_create_product(client: AsyncClient):
    response = await client.post("/products", json={"name": "pen", "price": 1000})
    assert response.status_code == 201
```

---

## Security & Reliability

### Error Handling

| 상황 | 처리 |
|------|------|
| 요청 형식 검증 실패 | Pydantic이 422 자동 반환 — 커스텀 처리 불필요 |
| 비즈니스 규칙 위반 | 커스텀 예외 → `exception_handler`에서 HTTP status 매핑 |
| DB/외부 API 오류 | try/except + 로깅 + 명시적 재raise 또는 502/503 변환 |
| 인증/인가 실패 | `HTTPException(401/403)` — 미들웨어/`Depends` 경계에서만 발생 |

**금지:**
- 빈 except 블록(silent catch)
- 예외를 삼키고 `None`/기본값으로 대체(implicit fallback)
- 광범위한 `except Exception: pass`

### Auth

- 예시 흐름: `OAuth2PasswordBearer` + JWT(`python-jose` 또는 `pyjwt`). 세션 쿠키 기반이 필요하면 Project Decisions에서 교체한다.
- 인가는 `Depends(require_role("admin"))`류 의존성으로 라우터 시그니처에 명시한다 — 라우터 본문 안에서 role을 직접 비교하지 않는다.

### Security

- Secret/DB credential은 `.env`(로컬)/secret manager(배포)로만 주입한다 — 코드나 설정 파일에 하드코딩하지 않는다.
- CORS는 명시적 origin allow-list만 사용한다 — `allow_origins=["*"]`와 `allow_credentials=True`를 동시에 쓰지 않는다.
- 내부 전용 필드(hashed_password 등)가 응답에 직렬화되지 않도록 Read 스키마를 항상 별도로 정의해 명시적으로 노출 필드를 고른다.

---

## 구조 패턴 일괄 치환 (ast-grep)

동일 AST 패턴이 **N건** 있고 그걸 한 번에 바꿔야 할 때만 쓴다. 단건 심볼 편집은 Serena,
경로를 이미 아는 단순 확인은 내장 Read/Grep이 싸다. 이 스택의 언어 id: `python`.

**기본은 애드혹 — 설정 파일이 필요 없다.**

```bash
# 조회
ast-grep run -p 'def $FN($$$ARGS) -> $RET: $$$BODY' --lang python app/
# (동기 핸들러 전수 조회(async 전환 대상 식별))

# 치환 (-r 추가, --dry-run 으로 먼저 확인)
ast-grep run -p '<pattern>' -r '<rewrite>' --lang <lang> --dry-run <경로>
```

**영속 규칙(`sgconfig.yml` + `ruleDirs`)은 지금 넣을 규칙이 있을 때만 만든다.**
설정만 만들고 규칙을 비워두면 `ast-grep scan`이 영원히 0줄을 출력하며 아무도 이상을 눈치채지
못한다 — 설정 없는 상태보다 나쁘다.

만들 때는:

1. `ast-grep new project -y` — `sgconfig.yml` + `rules/` + `rule-tests/` + `utils/`를 만든다.
2. **`sgconfig.yml`의 절대경로를 상대경로로 반드시 교정한다** — 스캐폴드가 절대경로를 박아서
   팀 공유·CI에서 깨진다. `ruleDirs`·`utilDirs`는 경로 나열이지만 `testConfigs`는
   `- testDir: <경로>` **구조체**라 형식이 다르다:
   ```yaml
   ruleDirs:
     - rules
   testConfigs:
     - testDir: rule-tests
   utilDirs:
     - utils
   ```
3. `ast-grep new rule <id> -l <lang> -y`로 규칙과 테스트를 함께 만들고, `rule-tests/<id>-test.yml`의
   `valid:`/`invalid:` 인라인 샘플을 채운다.
4. **`ast-grep test`가 PASS하는 것을 스캐폴드 완료 판정으로 삼는다.**

4번이 중요하다 — `ast-grep test`는 **프로젝트 소스가 0개여도** 규칙의 정확성을 판정한다
(인라인 샘플로 검증하므로). 반대로 `ast-grep scan`은 소스가 없거나 패턴이 틀려도 똑같이 0줄을
출력해 둘을 구분할 수 없다. 규칙을 넣었는데 `scan`이 0건이면 **규칙이 죽었는지 우리 코드가
깨끗한지를 `test`로 먼저 가른다.**

monorepo면 저장소 루트가 아니라 실제 소스 패키지 루트에 두고, `ast-grep scan`·`test`도
**`sgconfig.yml`이 있는 그 디렉토리에서** 실행한다.

### 어떤 규칙을 쓸 수 있나

| 종류 | 필요한 전제 | 언제 쓸 수 있나 |
|------|------------|----------------|
| **스택 일반** — 프레임워크·라이브러리 deprecated API | 스택·버전 사실만 | 소스가 없어도 작성 가능 |
| **프로젝트 고유** — 자체 SSOT·컨벤션 위반 검출 | 그 SSOT가 실재하고 합의돼야 함 | 코드가 쌓인 뒤 |

프로젝트 고유 규칙을 SSOT가 확정되기 전에 넣으면 규칙이 곧 거짓이 된다 — 순서를 지킨다.

### 함정 (실측 확인)

| 증상 | 원인 | 대응 |
|------|------|------|
| 패턴이 조용히 0건 | `키: $V` 형태는 오브젝트 속성이 아니라 `labeled_statement`로 파싱된다 | `--debug-query=pattern`으로 파싱 형태를 먼저 확인하고, 속성 매칭은 `pattern.context` + `selector: pair`로 쓴다 |
| `scan`이 전부 안 돌고 에러 | 규칙 YAML **1개**만 깨져도 스캔 전체가 중단된다 | `context` 등 `:`가 들어가는 값은 **큰따옴표로 감싼다** |
| `.md` 같은 비코드 파일이 매치 | `--lang` 미지정 | `--lang`을 항상 명시한다 |
| CI에서 통과해버림 | `scan`은 `severity: error` 항목이 있을 때만 exit 1 | 게이트로 쓸 규칙은 `severity: error`로 둔다 |

`node_modules`·`dist`·빌드 산출물은 gitignore를 따라 자동 제외되므로 별도 ignore 설정은 불필요하다.

---

## Comment Rules

- **한국어** 사용, 자명한 코드에는 금지, 타겟 독자는 5년차 미드레벨 엔지니어
- 아래 3종은 독립 판단 — 한 대상이 여러 개 해당하면 나란히 작성(순서 무관)

### 프로젝트 기본 주석

- 재사용되는 공개 API(다른 도메인이 import하는 service 함수)로 파라미터·반환값 의미가 이름만으로 드러나지 않을 때
- 사이드이펙트가 있는 의존성 함수(DB 세션 생성, 외부 커넥션 open 등)
- 특정 조합·범위만 허용되는 설정 객체(Settings 필드 등)
- Description은 필수, docstring 파라미터/반환/예외 설명은 의미가 자명하지 않을 때만 추가

```python
def should_reorder_stock(remaining_qty: int, threshold_qty: int) -> bool:
    """재고 수량이 재주문 임계값 이하인지 판단한다.

    Args:
        remaining_qty: 현재 재고 수량
        threshold_qty: 재주문 트리거 임계값

    Raises:
        ValueError: remaining_qty가 음수일 때
    """
    if remaining_qty < 0:
        raise ValueError("remaining_qty는 음수일 수 없습니다")
    return remaining_qty <= threshold_qty
```

### Rationale Comment

자명한 코드에는 주석을 달지 않는다. 이름만으로 의도가 드러나면 주석 대신 네이밍으로 해결한다.
**"왜"가 코드 문법만으로는 전혀 드러나지 않을 때만** 추가하며, 모든 함수에 기계적으로 붙이지 않는다.

- **Workaround/Hack** — 외부 라이브러리·특정 DB 드라이버·레거시 시스템의 버그·특이 동작 우회
- **Business Rule** — 코드만으로 유추 불가능한 도메인 규칙
- **Non-obvious Trade-off** — 가독성보다 성능·보안을 택한 경우(커넥션 풀 크기, 캐싱 레이어 등)
- `[WHY]`(필수)/`[CONTEXT]`/`[TRADE-OFF]` 태그로 1~2줄만, 무거운 템플릿 금지

```python
# [WHY] 특정 결제 PG의 웹훅이 동일 이벤트를 중복 전송하는 버그가 있어 이벤트 ID로 dedup
# [CONTEXT] 오프라인 매장은 재고 음수를 허용하는 정책(온라인과 다른 룰)
```

### Provider Header

- 적용 대상: DI 의존성 함수(`Depends` 대상, `core/*.py`의 provider), `lifespan` 컨텍스트 매니저 최상단, 항상 붙인다
- `Domain` — 이 provider가 담당하는 책임 경계(SSOT 여부 등). 코드만으로는 알 수 없는 아키텍처 정보가 있으면 그것을 적고, 없으면 책임 범위를 한 줄로 요약한다(필수)
- `Contract` — 세션/커넥션 생명주기 등 코드로 드러나지 않는 전제조건(선택)

```python
# Domain: DB 세션 provider — 요청 스코프 세션 생성/정리 경계
# Contract: 예외 발생 시에도 async context manager가 세션을 자동 close한다. 커밋 시점은 서비스 계층 책임.
async def get_db_session() -> AsyncIterator[AsyncSession]:
    async with async_session_factory() as session:
        yield session
```

---

## Pitfalls

| 실수 | 결과 | 방지 |
|------|------|------|
| 라우터에서 직접 SQLAlchemy 쿼리 작성 | 서비스 계층 우회, 테스트 어려움 | `service.py`로 위임 |
| Pydantic 스키마와 SQLAlchemy 모델 혼용 | ORM lazy-load 필드가 응답에 그대로 직렬화되어 정보 노출/직렬화 에러 | Read 스키마 분리 + `from_attributes=True` |
| async 엔드포인트에서 동기 blocking 호출(예: 동기 HTTP 클라이언트) | 이벤트 루프 블로킹 → 전체 워커 응답 지연 | 비동기 클라이언트(`httpx.AsyncClient`) 또는 `run_in_threadpool` |
| 모델 필드만 바꾸고 Alembic revision 생략 | 스키마 drift, 배포 시 마이그레이션 누락 | 모델 변경 시 `alembic revision --autogenerate` 필수화 |
| DB 세션을 모듈 전역 변수로 재사용 | 요청 간 세션 공유로 동시성 버그 | 요청 스코프 `Depends(get_db_session)`만 사용 |
| 서비스 계층에서 `HTTPException` 직접 raise | HTTP 계층과 결합 → 서비스 재사용(배치/CLI) 시 깨짐 | 커스텀 예외 + `exception_handler` 매핑 |
| `allow_origins=["*"]` + `allow_credentials=True` 동시 사용 | 자격증명 탈취로 이어질 수 있는 CORS 오설정 | 명시적 origin allow-list |
| 제출/결제 등 단발 API를 클라이언트 재진입 가드만으로 방어 | 네트워크 재시도·중복 탭에서 중복 리소스 생성 | Idempotency-Key + DB unique 제약으로 서버가 직접 보장. 판정 기준은 `.claude/refs/interaction-integrity.md` §1·C4 |

---

## Project Decisions

아래는 preset 주입 후 반드시 프로젝트 실정에 맞게 채운다.

- **Architecture SSOT:** [예: `docs/architecture.md`]
- **DB SSOT:** [예: PostgreSQL, `app/core/db.py`]
- **Migration 정책:** [예: `alembic/` 디렉토리, PR마다 revision 포함 필수]
- **Auth 전략:** [예: JWT Bearer / 세션 쿠키 중 택1]
- **비동기 워커:** [예: Celery + Redis 사용 여부, 미사용이면 "미사용"]
- **Sensitive Files:** [예: `.env`, `*.pem`, `alembic.ini`의 DB 접속 정보]
