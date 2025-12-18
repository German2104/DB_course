-- Наполнение справочников и основных таблиц тестовыми данными
-- Выполняется после schema.sql; значения подобраны так, чтобы покрыть связи

-- Пользователи (клиенты, мастера, администратор)
INSERT INTO users (full_name, phone, email, role) VALUES
  ('Alice Johnson', '+1-202-555-0111', 'alice.johnson@example.com', 'client'),
  ('Bob Smith', '+1-202-555-0133', 'bob.smith@example.com', 'client'),
  ('Carol Diaz', '+1-202-555-0166', 'carol.diaz@example.com', 'client'),
  ('Dmitry Kozlov', '+7-495-555-1001', 'dmitry.kozlov@svc.com', 'technician'),
  ('Elena Petrova', '+7-812-555-2202', 'elena.petrova@svc.com', 'technician'),
  ('Ivan Admin', '+7-999-555-3003', 'admin@example.com', 'admin');

-- Сервисные центры: адреса и таймзоны
INSERT INTO service_centers (name, address, timezone) VALUES
  ('TechFix Downtown', '123 Main St, City Center', 'Europe/Moscow'),
  ('GadgetCare North', '50 North Ave, Uptown', 'Europe/Moscow');

-- Профили мастеров: связываем с users и центрами по email/названию
INSERT INTO technicians (user_id, center_id, skill_level)
SELECT u.user_id, sc.center_id, data.skill_level
FROM (
  VALUES
    ('dmitry.kozlov@svc.com', 'TechFix Downtown', 4),
    ('elena.petrova@svc.com', 'GadgetCare North', 5)
) AS data(email, center_name, skill_level)
JOIN users u ON u.email = data.email
JOIN service_centers sc ON sc.name = data.center_name;

-- Типы устройств (справочник)
INSERT INTO device_types (name, description) VALUES
  ('Smartphone', 'Телефоны и смартфоны'),
  ('Laptop', 'Ноутбуки и ультрабуки'),
  ('Tablet', 'Планшеты');

-- Модели устройств: связываем с типами через name -> device_type_id
INSERT INTO device_models (device_type_id, brand, model)
SELECT dt.device_type_id, data.brand, data.model
FROM (
  VALUES
    ('Smartphone', 'Apple', 'iPhone 14'),
    ('Smartphone', 'Samsung', 'Galaxy S22'),
    ('Laptop', 'Dell', 'XPS 13'),
    ('Laptop', 'Apple', 'MacBook Air M2'),
    ('Tablet', 'Apple', 'iPad Pro 11')
) AS data(type_name, brand, model)
JOIN device_types dt ON dt.name = data.type_name;

-- Устройства клиентов: проверяем принадлежность клиента, типа и модели
INSERT INTO devices (client_id, device_type_id, device_model_id, serial_number, purchase_date, color, notes)
SELECT u.user_id,
       dt.device_type_id,
       dm.device_model_id,
       data.serial_number,
       data.purchase_date::date,
       data.color,
       data.notes
FROM (
  VALUES
    ('alice.johnson@example.com', 'Smartphone', 'Apple', 'iPhone 14', 'A-IPH14-001', '2023-11-12', 'Blue', 'Треснуло стекло'),
    ('bob.smith@example.com', 'Laptop', 'Dell', 'XPS 13', 'B-XPS13-010', '2022-05-01', 'Silver', 'Перегревается'),
    ('carol.diaz@example.com', 'Laptop', 'Apple', 'MacBook Air M2', 'C-MBA-777', '2023-02-15', 'Space Gray', 'Замена батареи'),
    ('alice.johnson@example.com', 'Smartphone', 'Samsung', 'Galaxy S22', 'A-GS22-009', '2022-08-20', 'Black', 'Не работает микрофон'),
    ('bob.smith@example.com', 'Tablet', 'Apple', 'iPad Pro 11', 'B-IPAD-005', '2021-10-05', 'Silver', 'Не держит заряд')
) AS data(email, type_name, brand, model_name, serial_number, purchase_date, color, notes)
JOIN users u ON u.email = data.email
JOIN device_types dt ON dt.name = data.type_name
JOIN device_models dm ON dm.brand = data.brand AND dm.model = data.model_name;

