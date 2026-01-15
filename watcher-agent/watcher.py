#!/usr/bin/env python3
"""
Промышленный агент-наблюдатель (Watcher Agent)
Мониторинг сервисов, запись инцидентов в БД, метрики Prometheus
"""

import os
import sys
import time
import logging
import signal
import threading
import requests
import psycopg2
from datetime import datetime
from logging.handlers import RotatingFileHandler
from http.server import HTTPServer, BaseHTTPRequestHandler
from typing import Optional, Dict, Any

# Конфигурация
DB_CONFIG = {
    "host": os.getenv("POSTGRES_HOST", "db"),
    "port": os.getenv("POSTGRES_PORT", "5432"),
    "database": os.getenv("POSTGRES_DB", "autoshop_db"),
    "user": os.getenv("POSTGRES_USER", "autoshop"),
    "password": os.getenv("POSTGRES_PASSWORD", "autoshop")
}

SERVICES_TO_MONITOR = [
    {"name": "api", "url": "http://api:8000/health", "type": "http"},
    {"name": "shell-agent", "url": "http://shell-agent:8001/health", "type": "http"},
    {"name": "postgres", "url": None, "type": "postgres"}
]

CHECK_INTERVAL = int(os.getenv("WATCHER_INTERVAL", "30"))  # секунды
LOG_FILE = "/var/log/watcher/watcher.log"
METRICS_PORT = int(os.getenv("WATCHER_METRICS_PORT", "9090"))

class MetricsHandler(BaseHTTPRequestHandler):
    """HTTP обработчик для метрик Prometheus"""
    
    def do_GET(self):
        if self.path == '/metrics':
            self.send_response(200)
            self.send_header('Content-type', 'text/plain')
            self.end_headers()
            self.wfile.write(self.server.watcher.get_metrics().encode())
        elif self.path == '/health':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            response = {'status': 'healthy', 'timestamp': str(datetime.now())}
            self.wfile.write(str(response).encode())
        else:
            self.send_response(404)
            self.end_headers()
    
    def log_message(self, format, *args):
        pass  # Отключаем логирование HTTP запросов

