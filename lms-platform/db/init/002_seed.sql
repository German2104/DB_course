INSERT INTO roles (name) VALUES
('student'),
('teacher'),
('admin')
ON CONFLICT (name) DO NOTHING;

WITH role_map AS (
    SELECT id, name FROM roles
),
user_seed(email, password_hash, full_name, role_name) AS (
    VALUES
    ('admin@lms.local', '$2b$12$seed_hash_admin_01', 'Системный администратор', 'admin'),
    ('ops.admin@lms.local', '$2b$12$seed_hash_admin_02', 'Администратор платформы', 'admin'),
    ('ivan.petrov.teacher@lms.local', '$2b$12$seed_hash_t_01', 'Иван Петров', 'teacher'),
    ('aleksei.smirnov.teacher@lms.local', '$2b$12$seed_hash_t_02', 'Алексей Смирнов', 'teacher'),
    ('maria.ivanova.teacher@lms.local', '$2b$12$seed_hash_t_03', 'Мария Иванова', 'teacher'),
    ('dmitrii.volkov.teacher@lms.local', '$2b$12$seed_hash_t_04', 'Дмитрий Волков', 'teacher'),
    ('nikita.kuznetsov.student@lms.local', '$2b$12$seed_hash_s_01', 'Никита Кузнецов', 'student'),
    ('olga.sokolova.student@lms.local', '$2b$12$seed_hash_s_02', 'Ольга Соколова', 'student'),
    ('egor.pavlov.student@lms.local', '$2b$12$seed_hash_s_03', 'Егор Павлов', 'student'),
    ('anna.lebedeva.student@lms.local', '$2b$12$seed_hash_s_04', 'Анна Лебедева', 'student'),
    ('maksim.novikov.student@lms.local', '$2b$12$seed_hash_s_05', 'Максим Новиков', 'student'),
    ('elena.kozlova.student@lms.local', '$2b$12$seed_hash_s_06', 'Елена Козлова', 'student'),
    ('sofia.orlova.student@lms.local', '$2b$12$seed_hash_s_07', 'София Орлова', 'student'),
    ('roman.fedorov.student@lms.local', '$2b$12$seed_hash_s_08', 'Роман Федоров', 'student'),
    ('polina.morozova.student@lms.local', '$2b$12$seed_hash_s_09', 'Полина Морозова', 'student'),
    ('arsenii.volkov.student@lms.local', '$2b$12$seed_hash_s_10', 'Арсений Волков', 'student'),
    ('irina.belova.student@lms.local', '$2b$12$seed_hash_s_11', 'Ирина Белова', 'student'),
    ('vladislav.zaitsev.student@lms.local', '$2b$12$seed_hash_s_12', 'Владислав Зайцев', 'student')
)
INSERT INTO users (email, password_hash, full_name, role_id)
SELECT us.email, us.password_hash, us.full_name, rm.id
FROM user_seed us
JOIN role_map rm ON rm.name = us.role_name
ON CONFLICT (email) DO NOTHING;

WITH course_seed(title, description, teacher_email, is_published) AS (
    VALUES
    ('PostgreSQL для LMS', 'Проектирование надежных реляционных моделей для образовательной платформы', 'ivan.petrov.teacher@lms.local', TRUE),
    ('Основы FastAPI', 'Асинхронная разработка backend API на Python', 'aleksei.smirnov.teacher@lms.local', TRUE),
    ('Инженерия данных: базовый курс', 'Пайплайны, хранилища данных и ETL-процессы', 'maria.ivanova.teacher@lms.local', TRUE),
    ('ML для продуктовых команд', 'От постановки задачи до мониторинга модели в продакшене', 'dmitrii.volkov.teacher@lms.local', FALSE),
    ('Системный дизайн backend', 'Масштабируемая архитектура и ключевые компромиссы', 'aleksei.smirnov.teacher@lms.local', TRUE),
    ('SQL-аналитика', 'Практический SQL для отчетности и продуктовой аналитики', 'maria.ivanova.teacher@lms.local', TRUE)
)
INSERT INTO courses (title, description, teacher_id, is_published)
SELECT cs.title, cs.description, u.id, cs.is_published
FROM course_seed cs
JOIN users u ON u.email = cs.teacher_email
WHERE NOT EXISTS (
    SELECT 1
    FROM courses c
    WHERE c.title = cs.title
      AND c.teacher_id = u.id
      AND c.deleted_at IS NULL
);

