-- Осмысленные DML-операции (INSERT / UPDATE / DELETE)
-- Предполагается, что schema.sql и seed.sql уже выполнены; CTE помогают читать сценарий

-- 1) Добавляем новый тикет и бронируем ближайший свободный слот
BEGIN;
WITH client_device AS (
  -- берём последнее купленное устройство клиента
  SELECT d.device_id, d.client_id
  FROM devices d
  JOIN users u ON u.user_id = d.client_id
  WHERE u.email = 'carol.diaz@example.com'
  ORDER BY d.purchase_date DESC
  LIMIT 1
), new_ticket AS (
  -- вставляем тикет по выбранному устройству, запоминаем ID
  INSERT INTO tickets (client_id, device_id, problem_description, priority)
  SELECT client_id, device_id, 'Трещины на корпусе, требуется замена', 'high'
  FROM client_device
  RETURNING ticket_id, client_id, device_id
), free_slot AS (
  -- находим самый ранний свободный слот
  SELECT slot_id, technician_id, center_id
  FROM time_slots
  WHERE is_booked = FALSE
  ORDER BY starts_at
  LIMIT 1
), booked AS (
  -- создаём запись на приём, привязывая тикет к найденному слоту
  INSERT INTO appointments (ticket_id, center_id, technician_id, slot_id)
  SELECT nt.ticket_id, fs.center_id, fs.technician_id, fs.slot_id
  FROM new_ticket nt CROSS JOIN free_slot fs
  RETURNING appointment_id, slot_id
)
-- помечаем слот занятым
UPDATE time_slots ts
SET is_booked = TRUE
WHERE ts.slot_id IN (SELECT slot_id FROM booked);
COMMIT;

-- 2) Обновляем статусы: отмечаем завершение приёма и заявки
UPDATE appointments
SET status = 'completed'
WHERE appointment_id = (
  -- берём последнюю запись по тикету в работе
  SELECT appointment_id FROM appointments a
  JOIN tickets t ON t.ticket_id = a.ticket_id
  WHERE t.status = 'in_progress'
  ORDER BY a.created_at DESC
  LIMIT 1
);

UPDATE tickets
SET status = 'done', last_updated_at = now()
WHERE ticket_id IN (
  -- для всех завершённых приёмов закрываем тикет
  SELECT a.ticket_id
  FROM appointments a
  WHERE a.status = 'completed'
);

-- 3) Удаляем отменённые записи и освобождаем слоты
WITH cancelled AS (
  -- удаляем отменённые записи, запоминаем слоты
  DELETE FROM appointments
  WHERE status = 'cancelled'
  RETURNING slot_id
)
-- освобождаем слоты, чтобы их можно было снова бронировать
UPDATE time_slots ts
SET is_booked = FALSE
WHERE ts.slot_id IN (SELECT slot_id FROM cancelled);
