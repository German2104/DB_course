from pathlib import Path


BASE_DIR = Path(__file__).resolve().parents[2]
DB_DIR = BASE_DIR / "db"


def _read_sql(name: str) -> str:
    return (DB_DIR / name).read_text(encoding="utf-8")


def test_schema_has_core_tables():
    schema = _read_sql("schema.sql")
    for table in [
        "users",
        "courses",
        "course_instructors",
        "course_enrollments",
        "assignments",
        "assignment_criteria",
        "submissions",
        "submission_files",
        "grades",
        "notifications",
        "import_error_log",
    ]:
        assert f"CREATE TABLE {table}" in schema


def test_audit_and_aggregate_sql_present():
    audit_sql = _read_sql("audit.sql")
    aggregates_sql = _read_sql("aggregates.sql")
    assert "CREATE TABLE audit_log" in audit_sql
    assert "CREATE TABLE course_leaderboard_cache" in aggregates_sql
    assert "CREATE TABLE assignment_stats" in aggregates_sql


def test_functions_and_views_present():
    functions_sql = _read_sql("functions.sql")
    views_sql = _read_sql("views.sql")
    assert "fn_student_course_rating" in functions_sql
    assert "fn_course_leaderboard" in functions_sql
    assert "CREATE OR REPLACE VIEW v_course_progress" in views_sql
    assert "CREATE OR REPLACE VIEW v_assignment_summary" in views_sql
    assert "CREATE OR REPLACE VIEW v_review_analytics" in views_sql