WITH lesson_seed(course_title, position, title, content) AS (
    VALUES
    ('PostgreSQL для LMS', 1, 'ER-моделирование для LMS', 'Пользователи, курсы, записи и нормализация данных'),
    ('PostgreSQL для LMS', 2, 'Ограничения и индексы', 'Ключи, проверки и базовая оптимизация запросов'),
    ('PostgreSQL для LMS', 3, 'Транзакции', 'Уровни изоляции и согласованность данных в учебных процессах'),
    ('PostgreSQL для LMS', 4, 'Миграции схемы', 'Версионирование и безопасное развитие структуры БД'),
    ('Основы FastAPI', 1, 'Старт проекта', 'Окружение, структура приложения и зависимости'),
    ('Основы FastAPI', 2, 'Роутинг и валидация', 'Pydantic-схемы и API-контракты'),
    ('Основы FastAPI', 3, 'Авторизация и права', 'JWT-подход и ролевая модель доступа'),
    ('Основы FastAPI', 4, 'OpenAPI и документация', 'Swagger и поддержка API-документации'),
    ('Инженерия данных: базовый курс', 1, 'Паттерны хранения', 'OLTP и OLAP, границы и сценарии использования'),
    ('Инженерия данных: базовый курс', 2, 'ETL-пайплайны', 'Пакетная загрузка и преобразование данных'),
    ('Инженерия данных: базовый курс', 3, 'Качество данных', 'Проверки целостности и обработка инцидентов'),
    ('ML для продуктовых команд', 1, 'Формулировка задачи', 'Целевые метрики, ограничения и гипотезы'),
    ('ML для продуктовых команд', 2, 'Фиче-пайплайн', 'Feature store и согласованность online/offline данных'),
    ('ML для продуктовых команд', 3, 'Оценка модели', 'Метрики, срезы и контроль деградации качества'),
    ('Системный дизайн backend', 1, 'Планирование нагрузки', 'Оценка трафика и поиск узких мест'),
    ('Системный дизайн backend', 2, 'Стратегии кэширования', 'Шаблоны чтения/записи и инвалидация кэша'),
    ('Системный дизайн backend', 3, 'Надежность системы', 'Retry, идемпотентность и circuit breaker'),
    ('SQL-аналитика', 1, 'Аналитические функции', 'Оконные функции и расчет retention-метрик'),
    ('SQL-аналитика', 2, 'Воронки и когорты', 'Запросы для анализа пользовательского поведения'),
    ('SQL-аналитика', 3, 'Датасеты для BI', 'Агрегации для дашбордов и витрин данных')
)
INSERT INTO lessons (course_id, title, content, position)
SELECT c.id, ls.title, ls.content, ls.position
FROM lesson_seed ls
JOIN courses c ON c.title = ls.course_title
WHERE c.deleted_at IS NULL
ON CONFLICT (course_id, position) DO NOTHING;

WITH assignment_seed(course_title, lesson_position, title, description, max_score, due_in_days) AS (
    VALUES
    ('PostgreSQL для LMS', 1, 'Спроектировать ядро схемы', 'Создать таблицы пользователей, курсов и записей на курс', 100, 5),
    ('PostgreSQL для LMS', 2, 'Оптимизация запросов', 'Добавить индексы и проанализировать EXPLAIN-планы', 100, 9),
    ('Основы FastAPI', 2, 'CRUD-ручки', 'Реализовать валидированный CRUD для курсов', 100, 6),
    ('Основы FastAPI', 3, 'Сценарий JWT', 'Собрать регистрацию, логин и RBAC-модель доступа', 100, 10),
    ('Инженерия данных: базовый курс', 2, 'Прототип ETL', 'Загрузить CSV и заполнить нормализованную схему', 100, 7),
    ('Инженерия данных: базовый курс', 3, 'Проверки качества данных', 'Добавить DQ-правила и итоговый отчет', 100, 12),
    ('ML для продуктовых команд', 2, 'Фиче-таблица', 'Подготовить переиспользуемый датасет признаков', 100, 14),
    ('Системный дизайн backend', 1, 'Архитектурный документ', 'Описать high-level дизайн и компромиссы', 100, 8),
    ('Системный дизайн backend', 3, 'Сценарии отказа', 'Задокументировать паттерны надежности и ограничения', 100, 13),
    ('SQL-аналитика', 1, 'Оконные метрики', 'Рассчитать ключевые growth и retention-метрики', 100, 7),
    ('SQL-аналитика', 2, 'Воронка конверсии', 'Построить SQL-запрос воронки с этапами', 100, 11)
)
INSERT INTO assignments (lesson_id, title, description, max_score, due_date)
SELECT l.id, a.title, a.description, a.max_score, NOW() + make_interval(days => a.due_in_days)
FROM assignment_seed a
JOIN courses c ON c.title = a.course_title
JOIN lessons l ON l.course_id = c.id AND l.position = a.lesson_position
WHERE c.deleted_at IS NULL
  AND l.deleted_at IS NULL
  AND NOT EXISTS (
      SELECT 1
      FROM assignments ax
      WHERE ax.lesson_id = l.id
        AND ax.title = a.title
        AND ax.deleted_at IS NULL
  );

