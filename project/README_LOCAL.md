# AVTOSVECHI / AUTOSHOP — локальный запуск

Документ для разработчиков проекта AVTOSVECHI / AUTOSHOP: как локально поднять backend (FastAPI + Postgres + Redis + Nginx) и проверить его работоспособность.

## 1. Предусловия

- Установлены Docker и Docker Compose.
- Код проекта находится в каталоге `~/autoshop` на сервере `avtosvechi-server`.
- Рабочие URL:
  - API docs: `http://192.168.1.100:8000/docs`
  - API health: `http://192.168.1.100:8000/health`
  - Nginx: `http://192.168.1.100:8080/`
  - Grafana: `http://192.168.1.100:3000/`
  - Prometheus: `http://192.168.1.100:9091/`

## 2. Как запустить проект

### 2.1. Запуск core + monitoring

Рекомендуемый способ — через единый скрипт:

~~~bash
cd ~/autoshop
~/autoshop-start.sh
~~~

Скрипт поднимает:
- backend стек: `api`, `postgres`, `redis`, `nginx`;
- monitoring стек: Prometheus, Grafana и связанные сервисы.

### 2.2. Проверка состояния контейнеров

~~~bash
cd ~/autoshop
docker compose ps
~~~

Ожидается, что:
- `autoshop_api` — `Up` (healthy или health: starting при первом старте);
- `autoshop_db` — `Up (healthy)`;
- `autoshop_redis` — `Up (healthy)`;
- `autoshop_nginx` — `Up`.

## 3. Как проверить здоровье

### 3.1. Быстрый smoke-check (ежедневно)

~~~bash
~/autoshop-smoke.sh
~~~

Скрипт проверяет:
- `http://192.168.1.100:8000/health` → HTTP 200;
- `http://192.168.1.100:8000/docs` → HTTP 200;
- `http://192.168.1.100:3000/` → HTTP 302 (редирект Grafana);
- `http://192.168.1.100:9091/-/ready` → HTTP 200 (Prometheus ready);
- `http://192.168.1.100:9091/api/v1/targets` → Prometheus возвращает статус `success`, targets в состоянии UP.

### 3.2. Ручные проверки API

~~~bash
curl -i http://192.168.1.100:8000/health
curl -i http://192.168.1.100:8000/docs
~~~

Ожидается:
- `/health` — HTTP 200 и краткий JSON/текст о состоянии сервера;
- `/docs` — Swagger UI FastAPI.

## 4. Где искать логи

### 4.1. Логи Nginx

На хосте:

~~~bash
ls -la ~/autoshop/logs/nginx
tail -n 100 ~/autoshop/logs/nginx/access.log
tail -n 100 ~/autoshop/logs/nginx/error.log
~~~

Nginx проксирует запросы к API и статику, поэтому при ошибках 4xx/5xx сначала смотрим сюда.

### 4.2. Логи API и Nginx через Docker

~~~bash
cd ~/autoshop
docker compose logs --no-color --tail=200 api
docker compose logs --no-color --tail=200 nginx
~~~

Полезно для поиска traceback'ов FastAPI и ошибок проксирования.

## 5. Где код

- Backend API: `~/autoshop/api/app`
  - Точка входа: `app.main` (FastAPI, Uvicorn).
  - Миграции Alembic: `~/autoshop/api/alembic`.
- Инфраструктура:
  - Docker Compose: `~/autoshop/docker-compose.yml`
  - Nginx конфиг: `~/autoshop/nginx.conf`
  - Скрипты запуска/проверки: `~/autoshop-start.sh`, `~/autoshop-smoke.sh`

## 6. Схема БД

Актуальная структура схемы `public` зафиксирована в:

- `project/db_schema.md` — дамп `pg_dump --schema-only -n public autoshop_db`.

При изменении моделей/миграций:
1. Прогнать Alembic миграции в контейнере `api`.
2. Обновить дамп `db_schema.md` по инструкции внутри файла.
3. Закоммитить изменения в Git.
