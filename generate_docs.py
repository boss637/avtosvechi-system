#!/usr/bin/env python3
"""
Скрипт для генерации документации Триады Агентов
"""

import os

def create_trinity_plan():
    """Создает план Триады Агентов"""
    content = """# План: «Триада — Промышленный Стандарт» (v.5.0)

## Архитектура:
1. 👁️ Watcher Agent - мониторинг (порт 9090)
2. 🤖 Executor Agent - Telegram бот
3. 🧠 Solver Agent - автоматизация (порт 8080)

## Статус: ВЫПОЛНЕНО
- ✅ База данных создана
- ✅ Все агенты реализованы
- ✅ Docker конфигурация обновлена
- ✅ Документация создана

## Для запуска:
1. Настройте .env файл
2. Запустите: docker compose up -d --build
3. Проверьте: docker compose ps

## Доступ:
- Метрики: http://localhost:9090/metrics
- Health: http://localhost:8080/health
- Бот: Найдите в Telegram
"""
    
    os.makedirs("docs", exist_ok=True)
    with open("docs/TRINITY_AGENTS_PLAN.md", "w") as f:
        f.write(content)
    
    print("✅ TRINITY_AGENTS_PLAN.md создан")

def create_deployment_guide():
    """Создает руководство по развертыванию"""
    content = """# Руководство по развертыванию

## Быстрый старт:
1. cp .env.example .env
2. Заполните TELEGRAM_TOKEN
3. docker compose up -d --build
4. docker compose ps

## Проверка:
- curl http://localhost:9090/metrics
- curl http://localhost:8080/health
- Команда /start в Telegram боте

## Устранение неполадок:
1. Проверьте .env файл
2. Проверьте логи: docker compose logs
3. Перезапустите: docker compose restart
"""
    
    with open("docs/DEPLOYMENT_GUIDE.md", "w") as f:
        f.write(content)
    
    print("✅ DEPLOYMENT_GUIDE.md создан")

def update_readme():
    """Обновляет README.md"""
    try:
        with open("README.md", "a") as f:
            f.write("\n\n## 🏗️ Триада Агентов (v5.0)\n")
            f.write("Промышленная система мониторинга и автоматизации.\n")
            f.write("- 👁️ Watcher Agent: мониторинг и метрики\n")
            f.write("- 🤖 Executor Agent: управление через Telegram\n")
            f.write("- 🧠 Solver Agent: автоматическое решение проблем\n")
            f.write("\n[Подробный план](./docs/TRINITY_AGENTS_PLAN.md)\n")
        
        print("✅ README.md обновлен")
    except:
        print("⚠️ README.md не обновлен (возможно, файл не существует)")

if __name__ == "__main__":
    print("Генерация документации Триады Агентов...")
    create_trinity_plan()
    create_deployment_guide()
    update_readme()
    print("🎉 Документация создана!")
