-- Лабораторная работа №3. Процедуры, функции и триггеры
-- БД: Система записи в сервисные центры (продолжение схемы из lab-02)
-- Скрипт создаёт 3 хранимые функции/процедуры и 4 триггера с обработкой ошибок

-- Очистка предыдущих объектов, чтобы скрипт можно было запускать многократно
DROP TRIGGER IF EXISTS trg_validate_appointment ON appointments;
DROP TRIGGER IF EXISTS trg_mark_slot_booked ON appointments;
DROP TRIGGER IF EXISTS trg_release_slot ON appointments;
DROP TRIGGER IF EXISTS trg_touch_ticket ON tickets;

DROP FUNCTION IF EXISTS validate_appointment() CASCADE;
DROP FUNCTION IF EXISTS set_slot_booked() CASCADE;
DROP FUNCTION IF EXISTS free_slot_after_delete() CASCADE;
DROP FUNCTION IF EXISTS touch_ticket_updated_at() CASCADE;
DROP FUNCTION IF EXISTS fn_is_ticket_active(bigint) CASCADE;
DROP FUNCTION IF EXISTS fn_technician_utilization(bigint) CASCADE;
DROP PROCEDURE IF EXISTS book_ticket_with_slot(text, text, text, ticket_priority, bigint);

-- 1) Функция: активен ли тикет (не закрыт/не отменён)
CREATE OR REPLACE FUNCTION fn_is_ticket_active(p_ticket_id BIGINT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
  v_is_active BOOLEAN;
BEGIN
  SELECT status NOT IN ('done', 'cancelled')
  INTO v_is_active
  FROM tickets
  WHERE ticket_id = p_ticket_id;

  IF v_is_active IS NULL THEN
    RAISE EXCEPTION 'Тикет % не найден', p_ticket_id USING ERRCODE = 'RB100';
  END IF;

  RETURN v_is_active;
END;
$$;

-- 2) Функция: загрузка мастера (всего слотов, занято, %)
CREATE OR REPLACE FUNCTION fn_technician_utilization(p_technician_id BIGINT)
RETURNS TABLE(total_slots INT, booked_slots INT, utilization_percent NUMERIC(5,2))
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    COUNT(*)::INT AS total_slots,
    COUNT(*) FILTER (WHERE is_booked)::INT AS booked_slots,
    CASE
      WHEN COUNT(*) = 0 THEN 0
      ELSE ROUND(COUNT(*) FILTER (WHERE is_booked)::NUMERIC * 100 / COUNT(*), 2)
    END AS utilization_percent
  FROM time_slots ts
  WHERE ts.technician_id = p_technician_id;
END;
$$;

