#!/usr/bin/env python3
import time
import sys

# Включаем буферизацию вывода
sys.stdout.reconfigure(line_buffering=True)
sys.stderr.reconfigure(line_buffering=True)

print("🤖 Telegram Bot Fixed: Started!", flush=True)
print(f"✅ Time: {time.ctime()}", flush=True)
print(f"✅ Python: {sys.version}", flush=True)

counter = 0
try:
    while True:
        print(f"✅ Heartbeat {counter}: {time.ctime()}", flush=True)
        time.sleep(10)
        counter += 1
except KeyboardInterrupt:
    print("🛑 Bot stopped by user", flush=True)
except Exception as e:
    print(f"❌ Error: {e}", flush=True)
