# API Usage Guide

Короткий практический гайд: какие ручки есть, за что отвечают и в каком порядке их вызывать.

## База URL

- `http://localhost:8000`
- Swagger: `http://localhost:8000/docs`

## Общая логика работы

1. Проверить, что API живо: `GET /health`
2. Залогиниться: `POST /auth/login`
3. Взять `token` из ответа (это UUID пользователя)
4. Токен автоматически сохранится в cookie `auth_token`
5. После этого защищенные ручки работают без ручной передачи токена
6. Если нужно, можно явно передать `X-User-Id: <token>`
7. Проверить текущего пользователя: `GET /auth/me`
8. Работать с доменными ручками (`/courses`, `/assignments`, `/submissions`, `/grades`)

## Авторизация (demo)

### `GET /auth/demo-accounts`
- Назначение: получить готовые email для проверки ролей.
- Ответ:

```json
{
  "teacher_email": "ivan.petrov.teacher@lms.local",
  "student_email": "nikita.kuznetsov.student@lms.local"
}
```

### `POST /auth/login`
- Назначение: получить demo-токен по email.
- Тело:

```json
{
  "email": "nikita.kuznetsov.student@lms.local"
}
```

- Ответ:

```json
{
  "token": "uuid",
  "user_id": "uuid",
  "role": "student",
  "full_name": "Никита Кузнецов",
  "email": "nikita.kuznetsov.student@lms.local"
}
```

- Дополнительно:
  - сервер ставит cookie `auth_token`, поэтому в Swagger/браузере токен начнет подставляться автоматически.

### `POST /auth/logout`
- Назначение: удалить `auth_token` cookie.
- После этого защищенные ручки снова будут отдавать `401`.

### `GET /auth/me`
- Назначение: вернуть текущего пользователя.
- Авторизация берется из cookie `auth_token` или из заголовка `X-User-Id`.

## Пользователи

### `GET /users`
- Назначение: список пользователей.
- Query-параметры:
  - `limit` (по умолчанию `50`)
  - `offset` (по умолчанию `0`)

### `GET /users/{user_id}`
- Назначение: получить пользователя по UUID.
- Возвращает `404`, если не найден.

## Курсы

### `GET /courses`
- Назначение: список курсов.
- Query-параметры:
  - `published_only` (`true/false`)
  - `teacher_id` (UUID)
  - `limit`, `offset`

### `GET /courses/my`
- Назначение:
  - `student` видит только свои курсы (через enrollments)
  - `teacher` видит свои созданные курсы
  - `admin` видит все курсы
- Требует `X-User-Id`

### `POST /courses`
- Назначение: создать курс.
- Доступ: только `teacher` и `admin`.
- Для `teacher`:
  - может создавать курс только на себя.
- Тело:

```json
{
  "title": "New Course",
  "description": "Short description",
  "is_published": false
}
```

### `PATCH /courses/{course_id}`
- Назначение: обновить курс.
- Доступ: только `teacher` и `admin`.
- Для `teacher`:
  - может обновлять только свои курсы.
- Тело (любые поля из списка):

```json
{
  "title": "Updated title",
  "description": "Updated description",
  "is_published": true
}
```

### `POST /courses/{course_id}/publish`
- Назначение: опубликовать курс (`is_published=true`).
- Доступ: только `teacher` и `admin`.
- Для `teacher`: только свой курс.

## Задания и решения

### `GET /assignments`
- Назначение: список заданий.
- Query-параметры:
  - `course_id` (UUID, опционально)
  - `limit`, `offset`

### `GET /assignments/my`
- Назначение: задания только по курсам текущего студента.
- Доступ: только `student`.
- Используй для выбора корректного `assignment_id` перед `POST /submissions`.

### `POST /submissions`
- Назначение: студент отправляет решение по заданию.
- Доступ: только `student`.
- Ограничение:
  - студент может отправить только по заданию курса, на который он записан
  - повторная отправка на то же задание обновляет предыдущее решение
- Тело:

```json
{
  "assignment_id": "uuid",
  "content": "My solution text"
}
```

## Оценки

### `GET /grades`
- Назначение:
  - `teacher` видит оценки только по своим курсам
  - `admin` видит оценки по всем курсам
- Query-параметры:
  - `course_id` (UUID, опционально)
  - `limit`, `offset`

## Записи на курсы (enrollments)

### `GET /enrollments`
- Назначение: список записей пользователей на курсы.
- Query-параметры:
  - `user_id` (UUID)
  - `course_id` (UUID)
  - `limit`, `offset`
- Ограничение:
  - `student` может видеть только свои enrollments.

## Роли и права (RBAC)

- `student`
  - может логиниться, смотреть `me`
  - может читать курсы и смотреть только `GET /courses/my`
  - может отправлять решения через `POST /submissions`
  - в `enrollments` видит только свои записи
- `teacher`
  - все как у `student`
  - может создавать/обновлять/публиковать свои курсы
  - может смотреть оценки по своим курсам (`GET /grades`)
- `admin`
  - может создавать/обновлять/публиковать любые курсы
  - может смотреть все оценки

## Рекомендуемый порядок проверки (для демо преподавателю)

1. `GET /health`
2. `POST /auth/login` (например, студентом)
3. `GET /auth/me` (без ручного заголовка, токен уже в cookie)
4. `GET /courses/my` (показать мои курсы студента)
5. `GET /assignments/my`
6. `POST /submissions` (успех для student)
7. `POST /auth/login` под teacher
8. `GET /grades` (оценки своих курсов)
9. `POST /courses` и `POST /courses/{id}/publish`

## Готовые примеры curl

### 1) Login

```bash
curl -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"nikita.kuznetsov.student@lms.local"}'
```

### 2) Me

```bash
# Вариант A: через cookie jar (авто)
curl -c cookies.txt -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"nikita.kuznetsov.student@lms.local"}'
curl -b cookies.txt http://localhost:8000/auth/me

# Вариант B: вручную через заголовок
curl http://localhost:8000/auth/me -H "X-User-Id: <TOKEN_UUID>"
```

### 3) Courses list

```bash
curl "http://localhost:8000/courses?published_only=true&limit=10&offset=0"
```

### 4) My courses (student/teacher/admin)

```bash
curl "http://localhost:8000/courses/my?limit=10" \
  -H "X-User-Id: <TOKEN_UUID>"
```

### 5) Create course (teacher/admin)

```bash
curl -X POST http://localhost:8000/courses \
  -H "Content-Type: application/json" \
  -H "X-User-Id: <TOKEN_UUID>" \
  -d '{"title":"Intro to DB","description":"demo","is_published":false}'
```

### 6) Submit solution (student)

```bash
# Сначала получи assignment_id:
curl "http://localhost:8000/assignments/my?limit=10" \
  -H "X-User-Id: <TOKEN_UUID>"

# Потом отправь решение:
curl -X POST http://localhost:8000/submissions \
  -H "Content-Type: application/json" \
  -H "X-User-Id: <TOKEN_UUID>" \
  -d '{"assignment_id":"<ASSIGNMENT_UUID>","content":"my answer"}'
```

### 7) Grades for teacher

```bash
curl "http://localhost:8000/grades?limit=20" \
  -H "X-User-Id: <TOKEN_UUID>"
```

### 8) Enrollments list (student sees only own)

```bash
curl "http://localhost:8000/enrollments?limit=20" \
  -H "X-User-Id: <TOKEN_UUID>"
```
