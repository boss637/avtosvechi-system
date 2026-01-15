FROM python:3.9-slim

WORKDIR /app

# Устанавливаем зависимости
RUN apt-get update && apt-get install -y \
    netcat-traditional \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY solver.py rules.yaml .

# Создаем пользователя для безопасности
RUN useradd -m -u 1000 solver && \
    chown -R solver:solver /app
USER solver

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD python -c "import requests; requests.get('http://localhost:8080/health', timeout=2)" || exit 1

EXPOSE 8080

CMD ["python", "solver.py"]
