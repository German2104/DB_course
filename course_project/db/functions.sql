CREATE OR REPLACE FUNCTION fn_student_course_rating(p_course_id BIGINT, p_student_id BIGINT)
RETURNS NUMERIC(8, 2) AS $$
DECLARE
    v_total NUMERIC(8, 2);
BEGIN
    SELECT COALESCE(SUM(g.score), 0)
    INTO v_total
    FROM assignments a
    JOIN submissions s ON s.assignment_id = a.id AND s.student_id = p_student_id
    JOIN grades g ON g.submission_id = s.id
    WHERE a.course_id = p_course_id;
    RETURN v_total;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_student_course_progress(p_course_id BIGINT, p_student_id BIGINT)
RETURNS NUMERIC(5, 2) AS $$
DECLARE
    v_total NUMERIC(8, 2);
    v_max NUMERIC(8, 2);
BEGIN
    SELECT COALESCE(SUM(g.score), 0), COALESCE(SUM(a.max_score), 0)
    INTO v_total, v_max
    FROM assignments a
    LEFT JOIN submissions s ON s.assignment_id = a.id AND s.student_id = p_student_id
    LEFT JOIN grades g ON g.submission_id = s.id
    WHERE a.course_id = p_course_id;

    IF v_max = 0 THEN
        RETURN 0;
    END IF;
    RETURN ROUND((v_total / v_max) * 100, 2);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_late_penalty(p_due_at TIMESTAMPTZ, p_submitted_at TIMESTAMPTZ)
RETURNS NUMERIC(6, 2) AS $$
DECLARE
    v_hours INT;
BEGIN
    IF p_submitted_at <= p_due_at THEN
        RETURN 0;
    END IF;
    v_hours := EXTRACT(EPOCH FROM (p_submitted_at - p_due_at)) / 3600;
    RETURN LEAST(v_hours * 0.5, 50);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_course_leaderboard(p_course_id BIGINT)
RETURNS TABLE (
    student_id BIGINT,
    student_name TEXT,
    total_score NUMERIC(8, 2),
    max_score NUMERIC(8, 2),
    progress_pct NUMERIC(5, 2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT u.id, u.full_name, c.total_score, c.max_score, c.progress_pct
    FROM course_leaderboard_cache c
    JOIN users u ON u.id = c.student_id
    WHERE c.course_id = p_course_id
    ORDER BY c.total_score DESC, u.full_name;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_assignment_report(p_assignment_id BIGINT)
RETURNS TABLE (
    student_id BIGINT,
    student_name TEXT,
    attempt_no INT,
    submitted_at TIMESTAMPTZ,
    score NUMERIC(6, 2),
    status TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT u.id, u.full_name, s.attempt_no, s.submitted_at, g.score, g.status
    FROM submissions s
    JOIN users u ON u.id = s.student_id
    LEFT JOIN grades g ON g.submission_id = s.id
    WHERE s.assignment_id = p_assignment_id
    ORDER BY s.submitted_at DESC;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_instructor_load(p_instructor_id BIGINT)
RETURNS TABLE (
    course_id BIGINT,
    course_title TEXT,
    assignments_count INT,
    submissions_pending INT,
    last_submission_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT c.id, c.title,
           COUNT(DISTINCT a.id) AS assignments_count,
           COUNT(s.id) FILTER (WHERE g.status IS NULL OR g.status = 'pending') AS submissions_pending,
           MAX(s.submitted_at) AS last_submission_at
    FROM courses c
    JOIN course_instructors ci ON ci.course_id = c.id
    LEFT JOIN assignments a ON a.course_id = c.id
    LEFT JOIN submissions s ON s.assignment_id = a.id
    LEFT JOIN grades g ON g.submission_id = s.id
    WHERE ci.instructor_id = p_instructor_id
    GROUP BY c.id, c.title
    ORDER BY c.title;
END;
$$ LANGUAGE plpgsql;
