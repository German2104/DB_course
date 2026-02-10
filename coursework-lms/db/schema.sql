CREATE TABLE users (
    user_id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    full_name VARCHAR(200) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('student', 'teacher', 'admin')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE courses (
    course_id BIGSERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    teacher_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE enrollments (
    enrollment_id BIGSERIAL PRIMARY KEY,
    course_id BIGINT NOT NULL REFERENCES courses(course_id) ON DELETE CASCADE,
    student_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    enrolled_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (course_id, student_id)
);

CREATE TABLE assignments (
    assignment_id BIGSERIAL PRIMARY KEY,
    course_id BIGINT NOT NULL REFERENCES courses(course_id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    max_score INT NOT NULL CHECK (max_score > 0 AND max_score <= 100),
    due_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE submissions (
    submission_id BIGSERIAL PRIMARY KEY,
    assignment_id BIGINT NOT NULL REFERENCES assignments(assignment_id) ON DELETE CASCADE,
    student_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    submitted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    content TEXT NOT NULL,
    UNIQUE (assignment_id, student_id)
);

CREATE TABLE grades (
    grade_id BIGSERIAL PRIMARY KEY,
    submission_id BIGINT NOT NULL UNIQUE REFERENCES submissions(submission_id) ON DELETE CASCADE,
    teacher_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
    score INT NOT NULL CHECK (score >= 0 AND score <= 100),
    feedback TEXT NOT NULL,
    graded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_courses_teacher_id ON courses(teacher_id);
CREATE INDEX idx_enrollments_student_id ON enrollments(student_id);
CREATE INDEX idx_assignments_course_id ON assignments(course_id);
CREATE INDEX idx_submissions_student_id ON submissions(student_id);
CREATE INDEX idx_submissions_assignment_id ON submissions(assignment_id);