class WatcherAgent:
    """Класс агента-наблюдателя с промышленными стандартами"""
    
    def __init__(self):
        self.setup_logging()
        self.running = True
        self.metrics = {
            "checks_total": 0,
            "checks_failed": 0,
            "incidents_created": 0,
            "last_check_time": None,
            "services_health": {}
        }
        
        # Настройка обработки сигналов
        signal.signal(signal.SIGTERM, self.handle_shutdown)
        signal.signal(signal.SIGINT, self.handle_shutdown)
        
        self.logger.info("Watcher Agent инициализирован")
        self.logger.info(f"Будет мониторить сервисы: {[s['name'] for s in SERVICES_TO_MONITOR]}")
    
    def setup_logging(self):
        """Настройка логирования с ротацией"""
        os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)
        
        self.logger = logging.getLogger("watcher_agent")
        self.logger.setLevel(logging.INFO)
        
        # Форматтер
        formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S'
        )
        
        # Файловый обработчик с ротацией
        file_handler = RotatingFileHandler(
            LOG_FILE,
            maxBytes=10*1024*1024,  # 10 MB
            backupCount=5
        )
        file_handler.setFormatter(formatter)
        
        # Консольный обработчик
        console_handler = logging.StreamHandler()
        console_handler.setFormatter(formatter)
        
        self.logger.addHandler(file_handler)
        self.logger.addHandler(console_handler)
    
    def handle_shutdown(self, signum, frame):
        """Graceful shutdown при получении SIGTERM/SIGINT"""
        self.logger.info(f"Получен сигнал {signum}. Завершаем работу...")
        self.running = False
    
    def check_postgres(self) -> bool:
        """Проверка доступности PostgreSQL"""
        try:
            conn = psycopg2.connect(**DB_CONFIG)
            cursor = conn.cursor()
            cursor.execute("SELECT 1")
            cursor.close()
            conn.close()
            return True
        except Exception as e:
            self.logger.error(f"PostgreSQL недоступен: {str(e)}")
            return False
    
    def check_http_service(self, url: str) -> Dict[str, Any]:
        """Проверка HTTP сервиса"""
        try:
            response = requests.get(url, timeout=5)
            return {
                "available": response.status_code == 200,
                "status_code": response.status_code,
                "response_time": response.elapsed.total_seconds(),
                "timestamp": datetime.now().isoformat()
            }
        except requests.exceptions.Timeout:
            return {"available": False, "error": "timeout", "timestamp": datetime.now().isoformat()}
        except requests.exceptions.ConnectionError:
            return {"available": False, "error": "connection_refused", "timestamp": datetime.now().isoformat()}
        except Exception as e:
            return {"available": False, "error": str(e), "timestamp": datetime.now().isoformat()}
    
    def record_incident(self, service_name: str, error_type: str, metadata: dict):
        """Запись инцидента в базу данных"""
        try:
            conn = psycopg2.connect(**DB_CONFIG)
            cursor = conn.cursor()
            
            cursor.execute("""
                INSERT INTO incidents 
                (service_name, error_type, status, metadata) 
                VALUES (%s, %s, 'new', %s)
            """, (service_name, error_type, metadata))
            
            conn.commit()
            cursor.close()
            conn.close()
            
            self.metrics["incidents_created"] += 1
            self.logger.info(f"Инцидент записан: {service_name} - {error_type}")
            
        except Exception as e:
            self.logger.error(f"Ошибка записи инцидента в БД: {str(e)}")
    
    def run_check(self):
        """Выполнение одной проверки всех сервисов"""
        self.metrics["checks_total"] += 1
        self.metrics["last_check_time"] = datetime.now()
        
        for service in SERVICES_TO_MONITOR:
            service_name = service["name"]
            service_type = service["type"]
            
            if service_type == "postgres":
                is_healthy = self.check_postgres()
                self.metrics["services_health"][service_name] = {
                    "healthy": is_healthy,
                    "timestamp": datetime.now().isoformat()
                }
                
                if not is_healthy:
                    self.metrics["checks_failed"] += 1
                    self.record_incident(
                        service_name="postgres",
                        error_type="postgres_unavailable",
                        metadata={"type": "database", "timestamp": str(datetime.now())}
                    )
            
            elif service_type == "http":
                result = self.check_http_service(service["url"])
                self.metrics["services_health"][service_name] = result
                
                if not result["available"]:
                    self.metrics["checks_failed"] += 1
                    
                    error_type = result.get("error", "http_error")
                    metadata = {
                        "url": service["url"],
                        "error": result.get("error"),
                        "status_code": result.get("status_code"),
                        "timestamp": str(datetime.now())
                    }
                    
                    self.record_incident(
                        service_name=service_name,
                        error_type=error_type,
                        metadata=metadata
                    )
                else:
                    self.logger.debug(f"Сервис {service_name} доступен, время ответа: {result['response_time']:.3f}с")
    
    def get_metrics(self) -> str:
        """Генерация метрик в формате Prometheus"""
        metrics_lines = []
        
        # Счетчики
        metrics_lines.append(f'watcher_checks_total {self.metrics["checks_total"]}')
        metrics_lines.append(f'watcher_checks_failed {self.metrics["checks_failed"]}')
        metrics_lines.append(f'watcher_incidents_created {self.metrics["incidents_created"]}')
        
        # Время последней проверки
        if self.metrics["last_check_time"]:
            last_check_timestamp = self.metrics["last_check_time"].timestamp()
            metrics_lines.append(f'watcher_last_check_timestamp {last_check_timestamp}')
        
        # Статусы сервисов
        for service_name, health_info in self.metrics["services_health"].items():
            is_healthy = 1 if health_info.get("healthy", False) or health_info.get("available", False) else 0
            metrics_lines.append(f'watcher_service_healthy{{service="{service_name}"}} {is_healthy}')
        
        return "\n".join(metrics_lines)
    
    def start_metrics_server(self):
        """Запуск HTTP сервера для метрик"""
        class CustomHTTPServer(HTTPServer):
            watcher = self
        
        server = CustomHTTPServer(('0.0.0.0', METRICS_PORT), MetricsHandler)
        self.logger.info(f"Метрики доступны на порту {METRICS_PORT}")
        
        # Запускаем сервер в отдельном потоке
        server_thread = threading.Thread(target=server.serve_forever)
        server_thread.daemon = True
        server_thread.start()
    
    def run(self):
        """Основной цикл работы агента"""
        self.logger.info("Запуск основного цикла мониторинга")
        
        # Запускаем HTTP сервер для метрик
        self.start_metrics_server()
        
        while self.running:
            try:
                self.logger.info(f"Начинаем проверку сервисов (цикл #{self.metrics['checks_total'] + 1})")
                self.run_check()
                self.logger.info(f"Проверка завершена. Ожидание {CHECK_INTERVAL} секунд...")
                time.sleep(CHECK_INTERVAL)
                
            except Exception as e:
                self.logger.error(f"Критическая ошибка в основном цикле: {str(e)}")
                time.sleep(10)  # Подождать перед повторной попыткой
        
        self.logger.info("Watcher Agent завершил работу")

if __name__ == "__main__":
    agent = WatcherAgent()
    agent.run()
