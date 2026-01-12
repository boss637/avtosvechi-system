# AVTOSVECHI / AUTOSHOP — MASTER PLAN (6 месяцев)
PLAN: done=40 todo=65 total=105 progress=38.1%

Дата актуализации: 21.12.2025  
Проект: Dockerized FastAPI + Postgres + Redis + Nginx (+ Monitoring позже, отдельным стеком)

Базовые URL (актуальные):
- API (через Nginx):  
  - http://192.168.1.100:8080/health  
  - http://192.168.1.100:8080/api/v1/inventory/status  
  - http://192.168.1.100:8080/docs (опционально, для разработчика)
- Nginx:  
  - http://192.168.1.100:8080/
- Внутренний API (только внутри docker-сети):  
  - http://api:8000/
- Monitoring (будет включён позже отдельным compose):
  - Grafana: http://192.168.1.100:3000/ (пока отключено)
  - Prometheus: http://192.168.1.100:9091/ (пока отключено)

---

## 0) Стратегическая цель (North Star)
Превратить старый Bitrix‑сайт и разрозненные магазины в единую систему с:
- [ ] Единой точкой истины по остаткам для 2 магазинов + онлайн (inventory-service).
- [ ] “Умным подбором” (VIN, аналоги, рекомендации) как ключевым преимуществом.
- [ ] Автоматизацией закупок (ABC‑анализ, min/max уровни, черновики закупок).
- [ ] Современным фронтендом под avtosvechi.ru поверх FastAPI API, без ломки Bitrix на старте.

---

## 1) Правила ведения плана (жёстко)
- Чек‑лист только в формате: `- [ ]` / `- [x]`.
- Любая задача становится `- [x]` только если есть проверка (команда/URL) и ожидаемый результат.
- Любые изменения файлов — только полные файлы для вставки в nano (никаких “найди и поправь”).
- Всегда URL только вида `http://192.168.1.100:...` (не localhost).

---

## 2) Текущая фиксация состояния (что уже сделано)

### Инфраструктура / стабильность (DONE на уровне core-стека)
- [x] Core compose: api/postgres/redis/nginx в Up, API `/health` = 200 через Nginx.
  - Проверка:  
    - `curl -sS -i http://192.168.1.100:8080/health` → 200 + `{"status":"ok"}`  
    - `curl -sS -i http://192.168.1.100:8080/api/v1/inventory/status` → 200 + валидный JSON.
- [x] Скрипт деплоя core-стека `~/autoshop/deploy.sh`:
  - Делает `docker compose up -d --remove-orphans --wait`.
  - Проверяет health сервисов и основные эндпоинты.
  - Проверка: `~/autoshop/deploy.sh` завершился без ошибок, `docker compose ps` = все `healthy`.
- [ ] Monitoring stack (Prometheus/Grafana/Alertmanager/cAdvisor/node_exporter) — ВРЕМЕННО ОТКЛЮЧЁН:
  - [ ] Восстановить monitoring отдельным compose в `~/autoshop/monitoring`.
  - [ ] Прописать актуальные URL после восстановления.
- [x] Postgres/Redis закрыты из LAN: порты привязаны к 127.0.0.1 (5432/6379), при этом работа через Cockpit не ломается.

### Продуктовые принципы (принято к разработке)
- [x] Inventory — единственный источник правды по остаткам и статусам доступности.
- [x] VIN/подбор/аналоги/наборы — отдельные эндпоинты API, кэш “горячих” запросов в Redis.
- [x] Закупки — базовая аналитика (ABC + min/max) и черновики заказа, без “тяжёлого ML”.

---

## 3) Дорожная карта на 6 месяцев (по фазам)

### Фаза 1 — Стабилизация и готовность инфраструктуры (недели 1–2)
Цель: любой участник поднимает core‑проект “одной командой”, понимает где логи, и имеет документацию/схему БД.

#### 1.1 Запуск/логирование/операционные проверки
- [x] Сделать единый скрипт запуска core-стека `~/autoshop/deploy.sh` (api/postgres/redis/nginx).
  - Проверка: `~/autoshop/deploy.sh` → все контейнеры `Up (healthy)`, `/health` и `/api/v1/inventory/status` = 200.
- [x] Зафиксировать логи:
  - [x] Репозиторная папка логов: `~/autoshop/logs/` (api/db/nginx/redis).
  - [x] Nginx логи: `~/autoshop/logs/nginx/access.log` и `~/autoshop/logs/nginx/error.log`.
  - [x] Быстрый просмотр docker-логов:  
    - `docker compose logs --no-color --tail=200 api`  
    - `docker compose logs --no-color --tail=200 nginx`
  - Проверка: `ls -la ~/autoshop/logs/nginx` и `docker compose logs --tail=80 api`.
- [x] Smoke-check “одним блоком” для core:
  - Проверка (пример):  
    ```bash
    URL_NGX='http://192.168.1.100:8080'
    curl -sS -i "${URL_NGX}/health"
    curl -sS -i "${URL_NGX}/api/v1/inventory/status"
    ```

#### 1.2 Схема БД для документации
- [x] Снять и сохранить схему таблиц в `project/db_schema.md`:
  - [x] `products`
  - [x] `vehicles`
  - [x] `inventory`
  - [x] `movements`
  - [x] `stock_snapshots`
  - [x] Проверка: файл заполнен и в git.

#### 1.3 Минимальная документация проекта
- [x] `project/README_LOCAL.md`:
  - [x] Как запустить (включая `deploy.sh`).
  - [x] Как проверить здоровье (`/health`, inventory‑эндпоинты).
  - [x] Где логи.
  - [x] Где код (`~/autoshop`, `~/autoshop/api/app`).
  - [x] Какие ключевые эндпоинты уже есть.
  - [x] Проверка: новый участник по документу поднимает проект.

