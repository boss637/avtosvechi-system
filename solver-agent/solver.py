#!/usr/bin/env python3
"""
Агент-решатель (Solver Agent) - расширяемая система автоматизации
Будущая интеграция с ML-моделями для автоматического решения инцидентов
"""

import os
import sys
import yaml
import logging
import psycopg2
from datetime import datetime
from http.server import HTTPServer, BaseHTTPRequestHandler
from typing import Dict, List, Optional, Any
import threading

# Конфигурация
DB_CONFIG = {
    "host": os.getenv("POSTGRES_HOST", "db"),
    "port": os.getenv("POSTGRES_PORT", "5432"),
    "database": os.getenv("POSTGRES_DB", "autoshop_db"),
    "user": os.getenv("POSTGRES_USER", "autoshop"),
    "password": os.getenv("POSTGRES_PASSWORD", "autoshop")
}

RULES_FILE = "/app/rules.yaml"
HEALTH_PORT = 8080

class RulesEngine:
    """Движок правил для анализа инцидентов"""
    
    def __init__(self, rules_file: str):
        self.rules_file = rules_file
        self.rules = self.load_rules()
        self.logger = self.setup_logging()
        self.logger.info(f"RulesEngine инициализирован, загружено правил: {len(self.rules)}")
    
    def setup_logging(self):
        """Настройка логирования"""
        logger = logging.getLogger("solver_agent")
        logger.setLevel(logging.INFO)
        
        formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S'
        )
        
        console_handler = logging.StreamHandler()
        console_handler.setFormatter(formatter)
        logger.addHandler(console_handler)
        
        return logger
    
    def load_rules(self) -> List[Dict[str, Any]]:
        """Загрузка правил из YAML файла"""
        default_rules = [
            {
                "id": "rule_001",
                "name": "Перезапуск API при 500 ошибке",
                "condition": {
                    "service": "api",
                    "error_type": "http_500",
                    "count_threshold": 3,
                    "time_window_minutes": 5
                },
                "action": {
                    "type": "restart_service",
                    "service": "api",
                    "command": "docker restart autoshop_api"
                },
                "priority": "high",
                "enabled": True
            },
            {
                "id": "rule_002",
                "name": "Очистка кэша при медленном ответе",
                "condition": {
                    "service": "api",
                    "response_time_threshold": 2.0,
                    "count_threshold": 5,
                    "time_window_minutes": 10
                },
                "action": {
                    "type": "execute_command",
                    "command": "redis-cli FLUSHALL",
                    "description": "Очистка кэша Redis"
                },
                "priority": "medium",
                "enabled": True
            }
        ]
        
        try:
            if os.path.exists(self.rules_file):
                with open(self.rules_file, 'r') as f:
                    rules = yaml.safe_load(f) or []
                self.logger.info(f"Правила загружены из {self.rules_file}")
                return rules
            else:
                self.logger.warning(f"Файл правил {self.rules_file} не найден, используются правила по умолчанию")
                return default_rules
        except Exception as e:
            self.logger.error(f"Ошибка загрузки правил: {str(e)}")
            return default_rules
    
    def analyze_incident(self, incident: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Анализ инцидента и поиск подходящего правила"""
        for rule in self.rules:
            if not rule.get("enabled", True):
                continue
            
            if self._check_condition(rule["condition"], incident):
                self.logger.info(f"Найдено правило для инцидента {incident.get('id')}: {rule['name']}")
                return {
                    "rule": rule,
                    "incident": incident,
                    "timestamp": datetime.now().isoformat()
                }
        
        return None
    
    def _check_condition(self, condition: Dict[str, Any], incident: Dict[str, Any]) -> bool:
        """Проверка условия правила"""
        try:
            # Проверка сервиса
            if condition.get("service") and condition["service"] != incident.get("service_name"):
                return False
            
            # Проверка типа ошибки
            if condition.get("error_type") and condition["error_type"] != incident.get("error_type"):
                return False
            
            # Дополнительные проверки могут быть добавлены здесь
            # Например, проверка порогов, временных окон и т.д.
            
            return True
            
        except Exception as e:
            self.logger.error(f"Ошибка проверки условия: {str(e)}")
            return False
    
    def get_recommended_action(self, rule_match: Dict[str, Any]) -> Dict[str, Any]:
        """Получение рекомендуемого действия на основе правила"""
        rule = rule_match["rule"]
        incident = rule_match["incident"]
        
        return {
            "rule_id": rule["id"],
            "rule_name": rule["name"],
            "incident_id": incident.get("id"),
            "action": rule["action"],
            "confidence": 0.85,  # Базовая уверенность, может быть улучшена ML
            "timestamp": datetime.now().isoformat(),
            "description": f"Автоматическое действие на основе правила '{rule['name']}'"
        }

class SolverAgent:
    """Основной класс агента-решателя"""
    
    def __init__(self):
        self.rules_engine = RulesEngine(RULES_FILE)
        self.logger = self.rules_engine.logger
        self.running = True
        self.logger.info("Solver Agent инициализирован")
    
    def check_new_incidents(self):
        """Проверка новых инцидентов в БД"""
        try:
            conn = psycopg2.connect(**DB_CONFIG)
            cursor = conn.cursor()
            
            cursor.execute("""
                SELECT id, service_name, error_type, status, metadata
                FROM incidents 
                WHERE status = 'new'
                ORDER BY created_at ASC
                LIMIT 10
            """)
            
            incidents = cursor.fetchall()
            cursor.close()
            conn.close()
            
            recommendations = []
            
            for incident in incidents:
                incident_dict = {
                    "id": incident[0],
                    "service_name": incident[1],
                    "error_type": incident[2],
                    "status": incident[3],
                    "metadata": incident[4] if incident[4] else {}
                }
                
                # Анализируем инцидент
                rule_match = self.rules_engine.analyze_incident(incident_dict)
                if rule_match:
                    action = self.rules_engine.get_recommended_action(rule_match)
                    recommendations.append(action)
                    
                    # Логируем рекомендацию
                    self.logger.info(f"Рекомендация для инцидента {incident[0]}: {action['rule_name']}")
            
            return recommendations
            
        except Exception as e:
            self.logger.error(f"Ошибка проверки инцидентов: {str(e)}")
            return []
    
    def execute_action(self, action: Dict[str, Any]) -> Dict[str, Any]:
        """Выполнение действия (заглушка для будущей реализации)"""
        self.logger.info(f"ВЫПОЛНЕНИЕ ДЕЙСТВИЯ: {action['rule_name']}")
        self.logger.info(f"Тип действия: {action['action']['type']}")
        self.logger.info(f"Описание: {action.get('description', 'Нет описания')}")
        
        # Заглушка: в реальной системе здесь будет выполнение команды
        # через shell-agent или другую систему
        
        return {
            "action_id": action["rule_id"],
            "status": "simulated_success",
            "message": "Действие успешно смоделировано",
            "timestamp": datetime.now().isoformat(),
            "execution_time": 0.1
        }
    
    def run_analysis_cycle(self):
        """Цикл анализа инцидентов"""
        self.logger.info("Запуск цикла анализа инцидентов")
        
        while self.running:
            try:
                self.logger.info("Проверка новых инцидентов...")
                recommendations = self.check_new_incidents()
                
                if recommendations:
                    self.logger.info(f"Найдено рекомендаций: {len(recommendations)}")
                    
                    for rec in recommendations:
                        # В реальной системе здесь может быть проверка
                        # нужно ли требовать подтверждение от человека
                        if rec.get("confidence", 0) > 0.9:  # Высокая уверенность
                            self.logger.info(f"Автоматическое выполнение: {rec['rule_name']}")
                            result = self.execute_action(rec)
                            self.logger.info(f"Результат: {result['status']}")
                        else:
                            self.logger.info(f"Требуется подтверждение для: {rec['rule_name']}")
                            # Здесь можно отправить уведомление в Telegram
                
                # Ожидание перед следующей проверкой
                import time
                time.sleep(60)  # Проверка каждую минуту
                
            except Exception as e:
                self.logger.error(f"Ошибка в цикле анализа: {str(e)}")
                import time
                time.sleep(30)

class HealthHandler(BaseHTTPRequestHandler):
    """HTTP обработчик для health checks"""
    
    def do_GET(self):
        if self.path == '/health':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            response = {
                "status": "healthy",
                "service": "solver-agent",
                "timestamp": datetime.now().isoformat(),
                "version": "1.0.0",
                "rules_loaded": len(self.server.solver.rules_engine.rules)
            }
            self.wfile.write(str(response).encode())
        elif self.path == '/rules':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            response = {
                "rules_count": len(self.server.solver.rules_engine.rules),
                "rules": self.server.solver.rules_engine.rules
            }
            self.wfile.write(str(response).encode())
        else:
            self.send_response(404)
            self.end_headers()
    
    def log_message(self, format, *args):
        pass  # Отключаем логирование HTTP запросов

def start_health_server(solver_agent: SolverAgent, port: int = 8080):
    """Запуск HTTP сервера для health checks"""
    class CustomHTTPServer(HTTPServer):
        solver = solver_agent
    
    server = CustomHTTPServer(('0.0.0.0', port), HealthHandler)
    
    server_thread = threading.Thread(target=server.serve_forever)
    server_thread.daemon = True
    server_thread.start()
    
    return server

def main():
    """Основная функция запуска агента"""
    agent = SolverAgent()
    
    # Запускаем HTTP сервер для health checks
    start_health_server(agent, HEALTH_PORT)
    agent.logger.info(f"Health server запущен на порту {HEALTH_PORT}")
    
    # Запускаем цикл анализа
    agent.run_analysis_cycle()

if __name__ == "__main__":
    main()
