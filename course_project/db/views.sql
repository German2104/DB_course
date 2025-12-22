CREATE OR REPLACE VIEW v_course_progress AS
SELECT
    ce.course_id,
    c.title AS course_title,
    ce.student_id,
    u.full_name,
    ce.progress_pct,
    ce.final_grade,
    ce.status
FROM course_enrollments ce
JOIN courses c ON c.id = ce.course_id
JOIN users u ON u.id = ce.student_id;

CREATE OR REPLACE VIEW v_assignment_summary AS
SELECT
    a.id AS assignment_id,
    a.title,
    a.course_id,
    c.title AS course_title,
    COUNT(s.id) AS submissions_count,
    COUNT(g.id) AS graded_count,
    COALESCE(AVG(g.score), 0) AS avg_score
FROM assignments a
JOIN courses c ON c.id = a.course_id
LEFT JOIN submissions s ON s.assignment_id = a.id
LEFT JOIN grades g ON g.submission_id = s.id
GROUP BY a.id, a.title, a.course_id, c.title;

CREATE OR REPLACE VIEW v_review_analytics AS
SELECT
    g.reviewer_id,
    u.full_name AS reviewer_name,
    COUNT(g.id) AS graded_total,
    AVG(EXTRACT(EPOCH FROM (g.graded_at - s.submitted_at)) / 3600) AS avg_review_hours,
    SUM(CASE WHEN g.status = 'rework' THEN 1 ELSE 0 END) AS rework_count
FROM grades g
JOIN submissions s ON s.id = g.submission_id
JOIN users u ON u.id = g.reviewer_id
GROUP BY g.reviewer_id, u.full_name;
