# LMS Backend (FastAPI + PostgreSQL)

## Stack

- FastAPI
- SQLAlchemy 2.0 (async)
- asyncpg
- pytest + httpx

## Quick start

```bash
cd lms-platform/backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
```

Убедись, что БД уже запущена из `lms-platform`:

```bash
cd ..
make up
```

## Run API

```bash
cd backend
uvicorn app.main:app --reload
```

Swagger:

- `http://localhost:8000/docs`

## Demo Auth (без JWT)

- `GET /auth/demo-accounts`:
  - teacher: `ivan.petrov.teacher@lms.local`
  - student: `nikita.kuznetsov.student@lms.local`
- `POST /auth/login` с телом:

```json
{ "email": "nikita.kuznetsov.student@lms.local" }
```

- ответ вернет `token`, где `token = user_id` (UUID).
- для защищенных ручек передавай заголовок:
  - `X-User-Id: <token>`
- проверка текущего пользователя:
  - `GET /auth/me`

RBAC в текущем MVP:

- `POST /courses` и `PATCH /courses/{course_id}`: только `teacher/admin`
- `POST /courses/{course_id}/publish`: только `teacher/admin`
- teacher может создавать/изменять только свои курсы
- `GET /grades`: teacher видит оценки своих курсов
- `POST /submissions`: только student (отправка решения)
- `GET /courses/my`: student видит только свои курсы
- `GET /enrollments`: студент видит только свои записи

## Run tests

```bash
pytest -q
```

## API guide

- Подробный порядок использования ручек: `API_USAGE.md`
- Объяснение SQL-запросов из Python-кода: `QUERY_EXPLANATIONS.md`
