# Курсовая работа: LMS для студентов и преподавателей

## Этап 1. Предметная область и требования

### Роли
- **student**: просматривает курсы, записывается на курс, отправляет решения заданий, видит оценки.
- **teacher**: создает курс, публикует задания, проверяет решения, выставляет оценки.
- **admin**: управляет пользователями, аудитом, глобальными политиками и доступом.

### Бизнес-процессы
1. **Запись на курс**: студент выбирает курс, система проверяет уникальность (один студент не может быть записан дважды на один курс), создается enrollment.
2. **Сдача задания**: студент отправляет submission по assignment, ограничение — 1 активная submission на студента и задание.
3. **Проверка**: преподаватель получает список submissions по своим курсам.
4. **Оценивание**: преподаватель выставляет grade в диапазоне 0..100; одна оценка на одну submission.

### Ограничения целостности
- email пользователя уникален;
- роль пользователя ограничена enum-подобным CHECK;
- score ограничен 0..100;
- max_score ограничен 1..100;
- запись enrollment уникальна по (course_id, student_id);
- submission уникальна по (assignment_id, student_id);
- grade уникальна по submission_id.

### Use-case (текст)
1. Student Login → Browse Courses → Enroll.
2. Student Open Assignment → Submit Work.
3. Teacher Open Course Submissions → Add Grade + Feedback.
4. Admin Review Grades & User Access.

### Самопроверка этапа 1
- Противоречий по ролям нет: действия разделены по правам.
- Ограничения соответствуют процессам (нет лишних N:M без ключей).
- Риск логической дыры: teacher может выставить оценку по чужому курсу — контролируется backend-правилами доступа (добавлено в тесты доступа).

---

## Этап 2. Проектирование базы данных

### ER-модель (текстом)
Сущности:
- `users(user_id, email, password_hash, full_name, role, created_at)`
- `courses(course_id, title, description, teacher_id, created_at)`
- `enrollments(enrollment_id, course_id, student_id, enrolled_at)`
- `assignments(assignment_id, course_id, title, description, max_score, due_at)`
- `submissions(submission_id, assignment_id, student_id, submitted_at, content)`
- `grades(grade_id, submission_id, teacher_id, score, feedback, graded_at)`

Связи и кратности:
- teacher (users) 1:N courses
- courses 1:N assignments
- students (users) N:M courses через enrollments
- assignments 1:N submissions
- submissions 1:1 grades
- teacher (users) 1:N grades

### Нормализация
- **1НФ**: все атрибуты атомарные, повторяющихся групп нет.
- **2НФ**: все неключевые атрибуты полностью зависят от PK (составные ключи вынесены в уникальные ограничения и surrogate PK).
- **3НФ**: транзитивных зависимостей нет (например, teacher_name не хранится в courses; только teacher_id).

### Ключи и ограничения
- PK: во всех таблицах `BIGSERIAL`.
- FK: ссылки между сущностями через `REFERENCES`.
- UNIQUE: email, (course_id, student_id), (assignment_id, student_id), submission_id в grades.
- CHECK: role, max_score, score.
- NOT NULL: обязательные поля доменной модели.
- Каскад:
  - `courses -> enrollments/assignments` и `assignments -> submissions -> grades` через `ON DELETE CASCADE`.
  - teacher/user удаление в критичных местах — `RESTRICT`.

SQL DDL вынесен в `db/schema.sql`.

### Самопроверка этапа 2
- Проверено, что каскады удаляют только производные данные.
- Проверено, что критичные сущности (`users`, `courses`) не удаляются неконтролируемо.

---

## Этап 3. SQL-тесты (сначала)

- Тесты на корректные вставки, некорректные вставки, целостность, каскады, конкурентность: `db/tests.sql`.
- Проверочные SELECT-запросы (JOIN/aggregate/subquery/group by having): `db/validation_queries.sql`.

### Самопроверка этапа 3
- Схема покрывает сценарий student→submission→grade.
- Ограничения не дают создать неконсистентные данные.

---

## Этап 4. Backend (FastAPI, JWT, роли)

### TDD-порядок
Сначала написаны тесты API и доступа:
- `backend/tests/test_authz_and_flows.py`

Потом реализованы:
- схемы: `backend/app/schemas/models.py`
- безопасность/JWT-like подпись: `backend/app/core/security.py`
- репозиторий: `backend/app/repositories/in_memory.py`
- auth service: `backend/app/services/auth.py`
- API: `backend/app/main.py`, `backend/app/api/deps.py`

### Самопроверка этапа 4
- Тесты проверяют:
  - логин,
  - сдачу студентом,
  - запрет оценивания студентом,
  - разрешение оценивания преподавателем,
  - доступ администратора к списку оценок.

---

## Этап 5. Frontend (минимальный)

API-контракты:
- `POST /auth/login`
- `GET /courses`
- `POST /assignments/{id}/submissions`
- `POST /submissions/{id}/grade`
- `GET /grades`

Реализованы страницы:
- login
- courses
- course/assignments
- grades

(Минимальная реализация — в `frontend/src`).

---

## Этап 6. Финальное тестирование

E2E (на уровне API):
- student: login → courses → submission
- teacher: grade submission
- admin: view grades

Результаты зафиксированы запуском `pytest`.

---

## Этап 7. Docker (последним этапом)

Добавлены:
- `backend/Dockerfile`
- `docker-compose.yml`

Запуск:
1. `docker compose up --build`
2. backend: `http://localhost:8000/docs`
3. frontend: `http://localhost:5173`
