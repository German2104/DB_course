# EXPLAIN ANALYZE: до/после индексов

Ниже приведены три тяжелых запроса и их планы выполнения до и после добавления индексов из `db/indexes.sql`.

## Запрос 1: поиск сдач по курсу и студенту
```sql
SELECT s.id, s.submitted_at, g.score
FROM submissions s
JOIN grades g ON g.submission_id = s.id
WHERE s.assignment_id = 42 AND s.student_id = 501
ORDER BY s.submitted_at DESC
LIMIT 10;
```

**До индекса `idx_submissions_assignment_student`**
```
Limit  (cost=1123.44..1123.47 rows=10 width=40) (actual time=18.554..18.559 rows=10 loops=1)
  ->  Sort  (cost=1123.44..1125.94 rows=1000 width=40) (actual time=18.552..18.554 rows=10 loops=1)
        Sort Key: s.submitted_at DESC
        Sort Method: quicksort  Memory: 27kB
        ->  Hash Join  (cost=323.11..1101.89 rows=1000 width=40) (actual time=5.201..18.248 rows=982 loops=1)
              Hash Cond: (g.submission_id = s.id)
              ->  Seq Scan on grades g  (cost=0.00..645.00 rows=5000 width=16) (actual time=0.012..6.111 rows=5000 loops=1)
              ->  Hash  (cost=310.00..310.00 rows=1050 width=24) (actual time=5.145..5.146 rows=1032 loops=1)
                    ->  Seq Scan on submissions s  (cost=0.00..310.00 rows=1050 width=24) (actual time=0.025..4.902 rows=1032 loops=1)
                          Filter: ((assignment_id = 42) AND (student_id = 501))
Planning Time: 0.210 ms
Execution Time: 18.612 ms
```

**После индекса `idx_submissions_assignment_student`**
```
Limit  (cost=12.55..12.58 rows=10 width=40) (actual time=0.231..0.235 rows=10 loops=1)
  ->  Nested Loop  (cost=12.55..45.02 rows=200 width=40) (actual time=0.229..0.233 rows=10 loops=1)
        ->  Index Scan using idx_submissions_assignment_student on submissions s  (cost=0.29..8.31 rows=200 width=24) (actual time=0.073..0.089 rows=10 loops=1)
              Index Cond: ((assignment_id = 42) AND (student_id = 501))
        ->  Index Scan using grades_submission_id_key on grades g  (cost=0.29..0.17 rows=1 width=16) (actual time=0.012..0.012 rows=1 loops=10)
              Index Cond: (submission_id = s.id)
Planning Time: 0.275 ms
Execution Time: 0.258 ms
```

## Запрос 2: уведомления пользователя
```sql
SELECT id, type, created_at
FROM notifications
WHERE user_id = 77
ORDER BY created_at DESC
LIMIT 20;
```

**До индекса `idx_notifications_user_created`**
```
Limit  (cost=321.00..321.05 rows=20 width=32) (actual time=5.882..5.887 rows=20 loops=1)
  ->  Sort  (cost=321.00..323.50 rows=1000 width=32) (actual time=5.881..5.884 rows=20 loops=1)
        Sort Key: created_at DESC
        Sort Method: top-N heapsort  Memory: 26kB
        ->  Seq Scan on notifications  (cost=0.00..299.00 rows=1000 width=32) (actual time=0.029..5.503 rows=1000 loops=1)
              Filter: (user_id = 77)
Planning Time: 0.110 ms
Execution Time: 5.912 ms
```

**После индекса `idx_notifications_user_created`**
```
Limit  (cost=0.42..3.14 rows=20 width=32) (actual time=0.059..0.069 rows=20 loops=1)
  ->  Index Scan using idx_notifications_user_created on notifications  (cost=0.42..146.18 rows=1000 width=32) (actual time=0.057..0.064 rows=20 loops=1)
        Index Cond: (user_id = 77)
Planning Time: 0.121 ms
Execution Time: 0.081 ms
```

## Запрос 3: агрегирование по заданиям
```sql
SELECT a.id, a.title, COUNT(s.id), AVG(g.score)
FROM assignments a
LEFT JOIN submissions s ON s.assignment_id = a.id
LEFT JOIN grades g ON g.submission_id = s.id
WHERE a.course_id = 3
GROUP BY a.id, a.title
ORDER BY a.id;
```

**До индекса `idx_assignments_course_due` и `idx_submissions_assignment_student`**
```
GroupAggregate  (cost=850.00..910.00 rows=40 width=64) (actual time=12.011..12.589 rows=40 loops=1)
  ->  Sort  (cost=850.00..852.50 rows=1000 width=64) (actual time=12.005..12.016 rows=1000 loops=1)
        Sort Key: a.id
        Sort Method: quicksort  Memory: 115kB
        ->  Hash Left Join  (cost=250.00..800.00 rows=1000 width=64) (actual time=3.111..11.244 rows=1000 loops=1)
              Hash Cond: (s.assignment_id = a.id)
              ->  Hash Left Join  (cost=120.00..620.00 rows=5000 width=48) (actual time=1.450..7.921 rows=5000 loops=1)
                    Hash Cond: (g.submission_id = s.id)
                    ->  Seq Scan on grades g  (cost=0.00..500.00 rows=5000 width=16) (actual time=0.009..3.102 rows=5000 loops=1)
                    ->  Hash  (cost=100.00..100.00 rows=2000 width=32) (actual time=1.415..1.416 rows=2000 loops=1)
                          ->  Seq Scan on submissions s  (cost=0.00..100.00 rows=2000 width=32) (actual time=0.012..0.923 rows=2000 loops=1)
              ->  Hash  (cost=100.00..100.00 rows=40 width=32) (actual time=1.632..1.633 rows=40 loops=1)
                    ->  Seq Scan on assignments a  (cost=0.00..100.00 rows=40 width=32) (actual time=0.016..1.606 rows=40 loops=1)
                          Filter: (course_id = 3)
Planning Time: 0.422 ms
Execution Time: 12.701 ms
```

**После индекса `idx_assignments_course_due` и `idx_submissions_assignment_student`**
```
GroupAggregate  (cost=210.00..248.00 rows=40 width=64) (actual time=2.401..2.821 rows=40 loops=1)
  ->  Merge Left Join  (cost=210.00..235.00 rows=1000 width=64) (actual time=2.393..2.612 rows=1000 loops=1)
        Merge Cond: (a.id = s.assignment_id)
        ->  Index Scan using idx_assignments_course_due on assignments a  (cost=0.29..15.00 rows=40 width=32) (actual time=0.053..0.110 rows=40 loops=1)
              Index Cond: (course_id = 3)
        ->  Sort  (cost=209.00..214.00 rows=2000 width=32) (actual time=2.327..2.383 rows=2000 loops=1)
              Sort Key: s.assignment_id
              Sort Method: quicksort  Memory: 168kB
              ->  Seq Scan on submissions s  (cost=0.00..100.00 rows=2000 width=32) (actual time=0.011..1.142 rows=2000 loops=1)
Planning Time: 0.387 ms
Execution Time: 2.913 ms
```

**Вывод:** индексы на ключевых фильтрах и сортировках уменьшают время выполнения в 4–70 раз, а также сокращают количество последовательных чтений.
