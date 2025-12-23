"""init schema

Revision ID: 0001_init
Revises: 
Create Date: 2024-01-01 00:00:00
"""

from pathlib import Path
from alembic import op

from app.sql_utils import split_sql_statements

revision = '0001_init'
down_revision = None
branch_labels = None
depends_on = None


DB_DIR = Path('/db')


def _run_sql(filename: str) -> None:
    sql_path = DB_DIR / filename
    sql_text = sql_path.read_text(encoding='utf-8')
    for statement in split_sql_statements(sql_text):
        op.execute(statement)


def upgrade() -> None:
    _run_sql('schema.sql')
    _run_sql('audit.sql')
    _run_sql('aggregates.sql')
    _run_sql('functions.sql')
    _run_sql('views.sql')
    _run_sql('indexes.sql')


def downgrade() -> None:
    op.execute('DROP VIEW IF EXISTS v_review_analytics CASCADE')
    op.execute('DROP VIEW IF EXISTS v_assignment_summary CASCADE')
    op.execute('DROP VIEW IF EXISTS v_course_progress CASCADE')
    op.execute('DROP FUNCTION IF EXISTS fn_instructor_load(BIGINT) CASCADE')
    op.execute('DROP FUNCTION IF EXISTS fn_assignment_report(BIGINT) CASCADE')
    op.execute('DROP FUNCTION IF EXISTS fn_course_leaderboard(BIGINT) CASCADE')
    op.execute('DROP FUNCTION IF EXISTS fn_late_penalty(TIMESTAMPTZ, TIMESTAMPTZ) CASCADE')
    op.execute('DROP FUNCTION IF EXISTS fn_student_course_progress(BIGINT, BIGINT) CASCADE')
    op.execute('DROP FUNCTION IF EXISTS fn_student_course_rating(BIGINT, BIGINT) CASCADE')
    op.execute('DROP TABLE IF EXISTS assignment_stats CASCADE')
    op.execute('DROP TABLE IF EXISTS course_leaderboard_cache CASCADE')
    op.execute('DROP TABLE IF EXISTS audit_log CASCADE')
    op.execute('DROP TABLE IF EXISTS import_error_log CASCADE')
    op.execute('DROP TABLE IF EXISTS notifications CASCADE')
    op.execute('DROP TABLE IF EXISTS grades CASCADE')
    op.execute('DROP TABLE IF EXISTS submission_files CASCADE')
    op.execute('DROP TABLE IF EXISTS submissions CASCADE')
    op.execute('DROP TABLE IF EXISTS assignment_criteria CASCADE')
    op.execute('DROP TABLE IF EXISTS assignments CASCADE')
    op.execute('DROP TABLE IF EXISTS course_enrollments CASCADE')
    op.execute('DROP TABLE IF EXISTS course_instructors CASCADE')
    op.execute('DROP TABLE IF EXISTS courses CASCADE')
    op.execute('DROP TABLE IF EXISTS users CASCADE')
    op.execute('DROP EXTENSION IF EXISTS pgcrypto')
