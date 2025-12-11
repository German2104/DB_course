-- ЛР4. Транзакции и демонстрация аномалий параллельного доступа
-- БД: система записи в сервисные центры (можно запускать после lab-02/seed.sql)
-- Для наглядности используются две сессии psql: T1 и T2.
-- Комментарии показывают, что вводить в каждой сессии; таблица тестовая, не трогает основную схему

-- Подготовка тестовой таблицы (идемпотентно: сначала удаляем)
DROP TABLE IF EXISTS tx_demo;
CREATE TABLE tx_demo (
  id       SERIAL PRIMARY KEY, -- surrogate PK
  note     TEXT,               -- текст заявки
  status   TEXT,               -- статус
  priority INT                 -- приоритет для демонстрации фантомов
);

-- Базовые строки для экспериментов
INSERT INTO tx_demo (note, status, priority) VALUES
  ('Заявка клиента A', 'new', 1),
  ('Заявка клиента B', 'in_progress', 2),
  ('Заявка клиента C', 'waiting', 3);

-- =========================================
-- 1) Dirty read (в PostgreSQL не проявляется, даже в READ UNCOMMITTED)
-- =========================================
-- Session T1
-- BEGIN;
-- UPDATE tx_demo SET status = 'processing' WHERE id = 1;
--
-- Session T2 (пытаемся прочитать «грязное» значение)
-- BEGIN;
-- SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
-- SELECT id, status FROM tx_demo WHERE id = 1;
-- -- Получим исходное значение 'new': PostgreSQL не даёт dirty read.
-- COMMIT;
--
-- Session T1
-- ROLLBACK;  -- откатываем незакоммиченные изменения

-- =========================================
-- 2) Non-repeatable read (READ COMMITTED → разные значения в одной транзакции)
-- =========================================
-- Возвращаем исходное состояние строки
UPDATE tx_demo SET status = 'new' WHERE id = 1;

-- Session T1
-- BEGIN;
-- SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- SELECT status FROM tx_demo WHERE id = 1;  -- статус: new
--
-- Session T2 (параллельно)
-- BEGIN;
-- UPDATE tx_demo SET status = 'done' WHERE id = 1;
-- COMMIT;
--
-- Session T1 (повторяем чтение в той же транзакции)
-- SELECT status FROM tx_demo WHERE id = 1;  -- статус: done (non-repeatable read)
-- COMMIT;
--
-- Как избежать: использовать REPEATABLE READ
-- Session T1 (повтор)
-- BEGIN;
-- SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
-- SELECT status FROM tx_demo WHERE id = 1;  -- статус: done
--
-- Session T2
-- BEGIN;
-- UPDATE tx_demo SET status = 'in_progress' WHERE id = 1;
-- COMMIT;  -- запись изменится, но T1 увидит старый снимок
--
-- Session T1 (тот же снимок)
-- SELECT status FROM tx_demo WHERE id = 1;  -- всё ещё done
-- COMMIT;

-- =========================================
-- 3) Phantom read (новые строки попадают в выборку той же транзакции)
-- =========================================
-- Session T1
-- BEGIN;
-- SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- SELECT COUNT(*) FROM tx_demo WHERE priority >= 2;  -- допустим, получили 2
--
-- Session T2
-- BEGIN;
-- INSERT INTO tx_demo (note, status, priority) VALUES ('Новый тикет с высоким приоритетом', 'new', 3);
-- COMMIT;
--
-- Session T1 (повторяем тот же запрос в рамках транзакции)
-- SELECT COUNT(*) FROM tx_demo WHERE priority >= 2;  -- теперь 3 (phantom read)
-- COMMIT;
--
-- Как избежать: SERIALIZABLE (или REPEATABLE READ с предикатными блокировками)
-- Session T1
-- BEGIN;
-- SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
-- SELECT COUNT(*) FROM tx_demo WHERE priority >= 2;  -- фиксируем снимок
--
-- Session T2
-- BEGIN;
-- INSERT INTO tx_demo (note, status, priority) VALUES ('Фантомная вставка', 'new', 4);
-- COMMIT;  -- возможен serialization failure, если T1 уже читает тот же диапазон
--
-- Session T1
-- SELECT COUNT(*) FROM tx_demo WHERE priority >= 2;  -- остаётся прежнее значение
-- COMMIT;

-- Очистка (по желанию, чтобы не мешать основной схеме)
-- DROP TABLE tx_demo;
