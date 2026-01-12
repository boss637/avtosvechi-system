#!/usr/bin/env bash
set -euo pipefail

cd ~/autoshop

TAG="${1:-v1.0-stable-healthy}"
URL_NGX="http://192.168.1.100:8080"

echo "== RESTORE START =="
date
echo "tag: ${TAG}"
echo

echo "== precheck: working dir =="
pwd
echo

echo "== precheck: git status (must be clean) =="
git status --porcelain
if [ -n "$(git status --porcelain)" ]; then
  echo "ERROR: working tree is not clean. Commit or stash changes, then retry."
  echo "Hint: git add -A && git commit -m 'WIP'  OR  git stash -u"
  exit 1
fi
echo "OK: working tree clean"
echo

echo "== git fetch tags =="
git fetch --tags
echo

echo "== git checkout tag (detached HEAD is expected) =="
git checkout "${TAG}"
echo

echo "== stop stack =="
docker compose down
echo

echo "== remove api image (force rebuild from this tag) =="
docker image rm autoshop-api || true
echo

echo "== start stack (build) =="
docker compose up -d --build
echo

echo "== wait for services =="
sleep 40
echo

echo "== compose ps =="
docker compose ps
echo

echo "== verify via nginx =="
curl -fsS -i "${URL_NGX}/health"
echo
curl -fsS -i "${URL_NGX}/ready"
echo
curl -fsS -i "${URL_NGX}/api/v1/inventory/status"
echo

echo "== verify docs =="
curl -fsS -i "${URL_NGX}/docs" >/dev/null
echo "docs: OK"
echo

echo "== RESTORE RESULT: OK =="
