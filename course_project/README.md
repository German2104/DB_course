# LMS-lite: информационная система управления учебными заданиями

Автор: Пермяков Герман Алексеевич

Проект: веб‑сервис для публикации заданий, сдачи решений, проверки, расчёта рейтингов и уведомлений.

## Быстрый старт

```bash
docker-compose up --build
```

- Frontend: http://localhost:5173
- Backend (Swagger UI): http://localhost:8000/api/docs
- OpenAPI JSON: http://localhost:8000/api/openapi.json

## Миграции и сидинг

Миграции выполняются сервисом `migrate` автоматически при `docker-compose up`.
Сидинг выполняется сервисом `seed` после миграций.

При необходимости:

```bash
docker-compose run --rm migrate
```

```bash
docker-compose run --rm seed
```

## Примеры запросов

### Логин

```bash
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=student1@example.com&password=secret"
```

### Курсы

```bash
curl http://localhost:8000/api/courses
```

### Задания курса

```bash
curl http://localhost:8000/api/courses/1/assignments
```

### Отчёт: лидерборд

```bash
curl http://localhost:8000/api/reports/leaderboard/1
```

### Batch import (CSV)

```bash
curl -X POST "http://localhost:8000/api/batch-import?dry_run=false&continue_on_error=true" \
  -H "Authorization: Bearer <TOKEN>" \
  -F "file=@samples/submissions.csv"
```

## Структура проекта

```
course_project/
  db/                # DDL, функции, триггеры, индексы, сидинг
  backend/           # FastAPI + SQLAlchemy + Alembic
  frontend/          # React + Vite + TypeScript
  docs/              # план пояснительной записки
```
