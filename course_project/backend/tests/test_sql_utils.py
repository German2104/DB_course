import unittest
from pathlib import Path
import sys

BACKEND_DIR = Path(__file__).resolve().parents[1]
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

from app.sql_utils import split_sql_statements


class TestSqlSplit(unittest.TestCase):
    def test_split_handles_dollar_blocks(self):
        sql = """
        CREATE TABLE example(id INT);
        CREATE OR REPLACE FUNCTION test_fn() RETURNS void AS $$
        BEGIN
            RAISE NOTICE 'hi';
        END;
        $$ LANGUAGE plpgsql;
        CREATE INDEX idx_example_id ON example(id);
        """
        statements = list(split_sql_statements(sql))
        self.assertEqual(len(statements), 3)
        self.assertTrue(statements[0].startswith("CREATE TABLE example"))
        self.assertIn("FUNCTION test_fn", statements[1])
        self.assertTrue(statements[2].startswith("CREATE INDEX idx_example_id"))
