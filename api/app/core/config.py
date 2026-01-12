import os
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    database_url: str
    app_env: str = "production"
    SECRET_KEY: str = "your-super-secret-key-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30

settings = Settings()
