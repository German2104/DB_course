from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession


async def course_leaderboard(session: AsyncSession, course_id: int):
    query = text('''
        SELECT student_id, student_name, total_score, max_score, progress_pct
        FROM fn_course_leaderboard(:course_id)
    ''')
    result = await session.execute(query, {'course_id': course_id})
    return [dict(row) for row in result.mappings().all()]


async def assignment_report(session: AsyncSession, assignment_id: int):
    query = text('''
        SELECT student_id, student_name, attempt_no, submitted_at, score, status
        FROM fn_assignment_report(:assignment_id)
    ''')
    result = await session.execute(query, {'assignment_id': assignment_id})
    return [dict(row) for row in result.mappings().all()]


async def instructor_load(session: AsyncSession, instructor_id: int):
    query = text('''
        SELECT course_id, course_title, assignments_count, submissions_pending, last_submission_at
        FROM fn_instructor_load(:instructor_id)
    ''')
    result = await session.execute(query, {'instructor_id': instructor_id})
    return [dict(row) for row in result.mappings().all()]
