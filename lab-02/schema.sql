-- Лабораторная работа №2. Схема БД
-- БД: Система записи в сервисные центры
-- Скрипт пересоздаёт типы и таблицы для PostgreSQL с комментариями по каждому шагу

-- Очистка зависимостей (вьюхи удалятся каскадно), чтобы скрипт был идемпотентным
DROP TABLE IF EXISTS appointments, tickets, time_slots, devices, device_models, device_types, technicians, service_centers, users CASCADE;
DROP TYPE IF EXISTS appointment_status CASCADE;
DROP TYPE IF EXISTS ticket_priority CASCADE;
DROP TYPE IF EXISTS ticket_status CASCADE;
DROP TYPE IF EXISTS user_role CASCADE;

-- ENUM-типы статусов и ролей
CREATE TYPE user_role AS ENUM ('client', 'technician', 'admin');
CREATE TYPE ticket_status AS ENUM ('new', 'in_progress', 'waiting_parts', 'done', 'cancelled');
CREATE TYPE ticket_priority AS ENUM ('low', 'normal', 'high');
CREATE TYPE appointment_status AS ENUM ('booked', 'checked_in', 'no_show', 'completed', 'cancelled');

-- Таблица пользователей: клиенты, мастера, администраторы
CREATE TABLE users (
  user_id    BIGSERIAL PRIMARY KEY,     -- surrogate PK
  full_name  VARCHAR(200) NOT NULL,     -- ФИО
  phone      VARCHAR(32) NOT NULL,      -- телефон (уникальный)
  email      VARCHAR(255) NOT NULL,     -- email (уникальный)
  role       user_role NOT NULL DEFAULT 'client', -- роль по умолчанию — клиент
  active     BOOLEAN NOT NULL DEFAULT TRUE,       -- активен ли пользователь
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),  -- дата регистрации
  CONSTRAINT users_phone_uniq UNIQUE (phone),     -- ограничение уникальности телефона
  CONSTRAINT users_email_uniq UNIQUE (email)      -- ограничение уникальности email
);

-- Сервисные центры: справочник площадок
CREATE TABLE service_centers (
  center_id   BIGSERIAL PRIMARY KEY,        -- PK
  name        VARCHAR(200) NOT NULL,        -- название центра
  address     TEXT NOT NULL,                -- адрес
  timezone    VARCHAR(64) NOT NULL,         -- таймзона, чтобы слоты были корректны
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(), -- дата создания записи
  CONSTRAINT service_centers_name_address_uniq UNIQUE (name, address) -- защита от дублей
);

-- Профили мастеров (1:1 к users)
CREATE TABLE technicians (
  technician_id BIGSERIAL PRIMARY KEY,    -- PK
  user_id       BIGINT NOT NULL UNIQUE REFERENCES users(user_id), -- ссылка на пользователя
  center_id     BIGINT NOT NULL REFERENCES service_centers(center_id), -- привязка к центру
  skill_level   SMALLINT NOT NULL DEFAULT 1 CHECK (skill_level BETWEEN 1 AND 5), -- уровень навыка 1-5
  active        BOOLEAN NOT NULL DEFAULT TRUE, -- активен ли мастер
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now() -- дата создания записи
);

-- Справочник типов устройств (смартфоны/ноутбуки/планшеты и т.д.)
CREATE TABLE device_types (
  device_type_id BIGSERIAL PRIMARY KEY, -- PK
  name           VARCHAR(100) NOT NULL UNIQUE, -- название типа
  description    TEXT -- опциональное описание
);

-- Справочник моделей устройств (бренд + модель внутри типа)
CREATE TABLE device_models (
  device_model_id BIGSERIAL PRIMARY KEY, -- PK
  device_type_id  BIGINT NOT NULL REFERENCES device_types(device_type_id), -- связь с типом
  brand           VARCHAR(100) NOT NULL, -- бренд
  model           VARCHAR(120) NOT NULL, -- модель
  CONSTRAINT device_models_brand_model_uniq UNIQUE (brand, model)
);
CREATE INDEX device_models_device_type_id_idx ON device_models (device_type_id); -- ускоряет фильтр по типу

