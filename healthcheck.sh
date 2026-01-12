#!/usr/bin/env bash
# healthcheck.sh — комплексный health-check для AUTOSHOP v5.0 (ФИНАЛЬНАЯ ВЕРСИЯ v2)
set -u
TIMESTAMP="$(date +'%Y%m%d_%H%M%S')"
REPORT="healthcheck_${TIMESTAMP}.log"
SUMMARY="healthcheck_summary_${TIMESTAMP}.txt"
echo "Healthcheck started: $(date)" | tee "$REPORT"; echo "Report: $(realpath "$REPORT")" | tee -a "$REPORT"; echo "----------------------------------------" | tee -a "$REPORT"
run() { local title="$1"; shift; echo -e "\n>>>>> ${title} <<<<<" | tee -a "$REPORT"; if "$@" >>"$REPORT" 2>&1; then echo "[OK] ${title}"; else local rc=$?; echo "[ERROR rc=${rc}] ${title}"; fi; }
run "hostnamectl" hostnamectl; run "uptime" uptime; run "df -h" df -h; run "free -h" free -h
if command -v docker >/dev/null 2>&1; then DOCKER_CMD="docker"; echo -e "\nDocker found: $(docker --version)" | tee -a "$REPORT"; if docker compose version >/dev/null 2>&1; then COMPOSE_CMD="docker compose"; elif command -v docker-compose >/dev/null 2>&1; then COMPOSE_CMD="docker-compose"; else COMPOSE_CMD=""; fi; run "docker info (кратко)" docker info --format 'Docker Version: {{.ServerVersion}} | Cgroup: {{.CgroupVersion}} | Storage Driver: {{.Driver}}'; run "docker ps -a" docker ps -a; if [ -n "$COMPOSE_CMD" ]; then echo -e "\nUsing compose: $COMPOSE_CMD" | tee -a "$REPORT"; if [ -f docker-compose.yml ] || [ -f docker-compose.yaml ]; then run "$COMPOSE_CMD ps" $COMPOSE_CMD ps; fi; fi; else echo "Docker is NOT installed or not in PATH" | tee -a "$REPORT"; fi
run "curl http://127.0.0.1:8000/health (API)" curl -fsS --max-time 5 http://127.0.0.1:8000/health
run "curl http://127.0.0.1:9999/health (Shell Agent)" curl -fsS --max-time 5 http://127.0.0.1:9999/health
run "curl http://127.0.0.1:9090/-/ready (Prometheus)" curl -fsS --max-time 5 http://127.0.0.1:9090/-/ready
run "curl http://127.0.0.1:3000/api/health (Grafana)" curl -fsS --max-time 5 http://127.0.0.1:3000/api/health
run "curl -I http://127.0.0.1:8080/ (Nginx)" curl -fsS --max-time 5 -I http://127.0.0.1:8080/
PG_CONTAINER=$(docker ps --format '{{.Names}}' | grep -i -E '^autoshop_db' | head -n1 || true); if [ -n "$PG_CONTAINER" ]; then run "docker exec ${PG_CONTAINER} pg_isready -U autoshop -d autoshop_db" docker exec "$PG_CONTAINER" pg_isready -U autoshop -d autoshop_db; else echo "No running postgres container detected" | tee -a "$REPORT"; fi
REDIS_CONTAINER=$(docker ps --format '{{.Names}}' | grep -i -E '^autoshop_redis' | head -n1 || true); if [ -n "$REDIS_CONTAINER" ]; then run "docker exec ${REDIS_CONTAINER} redis-cli ping" docker exec "$REDIS_CONTAINER" redis-cli ping; else echo "No running redis container detected" | tee -a "$REPORT"; fi
KEY_SERVICES=("api" "postgres" "redis" "nginx" "grafana" "prometheus" "pulse-agent" "immunity-agent" "shell-agent" "telegram-bot"); if command -v docker >/dev/null 2>&1; then for svc in "${KEY_SERVICES[@]}"; do CONTAINER="$(docker ps --format '{{.Names}}' | grep -i "$svc" | head -n1 || true)"; if [ -n "$CONTAINER" ]; then echo -e "\n>>>> Docker logs for ${CONTAINER} (last 50 lines) <<<<" | tee -a "$REPORT"; docker logs --tail 50 "$CONTAINER" >>"$REPORT" 2>&1 || true; fi; done; fi
run "crontab -l" crontab -l; run "ls -la /etc/cron.*" ls -la /etc/cron.*; BACKUP_DIRS=("$HOME/autoshop/backups" "/mnt/usb/autoshop-backups" "/mnt/backup" "/var/backups"); echo -e "\n>>>> Backup dirs <<<<" | tee -a "$REPORT"; for d in "${BACKUP_DIRS[@]}"; do if [ -d "$d" ]; then echo "Contents of $d:" >>"$REPORT"; ls -lah "$d" | head -n 20 >>"$REPORT" 2>&1 || true; fi; done
if [ -d tests ] && command -v pytest >/dev/null 2>&1; then run "pytest -q" pytest -q --maxfail=1; else echo "pytest not run: tests/ missing or pytest not installed" | tee -a "$REPORT"; fi

# --- ИНТЕГРИРОВАН НОВЫЙ "УМНЫЙ" ФИЛЬТР ---
echo -e "\n----------------------------------------" | tee -a "$REPORT"
echo "Generating intelligent summary..."
# Ищем error/fail/warn, а затем убираем весь HTML-шум
grep -niE "error|fail|warn" "$REPORT" \
  | grep -viE "<[^>]+>" \
  | grep -viE "pf-c-alert|dialog-error|noscript|aria-label" \
  > "$SUMMARY" || true

echo "----"
if [ -s "$SUMMARY" ]; then
  echo -e "\nSummary (найдены потенциальные проблемы):"
  cat "$SUMMARY"
else
  echo -e "\nSummary: No significant errors or warnings found. System is clean."
fi

echo -e "\nHealthcheck completed: $(date)" | tee -a "$REPORT"
echo "Full report: $(realpath "$REPORT")"
echo "Summary (error-like lines): $(realpath "$SUMMARY")"
exit 0
