from sqlalchemy.orm import Session
from app.core.database import get_db
from typing import Generator

def get_db_session() -> Generator[Session, None, None]:
    """Зависимость для получения сессии БД"""
    db = next(get_db())
    try:
        yield db
    finally:
        db.close()
