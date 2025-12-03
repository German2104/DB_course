-- Лабораторная работа №2. Схема БД
-- БД: Система записи в сервисные центры
-- Скрипт пересоздаёт типы и таблицы для PostgreSQL

-- Очистка зависимостей (вьюхи удалятся каскадно)
DROP TABLE IF EXISTS appointments, tickets, time_slots, devices, device_models, device_types, technicians, service_centers, users CASCADE;
DROP TYPE IF EXISTS appointment_status CASCADE;
DROP TYPE IF EXISTS ticket_priority CASCADE;
DROP TYPE IF EXISTS ticket_status CASCADE;
DROP TYPE IF EXISTS user_role CASCADE;

-- ENUM-типы
CREATE TYPE user_role AS ENUM ('client', 'technician', 'admin');
CREATE TYPE ticket_status AS ENUM ('new', 'in_progress', 'waiting_parts', 'done', 'cancelled');
CREATE TYPE ticket_priority AS ENUM ('low', 'normal', 'high');
CREATE TYPE appointment_status AS ENUM ('booked', 'checked_in', 'no_show', 'completed', 'cancelled');

-- Таблица пользователей
CREATE TABLE users (
  user_id    BIGSERIAL PRIMARY KEY,
  full_name  VARCHAR(200) NOT NULL,
  phone      VARCHAR(32) NOT NULL,
  email      VARCHAR(255) NOT NULL,
  role       user_role NOT NULL DEFAULT 'client',
  active     BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT users_phone_uniq UNIQUE (phone),
  CONSTRAINT users_email_uniq UNIQUE (email)
);

-- Сервисные центры
CREATE TABLE service_centers (
  center_id   BIGSERIAL PRIMARY KEY,
  name        VARCHAR(200) NOT NULL,
  address     TEXT NOT NULL,
  timezone    VARCHAR(64) NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT service_centers_name_address_uniq UNIQUE (name, address)
);

-- Профили мастеров (1:1 к users)
CREATE TABLE technicians (
  technician_id BIGSERIAL PRIMARY KEY,
  user_id       BIGINT NOT NULL UNIQUE REFERENCES users(user_id),
  center_id     BIGINT NOT NULL REFERENCES service_centers(center_id),
  skill_level   SMALLINT NOT NULL DEFAULT 1 CHECK (skill_level BETWEEN 1 AND 5),
  active        BOOLEAN NOT NULL DEFAULT TRUE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Справочник типов устройств
CREATE TABLE device_types (
  device_type_id BIGSERIAL PRIMARY KEY,
  name           VARCHAR(100) NOT NULL UNIQUE,
  description    TEXT
);

-- Справочник моделей устройств
CREATE TABLE device_models (
  device_model_id BIGSERIAL PRIMARY KEY,
  device_type_id  BIGINT NOT NULL REFERENCES device_types(device_type_id),
  brand           VARCHAR(100) NOT NULL,
  model           VARCHAR(120) NOT NULL,
  CONSTRAINT device_models_brand_model_uniq UNIQUE (brand, model)
);
CREATE INDEX device_models_device_type_id_idx ON device_models (device_type_id);

-- Устройства клиентов
CREATE TABLE devices (
  device_id        BIGSERIAL PRIMARY KEY,
  client_id        BIGINT NOT NULL REFERENCES users(user_id),
  device_type_id   BIGINT NOT NULL REFERENCES device_types(device_type_id),
  device_model_id  BIGINT NOT NULL REFERENCES device_models(device_model_id),
  serial_number    VARCHAR(120) UNIQUE,
  purchase_date    DATE,
  color            VARCHAR(50),
  notes            TEXT
);
CREATE INDEX devices_client_id_idx ON devices (client_id);
CREATE INDEX devices_type_model_idx ON devices (device_type_id, device_model_id);

-- Рабочие слоты мастеров
CREATE TABLE time_slots (
  slot_id       BIGSERIAL PRIMARY KEY,
  technician_id BIGINT NOT NULL REFERENCES technicians(technician_id),
  center_id     BIGINT NOT NULL REFERENCES service_centers(center_id),
  starts_at     TIMESTAMPTZ NOT NULL,
  ends_at       TIMESTAMPTZ NOT NULL,
  is_booked     BOOLEAN NOT NULL DEFAULT FALSE,
  CONSTRAINT time_slots_tech_start_uniq UNIQUE (technician_id, starts_at),
  CONSTRAINT time_slots_time_check CHECK (ends_at > starts_at)
);
CREATE INDEX time_slots_center_booked_start_idx ON time_slots (center_id, is_booked, starts_at);

-- Заявки на ремонт
CREATE TABLE tickets (
  ticket_id           BIGSERIAL PRIMARY KEY,
  client_id           BIGINT NOT NULL REFERENCES users(user_id),
  device_id           BIGINT NOT NULL REFERENCES devices(device_id),
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  problem_description TEXT NOT NULL,
  status              ticket_status NOT NULL DEFAULT 'new',
  priority            ticket_priority NOT NULL DEFAULT 'normal',
  last_updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX tickets_client_id_idx ON tickets (client_id);
CREATE INDEX tickets_status_idx ON tickets (status);

-- Записи на приём
CREATE TABLE appointments (
  appointment_id BIGSERIAL PRIMARY KEY,
  ticket_id      BIGINT NOT NULL REFERENCES tickets(ticket_id),
  center_id      BIGINT NOT NULL REFERENCES service_centers(center_id),
  technician_id  BIGINT NOT NULL REFERENCES technicians(technician_id),
  slot_id        BIGINT NOT NULL UNIQUE REFERENCES time_slots(slot_id),
  status         appointment_status NOT NULL DEFAULT 'booked',
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX appointments_technician_id_idx ON appointments (technician_id);
CREATE INDEX appointments_ticket_id_idx ON appointments (ticket_id);
