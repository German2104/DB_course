-- JOIN: course roster with teacher and students
SELECT c.title, t.full_name AS teacher, s.full_name AS student
FROM courses c
JOIN users t ON t.user_id = c.teacher_id
JOIN enrollments e ON e.course_id = c.course_id
JOIN users s ON s.user_id = e.student_id;

-- Aggregate: average grade by course
SELECT c.title, AVG(g.score) AS avg_score
FROM courses c
JOIN assignments a ON a.course_id = c.course_id
JOIN submissions s ON s.assignment_id = a.assignment_id
JOIN grades g ON g.submission_id = s.submission_id
GROUP BY c.title;

-- Subquery: students without submissions in a course
SELECT u.full_name
FROM users u
WHERE u.role = 'student'
  AND u.user_id IN (
    SELECT e.student_id
    FROM enrollments e
    WHERE e.course_id = 1
  )
  AND u.user_id NOT IN (
    SELECT s.student_id
    FROM submissions s
    JOIN assignments a ON a.assignment_id = s.assignment_id
    WHERE a.course_id = 1
  );

-- GROUP BY / HAVING: teachers with at least one graded submission
SELECT t.full_name, COUNT(g.grade_id) AS graded_count
FROM users t
JOIN grades g ON g.teacher_id = t.user_id
WHERE t.role = 'teacher'
GROUP BY t.full_name
HAVING COUNT(g.grade_id) >= 1;
