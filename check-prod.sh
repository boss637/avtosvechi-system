#!/usr/bin/env bash
set -u

cd ~/autoshop

URL_NGX="http://192.168.1.100:8080"

echo "== AVTOSVECHI / AUTOSHOP PROD CHECK =="
date
echo

echo "== compose ps =="
docker compose ps
echo

echo "== nginx checks (via 8080) =="
curl -fsS -i "${URL_NGX}/health"
echo
curl -fsS -i "${URL_NGX}/ready"
echo
curl -fsS -i "${URL_NGX}/api/v1/inventory/status"
echo
curl -fsS -i "${URL_NGX}/docs" >/dev/null
echo "docs: OK"
echo

echo "== api direct (host -> published 8000) =="
curl -fsS -i "http://127.0.0.1:8000/health"
echo
curl -fsS -i "http://127.0.0.1:8000/api/v1/inventory/status"
echo

echo "== alembic checks (api container) =="
docker exec -it autoshop_api sh -lc "cd /app && alembic current && alembic heads && alembic check"
echo

echo "== effective compose snapshot =="
ARCHIVE="ARCHIVE-effective-compose-$(date +%Y%m%d-%H%M%S).yml"
docker compose config > "${ARCHIVE}"
echo "saved: ${ARCHIVE}"
echo

echo "== nginx active config (container) =="
docker exec autoshop_nginx nginx -T 2>&1 | grep -i "upstream\|location" || true
echo

echo "== nginx mounts (container) =="
docker inspect autoshop_nginx | grep -A 60 '"Mounts"' || true
echo

echo "== cleanup local snapshots =="
rm -f "${ARCHIVE}" || true
echo "removed: ${ARCHIVE}"
echo

echo "== RESULT: OK =="
