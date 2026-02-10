-- Valid inserts
INSERT INTO users (email, password_hash, full_name, role) VALUES
('admin@lms.local', 'hash_admin', 'System Admin', 'admin'),
('teacher1@lms.local', 'hash_t1', 'Dr. Teacher', 'teacher'),
('student1@lms.local', 'hash_s1', 'Alice Student', 'student');

INSERT INTO courses (title, description, teacher_id)
VALUES ('Database Systems', 'Relational modeling and SQL', 2);

INSERT INTO enrollments (course_id, student_id) VALUES (1, 3);

INSERT INTO assignments (course_id, title, description, max_score, due_at)
VALUES (1, 'Normalization Homework', 'Normalize relation to 3NF', 100, NOW() + INTERVAL '7 days');

INSERT INTO submissions (assignment_id, student_id, content)
VALUES (1, 3, 'My 3NF solution');

INSERT INTO grades (submission_id, teacher_id, score, feedback)
VALUES (1, 2, 95, 'Excellent decomposition');

-- Invalid data tests (expected fail)
-- duplicate enrollment
INSERT INTO enrollments (course_id, student_id) VALUES (1, 3);
-- invalid role
INSERT INTO users (email, password_hash, full_name, role) VALUES ('x@x.x', 'h', 'Bad Role', 'moderator');
-- score out of range
INSERT INTO grades (submission_id, teacher_id, score, feedback) VALUES (1, 2, 150, 'Invalid score');

-- Referential integrity test (expected fail): non-existing teacher
INSERT INTO courses (title, teacher_id) VALUES ('Broken course', 999);

-- Cascade delete test
DELETE FROM assignments WHERE assignment_id = 1;
-- Expect linked submissions and grades deleted

-- Concurrency scenario (manual in two sessions)
-- Session A: BEGIN; UPDATE submissions SET content='A' WHERE submission_id=1;
-- Session B: BEGIN; UPDATE submissions SET content='B' WHERE submission_id=1; -- waits for lock
-- Session A: COMMIT;
-- Session B: COMMIT;
