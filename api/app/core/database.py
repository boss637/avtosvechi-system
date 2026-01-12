from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from typing import AsyncGenerator

from app.core.config import settings
from app.models.base import Base

# Используем DATABASE_URL как есть (asyncpg автоматически)
database_url = settings.database_url.replace('postgresql://', 'postgresql+asyncpg://')

# Создаём асинхронный движок для подключения к PostgreSQL
engine = create_async_engine(
    database_url,
    echo=True if settings.app_env == "development" else False,
    pool_size=20,
    max_overflow=30,
    pool_pre_ping=True
)

# Создаём фабрику сессий для работы с БД
AsyncSessionLocal = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with AsyncSessionLocal() as session:
        yield session
