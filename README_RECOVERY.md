# README_RECOVERY — AVTOSVECHI / AUTOSHOP (Аварийное восстановление)

Дата актуализации: 21.12.2025  
Сервер: avtosvechi-server  
Проект: ~/autoshop  
Вход через nginx: http://192.168.1.100:8080

## 1) Быстрая проверка (30 секунд)

cd ~/autoshop
./check-prod.sh

Ожидаем:
- GET http://192.168.1.100:8080/health -> 200
- GET http://192.168.1.100:8080/ready -> 200
- GET http://192.168.1.100:8080/api/v1/inventory/status -> 200
- /docs открывается
- Alembic внутри ./check-prod.sh: alembic current/heads/check и строка No new upgrade operations detected.

## 2) Самый быстрый откат (рекомендуется)

Актуальная стабильная точка:
- v1.0.8-ops-alembic-stable (рекомендуется)

cd ~/autoshop
./restore-from-tag.sh v1.0.8-ops-alembic-stable

Примечание: restore делает git checkout на тег, это "detached HEAD" — нормально.

После восстановления (если нужно вернуться к разработке):
cd ~/autoshop
git switch main

## 3) Ручной DB-патч (legacy / если требуется)

Исторически часть схемы БД фиксировалась вручную (users + stores + внешние ключи).
Если восстановление делается на новом сервере/пустой БД и таблиц нет, применить патч:

cd ~/autoshop
docker exec -i autoshop_db psql -U autoshop -d autoshop_db < SCHEMA_PATCH_20251221_fk_users_stores.sql

Проверка:
docker exec -it autoshop_db psql -U autoshop -d autoshop_db -c "\dt"
docker exec -it autoshop_db psql -U autoshop -d autoshop_db -c "\d current_inventory"
docker exec -it autoshop_db psql -U autoshop -d autoshop_db -c "\d movements"

## 4) Если restore не стартует (git не чистый)

Скрипт restore требует чистое дерево.

Проверка:
cd ~/autoshop
git status

Варианты:
- Закоммитить изменения (WIP)
- Или временно убрать их:
  cd ~/autoshop
  git stash -u

Затем повторить:
cd ~/autoshop
./restore-from-tag.sh v1.0.8-ops-alembic-stable

## 5) Если /health=200, но /api/v1/*=404

Симптом: nginx отвечает 404 на /api/v1/*, при этом API напрямую работает.

Проверка:
curl -sS -i http://192.168.1.100:8080/api/v1/inventory/status
curl -sS -i http://127.0.0.1:8000/api/v1/inventory/status

Причина (типовая): неправильно настроен proxy_pass и ломается URI при проксировании.  
Правило nginx: чтобы передать URI "как есть", proxy_pass должен быть без URI-части (например, proxy_pass http://api;).

## 6) Быстрый диагноз "что реально применено"

1) Реальный nginx-конфиг внутри контейнера:
cd ~/autoshop
docker exec autoshop_nginx nginx -T 2>&1 | grep -i "upstream\|server\|location"

2) Проверка, что nginx.conf смонтирован с хоста:
cd ~/autoshop
docker inspect autoshop_nginx | grep -A 40 '"Mounts"'

Конец документа.
