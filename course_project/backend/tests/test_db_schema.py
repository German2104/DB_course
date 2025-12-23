from pathlib import Path
from unittest import TestCase


BASE_DIR = Path(__file__).resolve().parents[2]
DB_DIR = BASE_DIR / "db"


def _read_sql(name: str) -> str:
    return (DB_DIR / name).read_text(encoding="utf-8")


class TestDbSchemaFiles(TestCase):
    def test_schema_has_core_tables(self):
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
            self.assertIn(f"CREATE TABLE {table}", schema)

    def test_audit_and_aggregate_sql_present(self):
        audit_sql = _read_sql("audit.sql")
        aggregates_sql = _read_sql("aggregates.sql")
        self.assertIn("CREATE TABLE audit_log", audit_sql)
        self.assertIn("CREATE TABLE course_leaderboard_cache", aggregates_sql)
        self.assertIn("CREATE TABLE assignment_stats", aggregates_sql)

    def test_functions_and_views_present(self):
        functions_sql = _read_sql("functions.sql")
        views_sql = _read_sql("views.sql")
        self.assertIn("fn_student_course_rating", functions_sql)
        self.assertIn("fn_course_leaderboard", functions_sql)
        self.assertIn("CREATE OR REPLACE VIEW v_course_progress", views_sql)
        self.assertIn("CREATE OR REPLACE VIEW v_assignment_summary", views_sql)
        self.assertIn("CREATE OR REPLACE VIEW v_review_analytics", views_sql)
