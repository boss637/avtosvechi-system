FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY watcher.py .

# Создаем директорию для логов
RUN mkdir -p /var/log/watcher

# Создаем пользователя для безопасности
RUN useradd -m -u 1000 watcher && \
    chown -R watcher:watcher /app /var/log/watcher
USER watcher

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD python -c "import requests; requests.get('http://localhost:9090/metrics', timeout=2)" || exit 1

EXPOSE 9090

CMD ["python", "watcher.py"]
