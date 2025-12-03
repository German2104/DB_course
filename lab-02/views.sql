-- Представления для аналитики

-- Итоги по центрам: слоты, тикеты, завершения
CREATE OR REPLACE VIEW vw_center_summary AS
SELECT sc.center_id,
       sc.name AS center,
       COUNT(DISTINCT ts.slot_id) AS total_slots,
       COUNT(DISTINCT ts.slot_id) FILTER (WHERE ts.is_booked) AS booked_slots,
       COUNT(DISTINCT a.appointment_id) FILTER (WHERE a.status = 'completed') AS completed_appointments,
       COUNT(DISTINCT t.ticket_id) FILTER (WHERE t.status IN ('new', 'in_progress', 'waiting_parts')) AS open_tickets
FROM service_centers sc
LEFT JOIN time_slots ts ON ts.center_id = sc.center_id
LEFT JOIN appointments a ON a.slot_id = ts.slot_id
LEFT JOIN tickets t ON t.ticket_id = a.ticket_id
GROUP BY sc.center_id, sc.name;

-- Сводка по клиентам: количество обращений и «вес» по приоритету
CREATE OR REPLACE VIEW vw_client_ticket_summary AS
SELECT u.user_id,
       u.full_name,
       COUNT(t.ticket_id) AS total_tickets,
       SUM(CASE t.priority WHEN 'high' THEN 3 WHEN 'normal' THEN 2 ELSE 1 END) AS priority_points,
       COUNT(*) FILTER (WHERE t.status = 'done') AS closed_tickets,
       COUNT(*) FILTER (WHERE t.status IN ('new', 'in_progress', 'waiting_parts')) AS open_tickets,
       MAX(t.last_updated_at) AS last_touch
FROM users u
LEFT JOIN tickets t ON t.client_id = u.user_id
WHERE u.role = 'client'
GROUP BY u.user_id, u.full_name;

-- Расписание мастеров с детализацией по клиенту и статусу
CREATE OR REPLACE VIEW vw_technician_schedule AS
SELECT tech.technician_id,
       u.full_name AS technician,
       sc.name AS center,
       DATE(ts.starts_at) AS work_date,
       ts.starts_at,
       ts.ends_at,
       ts.is_booked,
       COALESCE(a.status::TEXT, 'free') AS appointment_status,
       c.full_name AS client,
       dm.brand || ' ' || dm.model AS device,
       t.status AS ticket_status
FROM technicians tech
JOIN users u ON u.user_id = tech.user_id
JOIN service_centers sc ON sc.center_id = tech.center_id
LEFT JOIN time_slots ts ON ts.technician_id = tech.technician_id
LEFT JOIN appointments a ON a.slot_id = ts.slot_id
LEFT JOIN tickets t ON t.ticket_id = a.ticket_id
LEFT JOIN users c ON c.user_id = t.client_id
LEFT JOIN devices d ON d.device_id = t.device_id
LEFT JOIN device_models dm ON dm.device_model_id = d.device_model_id
ORDER BY work_date, ts.starts_at;
