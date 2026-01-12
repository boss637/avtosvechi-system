import logging
from logging.config import dictConfig
import os


LOG_DIR = "/app/logs"
os.makedirs(LOG_DIR, exist_ok=True)

LOGGING_CONFIG = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "default": {
            "format": "%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        },
    },
    "handlers": {
        "console": {
            "class": "logging.StreamHandler",
            "formatter": "default",
        },
        "file": {
            "class": "logging.FileHandler",
            "formatter": "default",
            "filename": os.path.join(LOG_DIR, "app.log"),
            "encoding": "utf-8",
        },
    },
    "loggers": {
        "": {
            "handlers": ["console", "file"],
            "level": "INFO",
        },
        "app": {
            "handlers": ["console", "file"],
            "level": "INFO",
            "propagate": False,
        },
    },
}


def setup_logging(level: str = "INFO") -> None:
    LOGGING_CONFIG["loggers"][""]["level"] = level
    LOGGING_CONFIG["loggers"]["app"]["level"] = level
    dictConfig(LOGGING_CONFIG)
