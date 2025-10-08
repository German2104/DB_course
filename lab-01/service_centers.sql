-- =========================
-- Service Centers (simple)
-- PostgreSQL 15+
-- =========================

-- 1) Таблицы справочников
CREATE TABLE IF NOT EXISTS service_centers (
    id        SERIAL PRIMARY KEY,
    name      VARCHAR(100) NOT NULL,
    address   VARCHAR(255) NOT NULL,
    phone     VARCHAR(20),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT service_center_name_addr_unq UNIQUE (name, address)
);

CREATE TABLE IF NOT EXISTS clients (
    id          SERIAL PRIMARY KEY,
    full_name   VARCHAR(100) NOT NULL,
    phone       VARCHAR(20),
    email       VARCHAR(100),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
-- Уникальность контактов (опционально). Если не хочешь — закомментируй одну/обе строки:
CREATE UNIQUE INDEX IF NOT EXISTS clients_email_unq ON clients(email);
CREATE UNIQUE INDEX IF NOT EXISTS clients_phone_unq ON clients(phone);

-- 2) Устройства
CREATE TABLE IF NOT EXISTS devices (
    id             SERIAL PRIMARY KEY,
    client_id      INTEGER NOT NULL REFERENCES clients(id) ON UPDATE CASCADE ON DELETE RESTRICT,
    type           VARCHAR(50)  NOT NULL,  -- Телефон/Ноутбук/...
    brand          VARCHAR(50),
    model          VARCHAR(50),
    serial_number  VARCHAR(50),
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
-- Серийник может быть NULL, но если указан — уникален:
CREATE UNIQUE INDEX IF NOT EXISTS devices_serial_unq ON devices(serial_number) WHERE serial_number IS NOT NULL;
CREATE INDEX IF NOT EXISTS devices_client_idx ON devices(client_id);

-- 3) Сотрудники
CREATE TABLE IF NOT EXISTS employees (
    id                 SERIAL PRIMARY KEY,
    service_center_id  INTEGER NOT NULL REFERENCES service_centers(id) ON UPDATE CASCADE ON DELETE RESTRICT,
    full_name          VARCHAR(100) NOT NULL,
    position           VARCHAR(50),
    active             BOOLEAN NOT NULL DEFAULT TRUE,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS employees_center_idx ON employees(service_center_id);

-- 4) Заказы (заявки)
CREATE TABLE IF NOT EXISTS orders (
    id                 SERIAL PRIMARY KEY,
    device_id          INTEGER NOT NULL REFERENCES devices(id) ON UPDATE CASCADE ON DELETE RESTRICT,
    employee_id        INTEGER REFERENCES employees(id) ON UPDATE CASCADE ON DELETE SET NULL,
    service_center_id  INTEGER NOT NULL REFERENCES service_centers(id) ON UPDATE CASCADE ON DELETE RESTRICT,
    date_received      DATE NOT NULL,
    date_completed     DATE,
    status             VARCHAR(30) NOT NULL,
    description        TEXT,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT orders_status_chk CHECK (status IN (
        'received',        -- принято
        'in_progress',     -- в работе
        'waiting_parts',   -- ждём запчасти
        'done',            -- выполнено
        'cancelled'        -- отменено
    )),
    CONSTRAINT orders_dates_chk CHECK (
        date_completed IS NULL OR date_completed >= date_received
    )
);
CREATE INDEX IF NOT EXISTS orders_device_idx  ON orders(device_id);
CREATE INDEX IF NOT EXISTS orders_employee_idx ON orders(employee_id);
CREATE INDEX IF NOT EXISTS orders_center_idx ON orders(service_center_id);
CREATE INDEX IF NOT EXISTS orders_status_idx ON orders(status);