---

### Фаза 2 — Единые остатки и статусы наличия (недели 3–4)
Цель: inventory-service становится “единственной точкой истины” для Bitrix/нового фронта/мобилки.

#### 2.1 Модель данных инвентаря (минимально достаточная)
- [ ] Убедиться/добавить в `inventory`:
  - [ ] `product_id`, `store_id`, `quantity`, `reserved`, `updated_at`
- [x] Убедиться/добавить в `movements`:
  - [x] `product_id`, `store_id`, `movement_type` (inbound/sale/transfer/writeoff), `quantity`, `created_at`
- [x] Убедиться/добавить `stock_snapshots`:
  - [x] периодические снимки остатков
- [ ] Добавить статусы доступности (как минимум):
  - [ ] `on_hand`, `in_transit`, `backorder`, `transfer_1d`
  - [ ] `eta_minutes`/`eta_text` (время поставки/переброски)
- [x] Проверка: миграции применяются, CRUD работает, тестовые данные вставляются.

#### 2.2 API инвентаря (контракт для фронтов)
(все проверки теперь через Nginx: порт 8080)

- [x] GET `/api/v1/inventory/status` — остатки по магазинам + общий итог.
  - Проверка:  
    `curl -sS -i http://192.168.1.100:8080/api/v1/inventory/status` → 200 + валидный JSON.
- [x] GET `/api/v1/inventory/{product_id}` — остаток + статус + ETA по магазинам.
  - Проверка:  
    `curl -sS -i http://192.168.1.100:8080/api/v1/inventory/1` → 200 + валидный JSON (при наличии данных).
- [x] POST `/api/v1/inventory/movement` — логирование движения (продажа/поступление/перемещение/списание).
  - Проверка:  
    - Позитив:  
      `curl -sS -i -X POST http://192.168.1.100:8080/api/v1/inventory/movement -H 'Content-Type: application/json' -d '{"product_id":1,"store_id":1,"movement_type":"sale","quantity":1,"related_document":"test-sale-1"}'` → 200 + JSON с `ok=true` и `movement_id`.  
    - Негатив:  
      `curl -sS -i -X POST http://192.168.1.100:8080/api/v1/inventory/movement -H 'Content-Type: application/json' -d '{"product_id":1,"store_id":1,"movement_type":"writeoff","quantity":999,"related_document":"test-writeoff-too-much"}'` → 409 + `Insufficient stock`.
- [x] GET `/api/v1/inventory/movements?product_id=X&date_from=...` — история движений.
  - Проверка:  
    `curl -sS -i "http://192.168.1.100:8080/api/v1/inventory/movements?product_id=1"` → 200 + JSON, `count>=1` после тестового movement.
- [x] Проверка: curl 200 + валидный JSON, данные отражаются консистентно.

#### 2.3 Логика “переброска”
- [ ] Правило: если в store_1 нет, но в store_2 есть → статус `transfer_1d` и ETA “завтра после 17:00” (или параметризуемое).
- [ ] Проверка: сценарий на тестовых данных.

---

### Фаза 3 — VIN‑поиск, аналоги, рекомендации (недели 5–6)
*(без изменений, кроме ссылок, если будут использоваться HTTP‑проверки — только через 8080)*

… (оставляем как в предыдущей версии, с учётом того, что все HTTP URL при фактической реализации будут через `http://192.168.1.100:8080/...`)

---

### Фаза 4 — Аналитика и автозаказ (недели 7–8)
*(оставляем как было, статус задач см. старый план; URL‑проверки при реализации — через 8080)*

---

### Фаза 5 — Логистика и мультиканальность (недели 9–10)
*(без изменений концептуально)*

---

### Фаза 6 — Новый фронтенд поверх FastAPI (недели 11–12)
*(без изменений, Nginx уже готов для маршрутизации `/` → фронт, `/api/v1/` → FastAPI)*

---

## 4) Monitoring под nginx (отложено)
Цель: единый вход через Nginx.

- [ ] Восстановить monitoring стек в `~/autoshop/monitoring/docker-compose.yml`.
- [ ] Проксирование monitoring под `http://192.168.1.100:8080/monitoring/`.
- [ ] Grafana subpath (root_url + serve_from_sub_path) после настройки nginx.
- [ ] Prometheus subpath (web.external-url / route-prefix) после настройки nginx.

---

## 5) Репозиторий / дисциплина / “Миграция”
- [x] Закоммитить текущие изменения (docker-compose.yml + project/*).
- [x] Зафиксировать процесс “Миграция” в `project/MIGRATION.md` и всегда использовать.

---

## 6) Параллельные задачи (все фазы)
- [ ] Тестирование: еженедельный smoke-check (инфра + базовые API) через 8080.
- [ ] Документация: схема БД + API + бизнес-логика (обновлять по факту изменений).
- [ ] Мониторинг: следить за ошибками и производительностью (после восстановления monitoring-стека).

---

## 7) Метрики успеха (Definition of Success)
- [ ] API отвечает <100ms на стандартные запросы (в рамках LAN/домашнего сервера).
- [ ] Остатки синхронизируются между магазинами “почти в реальном времени”.
- [ ] VIN‑поиск работает и удобнее конкурентов (быстро, понятно, с аналогами).
- [ ] Закупки планируются на основе данных (draft replenishment).
- [ ] avtosvechi.ru загружается <3 сек и корректно работает на мобильных.
