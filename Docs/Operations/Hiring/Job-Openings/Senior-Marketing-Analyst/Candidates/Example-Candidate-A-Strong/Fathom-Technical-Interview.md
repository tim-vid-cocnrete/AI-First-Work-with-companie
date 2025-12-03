# Транскрипт Технического Интервью
*[ПРИМЕР ШАБЛОНА - Это вымышленный транскрипт технического интервью для демонстрационных целей]*

**Кандидат:** Sarah Johnson
**Интервьюеры:** Robert Chen (Lead Data Engineer), Lisa Martinez (Senior Analyst)
**Дата:** 15 Июня 2024
**Длительность:** 50 минут
**Позиция:** Senior Marketing Analyst

---

## Техническая Оценка: Продвинутые Навыки SQL

**Robert Chen:** Привет, Сара, спасибо, что присоединились к нам сегодня. Мы протестируем ваши навыки SQL на сценариях, похожих на нашу ежедневную работу. Я делюсь нашей тестовой базой данных - вы можете видеть таблицы companies, passengers, passenger_trips и trips.

**Sarah Johnson:** Отлично, вижу схему. Это похоже на систему бронирования полетов с отношением многие-ко-многим между пассажирами и поездками.

**Robert Chen:** Совершенно верно. Давайте начнем с чего-то умеренно сложного. Можете написать запрос, чтобы найти пассажиров, которые совершили 3 или более полетов с одной и той же компанией?

**Sarah Johnson:** Конечно, мне нужно будет сделать джойн через связующую таблицу passenger_trips и агрегировать по пассажиру и компании.

```sql
SELECT p.passenger_name, c.company_name, COUNT(*) as flight_count
FROM passengers p
JOIN passenger_trips pt ON p.passenger_id = pt.passenger_id
JOIN trips t ON pt.trip_id = t.trip_id
JOIN companies c ON t.company_id = c.company_id
GROUP BY p.passenger_id, p.passenger_name, c.company_id, c.company_name
HAVING COUNT(*) >= 3
ORDER BY flight_count DESC, p.passenger_name;
```

**Lisa Martinez:** Отлично! Вы включили правильную группировку и сортировку. Теперь давайте усложним. Можете найти самый популярный тип самолета для каждой компании, правильно обрабатывая ничьи?

**Sarah Johnson:** Я буду использовать оконные функции для обработки ничьих с RANK() вместо ROW_NUMBER().

```sql
WITH aircraft_popularity AS (
  SELECT 
    c.company_name,
    t.aircraft_type,
    COUNT(*) as flight_count,
    RANK() OVER (PARTITION BY c.company_id ORDER BY COUNT(*) DESC) as popularity_rank
  FROM companies c
  JOIN trips t ON c.company_id = t.company_id
  GROUP BY c.company_id, c.company_name, t.aircraft_type
)
SELECT company_name, aircraft_type, flight_count
FROM aircraft_popularity
WHERE popularity_rank = 1
ORDER BY company_name, flight_count DESC;
```

**Robert Chen:** Отличное использование CTE и оконных функций! Теперь давайте проверим знания оптимизации. Этот запрос может быть медленным с миллионами записей. Как бы вы его оптимизировали?

**Sarah Johnson:** Несколько подходов:
1. **Индексы:** Составной индекс по (company_id, aircraft_type) и потенциально (company_id, trip_id)
2. **Партиционирование:** Если мы партиционируем поездки по диапазонам дат, мы могли бы ограничить сканирование
3. **Материализованные представления:** Предварительно агрегировать количество самолетов по компаниям, если этот запрос выполняется часто
4. **Переписывание запроса:** В зависимости от распределения данных, мы могли бы использовать EXISTS вместо джойнов

**Lisa Martinez:** Идеальный ответ! Давайте перейдем к сценариям атрибуции. Вы будете работать с этим ежедневно.

## Логика Маркетинговой Атрибуции

**Lisa Martinez:** У нас есть сессии Google Analytics и данные заказов. Постройте запрос атрибуции по последнему клику, но переопределите кодами инфлюенсеров, когда они присутствуют.

**Sarah Johnson:** Я сделаю это пошагово с CTE для ясности:

