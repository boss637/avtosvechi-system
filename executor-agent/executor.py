#!/usr/bin/env python3
"""
Промышленный Telegram-бот (Executor Agent)
Команды для управления системой, rate-limiting, аудит действий
"""

import os
import sys
import logging
import time
import hashlib
import psycopg2
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple
from telegram import Update, InlineKeyboardButton, InlineKeyboardMarkup
from telegram.ext import (
    Application, CommandHandler, MessageHandler, filters,
    ContextTypes, CallbackQueryHandler
)

# Конфигурация
TELEGRAM_TOKEN = os.getenv("TELEGRAM_TOKEN", "")
if not TELEGRAM_TOKEN:
    print("ОШИБКА: TELEGRAM_TOKEN не установлен!")
    sys.exit(1)

ALLOWED_USER_IDS = list(map(int, os.getenv("ALLOWED_USER_IDS", "").split(","))) if os.getenv("ALLOWED_USER_IDS") else []

DB_CONFIG = {
    "host": os.getenv("POSTGRES_HOST", "db"),
    "port": os.getenv("POSTGRES_PORT", "5432"),
    "database": os.getenv("POSTGRES_DB", "autoshop_db"),
    "user": os.getenv("POSTGRES_USER", "autoshop"),
    "password": os.getenv("POSTGRES_PASSWORD", "autoshop")
}

# Rate limiting: максимум 5 команд в минуту на пользователя
RATE_LIMIT = {"max_commands": 5, "time_window": 60}

class RateLimiter:
    """Класс для ограничения частоты запросов"""
    
    def __init__(self):
        self.user_requests: Dict[int, List[float]] = {}
    
    def is_allowed(self, user_id: int) -> Tuple[bool, Optional[float]]:
        """Проверяет, может ли пользователь выполнить команду"""
        now = time.time()
        
        if user_id not in self.user_requests:
            self.user_requests[user_id] = []
        
        # Удаляем старые запросы вне временного окна
        window_start = now - RATE_LIMIT["time_window"]
        self.user_requests[user_id] = [t for t in self.user_requests[user_id] if t > window_start]
        
        # Проверяем лимит
        if len(self.user_requests[user_id]) < RATE_LIMIT["max_commands"]:
            self.user_requests[user_id].append(now)
            return True, None
        
        # Вычисляем время ожидания
        next_allowed = self.user_requests[user_id][0] + RATE_LIMIT["time_window"]
        wait_time = next_allowed - now
        return False, wait_time