-- Рабочие слоты мастеров (часть уже забронирована) — проверяется связность по email и центру
INSERT INTO time_slots (technician_id, center_id, starts_at, ends_at, is_booked)
SELECT t.technician_id,
       t.center_id,
       data.starts_at::timestamptz,
       data.ends_at::timestamptz,
       data.is_booked
FROM (
  VALUES
    ('dmitry.kozlov@svc.com', 'TechFix Downtown', '2024-04-01 09:00+03', '2024-04-01 10:00+03', TRUE),
    ('dmitry.kozlov@svc.com', 'TechFix Downtown', '2024-04-01 10:00+03', '2024-04-01 11:00+03', TRUE),
    ('elena.petrova@svc.com', 'GadgetCare North', '2024-04-01 09:00+03', '2024-04-01 10:00+03', TRUE),
    ('elena.petrova@svc.com', 'GadgetCare North', '2024-04-01 10:00+03', '2024-04-01 11:00+03', FALSE),
    ('dmitry.kozlov@svc.com', 'TechFix Downtown', '2024-04-01 11:00+03', '2024-04-01 12:00+03', FALSE)
) AS data(email, center_name, starts_at, ends_at, is_booked)
JOIN technicians t ON t.user_id = (SELECT user_id FROM users WHERE email = data.email)
JOIN service_centers sc ON sc.name = data.center_name AND sc.center_id = t.center_id;

-- Заявки (tickets): создаём обращения по устройствам клиентов
INSERT INTO tickets (client_id, device_id, created_at, problem_description, status, priority, last_updated_at)
SELECT u.user_id,
       d.device_id,
       data.created_at::timestamptz,
       data.problem_description,
       data.status::ticket_status,
       data.priority::ticket_priority,
       data.last_updated_at::timestamptz
FROM (
  VALUES
    ('alice.johnson@example.com', 'A-IPH14-001', '2024-03-28 09:15+03', 'Замена дисплея после падения', 'new', 'high', '2024-03-28 09:15+03'),
    ('bob.smith@example.com', 'B-XPS13-010', '2024-03-27 15:00+03', 'Тормозит вентилятор, нагрев корпуса', 'in_progress', 'normal', '2024-03-31 10:00+03'),
    ('carol.diaz@example.com', 'C-MBA-777', '2024-03-25 12:30+03', 'Быстро разряжается батарея', 'waiting_parts', 'normal', '2024-03-30 18:00+03'),
    ('alice.johnson@example.com', 'A-GS22-009', '2024-03-29 11:45+03', 'Пропадает звук микрофона', 'done', 'low', '2024-03-30 09:00+03')
) AS data(email, serial_number, created_at, problem_description, status, priority, last_updated_at)
JOIN users u ON u.email = data.email
JOIN devices d ON d.serial_number = data.serial_number;

-- Записи на приём (appointments): используем уже занятые слоты
INSERT INTO appointments (ticket_id, center_id, technician_id, slot_id, status, created_at)
SELECT t.ticket_id,
       ts.center_id,
       ts.technician_id,
       ts.slot_id,
       data.status::appointment_status,
       data.created_at::timestamptz
FROM (
  VALUES
    ('alice.johnson@example.com', 'A-IPH14-001', '2024-03-28 09:15+03', 'completed', '2024-04-01 09:00+03', 'dmitry.kozlov@svc.com'),
    ('bob.smith@example.com', 'B-XPS13-010', '2024-03-31 10:00+03', 'checked_in', '2024-04-01 10:00+03', 'dmitry.kozlov@svc.com'),
    ('carol.diaz@example.com', 'C-MBA-777', '2024-03-30 12:00+03', 'cancelled', '2024-04-01 09:00+03', 'elena.petrova@svc.com')
) AS data(email, serial_number, created_at, status, slot_starts_at, technician_email)
JOIN tickets t ON t.device_id = (SELECT device_id FROM devices WHERE serial_number = data.serial_number)
JOIN technicians tech ON tech.user_id = (SELECT user_id FROM users WHERE email = data.technician_email)
JOIN time_slots ts ON ts.is_booked = TRUE
                 AND ts.starts_at = data.slot_starts_at::timestamptz
                 AND ts.technician_id = tech.technician_id;
