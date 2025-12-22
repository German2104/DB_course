-- 1. Рейтинг по курсу с учетом прогресса и последних оценок
SELECT
    u.id AS student_id,
    u.full_name,
    SUM(g.score) AS total_score,
    COUNT(DISTINCT a.id) AS assignments_graded,
    MAX(s.submitted_at) AS last_submission
FROM course_enrollments ce
JOIN users u ON u.id = ce.student_id
JOIN assignments a ON a.course_id = ce.course_id
LEFT JOIN submissions s ON s.assignment_id = a.id AND s.student_id = ce.student_id
LEFT JOIN grades g ON g.submission_id = s.id
WHERE ce.course_id = 1
GROUP BY u.id, u.full_name
ORDER BY total_score DESC NULLS LAST;

-- 2. Выявление студентов с риском просрочки
SELECT
    u.id AS student_id,
    u.full_name,
    a.id AS assignment_id,
    a.title,
    a.due_at
FROM assignments a
JOIN course_enrollments ce ON ce.course_id = a.course_id
JOIN users u ON u.id = ce.student_id
LEFT JOIN submissions s ON s.assignment_id = a.id AND s.student_id = ce.student_id
WHERE a.due_at < now() + interval '2 days'
  AND s.id IS NULL
ORDER BY a.due_at, u.full_name;

-- 3. Аналитика по проверкам преподавателей
SELECT
    u.full_name AS reviewer_name,
    COUNT(g.id) AS graded_count,
    AVG(g.score) AS avg_score,
    AVG(EXTRACT(EPOCH FROM (g.graded_at - s.submitted_at)) / 3600) AS avg_hours_to_grade
FROM grades g
JOIN submissions s ON s.id = g.submission_id
JOIN users u ON u.id = g.reviewer_id
GROUP BY u.full_name
HAVING COUNT(g.id) > 10
ORDER BY avg_hours_to_grade;
