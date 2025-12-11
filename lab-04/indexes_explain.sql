-- ЛР4. Индексы и анализ планов выполнения с EXPLAIN
-- БД: система записи в сервисные центры (схема и данные из lab-02)
-- Скрипт показывает: создание индексов, планы до/после и влияние на время выполнения, каждое действие подписано
-- Запуск: psql -f lab-04/indexes_explain.sql

\timing on

-- Очистка, чтобы скрипт был идемпотентным (удаляем индексы, если существовали)
DROP INDEX IF EXISTS idx_time_slots_free_by_center_start;
DROP INDEX IF EXISTS idx_users_role_full_name_lower;
DROP INDEX IF EXISTS idx_tickets_problem_description_trgm;

-- Расширение для ускорения поисков по подстроке (LIKE/ILIKE)
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- ================================
-- 1) Поиск свободных слотов по центру и диапазону дат
--    Ожидаем: до индекса — Seq Scan по time_slots; после — Bitmap/Index Scan по partial index.
-- ================================
-- План до индекса: фильтр по центру/занятости/диапазону + сортировка
EXPLAIN ANALYZE
SELECT ts.slot_id,
       ts.starts_at,
       u.full_name AS technician,
       ts.is_booked
FROM time_slots ts
JOIN technicians t ON t.technician_id = ts.technician_id
JOIN users u ON u.user_id = t.user_id
WHERE ts.center_id = (SELECT center_id FROM service_centers WHERE name = 'TechFix Downtown')
  AND ts.is_booked = FALSE
  AND ts.starts_at BETWEEN '2024-04-01 00:00+03' AND '2024-04-07 23:59+03'
ORDER BY ts.starts_at;

-- Индекс для типового поиска свободных слотов по центру и дате (partial index на свободные слоты)
CREATE INDEX idx_time_slots_free_by_center_start
  ON time_slots (center_id, starts_at)
  WHERE is_booked = FALSE;

-- Повторный план: ожидаем Index/Bitmap Index Scan вместо Seq Scan
EXPLAIN ANALYZE
SELECT ts.slot_id,
       ts.starts_at,
       u.full_name AS technician,
       ts.is_booked
FROM time_slots ts
JOIN technicians t ON t.technician_id = ts.technician_id
JOIN users u ON u.user_id = t.user_id
WHERE ts.center_id = (SELECT center_id FROM service_centers WHERE name = 'TechFix Downtown')
  AND ts.is_booked = FALSE
  AND ts.starts_at BETWEEN '2024-04-01 00:00+03' AND '2024-04-07 23:59+03'
ORDER BY ts.starts_at;

-- ================================
-- 2) Фильтрация и сортировка по текстовым полям (поиск мастеров по началу имени)
--    Ожидаем: до индекса — Seq Scan + сортировка; после — Index Scan с готовым order.
-- ================================
-- План до индекса: Seq Scan по users с фильтром role + lower(full_name) и отдельной сортировкой
EXPLAIN ANALYZE
SELECT user_id, full_name, email
FROM users
WHERE role = 'technician'
  AND lower(full_name) LIKE 'd%'
ORDER BY full_name;

-- Выражение lower(full_name) + роль для case-insensitive поиска и сортировки
CREATE INDEX idx_users_role_full_name_lower
  ON users (role, lower(full_name));

-- План после индекса: должен использовать Index Scan без дополнительной сортировки
EXPLAIN ANALYZE
SELECT user_id, full_name, email
FROM users
WHERE role = 'technician'
  AND lower(full_name) LIKE 'd%'
ORDER BY full_name;

-- ================================
-- 3) Поиск по подстроке в описании проблемы + агрегация по центрам
--    Ожидаем: до индекса — Seq Scan по tickets; после — Bitmap Index Scan по GIN + быстрый фильтр.
-- ================================
-- План до индекса: ILIKE по problem_description заставляет Seq Scan
EXPLAIN ANALYZE
SELECT sc.name AS center,
       t.priority,
       COUNT(*) AS tickets_count
FROM tickets t
JOIN appointments a ON a.ticket_id = t.ticket_id
JOIN service_centers sc ON sc.center_id = a.center_id
WHERE t.problem_description ILIKE '%звук%'   -- поиск по подстроке (рус/англ)
GROUP BY sc.name, t.priority
ORDER BY tickets_count DESC;

-- GIN + trigram для LIKE/ILIKE по описанию проблемы
CREATE INDEX idx_tickets_problem_description_trgm
  ON tickets
  USING gin (problem_description gin_trgm_ops);

-- План после индекса: ожидаем Bitmap Index Scan по GIN и ускоренное выполнение
EXPLAIN ANALYZE
SELECT sc.name AS center,
       t.priority,
       COUNT(*) AS tickets_count
FROM tickets t
JOIN appointments a ON a.ticket_id = t.ticket_id
JOIN service_centers sc ON sc.center_id = a.center_id
WHERE t.problem_description ILIKE '%звук%'
GROUP BY sc.name, t.priority
ORDER BY tickets_count DESC;

-- После выполнения можно проверить реальные изменения плана (Index Scan, Bitmap Index Scan, Hash/Seq Scan)
-- и сравнить время выполнения (timing включен).
