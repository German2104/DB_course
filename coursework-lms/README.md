# LMS Coursework

## Structure
- `docs/coursework_report.md` — поэтапное описание проектирования и проверки.
- `db/schema.sql` — DDL PostgreSQL.
- `db/tests.sql` — SQL-тесты ограничений.
- `db/validation_queries.sql` — аналитические запросы.
- `backend` — FastAPI + role-based JWT-like auth.
- `frontend` — минимальный React UI.

## Backend local run
```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
pytest
uvicorn app.main:app --reload
```

## Frontend local run
```bash
cd frontend
npm install
npm run dev
```

## Docker
```bash
docker compose up --build
```
