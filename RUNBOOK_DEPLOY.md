# RUNBOOK_DEPLOY — AVTOSVECHI / AUTOSHOP

Дата актуализации: 21.12.2025

Цель: быстрый и предсказуемый деплой/откат, без “магии” Docker/Compose и без повторения граблей.

---

## 0) Золотое правило рабочего каталога

Все команды docker compose выполнять ТОЛЬКО из каталога проекта:

cd ~/autoshop

Иначе получите:
docker compose ... -> no configuration file provided: not found (Compose не нашёл compose-файл).

---

## 1) Базовая проверка прод-статуса

1) Статус контейнеров:
docker compose ps

2) Проверка через nginx (только такие URL используем):
curl -sS -i http://192.168.1.100:8080/health
curl -sS -i http://192.168.1.100:8080/ready
curl -sS -i http://192.168.1.100:8080/api/v1/inventory/status
curl -sS http://192.168.1.100:8080/docs

Если /health=200, но /api/v1/*=404 — почти всегда проблема в nginx proxy rules (proxy_pass / trailing slash).

---

## 2) “Эффективная” конфигурация Compose (снапшот)

Compose может мерджить конфиги (несколько файлов, env substitution и т.д.), поэтому всегда полезно иметь слепок “как реально запущено”:

docker compose config > ARCHIVE-effective-compose.yml

Это помогает доказать, что реально было применено (volumes, ports, command, env).

Важно:
- ARCHIVE-effective-compose-*.yml у нас игнорируется через .gitignore (это локальная диагностика, не артефакт репозитория).

---

## 3) Проверка реального nginx-конфига (как видит контейнер)

Если nginx ведёт себя странно — смотрим конфиг из контейнера:

docker exec autoshop_nginx nginx -T 2>&1 | grep -i "upstream\|server\|location"

И проверяем mount’ы (не подменён ли nginx.conf):

docker inspect autoshop_nginx | grep -A 40 '"Mounts"'

Важно:
- bind mount может “скрывать” содержимое из образа и показывать то, что на хосте.

---

## 4) Правильный шаблон nginx для прокси

Надёжный и простой вариант (из практики проекта):
- upstream на сервис api:8000
- catch-all прокси на backend

Признак правильной схемы:
- location / { proxy_pass http://api; }

Нюанс:
- trailing slash в proxy_pass меняет URI и может ломать префиксные location /api/.

---

## 5) Процедура “одно изменение → проверка → commit”

Алгоритм:
1) Зафиксировать текущий статус:
docker compose ps
curl -sS -i http://192.168.1.100:8080/health

2) Сделать ровно одно изменение (например nginx.conf)

3) Применить:
docker compose restart nginx

4) Проверить:
curl -sS -i http://192.168.1.100:8080/health
curl -sS -i http://192.168.1.100:8080/api/v1/inventory/status

5) Если ОК — commit + push.

---

## 6) Откат к тегу (точка восстановления)

Важное:
- Тег — это “якорь” восстановления, но рантайм всё равно зависит от того, какие файлы смонтированы volumes.
- Откат делает git checkout на тег (detached HEAD) — это ожидаемо.

Откат (через наш скрипт, рекомендуемый вариант):
./restore-from-tag.sh v1.0.1-ops

Откат (вручную):

cd ~/autoshop
git fetch --tags
git checkout v1.0.1-ops
docker compose down
docker image rm autoshop-api || true
docker compose up -d --build

Проверка:
curl -sS -i http://192.168.1.100:8080/health
curl -sS -i http://192.168.1.100:8080/api/v1/inventory/status

После отката на тег (если нужно вернуться в разработку):
git switch main

---

## 7) “Почему откат не помогает” — чек-лист

Если git checkout на “стабильную точку” не вернул стабильность:

1) Убедиться, что команды выполняются из ~/autoshop (иначе compose вообще не тот).
2) Снять docker compose config и проверить volumes.
3) Проверить docker inspect autoshop_nginx Mounts: не подменяется ли nginx.conf.
4) Снять nginx -T из контейнера: что реально активировано.
5) Проверить backend напрямую (на хосте):
   curl -sS -i http://127.0.0.1:8000/health
   curl -sS -i http://127.0.0.1:8000/api/v1/inventory/status

---

## 8) Быстрый “сбор пакета диагностики” для нового чата

cd ~/autoshop

echo "== git status ==" && git status
echo "== git log -5 ==" && git log --oneline -5
echo "== compose ps ==" && docker compose ps

echo "== nginx via 8080 ==" &&
curl -sS -i http://192.168.1.100:8080/health || true
curl -sS -i http://192.168.1.100:8080/api/v1/inventory/status || true

echo "== api direct from host ==" &&
curl -sS -i http://127.0.0.1:8000/health || true
curl -sS -i http://127.0.0.1:8000/api/v1/inventory/status || true

echo "== effective compose ==" &&
docker compose config > ARCHIVE-effective-compose.yml &&
wc -l ARCHIVE-effective-compose.yml

echo "== nginx -T (container) ==" &&
docker exec autoshop_nginx nginx -T 2>&1 | grep -i "upstream\|location" || true

echo "== nginx mounts ==" &&
docker inspect autoshop_nginx | grep -A 40 '"Mounts"' || true

---

## 9) Что считаем “стабильной точкой”

Стабильная точка = выполнены условия:
- Есть git tag
- Есть commit с nginx.conf / docker-compose.yml
- Есть локальная диагностика (ARCHIVE-effective-compose.yml по необходимости)
- /health и /api/v1/inventory/status дают 200 через nginx

Primary restore tag (боевой): v1.0.1-ops
Legacy/partial tag: v1.0-stable-healthy (исторический; не гарантирует /api/v1 через nginx)

Конец документа.
