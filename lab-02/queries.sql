-- Подборка примеров SELECT с агрегацией и соединениями
-- Скрипт только читает данные; порядок выполнения произвольный

-- 1) Нагрузка по центрам: количество тикетов по статусам + вес по приоритетам
SELECT sc.name AS center,
       t.status,
       COUNT(*) AS tickets_count,
       SUM(CASE t.priority WHEN 'high' THEN 3 WHEN 'normal' THEN 2 ELSE 1 END) AS workload_points
FROM tickets t
JOIN appointments a ON a.ticket_id = t.ticket_id
JOIN service_centers sc ON sc.center_id = a.center_id
GROUP BY sc.name, t.status
ORDER BY sc.name, t.status;

-- 2) Среднее число занятых слотов мастеров за день и доля завершённых приёмов
SELECT tech.technician_id,
       u.full_name AS technician,
       DATE(ts.starts_at) AS work_date,
       COUNT(a.appointment_id) AS booked_slots,
       AVG(CASE WHEN a.status = 'completed' THEN 1 ELSE 0 END)::NUMERIC AS completion_ratio
FROM technicians tech
JOIN users u ON u.user_id = tech.user_id
LEFT JOIN time_slots ts ON ts.technician_id = tech.technician_id
LEFT JOIN appointments a ON a.slot_id = ts.slot_id
GROUP BY tech.technician_id, u.full_name, DATE(ts.starts_at)
ORDER BY work_date, technician;

-- 3) Популярные модели устройств по числу тикетов
SELECT dm.brand, dm.model, COUNT(t.ticket_id) AS tickets
FROM tickets t
JOIN devices d ON d.device_id = t.device_id
JOIN device_models dm ON dm.device_model_id = d.device_model_id
GROUP BY dm.brand, dm.model
HAVING COUNT(t.ticket_id) >= 1
ORDER BY tickets DESC, dm.brand;

-- 4) Клиенты с несколькими активными обращениями (new/in_progress/waiting_parts)
SELECT u.full_name,
       COUNT(*) AS open_tickets,
       MIN(t.created_at) AS first_opened_at,
       MAX(t.last_updated_at) AS last_touch
FROM tickets t
JOIN users u ON u.user_id = t.client_id
WHERE t.status IN ('new', 'in_progress', 'waiting_parts')
GROUP BY u.full_name
HAVING COUNT(*) > 1
ORDER BY open_tickets DESC;

-- 5) Расписание приёмов с детализацией клиента и устройства (JOIN без агрегации)
SELECT a.appointment_id,
       sc.name AS center,
       u.full_name AS technician,
       ts.starts_at,
       ts.ends_at,
       c.full_name AS client,
       dm.brand || ' ' || dm.model AS device,
       t.status AS ticket_status,
       a.status AS appointment_status
FROM appointments a
JOIN time_slots ts ON ts.slot_id = a.slot_id
JOIN service_centers sc ON sc.center_id = a.center_id
JOIN technicians tech ON tech.technician_id = a.technician_id
JOIN users u ON u.user_id = tech.user_id
JOIN tickets t ON t.ticket_id = a.ticket_id
JOIN users c ON c.user_id = t.client_id
JOIN devices d ON d.device_id = t.device_id
JOIN device_models dm ON dm.device_model_id = d.device_model_id
ORDER BY ts.starts_at;
