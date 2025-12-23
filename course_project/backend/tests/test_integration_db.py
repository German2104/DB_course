import os

import asyncio

import asyncpg
import pytest


DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@localhost:5432/lms")


async def _connect():
    return await asyncpg.connect(DATABASE_URL)


def _run(coro):
    return asyncio.run(coro)


def _connect_or_skip():
    try:
        return _run(_connect())
    except Exception as exc:  # pragma: no cover - environment dependent
        pytest.skip(f"Database not available: {exc}")


def test_db_connection():
    conn = _connect_or_skip()
    value = _run(conn.fetchval("SELECT 1"))
    _run(conn.close())
    assert value == 1


def test_tables_exist():
    conn = _connect_or_skip()
    rows = _run(
        conn.fetch(
            """
            SELECT table_name
            FROM information_schema.tables
            WHERE table_schema = 'public'
            """
        )
    )
    _run(conn.close())
    tables = {row["table_name"] for row in rows}
    for table in {"users", "courses", "assignments", "submissions", "grades"}:
        assert table in tables


def test_fk_constraints_present():
    conn = _connect_or_skip()
    fk_count = _run(
        conn.fetchval(
            """
            SELECT COUNT(*)
            FROM information_schema.table_constraints
            WHERE table_schema = 'public'
              AND table_name = 'submissions'
              AND constraint_type = 'FOREIGN KEY'
            """
        )
    )
    _run(conn.close())
    assert fk_count >= 2


def test_seed_data_present():
    conn = _connect_or_skip()
    submissions_count = _run(conn.fetchval("SELECT COUNT(*) FROM submissions"))
    users_count = _run(conn.fetchval("SELECT COUNT(*) FROM users"))
    _run(conn.close())
    assert submissions_count >= 5000
    assert users_count >= 500