class ExecutorBot:
    """Основной класс Telegram-бота"""
    
    def __init__(self):
        self.setup_logging()
        self.rate_limiter = RateLimiter()
        self.logger.info("Executor Bot инициализирован")
    
    def setup_logging(self):
        """Настройка логирования"""
        self.logger = logging.getLogger("executor_bot")
        self.logger.setLevel(logging.INFO)
        
        formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S'
        )
        
        console_handler = logging.StreamHandler()
        console_handler.setFormatter(formatter)
        self.logger.addHandler(console_handler)
    
    def audit_log(self, user_id: int, command: str, result: str = None):
        """Запись действия в лог аудита"""
        try:
            conn = psycopg2.connect(**DB_CONFIG)
            cursor = conn.cursor()
            
            cursor.execute("""
                INSERT INTO audit_log_executor (user_id, command, result)
                VALUES (%s, %s, %s)
            """, (user_id, command, result))
            
            conn.commit()
            cursor.close()
            conn.close()
            
            self.logger.info(f"Аудит: user_id={user_id}, command={command}")
            
        except Exception as e:
            self.logger.error(f"Ошибка записи в аудит-лог: {str(e)}")
    
    async def start(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Обработчик команды /start"""
        user_id = update.effective_user.id
        
        # Проверка доступа
        if ALLOWED_USER_IDS and user_id not in ALLOWED_USER_IDS:
            await update.message.reply_text("⛔ Доступ запрещен.")
            self.audit_log(user_id, "/start", "access_denied")
            return
        
        # Rate limiting
        allowed, wait_time = self.rate_limiter.is_allowed(user_id)
        if not allowed:
            await update.message.reply_text(
                f"⚠️ Слишком много запросов. Подождите {int(wait_time)} секунд."
            )
            return
        
        welcome_text = """
🤖 *Autoshop Executor Bot* (v5.0)

*Доступные команды:*
/help - Показать это сообщение
/status - Статус системы
/incidents - Последние инциденты
/restart [service] - Перезапустить сервис
/backup - Создать резервную копию
/logs [service] - Показать логи сервиса

📊 *Триада Агентов:*
• 👁️ Watcher-agent (мониторинг)
• 🤖 Executor-agent (эта панель)
• 🧠 Solver-agent (автоматизация)

_Версия: Промышленный стандарт_
        """
        
        keyboard = [
            [InlineKeyboardButton("📊 Статус", callback_data="status"),
             InlineKeyboardButton("🚨 Инциденты", callback_data="incidents")],
            [InlineKeyboardButton("🔄 Перезапуск", callback_data="restart_menu"),
             InlineKeyboardButton("💾 Бэкап", callback_data="backup")],
            [InlineKeyboardButton("📋 Помощь", callback_data="help")]
        ]
        reply_markup = InlineKeyboardMarkup(keyboard)
        
        await update.message.reply_text(
            welcome_text,
            parse_mode='Markdown',
            reply_markup=reply_markup
        )
        self.audit_log(user_id, "/start", "success")
    
    async def help_command(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Обработчик команды /help"""
        user_id = update.effective_user.id
        
        if ALLOWED_USER_IDS and user_id not in ALLOWED_USER_IDS:
            return
        
        allowed, wait_time = self.rate_limiter.is_allowed(user_id)
        if not allowed:
            await update.message.reply_text(
                f"⚠️ Слишком много запросов. Подождите {int(wait_time)} секунд."
            )
            return
        
        help_text = """
*📋 Доступные команды:*

*Основные команды:*
/start - Запустить бота
/help - Показать это сообщение
/status - Статус всех сервисов
/incidents - Последние 10 инцидентов

*Управление сервисами:*
/restart [api|shell-agent|watcher] - Перезапустить сервис
/logs [service] [lines] - Логи сервиса (по умолчанию 50 строк)

*Резервное копирование:*
/backup - Создать точку восстановления
/list_backups - Список точек восстановления

*Примеры:*
`/restart api` - Перезапустить API
`/logs watcher 100` - 100 строк логов watcher-agent
`/backup "важное обновление"` - Бэкап с описанием

*Rate limiting:* максимум 5 команд в минуту
        """
        
        await update.message.reply_text(help_text, parse_mode='Markdown')
        self.audit_log(user_id, "/help", "success")
    
    async def status_command(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Обработчик команды /status"""
        user_id = update.effective_user.id
        
        if ALLOWED_USER_IDS and user_id not in ALLOWED_USER_IDS:
            return
        
        allowed, wait_time = self.rate_limiter.is_allowed(user_id)
        if not allowed:
            await update.message.reply_text(
                f"⚠️ Слишком много запросов. Подождите {int(wait_time)} секунд."
            )
            return
        
        try:
            # Проверяем статусы сервисов
            services = [
                ("API", "http://api:8000/health"),
                ("Shell Agent", "http://shell-agent:8001/health"),
                ("Watcher Agent", "http://watcher-agent:9090/health")
            ]
            
            status_text = "📊 *Статус системы Autoshop:*\n\n"
            
            for service_name, url in services:
                try:
                    response = requests.get(url, timeout=3)
                    if response.status_code == 200:
                        status_text += f"✅ *{service_name}*: Работает\n"
                    else:
                        status_text += f"❌ *{service_name}*: Ошибка HTTP {response.status_code}\n"
                except Exception as e:
                    status_text += f"❌ *{service_name}*: Недоступен ({str(e)})\n"
            
            # Информация из БД
            try:
                conn = psycopg2.connect(**DB_CONFIG)
                cursor = conn.cursor()
                
                cursor.execute("SELECT COUNT(*) FROM incidents WHERE status = 'new'")
                new_incidents = cursor.fetchone()[0]
                
                cursor.execute("SELECT COUNT(*) FROM incidents")
                total_incidents = cursor.fetchone()[0]
                
                cursor.execute("SELECT COUNT(*) FROM audit_log_executor")
                audit_entries = cursor.fetchone()[0]
                
                cursor.close()
                conn.close()
                
                status_text += f"\n📈 *Статистика:*\n"
                status_text += f"• Новых инцидентов: {new_incidents}\n"
                status_text += f"• Всего инцидентов: {total_incidents}\n"
                status_text += f"• Записей аудита: {audit_entries}\n"
                
            except Exception as e:
                status_text += f"\n⚠️ *Ошибка БД:* {str(e)}\n"
            
            status_text += f"\n🕐 *Время сервера:* {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
            
            await update.message.reply_text(status_text, parse_mode='Markdown')
            self.audit_log(user_id, "/status", "success")
            
        except Exception as e:
            await update.message.reply_text(f"❌ Ошибка при проверке статуса: {str(e)}")
            self.audit_log(user_id, "/status", f"error: {str(e)}")
    
    async def incidents_command(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Обработчик команды /incidents"""
        user_id = update.effective_user.id
        
        if ALLOWED_USER_IDS and user_id not in ALLOWED_USER_IDS:
            return
        
        allowed, wait_time = self.rate_limiter.is_allowed(user_id)
        if not allowed:
            await update.message.reply_text(
                f"⚠️ Слишком много запросов. Подождите {int(wait_time)} секунд."
            )
            return
        
        try:
            conn = psycopg2.connect(**DB_CONFIG)
            cursor = conn.cursor()
            
            cursor.execute("""
                SELECT service_name, error_type, status, created_at 
                FROM incidents 
                ORDER BY created_at DESC 
                LIMIT 10
            """)
            
            incidents = cursor.fetchall()
            cursor.close()
            conn.close()
            
            if not incidents:
                await update.message.reply_text("🚫 Инцидентов не обнаружено")
            else:
                incidents_text = "🚨 *Последние 10 инцидентов:*\n\n"
                
                for i, (service, error_type, status, created_at) in enumerate(incidents, 1):
                    time_str = created_at.strftime('%H:%M:%S') if isinstance(created_at, datetime) else str(created_at)
                    
                    status_icon = "🟡" if status == "new" else "🟢" if status == "resolved" else "🔵"
                    incidents_text += f"{i}. *{service}* - {error_type}\n"
                    incidents_text += f"   {status_icon} {status} | 🕐 {time_str}\n\n"
                
                await update.message.reply_text(incidents_text, parse_mode='Markdown')
            
            self.audit_log(user_id, "/incidents", f"found_{len(incidents)}")
            
        except Exception as e:
            await update.message.reply_text(f"❌ Ошибка при получении инцидентов: {str(e)}")
            self.audit_log(user_id, "/incidents", f"error: {str(e)}")
    
    async def button_callback(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Обработчик нажатий кнопок"""
        query = update.callback_query
        await query.answer()
        
        user_id = query.from_user.id
        
        if ALLOWED_USER_IDS and user_id not in ALLOWED_USER_IDS:
            await query.edit_message_text("⛔ Доступ запрещен.")
            return
        
        allowed, wait_time = self.rate_limiter.is_allowed(user_id)
        if not allowed:
            await query.edit_message_text(
                f"⚠️ Слишком много запросов. Подождите {int(wait_time)} секунд."
            )
            return
        
        if query.data == "status":
            # Имитируем команду /status
            await self.status_command(update, context)
        elif query.data == "incidents":
            # Имитируем команду /incidents
            await self.incidents_command(update, context)
        elif query.data == "help":
            await self.help_command(update, context)
        elif query.data == "restart_menu":
            keyboard = [
                [InlineKeyboardButton("API", callback_data="restart_api"),
                 InlineKeyboardButton("Shell Agent", callback_data="restart_shell")],
                [InlineKeyboardButton("Watcher", callback_data="restart_watcher"),
                 InlineKeyboardButton("Назад", callback_data="back_to_main")]
            ]
            reply_markup = InlineKeyboardMarkup(keyboard)
            await query.edit_message_text(
                "🔄 Выберите сервис для перезапуска:",
                reply_markup=reply_markup
            )
        elif query.data.startswith("restart_"):
            service = query.data.replace("restart_", "")
            await query.edit_message_text(f"🔄 Перезапуск {service}...")
            # Здесь будет реальная логика перезапуска
            time.sleep(1)
            await query.edit_message_text(f"✅ Сервис {service} перезапущен (заглушка)")
            self.audit_log(user_id, f"/restart {service}", "stub_success")
        elif query.data == "backup":
            await query.edit_message_text("💾 Создание бэкапа...")
            # Здесь будет реальная логика бэкапа
            time.sleep(1)
            await query.edit_message_text("✅ Бэкап создан (заглушка)")
            self.audit_log(user_id, "/backup", "stub_success")
        elif query.data == "back_to_main":
            await self.start(update, context)
    
    async def error_handler(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Обработчик ошибок"""
        self.logger.error(f"Ошибка в боте: {context.error}")
        
        if update and update.effective_message:
            await update.effective_message.reply_text(
                "❌ Произошла ошибка при обработке команды. Попробуйте позже."
            )
    
    def run(self):
        """Запуск бота"""
        self.logger.info("Запуск Telegram бота...")
        
        # Создаем приложение
        application = Application.builder().token(TELEGRAM_TOKEN).build()
        
        # Регистрируем обработчики команд
        application.add_handler(CommandHandler("start", self.start))
        application.add_handler(CommandHandler("help", self.help_command))
        application.add_handler(CommandHandler("status", self.status_command))
        application.add_handler(CommandHandler("incidents", self.incidents_command))
        
        # Обработчик кнопок
        application.add_handler(CallbackQueryHandler(self.button_callback))
        
        # Обработчик ошибок
        application.add_error_handler(self.error_handler)
        
        # Запускаем бота
        application.run_polling(allowed_updates=Update.ALL_TYPES)

# Глобальный импорт для requests
import requests

if __name__ == "__main__":
    bot = ExecutorBot()
    bot.run()
