# 🚀 **ВОССТАНОВИТЬ СИСТЕМУ ИЗ БЭКАПА** (ПУНКТ 11)

## 📝 **ПРОЦЕСС (3 минуты)**
1. **Код** ← `git pull origin master` (GitHub avtosvechi-system)
2. **БД** ← выбранный дамп из `~/autoshop/backups/`
3. **Перезапуск** ← `docker compose up -d --build`

## 🔍 **1. ПОСЛЕДНИЕ 3 ТОЧКИ ВОССТАНОВЛЕНИЯ**
```bash
cd ~/autoshop
echo "🔍 ПОСЛЕДНИЕ 3 ТОЧКИ ВОССТАНОВЛЕНИЯ:"
echo ""
counter=1
ls -lt backups/db_dump_*.sql.gz | head -3 | while read -r perm links user group size month day time filename; do
  timestamp=$(echo "$filename" | grep -o '202[0-9]-[0-9][0-9]-[0-9][0-9]_[0-9][0-9]-[0-9][0-9]-[0-9][0-9]')
  human_date=$(echo "$month $day $time" | sed 's/://g')
  
  echo "$counter. $filename"
  echo "   📅 Создана: $human_date"
  echo "   📦 Размер: ${size}B"
  echo "   💾 Код: code_snapshot_${timestamp}.tar.gz"
  echo "   🏷️  Описание: Восстановление системы"
  echo ""
  
  ((counter++))
done
```

## ⚡ **2. КОМАНДА ВОССТАНОВЛЕНИЯ ИЗ ПОСЛЕДНЕЙ ТОЧКИ**
```bash
cd ~/autoshop

# 1. Остановка
echo "🛑 1/4 Остановка..."
docker compose down -v

# 2. Код из GitHub (master всегда чистый)
echo "📥 2/4 Код из GitHub..."
git reset --hard origin/master
git pull

# 3. БД из последнего бэкапа
echo "💾 3/4 Восстановление БД..."
LATEST_DB=$(ls -t backups/db_dump_*.sql.gz | head -1)
echo "→ Используем: $LATEST_DB"
docker compose up -d postgres
sleep 15
gunzip -c "$LATEST_DB" | docker compose exec -T postgres psql -U autoshop -d autoshop_db

# 4. Полный запуск
echo "▶️ 4/4 Запуск системы..."
docker compose up -d --build
sleep 20
```

## 🧪 **3. ТЕСТ ПРОВЕРКИ УСПЕШНОСТИ ВОССТАНОВЛЕНИЯ**
```bash
cd ~/autoshop
echo "🧪 ПРОВЕРКА ВОССТАНОВЛЕНИЯ:"

# 1. Контейнеры
CONTAINERS=$(docker compose ps | grep Up | wc -l)
if [ "$CONTAINERS" -ge 8 ]; then
  echo "✅ Контейнеры: $CONTAINERS/9 UP"
else
  echo "❌ Контейнеры: только $CONTAINERS/9"
fi

# 2. API здоровье
if curl -s http://localhost:8000/health | grep -q '"status":"ok"'; then
  echo "✅ API healthy"
else
  echo "❌ API DOWN"
fi

# 3. Проверка данных в БД
DB_CHECK=$(docker compose exec -T postgres psql -U autoshop -d autoshop_db -c "SELECT COUNT(*) FROM parts;" 2>/dev/null | grep -E '[0-9]+' | head -1)
if [ -n "$DB_CHECK" ] && [ "$DB_CHECK" -gt 0 ] 2>/dev/null; then
  echo "✅ БД: $DB_CHECK SKU"
else
  echo "❌ БД пуста"
fi

# Итог
if [ "$CONTAINERS" -ge 8 ] && curl -s http://localhost:8000/health | grep -q '"status":"ok"' && [ -n "$DB_CHECK" ] && [ "$DB_CHECK" -gt 0 ] 2>/dev/null; then
  echo "🎉 ВОССТАНОВЛЕНИЕ УСПЕШНО! Все 3 проверки пройдены."
else
  echo "⚠️  ВОССТАНОВЛЕНИЕ ИМЕЕТ ПРОБЛЕМЫ"
fi
```

## 📋 **КРИТЕРИИ УСПЕХА**
1. ✅ Все контейнеры запущены (8+ из 9)
2. ✅ API отвечает со статусом 200 и "ok"
3. ✅ База данных содержит записи (>0 SKU)

**Успех = все 3 ✅**