-- Устройства клиентов: конкретные экземпляры
CREATE TABLE devices (
  device_id        BIGSERIAL PRIMARY KEY,          -- PK
  client_id        BIGINT NOT NULL REFERENCES users(user_id),       -- владелец
  device_type_id   BIGINT NOT NULL REFERENCES device_types(device_type_id), -- тип
  device_model_id  BIGINT NOT NULL REFERENCES device_models(device_model_id), -- модель
  serial_number    VARCHAR(120) UNIQUE,            -- серийный номер (уникальный)
  purchase_date    DATE,                           -- дата покупки
  color            VARCHAR(50),                    -- цвет
  notes            TEXT                            -- примечания
);
CREATE INDEX devices_client_id_idx ON devices (client_id); -- быстрый поиск устройств клиента
CREATE INDEX devices_type_model_idx ON devices (device_type_id, device_model_id); -- фильтр по типу/модели

-- Рабочие слоты мастеров (время приёма)
CREATE TABLE time_slots (
  slot_id       BIGSERIAL PRIMARY KEY, -- PK
  technician_id BIGINT NOT NULL REFERENCES technicians(technician_id), -- мастер
  center_id     BIGINT NOT NULL REFERENCES service_centers(center_id), -- площадка
  starts_at     TIMESTAMPTZ NOT NULL, -- начало приёма
  ends_at       TIMESTAMPTZ NOT NULL, -- конец приёма
  is_booked     BOOLEAN NOT NULL DEFAULT FALSE, -- флаг занятости
  CONSTRAINT time_slots_tech_start_uniq UNIQUE (technician_id, starts_at), -- один слот на мастера в это время
  CONSTRAINT time_slots_time_check CHECK (ends_at > starts_at) -- защита от некорректного интервала
);
CREATE INDEX time_slots_center_booked_start_idx ON time_slots (center_id, is_booked, starts_at); -- поиск свободных по центру и дате

-- Заявки на ремонт (тикеты)
CREATE TABLE tickets (
  ticket_id           BIGSERIAL PRIMARY KEY,                  -- PK
  client_id           BIGINT NOT NULL REFERENCES users(user_id), -- кто создал
  device_id           BIGINT NOT NULL REFERENCES devices(device_id), -- что ломалось
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),     -- дата создания
  problem_description TEXT NOT NULL,                          -- описание проблемы
  status              ticket_status NOT NULL DEFAULT 'new',   -- статус
  priority            ticket_priority NOT NULL DEFAULT 'normal', -- приоритет
  last_updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()      -- последняя правка
);
CREATE INDEX tickets_client_id_idx ON tickets (client_id); -- поиск тикетов клиента
CREATE INDEX tickets_status_idx ON tickets (status); -- фильтр по статусу

-- Записи на приём (привязка тикета к слоту и мастеру)
CREATE TABLE appointments (
  appointment_id BIGSERIAL PRIMARY KEY,             -- PK
  ticket_id      BIGINT NOT NULL REFERENCES tickets(ticket_id), -- какой тикет
  center_id      BIGINT NOT NULL REFERENCES service_centers(center_id), -- площадка
  technician_id  BIGINT NOT NULL REFERENCES technicians(technician_id), -- мастер
  slot_id        BIGINT NOT NULL UNIQUE REFERENCES time_slots(slot_id), -- уникальный слот
  status         appointment_status NOT NULL DEFAULT 'booked', -- статус приёма
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now()            -- дата записи
);
CREATE INDEX appointments_technician_id_idx ON appointments (technician_id); -- расписание мастера
CREATE INDEX appointments_ticket_id_idx ON appointments (ticket_id); -- все записи по тикету
