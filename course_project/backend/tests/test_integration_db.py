import os

import asyncpg
import pytest


DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@localhost:5432/lms")


@pytest.mark.asyncio
async def test_db_connection():
    conn = await asyncpg.connect(DATABASE_URL)
    value = await conn.fetchval("SELECT 1")
    await conn.close()
    assert value == 1


@pytest.mark.asyncio
async def test_tables_exist():
    conn = await asyncpg.connect(DATABASE_URL)
    rows = await conn.fetch(
        """
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'public'
        """
    )
    await conn.close()
    tables = {row["table_name"] for row in rows}
    for table in {"users", "courses", "assignments", "submissions", "grades"}:
        assert table in tables


@pytest.mark.asyncio
async def test_fk_constraints_present():
    conn = await asyncpg.connect(DATABASE_URL)
    fk_count = await conn.fetchval(
        """
        SELECT COUNT(*)
        FROM information_schema.table_constraints
        WHERE table_schema = 'public'
          AND table_name = 'submissions'
          AND constraint_type = 'FOREIGN KEY'
        """
    )
    await conn.close()
    assert fk_count >= 2


@pytest.mark.asyncio
async def test_seed_data_present():
    conn = await asyncpg.connect(DATABASE_URL)
    submissions_count = await conn.fetchval("SELECT COUNT(*) FROM submissions")
    users_count = await conn.fetchval("SELECT COUNT(*) FROM users")
    await conn.close()
    assert submissions_count >= 5000
    assert users_count >= 500