```sql
WITH order_sessions AS (
  -- Получить последнюю сессию перед каждым заказом
  SELECT 
    o.order_id,
    o.user_id,
    o.order_time,
    o.promo_code,
    s.session_id,
    s.source,
    s.medium,
    s.campaign,
    ROW_NUMBER() OVER (
      PARTITION BY o.order_id 
      ORDER BY s.session_time DESC
    ) as session_rank
  FROM orders o
  LEFT JOIN sessions s ON o.user_id = s.user_id 
                      AND s.session_time < o.order_time
                      AND s.session_time >= o.order_time - INTERVAL '30 days'
),
last_click_attribution AS (
  SELECT 
    order_id,
    user_id,
    CASE 
      WHEN promo_code IS NOT NULL AND promo_code LIKE 'INFLUENCER_%' 
      THEN 'influencer'
      WHEN session_rank = 1 THEN source
      ELSE 'direct'
    END as attribution_source,
    CASE 
      WHEN promo_code IS NOT NULL AND promo_code LIKE 'INFLUENCER_%' 
      THEN promo_code
      WHEN session_rank = 1 THEN campaign
      ELSE NULL
    END as attribution_campaign
  FROM order_sessions
  WHERE session_rank = 1 OR session_rank IS NULL
)
SELECT * FROM last_click_attribution;
```

**Robert Chen:** Отлично! Вы обработали граничные случаи, такие как отсутствующие сессии, и добавили 30-дневное окно ретроспективы. А как насчет соображений производительности для этого запроса?

**Sarah Johnson:** Ключевые оптимизации:
1. **Партиционированные индексы** по sessions(user_id, session_time)
2. **Партиционирование по дате** в таблице sessions по месяцам
3. **Рассмотреть инкрементальную обработку** - пересчитывать атрибуцию только для недавних заказов
4. **Материализованная таблица** для исторической атрибуции, которая не меняется

## Сложные Аналитические Сценарии

**Lisa Martinez:** Вот реальный сценарий: Коэффициент конверсии упал на 40% вчера, но трафик остался прежним. Проведите меня через ваш подход к дебаггингу.

**Sarah Johnson:** Я бы следовала этому систематическому подходу:

**1. Проверки Качества Данных:**
```sql
-- Сравнить ежедневные метрики
SELECT 
  DATE(event_time) as date,
  COUNT(*) as total_events,
  COUNT(DISTINCT user_id) as unique_users,
  COUNT(CASE WHEN event_type = 'purchase' THEN 1 END) as conversions,
  ROUND(100.0 * COUNT(CASE WHEN event_type = 'purchase' THEN 1 END) / COUNT(*), 2) as conversion_rate
FROM events 
WHERE event_time >= CURRENT_DATE - 7
GROUP BY DATE(event_time)
ORDER BY date;

-- Проверить полноту данных
SELECT 
  COUNT(*) as total_records,
  COUNT(user_id) as non_null_users,
  COUNT(session_id) as non_null_sessions,
  COUNT(CASE WHEN event_type IS NULL THEN 1 END) as null_event_types
FROM events 
WHERE DATE(event_time) = CURRENT_DATE - 1;
```

**2. Техническое Расследование:**
- Проверить логи ETL пайплайна на сбои
- Проверить время деплоя кодов трекинга
- Искать бот-трафик или проблемы с сбором данных
- Изучить воронку конверсии шаг за шагом

**3. Бизнес-Контекст:**
- Проблемы с производительностью сайта или простои
- Проблемы с платежным процессором
- Изменения UI/UX, влияющие на процесс чекаута
- Внешние факторы (праздники, новости)

**Robert Chen:** Отличный систематический подход. Что если данные выглядят чистыми, но конверсии действительно упали?

**Sarah Johnson:** Тогда я бы исследовала бизнес-факторы:

```sql
-- Анализ разбивки воронки конверсии
WITH funnel_analysis AS (
  SELECT 
    DATE(event_time) as date,
    COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END) as visitors,
    COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN user_id END) as cart_adds,
    COUNT(DISTINCT CASE WHEN event_type = 'checkout_start' THEN user_id END) as checkout_starts,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) as purchases
  FROM events 
  WHERE event_time >= CURRENT_DATE - 7
  GROUP BY DATE(event_time)
)
SELECT 
  date,
  visitors,
  ROUND(100.0 * cart_adds / visitors, 2) as cart_rate,
  ROUND(100.0 * checkout_starts / cart_adds, 2) as checkout_rate,
  ROUND(100.0 * purchases / checkout_starts, 2) as purchase_rate
FROM funnel_analysis
ORDER BY date;
```

