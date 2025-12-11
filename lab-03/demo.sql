-- Демонстрация процедур, функций и триггеров (ЛР3)
-- Выполнить после schema.sql, seed.sql и procedures_functions_triggers.sql; комментарии поясняют каждый шаг

-- 1) Успешное создание тикета и бронирование свободного слота (slot_id = 5)
--    Проверяет: клиент, устройство, слот, создаёт тикет и запись, триггеры помечают слот занятым
CALL book_ticket_with_slot(
  'alice.johnson@example.com',
  'A-GS22-009',
  'Не ловит сеть, требуется диагностика',
  'high',
  5
);

-- Проверяем, что слот помечен как занятый триггером
SELECT slot_id, is_booked FROM time_slots WHERE slot_id = 5;

-- 2) Ошибка при повторном бронировании того же слота — обработка исключения
--    DO-блок ловит любое исключение и выводит его текст через NOTICE
DO $$
BEGIN
  CALL book_ticket_with_slot(
    'bob.smith@example.com',
    'B-XPS13-010',
    'Повторная попытка брони для демонстрации ошибки',
    'normal',
    5
  );
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Ожидаемая ошибка: %', SQLERRM;
END $$;

-- 3) Функции: активность тикета и загрузка мастера
--    Проверяем живость тикета 1 и считаем занятость мастера Дмитрия
SELECT fn_is_ticket_active(1) AS ticket1_active;

SELECT * FROM fn_technician_utilization(
  (SELECT technician_id FROM technicians t JOIN users u ON u.user_id = t.user_id WHERE u.email = 'dmitry.kozlov@svc.com')
);

-- 4) Триггеры освобождают слот после удаления записи
--    Удаляем запись и убеждаемся, что is_booked сброшен триггером
DELETE FROM appointments WHERE slot_id = 5;
SELECT slot_id, is_booked FROM time_slots WHERE slot_id = 5;
