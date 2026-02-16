# LMS Platform DB (PostgreSQL)

Отдельный модуль для базы LMS, готовый для подключения FastAPI/SQLAlchemy.

## Что внутри

- `docker-compose.yml` — PostgreSQL + pgAdmin
- `db/init/001_schema.sql` — схема БД
- `db/init/002_seed.sql` — стартовые данные
- `db/queries/quick_checks.sql` — типовые SELECT-запросы
- `db/DATA_MODEL_RATIONALE.md` — обоснование типов данных и связей
- `Makefile` — короткие команды управления

## 1) Запуск БД

```bash
cd lms-platform
cp .env.example .env
make up
```

Это поднимет:
- PostgreSQL: `localhost:5433`
- FastAPI API: `http://localhost:8000`
- Swagger: `http://localhost:8000/docs`
- pgAdmin: `http://localhost:5050`

Проверка статуса:

```bash
make logs
```

Логи API:

```bash
make logs-api
```

## 2) Подключение к БД

### Через psql

```bash
make psql
```

Примеры запросов:

```sql
\dt
SELECT * FROM roles;
SELECT email, full_name FROM users;
```

### Через pgAdmin (GUI)

- URL: `http://localhost:5050`
- Login: из `.env` (`PGADMIN_EMAIL` / `PGADMIN_PASSWORD`)
- New Server:
  - Host: `postgres`
  - Port: `5432`
  - Username: `${POSTGRES_USER}`
  - Password: `${POSTGRES_PASSWORD}`
  - Database: `${POSTGRES_DB}`

## 3) Готовые проверочные запросы

```bash
make run-queries
```

## 4) Подключение через DBeaver

1. Открой `Database` -> `New Database Connection`.
2. Выбери `PostgreSQL`.
3. Вкладка `Main`:
   - Host: `localhost`
   - Port: `5433` (или твой `POSTGRES_PORT` из `.env`)
   - Database: `lms_db`
   - Username: `lms_user`
   - Password: `lms_password`
4. Нажми `Test Connection` -> `Finish`.

Если DBeaver запущен в Docker-сети вместе с Postgres, вместо `localhost` используй `postgres` и порт `5432`.

## 5) Подключение из FastAPI

`DATABASE_URL` для SQLAlchemy async:

```text
postgresql+asyncpg://lms_user:lms_password@localhost:5433/lms_db
```

`DATABASE_URL` для sync:

```text
postgresql://lms_user:lms_password@localhost:5433/lms_db
```

## 6) Пересоздать БД с нуля

```bash
make reset
```

Это удалит volume и заново применит `001_schema.sql` и `002_seed.sql`.
