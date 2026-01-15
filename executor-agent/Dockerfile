FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY executor.py .

# Создаем пользователя для безопасности
RUN useradd -m -u 1000 executor && \
    chown -R executor:executor /app
USER executor

CMD ["python", "executor.py"]