Это помогло бы определить, где именно пользователи отваливаются.

## Продвинутая Оптимизация Производительности

**Robert Chen:** Последний вызов. У нас 100M записей в нашей таблице сессий. Этот запрос атрибуции занимает 45 минут. Как вы его оптимизируете?

**Sarah Johnson:** Многосторонний подход:

**1. Дизайн Таблицы:**
```sql
-- Партиционировать сессии по месяцам
CREATE TABLE sessions_partitioned (
  session_id BIGINT,
  user_id BIGINT,
  session_time TIMESTAMP,
  source VARCHAR(100)
) PARTITION BY RANGE (session_time);

-- Создать ежемесячные партиции с индексами
CREATE INDEX idx_sessions_user_time ON sessions_partitioned (user_id, session_time DESC);
```

**2. Оптимизация Запроса:**
```sql
-- Использовать EXISTS вместо джойнов для лучшей производительности
WITH recent_orders AS (
  SELECT order_id, user_id, order_time, promo_code
  FROM orders 
  WHERE order_time >= CURRENT_DATE - 1
),
order_attribution AS (
  SELECT 
    o.order_id,
    o.promo_code,
    (
      SELECT s.source 
      FROM sessions s 
      WHERE s.user_id = o.user_id 
        AND s.session_time < o.order_time
        AND s.session_time >= o.order_time - INTERVAL '30 days'
      ORDER BY s.session_time DESC 
      LIMIT 1
    ) as last_click_source
  FROM recent_orders o
)
SELECT * FROM order_attribution;
```

**3. Инкрементальная Обработка:**
- Обрабатывать только новые заказы ежедневно
- Хранить историческую атрибуцию в отдельной таблице
- Использовать change data capture (CDC) для обновлений в реальном времени

**Lisa Martinez:** Выдающийся ответ! Ваш подход к оптимизации производительности показывает глубокое понимание как тюнинга запросов, так и системной архитектуры.

## Завершение и Оценка

**Robert Chen:** Сара, это было впечатляюще. Ваши навыки SQL явно продвинутые, и ваш систематический подход к решению проблем - именно то, что нам нужно.

**Sarah Johnson:** Спасибо! Мне действительно понравилось работать над этими сценариями. Они намного сложнее, чем в моей текущей роли, что именно то, что я ищу.

**Lisa Martinez:** Есть вопросы о нашем тех стеке или ежедневных обязанностях?

**Sarah Johnson:** Да, пара:
1. Вы используете DBT или похожие инструменты для пайплайнов трансформации?
2. Каков ваш подход к мониторингу качества данных?
3. Как вы принимаете решения о real-time vs. batch обработке?

**Robert Chen:** Отличные вопросы - они показывают, что вы думаете о более широкой архитектуре данных. Мы используем DBT обширно, имеем автоматизированные проверки качества данных и тщательно балансируем real-time vs. batch на основе бизнес-требований.

Мы обсудим внутри и вернемся к вам скоро. Спасибо за отличную техническую сессию!

---

## Оценка Технического Интервью

**Владение SQL:** 5/5 - Продвинутые навыки, оптимальная структура запросов
**Оптимизация Производительности:** 5/5 - Глубокое понимание индексирования, партиционирования
**Логика Атрибуции:** 5/5 - Сложные сценарии обработаны корректно
**Решение Проблем:** 5/5 - Систематический, комплексный подход
**Оконные Функции:** 5/5 - Правильное использование RANK vs ROW_NUMBER
**Архитектура Данных:** 5/5 - Понимает более широкие системные импликации
**Коммуникация:** 5/5 - Четкие объяснения сложных концепций

**Общее Техническое Соответствие:** Отличное - превышает требования, готова к немедленной продуктивности

---

*Примечание к шаблону: Это интервью демонстрирует сильного кандидата, который превышает технические требования и показывает продвинутые способности к решению проблем. Используйте это для калибровки ожиданий для найма senior-уровня.*
