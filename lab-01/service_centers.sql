-- =========================================================
-- ENUM-типы
-- =========================================================

CREATE TYPE user_role AS ENUM ('client', 'technician', 'admin');

CREATE TYPE ticket_status AS ENUM ('new', 'in_progress', 'waiting_parts', 'done', 'cancelled');

CREATE TYPE ticket_priority AS ENUM ('low', 'normal', 'high');

CREATE TYPE appointment_status AS ENUM ('booked', 'checked_in', 'no_show', 'completed', 'cancelled');


-- =========================================================
-- Таблицы
-- =========================================================

CREATE TABLE IF NOT EXISTS users (
  user_id    BIGSERIAL PRIMARY KEY,
  full_name  VARCHAR(200) NOT NULL,
  phone      VARCHAR(32),
  email      VARCHAR(255),
  role       user_role NOT NULL DEFAULT 'client',
  active     BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT users_phone_uniq UNIQUE (phone),
  CONSTRAINT users_email_uniq UNIQUE (email)
);

CREATE TABLE IF NOT EXISTS service_centers (
  center_id   BIGSERIAL PRIMARY KEY,
  name        VARCHAR(200) NOT NULL,
  address     TEXT NOT NULL,
  timezone    VARCHAR(64) NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT service_centers_name_address_uniq UNIQUE (name, address)
);

CREATE TABLE IF NOT EXISTS technicians (
  technician_id BIGSERIAL PRIMARY KEY,
  user_id       BIGINT NOT NULL UNIQUE REFERENCES users(user_id),
  center_id     BIGINT NOT NULL REFERENCES service_centers(center_id),
  skill_level   SMALLINT NOT NULL DEFAULT 1,
  active        BOOLEAN NOT NULL DEFAULT TRUE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS device_types (
  device_type_id BIGSERIAL PRIMARY KEY,
  name           VARCHAR(100) NOT NULL UNIQUE,
  description    TEXT
);

CREATE TABLE IF NOT EXISTS device_models (
  device_model_id BIGSERIAL PRIMARY KEY,
  device_type_id  BIGINT NOT NULL REFERENCES device_types(device_type_id),
  brand           VARCHAR(100) NOT NULL,
  model           VARCHAR(120) NOT NULL,
  CONSTRAINT device_models_brand_model_uniq UNIQUE (brand, model)
);
CREATE INDEX IF NOT EXISTS device_models_device_type_id_idx
  ON device_models (device_type_id);

CREATE TABLE IF NOT EXISTS devices (
  device_id        BIGSERIAL PRIMARY KEY,
  client_id        BIGINT NOT NULL REFERENCES users(user_id),
  device_type_id   BIGINT NOT NULL REFERENCES device_types(device_type_id),
  device_model_id  BIGINT NOT NULL REFERENCES device_models(device_model_id),
  serial_number    VARCHAR(120) UNIQUE,
  purchase_date    DATE,
  color            VARCHAR(50),
  notes            TEXT
);
CREATE INDEX IF NOT EXISTS devices_client_id_idx
  ON devices (client_id);
CREATE INDEX IF NOT EXISTS devices_type_model_idx
  ON devices (device_type_id, device_model_id);

CREATE TABLE IF NOT EXISTS time_slots (
  slot_id       BIGSERIAL PRIMARY KEY,
  technician_id BIGINT NOT NULL REFERENCES technicians(technician_id),
  center_id     BIGINT NOT NULL REFERENCES service_centers(center_id),
  starts_at     TIMESTAMPTZ NOT NULL,
  ends_at       TIMESTAMPTZ NOT NULL,
  is_booked     BOOLEAN NOT NULL DEFAULT FALSE,
  CONSTRAINT time_slots_tech_start_uniq UNIQUE (technician_id, starts_at)
);
CREATE INDEX IF NOT EXISTS time_slots_center_booked_start_idx
  ON time_slots (center_id, is_booked, starts_at);

CREATE TABLE IF NOT EXISTS tickets (
  ticket_id           BIGSERIAL PRIMARY KEY,
  client_id           BIGINT NOT NULL REFERENCES users(user_id),
  device_id           BIGINT NOT NULL REFERENCES devices(device_id),
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  problem_description TEXT NOT NULL,
  status              ticket_status NOT NULL DEFAULT 'new',
  priority            ticket_priority NOT NULL DEFAULT 'normal',
  last_updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS tickets_client_id_idx
  ON tickets (client_id);
CREATE INDEX IF NOT EXISTS tickets_status_idx
  ON tickets (status);

CREATE TABLE IF NOT EXISTS appointments (
  appointment_id BIGSERIAL PRIMARY KEY,
  ticket_id      BIGINT NOT NULL REFERENCES tickets(ticket_id),
  center_id      BIGINT NOT NULL REFERENCES service_centers(center_id),
  technician_id  BIGINT NOT NULL REFERENCES technicians(technician_id),
  slot_id        BIGINT NOT NULL UNIQUE REFERENCES time_slots(slot_id),
  status         appointment_status NOT NULL DEFAULT 'booked',
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS appointments_technician_id_idx
  ON appointments (technician_id);
CREATE INDEX IF NOT EXISTS appointments_ticket_id_idx
  ON appointments (ticket_id);