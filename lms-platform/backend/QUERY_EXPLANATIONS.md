# Объяснение SQL-Запросов Из Python Кода

Документ описывает, какие запросы формируются в сервисах backend (`app/services/*.py`), зачем они нужны и во что логически разворачиваются в SQL.

## user_service.py

### `list_users(limit, offset)`
- Что делает: получает список активных пользователей (без soft delete) с пагинацией.
- SQL-логика:
```sql
SELECT *
FROM users
WHERE deleted_at IS NULL
ORDER BY created_at DESC
LIMIT :limit OFFSET :offset;
```

### `get_user_by_id(user_id)`
- Что делает: получает одного пользователя по UUID.
- SQL-логика:
```sql
SELECT *
FROM users
WHERE id = :user_id AND deleted_at IS NULL;
```

### `get_user_by_email(email)`
- Что делает: поиск пользователя по email для логина.
- SQL-логика:
```sql
SELECT *
FROM users
WHERE email = :email AND deleted_at IS NULL;
```

### `get_role_name_by_id(role_id)`
- Что делает: получает текстовое имя роли (`student/teacher/admin`).
- SQL-логика:
```sql
SELECT name
FROM roles
WHERE id = :role_id;
```

## course_service.py

### `list_courses(published_only, teacher_id, limit, offset)`
- Что делает: каталог курсов с фильтрами публикации и преподавателя.
- SQL-логика:
```sql
SELECT *
FROM courses
WHERE deleted_at IS NULL
  AND (:published_only = false OR is_published = true)
  AND (:teacher_id IS NULL OR teacher_id = :teacher_id)
ORDER BY created_at DESC
LIMIT :limit OFFSET :offset;
```

### `get_course_by_id(course_id)`
- Что делает: получает курс по UUID.
- SQL-логика:
```sql
SELECT *
FROM courses
WHERE id = :course_id AND deleted_at IS NULL;
```

### `create_course(payload, teacher_id)`
- Что делает: вставляет новый курс.
- SQL-логика:
```sql
INSERT INTO courses (id, title, description, teacher_id, is_published, created_at, updated_at)
VALUES (:id, :title, :description, :teacher_id, :is_published, :created_at, :updated_at);
```

### `update_course(course, payload)`
- Что делает: обновляет поля курса.
- SQL-логика:
```sql
UPDATE courses
SET title = COALESCE(:title, title),
    description = COALESCE(:description, description),
    is_published = COALESCE(:is_published, is_published),
    updated_at = NOW()
WHERE id = :course_id;
```

### `list_my_courses(user_id, role, limit, offset)`
- Что делает: возвращает “мои курсы” в зависимости от роли.
- SQL-логика для `student`:
```sql
SELECT c.*
FROM courses c
JOIN enrollments e ON e.course_id = c.id
WHERE c.deleted_at IS NULL
  AND e.deleted_at IS NULL
  AND e.user_id = :user_id
ORDER BY c.created_at DESC
LIMIT :limit OFFSET :offset;
```
- SQL-логика для `teacher`:
```sql
SELECT *
FROM courses
WHERE deleted_at IS NULL
  AND teacher_id = :user_id
ORDER BY created_at DESC
LIMIT :limit OFFSET :offset;
```
- SQL-логика для `admin`: тот же запрос без фильтра `teacher_id`.

### `publish_course(course)`
- Что делает: публикует курс.
- SQL-логика:
```sql
UPDATE courses
SET is_published = true,
    updated_at = NOW()
WHERE id = :course_id;
```

## enrollment_service.py

### `list_enrollments(user_id, course_id, limit, offset)`
- Что делает: список записей на курсы.
- SQL-логика:
```sql
SELECT *
FROM enrollments
WHERE deleted_at IS NULL
  AND (:user_id IS NULL OR user_id = :user_id)
  AND (:course_id IS NULL OR course_id = :course_id)
ORDER BY enrolled_at DESC
LIMIT :limit OFFSET :offset;
```