-- 3) Процедура: создать тикет и забронировать слот для клиента
--   - проверяет клиента/устройство/слот
--   - создаёт тикет и запись на приём
--   - переводит системные ошибки в бизнес-сообщения
CREATE OR REPLACE PROCEDURE book_ticket_with_slot(
  p_client_email    TEXT,
  p_device_serial   TEXT,
  p_problem         TEXT,
  p_priority        ticket_priority DEFAULT 'normal',
  p_slot_id         BIGINT
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_client_id     BIGINT;
  v_device_id     BIGINT;
  v_ticket_id     BIGINT;
  v_center_id     BIGINT;
  v_technician_id BIGINT;
  v_is_booked     BOOLEAN;
BEGIN
  -- Проверяем клиента
  SELECT user_id
  INTO v_client_id
  FROM users
  WHERE email = p_client_email
    AND role = 'client'
    AND active = TRUE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      MESSAGE = format('Клиент с email % не найден или неактивен', p_client_email),
      ERRCODE = 'RB001';
  END IF;

  -- Проверяем устройство, что оно принадлежит клиенту
  SELECT device_id
  INTO v_device_id
  FROM devices
  WHERE serial_number = p_device_serial
    AND client_id = v_client_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      MESSAGE = format('У клиента нет устройства с серийным номером %', p_device_serial),
      ERRCODE = 'RB002';
  END IF;

  -- Проверяем слот
  SELECT center_id, technician_id, is_booked
  INTO v_center_id, v_technician_id, v_is_booked
  FROM time_slots
  WHERE slot_id = p_slot_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      MESSAGE = format('Слот % не найден', p_slot_id),
      ERRCODE = 'RB003';
  END IF;

  IF v_is_booked THEN
    RAISE EXCEPTION USING
      MESSAGE = format('Слот % уже забронирован', p_slot_id),
      ERRCODE = 'RB004';
  END IF;

  -- Создаём тикет
  INSERT INTO tickets (client_id, device_id, problem_description, priority)
  VALUES (v_client_id, v_device_id, p_problem, p_priority)
  RETURNING ticket_id INTO v_ticket_id;

  -- Бронируем слот
  INSERT INTO appointments (ticket_id, center_id, technician_id, slot_id, status)
  VALUES (v_ticket_id, v_center_id, v_technician_id, p_slot_id, 'booked');

EXCEPTION
  WHEN unique_violation THEN
    RAISE EXCEPTION USING
      MESSAGE = 'Нарушена уникальность при создании записи: ' || SQLERRM,
      ERRCODE = 'RB010',
      HINT = 'Проверьте, что слот не занят и нет дубликатов телефона/email.';
  WHEN foreign_key_violation THEN
    RAISE EXCEPTION USING
      MESSAGE = 'Нарушена ссылочная целостность: ' || SQLERRM,
      ERRCODE = 'RB011',
      HINT = 'Проверьте существование клиента, устройства и слота.';
  WHEN check_violation THEN
    RAISE EXCEPTION USING
      MESSAGE = 'Нарушено ограничение CHECK: ' || SQLERRM,
      ERRCODE = 'RB012';
END;
$$;

-- Триггер: валидация записи на приём (слот, мастер, статус тикета)
CREATE OR REPLACE FUNCTION validate_appointment()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_slot RECORD;
  v_ticket_status ticket_status;
BEGIN
  SELECT slot_id, center_id, technician_id, is_booked
  INTO v_slot
  FROM time_slots
  WHERE slot_id = NEW.slot_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Нельзя создать запись: слот % не существует', NEW.slot_id;
  END IF;

  IF (TG_OP = 'INSERT' OR NEW.slot_id <> OLD.slot_id) AND v_slot.is_booked THEN
    RAISE EXCEPTION 'Слот % уже занят', v_slot.slot_id;
  END IF;

  IF NEW.technician_id IS DISTINCT FROM v_slot.technician_id THEN
    RAISE EXCEPTION 'Слот % относится к другому мастеру', v_slot.slot_id;
  END IF;

  -- Подтягиваем центр из слота, чтобы исключить несовпадения
  NEW.center_id := v_slot.center_id;

  SELECT status
  INTO v_ticket_status
  FROM tickets
  WHERE ticket_id = NEW.ticket_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Тикет % не найден', NEW.ticket_id;
  END IF;

  IF v_ticket_status IN ('done', 'cancelled') THEN
    RAISE EXCEPTION 'Нельзя бронировать закрытый тикет %', NEW.ticket_id;
  END IF;

  RETURN NEW;
END;
$$;

-- Триггер: отмечаем слот занятым после создания записи
CREATE OR REPLACE FUNCTION set_slot_booked()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE time_slots
  SET is_booked = TRUE
  WHERE slot_id = NEW.slot_id;
  RETURN NEW;
END;
$$;

-- Триггер: освобождаем слот после удаления записи
CREATE OR REPLACE FUNCTION free_slot_after_delete()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE time_slots
  SET is_booked = FALSE
  WHERE slot_id = OLD.slot_id;
  RETURN OLD;
END;
$$;

-- Триггер: обновляем last_updated_at при смене статуса/приоритета тикета
CREATE OR REPLACE FUNCTION touch_ticket_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.status IS DISTINCT FROM OLD.status
     OR NEW.priority IS DISTINCT FROM OLD.priority THEN
    NEW.last_updated_at := now();
  END IF;
  RETURN NEW;
END;
$$;

-- Привязка триггеров
CREATE TRIGGER trg_validate_appointment
BEFORE INSERT OR UPDATE ON appointments
FOR EACH ROW EXECUTE FUNCTION validate_appointment();

CREATE TRIGGER trg_mark_slot_booked
AFTER INSERT ON appointments
FOR EACH ROW EXECUTE FUNCTION set_slot_booked();

CREATE TRIGGER trg_release_slot
AFTER DELETE ON appointments
FOR EACH ROW EXECUTE FUNCTION free_slot_after_delete();

CREATE TRIGGER trg_touch_ticket
BEFORE UPDATE ON tickets
FOR EACH ROW EXECUTE FUNCTION touch_ticket_updated_at();