WITH enrollment_seed(student_email, course_title) AS (
    VALUES
    ('nikita.kuznetsov.student@lms.local', 'PostgreSQL для LMS'),
    ('nikita.kuznetsov.student@lms.local', 'Основы FastAPI'),
    ('olga.sokolova.student@lms.local', 'PostgreSQL для LMS'),
    ('olga.sokolova.student@lms.local', 'SQL-аналитика'),
    ('egor.pavlov.student@lms.local', 'Основы FastAPI'),
    ('egor.pavlov.student@lms.local', 'Системный дизайн backend'),
    ('anna.lebedeva.student@lms.local', 'Инженерия данных: базовый курс'),
    ('anna.lebedeva.student@lms.local', 'PostgreSQL для LMS'),
    ('maksim.novikov.student@lms.local', 'Инженерия данных: базовый курс'),
    ('maksim.novikov.student@lms.local', 'SQL-аналитика'),
    ('elena.kozlova.student@lms.local', 'ML для продуктовых команд'),
    ('elena.kozlova.student@lms.local', 'Системный дизайн backend'),
    ('sofia.orlova.student@lms.local', 'Основы FastAPI'),
    ('sofia.orlova.student@lms.local', 'SQL-аналитика'),
    ('roman.fedorov.student@lms.local', 'Системный дизайн backend'),
    ('roman.fedorov.student@lms.local', 'PostgreSQL для LMS'),
    ('polina.morozova.student@lms.local', 'Инженерия данных: базовый курс'),
    ('polina.morozova.student@lms.local', 'ML для продуктовых команд'),
    ('arsenii.volkov.student@lms.local', 'PostgreSQL для LMS'),
    ('arsenii.volkov.student@lms.local', 'SQL-аналитика'),
    ('irina.belova.student@lms.local', 'Основы FastAPI'),
    ('irina.belova.student@lms.local', 'Инженерия данных: базовый курс'),
    ('vladislav.zaitsev.student@lms.local', 'Системный дизайн backend'),
    ('vladislav.zaitsev.student@lms.local', 'PostgreSQL для LMS')
)
INSERT INTO enrollments (user_id, course_id)
SELECT u.id, c.id
FROM enrollment_seed es
JOIN users u ON u.email = es.student_email
JOIN courses c ON c.title = es.course_title
WHERE u.deleted_at IS NULL
  AND c.deleted_at IS NULL
ON CONFLICT (user_id, course_id) DO NOTHING;

INSERT INTO progress (user_id, lesson_id, completed)
SELECT
    e.user_id,
    l.id,
    mod(abs(hashtext(e.user_id::text || ':' || l.id::text)), 100) < 68 AS completed
FROM enrollments e
JOIN lessons l ON l.course_id = e.course_id
WHERE e.deleted_at IS NULL
  AND l.deleted_at IS NULL
ON CONFLICT (user_id, lesson_id) DO NOTHING;

INSERT INTO submissions (assignment_id, student_id, content)
SELECT
    a.id,
    e.user_id,
    format(
        'Ответ по заданию "%s" от студента %s в %s',
        a.title,
        e.user_id::text,
        to_char(NOW(), 'YYYY-MM-DD HH24:MI')
    )
FROM assignments a
JOIN lessons l ON l.id = a.lesson_id
JOIN enrollments e ON e.course_id = l.course_id
WHERE a.deleted_at IS NULL
  AND l.deleted_at IS NULL
  AND e.deleted_at IS NULL
  AND mod(abs(hashtext(e.user_id::text || ':' || a.id::text)), 100) < 74
ON CONFLICT (assignment_id, student_id) DO NOTHING;

INSERT INTO grades (submission_id, score, feedback, graded_by)
SELECT
    s.id,
    (60 + mod(abs(hashtext(s.id::text)), 41))::INT AS score,
    CASE
        WHEN mod(abs(hashtext(s.id::text)), 10) < 3 THEN 'Хорошая работа. Стоит доработать обработку крайних случаев.'
        WHEN mod(abs(hashtext(s.id::text)), 10) < 7 THEN 'Сильный результат. Рекомендуются небольшие улучшения.'
        ELSE 'Отличная структура и качество выполнения.'
    END AS feedback,
    c.teacher_id
FROM submissions s
JOIN assignments a ON a.id = s.assignment_id
JOIN lessons l ON l.id = a.lesson_id
JOIN courses c ON c.id = l.course_id
WHERE s.deleted_at IS NULL
  AND a.deleted_at IS NULL
  AND l.deleted_at IS NULL
  AND c.deleted_at IS NULL
  AND mod(abs(hashtext(s.id::text || ':graded')), 100) < 86
ON CONFLICT (submission_id) DO NOTHING;