## assignment_service.py

### `list_assignments(course_id, limit, offset)`
- Что делает: общий список заданий с опциональным фильтром по курсу.
- SQL-логика:
```sql
SELECT a.*
FROM assignments a
JOIN lessons l ON l.id = a.lesson_id
JOIN courses c ON c.id = l.course_id
WHERE a.deleted_at IS NULL
  AND l.deleted_at IS NULL
  AND c.deleted_at IS NULL
  AND (:course_id IS NULL OR c.id = :course_id)
ORDER BY a.created_at DESC
LIMIT :limit OFFSET :offset;
```

### `list_assignments_for_student(student_id, limit, offset)`
- Что делает: задания только по курсам конкретного студента.
- SQL-логика:
```sql
SELECT a.*
FROM assignments a
JOIN lessons l ON l.id = a.lesson_id
JOIN courses c ON c.id = l.course_id
JOIN enrollments e ON e.course_id = c.id AND e.user_id = :student_id
WHERE a.deleted_at IS NULL
  AND l.deleted_at IS NULL
  AND c.deleted_at IS NULL
  AND e.deleted_at IS NULL
ORDER BY a.created_at DESC
LIMIT :limit OFFSET :offset;
```

## submission_service.py

### `create_submission_for_student(student_id, payload)`
- Шаг 1. Проверка, что студент записан на курс задания (`EXISTS`):
```sql
SELECT EXISTS (
  SELECT 1
  FROM enrollments e
  JOIN lessons l ON l.course_id = e.course_id
  JOIN assignments a ON a.lesson_id = l.id
  WHERE e.user_id = :student_id
    AND e.deleted_at IS NULL
    AND l.deleted_at IS NULL
    AND a.deleted_at IS NULL
    AND a.id = :assignment_id
);
```
- Шаг 2. Попытка вставки новой отправки:
```sql
INSERT INTO submissions (id, assignment_id, student_id, content, submitted_at, created_at, updated_at)
VALUES (:id, :assignment_id, :student_id, :content, :submitted_at, :created_at, :updated_at);
```
- Шаг 3. Если сработал `UNIQUE (assignment_id, student_id)`, выполняется обновление существующей отправки:
```sql
UPDATE submissions
SET content = :content,
    submitted_at = :submitted_at,
    updated_at = :updated_at
WHERE assignment_id = :assignment_id
  AND student_id = :student_id
  AND deleted_at IS NULL;
```

## grade_service.py

### `list_grades_for_teacher(teacher_id, course_id, limit, offset)`
- Что делает: денормализованный список оценок для таблицы UI (курс, задание, студент, оценка).
- SQL-логика:
```sql
SELECT
  g.id          AS grade_id,
  g.score,
  g.feedback,
  g.graded_at,
  s.id          AS submission_id,
  s.assignment_id,
  a.title       AS assignment_title,
  s.student_id,
  u.email       AS student_email,
  c.id          AS course_id,
  c.title       AS course_title
FROM grades g
JOIN submissions s ON s.id = g.submission_id
JOIN assignments a ON a.id = s.assignment_id
JOIN lessons l     ON l.id = a.lesson_id
JOIN courses c     ON c.id = l.course_id
JOIN users u       ON u.id = s.student_id
WHERE g.deleted_at IS NULL
  AND s.deleted_at IS NULL
  AND a.deleted_at IS NULL
  AND l.deleted_at IS NULL
  AND c.deleted_at IS NULL
  AND u.deleted_at IS NULL
  AND (:teacher_id IS NULL OR c.teacher_id = :teacher_id)
  AND (:course_id IS NULL OR c.id = :course_id)
ORDER BY g.graded_at DESC
LIMIT :limit OFFSET :offset;
```

## Где используются эти запросы

- Роуты (`app/api/routes/*.py`) вызывают сервисы.
- Сервисы формируют SQLAlchemy-запросы.
- Фактический SQL отправляется в PostgreSQL через `AsyncSession.execute()` / `commit()`.
