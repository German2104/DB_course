import asyncio
import os
import random
from datetime import datetime, timedelta

import asyncpg
from faker import Faker

fake = Faker('ru_RU')


async def main():
    database_url = os.getenv('DATABASE_URL', 'postgresql://postgres:postgres@localhost:5432/lms')
    conn = await asyncpg.connect(database_url)

    await conn.execute('TRUNCATE TABLE import_error_log, notifications, grades, submission_files, submissions, assignment_criteria, assignments, course_enrollments, course_instructors, courses, users RESTART IDENTITY CASCADE')

    users = []
    for i in range(700):
        users.append((fake.unique.email(), fake.name(), 'student', 'hashed_password', True))
    for i in range(80):
        users.append((fake.unique.email(), fake.name(), 'instructor', 'hashed_password', True))
    for i in range(20):
        users.append((fake.unique.email(), fake.name(), 'admin', 'hashed_password', True))
    await conn.executemany(
        'INSERT INTO users (email, full_name, role, password_hash, is_active) VALUES ($1, $2, $3, $4, $5)',
        users,
    )

    user_rows = await conn.fetch('SELECT id, role FROM users')
    students = [row['id'] for row in user_rows if row['role'] == 'student']
    instructors = [row['id'] for row in user_rows if row['role'] == 'instructor']

    courses = []
    for i in range(30):
        code = f'DB-{i+1:02d}'
        title = f'Базы данных: модуль {i+1}'
        desc = fake.text(max_nb_chars=120)
        created_by = random.choice(instructors)
        start = datetime.utcnow().date() - timedelta(days=30)
        end = datetime.utcnow().date() + timedelta(days=120)
        courses.append((code, title, desc, created_by, start, end, True))
    await conn.executemany(
        'INSERT INTO courses (code, title, description, created_by, start_date, end_date, is_active) VALUES ($1, $2, $3, $4, $5, $6, $7)',
        courses,
    )

    course_rows = await conn.fetch('SELECT id FROM courses')
    course_ids = [row['id'] for row in course_rows]

    course_instructors = []
    for course_id in course_ids:
        for instructor_id in random.sample(instructors, 2):
            course_instructors.append((course_id, instructor_id, 'lecturer', True))
    await conn.executemany(
        'INSERT INTO course_instructors (course_id, instructor_id, role_label, is_primary) VALUES ($1, $2, $3, $4)',
        course_instructors,
    )

    enrollments = []
    for course_id in course_ids:
        for student_id in random.sample(students, 35):
            enrollments.append((course_id, student_id, 'enrolled', datetime.utcnow()))
    await conn.executemany(
        'INSERT INTO course_enrollments (course_id, student_id, status, enrolled_at) VALUES ($1, $2, $3, $4)',
        enrollments,
    )

    assignments = []
    for course_id in course_ids:
        for i in range(8):
            title = f'Лабораторная работа {i+1}'
            desc = fake.text(max_nb_chars=200)
            max_score = random.choice([10, 15, 20, 25])
            due_at = datetime.utcnow() + timedelta(days=random.randint(5, 40))
            assignments.append((course_id, title, desc, max_score, due_at, True, i + 1))
    await conn.executemany(
        'INSERT INTO assignments (course_id, title, description, max_score, due_at, allow_late, position) VALUES ($1, $2, $3, $4, $5, $6, $7)',
        assignments,
    )

    assignment_rows = await conn.fetch('SELECT id FROM assignments')
    assignment_ids = [row['id'] for row in assignment_rows]

    criteria = []
    for assignment_id in assignment_ids:
        for i in range(3):
            criteria.append((assignment_id, f'Критерий {i+1}', fake.text(max_nb_chars=120), 5.0, 0.33))
    await conn.executemany(
        'INSERT INTO assignment_criteria (assignment_id, title, description, max_points, weight) VALUES ($1, $2, $3, $4, $5)',
        criteria,
    )

    submissions = []
    submission_files = []
    grades = []
    notifications = []

    submission_id = 1
    for _ in range(6000):
        assignment_id = random.choice(assignment_ids)
        student_id = random.choice(students)
        attempt_no = random.randint(1, 3)
        submitted_at = datetime.utcnow() - timedelta(days=random.randint(0, 20))
        status = random.choice(['submitted', 'in_review', 'accepted', 'rejected'])
        is_late = random.choice([True, False])
        content_text = fake.text(max_nb_chars=200)
        submissions.append((assignment_id, student_id, attempt_no, submitted_at, status, is_late, content_text))

        submission_files.append((submission_id, f'report_{submission_id}.pdf', f'/files/{submission_id}.pdf', random.randint(10000, 500000), 'application/pdf', fake.md5()))

        if random.random() > 0.15:
            reviewer_id = random.choice(instructors)
            score = round(random.uniform(5, 25), 2)
            grades.append((submission_id, reviewer_id, score, fake.text(max_nb_chars=120), random.choice(['pending', 'graded', 'rework']), datetime.utcnow()))

        if random.random() > 0.7:
            notifications.append((student_id, random.choice(['deadline', 'status_change', 'grade_posted']), fake.text(max_nb_chars=80)))

        submission_id += 1

    await conn.executemany(
        'INSERT INTO submissions (assignment_id, student_id, attempt_no, submitted_at, status, is_late, content_text) VALUES ($1, $2, $3, $4, $5, $6, $7)',
        submissions,
    )

    await conn.executemany(
        'INSERT INTO submission_files (submission_id, file_name, file_path, file_size, mime_type, checksum) VALUES ($1, $2, $3, $4, $5, $6)',
        submission_files,
    )

    await conn.executemany(
        'INSERT INTO grades (submission_id, reviewer_id, score, feedback, status, graded_at) VALUES ($1, $2, $3, $4, $5, $6)',
        grades,
    )

    await conn.executemany(
        'INSERT INTO notifications (user_id, type, message) VALUES ($1, $2, $3)',
        notifications,
    )

    import_errors = []
    for i in range(5000):
        import_errors.append((random.choice(['csv', 'json']), i + 1, {'row': i + 1, 'value': fake.word()}, 'Invalid value'))
    await conn.executemany(
        'INSERT INTO import_error_log (source, row_number, payload, error_message) VALUES ($1, $2, $3, $4)',
        import_errors,
    )

    audit_rows = []
    for i in range(5000):
        audit_rows.append((random.choice(students), 'submissions', str(random.randint(1, 6000)), 'INSERT', {'id': i}, {'id': i}, None, '127.0.0.1', 'seed'))
    await conn.executemany(
        'INSERT INTO audit_log (actor_user_id, table_name, row_pk, operation, old_data, new_data, request_id, ip, user_agent) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)',
        audit_rows,
    )

    await conn.execute('''
        INSERT INTO assignment_stats (assignment_id, submissions_count, graded_count, avg_score, last_submission_at)
        SELECT a.id,
               COUNT(s.id),
               COUNT(g.id),
               COALESCE(AVG(g.score), 0),
               MAX(s.submitted_at)
        FROM assignments a
        LEFT JOIN submissions s ON s.assignment_id = a.id
        LEFT JOIN grades g ON g.submission_id = s.id
        GROUP BY a.id
        ON CONFLICT (assignment_id) DO NOTHING
    ''')

    await conn.execute('''
        INSERT INTO course_leaderboard_cache (course_id, student_id, total_score, max_score, progress_pct)
        SELECT a.course_id,
               s.student_id,
               COALESCE(SUM(g.score), 0) AS total_score,
               COALESCE(SUM(a.max_score), 0) AS max_score,
               CASE WHEN SUM(a.max_score) > 0 THEN ROUND((SUM(g.score) / SUM(a.max_score)) * 100, 2) ELSE 0 END AS progress_pct
        FROM assignments a
        JOIN submissions s ON s.assignment_id = a.id
        LEFT JOIN grades g ON g.submission_id = s.id
        GROUP BY a.course_id, s.student_id
        ON CONFLICT (course_id, student_id) DO NOTHING
    ''')

    await conn.close()


if __name__ == '__main__':
    asyncio.run(main())
